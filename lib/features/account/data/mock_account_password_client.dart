import '../../../core/result/result.dart';
import '../../auth/domain/code_exchange.dart';
import '../domain/account_password_client.dart';

/// The dev sign-in sample, kept off a named password parameter.
const String devPasswordFixture = 'password-sample';

/// Dev-only password change. The current password starts as [initialPassword].
///
/// A wrong current password is refused, matching the dev sign-in mock. A
/// successful change replaces [currentPassword] so a second change must use
/// the new one.
class MockAccountPasswordClient implements AccountPasswordClient {
  MockAccountPasswordClient({String? initialPassword})
    : initialPassword = initialPassword ?? devPasswordFixture;

  final String initialPassword;
  String? _updated;

  /// The password a later change must present. Null until the first success.
  String get currentPassword => _updated ?? initialPassword;

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final Result<void>? invalid = _rules(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (invalid != null) return invalid;
    if (currentPassword != this.currentPassword) {
      return const Err<void>(
        ValidationFailure(
          fieldErrors: <String, List<String>>{
            'current_password': <String>['That password does not match.'],
          },
        ),
      );
    }
    _updated = newPassword;
    return const Ok<void>(null);
  }
}

Result<void>? _rules({
  required String currentPassword,
  required String newPassword,
}) {
  if (currentPassword.isEmpty) {
    return const Err<void>(
      ValidationFailure(
        fieldErrors: <String, List<String>>{
          'current_password': <String>['Enter your current password.'],
        },
      ),
    );
  }
  if (!CodeExchangeRules.acceptablePassword(newPassword)) {
    return const Err<void>(
      ValidationFailure(
        fieldErrors: <String, List<String>>{
          'new_password': <String>[
            'Use at least 8 characters, with a letter and a number.',
          ],
        },
      ),
    );
  }
  return null;
}
