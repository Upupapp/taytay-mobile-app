import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage for credential material.
///
/// A narrow interface on purpose: read, write, delete, clear. Anything wider
/// invites callers to enumerate or export secrets.
abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// Removes everything this app stored. Used on sign-out and on
  /// fail-closed session invalidation.
  Future<void> clear();
}

/// Platform keystore implementation.
///
/// ---
///
/// ## Why these options
///
/// Verified against the installed plugin source, `flutter_secure_storage`
/// **11.0.0** — its Android API changed in v10/v11 and the older
/// `encryptedSharedPreferences` flag no longer exists. Re-verify before changing
/// the plugin version.
///
/// **Android.** The default construction encrypts values with `AES/GCM/NoPadding`
/// under a key wrapped by `RSA/ECB/OAEPWithSHA-256AndMGF1Padding` held in the
/// Android Keystore — hardware-backed where the device has a TEE or StrongBox.
/// That is what CLAUDE.md Article 5.3 requires; a plain `SharedPreferences` file
/// would be readable over ADB backup and on a rooted device.
///
/// * `resetOnError: true` — a keystore entry can become undecryptable after an
///   OS upgrade, a backup restore or a device migration. The alternative to
///   resetting is an app that throws on every launch and can only be fixed by
///   clearing its data. The token was already useless; asking the resident to
///   sign in again is the better failure.
/// * `migrateWithBackup: false` — the plugin's own default, restated here
///   because it matters: credential material must not be written into a backup
///   during migration.
///
/// **iOS — `first_unlock_this_device`.** Two properties matter. *ThisDevice*
/// excludes the item from iCloud Keychain and from encrypted backups, so a
/// government access token cannot travel to another device the resident restores
/// onto. *AfterFirstUnlock* keeps it readable after the first unlock following a
/// reboot; the stricter `unlocked` fails whenever the device is locked, and
/// `passcode` breaks entirely on a device with no passcode — a real
/// configuration among the residents this app serves.
///
/// **Biometric prompts are deliberately not enabled** (`enforceBiometrics`
/// defaults to false). Requiring a fingerprint to read the session token would
/// lock out residents whose devices have no enrolled biometric, and the token is
/// already protected by the keystore. Biometric gating belongs on presenting a
/// credential, not on holding a session.
class KeystoreSecretStore implements SecretStore {
  KeystoreSecretStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              resetOnError: true,
              migrateWithBackup: false,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}

/// Process-lifetime store used by tests and by any build with no platform
/// keystore available.
///
/// Never used as a production fallback: a silent downgrade from "encrypted by
/// the keystore" to "a map in memory" is the kind of failure that looks like it
/// works. The composition root chooses this explicitly or not at all.
class InMemorySecretStore implements SecretStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();
}

/// The keys this app is allowed to store.
///
/// An enumeration rather than free-form strings, so a code review can see every
/// secret the app holds in one place, and so a typo cannot silently create a
/// second, never-cleared entry.
abstract final class SecretKeys {
  static const String accessToken = 'taytay.session.access_token';
  static const String residentSummary = 'taytay.session.resident';

  static const List<String> all = <String>[accessToken, residentSummary];
}
