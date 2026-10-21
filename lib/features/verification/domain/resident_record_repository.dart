import '../../../core/result/result.dart';
import 'resident_record.dart';

/// The profile wizard's own read and write.
///
/// Every method is the signed-in resident's own record. None takes an id.
/// The screen that calls this holds the result. The session does not.
abstract interface class ResidentRecordRepository {
  Future<Result<ResidentRecord>> load();

  Future<Result<ResidentRecord>> savePersonal(PersonalDraft draft);

  Future<Result<ResidentRecord>> saveHousehold(HouseholdDraft draft);

  /// Sends the profile the wizard is showing.
  ///
  /// A live build patches `/me` and the current household with the fields
  /// Clarence's spec publishes. Years at the address, residence type and a
  /// civil status are kept by the dev mock only. The repository does not
  /// retain the draft: the screen passes it, and drops it when it closes.
  Future<Result<ResidentRecord>> submit({
    required PersonalDraft personal,
    required HouseholdDraft household,
  });
}
