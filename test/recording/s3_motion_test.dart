@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/features/mock_data/data/mock/resident_record_mock.dart';
import 'package:taytay_resident/features/verification/presentation/manila_stamp.dart';
import 'package:taytay_resident/features/verification/presentation/profile_wizard_page.dart';
import 'package:taytay_resident/features/verification/presentation/unverified_gate_sheet.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';

/// Motion clips at 390×844 @3×. Animations stay on. No environment banner.
///
/// `flutter test --tags recording --run-skipped test/recording/s3_motion_test.dart`
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

Future<void> _mount(WidgetTester tester, Widget child) async {
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
        disableAnimations: false,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: RepaintBoundary(
          key: const ValueKey<String>('s3-motion'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);
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

Future<void> _shot(WidgetTester tester, Directory out, int frame) async {
  final boundary =
      tester.renderObject(find.byKey(const ValueKey<String>('s3-motion')))
          as RenderRepaintBoundary;
  debugDisableShadows = false;
  try {
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final name = frame.toString().padLeft(4, '0');
      File(
        '${out.path}/f_$name.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = true;
  }
}

/// Eight frames a second, which is the encode rate.
const Duration _step = Duration(milliseconds: 125);

Future<int> _hold(WidgetTester tester, Directory out, int frame, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(_step);
    await _shot(tester, out, frame);
    frame++;
  }
  return frame;
}

void _noop() {}

class _SceneReel extends StatefulWidget {
  const _SceneReel({required this.initial});

  final Widget initial;

  @override
  State<_SceneReel> createState() => _SceneReelState();
}

class _SceneReelState extends State<_SceneReel> {
  late Widget _child = widget.initial;

  void show(Widget next) => setState(() => _child = next);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionTokens.emphasised,
      switchInCurve: MotionTokens.enterEase,
      switchOutCurve: MotionTokens.exitEase,
      child: KeyedSubtree(
        key: ValueKey<Widget>(_child),
        child: _child,
      ),
    );
  }
}

class _GateReel extends StatefulWidget {
  const _GateReel();

  @override
  State<_GateReel> createState() => _GateReelState();
}

class _GateReelState extends State<_GateReel>
    with SingleTickerProviderStateMixin {
  late final AnimationController open = AnimationController(
    vsync: this,
    duration: MotionTokens.emphasised,
  );
  VerifiedOnlyAction action = VerifiedOnlyAction.message;

  void showDigitalId() =>
      setState(() => action = VerifiedOnlyAction.digitalId);

  @override
  void dispose() {
    open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: open,
      builder: (context, _) {
        final double t = open.value;
        return Stack(
          children: <Widget>[
            const GateBackdrop(),
            ModalBarrier(
              color: GateScrim.at(t),
              dismissible: false,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionalTranslation(
                translation: Offset(0, 1 - t),
                child: UnverifiedGateSheet(
                  action: action,
                  onContinue: _noop,
                  onDismiss: _noop,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('status screens, motion on', (tester) async {
    final out = Directory('/tmp/s3_motion_status');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    const record = MockResidentRecordRepository.sampleRecord;
    final String idType = idTypeLabel(MockResidentRecordRepository.sampleIdType);
    await _mount(
      tester,
      _SceneReel(
        initial: PendingStatusPage(
          accountCreated: formatManilaStamp(
            MockResidentRecordRepository.sampleAccountCreatedAt,
          ),
          email: record.email,
          idType: idType,
        ),
      ),
    );
    final reel = tester.state<_SceneReelState>(find.byType(_SceneReel));
    var frame = await _hold(tester, out, 0, 8);
    reel.show(
      VerifiedStatusPage(
        onHome: _noop,
        verifiedOn: formatManilaDate(
          MockResidentRecordRepository.sampleVerifiedAt,
        ),
        completeness: record.completeness,
      ),
    );
    frame = await _hold(tester, out, frame, 12);
    reel.show(
      NeedsCorrectionPage(
        onResubmit: _noop,
        reason: record.rejectionReason,
        idType: idType,
        reviewedOn: formatManilaDate(
          MockResidentRecordRepository.sampleReviewedAt,
        ),
      ),
    );
    frame = await _hold(tester, out, frame, 12);
    expect(frame, greaterThan(20));
  });

  testWidgets('unverified gate sheet, motion on', (tester) async {
    final out = Directory('/tmp/s3_motion_gate');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    await _mount(tester, const _GateReel());
    final reel = tester.state<_GateReelState>(find.byType(_GateReel));
    var frame = await _hold(tester, out, 0, 6);
    reel.open.forward();
    frame = await _hold(tester, out, frame, 12);
    reel.showDigitalId();
    frame = await _hold(tester, out, frame, 12);
    expect(frame, greaterThan(20));
  });

  testWidgets('resident profile wizard, motion on', (tester) async {
    final out = Directory('/tmp/s3_motion_wizard');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);
    const record = MockResidentRecordRepository.sampleRecord;

    Widget page(ProfileWizardStep step) => ProfileWizardPage(
      step: step,
      record: record,
      submittedAt: step == ProfileWizardStep.submitted
          ? MockResidentRecordRepository.sampleSubmittedAt
          : null,
      onBack: _noop,
      onContinue: _noop,
      certified: true,
    );

    await _mount(
      tester,
      _SceneReel(initial: page(ProfileWizardStep.overview)),
    );
    final reel = tester.state<_SceneReelState>(find.byType(_SceneReel));
    var frame = await _hold(tester, out, 0, 6);
    for (final step in <ProfileWizardStep>[
      ProfileWizardStep.personal,
      ProfileWizardStep.household,
      ProfileWizardStep.review,
      ProfileWizardStep.submitted,
    ]) {
      reel.show(page(step));
      frame = await _hold(tester, out, frame, 10);
    }
    expect(frame, greaterThan(30));
  });
}
