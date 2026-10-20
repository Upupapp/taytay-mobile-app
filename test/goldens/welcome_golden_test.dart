import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/features/onboarding/presentation/welcome_scene.dart';

/// 390×844 at 3×, the same frame as the design PNGs.
const Size _pixels = Size(1170, 2532);

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

WelcomePageCopy _copy(int page) {
  const shared = (
    skip: 'Skip',
    next: 'Next',
    started: 'Get started',
    guest: 'Continue as guest',
    note: 'You can browse municipal services without an account.',
  );
  return switch (page) {
    0 => WelcomePageCopy(
      eyebrow: 'Municipal services in one place',
      title: 'Serbisyong bayan,\nnasa isang app.',
      body:
          'Documents, real property tax, health programmes and job services — '
          'browse what Taytay LGU offers and track anything you apply for.',
      chips: const <String>['Documents', 'Real property tax', 'Health', 'Jobs'],
      tag: 'Taytay Municipal Hall',
      credit: 'Photo: Ramon FVelasquez · CC BY-SA 3.0',
      photoPath: 'assets/photos/municipal_hall.jpg',
      photoLabel: 'Photo: Taytay Municipal Hall',
      skipLabel: shared.skip,
      nextLabel: shared.next,
      getStartedLabel: shared.started,
      guestLabel: shared.guest,
      guestNote: shared.note,
      stepLabel: 'Step 1 of 3',
    ),
    1 => WelcomePageCopy(
      eyebrow: 'Your Taytay ID, on your phone',
      title: 'Ang Taytay ID mo,\nnasa phone mo na.',
      body:
          'Apply for and carry your Municipality of Taytay digital ID without '
          'queueing at the municipal hall.',
      chips: const <String>['Digital ID', 'No queueing'],
      tag: 'Taytay Tiangge · Garments & Woodcrafts Capital',
      credit: 'Photo: Ralff Nestor Nacor · CC BY-SA 4.0',
      photoPath: 'assets/photos/tiangge.jpg',
      photoLabel: 'Photo: Taytay Tiangge',
      skipLabel: shared.skip,
      nextLabel: shared.next,
      getStartedLabel: shared.started,
      guestLabel: shared.guest,
      guestNote: shared.note,
      stepLabel: 'Step 2 of 3',
    ),
    _ => WelcomePageCopy(
      eyebrow: 'You choose what you share',
      title: 'Ikaw ang pipili\nng ibabahagi.',
      body:
          'Taytay LGU asks only for what a service needs, and tells you why. '
          'Your information is protected under the Data Privacy Act of 2012.',
      chips: const <String>[],
      tag: 'St. John the Baptist Parish Church',
      credit: 'Photo: Urbanroamer · CC BY-SA 3.0',
      photoPath: 'assets/photos/parish_church.jpg',
      photoLabel: 'Photo: St. John the Baptist Parish Church',
      skipLabel: shared.skip,
      nextLabel: shared.next,
      getStartedLabel: shared.started,
      guestLabel: shared.guest,
      guestNote: shared.note,
      stepLabel: 'Step 3 of 3',
    ),
  };
}

Future<void> _paint(WidgetTester tester, int page, String golden) async {
  debugDisableShadows = false;
  const dpr = 3.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = _pixels * dpr;
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
          ).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
          child: widget ?? const SizedBox.shrink(),
        );
      },
      home: ColoredBox(
        key: const ValueKey<String>('welcome-root'),
        color: const Color(0xFFF3F5FA),
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: _pixels.width / dpr,
            height: _pixels.height / dpr,
            child: WelcomeCanvas(
              page: page,
              copy: _copy(page),
              onSkip: () {},
              onNext: () {},
              onBack: () {},
              onGetStarted: () {},
              onGuest: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
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
    tester.getSize(find.byKey(const ValueKey<String>('welcome-root'))),
    _pixels,
  );
  try {
    await expectLater(
      find.byKey(const ValueKey<String>('welcome-root')),
      matchesGoldenFile(golden),
    );
  } finally {
    debugDisableShadows = true;
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('welcome 01-01 hides the speck', (tester) async {
    await _paint(tester, 0, 'welcome/01-01.png');
  });

  testWidgets('welcome 01-02 hides the speck', (tester) async {
    await _paint(tester, 1, 'welcome/01-02.png');
  });

  testWidgets('welcome 01-03 hides the speck', (tester) async {
    await _paint(tester, 2, 'welcome/01-03.png');
  });
}
