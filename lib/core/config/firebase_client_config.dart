import 'package:flutter/foundation.dart';

/// The four values Firebase needs before a resident can sign in.
///
/// They come only from `--dart-define`, like every other build setting
/// (Article 7), usually through `--dart-define-from-file=env/firebase.<env>.json`.
/// There is no `google-services.json` and no default project (decision D-185).
///
/// They are **public project identifiers, not secrets** — the single named
/// exception in Article 5.4. They ship inside every Firebase client, and what
/// protects an account is Firebase Auth's own checks and the backend's
/// verification of the ID token. They are still never logged: [toString] and
/// [problems] name the defines, never a value.
///
/// This file knows nothing about the Firebase SDK. Turning these values into
/// options and starting Firebase happens once, in `app/firebase_startup.dart`.
@immutable
class FirebaseClientConfig {
  const FirebaseClientConfig({
    required this.apiKey,
    required this.appId,
    required this.projectId,
    required this.messagingSenderId,
    this.platform = '',
  });

  /// Reads the ambient `--dart-define` values for the platform this runs on.
  factory FirebaseClientConfig.resolve() {
    const String apiKey = String.fromEnvironment(apiKeyDefineKey);
    const String appId = String.fromEnvironment(appIdDefineKey);
    const String projectId = String.fromEnvironment(projectIdDefineKey);
    const String messagingSenderId = String.fromEnvironment(
      messagingSenderIdDefineKey,
    );
    return FirebaseClientConfig(
      apiKey: apiKey.trim(),
      appId: appId.trim(),
      projectId: projectId.trim(),
      messagingSenderId: messagingSenderId.trim(),
      platform: defaultTargetPlatform.name,
    );
  }

  /// `--dart-define` key: the Firebase Web API key of the project.
  static const String apiKeyDefineKey = 'TAYTAY_FIREBASE_API_KEY';

  /// `--dart-define` key: the Firebase app ID registered for this platform.
  static const String appIdDefineKey = 'TAYTAY_FIREBASE_APP_ID';

  /// `--dart-define` key: the Firebase project ID.
  static const String projectIdDefineKey = 'TAYTAY_FIREBASE_PROJECT_ID';

  /// `--dart-define` key: the project number, which Firebase calls the
  /// messaging sender ID.
  static const String messagingSenderIdDefineKey =
      'TAYTAY_FIREBASE_MESSAGING_SENDER_ID';

  /// All four keys, in the order a release engineer would read them.
  static const List<String> defineKeys = <String>[
    apiKeyDefineKey,
    appIdDefineKey,
    projectIdDefineKey,
    messagingSenderIdDefineKey,
  ];

  final String apiKey;
  final String appId;
  final String projectId;
  final String messagingSenderId;

  /// The platform this build runs on, as `TargetPlatform.name` spells it.
  /// Empty when the caller does not know, which skips the platform check.
  final String platform;

  /// What is wrong with these values, phrased for a release engineer.
  ///
  /// Empty means Firebase can be started. Each entry names defines, never
  /// their values.
  List<String> get problems {
    final List<String> missing = <String>[
      if (apiKey.trim().isEmpty) apiKeyDefineKey,
      if (appId.trim().isEmpty) appIdDefineKey,
      if (projectId.trim().isEmpty) projectIdDefineKey,
      if (messagingSenderId.trim().isEmpty) messagingSenderIdDefineKey,
    ];
    if (missing.isNotEmpty) {
      return <String>[
        'This build signs residents in through Firebase and was compiled '
            'without ${missing.join(', ')}. Pass all four with '
            '--dart-define-from-file=env/firebase.<environment>.json '
            '(docs/release.md). There is no default Firebase project.',
      ];
    }

    // An app ID reads `1:<project number>:<platform>:<hash>`. An Android app
    // ID on an iPhone starts cleanly and then fails inside the first sign-in,
    // which is the failure this class exists to move to startup.
    final List<String> parts = appId.split(':');
    final String registeredFor = parts.length == 4 ? parts[2] : '';
    final String runningOn = platform.toLowerCase();
    if (registeredFor.isNotEmpty &&
        runningOn.isNotEmpty &&
        registeredFor.toLowerCase() != runningOn) {
      return <String>[
        '$appIdDefineKey names a Firebase app registered for $registeredFor, '
            'and this build runs on $runningOn. Register a $runningOn app in '
            'the Firebase project and pass its app ID.',
      ];
    }
    return const <String>[];
  }

  bool get isComplete => problems.isEmpty;

  /// Deliberately says nothing about the values (Article 5.4).
  @override
  String toString() =>
      'FirebaseClientConfig(${isComplete ? 'complete' : 'incomplete'}, '
      'values redacted)';
}
