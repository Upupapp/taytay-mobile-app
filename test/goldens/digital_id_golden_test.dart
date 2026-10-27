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
      design: '08-11_My-Account_Digital-ID-Active.png',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: 'Juan Dela Cruz',
      now: now,
      sample: true,
      maskQr: true,
    ),
    _Specimen(
      'suspended',
      design: '08-11b_My-Account_Digital-ID-Suspended.png',
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
      design: '08-11c_My-Account_Digital-ID-Revoked.png',
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
      design: '08-11d_My-Account_Digital-ID-Expired.png',
      card: _sampleCard(issued, expires),
      nameText: 'Juan Dela Cruz',
      now: DateTime(2029, 10, 23),
      sample: true,
    ),
    _Specimen(
      'not-issued',
      design: '08-11e_My-Account_Digital-ID-Not-Issued.png',
      now: now,
    ),
    _Specimen(
      'long-name',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: _longName,
      now: now,
      sample: true,
      maskQr: true,
    ),
    _Specimen(
      'ellipsis',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: '$_longName Reyes',
      now: now,
      sample: true,
      maskQr: true,
    ),
    _Specimen(
      'empty-name',
      card: _sampleCard(issued, expires, qr: qr),
      nameText: '   ',
      now: now,
      sample: true,
      maskQr: true,
    ),
  ];

  for (final _Specimen specimen in specimens) {
    testWidgets('${specimen.name} matches its golden', (tester) async {
      final img.Image rendered = await _paint(tester, specimen);
      final String? designName = specimen.design;
      GoldenMask? mask;
      String? lineReport;
      if (designName != null) {
        final img.Image? design = img.decodePng(
          File('test/goldens/design/digital-id/$designName').readAsBytesSync(),
        );
        expect(design, isNotNull, reason: designName);
        if (specimen.maskQr) {
          final Rect qr = tester.getRect(find.byKey(DigitalIdView.qrKey));
          final Rect phone = tester.getRect(
            find.byKey(const ValueKey<String>('digital-id-frame')),
          );
          mask = GoldenMask(
            ((qr.left - phone.left) * 3).floor(),
            ((qr.top - phone.top) * 3).floor(),
            (qr.width * 3).ceil(),
            (qr.height * 3).ceil(),
          );
        }
        lineReport = _lineReport(design!, rendered, mask);
      }

      final String goldenPath = 'test/goldens/digital_id/${specimen.name}.png';
      final String sidePath =
          'test/goldens/compare/digital-id/${specimen.name}.png';
      if (autoUpdateGoldenFiles) {
        final File golden = File(goldenPath);
        golden.parent.createSync(recursive: true);
        golden.writeAsBytesSync(img.encodePng(rendered));
        if (designName != null) {
          final img.Image? design = img.decodePng(
            File(
              'test/goldens/design/digital-id/$designName',
            ).readAsBytesSync(),
          );
          final GoldenReport report = compareImages(
            design!,
            rendered,
            masks: mask == null ? const <GoldenMask>[] : <GoldenMask>[mask],
          );
          final File side = File(sidePath);
          side.parent.createSync(recursive: true);
          side.writeAsBytesSync(img.encodePng(report.sideBySide));
        }
      }

      final File goldenFile = File(goldenPath);
      expect(goldenFile.existsSync(), isTrue, reason: goldenPath);
      final img.Image? committed = img.decodePng(goldenFile.readAsBytesSync());
      expect(committed, isNotNull);
      final GoldenReport self = compareImages(committed!, rendered);
      expect(self.sameSize, isTrue, reason: specimen.name);
      expect(self.mismatchPercent, 0, reason: specimen.name);
      if (lineReport != null) {
        expect(lineReport, startsWith('dev '), reason: specimen.name);
        final int deviation = int.parse(lineReport.split(' ').elementAt(1));
        expect(deviation, lessThanOrEqualTo(2), reason: lineReport);
      }
      if (designName != null) {
        expect(File(sidePath).existsSync(), isTrue, reason: sidePath);
      }
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
    this.design,
    this.card,
    this.nameText,
    this.sample = false,
    this.maskQr = false,
  });

  final String name;
  final String? design;
  final ResidentCredential? card;
  final String? nameText;
  final DateTime now;
  final bool sample;
  final bool maskQr;

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

String _lineReport(img.Image design, img.Image render, GoldenMask? mask) {
  final img.Image left = img.Image.from(design);
  final img.Image right = img.Image.from(render);
  if (mask != null) {
    _whiten(left, mask);
    _whiten(right, mask);
  }
  final List<int> designStarts = _darkStarts(left);
  final List<int> renderStarts = _darkStarts(right);
  if (designStarts.length != renderStarts.length) {
    return 'dev 999 lines ${renderStarts.length}/${designStarts.length} '
        'design $designStarts render $renderStarts';
  }
  var max = 0;
  for (var i = 0; i < designStarts.length; i++) {
    final int delta = (designStarts[i] - renderStarts[i]).abs();
    if (delta > max) max = delta;
  }
  return 'dev $max lines ${renderStarts.length}/${designStarts.length}';
}

void _whiten(img.Image image, GoldenMask mask) {
  final int x1 = (mask.x + mask.width).clamp(0, image.width);
  final int y1 = (mask.y + mask.height).clamp(0, image.height);
  for (var y = mask.y.clamp(0, image.height); y < y1; y++) {
    for (var x = mask.x.clamp(0, image.width); x < x1; x++) {
      image.setPixelRgb(x, y, 255, 255, 255);
    }
  }
}

/// A row is dark when any pixel from x 60 to 1110 has mean RGB below 110.
/// Runs shorter than 8 rows are dropped. The value is the start row.
List<int> _darkStarts(img.Image image) {
  final List<bool> rows = List<bool>.filled(image.height, false);
  final int x1 = image.width < 1110 ? image.width : 1110;
  for (var y = 0; y < image.height; y++) {
    for (var x = 60; x < x1; x++) {
      final img.Pixel pixel = image.getPixel(x, y);
      final num mean = (pixel.r + pixel.g + pixel.b) / 3;
      if (mean < 110) {
        rows[y] = true;
        break;
      }
    }
  }
  final List<int> starts = <int>[];
  int? start;
  for (var y = 0; y < rows.length; y++) {
    if (rows[y] && start == null) start = y;
    if (!rows[y] && start != null) {
      if (y - start >= 8) starts.add(start);
      start = null;
    }
  }
  if (start != null && rows.length - start >= 8) starts.add(start);
  return starts;
}
