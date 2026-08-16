import '../../../core/result/result.dart';
import '../../../core/storage/public_cache.dart';
import 'lgu_service.dart';

/// Reads the published LGU service catalogue.
///
/// The one repository in this app backed by a real, committed endpoint:
/// `GET /api/v1/services`, unauthenticated by design so residents can browse
/// before registering.
abstract interface class ServiceCatalogRepository {
  /// Lists services.
  ///
  /// [channel] and [category] are the two filters the server accepts
  /// (`ListServicesCriteria::fromRequest`), both enumerated allow-lists where an
  /// unrecognised value is dropped rather than applied.
  ///
  /// Note that `?channel=` is a **presentation filter chosen by the caller** and
  /// is unrelated to the `X-Client-Channel` header, which is telemetry. Neither
  /// confers authority.
  Future<Result<Paginated<LguService>>> listServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page,
    int perPage,
  });

  /// The last catalogue this app actually fetched, however old — or `null`.
  ///
  /// ---
  ///
  /// **A separate method, and synchronous, on purpose.** [listServices] never
  /// silently substitutes an old answer for a new one: a caller that receives
  /// data has no obligation to check whether it should have. This is the
  /// opposite door, and taking it is an explicit act that carries an obligation
  /// with it — [CachedRead.storedAt] comes back attached to the value, so the
  /// screen that shows it can say how old it is.
  ///
  /// Public content only, and only what a real request already returned. The
  /// catalogue is unauthenticated by design on the server, so nothing personal
  /// can be behind this.
  CachedRead<Paginated<LguService>>? lastKnownServices({
    ServiceChannel? channel,
    ServiceCategory? category,
    int page,
    int perPage,
  });
}
