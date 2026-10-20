import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/features/gallery/presentation/component_gallery_screen.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_buttons.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';
import 'package:taytay_resident/shared/widgets/taytay_rows.dart';

/// Phone frame the programme compares against: 390×844 logical pixels at 3x.
const Size _frame = Size(390, 844);
const double _dpr = 3;

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

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size logical = const Size(360, 120),
}) async {
  tester.view.physicalSize = logical * _dpr;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: widget ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the back control is 48 dp with a 44 dp circle', (tester) async {
    await _pump(tester, const TaytayBackButton());
    final boxes = find.descendant(
      of: find.byType(TaytayBackButton),
      matching: find.byType(SizedBox),
    );
    expect(tester.getSize(boxes.first), const Size(48, 48));
    expect(tester.getSize(boxes.at(1)), const Size(44, 44));
    await expectLater(
      find.byType(TaytayBackButton),
      matchesGoldenFile('components/back_button.png'),
    );
  });

  testWidgets('primary, secondary and gold buttons', (tester) async {
    await _pump(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PrimaryButton(label: 'Read Balita', onPressed: _noop),
          SizedBox(height: 8),
          SecondaryButton(label: 'See all', onPressed: _noop),
          SizedBox(height: 8),
          GoldButton(label: 'Next', onPressed: _noop),
        ],
      ),
      logical: const Size(360, 220),
    );
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('components/buttons.png'),
    );
  });

  testWidgets('status chips and the sample tag', (tester) async {
    await _pump(
      tester,
      const Wrap(
        spacing: 8,
        children: <Widget>[
          StatusChip(label: 'Advisory', tone: StatusTone.amber),
          StatusChip(label: 'Open', tone: StatusTone.green),
          SampleTag(),
        ],
      ),
      logical: const Size(360, 80),
    );
    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('components/chips.png'),
    );
  });

  testWidgets('a labelled icon', (tester) async {
    await _pump(
      tester,
      const TaytayIcon(
        icon: TaytayIcons.landmark,
        semanticLabel: 'Municipal hall',
      ),
      logical: const Size(64, 64),
    );
    expect(find.bySemanticsLabel('Municipal hall'), findsOneWidget);
  });

  testWidgets('primary button matches the sign-in crop', (tester) async {
    // The crop is 964×150 device pixels. The golden captures logical pixels,
    // so the frame is that size at a pixel ratio of 1 and the button is
    // painted at 3× to match the design file.
    tester.view.physicalSize = const Size(964, 150);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(964, 150),
          textScaler: TextScaler.noScaling,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const ColoredBox(
            color: Color(0xFFFDFDFE),
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: 964 / 3,
                height: 150 / 3,
                child: PrimaryButton(label: 'Sign in', onPressed: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(ColoredBox),
      matchesGoldenFile('components/signin_primary_render.png'),
    );
  });

  testWidgets('gallery harness is the 390 by 844 light frame', (tester) async {
    final behavior = MockBehaviorController(
      latency: Duration.zero,
      failure: MockFailureMode.none,
    );
    addTearDown(behavior.dispose);
    await _pump(
      tester,
      ComponentGalleryScreen(behavior: behavior),
      logical: _frame,
    );
    expect(find.text('Components'), findsOneWidget);
    expect(find.text('SAMPLE'), findsWidgets);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('components/gallery_frame.png'),
    );
  });
}

void _noop() {}
