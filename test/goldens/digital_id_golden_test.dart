import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/credential/domain/credential_repository.dart';
import 'package:taytay_resident/features/credential/presentation/digital_id_canvas.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

import '../../tool/golden_compare.dart';

/// 390×844 at 3×. The designs are the same size.
const Size _frame = Size(390, 844);

const String _longName =
    'Maria Concepcion Josefina Dela Paz-Villanueva Santiago Fernandez';

void main() {
  setUpAll(_loadFonts);

  final DateTime now = DateTime(2026, 10, 22, 12);
  final DateTime issued = DateTime(2026, 10, 22);
  final DateTime expires = DateTime(2029, 10, 22);
  final PresentationArtifact qr = PresentationArtifact(
    payload: 'sample-qr-not-a-credential',
    expiresAt: DateTime(2026, 10, 22, 21, 42),
  );

  final List<_Specimen> specimens = <_Specimen>[
    _Specimen(
      'active',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: 'Juan Dela Cruz',
      now: now,
      sample: true,
    ),
    _Specimen(
      'suspended',
      card: _sampleCard(
        issued,
        expires,
        state: CredentialLifecycleState.suspended,
      ),
      nameText: 'Juan Dela Cruz',
      now: now,
      sample: true,
    ),
    _Specimen(
      'revoked',
      card: _sampleCard(
        issued,
        expires,
        state: CredentialLifecycleState.revoked,
      ),
      nameText: 'Juan Dela Cruz',
      now: now,
      sample: true,
    ),
    _Specimen(
      'expired',
      card: _sampleCard(issued, expires),
      nameText: 'Juan Dela Cruz',
      now: DateTime(2029, 10, 23),
      sample: true,
    ),
    _Specimen('not-issued', now: now),
    _Specimen(
      'long-name',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: _longName,
      now: now,
      sample: true,
    ),
    _Specimen(
      'ellipsis',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: '$_longName Reyes',
      now: now,
      sample: true,
    ),
    _Specimen(
      'empty-name',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: '   ',
      now: now,
      sample: true,
    ),
  ];

  for (final _Specimen specimen in specimens) {
    testWidgets('${specimen.name} matches its golden', (tester) async {
      final img.Image rendered = await _paint(tester, specimen);
      // Redesign P3b: the card is DigitalID.dc.html now. The old specimen
      // PNGs (test/goldens/design/digital-id) were the retired card, so the
      // row-by-row comparison with them and its side-by-side images are gone.
      // Each face is still pinned, pixel for pixel, to its own golden.
      final String goldenPath = 'test/goldens/digital_id/${specimen.name}.png';
      if (autoUpdateGoldenFiles) {
        final File golden = File(goldenPath);
        golden.parent.createSync(recursive: true);
        golden.writeAsBytesSync(img.encodePng(rendered));
      }

      final File goldenFile = File(goldenPath);
      expect(goldenFile.existsSync(), isTrue, reason: goldenPath);
      final img.Image? committed = img.decodePng(goldenFile.readAsBytesSync());
      expect(committed, isNotNull);
      final GoldenReport self = compareImages(committed!, rendered);
      expect(self.sameSize, isTrue, reason: specimen.name);
      expect(self.mismatchPercent, 0, reason: specimen.name);
    });
  }
}

ResidentCredential _sampleCard(
  DateTime issued,
  DateTime expires, {
  CredentialLifecycleState state = CredentialLifecycleState.active,
  PresentationArtifact? qr,
}) {
  return ResidentCredential(
    id: 'credential-sample-1',
    idNumber: 'TYT-0000-0000',
    state: state,
    rawState: state.name,
    issuedAt: issued,
    expiresAt: expires,
    qr: qr,
  );
}

class _Specimen {
  const _Specimen(
    this.name, {
    required this.now,
    this.card,
    this.nameText,
    this.sample = false,
  });

  final String name;
  final ResidentCredential? card;
  final String? nameText;
  final DateTime now;
  final bool sample;

  String? get residentName => nameText;
}

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

Future<img.Image> _paint(WidgetTester tester, _Specimen specimen) async {
  debugDisableShadows = false;
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: _frame,
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: RepaintBoundary(
          key: const ValueKey<String>('digital-id-frame'),
          child: _Phone(
            child: DigitalIdView(
              card: specimen.card,
              name: specimen.residentName,
              now: specimen.now,
              sample: specimen.sample,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);

  final RenderRepaintBoundary boundary =
      tester.renderObject(
            find.byKey(const ValueKey<String>('digital-id-frame')),
          )
          as RenderRepaintBoundary;
  try {
    final img.Image? decoded = await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      final img.Image? parsed = img.decodePng(data!.buffer.asUint8List());
      if (parsed == null) {
        throw StateError('The digital ID frame did not decode.');
      }
      return parsed;
    });
    if (decoded == null) {
      throw StateError('The digital ID frame did not decode.');
    }
    return decoded;
  } finally {
    debugDisableShadows = true;
  }
}

Future<void> _precache(WidgetTester tester) async {
  final Finder images = find.byType(Image);
  if (images.evaluate().isEmpty) return;
  final BuildContext context = tester.element(images.first);
  for (final Element element in images.evaluate()) {
    final Widget widget = element.widget;
    if (widget is Image) {
      await tester.runAsync(() => precacheImage(widget.image, context));
    }
  }
  await tester.pump();
}

class _Phone extends StatelessWidget {
  const _Phone({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 844,
      child: ColoredBox(
        color: BrandColors.surface,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: ShellTabBar.barHeight),
                child: child,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShellTabBar(selectedIndex: 4, onSelected: _ignore),
            ),
          ],
        ),
      ),
    );
  }
}

void _ignore(int index) {}
