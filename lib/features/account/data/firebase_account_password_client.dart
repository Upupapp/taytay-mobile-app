import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/result/result.dart';
import '../../auth/domain/code_exchange.dart';
import '../domain/account_password_client.dart';

/// The signed-in Firebase user, narrowed to the two calls a password change makes.
abstract interface class SignedInPasswordUser {
  String? get email;

  Future<void> reauthenticate(String password);

  Future<void> updatePassword(String password);
}

/// Firebase Auth: `reauthenticateWithCredential`, then `updatePassword`.
///
/// Pass a session to prove the order without a Firebase app.
class FirebaseAccountPasswordClient implements AccountPasswordClient {
  const FirebaseAccountPasswordClient({SignedInPasswordUser? session})
    : _session = session;

  final SignedInPasswordUser? _session;

  SignedInPasswordUser get _user => _session ?? FirebaseSignedInPasswordUser();

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
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
    final SignedInPasswordUser user = _user;
    if (user.email == null || user.email!.isEmpty) {
      return const Err<void>(
        UnauthenticatedFailure(
          debugMessage: 'No signed-in email for a password change.',
        ),
      );
    }
    try {
      await user.reauthenticate(currentPassword);
      await user.updatePassword(newPassword);
      return const Ok<void>(null);
    } on PasswordChangeException catch (error) {
      return Err<void>(error.failure);
    } catch (error, stack) {
      return Err<void>(
        UnexpectedFailure(
          debugContext: 'FirebaseAccountPasswordClient.changePassword',
          error: error.runtimeType,
          stackTrace: stack,
        ),
      );
    }
  }
}

/// Reads [FirebaseAuth.currentUser] at the moment of the call.
class FirebaseSignedInPasswordUser implements SignedInPasswordUser {
  FirebaseSignedInPasswordUser({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  FirebaseAuth get _firebase => _auth ?? FirebaseAuth.instance;

  User? get _current => _firebase.currentUser;

  @override
  String? get email => _current?.email;

  @override
  Future<void> reauthenticate(String password) async {
    final User? user = _current;
    final String? address = user?.email;
    if (user == null || address == null || address.isEmpty) {
      throw const PasswordChangeException(
        UnauthenticatedFailure(
          debugMessage: 'No signed-in email for a password change.',
        ),
      );
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: address, password: password),
      );
    } on FirebaseAuthException catch (error) {
      throw PasswordChangeException(_failure(error.code));
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    final User? user = _current;
    if (user == null) {
      throw const PasswordChangeException(
        UnauthenticatedFailure(
          debugMessage: 'Signed-in user disappeared before the update.',
        ),
      );
    }
    try {
      await user.updatePassword(password);
    } on FirebaseAuthException catch (error) {
      throw PasswordChangeException(_failure(error.code));
    }
  }
}

final class PasswordChangeException implements Exception {
  const PasswordChangeException(this.failure);

  final AppFailure failure;
}

AppFailure _failure(String code) => switch (code) {
  'wrong-password' ||
  'invalid-credential' ||
  'invalid-login-credentials' ||
  'user-mismatch' => const ValidationFailure(
    fieldErrors: <String, List<String>>{
      'current_password': <String>['That password does not match.'],
    },
    debugMessage: 'firebase-auth-rejected-current-password',
  ),
  'weak-password' => const ValidationFailure(
    fieldErrors: <String, List<String>>{
      'new_password': <String>[
        'Use at least 8 characters, with a letter and a number.',
      ],
    },
    debugMessage: 'firebase-auth-weak-password',
  ),
  'network-request-failed' => const NetworkFailure(
    debugMessage: 'firebase-auth-network',
  ),
  'too-many-requests' => const RateLimitedFailure(
    debugMessage: 'firebase-auth-rate-limited',
  ),
  'user-not-found' || 'requires-recent-login' => const UnauthenticatedFailure(
    debugMessage: 'firebase-auth-needs-sign-in',
  ),
  _ => const UnexpectedFailure(
    debugContext: 'FirebaseSignedInPasswordUser',
    debugMessage: 'firebase-auth-unrecognised',
  ),
};
