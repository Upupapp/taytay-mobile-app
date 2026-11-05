import 'package:firebase_core/firebase_core.dart';

import '../core/config/app_config.dart';
import '../core/config/firebase_client_config.dart';

/// Starts the default Firebase app. Replaced in tests, which never reach the
/// platform.
typedef FirebaseInitializer = Future<void> Function(FirebaseOptions options);

/// Starts Firebase for a build that signs residents in through it, and only
/// then. Called once, before the first frame (decision D-185).
///
/// * A configuration the startup screen will refuse is returned untouched:
///   nothing is started for a build that is not going to run.
/// * A dev mock holds no options ([AppConfig.firebase] is null) and is
///   returned untouched. Firebase is never initialised for it.
/// * A build that signs in through Firebase starts it from the four
///   `--dart-define` values. If that fails, the build stops on the
///   configuration screen. It does not start and then fail in sign-in.
///
/// Nothing about the options is logged, and the exception from a failed start
/// is dropped rather than shown: its text can quote what it was given.
Future<AppConfig> startFirebase(
  AppConfig config, {
  FirebaseInitializer initialize = _initializeDefaultApp,
}) async {
  final FirebaseClientConfig? client = config.firebase;
  if (!config.isUsable || client == null) return config;

  try {
    await initialize(firebaseOptionsFor(client));
  } on Object {
    return config.withIssues(const <ConfigIssue>[
      ConfigIssue(
        'Firebase did not start with the options this build was compiled '
        'with. Check that the four TAYTAY_FIREBASE_* values come from one '
        'app registered in one Firebase project (docs/release.md).',
      ),
    ]);
  }
  return config;
}

/// The SDK's options, built from the four values and nothing else.
FirebaseOptions firebaseOptionsFor(FirebaseClientConfig client) {
  return FirebaseOptions(
    apiKey: client.apiKey,
    appId: client.appId,
    messagingSenderId: client.messagingSenderId,
    projectId: client.projectId,
  );
}

Future<void> _initializeDefaultApp(FirebaseOptions options) async {
  await Firebase.initializeApp(options: options);
}
