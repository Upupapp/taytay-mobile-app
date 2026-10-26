import '../../../core/result/result.dart';

/// Changes the signed-in resident's password.
///
/// Staging and production call Firebase Auth. A dev mock build never talks
/// to Firebase.
abstract interface class AccountPasswordClient {
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
