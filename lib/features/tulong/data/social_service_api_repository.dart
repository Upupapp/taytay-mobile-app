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
/// The Tulong tab reads the whole list with [readCatalogue] and searches it on
/// the phone. No request from this class carries a search term (D-59, D-205).
///
/// Gaps, left unset rather than filled in:
///
/// * No hours on `Service`. A contact whose label contains "hour" is shown
///   as sent. Otherwise hours come from `GET /offices` `hours`, when that
///   string exists.
/// * No saved-pages resource and no saved-at. [savedOnThisPhone] is the list
///   already loaded in this process. Nothing is written to device storage.
///   A page the API says is gone leaves it (D-222): see [savedOnThisPhone].
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

  /// The slugs in [_seen] that a list read has carried as listed. Only these
  /// can be forgotten for missing from a whole catalogue: a page only ever
  /// reached by its address (a hidden one, or a link) was never the list's to
  /// speak for (D-222).
  final Set<String> _listed = <String>{};

  static const String path = 'services';

  /// The most pages [readCatalogue] reads: 500 services at the route's
  /// ceiling of 50 a page. Far above what the MSWDO publishes; a catalogue
  /// that outgrows it is shown as far as it was read, labelled (D-205).
  static const int catalogueMaxPages = 10;

  /// The route's own ceiling (`limit` 1–50).
  static const int catalogueLimit = 50;

  @override
  Future<Result<ServiceCatalogue>> readCatalogue() async {
    final List<SocialService> read = <SocialService>[];
    final Set<String> slugs = <String>{};
    String? cursor;
    for (var page = 0; page < catalogueMaxPages; page++) {
      final Result<ApiEnvelope<List<SocialService>>> response = await _apiClient
          .send<List<SocialService>>(
            method: HttpMethod.get,
            path: path,
            authenticated: false,
            attachTokenIfAvailable: true,
            // Never `q` (D-59): the term stays on the phone.
            query: <String, String>{
              'limit': '$catalogueLimit',
              'cursor': ?cursor,
            },
            decode: _decodeList,
          );
      switch (response) {
        case Err<ApiEnvelope<List<SocialService>>>(:final failure):
          return Err<ServiceCatalogue>(failure);
        case Ok<ApiEnvelope<List<SocialService>>>(:final value):
          for (final SocialService service in value.data) {
            if (service.hiddenFromList || !slugs.add(service.slug)) continue;
            read.add(service);
          }
          final PageMeta? meta = value.pagination;
          final String? next = meta?.nextCursor;
          if (meta == null || !meta.hasMore) {
            return Ok<ServiceCatalogue>(
              ServiceCatalogue(
                services: await _joined(read, whole: true),
                complete: true,
              ),
            );
          }
          if (next == null || next.isEmpty) {
            // More, and no way to ask for it.
            return Ok<ServiceCatalogue>(
              ServiceCatalogue(
                services: await _joined(read, whole: false),
                complete: false,
              ),
            );
          }
          cursor = next;
      }
    }
    return Ok<ServiceCatalogue>(
      ServiceCatalogue(
        services: await _joined(read, whole: false),
        complete: false,
      ),
    );
  }

  /// [whole] is a read that reached the catalogue's last page. Only that read
  /// can say a saved page is no longer listed; a cut one cannot (D-222).
  Future<List<SocialService>> _joined(
    List<SocialService> read, {
    required bool whole,
  }) async {
    final List<SocialService> joined = List<SocialService>.unmodifiable(
      await _withOffices(read),
    );
    if (whole) {
      final Set<String> listed = <String>{
        for (final SocialService service in joined) service.slug,
      };
      _forget(_listed.difference(listed));
    }
    // The first twenty, kept in the catalogue's order, are the saved pages.
    _remember(joined.take(20).toList().reversed.toList());
    _carried(joined);
    return joined;
  }

  @override
  Future<Result<Paginated<SocialService>>> listServices({
    int? limit,
    String? cursor,
    bool featured = false,
    String? office,
  }) async {
    final String? officeSlug = office?.trim();
    final bool scoped = officeSlug != null && officeSlug.isNotEmpty;
    final int size = (limit ?? 20).clamp(1, 50);
    if (!scoped && cursor == null) _cursor = null;
    final Result<ApiEnvelope<List<SocialService>>> response = await _apiClient
        .send<List<SocialService>>(
          method: HttpMethod.get,
          path: path,
          authenticated: false,
          attachTokenIfAvailable: true,
          query: <String, String>{
            'limit': '$size',
            'cursor': ?(scoped ? cursor : cursor ?? _cursor),
            'featured': ?(featured ? 'true' : null),
            'office': ?(scoped ? officeSlug : null),
          },
          decode: _decodeList,
        );
    switch (response) {
      case Err<ApiEnvelope<List<SocialService>>>(:final failure):
        return Err<Paginated<SocialService>>(failure);
      case Ok<ApiEnvelope<List<SocialService>>>(:final value):
        if (!scoped) _cursor = value.pagination?.nextCursor;
        final List<SocialService> joined = await _withOffices(value.data);
        final List<SocialService> visible = <SocialService>[
          for (final SocialService service in joined)
            if (featured ? service.featured : !service.hiddenFromList) service,
        ];
        _remember(visible);
        _carried(visible);
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
        // The API's answer that the page is gone, as an archived one is: it
        // is no longer offered as saved (D-222). Any other failure keeps it,
        // which is what the saved list is for.
        if (failure is NotFoundFailure) {
          _forget(<String>{slug});
        }
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

  /// The pages already loaded in this process, never one the API has since
  /// said is withdrawn (D-222): a `404` on its own read forgets it, and so
  /// does a whole catalogue that no longer lists a page a list read carried.
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
      _listed.retainWhere(_saved);
    }
  }

  /// Marks the saved pages among [rows] as ones the list speaks for. A row
  /// hidden from the list (the featured list carries some) is not: the
  /// catalogue never lists it, so its absence there says nothing.
  void _carried(Iterable<SocialService> rows) {
    for (final SocialService row in rows) {
      if (!row.hiddenFromList && _saved(row.slug)) _listed.add(row.slug);
    }
  }

  bool _saved(String slug) =>
      _seen.any((SocialService seen) => seen.slug == slug);

  void _forget(Set<String> slugs) {
    if (slugs.isEmpty) return;
    _seen.removeWhere((SocialService seen) => slugs.contains(seen.slug));
    _listed.removeAll(slugs);
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
