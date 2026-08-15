import '../../../core/result/result.dart';
import 'household_summary.dart';

/// The signed-in resident's own household.
///
/// ---
///
/// **Every method is `/me`-scoped and takes no identifier.** Not "takes one and
/// validates it" — takes none at all. The only household route in the committed
/// contract is `GET /api/v1/households/{household_id}`, which is a **staff**
/// route requiring `resident.view` under a role scope, with the sensitivity note
/// *"member list is other people's data — audited read"*. A citizen app must
/// never hold that permission, and an interface that cannot express "fetch
/// household 42" cannot be talked into unrestricted registry browsing by any
/// future caller (acceptance 1).
///
/// **Nothing here writes to the registry.** [submitCorrectionRequest] raises a
/// question for a person to answer; it carries a category and no target value,
/// so it cannot rewrite membership, a relationship or an address, and it cannot
/// move anybody between households (acceptance 3).
///
/// **No endpoint backs any of this yet.** The contract has no `/me/household`
/// row and no correction route. The shipped implementation therefore declines,
/// and the screens say so honestly rather than showing an invented family.
abstract interface class HouseholdRepository {
  /// The signed-in resident's own household summary.
  ///
  /// A `404` is an ordinary outcome, not an error to hide: plenty of residents
  /// are recorded without a household, and the screen says so plainly.
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
}
