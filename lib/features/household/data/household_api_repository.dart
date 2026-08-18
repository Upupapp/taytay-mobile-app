import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/household_repository.dart';
import '../domain/household_summary.dart';

/// Talks to `GET me/household`.
///
/// ---
///
/// **The server sends more than this app reads, and that is the point.** The
/// payload carries a `members` array with every co-resident's name, whether each
/// is the head, the caller's relationship to them, and — for the caller and
/// anyone they are recorded as caring for — a birth date and a verification
/// tier. None of it is decoded here.
///
/// That is not caution for its own sake. Household data is *other people's*
/// personal data, and this screen exists so a resident can notice that the LGU's
/// record of their home is wrong. A count answers that: it says how large a
/// household the office believes it is serving, which is exactly what makes an
/// error visible, while naming nobody. A list of names and birth dates on a
/// phone in a queue serves the resident no better and everyone else a great deal
/// worse.
///
/// The server has already done its own minimisation — `verification_status`,
/// `profile_completeness`, `dwelling_type` and the utility columns are
/// deliberately absent, because a household that learns it has been recorded as
/// "makeshift" has been handed a judgement about itself by an API rather than by
/// a caseworker who can explain it. This decoder does not undo that, and it does
/// not stop there either.
class HouseholdApiRepository implements HouseholdRepository {
  const HouseholdApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'me/household';

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async {
    final response = await _apiClient.send<HouseholdSummary>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      decode: _decode,
    );
    return response.map((envelope) => envelope.data);
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

  static HouseholdSummary _decode(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    // THE MEMBER ARRAY IS NOT READ AT ALL, and the first version of this
    // decoder did read it — for one field.
    //
    // `is_head` is only published inside `members`, so learning whether the
    // resident is the household head means walking a list of their relatives.
    // The feature's own acceptance is deliberately stronger than "we do not
    // render members": it is that nothing here could hold one, and a test
    // enforces it over the whole directory. Walking the array to take one
    // boolean out of it satisfies the letter and gives up the guarantee — the
    // list would be in memory, in a decoder somebody later extends.
    //
    // So the role is left to fail closed, which it already does. What that costs
    // is a label: a household head sees "Household member". What it buys is that
    // the strongest privacy claim this feature makes stays true by construction
    // rather than by care. The head/member distinction is also, exactly, a fact
    // about this resident's standing relative to the others — the surface being
    // avoided — and the office can say it out loud where a caseworker can
    // explain it.
    final Object? street = map['street_address'];
    final Object? label = map['code'];
    final Object? count = map['member_count'];

    return HouseholdSummary(
      // Fails closed to member: being shown as the head when you are not is a
      // claim about authority over other people's records. See above for why it
      // is never anything else.
      role: HouseholdRole.member,
      label: label is String && label.trim().isNotEmpty ? label.trim() : null,
      // `barangay_id` is an integer key, and no route publishes the directory
      // that would turn it into a name (F14). A raw id on this screen tells a
      // resident nothing and invites them to believe it is meaningful, so it is
      // left absent until there is something readable to put there.
      streetAddress: street is String && street.trim().isNotEmpty
          ? street.trim()
          : null,
      memberCount: count is int ? count : null,
    );
  }
}
