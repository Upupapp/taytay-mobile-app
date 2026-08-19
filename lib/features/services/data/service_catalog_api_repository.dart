import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/page_policy.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/public_cache.dart';
import '../domain/lgu_service.dart';
import '../domain/service_catalog_repository.dart';
import 'lgu_service_dto.dart';

/// Talks to `GET /api/v1/services`.
///
/// The reference implementation for every repository that follows: the data
/// layer owns the wire format, the domain layer never sees a `Map`, pagination
/// comes from `meta.pagination`, and the request is explicitly unauthenticated
/// because the server publishes this route that way.
class ServiceCatalogApiRepository implements ServiceCatalogRepository {
  const ServiceCatalogApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The contract's own bounds (conventions §5). Sent explicitly rather than
  /// relying on the default, so the page size is visible at the call site — and
  /// clamped here too, because an over-large page is a slow response for a
  /// resident on a weak connection even when the server tolerates it.

  @override
  Future<Result<Paginated<LguService>>> listServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int? perPage,
  }) async {
    final response = await _apiClient.send<List<LguService>>(
      method: HttpMethod.get,
      path: path,
      // PUBLIC BY DESIGN: the server's route is unauthenticated so residents can
      // browse before registering.
      authenticated: false,
      query: _query(
        channel: channel,
        category: category,
        page: page,
        perPage: _apiClient.pages.clampRequest(
          perPage ?? _apiClient.pages.defaultPerPage,
        ),
      ),
      decode: LguServiceDto.listFromJson,
    );

    return response.map(_toPage);
  }

  @override
  CachedRead<Paginated<LguService>>? lastKnownServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page = 1,
    int? perPage,
  }) {
    // The same query the request would have used, so the key matches the entry
    // that request stored. Building it in one place is what makes that true.
    final cached = _apiClient.cachedAllowingStale<List<LguService>>(
      path,
      _query(
        channel: channel,
        category: category,
        page: page,
        perPage: _apiClient.pages.clampRequest(
          perPage ?? _apiClient.pages.defaultPerPage,
        ),
      ),
    );
    if (cached == null) return null;

    return CachedRead<Paginated<LguService>>(
      value: _toPage(cached.value),
      storedAt: cached.storedAt,
      isFresh: cached.isFresh,
    );
  }

  /// The contract's own path for the catalogue.
  static const String path = 'services';

  /// One place the query is built, used by the request and by the cache lookup.
  static Map<String, String> _query({
    required ServiceChannel? channel,
    required ServiceCategory? category,
    required int page,
    required int perPage,
  }) {
    final clampedPerPage = perPage.clamp(1, PagePolicy.maxPerPage);
    final clampedPage = page < 1 ? 1 : page;
    return <String, String>{
      'page': '$clampedPage',
      'per_page': '$clampedPerPage',
      if (channel != null) 'channel': channel.wireValue,
      if (category != null) 'category': category.wireValue,
    };
  }

  static Paginated<LguService> _toPage(ApiEnvelope<List<LguService>> envelope) {
    final pagination = envelope.pagination;
    if (pagination == null) {
      // The contract says collections are always paginated, but a client that
      // crashes when `meta.pagination` is absent is a client that turns a server
      // omission into an outage. Degrade to a single page.
      return Paginated<LguService>.single(envelope.data);
    }
    return Paginated<LguService>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
    );
  }
}
