import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/mock_data/data/mock/resident_record_mock.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/unverified_gate_sheet.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';

void _noop() {}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: child,
    ),
  );
  await tester.pump();
}

void main() {
  test('verification presentation does not nudge text', () {
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/features/verification',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('Transform.translate')) {
        offenders.add(entity.path);
      }
      if (source.contains('juana.delacruz@example.com') ||
          source.contains('Oct 20, 2026') ||
          source.contains('(sample)')) {
        offenders.add('${entity.path} sample');
      }
    }
    expect(offenders, isEmpty);
  });

  testWidgets('S3 controls are at least 48 dp', (tester) async {
    const record = MockResidentRecordRepository.sampleRecord;
    final pages = <Widget>[
      const PendingStatusPage(onBack: _noop),
      const VerifiedStatusPage(onBack: _noop, onHome: _noop, completeness: 60),
      const NeedsCorrectionPage(onBack: _noop, onResubmit: _noop),
      const UnverifiedStatusPage(onBack: _noop, onStart: _noop),
      const UnverifiedGatePreview(),
      const UnverifiedGateSheet(
        action: VerifiedOnlyAction.message,
        onContinue: _noop,
        onDismiss: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.overview,
        record: record,
        onBack: _noop,
        onPersonal: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.personal,
        record: record,
        onBack: _noop,
        onContinue: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.household,
        record: record,
        onBack: _noop,
        onContinue: _noop,
      ),
      const ProfileWizardPage(
        step: ProfileWizardStep.review,
        record: record,
        onBack: _noop,
        onContinue: _noop,
        onEditPersonal: _noop,
        certified: true,
      ),
      ProfileWizardPage(
        step: ProfileWizardStep.submitted,
        record: record,
        submittedAt: MockResidentRecordRepository.sampleSubmittedAt,
        onBack: _noop,
        onContinue: _noop,
      ),
    ];

    for (final page in pages) {
      await _pump(tester, page);
      final undersized = <String>[];
      for (final element
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget is IconButton ||
                    widget is FilledButton ||
                    widget is OutlinedButton ||
                    widget is TextButton ||
                    widget is InkWell ||
                    widget is GestureDetector,
              )
              .evaluate()) {
        final size = element.size;
        if (size == null) continue;
        if (size.height == 0 || size.width == 0) continue;
        if (size.height + 0.01 < A11y.minTapTarget ||
            size.width + 0.01 < A11y.minTapTarget) {
          undersized.add(
            '${element.widget.runtimeType} ${size.width}x${size.height}',
          );
        }
      }
      expect(undersized, isEmpty, reason: page.runtimeType.toString());
    }
  });
}
