import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/page_policy.dart';
import '../../../core/result/result.dart';
import '../domain/registration_domain.dart';

/// Reads `GET /api/v1/barangays`.
///
/// ---
///
/// **The endpoint this app spent an entire integration sequence unable to call.**
/// `POST me/kyc` requires a barangay, and until the backend published this
/// directory the only accepted identifier was an auto-increment primary key that
/// no route gave out — so a resident could not open a KYC case, could not become
/// Verified, and could not reach the digital ID or any service resting on it.
/// That was F14, and it was the largest single blocker in the platform.
///
/// **Public, and requested anonymously.** Barangay names are on municipal
/// signage; there is nothing here about anybody. Sending no token keeps the
/// response publicly cacheable, which matters because this list is fetched by
/// every resident filling in an address, on connections that pay per megabyte.
///
/// **A `code`, not an integer.** The directory publishes a UUID and a stable slug
/// and the app carries both — the slug is what a KYC claim is filed against. The
/// app never invents a PSGC code either: a wrong one is worse than an absent
/// one, because DSWD reporting keys off it.
class BarangayApiRepository implements BarangayDirectory {
  const BarangayApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'barangays';

  /// Taytay's barangays fit comfortably inside one page at the contract's
  /// ceiling, so the whole list arrives in a single request. Asked for
  /// explicitly rather than relying on the default, which is 15 for this channel
  /// and would silently truncate an address picker to the first fifteen.
  ///
  /// **The deliberate exception to TAB 05, and the reason the clamp is a method
  /// rather than a rule.** Everything else takes the size the server chose; this
  /// asks for the contract's maximum because a partial list of barangays is not
  /// a shorter list, it is an address a resident cannot select. It still goes
  /// through [PagePolicy] so it cannot exceed what the server will serve.
  static const int _perPage = PagePolicy.maxPerPage;

  @override
  Future<Result<List<Barangay>>> listBarangays() async {
    final response = await _apiClient.send<List<Barangay>>(
      method: HttpMethod.get,
      path: path,
      authenticated: false,
      query: const <String, String>{'page': '1', 'per_page': '$_perPage'},
      decode: _decodeAll,
    );
    return response.map((envelope) => envelope.data);
  }

  static List<Barangay> _decodeAll(Object? data) {
    if (data is! List<dynamic>) return const <Barangay>[];

    final List<Barangay> barangays = <Barangay>[];
    for (final Object? entry in data) {
      if (entry is! Map<String, dynamic>) continue;

      final Object? id = entry['id'];
      final Object? name = entry['name'];
      // A barangay with no name cannot be offered in a picker, and one with no
      // id cannot be filed against. Either way it is dropped rather than shown
      // as a blank row somebody might select.
      if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
        continue;
      }

      final Object? code = entry['code'];
      final Object? psgc = entry['psgc_code'];

      barangays.add(
        Barangay(
          id: id,
          name: name,
          code: code is String && code.isNotEmpty ? code : null,
          psgcCode: psgc is String && psgc.isNotEmpty ? psgc : null,
        ),
      );
    }
    return List<Barangay>.unmodifiable(barangays);
  }
}
