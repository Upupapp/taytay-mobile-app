import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/design/typography.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/features/gallery/presentation/component_gallery_screen.dart';
import 'package:taytay_resident/shared/widgets/pills.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_buttons.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';
import 'package:taytay_resident/shared/widgets/taytay_rows.dart';
import 'package:taytay_resident/shared/widgets/taytay_states.dart';

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
    await _match(
      tester,
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
    await _match(
      tester,
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
          StatusPill(label: 'Advisory', tone: PillTone.gold),
          StatusPill(label: 'Open', tone: PillTone.green),
          SampleTag(),
        ],
      ),
      logical: const Size(360, 80),
    );
    await _match(
      tester,
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
    await _paintPixels(
      tester,
      const PrimaryButton(
        kind: TaytayButtonKind.signIn,
        label: 'Sign in',
        onPressed: _noop,
      ),
      const Size(964, 150),
      'components/signin_primary_render.png',
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
    await _match(
      tester,
      find.byType(MaterialApp),
      matchesGoldenFile('components/gallery_frame.png'),
    );
  });

  testWidgets('colour and gradient tokens', (tester) async {
    await _paintPixels(
      tester,
      const Column(
        children: <Widget>[
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: ColoredBox(color: BrandColors.taytayBlue)),
                Expanded(child: ColoredBox(color: BrandColors.taytayBlueDark)),
                Expanded(child: ColoredBox(color: BrandColors.sealGold)),
                Expanded(child: ColoredBox(color: BrandColors.danger)),
                Expanded(child: ColoredBox(color: BrandColors.success)),
                Expanded(child: ColoredBox(color: BrandColors.warning)),
                Expanded(child: ColoredBox(color: BrandColors.surface)),
                Expanded(child: ColoredBox(color: BrandColors.fieldFill)),
              ],
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    BrandColors.taytayBlueDark,
                    BrandColors.taytayBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
      const Size(960, 276),
      'components/evidence_tokens.png',
    );
  });

  testWidgets('type scale', (tester) async {
    const ink = BrandColors.taytayBlueDark;
    await _paintPixels(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Serbisyong bayan',
            style: AppTypography.h1.copyWith(color: ink),
          ),
          Text(
            'Mag-sign in',
            style: AppTypography.h1SignIn.copyWith(color: ink),
          ),
          Text(
            'Sign in',
            style: AppTypography.buttonSignIn.copyWith(color: ink),
          ),
          Text('Read Balita', style: AppTypography.button.copyWith(color: ink)),
          Text(
            'Sign in to your Taytay resident account.',
            style: AppTypography.bodyStyle.copyWith(
              color: BrandColors.sheetBody,
            ),
          ),
          Text(
            'Basic details only.',
            style: AppTypography.bodyCompact.copyWith(
              color: BrandColors.sheetBody,
            ),
          ),
          Text(
            'Email or mobile number',
            style: AppTypography.label.copyWith(color: BrandColors.fieldLabel),
          ),
          Text(
            'PENDING REVIEW',
            style: AppTypography.eyebrow.copyWith(color: BrandColors.inkGold),
          ),
          Text(
            'MAG-SIGN IN',
            style: AppTypography.eyebrowSignIn.copyWith(
              color: BrandColors.inkGold,
            ),
          ),
        ],
      ),
      const Size(1020, 780),
      'components/evidence_type.png',
      background: Colors.white,
    );
  });

  testWidgets('secondary and text buttons', (tester) async {
    await _paintPixels(
      tester,
      const Column(
        children: <Widget>[
          SecondaryButton(
            kind: TaytayButtonKind.signIn,
            label: 'Create an account',
            onPressed: _noop,
          ),
          SizedBox(height: 8),
          Text(
            'Continue as guest',
            textAlign: TextAlign.center,
            style: AppTypography.link,
          ),
        ],
      ),
      const Size(964, 240),
      'components/evidence_secondary_text.png',
      background: Colors.white,
    );
  });

  testWidgets('secondary button matches the sign-in crop', (tester) async {
    await _paintPixels(
      tester,
      const SecondaryButton(
        kind: TaytayButtonKind.signIn,
        label: 'Create an account',
        onPressed: _noop,
      ),
      const Size(964, 150),
      'components/signin_secondary_render.png',
      background: Colors.white,
    );
  });

  testWidgets('text button matches the guest link crop', (tester) async {
    await _paintPixels(
      tester,
      Center(
        child: Text(
          'Continue as guest',
          textAlign: TextAlign.center,
          style: AppTypography.linkGuest.copyWith(
            color: BrandColors.taytayBlue,
          ),
        ),
      ),
      const Size(963, 120),
      'components/evidence_text_button.png',
      background: Colors.white,
    );
  });

  testWidgets('back button on navy', (tester) async {
    await _paintPixels(
      tester,
      const Center(child: TaytayBackButton(light: true)),
      const Size(144, 144),
      'components/evidence_back.png',
      background: BrandColors.taytayBlueDark,
    );
  });

  testWidgets('empty state', (tester) async {
    await _paintPixels(
      tester,
      const Center(
        child: EmptyState(
          title: 'No offices found',
          message: 'Try another word, or browse by category.',
        ),
      ),
      const Size(900, 720),
      'components/evidence_empty.png',
      background: Colors.white,
    );
  });
}

/// Paints [child] at [pixels] device pixels.
///
/// The design PNGs are 3× exports. The child is laid out at the CSS size with
/// a device pixel ratio of 3, so line boxes snap to a device pixel, then drawn
/// into a frame of [pixels] logical pixels. [matchesGoldenFile] records that
/// frame 1:1.
Future<void> _paintPixels(
  WidgetTester tester,
  Widget child,
  Size pixels,
  String golden, {
  Color background = const Color(0xFFFDFDFE),
}) async {
  debugDisableShadows = false;
  const dpr = 3.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = pixels * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: widget ?? const SizedBox.shrink(),
        );
      },
      home: ColoredBox(
        key: const ValueKey<String>('evidence-root'),
        color: background,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: pixels.width / dpr,
            height: pixels.height / dpr,
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  // Decode bundled images before the capture. A single pump paints the frame
  // before the seal's bytes are ready when nothing else has loaded them.
  final images = find.byType(Image);
  if (images.evaluate().isNotEmpty) {
    final context = tester.element(images.first);
    for (final element in images.evaluate()) {
      final widget = element.widget;
      if (widget is Image) {
        await tester.runAsync(() => precacheImage(widget.image, context));
      }
    }
    await tester.pump();
  }
  expect(
    tester.getSize(find.byKey(const ValueKey<String>('evidence-root'))),
    pixels,
  );
  await _match(
    tester,
    find.byKey(const ValueKey<String>('evidence-root')),
    matchesGoldenFile(golden),
  );
}

Future<void> _match(
  WidgetTester tester,
  dynamic finder,
  dynamic matcher,
) async {
  debugDisableShadows = false;
  try {
    await tester.pump();
    await expectLater(finder, matcher);
  } finally {
    debugDisableShadows = true;
  }
}

void _noop() {}
