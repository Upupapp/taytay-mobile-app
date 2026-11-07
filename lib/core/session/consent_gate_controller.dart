import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/platform/domain/app_bootstrap.dart';
import '../../features/platform/domain/consent_review.dart';
import '../../features/platform/domain/platform_repository.dart';
import '../../features/settings/domain/account_controls.dart';
import '../result/result.dart';
import 'session_controller.dart';
import 'session_state.dart';

/// Asks a signed-in resident to accept a Terms of Use or Privacy Notice
/// version published after they last agreed.
///
/// ---
///
/// ## When it asks
///
/// When a session begins (a cold start that restores one, or a sign-in) and
/// when the resident returns to the app. The staff console's warning — that a
/// new version "makes every resident accept the text again in the app" — is
/// only true if the app looks; registration alone records consent once.
///
/// ## A failure never locks anybody out
///
/// The gate closes only on a **successful** answer from both
/// `GET /app/config` and `GET /me/consents` that names a version the resident
/// has not accepted. No version, no answer, a refusal or a timeout all leave
/// the app usable, and the next return to the app asks again. A municipal app
/// that a weak connection could lock is one a resident cannot rely on at the
/// counter, which is exactly where the digital ID is needed.
///
/// ## Nothing is claimed that the server did not confirm
///
/// [agree] reports success only when every missing version came back from
/// `POST /me/consents` as an accepted, unwithdrawn record. Anything less keeps
/// the screen up with the failure, so a resident is never told an agreement
/// was recorded when it was not. If the server still cannot record it,
/// [continueForNow] lets them in without pretending, and they are asked again
/// next time.
///
/// **This is presentation, not authorization** (Article 3.1). The server does
/// not refuse requests from a resident who has not accepted the latest text;
/// the gate exists so the LGU's request to accept actually reaches people.
class ConsentGateController extends ChangeNotifier {
  ConsentGateController({
    required SessionController session,
    required PlatformRepository platform,
    required AccountControlsRepository consents,
    DateTime Function()? clock,
    this.resumeInterval = const Duration(minutes: 5),
  }) : _session = session,
       _platform = platform,
       _consents = consents,
       _now = clock ?? DateTime.now {
    _session.addListener(_onSessionChanged);
  }

  final SessionController _session;
  final PlatformRepository _platform;
  final AccountControlsRepository _consents;
  final DateTime Function() _now;

  /// How long after a successful check a return to the app asks again.
  ///
  /// A photo taken from a form returns to the app too. Asking the server on
  /// every one of those costs two requests and buys nothing: a text published
  /// in the last five minutes is still asked for on the next return.
  final Duration resumeInterval;

  String? _accountId;
  int _generation = 0;
  ConsentReview? _owed;
  final List<String> _pending = <String>[];
  bool _recording = false;
  AppFailure? _recordFailure;
  DateTime? _lastAnswered;

  /// Whether a signed-in resident must agree before reaching their account.
  bool get isRequired =>
      _owed != null && _session.state is AuthenticatedSession;

  /// What is owed. Null when nothing is.
  ConsentReview? get review => isRequired ? _owed : null;

  /// Whether [agree] is waiting for the server.
  bool get isRecording => _recording;

  /// Why the last [agree] did not finish. Null after a success or a new check.
  AppFailure? get recordFailure => _recordFailure;

  /// Asks the server what is in force and what this resident has accepted.
  ///
  /// Never throws and never blocks: until it answers, the gate stays as it
  /// was, and a failed answer opens it.
  Future<void> check() async {
    final String? accountId = _session.state.residentOrNull?.accountId;
    if (accountId == null) {
      _reset();
      return;
    }
    final int generation = ++_generation;

    final Result<AppBootstrap> config = await _platform.loadBootstrap();
    if (!_stillAsking(generation, accountId)) return;
    final AppBootstrap? current = config.valueOrNull;
    if (current == null) {
      _settle(null);
      return;
    }
    if (ConsentReview.of(current, const <ConsentRecord>[]).namesNoVersion) {
      // Nothing is asked for, so there is nothing to look up.
      _lastAnswered = _now();
      _settle(null);
      return;
    }

    final Result<List<ConsentRecord>> held = await _consents.listConsents();
    if (!_stillAsking(generation, accountId)) return;
    switch (held) {
      case Err<List<ConsentRecord>>():
        _settle(null);
      case Ok<List<ConsentRecord>>(:final List<ConsentRecord> value):
        final ConsentReview review = ConsentReview.of(current, value);
        _lastAnswered = _now();
        _settle(review.isSettled ? null : review);
    }
  }

  /// [check], unless the last answer is younger than [resumeInterval].
  Future<void> checkOnResume() async {
    if (_session.state is! AuthenticatedSession) return;
    final DateTime? last = _lastAnswered;
    if (last != null && _now().difference(last) < resumeInterval) return;
    await check();
  }

  /// Records every missing version. True only when the server confirmed each.
  Future<bool> agree() async {
    final ConsentReview? owed = review;
    final String? accountId = _session.state.residentOrNull?.accountId;
    if (owed == null || accountId == null) return false;
    if (_recording) return false;
    // A check already in flight read the consents before this agreement and
    // would close the gate again on a stale list. It is let go.
    final int generation = ++_generation;

    _recording = true;
    _recordFailure = null;
    notifyListeners();

    while (_pending.isNotEmpty) {
      final String version = _pending.first;
      final Result<ConsentRecord> result = await _consents.acceptConsent(
        version: version,
      );
      if (!_stillAsking(generation, accountId)) return false;
      final AppFailure? failure = switch (result) {
        Err<ConsentRecord>(:final AppFailure failure) => failure,
        // The record that came back is the server's word. One that is not
        // this version, or is still withdrawn, is not a confirmation.
        Ok<ConsentRecord>(:final ConsentRecord value)
            when value.key.trim() != version || !value.isActive =>
          const ContractFailure(
            debugMessage: 'Consent answer did not confirm the version.',
          ),
        Ok<ConsentRecord>() => null,
      };
      if (failure != null) {
        _recording = false;
        _recordFailure = failure;
        notifyListeners();
        return false;
      }
      _pending.removeAt(0);
    }

    _recording = false;
    _owed = null;
    _lastAnswered = _now();
    notifyListeners();
    return true;
  }

  /// Lets a resident in after [agree] failed, without recording anything.
  ///
  /// Offered only once the server has failed to record the agreement: a
  /// request that cannot get through must not keep somebody out of their own
  /// account. The next return to the app asks again.
  void continueForNow() {
    if (_recordFailure == null || _recording) return;
    _owed = null;
    _pending.clear();
    _recordFailure = null;
    _lastAnswered = null;
    notifyListeners();
  }

  bool _stillAsking(int generation, String accountId) =>
      generation == _generation &&
      _session.state.residentOrNull?.accountId == accountId;

  void _settle(ConsentReview? owed) {
    _owed = owed;
    _pending
      ..clear()
      ..addAll(owed?.versionsToRecord ?? const <String>[]);
    _recording = false;
    _recordFailure = null;
    notifyListeners();
  }

  void _reset() {
    _generation++;
    final bool changed = _owed != null || _recording || _recordFailure != null;
    _owed = null;
    _pending.clear();
    _recording = false;
    _recordFailure = null;
    _lastAnswered = null;
    if (changed) notifyListeners();
  }

  /// A new account is a new question; a session ending answers none.
  ///
  /// A tier change (unverified to verified) is the same account and asks
  /// nothing new.
  void _onSessionChanged() {
    final SessionState state = _session.state;
    if (!state.isResolved) return;
    final String? accountId = state.residentOrNull?.accountId;
    if (accountId == _accountId) return;
    _accountId = accountId;
    _reset();
    if (accountId != null) unawaited(check());
  }

  @override
  void dispose() {
    _generation++;
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
