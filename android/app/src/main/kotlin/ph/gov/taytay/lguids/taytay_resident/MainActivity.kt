package ph.gov.taytay.lguids.taytay_resident

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * Host activity for the Flutter engine.
 *
 * Extends `FlutterFragmentActivity` rather than `FlutterActivity` because the
 * platform biometric prompt (`androidx.biometric.BiometricPrompt`, used by the
 * `local_auth` plugin) is a fragment and requires a `FragmentActivity` host. No
 * business logic lives here, and none may: CLAUDE.md Article 1 keeps Kotlin to
 * the generated platform runner.
 */
class MainActivity : FlutterFragmentActivity()
