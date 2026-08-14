import 'package:local_auth/local_auth.dart';

/// Whether this device can perform a local unlock at all.
enum LocalUnlockAvailability {
  /// A fingerprint, face or device passcode/pattern can be checked.
  available,

  /// The hardware exists but nothing is enrolled, or the device has no screen
  /// lock. The resident can fix this in system settings.
  notEnrolled,

  /// No hardware, no screen lock, or a platform this build cannot ask.
  unsupported;

  bool get canUnlock => this == LocalUnlockAvailability.available;
}

/// The result of asking the platform to confirm the person holding the device.
enum LocalUnlockOutcome {
  /// The platform confirmed. The app may show itself again.
  unlocked,

  /// The resident dismissed the prompt. Not a failure — they may simply want to
  /// sign out instead.
  cancelled,

  /// The platform said no: wrong finger, too many attempts, hardware lockout.
  failed,

  /// The prompt could not be shown. Treated exactly like [failed] for access,
  /// but worth different copy: the resident has done nothing wrong.
  unavailable,
}

/// Asks the platform to confirm that the person holding the device is the person
/// who unlocked it.
///
/// ---
///
/// **What this is, precisely.** A local possession check. It answers "is this
/// the same phone, unlocked by whoever the phone trusts?" It does **not**
/// authenticate a resident to Taytay LGU, it is never sent to the server, it is
/// never stored, and it can never raise an access level. The only thing it
/// gates is whether an app that is *already signed in* re-shows itself after
/// being backgrounded — see `AppLockController`.
///
/// **No biometric data reaches this app.** The platform runs its own prompt
/// against templates held in the Secure Enclave or TEE and returns a boolean.
/// There is nothing here to log, store or leak, which is why this is one of the
/// few identity-adjacent features that adds no personal data to the app at all.
///
/// The interface exists so that a test — and any platform where this is
/// unavailable — gets a real, typed answer instead of a plugin call that throws.
abstract interface class LocalAuthenticator {
  Future<LocalUnlockAvailability> availability();

  /// Shows the platform prompt. [reason] is displayed to the resident by the OS.
  ///
  /// Must not throw: every platform error is an outcome.
  Future<LocalUnlockOutcome> authenticate({required String reason});
}

/// The shipped implementation, over `local_auth`.
class PlatformLocalAuthenticator implements LocalAuthenticator {
  PlatformLocalAuthenticator({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<LocalUnlockAvailability> availability() async {
    try {
      // `isDeviceSupported` is true when *either* a biometric is enrolled or
      // the device has a passcode/pattern. Deliberately not biometrics-only:
      // refusing to offer an app lock to a resident whose phone has no
      // fingerprint reader would withhold the feature from exactly the cheaper
      // handsets this app must serve.
      if (await _auth.isDeviceSupported()) {
        return LocalUnlockAvailability.available;
      }
      // Hardware present but nothing usable enrolled — and no screen lock
      // either. Distinguished from `unsupported` because the resident can fix
      // it in system settings, and the screen says so.
      if (await _auth.canCheckBiometrics) {
        return LocalUnlockAvailability.notEnrolled;
      }
      return LocalUnlockAvailability.unsupported;
    } on Object {
      // A plugin failure is not an unlocked device.
      return LocalUnlockAvailability.unsupported;
    }
  }

  @override
  Future<LocalUnlockOutcome> authenticate({required String reason}) async {
    try {
      // Parameter names verified against the installed plugin source,
      // `local_auth` **3.0.2** — its 3.x API flattened `AuthenticationOptions`
      // into named arguments and renamed `stickyAuth`. Re-verify before
      // changing the plugin version.
      final ok = await _auth.authenticate(
        localizedReason: reason,
        // False: the device PIN, pattern or password is an acceptable fallback.
        // Requiring biometrics only would strand a resident whose fingerprint
        // stops being read — wet hands, a cut, a worn sensor — and would
        // withhold the feature entirely from a handset with no reader.
        biometricOnly: false,
        // The prompt must survive the app being backgrounded, which is exactly
        // the gesture someone would try to get past it.
        persistAcrossBackgrounding: true,
      );
      return ok ? LocalUnlockOutcome.unlocked : LocalUnlockOutcome.failed;
    } on Object {
      return LocalUnlockOutcome.unavailable;
    }
  }
}

/// Used by tests and by any build where no platform prompt exists.
///
/// Reports [LocalUnlockAvailability.unsupported], so the app lock cannot be
/// switched on and there is nothing for it to gate. Never used as a silent
/// production fallback: an app lock that quietly stops locking is worse than one
/// that was never offered.
class UnavailableLocalAuthenticator implements LocalAuthenticator {
  const UnavailableLocalAuthenticator();

  @override
  Future<LocalUnlockAvailability> availability() async =>
      LocalUnlockAvailability.unsupported;

  @override
  Future<LocalUnlockOutcome> authenticate({required String reason}) async =>
      LocalUnlockOutcome.unavailable;
}
