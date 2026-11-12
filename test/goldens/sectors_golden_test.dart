import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_environment.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/features/sectors/domain/resident_sector.dart';
import 'package:taytay_resident/features/sectors/presentation/sector_apply_canvas.dart';
import 'package:taytay_resident/features/sectors/presentation/sector_apply_controller.dart';
import 'package:taytay_resident/features/sectors/presentation/sectors_canvas.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Sectors and benefits and Apply for a sector (D-215), pinned as pictures:
/// 390 × 844 at 3×, the bundled fonts, no text scaling, animations off. The
/// data is synthetic; nothing here is a real person or a real record.
///
/// A deliberate visual change regenerates them:
///
/// ```sh
/// flutter test --update-goldens test/goldens/sectors_golden_test.dart
/// ```
const Size _frame = Size(390, 844);
const double _dpr = 3;

void main() {
  setUpAll(_loadFonts);

  final DateTime today = DateTime.utc(2026, 11, 12, 4);
  final SectorOverview overview = SectorOverview(
    recorded: <OwnSector>[
      OwnSector(
        sector: ResidentSector.pwd,
        since: DateTime.utc(2026, 1, 15),
        idLastFour: '0000',
        validUntil: DateTime.utc(2029, 1, 15),
      ),
    ],
    applications: <SectorApplication>[
      SectorApplication(
        id: 'sa-sample-1',
        sector: ResidentSector.soloParent,
        status: SectorApplicationStatus.pending,
        submittedAt: DateTime.utc(2026, 11, 2, 6, 41),
      ),
    ],
  );
  final CapturedDocument photo = CapturedDocument(
    bytes: Uint8List.fromList(List<int>.filled(240 * 1024, 7)),
    fileName: 'sample.jpg',
    mimeType: 'image/jpeg',
    source: DocumentSource.gallery,
  );

  SectorApplyCanvas apply(
    SectorApplyStep step, {
    CapturedDocument? proof,
    bool confirmed = false,
  }) => SectorApplyCanvas(
    step: step,
    policy: UploadPolicy.fallback,
    chosen: ResidentSector.soloParent,
    proof: proof,
    confirmed: confirmed,
    filed: SectorApplication(
      id: 'sa-sample-2',
      sector: ResidentSector.soloParent,
      status: SectorApplicationStatus.pending,
      submittedAt: DateTime.utc(2026, 11, 12, 6, 41),
    ),
    onChoose: (_) {},
    onNext: () {},
    onStepBack: () {},
    onAddPhoto: () {},
    onConfirm: (_) {},
    onSend: () {},
    onSectors: () {},
    onHome: () {},
  );

  testWidgets('Sectors and benefits', (tester) async {
    await _pump(
      tester,
      SectorsCanvas(
        today: today,
        environment: AppEnvironment.dev,
        overview: overview,
        onApply: (_) {},
      ),
    );
    await _match(tester, 'sectors/sectors.png');
  });

  testWidgets('Sectors and benefits, nothing on the record', (tester) async {
    await _pump(
      tester,
      SectorsCanvas(
        today: today,
        environment: AppEnvironment.dev,
        overview: SectorOverview(
          recorded: const <OwnSector>[],
          applications: const <SectorApplication>[],
        ),
        onApply: (_) {},
      ),
    );
    await _match(tester, 'sectors/sectors-empty.png');
  });

  testWidgets('Apply, step 1: choose', (tester) async {
    await _pump(tester, apply(SectorApplyStep.choose));
    await _match(tester, 'sectors/apply-choose.png');
  });

  testWidgets('Apply, step 2: the photo', (tester) async {
    await _pump(
      tester,
      apply(SectorApplyStep.proof, proof: photo, confirmed: true),
    );
    await _match(tester, 'sectors/apply-proof.png');
  });

  testWidgets('Apply: sent', (tester) async {
    await _pump(tester, apply(SectorApplyStep.sent));
    await _match(tester, 'sectors/apply-sent.png');
  });
}

final GlobalKey _frameKey = GlobalKey();

Future<void> _loadFonts() async {
  final FontLoader jakarta = FontLoader('Plus Jakarta Sans');
  for (final String file in <String>[
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Medium.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    jakarta.addFont(rootBundle.load(file));
  }
  await jakarta.load();
  final FontLoader lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/lucide/lucide.ttf'));
  await lucide.load();
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view
    ..devicePixelRatio = _dpr
    ..physicalSize = _frame * _dpr
    ..padding = FakeViewPadding.zero
    ..viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
      home: RepaintBoundary(key: _frameKey, child: screen),
    ),
  );
  // Bounded rather than pumpAndSettle: a skeleton never settles.
  for (int i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  for (final Element element in find.byType(Image).evaluate().toList()) {
    final Widget widget = element.widget;
    if (widget is Image && element.mounted) {
      await tester.runAsync(() => precacheImage(widget.image, element));
    }
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _match(WidgetTester tester, String golden) async {
  expect(tester.getSize(find.byKey(_frameKey)), _frame);
  await tester.pump();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(golden));
}
