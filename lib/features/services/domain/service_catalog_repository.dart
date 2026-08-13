import '../../../core/result/result.dart';
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
}
