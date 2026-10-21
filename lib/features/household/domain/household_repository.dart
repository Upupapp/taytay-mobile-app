import '../../../core/result/result.dart';
import 'household_record.dart';
import 'household_summary.dart';

/// The signed-in resident's own household.
///
/// Citizen routes only: create, the current household, its members, leave,
/// transfer, and the caller's invitation. There is no method that lists every
/// household in a barangay, and none that fetches a household by an arbitrary
/// id. Member and invitation ids are rows on the caller's own record.
///
/// [submitCorrectionRequest] is still the screen's report. The contract has
/// no correction route, so the live client declines that call. Address edits
/// go through [updateCurrent].
abstract interface class HouseholdRepository {
  /// The signed-in resident's own household summary.
  ///
  /// A missing household is a [NotFoundFailure]. The screen already treats
  /// that as "not readable here".
  Future<Result<HouseholdSummary>> loadOwnHousehold();

  /// Raises a correction for a person at Taytay LGU to look at.
  ///
  /// [idempotencyKey] is required: a resident on a weak connection will retry,
  /// and two identical corrections in a municipal queue is a real cost to the
  /// office that has to close one of them.
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  });

  /// `POST /households`.
  Future<Result<HouseholdRecord>> createHousehold({
    required String address,
    required String barangayId,
  });

  /// `GET /households/current`. Null when the resident has none (404).
  Future<Result<HouseholdRecord?>> loadCurrent();

  /// `PATCH /households/current`. Omitted fields are left unchanged.
  Future<Result<HouseholdRecord>> updateCurrent({
    String? address,
    String? barangayId,
  });

  /// `DELETE /households/current`.
  Future<Result<void>> deleteCurrent();

  /// `POST /households/current/members`.
  Future<Result<HouseholdMember>> addMember(HouseholdMemberDraft draft);

  /// `PATCH /households/current/members/{id}`.
  Future<Result<HouseholdMember>> updateMember({
    required String memberId,
    required HouseholdMemberChange change,
  });

  /// `DELETE /households/current/members/{id}`.
  Future<Result<void>> removeMember(String memberId);

  /// `POST /households/current/leave`.
  Future<Result<void>> leaveHousehold();

  /// `POST /households/current/transfer`.
  Future<Result<HouseholdRecord>> transferHeadship({required String memberId});

  /// `GET /households/invitations/current`. Null when there is none (404).
  Future<Result<HouseholdInvitation?>> loadCurrentInvitation();

  /// `POST /households/invitations/{id}/accept`.
  Future<Result<HouseholdRecord>> acceptInvitation(String invitationId);

  /// `POST /households/invitations/{id}/decline`.
  Future<Result<void>> declineInvitation(String invitationId);
}
