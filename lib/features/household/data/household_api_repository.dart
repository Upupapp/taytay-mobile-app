import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/household_repository.dart';
import '../domain/household_summary.dart';

/// Talks to `GET households/current`.
///
/// The citizen projection is the signed-in resident's own household: address,
/// barangay name, the viewer's role, and the members the contract publishes.
/// The screen still shows the count rather than a list of names. [toString]
/// on the summary and on each member stays redacted.
class HouseholdApiRepository implements HouseholdRepository {
  const HouseholdApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'households/current';

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async {
    final response = await _apiClient.send<HouseholdSummary>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      decode: decodeHousehold,
    );
    return switch (response) {
      Ok(:final value) => Ok<HouseholdSummary>(value.data),
      Err(:final failure) => Err<HouseholdSummary>(failure),
    };
  }

  /// Allow-list decoder for `Household` on `3e3b110`.
  static HouseholdSummary decodeHousehold(Object? data) {
    final Map<String, dynamic> map = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final List<HouseholdMember> members = _members(map['members']);
    final Object? address = map['address'];
    final Object? barangay = map['barangay_name'];
    return HouseholdSummary(
      role: HouseholdRole.fromRaw(
        map['viewer_role'] is String ? map['viewer_role'] as String : null,
      ),
      streetAddress: address is String && address.trim().isNotEmpty
          ? address.trim()
          : null,
      barangay: barangay is String && barangay.trim().isNotEmpty
          ? barangay.trim()
          : null,
      memberCount: members.length,
      members: members,
    );
  }

  static List<HouseholdMember> _members(Object? raw) {
    if (raw is! List) return const <HouseholdMember>[];
    return raw
        .map(_member)
        .whereType<HouseholdMember>()
        .toList(growable: false);
  }

  static HouseholdMember? _member(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> map = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    final Object? id = map['id'];
    final Object? name = map['name'];
    if (id is! String || id.isEmpty || name is! String || name.trim().isEmpty) {
      return null;
    }
    final Object? birthdate = map['birthdate'];
    final Object? userId = map['user_id'];
    return HouseholdMember(
      id: id,
      name: name.trim(),
      relationship: HouseholdRelationship.fromRaw(
        map['relationship'] is String ? map['relationship'] as String : null,
      ),
      birthdate: birthdate is String ? DateTime.tryParse(birthdate) : null,
      sex: HouseholdSex.fromRaw(
        map['sex'] is String ? map['sex'] as String : null,
      ),
      userId: userId is String && userId.isNotEmpty ? userId : null,
      inviteStatus: HouseholdInviteStatus.fromRaw(
        map['invite_status'] is String ? map['invite_status'] as String : null,
      ),
    );
  }

  @override
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  }) async {
    // The same mismatch as F23, in its sharpest form.
    //
    // `POST me/profile/corrections` requires `changes` — at least one named
    // field with a proposed value. A household correction here carries a
    // *category* and nothing else, deliberately: "someone is missing from the
    // household record" is a fact about other people, and this app does not ask
    // a resident to type their relatives' names into a form in order to report
    // that the office's count is wrong.
    //
    // So there is nothing to propose, and proposing something would be inventing
    // it. Declining is the honest answer, and the screen already routes the
    // resident to the office. Closing this needs a route that accepts a reported
    // discrepancy rather than an amendment — a contract conversation, not a
    // client workaround.
    return backendGapFailure<void>(
      BackendGap.kycFieldCorrections,
      'submitCorrectionRequest (${request.kind.name})',
    );
  }
}
