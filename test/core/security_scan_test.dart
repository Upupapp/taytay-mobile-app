import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level guards over the whole app.
///
/// These are cheap, blunt and catch the mistakes that code review misses because
/// they look ordinary in a diff: a token logged "just while debugging", a
/// dependency on plain preferences, a hard-coded credential.
///
/// Comments are stripped before scanning, so prose *describing* a rule does not
/// trip the rule it describes.
String stripComments(String source) {
  final withoutBlocks = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  return withoutBlocks
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

/// Removes `forbiddenKeys` declarations before scanning.
///
/// A decoder that rejects `household_members` has to name it, so the deny-list
/// itself trips the scan that exists to enforce it. Prose describing a rule is
/// already stripped by [stripComments]; this does the same for the one code
/// construct whose whole purpose is to enumerate what must never appear.
String stripForbiddenKeySets(String source) => source.replaceAll(
  RegExp(
    r'static const Set<String> forbiddenKeys\s*=\s*<String>\{.*?\};',
    dotAll: true,
  ),
  '',
);

List<File> dartFiles(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);

void main() {
  group('secret and credential storage', () {
    test('no plain-preferences dependency is declared', () {
      // CLAUDE.md Article 5.3: credential material belongs in the platform
      // keystore. `shared_preferences` is unencrypted XML on Android, readable
      // over ADB backup and on a rooted device.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        pubspec,
        isNot(contains('shared_preferences')),
        reason:
            'Plain preferences must not enter the dependency tree; use '
            'SecretStore for anything sensitive.',
      );
      expect(pubspec, contains('flutter_secure_storage'));
    });

    test('no source file references plain preferences', () {
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripComments(file.readAsStringSync());
        if (source.contains('SharedPreferences') ||
            source.contains('shared_preferences')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('only the keystore layer touches the secure-storage plugin', () {
      // Keeps the credential surface to one reviewable file.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripComments(file.readAsStringSync());
        if (!source.contains('flutter_secure_storage')) continue;
        final path = file.path.replaceAll(r'\', '/');
        if (!path.endsWith('core/storage/secure_secret_store.dart')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no hard-coded credential literals in lib/', () {
      final patterns = <RegExp>[
        RegExp(
          r'''(?:password|passwd|secret|api[_-]?key|apikey)\s*[:=]\s*['"][^'"]{6,}['"]''',
          caseSensitive: false,
        ),
        RegExp(r'''Bearer\s+[A-Za-z0-9\-._~+/]{20,}'''),
        RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
      ];

      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripComments(file.readAsStringSync());
        for (final pattern in patterns) {
          if (pattern.hasMatch(source)) {
            offenders.add('${file.path}: ${pattern.pattern}');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('only one file talks to the biometric plugin', () {
      // Same rule as the keystore: the surface that can raise a platform
      // identity prompt stays in one reviewable file, so nobody can quietly
      // start using a local unlock as though it authenticated somebody.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripComments(file.readAsStringSync());
        if (!source.contains('package:local_auth/')) continue;
        final path = file.path.replaceAll(r'\', '/');
        if (!path.endsWith('core/session/local_authenticator.dart')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no local unlock result is ever sent to the server', () {
      // A local unlock is a statement a device makes to itself. Putting it in a
      // request would invite the server — or a future reader — to treat it as
      // proof of identity, which it is not.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        if (!path.contains('/data/') && !path.contains('core/api/')) continue;
        final source = stripComments(file.readAsStringSync());
        for (final token in <String>[
          'LocalUnlockOutcome',
          'biometric',
          'appLockEnabled',
        ]) {
          if (source.contains(token)) offenders.add('$path: $token');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no source file invents a token refresh endpoint', () {
      // The committed contract publishes none. A path here would be a contract
      // the server never agreed to. See `core/api/auth_coordinator.dart`.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripComments(file.readAsStringSync());
        for (final pattern in <RegExp>[
          RegExp(r'''['"][^'"]*auth/refresh[^'"]*['"]'''),
          RegExp(r"""['"]refresh_token['"]"""),
        ]) {
          if (pattern.hasMatch(source)) {
            offenders.add('${file.path}: ${pattern.pattern}');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no .env file is present or referenced', () {
      expect(
        File('.env').existsSync(),
        isFalse,
        reason: 'Configuration reaches the app through --dart-define.',
      );
      final gitignore = File('.gitignore').readAsStringSync();
      expect(gitignore, contains('.env'));
    });
  });

  group('logging and PII', () {
    test('no print or debugPrint in lib/', () {
      // `avoid_print` is enforced by the analyzer, but debugPrint is not, and
      // device logs are readable by any app-adjacent tooling.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripComments(file.readAsStringSync());
        if (RegExp(r'\bprint\s*\(').hasMatch(source) ||
            source.contains('debugPrint(')) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('session and credential types redact their toString', () {
      // A type that ends up in a log line must not carry the token, the account
      // id or the resident's name.
      final checks = <String, List<String>>{
        'lib/core/session/session_state.dart': <String>[
          'accountId',
          'displayName',
        ],
        'lib/core/session/session_store.dart': <String>['accessToken'],
        'lib/core/api/request_context.dart': <String>['bearerToken'],
        // TAB 09: the two objects that now hold a token or a mobile number.
        'lib/features/auth/domain/auth_repository.dart': <String>[
          'accessToken',
          'accountId',
        ],
        'lib/features/auth/presentation/sign_in_controller.dart': <String>[
          'mobileNumber',
          '_mobileNumber',
          'code',
        ],
        'lib/features/auth/domain/device_session_repository.dart': <String>[
          'label',
          'id',
        ],
      };

      checks.forEach((path, forbidden) {
        final source = File(path).readAsStringSync();
        final match = RegExp(
          r'String toString\(\) =>(.*?);',
          dotAll: true,
        ).allMatches(source);
        expect(match, isNotEmpty, reason: '$path has no toString to check');

        for (final toString in match) {
          for (final field in forbidden) {
            expect(
              toString.group(1),
              isNot(contains('\$$field')),
              reason: '$path interpolates $field into toString',
            );
          }
        }
      });
    });

    test('registration types never render their contents', () {
      // A draft and an upload descriptor are the two objects in this app most
      // likely to reach a crash report while holding identity data.
      for (final path in <String>[
        'lib/features/registration/domain/registration_domain.dart',
      ]) {
        final source = File(path).readAsStringSync();
        for (final match in RegExp(
          r'String toString\(\) =>(.*?);',
          dotAll: true,
        ).allMatches(source)) {
          final body = match.group(1)!;
          for (final field in <String>[
            'givenName',
            'familyName',
            'middleName',
            'birthDate',
            'mobileNumber',
            'streetAddress',
            'localReference',
          ]) {
            expect(
              body,
              isNot(contains('\$$field')),
              reason: '$path interpolates $field into toString',
            );
          }
        }
      }
    });

    test('no identity image bytes are held or logged anywhere', () {
      // The upload seam carries a reference, a size and a MIME type — never the
      // image itself. Backend gap G-18 leaves the upload contract unspecified,
      // so this build must not be holding pixels it cannot send.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'', '/');
        if (!path.contains('/registration/')) continue;
        final source = stripComments(file.readAsStringSync());
        if (source.contains('Uint8List') ||
            source.contains('dart:io') ||
            source.contains('File(')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no domain type outside data/ parses raw JSON maps', () {
      // CLAUDE.md Article 2.4: the wire format stops at the data layer.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        if (!path.contains('/domain/')) continue;
        final source = stripComments(file.readAsStringSync());
        if (source.contains('jsonDecode') || source.contains('fromJson')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('authority-shaped values', () {
    test(
      'no request header or body claims a role, permission or admin flag',
      () {
        // ADR 0002 §4: such values are ignored server-side, and sending them
        // invites a future reader to believe they matter.
        final forbidden = <RegExp>[
          RegExp(r"""['"]X-Client-Role['"]""", caseSensitive: false),
          RegExp(r"""['"]X-.*-Permissions?['"]""", caseSensitive: false),
          RegExp(r"""['"]is_admin['"]"""),
          RegExp(r"""['"]role['"]\s*:"""),
        ];

        final offenders = <String>[];
        for (final file in dartFiles('lib')) {
          final source = stripComments(file.readAsStringSync());
          for (final pattern in forbidden) {
            if (pattern.hasMatch(source)) {
              offenders.add('${file.path}: ${pattern.pattern}');
            }
          }
        }
        expect(offenders, isEmpty, reason: offenders.join('\n'));
      },
    );

    test('the client channel is sent exactly once, from one place', () {
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        final source = stripComments(file.readAsStringSync());
        if (!source.contains('X-Client-Channel')) continue;
        if (!path.endsWith('core/api/request_context.dart')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('navigation and deep links', () {
    test('access is decided in one place, not by scattered level checks', () {
      // TAB 10 centralised this. A screen comparing access levels itself is how
      // two parts of the app come to disagree about who may see what — and the
      // one that is wrong is always the one nobody tested.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        // The centralised deciders, and the session model itself.
        if (path.contains('core/session/')) continue;
        // Serialisation, not a decision: the keystore writes the server's tier
        // vocabulary rather than this build's enum index, so that an app update
        // reordering the enum cannot promote a stored session.
        if (path.endsWith('core/storage/keystore_session_store.dart')) continue;
        // The gate sheet and the tiles that render a verdict may name levels in
        // their copy switch; they take no access decision of their own.
        if (path.endsWith('shared/widgets/access_gate_sheet.dart')) continue;

        final source = stripComments(file.readAsStringSync());
        for (final pattern in <RegExp>[
          // `if (level == AccessLevel.verified)` and friends.
          RegExp(r'(if|while)\s*\([^)]*AccessLevel\.\w+\s*[!=]='),
          RegExp(r'\.accessLevel\s*[!=]=\s*AccessLevel\.'),
          RegExp(r'\.isAuthenticated\s*\?'),
        ]) {
          if (pattern.hasMatch(source)) {
            offenders.add('$path: ${pattern.pattern}');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no screen builds a route path by string concatenation', () {
      // Routes are named or built through `AppRoute.location`, which encodes its
      // parameters. A concatenated path is how an identifier ends up carrying a
      // segment of its own.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        if (path.contains('core/router/')) continue;
        final source = stripComments(file.readAsStringSync());
        if (RegExp(r"""go\(\s*['"]/[^'"]*\$""").hasMatch(source)) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no personal data is put into a link or a route parameter', () {
      // A notification is stored by the OS, shown on a lock screen and often
      // mirrored to a watch. Anything readable there has been disclosed to
      // whoever is standing nearby.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        final source = stripComments(file.readAsStringSync());
        if (!source.contains('pathParameters') &&
            !source.contains('queryParameters')) {
          continue;
        }
        for (final field in <String>[
          'displayName',
          'mobileNumber',
          'birthDate',
          'accountId',
          'philsys',
          'address',
        ]) {
          if (RegExp('pathParameters[^;]*$field').hasMatch(source) ||
              RegExp('queryParameters[^;]*$field').hasMatch(source)) {
            offenders.add('$path: $field');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('cross-resident data', () {
    test('no source file names another resident on the wire', () {
      // The committed client-visibility matrix calls cross-resident access "a
      // critical defect" and names `Household.members` specifically. These
      // shapes are how it would arrive: a member list, a relative list, or a
      // request that takes somebody else's identifier.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        final source = stripForbiddenKeySets(
          stripComments(file.readAsStringSync()),
        ).split('\n').where((l) => !l.trimLeft().startsWith('///')).join('\n');

        for (final pattern in <RegExp>[
          RegExp(r'class\s+HouseholdMember'),
          RegExp(r"""['"]household_members['"]"""),
          RegExp(r"""['"]members['"]\s*:"""),
          RegExp(r'\bresidentId\b'),
          RegExp(r'\bhouseholdId\b'),
        ]) {
          if (pattern.hasMatch(source)) {
            offenders.add('$path: ${pattern.pattern}');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no vulnerability or casework field is modelled anywhere', () {
      // `sectors` is where `vawc-survivor` and `cicl` live; the backend omits
      // those values server-side rather than masking them, and a field this app
      // does not model is a field it cannot render.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        final source = stripForbiddenKeySets(
          stripComments(file.readAsStringSync()),
        ).split('\n').where((l) => !l.trimLeft().startsWith('///')).join('\n');

        for (final field in <String>[
          'vulnerabilityScore',
          'riskScore',
          'isIndigent',
          'monthlyIncome',
          'caseworkerNotes',
          'sensitiveSectors',
        ]) {
          if (RegExp('\\b$field\\b').hasMatch(source)) {
            offenders.add('$path: $field');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('eligibility and catalogue', () {
    test('no source file computes eligibility or promises an outcome', () {
      // Acceptance 2 of the directory TAB, enforced app-wide rather than in one
      // feature. A local eligibility rule is a second rule set: it drifts from
      // the office's the moment either changes, it is wrong in a released build
      // nobody can patch quickly, and it tells residents they do not qualify
      // for benefits they are entitled to — at which point they stop asking.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripComments(
          file.readAsStringSync(),
        ).split('\n').where((l) => !l.trimLeft().startsWith('///')).join('\n');

        for (final pattern in <RegExp>[
          RegExp(r'\bisEligible\b'),
          RegExp(r'\bcanApply\b'),
          RegExp(r'\bqualifies\b'),
          RegExp(r'\bcomputeEligibility\b'),
          RegExp(r'\bapprovalChance\b'),
          RegExp(r'\bincomeCeiling\b'),
        ]) {
          if (pattern.hasMatch(source)) {
            offenders.add('${file.path}: ${pattern.pattern}');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no source file models capacity, quota or ranking', () {
      // None of it is in the citizen projection. A remaining-slots figure on a
      // municipal benefit is the fastest way to start a queue at 4am for
      // something that was never first-come-first-served.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final source = stripForbiddenKeySets(
          stripComments(file.readAsStringSync()),
        ).split('\n').where((l) => !l.trimLeft().startsWith('///')).join('\n');

        for (final field in <String>[
          'slotsRemaining',
          'budgetRemaining',
          'beneficiaryCount',
          'priorityScore',
          'queuePosition',
          'fundingSource',
        ]) {
          if (RegExp('\\b$field\\b').hasMatch(source)) {
            offenders.add('${file.path}: $field');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('transport safety', () {
    test('no absolute API URL is hard-coded outside configuration', () {
      // Every call goes through AppConfig.apiBaseUri, so an environment is
      // never bypassed by a stray literal.
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        if (path.endsWith('core/config/app_config.dart')) continue;
        final source = stripComments(file.readAsStringSync());
        if (RegExp(r'''['"]https?://[^'"]+['"]''').hasMatch(source)) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('only the transport layer imports the HTTP package', () {
      final offenders = <String>[];
      for (final file in dartFiles('lib')) {
        final path = file.path.replaceAll(r'\', '/');
        final source = file.readAsStringSync();
        if (!source.contains('package:http/http.dart')) continue;
        if (!path.endsWith('core/api/http_api_transport.dart')) {
          offenders.add(path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });
}
