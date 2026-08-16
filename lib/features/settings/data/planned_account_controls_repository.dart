import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../domain/account_controls.dart';

/// Account controls for a backend module that does not exist yet.
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

  static const PlannedModule _module = PlannedModule.residentProfile;

  @override
  Future<Result<AccountControls>> loadControls() async =>
      const Ok<AccountControls>(AccountControls.none);

  @override
  Future<Result<List<ConsentRecord>>> listConsents() async =>
      plannedBackendFailure<List<ConsentRecord>>(_module, 'listConsents');

  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  }) async => plannedBackendFailure<ConsentRecord>(_module, 'withdrawConsent');

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) async => plannedBackendFailure<void>(_module, 'requestDataCorrection');

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) async => plannedBackendFailure<void>(_module, 'requestAccountClosure');
}
