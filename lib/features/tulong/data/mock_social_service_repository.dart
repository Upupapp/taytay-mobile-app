import '../../../core/api/paginated.dart';
import '../../../core/mock/mock_behavior.dart';
import '../../../core/mock/mock_fixtures.dart';
import '../../../core/result/result.dart';
import '../domain/social_service.dart';
import '../domain/social_service_repository.dart';
import 'office_stamp.dart';
import 'social_service_codec.dart';

/// Dev-only Tulong. Reads `tulong_services.json` and joins `offices.json`.
///
/// Staging and production never construct this. Mock data is refused outside
/// a dev build. A failed live call does not fall through to here.
class MockSocialServiceRepository implements SocialServiceRepository {
  MockSocialServiceRepository(this._behavior);

  final MockBehaviorController _behavior;

  List<SocialService>? _all;

  @override
  Future<Result<Paginated<SocialService>>> listServices({
    String? query,
    int? limit,
    String? cursor,
    bool featured = false,
  }) async {
    final List<SocialService> loaded = await _services();
    final String q = query?.trim().toLowerCase() ?? '';
    final List<SocialService> listed = <SocialService>[
      for (final SocialService service in loaded)
        if (_matches(service, q) &&
            (featured ? service.featured : !service.hiddenFromList))
          service,
    ];
    final int size = (limit ?? 20).clamp(1, 50);
    return _behavior.respond<Paginated<SocialService>>(
      Paginated<SocialService>.single(
        listed.take(size).toList(growable: false),
      ),
    );
  }

  @override
  Future<Result<SocialService>> loadService(String slug) async {
    final List<SocialService> loaded = await _services();
    for (final SocialService service in loaded) {
      if (service.slug == slug) {
        return _behavior.respond<SocialService>(service);
      }
    }
    return const Err<SocialService>(
      NotFoundFailure(debugMessage: 'No fixture service with that slug.'),
    );
  }

  /// Specimen rows that carry a saved label. Not affected by the failure
  /// switch: the list call fails, and these rows are what the phone had open.
  @override
  Future<List<SocialService>> savedOnThisPhone() async {
    final List<SocialService> loaded = await _services();
    return <SocialService>[
      for (final SocialService service in loaded)
        if (service.presentation?.savedLabel != null) service,
    ];
  }

  Future<List<SocialService>> _services() async {
    final List<SocialService>? cached = _all;
    if (cached != null) return cached;
    final Map<String, Object?> json = await MockFixtures.object(
      'tulong_services',
    );
    final Map<String, OfficeStamp> offices = await fixtureOffices();
    final Object? raw = json['services'];
    if (raw is! List<Object?>) {
      return _all = const <SocialService>[];
    }
    return _all = raw
        .map(
          (Object? item) => decodeSocialService(
            item,
            allowPresentation: true,
            offices: offices,
          ),
        )
        .whereType<SocialService>()
        .toList(growable: false);
  }

  bool _matches(SocialService service, String query) {
    if (query.isEmpty) return true;
    final String haystack =
        '${service.listTitle} ${service.name} ${service.summary}'.toLowerCase();
    return haystack.contains(query);
  }
}
