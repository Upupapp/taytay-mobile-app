import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/backend_baseline.dart';
import 'package:taytay_resident/core/api/backend_gap.dart';
import 'package:taytay_resident/core/api/planned_backend.dart';
import 'package:taytay_resident/core/api/unwired_repository.dart';

/// The half of the TAB 00 staleness guard that needs no network.
///
/// `tool/check_backend_baseline.sh` is the other half: it compares the committed
/// module table against the backend's own boundary map at the pinned tag, and so
/// catches the backend moving. This file catches *us* moving — an enum edited
/// without the document, or a document edited without the enum. Both directions
/// matter, because the original defect was a belief that no longer matched
/// anything and had nothing checking it.
void main() {
  final File doc = File('docs/integration/backend-baseline.md');
  final String text = doc.readAsStringSync();

  /// Rows of the first markdown table whose header contains [headerContains].
  List<List<String>> tableAfter(String headerContains) {
    final List<String> lines = text.split('\n');
    final int header = lines.indexWhere(
      (String l) => l.startsWith('|') && l.contains(headerContains),
    );
    expect(
      header,
      isNot(-1),
      reason: 'no table header matching $headerContains',
    );
    final List<List<String>> rows = <List<String>>[];
    for (int i = header + 2; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (!line.startsWith('|')) break;
      rows.add(
        line
            .split('|')
            .map((String c) => c.trim())
            .where((String c) => c.isNotEmpty)
            .toList(),
      );
    }
    return rows;
  }

  /// Markdown emphasis and code fences stripped, so `**planned**` reads as
  /// `planned` and `` `Identity` `` as `Identity`.
  String plain(String cell) => cell.replaceAll(RegExp(r'[*`]'), '').trim();

  group('the committed baseline document and the code agree', () {
    test(
      'the document names the tag, commit and date the code is pinned to',
      () {
        expect(text, contains(backendBaselineTag));
        expect(text, contains(backendBaselineCommit));
        expect(text, contains(backendBaselineDate));
      },
    );

    test('PlannedModule is exactly the modules the document calls planned', () {
      final List<String> planned = tableAfter('| Module | Built | Enabled |')
          .where((List<String> r) => plain(r[1]) == 'planned')
          .map((List<String> r) => plain(r[0]))
          .toList();

      // Two, and the document had better say so — a shrinking baseline is the
      // good direction, but an empty one means the table stopped being parsed.
      expect(
        planned,
        isNotEmpty,
        reason: 'module table parsed but found nothing planned',
      );
      expect(
        PlannedModule.values.map((PlannedModule m) => m.moduleName),
        unorderedEquals(planned),
      );
    });

    test('every BackendGap carries a finding the document raises', () {
      final Set<String> documented = tableAfter(
        '| ID | Sev | Finding |',
      ).map((List<String> r) => plain(r[0])).toSet();

      for (final BackendGap gap in BackendGap.values) {
        expect(
          documented,
          contains(gap.finding),
          reason:
              '${gap.name} cites ${gap.finding}, which the document does not raise',
        );
      }
    });

    test('every UnwiredRepository appears in the work plan with its TAB', () {
      final List<List<String>> plan = tableAfter(
        '| Repository | Module | Endpoints |',
      );
      expect(plan, isNotEmpty);
      final String planText = plan
          .map((List<String> r) => r.join(' '))
          .join('\n');

      for (final UnwiredRepository repository in UnwiredRepository.values) {
        // The TAB is the point: a repository listed with no owner is a backlog
        // entry nobody has, which is how the first stubs outlived their reason.
        expect(
          repository.wiredBy,
          matches(RegExp(r'TAB \d\d')),
          reason: '${repository.name} names no indexed TAB',
        );
        for (final String tab in RegExp(
          r'TAB \d\d',
        ).allMatches(repository.wiredBy).map((RegExpMatch m) => m.group(0)!)) {
          expect(
            planText,
            contains(tab),
            reason:
                '${repository.name} is wired by $tab, absent from the work plan',
          );
        }
      }
    });

    test('no repository claims a module the document calls planned', () {
      // The F17 class: a stub that survives the enum shrink because the name it
      // references still exists. `Verification` and `ServiceDelivery` are real
      // modules and no repository here belongs to either.
      final Set<String> planned = PlannedModule.values
          .map((PlannedModule m) => m.moduleName)
          .toSet();

      for (final UnwiredRepository repository in UnwiredRepository.values) {
        for (final String module in planned) {
          expect(
            repository.module.split(RegExp(r'[ ·+(]')),
            isNot(contains(module)),
            reason:
                '${repository.name} claims $module, which is planned — either the '
                'module shipped and the baseline needs re-deriving, or this is a '
                'mis-attribution of the kind F17 records',
          );
        }
      }
    });
  });
}
