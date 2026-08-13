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
        RegExp(r'''(?:password|passwd|secret|api[_-]?key|apikey)\s*[:=]\s*['"][^'"]{6,}['"]''', caseSensitive: false),
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
        'lib/core/session/session_state.dart': <String>['accountId', 'displayName'],
        'lib/core/session/session_store.dart': <String>['accessToken'],
        'lib/core/api/request_context.dart': <String>['bearerToken'],
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
    test('no request header or body claims a role, permission or admin flag', () {
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
    });

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
