import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/api/auth_coordinator.dart';
import '../../../core/result/result.dart';
import '../../../core/session/session_controller.dart';

/// A Firebase sign-in, reduced to the ID token this app sends as a bearer.
///
/// The token is credential material. [toString] does not include it.
class FirebaseCredentialSession {
  const FirebaseCredentialSession({required this.idToken, this.expiresAt});

  final String idToken;
  final DateTime? expiresAt;

  @override
  String toString() => 'FirebaseCredentialSession()';
}

/// Email, password, and phone sign-in on the Firebase SDK.
///
/// Sign-in and registration stay on this client. Password change uses
/// Firebase reauthentication and `updatePassword` in the account feature.
abstract interface class FirebaseIdentity {
  Future<Result<FirebaseCredentialSession>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Result<FirebaseCredentialSession>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sends a phone code when phone sign-in is enabled on the Firebase project.
  Future<Result<void>> sendPhoneCode({required String phoneNumber});

  Future<Result<FirebaseCredentialSession>> confirmPhoneCode({
    required String code,
  });

  /// The current ID token, refreshed when it is expired or [forceRefresh].
  ///
  /// Null when nobody is signed in to Firebase.
  Future<String?> idToken({bool forceRefresh = false});

  Future<void> signOut();
}

/// True when the cached ID token should be replaced before the next request.
bool firebaseTokenNeedsRefresh({
  required DateTime? expiresAt,
  required DateTime now,
  required bool force,
}) {
  if (force) return true;
  final DateTime? expiry = expiresAt;
  if (expiry == null) return false;
  // A minute early, so a request does not leave with a token that dies in flight.
  return !now.toUtc().isBefore(
    expiry.toUtc().subtract(const Duration(minutes: 1)),
  );
}

/// `09xxxxxxxxx` and `+639xxxxxxxxx` become E.164. Anything else is null.
String? philippineE164(String raw) {
  final String digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('09')) {
    return '+63${digits.substring(1)}';
  }
  if (digits.length == 12 && digits.startsWith('63')) return '+$digits';
  return null;
}

/// Firebase Auth. Constructing this does not touch Firebase.
class FirebaseAuthIdentity implements FirebaseIdentity {
  FirebaseAuthIdentity({FirebaseAuth? auth}) : _auth = auth;

  final FirebaseAuth? _auth;

  String? _verificationId;
  PhoneAuthCredential? _autoCredential;
  DateTime? _tokenExpiresAt;

  FirebaseAuth get _firebase => _auth ?? FirebaseAuth.instance;

  User? get _user {
    try {
      return _firebase.currentUser;
    } on Object {
      return null;
    }
  }

  @override
  Future<Result<FirebaseCredentialSession>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _firebase
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      return Ok<FirebaseCredentialSession>(await _session(credential.user));
    } on FirebaseAuthException catch (error) {
      return Err<FirebaseCredentialSession>(_failure(error.code));
    } on Object catch (error, stack) {
      return Err<FirebaseCredentialSession>(_unexpected(error, stack));
    }
  }

  @override
  Future<Result<FirebaseCredentialSession>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _firebase
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      return Ok<FirebaseCredentialSession>(await _session(credential.user));
    } on FirebaseAuthException catch (error) {
      return Err<FirebaseCredentialSession>(_failure(error.code));
    } on Object catch (error, stack) {
      return Err<FirebaseCredentialSession>(_unexpected(error, stack));
    }
  }

  @override
  Future<Result<void>> sendPhoneCode({required String phoneNumber}) async {
    final String? e164 = philippineE164(phoneNumber);
    if (e164 == null) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'A mobile number is required.'),
      );
    }
    final Completer<Result<void>> completer = Completer<Result<void>>();
    try {
      await _firebase.verifyPhoneNumber(
        phoneNumber: e164,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          _autoCredential = credential;
          if (!completer.isCompleted) {
            completer.complete(const Ok<void>(null));
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          if (!completer.isCompleted) {
            completer.complete(Err<void>(_failure(error.code)));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(const Ok<void>(null));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (error) {
      return Err<void>(_failure(error.code));
    } on Object catch (error, stack) {
      return Err<void>(_unexpected(error, stack));
    }
    return completer.future;
  }

  @override
  Future<Result<FirebaseCredentialSession>> confirmPhoneCode({
    required String code,
  }) async {
    final PhoneAuthCredential? automatic = _autoCredential;
    final String? verificationId = _verificationId;
    if (automatic == null &&
        (verificationId == null || verificationId.isEmpty)) {
      return const Err<FirebaseCredentialSession>(
        ValidationFailure(
          debugMessage: 'No phone verification is in progress.',
        ),
      );
    }
    try {
      final PhoneAuthCredential credential =
          automatic ??
          PhoneAuthProvider.credential(
            verificationId: verificationId!,
            smsCode: code.trim(),
          );
      final UserCredential signed = await _firebase.signInWithCredential(
        credential,
      );
      _autoCredential = null;
      return Ok<FirebaseCredentialSession>(await _session(signed.user));
    } on FirebaseAuthException catch (error) {
      return Err<FirebaseCredentialSession>(_failure(error.code));
    } on Object catch (error, stack) {
      return Err<FirebaseCredentialSession>(_unexpected(error, stack));
    }
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    final User? user = _user;
    if (user == null) return null;
    final bool refresh = firebaseTokenNeedsRefresh(
      expiresAt: _tokenExpiresAt,
      now: DateTime.now(),
      force: forceRefresh,
    );
    try {
      final IdTokenResult result = await user.getIdTokenResult(refresh);
      _tokenExpiresAt = result.expirationTime;
      final String? token = result.token;
      if (token == null || token.isEmpty) return null;
      return token;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    _verificationId = null;
    _autoCredential = null;
    _tokenExpiresAt = null;
    try {
      await _firebase.signOut();
    } on Object {
      // No Firebase app means there is no identity session to end.
    }
  }

  Future<FirebaseCredentialSession> _session(User? user) async {
    if (user == null) {
      throw const _IdentityException(
        UnauthenticatedFailure(debugMessage: 'Firebase returned no user.'),
      );
    }
    final IdTokenResult result = await user.getIdTokenResult(true);
    final String? token = result.token;
    if (token == null || token.isEmpty) {
      throw const _IdentityException(
        UnexpectedFailure(
          debugContext: 'FirebaseAuthIdentity',
          debugMessage: 'Firebase returned an empty ID token.',
        ),
      );
    }
    _tokenExpiresAt = result.expirationTime;
    return FirebaseCredentialSession(
      idToken: token,
      expiresAt: result.expirationTime,
    );
  }

  AppFailure _unexpected(Object error, StackTrace stack) {
    if (error is _IdentityException) return error.failure;
    return UnexpectedFailure(
      debugContext: 'FirebaseAuthIdentity',
      error: error.runtimeType,
      stackTrace: stack,
    );
  }
}

final class _IdentityException implements Exception {
  const _IdentityException(this.failure);

  final AppFailure failure;
}

AppFailure _failure(String code) => switch (code) {
  'wrong-password' ||
  'invalid-credential' ||
  'invalid-login-credentials' ||
  'user-not-found' ||
  'invalid-email' ||
  'invalid-verification-code' ||
  'invalid-verification-id' ||
  'session-expired' => const UnauthenticatedFailure(
    debugMessage: 'firebase-auth-rejected',
  ),
  'email-already-in-use' => const ConflictFailure(
    debugMessage: 'firebase-auth-email-in-use',
  ),
  'weak-password' => const ValidationFailure(
    fieldErrors: <String, List<String>>{
      'password': <String>[
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
  'operation-not-allowed' => const ServerFailure(
    debugMessage: 'firebase-auth-provider-disabled',
  ),
  _ => const UnexpectedFailure(
    debugContext: 'FirebaseAuthIdentity',
    debugMessage: 'firebase-auth-unrecognised',
  ),
};

/// Refreshes the Firebase ID token after a `401` and stores the replacement.
class FirebaseTokenRefresher implements TokenRefresher {
  const FirebaseTokenRefresher({
    required FirebaseIdentity identity,
    required SessionController session,
  }) : _identity = identity,
       _session = session;

  final FirebaseIdentity _identity;
  final SessionController _session;

  @override
  Future<String?> refresh() async {
    try {
      final String? token = await _identity.idToken(forceRefresh: true);
      if (token == null || token.isEmpty) return null;
      await _session.replaceAccessToken(accessToken: token);
      return token;
    } on Object {
      return null;
    }
  }
}
