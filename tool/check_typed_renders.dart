// Type-aware guard: no screen reads a localised enum's English constant.
//
// ## Why this is a tool script and not a test
//
// It was written as `test/core/typed_render_test.dart` first. Inside
// `flutter test` the analyzer cannot find the Dart SDK — `FolderBasedDartSdk`
// throws before any file is read — so it is run with `dart run`, from
// `tool/certify.sh`, alongside the other gates.
//
// That is a real trade: it does not run on a bare `flutter test`. It is stated
// here rather than left to be discovered, and `certify.sh` is the gate that
// matters before a push.
//
// ## What it does that the regex guard cannot
//
// `test/core/raw_enum_render_test.dart` sees a copy field read from a variable
// whose type is WRITTEN DOWN, and says so. This resolves types, so it also sees
// `final stage = _status?.stage;` then `stage.label`.
//
// It found TWO LIVE DEFECTS on its first run, both invisible to the regex:
//
//   * requirements_screen.dart:452 rendered the raw English
//     `rejection.residentMessage` when the refused file's size was unknown and
//     the localiser otherwise — the same banner in Filipino or English
//     depending on whether a size had been captured.
//   * intent_resumer.dart:78 said 'You can now ${intent.kind.description}.' —
//     an English sentence with an English enum fragment interpolated, the exact
//     shape fixed in the gate sheets days earlier, in a third place nobody had
//     found. `intent.kind` is a property access whose type is never written.
//
// Guessing a type from a variable's name is what produced the discarded
// thirty-file scan described in resident_copy_localisation_test.dart. The
// analyzer does not guess.
//
// Exit codes match the rest of tool/: 0 clean, 1 findings, 2 could not run.
//
// SET VIA `exitCode`, NOT RETURNED. `Future<int> main()` does NOT make Dart
// exit with that int — the process still exits 0. The first version of this
// file did exactly that: it printed FAIL, named the offending line, and exited
// 0, so `certify.sh` would have recorded a pass. A false OK in the guard
// written to catch false OKs, found only because the red-proof checked the exit
// code rather than trusting output that looked right.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

/// Enums with a localiser. Reading their copy fields on a screen is a bug.
///
/// Kept in step with `localised` in
/// `test/core/resident_copy_localisation_test.dart` by a test in
/// `test/core/raw_enum_render_test.dart` — two hand-maintained lists of the
/// same thing is how one of them goes stale.
const Set<String> localisedEnums = <String>{
  'ShellDestination',
  'ResidentProfileField',
  'FieldOwnership',
  'ResidentVerificationStage',
  'KycDocumentType',
  'DocumentRejection',
  'ResidentCapability',
  'ResidentIntentKind',
  'DocumentSource',
  'ServiceCategory',
  'HouseholdCorrectionKind',
  'HouseholdRole',
  'ReportReason',
  'NotificationCategory',
  'InboxGroup',
};

const Set<String> copyFields = <String>{
  'label',
  'title',
  'description',
  'summary',
  'explanation',
  'sectionTitle',
  'sectionExplanation',
  'residentMessage',
  'hint',
  'instruction',
  'nextActionLabel',
};

bool isScreen(String path) =>
    path.contains('/presentation/') || path.contains('/lib/shared/');

Future<void> main() async {
  final String root = Directory.current.path;
  final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>['$root/lib'],
  );

  final List<String> offenders = <String>[];
  int resolved = 0;

  for (final context in collection.contexts) {
    for (final String path in context.contextRoot.analyzedFiles()) {
      if (!path.endsWith('.dart') || !isScreen(path)) continue;
      final result = await context.currentSession.getResolvedUnit(path);
      if (result is! ResolvedUnitResult) continue;
      resolved++;
      result.unit.accept(
        _CopyFieldFinder(
          path: path.replaceFirst('$root/', ''),
          unit: result.unit,
          out: offenders,
        ),
      );
    }
  }

  // FLOOR. A resolver that resolved nothing reports nothing, and this
  // repository has been caught by that shape more than once — a parser seeing
  // 37 of 53 routes, a scan matching no files, a suite running no tests. An
  // empty result must mean "looked and found nothing".
  if (resolved < 40) {
    stderr.writeln('FAIL: only $resolved screen files resolved.');
    stderr.writeln('      The analyzer did not read this package, so an empty');
    stderr.writeln('      result would claim nothing. This is not a pass.');
    exitCode = 2;
    return;
  }

  if (offenders.isNotEmpty) {
    stderr.writeln("FAIL: a screen reads a localised enum's English constant.");
    stderr.writeln(
      '      The constant is the no-context fallback; a screen has',
    );
    stderr.writeln('      a BuildContext and must use the localiser.');
    for (final String o in offenders) {
      stderr.writeln('        $o');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'OK: $resolved screen files resolved; no localised enum constant is '
    'rendered directly.',
  );
}

class _CopyFieldFinder extends RecursiveAstVisitor<void> {
  _CopyFieldFinder({required this.path, required this.unit, required this.out});

  final String path;
  final CompilationUnit unit;
  final List<String> out;

  void _check(Expression target, String name, int offset) {
    if (!copyFields.contains(name)) return;
    final DartType? type = target.staticType;
    if (type == null) return;
    final String? owner = type.element?.name;
    if (owner == null || !localisedEnums.contains(owner)) return;
    final int line = unit.lineInfo.getLocation(offset).lineNumber;
    out.add('$path:$line  <$owner>.$name');
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _check(node.realTarget, node.propertyName.name, node.offset);
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _check(node.prefix, node.identifier.name, node.offset);
    super.visitPrefixedIdentifier(node);
  }
}
