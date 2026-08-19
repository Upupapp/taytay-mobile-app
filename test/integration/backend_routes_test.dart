import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/backend_routes.dart';

/// The half of the route guard that needs no backend clone.
///
/// `tool/check_backend_routes.sh` is the other half: it asserts every declared
/// route exists in the backend at the pinned baseline, and so catches the
/// contract moving. This file catches *us* moving — a call added without a
/// declaration, or a declaration left behind by a call that was deleted.
///
/// It reads the source rather than the running app on purpose. A route is a
/// fact about the code, and a test that exercised the repositories would prove
/// only that the ones it happened to call were declared.
void main() {
  /// Every `ApiClient.send` call in `lib/`, as `METHOD path` with parameters
  /// normalised to `{}`.
  ///
  /// Path segments are interpolated (`'$path/$id/read'`) and the leading part is
  /// usually a `static const String path` on the repository, so each file's own
  /// constants are resolved before normalising. A `$` that resolves to nothing
  /// known becomes `{}`, which is what a path parameter is.
  Set<String> callsInSource() {
    final Set<String> found = <String>{};

    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final String source = entity.readAsStringSync();
      if (!source.contains('.send<')) continue;

      final Map<String, String> constants = <String, String>{};
      for (final RegExpMatch m in RegExp(
        r"static const String (\w+)\s*=\s*'([^']*)'",
      ).allMatches(source)) {
        constants[m.group(1)!] = m.group(2)!;
      }

      for (final RegExpMatch call in RegExp(r'\.send\s*<').allMatches(source)) {
        final int open = source.indexOf('(', call.end);
        if (open < 0) continue;

        // Balanced scan rather than a lazy regex: an argument list contains
        // closures with their own parentheses, and `.*?\)` stops at the first
        // one of those rather than at the end of the call.
        int depth = 0;
        int i = open;
        for (; i < source.length; i++) {
          if (source[i] == '(') depth++;
          if (source[i] == ')') {
            depth--;
            if (depth == 0) break;
          }
        }
        final String block = source.substring(open, i);

        final RegExpMatch? method = RegExp(
          r'method:\s*HttpMethod\.(\w+)',
        ).firstMatch(block);
        if (method == null) continue;

        final RegExpMatch? literal = RegExp(
          r"path:\s*'([^']*)'",
        ).firstMatch(block);
        final RegExpMatch? identifier = RegExp(
          r'path:\s*([A-Za-z_]\w*)\s*,',
        ).firstMatch(block);

        String? raw;
        if (literal != null) {
          raw = literal.group(1);
        } else if (identifier != null) {
          raw = constants[identifier.group(1)];
        }
        if (raw == null || raw.startsWith(r'\')) continue;

        final String path = raw.replaceAllMapped(
          RegExp(r'\$\{?(\w+)\}?'),
          (Match m) => constants[m.group(1)] ?? '{}',
        );

        found.add('${method.group(1)!.toUpperCase()} $path');
      }
    }

    return found;
  }

  final Set<String> declared = backendRoutes
      .map((BackendRoute r) => '${r.method} ${r.path}')
      .toSet();

  test('the parser finds routes at all', () {
    // A guard that parses nothing passes everything. This is the floor: if the
    // extraction breaks — a renamed client method, a new call style — the suite
    // must say so rather than reporting agreement between two empty sets.
    expect(
      callsInSource().length,
      greaterThanOrEqualTo(40),
      reason:
          'The source scan found almost nothing. The call shape it looks for '
          'has probably changed. Fix the scan; do not lower this number.',
    );
  });

  test('every route this app calls is declared', () {
    final Set<String> undeclared = callsInSource().difference(declared);

    expect(
      undeclared,
      isEmpty,
      reason:
          'These routes are called and not declared in backend_routes.dart:\n'
          '  ${undeclared.join('\n  ')}\n'
          'Declaring a route is how tool/check_backend_routes.sh learns to check '
          'it exists at the pinned baseline. That check is the one that would '
          'have caught C-09.',
    );
  });

  test('every declared route is actually called', () {
    final Set<String> uncalled = declared.difference(callsInSource());

    expect(
      uncalled,
      isEmpty,
      reason:
          'These routes are declared and never called:\n  ${uncalled.join('\n  ')}\n'
          'A declaration left behind by a deleted call is a route the guard '
          'keeps checking on behalf of nobody, and it makes the list read as '
          'larger than the surface actually is.',
    );
  });

  test('no route is declared twice', () {
    expect(
      declared.length,
      backendRoutes.length,
      reason:
          'Two rows in backendRoutes share a method and path. The duplicate '
          'hides which repository owns the call.',
    );
  });

  test('every exception names a route this app really calls', () {
    final Set<String> phantom = routesAheadOfBaseline.toSet().difference(
      declared,
    );

    expect(
      phantom,
      isEmpty,
      reason:
          'routesAheadOfBaseline names routes that are not in backendRoutes:\n'
          '  ${phantom.join('\n  ')}\n'
          'An exception for a call that no longer exists is an exception that '
          'never expires. Remove it in the same commit as the call.',
    );
  });

  test('the exception list is exactly the two C-09 routes', () {
    // Deliberately an equality rather than a ceiling. The count is two, both are
    // named in docs/frontend/open-work.md, and both close the same way — by
    // moving the baseline. A third entry is a different finding and must be
    // argued in a report, not appended here.
    expect(
      routesAheadOfBaseline.toSet(),
      <String>{'GET barangays', 'POST newsfeed-comments/{}/reports'},
      reason:
          'The set of routes ahead of the baseline changed. If one closed, the '
          'baseline moved and backend_baseline.dart must move with it. If one '
          'was added, read C-09 in docs/frontend/open-work.md before deciding '
          'this is acceptable.',
    );
  });
}
