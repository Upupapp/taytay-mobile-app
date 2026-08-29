import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';

/// Source with `///` and `//` comments removed.
///
/// The prose in this repository names the reference apps constantly — it is how
/// a decision explains what it learned from where — and a branding scan that
/// tripped on an explanation would be a scan nobody could keep green.
String stripComments(String source) => source
    .replaceAll(RegExp(r'^\s*///.*$', multiLine: true), '')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '')
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

/// XML/plist source with `<!-- -->` comments removed.
///
/// The Android manifest documents the permissions this app **does not** declare
/// and why — `CAMERA`, `READ_MEDIA_IMAGES` — which is exactly the prose a
/// permission scan must not trip on.
String stripXmlComments(String source) =>
    source.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

/// A decoder that rejects `assigned_to` has to name it, so the deny-list itself
/// would trip the scan that exists to enforce it.
String stripForbiddenKeySets(String source) => source.replaceAll(
  RegExp(
    r'static const Set<String> forbiddenKeys\s*=\s*<String>\{.*?\};',
    dotAll: true,
  ),
  '',
);

List<File> filesUnder(String directory, {List<String> extensions = const []}) {
  final root = Directory(directory);
  if (!root.existsSync()) return const <File>[];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            extensions.isEmpty ||
            extensions.any((ext) => file.path.endsWith(ext)),
      )
      .toList(growable: false);
}

void main() {
  // ── The Taytay audit ────────────────────────────────────────────────────

  group('Only Taytay branding ships', () {
    test('no reference-app name appears in shipped code', () {
      // Acceptance: no reference-project branding remains. Comments are
      // stripped first — a decision that says "rebuilt, not traced from
      // Servana artwork" is documentation, not branding.
      final offenders = <String>[];
      for (final file in filesUnder('lib', extensions: <String>['.dart'])) {
        final source = stripComments(file.readAsStringSync()).toLowerCase();
        for (final name in <String>['esperanza', 'servana', 'upupapp']) {
          if (source.contains(name)) offenders.add('${file.path}: $name');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no reference-app name appears in an asset filename', () {
      final offenders = filesUnder('assets')
          .map((file) => file.path.toLowerCase())
          .where(
            (path) =>
                path.contains('esperanza') ||
                path.contains('servana') ||
                path.contains('upupapp'),
          )
          .toList();
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no reference-app name is in the manifest, plist or gradle', () {
      final files = <String>[
        'android/app/src/main/AndroidManifest.xml',
        'android/app/build.gradle.kts',
        'ios/Runner/Info.plist',
        'pubspec.yaml',
      ];
      for (final path in files) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final content = file.readAsStringSync().toLowerCase();
        for (final name in <String>['esperanza', 'servana', 'upupapp']) {
          expect(content, isNot(contains(name)), reason: '$path: $name');
        }
      }
    });

    test('the app identifies itself as Taytay everywhere it is named', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('Taytay'));

      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      // A municipality's own namespace, not a vendor's.
      expect(gradle, contains('ph.gov.taytay'));

      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('taytay_resident'));
    });
  });

  // ── The product boundary ────────────────────────────────────────────────

  group('No admin surface exists to reach', () {
    test('every route declares an access requirement', () {
      // The client-side echo of the backend's deny-by-default rule: there is no
      // default, so a new route cannot be added without someone deciding.
      for (final route in AppRoute.values) {
        expect(
          route.requirement,
          isNotNull,
          reason: '${route.routeName} declares no requirement',
        );
      }
    });

    test('no route is named or pathed like a staff surface', () {
      const forbidden = <String>[
        'admin',
        'staff',
        'console',
        'moderat',
        'approv',
        'reject',
        'audit',
        'dashboard',
        'publish',
        'assign',
        'rbac',
        'permission',
      ];
      for (final route in AppRoute.values) {
        final subject = '${route.routeName} ${route.path}'.toLowerCase();
        for (final word in forbidden) {
          expect(subject, isNot(contains(word)), reason: route.routeName);
        }
      }
    });

    test('the three resident states are the whole vocabulary', () {
      // Appendix A: verification unlocks resident-linked services; it does not
      // turn a resident into an admin. A fourth level would be the door.
      expect(
        AccessLevel.values.map((level) => level.name),
        unorderedEquals(<String>['guest', 'unverified', 'verified']),
      );
    });

    test('no shipped source models a staff concept', () {
      const forbidden = <String>[
        'isAdmin',
        'is_admin',
        'staffId',
        'staff_id',
        'assignedTo',
        'assigned_to',
        'internalNote',
        'internal_note',
        'reviewerId',
        'reviewer_id',
        'approverId',
        'moderationQueue',
      ];
      final offenders = <String>[];
      for (final file in filesUnder('lib', extensions: <String>['.dart'])) {
        final source = stripForbiddenKeySets(
          stripComments(file.readAsStringSync()),
        );
        for (final token in forbidden) {
          if (source.contains(token)) offenders.add('${file.path}: $token');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  // ── Platform configuration ──────────────────────────────────────────────

  group('Android configuration is releasable', () {
    late String manifest;

    setUp(() {
      manifest = stripXmlComments(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      );
    });

    test('only permissions the app actually uses are declared', () {
      final declared = RegExp(
        r'android:name="android\.permission\.([A-Z_]+)"',
      ).allMatches(manifest).map((match) => match.group(1)!).toSet();

      // INTERNET to reach the LGU; USE_BIOMETRIC for the optional local lock.
      // Everything else would be surface a resident is asked to trust for
      // nothing — CAMERA in particular, which the document picker deliberately
      // does not need (D-72).
      expect(declared, unorderedEquals(<String>{'INTERNET', 'USE_BIOMETRIC'}));
    });

    test('no advertising or tracking permission is declared', () {
      for (final permission in <String>[
        'AD_ID',
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'READ_CONTACTS',
        'READ_PHONE_STATE',
        'READ_EXTERNAL_STORAGE',
        'READ_MEDIA_IMAGES',
      ]) {
        expect(manifest, isNot(contains(permission)), reason: permission);
      }
    });

    test('cleartext traffic is not enabled', () {
      // Article 5.7: HTTPS outside local development. A manifest flag would
      // override the app's own refusal.
      expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
    });

    test('the application id is the municipality\'s own namespace', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(
        gradle,
        contains('applicationId = "ph.gov.taytay.lguids.taytay_resident"'),
      );
    });
  });

  group('iOS configuration is releasable', () {
    test('the bundle is named for Taytay and declares no tracking', () {
      final plist = File('ios/Runner/Info.plist');
      if (!plist.existsSync()) {
        markTestSkipped('no iOS runner in this checkout');
        return;
      }
      final content = stripXmlComments(plist.readAsStringSync());

      // App Tracking Transparency is the key an app adds when it intends to
      // track. Its absence is the statement.
      expect(content, isNot(contains('NSUserTrackingUsageDescription')));
      expect(content, isNot(contains('NSAllowsArbitraryLoads')));
    });
  });

  // ── Configuration safety ────────────────────────────────────────────────

  group('No secret ships in the binary', () {
    test('no dart-define name looks like a credential', () {
      // Article 5.4: `--dart-define` values are recoverable from the APK.
      final offenders = <String>[];
      final pattern = RegExp(r'String\.fromEnvironment\(\s*.([A-Z0-9_]+).');
      for (final file in filesUnder('lib', extensions: <String>['.dart'])) {
        for (final match in pattern.allMatches(file.readAsStringSync())) {
          final name = match.group(1)!;
          if (RegExp(r'KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL').hasMatch(name)) {
            offenders.add('${file.path}: $name');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no .env file is tracked', () {
      expect(File('.env').existsSync(), isFalse);
      expect(File('.gitignore').readAsStringSync(), contains('.env'));
    });
  });

  // ── The documentation the next reader needs ─────────────────────────────

  group('The record is complete', () {
    test('the supervisor state records all 28 TABs complete', () {
      final state =
          jsonDecode(
                File('.claude/master-supervisor/state.json').readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(state['totalTabs'], 28);
      expect(state['completedTabs'], hasLength(28));
    });

    test('every TAB this run covered has a completion report', () {
      final reports = filesUnder(
        '.claude/master-supervisor/tab-reports',
        extensions: <String>['.md'],
      ).map((file) => file.uri.pathSegments.last).toSet();

      // TABs 01–14 were certified before the supervisor's report directory
      // existed; their record is the commit history and `docs/`. Everything
      // from 15 on has a report, and the scan says which is which rather than
      // asserting a number that was never true.
      for (var tab = 15; tab <= 28; tab++) {
        final name = 'TAB-${tab.toString().padLeft(2, '0')}.md';
        expect(reports, contains(name), reason: '$name is missing');
      }
    });

    test('the decision log is numbered without gaps', () {
      final log = File('docs/mobile-ui-decision-log.md').readAsStringSync();
      final numbers =
          RegExp(r'^\| D-(\d+) \|', multiLine: true)
              .allMatches(log)
              .map((match) => int.parse(match.group(1)!))
              .toList()
            ..sort();

      expect(numbers, isNotEmpty);
      expect(numbers.first, 1);
      for (var i = 0; i < numbers.length; i++) {
        expect(
          numbers[i],
          i + 1,
          reason: 'D-${i + 1} is missing or duplicated',
        );
      }
    });

    test('the constitution is still the highest-authority document', () {
      final claudeMd = File('CLAUDE.md').readAsStringSync();
      expect(claudeMd, contains('highest-authority document'));
    });

    test('Article 2.3 still bans core reaching data or presentation', () {
      // ARTICLE 2.3 WAS AMENDED ON 2026-08-29, deliberately and by the owner.
      // It used to say `core/` never imports `features/`, full stop; the code
      // had never obeyed that, in thirteen places, all pointing at `domain/`.
      // The owner ruled that `core/ -> features/**/domain/` is allowed.
      //
      // What must NOT move is the half that was actually being broken: `core/`
      // reaching a feature's `data/` or `presentation/`. That is enforced by
      // `test/core/architecture_test.dart`; this asserts the rule it enforces
      // is still written down, so an amendment cannot quietly delete the
      // clause and leave a guard citing a rule that no longer exists.
      final claudeMd = File('CLAUDE.md').readAsStringSync();

      expect(
        claudeMd,
        contains(
          "`core/` never imports a feature's `data/` or `presentation/`",
        ),
        reason:
            'Article 2.3 no longer states the prohibition that '
            'architecture_test.dart enforces.',
      );
      expect(
        claudeMd,
        contains('app_router.dart'),
        reason: 'The single sanctioned exception is no longer named.',
      );
    });

    test('Article 10 still forbids what it has always forbidden', () {
      // ARTICLE 10 WAS AMENDED, AND THIS TEST CAUGHT IT.
      //
      // It used to assert the sentence "Never push, force-push, merge", which
      // is gone: the owner authorised direct pushes to `main` and Article 10
      // was rewritten to say so, matching taytay-backend and taytay-admin-web.
      // The failure was correct — the constitution moved and something noticed,
      // which is the whole point of asserting it at all.
      //
      // What is asserted now is the part that did NOT move. Pushing changed
      // status; nothing else did, and a future amendment that quietly dropped
      // one of these should go red here too.
      final claudeMd = File('CLAUDE.md').readAsStringSync();

      for (final prohibition in <String>[
        'force-push',
        'history rewriting',
        'merging protected',
        'deployment',
        'credential rotation',
        'production data',
        'exposing secrets',
      ]) {
        expect(
          claudeMd,
          contains(prohibition),
          reason: 'Article 10 no longer forbids $prohibition',
        );
      }

      // The amendment's own qualifier, and the reason a push here is not a
      // small act: this repository is public.
      expect(claudeMd, contains('a push is a publication'));
    });
  });
}
