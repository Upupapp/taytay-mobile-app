import 'package:flutter/foundation.dart';

import '../storage/secure_secret_store.dart';
import 'local_authenticator.dart';
import 'session_controller.dart';
import 'session_state.dart';

/// Whether the app is currently hiding its contents behind a local unlock.
enum AppLockState {
  /// The resident has not turned the lock on, or nobody is signed in.
  disabled,

  /// On, and satisfied. Normal use.
  unlocked,

  /// On, and the app has been backgrounded since it was last unlocked. Content
  /// is hidden until the platform confirms the person holding the device.
  locked,
}

/// An optional local lock over an app that is **already signed in**.
///
/// ---
///
/// ## What it is not
///
/// It is not authentication. It proves nothing to Taytay LGU, sends nothing to
/// the server, and cannot change an access level. The session behind it is
/// exactly as authorised while locked as while unlocked, and the server would
/// accept its token either way — which is the honest description of what a local
/// lock buys: it stops the person who picks up an unattended phone from reading
/// a resident's digital ID, and nothing more.
///
/// Treating it as identity proof would be the serious mistake here. A local
/// unlock is a statement about a *device*, made by the device, to itself.
///
/// ## Three rules that make it safe to ship
///
/// 1. **It never blocks a guest.** Public services, offices and announcements
///    stay reachable — the lock exists to protect a signed-in resident's data,
///    and there is none to protect when nobody is signed in.
/// 2. **There is always a way out.** The lock screen offers sign-out, always.
///    A resident whose fingerprint sensor has failed, or who is holding someone
///    else's phone, must never be trapped in a screen they cannot pass and
///    cannot leave. That is why enabling the lock requires no re-authentication
///    to *undo*: signing out is the escape hatch.
/// 3. **Turning it on requires passing it once.** Otherwise a resident could
///    enable a lock their device cannot actually satisfy and lock themselves out
///    of their own ID on the next resume.
class AppLockController extends ChangeNotifier {
  AppLockController({
    required SessionController session,
    required LocalAuthenticator authenticator,
    required SecretStore secrets,
  }) : _session = session,
       _authenticator = authenticator,
       _secrets = secrets {
    _session.addListener(_onSessionChanged);
  }

  final SessionController _session;
  final LocalAuthenticator _authenticator;
  final SecretStore _secrets;

  bool _enabled = false;
  bool _satisfied = true;
  bool _prompting = false;
  LocalUnlockAvailability _availability = LocalUnlockAvailability.unsupported;
  LocalUnlockOutcome? _lastOutcome;

  /// Whether the resident has switched the lock on.
  bool get isEnabled => _enabled;

  /// Whether a platform prompt is on screen. Used to avoid stacking prompts.
  bool get isPrompting => _prompting;

  LocalUnlockAvailability get availability => _availability;

  /// The outcome of the last unlock attempt, for copy on the lock screen.
  LocalUnlockOutcome? get lastOutcome => _lastOutcome;

  /// Whether this device could satisfy a lock if one were switched on.
  bool get canEnable => _availability.canUnlock;

  AppLockState get state {
    // Rule 1: a guest is never locked out of public information.
    if (_session.state is! AuthenticatedSession) return AppLockState.disabled;
    if (!_enabled) return AppLockState.disabled;
    return _satisfied ? AppLockState.unlocked : AppLockState.locked;
  }

  bool get isLocked => state == AppLockState.locked;

  /// Reads the stored preference and asks the platform what it can do.
  ///
  /// A lock whose device can no longer satisfy it — biometrics removed, screen
  /// lock switched off — is treated as **off**, not as permanently locked. The
  /// alternative bricks the app for a resident who changed a system setting.
  Future<void> load() async {
    _availability = await _authenticator.availability();
    final stored = await _secrets.read(SecretKeys.appLockEnabled);
    _enabled = stored == _enabledValue && _availability.canUnlock;
    _satisfied = true;
    notifyListeners();
  }

  /// Turns the lock on, but only after the resident passes it once (rule 3).
  ///
  /// Returns the platform's outcome so the settings screen can explain a
  /// refusal instead of silently leaving the switch off.
  Future<LocalUnlockOutcome> enable() async {
    if (!_availability.canUnlock) return LocalUnlockOutcome.unavailable;

    final outcome = await _prompt(
      'Confirm it is you before turning on the app lock',
    );
    if (outcome != LocalUnlockOutcome.unlocked) return outcome;

    await _secrets.write(SecretKeys.appLockEnabled, _enabledValue);
    _enabled = true;
    _satisfied = true;
    notifyListeners();
    return outcome;
  }

  /// Turns the lock off.
  ///
  /// Deliberately requires no unlock. The resident is already past the lock to
  /// reach this setting, and demanding a second prompt to *reduce* protection
  /// only strands people whose sensor has stopped working (rule 2).
  Future<void> disable() async {
    await _secrets.delete(SecretKeys.appLockEnabled);
    _enabled = false;
    _satisfied = true;
    _lastOutcome = null;
    notifyListeners();
  }

  /// The app left the foreground. Hides content behind the lock if it is on.
  ///
  /// Ignored when nobody is signed in. A guest has nothing behind the lock, and
  /// leaving the flag set would arm a lock that then sprang the moment somebody
  /// signed in — a resident would enter a code and be met by a prompt.
  void markBackgrounded() {
    if (_session.state is! AuthenticatedSession) return;
    if (!_enabled || !_satisfied) return;
    _satisfied = false;
    _lastOutcome = null;
    notifyListeners();
  }

  /// Asks the platform to confirm the holder, and unhides on success.
  Future<LocalUnlockOutcome> unlock() async {
    if (!isLocked) return LocalUnlockOutcome.unlocked;

    final outcome = await _prompt('Unlock Taytay LGU IDS');
    if (outcome == LocalUnlockOutcome.unlocked) {
      _satisfied = true;
    }
    notifyListeners();
    return outcome;
  }

  Future<LocalUnlockOutcome> _prompt(String reason) async {
    if (_prompting) return LocalUnlockOutcome.cancelled;
    _prompting = true;
    notifyListeners();
    try {
      final outcome = await _authenticator.authenticate(reason: reason);
      _lastOutcome = outcome;
      return outcome;
    } finally {
      _prompting = false;
      // Notified here, not by the callers: a caller that returns early on a
      // refusal would otherwise leave listeners believing a prompt is still on
      // screen, and the settings switch disabled until something else rebuilt.
      notifyListeners();
    }
  }

  /// Any change of session satisfies the lock.
  ///
  /// Both directions matter, and both were bugs before they were rules:
  ///
  /// * **Signing out** must clear it, or a locked screen would sit over a guest
  ///   session — a lock protecting nothing, that a resident cannot dismiss.
  /// * **Signing in** must clear it too. Someone who has just entered a
  ///   one-time code has proven far more than this lock ever asks, and meeting
  ///   them with an unlock prompt for their trouble is absurd.
  void _onSessionChanged() {
    if (_satisfied && _lastOutcome == null) return;
    _satisfied = true;
    _lastOutcome = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Stored rather than a boolean so that any value other than this exact string
  /// — including a corrupted read — means "off".
  static const String _enabledValue = 'on';
}
