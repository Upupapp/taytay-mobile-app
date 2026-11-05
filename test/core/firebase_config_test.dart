import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/firebase_startup.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/config/firebase_client_config.dart';

// Synthetic, shaped like Firebase values and belonging to no project.
const String _apiKey = 'synthetic-firebase-api-key-0000';
const String _appId = '1:000000000000:android:0000000000000000';
const String _projectId = 'taytay-synthetic-0000';
const String _senderId = '000000000000';

FirebaseClientConfig _client({
  String apiKey = _apiKey,
  String appId = _appId,
  String projectId = _projectId,
  String senderId = _senderId,
  String platform = 'android',
}) => FirebaseClientConfig(
  apiKey: apiKey,
  appId: appId,
  projectId: projectId,
  messagingSenderId: senderId,
  platform: platform,
);

AppConfig _config({
  String environment = 'staging',
  String baseUrl = 'https://api.example.test/api/v1',
  bool release = true,
  String data = '',
}) => AppConfig.from(
  rawEnvironment: environment,
  rawApiBaseUrl: baseUrl,
  isReleaseBuild: release,
  rawDataMode: data,
);

String _messages(AppConfig config) =>
    config.issues.map((ConfigIssue issue) => issue.message).join('\n');

/// No value may reach a message, a `toString`, or a log line (Article 5.4).
void _expectNoValues(String text) {
  for (final String value in <String>[_apiKey, _appId, _projectId]) {
    expect(text, isNot(contains(value)));
  }
}

void main() {
  group('FirebaseClientConfig', () {
    test('all four values make a complete configuration', () {
      final FirebaseClientConfig client = _client();
      expect(client.problems, isEmpty);
      expect(client.isComplete, isTrue);
    });

    test('each missing value is named, and only the missing ones', () {
      final Map<String, FirebaseClientConfig> partial =
          <String, FirebaseClientConfig>{
            FirebaseClientConfig.apiKeyDefineKey: _client(apiKey: ''),
            FirebaseClientConfig.appIdDefineKey: _client(appId: ''),
            FirebaseClientConfig.projectIdDefineKey: _client(projectId: ''),
            FirebaseClientConfig.messagingSenderIdDefineKey: _client(
              senderId: '',
            ),
          };
      for (final MapEntry<String, FirebaseClientConfig> entry
          in partial.entries) {
        final String problems = entry.value.problems.join('\n');
        expect(entry.value.isComplete, isFalse, reason: entry.key);
        expect(problems, contains(entry.key));
        for (final String other in FirebaseClientConfig.defineKeys) {
          if (other == entry.key) continue;
          expect(problems, isNot(contains(other)), reason: entry.key);
        }
        _expectNoValues(problems);
      }
    });

    test('none given names all four', () {
      final String problems = _client(
        apiKey: '',
        appId: '',
        projectId: '',
        senderId: '',
      ).problems.join('\n');
      for (final String key in FirebaseClientConfig.defineKeys) {
        expect(problems, contains(key));
      }
    });

    test('a value of only spaces is missing', () {
      expect(_client(projectId: '   ').isComplete, isFalse);
    });

    test('an Android app ID is refused on iOS, by name, before sign-in', () {
      final FirebaseClientConfig onIos = _client(platform: 'iOS');
      expect(onIos.isComplete, isFalse);
      expect(onIos.problems.join(), contains('registered for android'));
      expect(onIos.problems.join(), contains('runs on ios'));
      _expectNoValues(onIos.problems.join());

      expect(_client(platform: 'android').isComplete, isTrue);
      expect(_client(platform: '').isComplete, isTrue);
    });

    test('toString carries no value', () {
      _expectNoValues(_client().toString());
      _expectNoValues(_client(apiKey: '').toString());
    });
  });

  group('AppConfig.withFirebase', () {
    test('staging and production refuse to start without the values', () {
      for (final String environment in <String>['staging', 'prod']) {
        final AppConfig config = _config(environment: environment).withFirebase(
          _client(apiKey: '', appId: '', projectId: '', senderId: ''),
        );
        expect(config.isUsable, isFalse, reason: environment);
        expect(config.firebase, isNull);
        expect(
          _messages(config),
          contains(FirebaseClientConfig.apiKeyDefineKey),
        );
      }
    });

    test('a partial set refuses, naming what is missing', () {
      final AppConfig config = _config().withFirebase(_client(appId: ''));
      expect(config.isUsable, isFalse);
      expect(_messages(config), contains(FirebaseClientConfig.appIdDefineKey));
      _expectNoValues(_messages(config));
    });

    test('a complete set is usable and carries the values', () {
      final AppConfig config = _config().withFirebase(_client());
      expect(config.isUsable, isTrue, reason: _messages(config));
      expect(config.firebase, isNotNull);
      expect(config.firebase?.projectId, _projectId);
      _expectNoValues(config.toString());
    });

    test('a dev debug build on the live API uses the real identity too', () {
      final AppConfig config =
          _config(environment: 'dev', baseUrl: '', release: false).withFirebase(
            _client(apiKey: '', appId: '', projectId: '', senderId: ''),
          );
      expect(config.signsInWithFirebase, isTrue);
      expect(config.isUsable, isFalse);
    });

    test('a dev mock never holds the values, given or not', () {
      for (final FirebaseClientConfig client in <FirebaseClientConfig>[
        _client(),
        _client(apiKey: '', appId: '', projectId: '', senderId: ''),
      ]) {
        final AppConfig config = _config(
          environment: 'dev',
          baseUrl: '',
          release: false,
          data: 'mock',
        ).withFirebase(client);
        expect(config.signsInWithFirebase, isFalse);
        expect(config.isUsable, isTrue, reason: _messages(config));
        expect(config.usesMockData, isTrue);
        expect(config.firebase, isNull);
      }
    });

    test('every problem is reported at once, not one build at a time', () {
      final AppConfig config = _config(baseUrl: '')
          .withFirebase(_client(senderId: ''));
      expect(_messages(config), contains(AppConfig.apiBaseUrlDefineKey));
      expect(
        _messages(config),
        contains(FirebaseClientConfig.messagingSenderIdDefineKey),
      );
      expect(config.firebase, isNull);
    });
  });

  group('startFirebase', () {
    test('a dev mock never initialises Firebase', () async {
      var calls = 0;
      final AppConfig mock = _config(
        environment: 'dev',
        baseUrl: '',
        release: false,
        data: 'mock',
      ).withFirebase(_client());

      final AppConfig started = await startFirebase(
        mock,
        initialize: (FirebaseOptions options) async {
          calls++;
        },
      );

      expect(calls, 0);
      expect(identical(started, mock), isTrue);
    });

    test('a refused configuration never initialises Firebase', () async {
      var calls = 0;
      final AppConfig refused = _config().withFirebase(_client(apiKey: ''));

      await startFirebase(
        refused,
        initialize: (FirebaseOptions options) async {
          calls++;
        },
      );

      expect(calls, 0);
    });

    test(
      'a complete live build initialises once, with the four values',
      () async {
        final List<FirebaseOptions> seen = <FirebaseOptions>[];
        final AppConfig live = _config().withFirebase(_client());

        final AppConfig started = await startFirebase(
          live,
          initialize: (FirebaseOptions options) async {
            seen.add(options);
          },
        );

        expect(started.isUsable, isTrue);
        expect(seen, hasLength(1));
        expect(seen.single.apiKey, _apiKey);
        expect(seen.single.appId, _appId);
        expect(seen.single.projectId, _projectId);
        expect(seen.single.messagingSenderId, _senderId);
      },
    );

    test(
      'a failed start stops the build, and quotes nothing it was given',
      () async {
        final AppConfig started = await startFirebase(
          _config().withFirebase(_client()),
          initialize: (FirebaseOptions options) async {
            throw StateError('bad options ${options.apiKey}');
          },
        );

        expect(started.isUsable, isFalse);
        expect(started.firebase, isNull);
        expect(_messages(started), contains('Firebase did not start'));
        _expectNoValues(_messages(started));
      },
    );
  });

  group('wiring', () {
    test('main starts Firebase from the resolved configuration', () {
      final String main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('startFirebase(AppConfig.resolve())'));
    });

    test('only the startup seam calls Firebase.initializeApp', () {
      final List<String> callers = <String>[];
      for (final File file in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        if (file.readAsStringSync().contains('Firebase.initializeApp')) {
          callers.add(file.path.replaceAll(r'\', '/'));
        }
      }
      expect(callers, <String>['lib/app/firebase_startup.dart']);
    });

    test('real Firebase values are never tracked; only the example is', () {
      final String ignore = File('.gitignore').readAsStringSync();
      expect(ignore, contains('/env/firebase.*.json'));
      expect(ignore, contains('!/env/firebase.example.json'));

      final String example = File('env/firebase.example.json')
          .readAsStringSync();
      for (final String key in FirebaseClientConfig.defineKeys) {
        expect(example, contains('"$key": ""'));
      }
    });
  });
}
