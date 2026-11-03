import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/social_service.dart';
import '../domain/social_service_repository.dart';
import 'office_stamp.dart';
import 'social_service_codec.dart';

/// Live Tulong. `GET /services` and `GET /services/{slug}`.
///
/// Public reads. A signed-in resident still sends the session token. This
/// repository does not call admin routes, `GET /programs`, or apply.
///
/// Gaps, left unset rather than filled in:
///
/// * No hours on `Service`. A contact whose label contains "hour" is shown
///   as sent. Otherwise hours come from `GET /offices` `hours`, when that
///   string exists.
/// * No saved-pages resource and no saved-at. [savedOnThisPhone] is the list
///   already loaded in this process. Nothing is written to device storage.
/// * No apply or submit route.
/// * `hero_url` is stored. The service page reads `GET /services/{slug}/hero`
///   when it is set. A null URL keeps the icon tile. The list does not.
/// * No SAMPLE flag. A live requirement is never marked sample.
/// * Contacts are `{type, label|null, value}`. An unrecognised type is
///   still shown.
class SocialServiceApiRepository implements SocialServiceRepository {
  SocialServiceApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  String? _cursor;
  Map<String, OfficeStamp>? _offices;

  /// Services this process has already decoded, newest first.
  final List<SocialService> _seen = <SocialService>[];

  static const String path = 'services';

  @override
  Future<Result<Paginated<SocialService>>> listServices({
    String? query,
    int? limit,
    String? cursor,
    bool featured = false,
  }) async {
    final String? q = query?.trim();
    final int size = (limit ?? 20).clamp(1, 50);
    if (cursor == null) _cursor = null;
    final Result<ApiEnvelope<List<SocialService>>> response = await _apiClient
        .send<List<SocialService>>(
          method: HttpMethod.get,
          path: path,
          authenticated: false,
          attachTokenIfAvailable: true,
          query: <String, String>{
            'limit': '$size',
            'cursor': ?(cursor ?? _cursor),
            'q': ?((q == null || q.isEmpty) ? null : q),
            'featured': ?(featured ? 'true' : null),
          },
          decode: _decodeList,
        );
    switch (response) {
      case Err<ApiEnvelope<List<SocialService>>>(:final failure):
        return Err<Paginated<SocialService>>(failure);
      case Ok<ApiEnvelope<List<SocialService>>>(:final value):
        _cursor = value.pagination?.nextCursor;
        final List<SocialService> joined = await _withOffices(value.data);
        final List<SocialService> visible = <SocialService>[
          for (final SocialService service in joined)
            if (featured ? service.featured : !service.hiddenFromList) service,
        ];
        _remember(visible);
        final PageMeta? page = value.pagination;
        if (page == null) {
          return Ok<Paginated<SocialService>>(
            Paginated<SocialService>.single(visible),
          );
        }
        return Ok<Paginated<SocialService>>(
          Paginated<SocialService>(
            items: visible,
            page: page.page,
            perPage: page.perPage,
            total: page.total,
            totalPages: page.totalPages,
            hasMore: page.hasMore,
          ),
        );
    }
  }

  @override
  Future<Result<SocialService>> loadService(String slug) async {
    final Result<ApiEnvelope<SocialService?>> response = await _apiClient
        .send<SocialService?>(
          method: HttpMethod.get,
          path: '$path/$slug',
          authenticated: false,
          attachTokenIfAvailable: true,
          decode: (Object? data) =>
              decodeSocialService(data, allowPresentation: false),
        );
    switch (response) {
      case Err<ApiEnvelope<SocialService?>>(:final failure):
        return Err<SocialService>(failure);
      case Ok<ApiEnvelope<SocialService?>>(:final value):
        final SocialService? service = value.data;
        if (service == null) {
          return const Err<SocialService>(
            NotFoundFailure(debugMessage: 'No readable service in the body.'),
          );
        }
        final List<SocialService> joined = await _withOffices(<SocialService>[
          service,
        ]);
        _remember(joined);
        return Ok<SocialService>(joined.single);
    }
  }

  @override
  Future<List<SocialService>> savedOnThisPhone() async =>
      List<SocialService>.unmodifiable(_seen);

  void _remember(List<SocialService> services) {
    for (final SocialService service in services) {
      _seen.removeWhere((SocialService seen) => seen.slug == service.slug);
      _seen.insert(0, service);
    }
    if (_seen.length > 20) {
      _seen.removeRange(20, _seen.length);
    }
  }

  List<SocialService> _decodeList(Object? data) {
    if (data is! List<Object?>) return const <SocialService>[];
    return data
        .map(
          (Object? item) => decodeSocialService(item, allowPresentation: false),
        )
        .whereType<SocialService>()
        .toList(growable: false);
  }

  Future<List<SocialService>> _withOffices(List<SocialService> items) async {
    final bool needs = items.any(
      (SocialService item) =>
          item.officeSlug != null && item.officeName == null,
    );
    if (!needs) return items;
    final Map<String, OfficeStamp> offices = await _officeStamps();
    if (offices.isEmpty) return items;
    return <SocialService>[
      for (final SocialService item in items)
        if (item.officeSlug != null && offices[item.officeSlug] != null)
          item.withOffice(
            name: offices[item.officeSlug]!.name,
            shortName: offices[item.officeSlug]!.shortName,
            hours: offices[item.officeSlug]!.hours,
            phone: offices[item.officeSlug]!.phone,
          )
        else
          item,
    ];
  }

  Future<Map<String, OfficeStamp>> _officeStamps() async {
    final Map<String, OfficeStamp>? cached = _offices;
    if (cached != null) return cached;
    final Map<String, OfficeStamp> stamps = <String, OfficeStamp>{};
    String? cursor;
    for (var page = 0; page < 5; page++) {
      final Result<ApiEnvelope<List<OfficeStamp>>> response = await _apiClient
          .send<List<OfficeStamp>>(
            method: HttpMethod.get,
            path: 'offices',
            authenticated: false,
            query: <String, String>{'limit': '50', 'cursor': ?cursor},
            decode: _decodeOffices,
          );
      switch (response) {
        case Err<ApiEnvelope<List<OfficeStamp>>>():
          return stamps;
        case Ok<ApiEnvelope<List<OfficeStamp>>>(:final value):
          for (final OfficeStamp stamp in value.data) {
            stamps[stamp.slug] = stamp;
          }
          final String? next = value.pagination?.nextCursor;
          if (value.pagination?.hasMore != true ||
              next == null ||
              next.isEmpty) {
            return _offices = stamps;
          }
          cursor = next;
      }
    }
    return _offices = stamps;
  }

  static List<OfficeStamp> _decodeOffices(Object? data) {
    if (data is! List<Object?>) return const <OfficeStamp>[];
    final List<OfficeStamp> stamps = <OfficeStamp>[];
    for (final Object? item in data) {
      if (item is! Map) continue;
      final OfficeStamp? stamp = officeStampFrom(item.cast<Object?, Object?>());
      if (stamp != null) stamps.add(stamp);
    }
    return stamps;
  }
}
