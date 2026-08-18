import '../../../core/api/backend_gap.dart';
import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/account_controls.dart';

/// The [AccountControlsRepository] this build ships with — and the one place
/// where "not built" is still partly the right answer.
///
/// `Audit` serves consents and acknowledgements today (`me/privacy/consents`,
/// `me/privacy/acknowledgement`) and corrections are `me/profile/corrections`,
/// so most of this screen is wiring work — TAB 18. **Account closure is not:**
/// no module publishes a route that closes, erases or deletes an account at the
/// baseline (`F13`). Both app stores require an in-app deletion path, so that is
/// a launch blocker owned by TAB 22, and it needs TAB 18's retention schedule
/// first — a municipal record cannot always simply be erased, and the screen has
/// to say what is deleted and what is kept by law.
///
/// ---
///
/// **`loadControls` succeeds, and returns nothing.** Every other planned
/// repository in this app declines, and this one deliberately does not: the
/// honest answer to "what may this resident ask for?" when no policy endpoint
/// exists is **"nothing yet"**, and that is a real answer rather than a failure.
///
/// Declining here would put an error state on the privacy screen — implying
/// something is broken — when the truthful reading is that the LGU has not
/// switched these paths on. Returning [AccountControls.none] makes the screen
/// say exactly that, and makes it impossible for any control to appear.
///
/// The operations themselves still decline. A correction or closure request that
/// silently succeeded against nothing would be the worst outcome available here:
/// a resident would believe they had asked the municipality to erase their
/// record, and no one would ever have been told.
class PlannedAccountControlsRepository implements AccountControlsRepository {
  const PlannedAccountControlsRepository();

  static const UnwiredRepository _repository =
      UnwiredRepository.accountControls;

  @override
  Future<Result<AccountControls>> loadControls() async =>
      const Ok<AccountControls>(AccountControls.none);

  @override
  Future<Result<List<ConsentRecord>>> listConsents() async =>
      unwiredRepositoryFailure<List<ConsentRecord>>(
        _repository,
        'listConsents',
      );

  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  }) async =>
      unwiredRepositoryFailure<ConsentRecord>(_repository, 'withdrawConsent');

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) async =>
      unwiredRepositoryFailure<void>(_repository, 'requestDataCorrection');

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) async => backendGapFailure<void>(
    BackendGap.accountClosure,
    'requestAccountClosure',
  );
}
