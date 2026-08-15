import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../domain/household_repository.dart';
import '../domain/household_summary.dart';

/// The [HouseholdRepository] this build ships with: it declines, honestly.
///
/// ---
///
/// **There is no citizen household endpoint at all.** The committed matrix has
/// one household row — `GET /api/v1/households/{household_id}`, staff-scoped
/// under `resident.view` — and no `/me/household`. There is likewise no
/// correction route: nothing in the contract lets a resident raise a question
/// about their own household record.
///
/// Mocking either would be worse here than anywhere else in the app. A
/// fabricated household is a claim by a local government about who somebody
/// lives with — the sort of thing that decides whether a family is counted as
/// one household or two for assistance — and a correction form that pretends to
/// submit would leave a resident believing the office had been told something it
/// never heard.
///
/// So both decline, and the screens say what is true: the record exists at the
/// municipal hall, and that is where it can be seen and corrected.
class PlannedHouseholdRepository implements HouseholdRepository {
  const PlannedHouseholdRepository();

  static const PlannedModule _module = PlannedModule.residentProfile;

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async =>
      plannedBackendFailure<HouseholdSummary>(_module, 'loadOwnHousehold');

  @override
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  }) async =>
      plannedBackendFailure<void>(_module, 'submitHouseholdCorrectionRequest');
}
