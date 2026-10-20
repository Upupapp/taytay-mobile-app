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
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_buttons.dart';
import 'package:taytay_resident/shared/widgets/taytay_headers.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';
import 'package:taytay_resident/shared/widgets/taytay_rows.dart';
import 'package:taytay_resident/shared/widgets/taytay_states.dart';
import 'package:taytay_resident/shared/widgets/taytay_text_field.dart';

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
          Text('Sign in', style: AppTypography.button.copyWith(color: ink)),
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
          SecondaryButton(label: 'Create an account', onPressed: _noop),
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
      const SecondaryButton(label: 'Create an account', onPressed: _noop),
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
          style: AppTypography.link.copyWith(color: BrandColors.taytayBlue),
        ),
      ),
      const Size(963, 120),
      'components/evidence_text_button.png',
      background: Colors.white,
    );
  });

  testWidgets('text fields', (tester) async {
    final focused = TextEditingController(text: 'name@example.com');
    addTearDown(focused.dispose);
    await _paintPixels(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TaytayTextField(
            label: 'Email or mobile number',
            hint: 'name@example.com',
          ),
          const SizedBox(height: 8),
          TaytayTextField(
            label: 'Email or mobile number',
            controller: focused,
            state: TaytayFieldState.focused,
          ),
          const SizedBox(height: 8),
          const TaytayTextField(
            label: 'Email or mobile number',
            state: TaytayFieldState.error,
            message: 'Enter a valid email or mobile number.',
          ),
        ],
      ),
      const Size(960, 960),
      'components/evidence_fields.png',
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

  testWidgets('card, list row and chips', (tester) async {
    await _paintPixels(
      tester,
      const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusChip(label: 'Pending review', tone: StatusTone.amber),
              StatusChip(label: 'Verified', tone: StatusTone.green),
              StatusChip(label: 'Needs correction', tone: StatusTone.red),
              SampleTag(),
            ],
          ),
          SizedBox(height: 12),
          SectionCard(
            child: Text(
              'Business Permits and Licensing Office',
              style: AppTypography.cardTitle,
            ),
          ),
          SizedBox(height: 8),
          ListRow(
            title: 'Municipal Treasurer\'s Office',
            subtitle: 'Community tax certificate',
            icon: TaytayIcons.landmark,
            iconLabel: 'Office',
          ),
        ],
      ),
      const Size(1020, 780),
      'components/evidence_card_row_chips.png',
      background: BrandColors.surface,
    );
  });

  testWidgets('woven header', (tester) async {
    await _paintPixels(
      tester,
      const WovenHeader(showBack: true),
      const Size(1170, 480),
      'components/evidence_woven.png',
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

/// Paints [child] at [pixels] device pixels. The child is laid out at one
/// third of that size and scaled by 3, which is how the design PNGs were
/// exported (390×844 at 3x).
Future<void> _paintPixels(
  WidgetTester tester,
  Widget child,
  Size pixels,
  String golden, {
  Color background = const Color(0xFFFDFDFE),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = pixels;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: pixels, textScaler: TextScaler.noScaling),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: ColoredBox(
          key: const ValueKey<String>('evidence-root'),
          color: background,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: pixels.width / 3,
              height: pixels.height / 3,
              child: Material(type: MaterialType.transparency, child: child),
            ),
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
  await expectLater(
    find.byKey(const ValueKey<String>('evidence-root')),
    matchesGoldenFile(golden),
  );
}

void _noop() {}
