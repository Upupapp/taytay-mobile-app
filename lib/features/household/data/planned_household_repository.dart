import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/household_repository.dart';
import '../domain/household_summary.dart';

/// The [HouseholdRepository] this build ships with: it declines, honestly.
///
/// ---
///
/// **Both halves of this are now wrong.** It said there was no citizen household
/// endpoint and no correction route. `ResidentProfile` serves `GET me/household`
/// and the full `me/profile/corrections` surface — get, post and delete — and
/// has since backend TAB 09. TAB 05 wires the household; corrections go through
/// TAB 04 rather than a second editing path built here.
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

  static const UnwiredRepository _repository = UnwiredRepository.household;

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async =>
      unwiredRepositoryFailure<HouseholdSummary>(
        _repository,
        'loadOwnHousehold',
      );

  @override
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  }) async => unwiredRepositoryFailure<void>(
    _repository,
    'submitHouseholdCorrectionRequest',
  );
}
