@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/features/mock_data/data/mock/resident_record_mock.dart';
import 'package:taytay_resident/features/verification/presentation/manila_stamp.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/unverified_gate_sheet.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';

/// Stills of `03-01` through `03-09` at 390×844 @3×.
///
/// `flutter test --tags recording --run-skipped test/recording/s3_frames_test.dart`
Future<void> _loadFonts() async {
  final jakarta = FontLoader('Plus Jakarta Sans');
  for (final file in <String>[
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Medium.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    jakarta.addFont(rootBundle.load(file));
  }
  await jakarta.load();
  final lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/lucide/lucide.ttf'));
  await lucide.load();
}

Future<void> _paint(WidgetTester tester, Widget child, String path) async {
  debugDisableShadows = false;
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: const ValueKey<String>('s3-frame'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);

  final boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s3-frame')))
          as RenderRepaintBoundary;
  try {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _precache(WidgetTester tester) async {
  final images = find.byType(Image);
  if (images.evaluate().isEmpty) return;
  final context = tester.element(images.first);
  for (final element in images.evaluate()) {
    final widget = element.widget;
    if (widget is Image) {
      await tester.runAsync(() => precacheImage(widget.image, context));
    }
  }
  await tester.pump();
}

void _noop() {}

void main() {
  setUpAll(_loadFonts);

  testWidgets('capture 03-01 through 03-09', (tester) async {
    final out = Directory('/tmp/s3_renders');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);
    const record = MockResidentRecordRepository.sampleRecord;
    final String created = formatManilaStamp(
      MockResidentRecordRepository.sampleAccountCreatedAt,
    );
    final String idType = idTypeLabel(MockResidentRecordRepository.sampleIdType);
    final frames = <(String, Widget)>[
      (
        '03-01',
        PendingStatusPage(
          onBack: _noop,
          accountCreated: created,
          email: record.email,
          idType: idType,
        ),
      ),
      (
        '03-02',
        VerifiedStatusPage(
          onBack: _noop,
          onHome: _noop,
          verifiedOn: formatManilaDate(
            MockResidentRecordRepository.sampleVerifiedAt,
          ),
          completeness: record.completeness,
        ),
      ),
      (
        '03-03',
        NeedsCorrectionPage(
          onBack: _noop,
          onResubmit: _noop,
          reason: record.rejectionReason,
          idType: idType,
          reviewedOn: formatManilaDate(
            MockResidentRecordRepository.sampleReviewedAt,
          ),
        ),
      ),
      ('03-04', const UnverifiedGatePreview()),
      (
        '03-05',
        const ProfileWizardPage(
          step: ProfileWizardStep.overview,
          record: record,
          onBack: _noop,
        ),
      ),
      (
        '03-06',
        const ProfileWizardPage(
          step: ProfileWizardStep.personal,
          record: record,
          onBack: _noop,
          onContinue: _noop,
        ),
      ),
      (
        '03-07',
        const ProfileWizardPage(
          step: ProfileWizardStep.household,
          record: record,
          onBack: _noop,
          onContinue: _noop,
        ),
      ),
      (
        '03-08',
        const ProfileWizardPage(
          step: ProfileWizardStep.review,
          record: record,
          certified: true,
          onBack: _noop,
          onContinue: _noop,
        ),
      ),
      (
        '03-09',
        ProfileWizardPage(
          step: ProfileWizardStep.submitted,
          record: record,
          submittedAt: MockResidentRecordRepository.sampleSubmittedAt,
          onBack: _noop,
          onContinue: _noop,
        ),
      ),
    ];
    for (final (name, child) in frames) {
      await _paint(tester, child, '${out.path}/$name.png');
    }
  });
}
