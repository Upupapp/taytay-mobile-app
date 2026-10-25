import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import 'social_service.dart';

/// Published social services. Information only.
///
/// Live: `GET /services` and `GET /services/{slug}`. A dev mock reads
/// `test/fixtures/mock/tulong_services.json`. There is no apply method.
abstract interface class SocialServiceRepository {
  /// [query] is the `q` parameter. Empty is omitted.
  /// [limit] is clamped to 1–50. The spec default is 20.
  ///
  /// [featured] sends `featured=true`. That list is the featured services,
  /// including ones hidden from the catalogue. The ordinary list omits
  /// `hidden_from_list`.
  Future<Result<Paginated<SocialService>>> listServices({
    String? query,
    int? limit,
    String? cursor,
    bool featured = false,
  });

  Future<Result<SocialService>> loadService(String slug);

  /// Pages this process has already shown, or the fixture's saved specimen.
  ///
  /// Not a server resource and not written to device storage.
  Future<List<SocialService>> savedOnThisPhone();
}
