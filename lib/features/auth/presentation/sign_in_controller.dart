import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../../../core/session/session_controller.dart';
import '../domain/auth_repository.dart';
import '../domain/sign_in_challenge.dart';

/// Drives the two-step sign-in: mobile number, then one-time code.
///
/// ---
///
/// **Why a controller rather than screen state.** The rules here — what a
/// resident is told after a refusal, when a resend becomes available, what is
/// held in memory and for how long — are the security-relevant part of sign-in,
/// and they are testable only if they are not tangled with widgets. The screen
/// renders this; it decides nothing.
///
/// **What is held, and for how long.** The mobile number lives here for the
/// length of the flow because the verify call needs it. The code is held only
/// between the keystroke and the request, and is cleared on every outcome —
/// success, refusal, or abandoning the step. Neither is ever written to storage,
/// logged, or put in [toString].
class SignInController extends ChangeNotifier {
  SignInController({
    required AuthRepository repository,
    required SessionController session,
    DateTime Function()? clock,
  }) : _repository = repository,
       _session = session,
       _now = clock ?? DateTime.now;

  final AuthRepository _repository;
  final SessionController _session;
  final DateTime Function() _now;

  SignInStep _step = SignInStep.identifier;
  String _mobileNumber = '';
  bool _busy = false;
  SignInMessage? _message;
  DateTime? _resendAvailableAt;
  Timer? _cooldownTicker;

  SignInStep get step => _step;

  /// The number being signed in with. Never rendered in full on the code step —
  /// see [maskedMobileNumber].
  String get mobileNumber => _mobileNumber;

  String get maskedMobileNumber => SignInIdentifier.mask(_mobileNumber);

  /// True while a request is in flight. The screen disables its action and shows
  /// a spinner; it must not let a resident spend a second attempt by
  /// double-tapping.
  bool get busy => _busy;

  SignInMessage? get message => _message;

  /// Seconds until "Send a new code" becomes available, or zero.
  int get resendCooldownSeconds {
    final until = _resendAvailableAt;
    if (until == null) return 0;
    final remaining = until.difference(_now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  bool get canResend => !_busy && resendCooldownSeconds == 0;

  /// Step 1: ask the server to send a code.
  ///
  /// The outcome message is [SignInMessage.codeSent] on success **and the step
  /// advances either way the server says yes** — because a server that answers
  /// `202` for a number it has never seen is exactly the behaviour the contract
  /// requires, and the client must not act differently on the two cases it
  /// cannot tell apart.
  Future<void> requestCode(String mobileNumber) async {
    if (_busy) return;
    _mobileNumber = mobileNumber.trim();
    await _send(advanceOnSuccess: true);
  }

  /// Asks for another code for the same number.
  Future<void> resendCode() async {
    if (!canResend) return;
    await _send(advanceOnSuccess: false);
  }

  Future<void> _send({required bool advanceOnSuccess}) async {
    _busy = true;
    _message = null;
    notifyListeners();

    final result = await _repository.requestOneTimeCode(
      mobileNumber: _mobileNumber,
    );

    _busy = false;
    switch (result) {
      case Ok<void>():
        _message = SignInMessage.codeSent;
        if (advanceOnSuccess) _step = SignInStep.code;
        _startCooldown();
      case Err<void>(:final failure):
        _message = SignInFeedback.forFailure(failure);
    }
    notifyListeners();
  }

  /// Step 2: exchange the code for a session.
  ///
  /// On success the session is established through [SessionController.signIn] —
  /// the single place an authenticated state is created — carrying the server's
  /// own `expires_at`. The screen does not navigate: the router reacts to the
  /// session, as it does everywhere else.
  Future<bool> verifyCode(String code) async {
    if (_busy) return false;
    _busy = true;
    _message = null;
    notifyListeners();

    final result = await _repository.verifyOneTimeCode(
      mobileNumber: _mobileNumber,
      code: code.trim(),
    );

    _busy = false;
    switch (result) {
      case Ok<AuthOutcome>(:final value):
        await _session.signIn(
          resident: value.resident,
          accessToken: value.accessToken,
          expiresAt: value.expiresAt,
        );
        // Nothing about this attempt is kept: the flow is over, and the number
        // has no reason to outlive it.
        _reset();
        notifyListeners();
        return true;
      case Err<AuthOutcome>(:final failure):
        _message = SignInFeedback.forFailure(failure);
        notifyListeners();
        return false;
    }
  }

  /// Back to step 1, e.g. "I typed the wrong number".
  void changeNumber() {
    _step = SignInStep.identifier;
    _message = null;
    _cancelCooldown();
    notifyListeners();
  }

  void _startCooldown() {
    _resendAvailableAt = _now().add(OneTimeCodeRules.resendCooldown);
    _cooldownTicker?.cancel();
    // Ticks only to re-render the countdown. The button's real gate is the
    // timestamp comparison, so a missed tick cannot enable it early.
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldownSeconds == 0) timer.cancel();
      notifyListeners();
    });
  }

  void _cancelCooldown() {
    _cooldownTicker?.cancel();
    _cooldownTicker = null;
    _resendAvailableAt = null;
  }

  void _reset() {
    _step = SignInStep.identifier;
    _mobileNumber = '';
    _message = null;
    _cancelCooldown();
  }

  @override
  void dispose() {
    _cancelCooldown();
    super.dispose();
  }

  /// Redacted: a mobile number is personal data under RA 10173, and this object
  /// is the kind that ends up in a crash report.
  @override
  String toString() => 'SignInController(step: ${_step.name}, busy: $_busy)';
}
