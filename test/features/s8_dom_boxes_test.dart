import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/typography.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/account/presentation/s8_space.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Two image pixels at the 3× capture. One CSS pixel is one logical pixel.
const double _tol = 2 / 3;

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

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        textScaler: TextScaler.noScaling,
      ),
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: SizedBox(width: 390, height: 844, child: child),
      ),
    ),
  );
  await tester.pump();
}

/// The ancestor whose box is closest to [want]. DOM dumps are border boxes.
Rect _closest(WidgetTester tester, Finder finder, Rect want) {
  RenderObject? node = tester.renderObject<RenderBox>(finder);
  Rect best = Rect.zero;
  var bestDelta = double.infinity;
  while (node is RenderBox && node.hasSize) {
    final Rect got = node.localToGlobal(Offset.zero) & node.size;
    final double delta =
        (got.left - want.left).abs() +
        (got.top - want.top).abs() +
        (got.width - want.width).abs() +
        (got.height - want.height).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      best = got;
    }
    node = node.parent;
  }
  return best;
}

void _expectBox(WidgetTester tester, String label, Finder finder, Rect want) {
  final Rect got = _closest(tester, finder, want);
  expect(
    (got.left - want.left).abs(),
    lessThan(_tol),
    reason: '$label left ${got.left} vs ${want.left}',
  );
  expect(
    (got.top - want.top).abs(),
    lessThan(_tol),
    reason: '$label top ${got.top} vs ${want.top}',
  );
  expect(
    (got.width - want.width).abs(),
    lessThan(_tol),
    reason: '$label width ${got.width} vs ${want.width}',
  );
  expect(
    (got.height - want.height).abs(),
    lessThan(_tol),
    reason: '$label height ${got.height} vs ${want.height}',
  );
}

void main() {
  setUpAll(_loadFonts);

  test('Plus Jakarta Bold matches the Chrome pill advance', () {
    // Chrome's All pill is 44.59375: text + padding 28 + border 2.
    // The 16.59 figure leaves the border out. Letter-spacing stays 0.
    final TextPainter painter = TextPainter(
      text: const TextSpan(
        text: 'All',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          height: S8Space.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    expect(painter.width, closeTo(14.592, 0.05));
    expect(painter.width + 28 + 2, closeTo(44.59375, 0.05));
    painter.dispose();

    final TextPainter unread = TextPainter(
      text: const TextSpan(
        text: 'Unread',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    expect(unread.width + 28 + 2, closeTo(72.5625, 0.05));
    unread.dispose();
  });

  test('Chrome normal line boxes at the 3× capture', () {
    expect(S8Space.line(11), closeTo(13.67, 0.01));
    expect(S8Space.line(12), 15);
    expect(S8Space.line(13), closeTo(16.33, 0.01));
    expect(S8Space.line(14), closeTo(17.67, 0.01));
    expect(S8Space.line(15), 19);
    expect(S8Space.line(16), closeTo(20.33, 0.01));
    expect(S8Space.line(20), 25);
  });

  testWidgets('08 DOM boxes', (WidgetTester tester) async {
    await _pump(tester, const AccountCanvas(frame: AccountFrame.home));
    _expectBox(
      tester,
      'profile card',
      find.textContaining('Juana'),
      const Rect.fromLTWH(16, 120, 358, 102.83),
    );
    _expectBox(
      tester,
      'name line',
      find.textContaining('Juana'),
      const Rect.fromLTWH(101, 137, 256, 22.13),
    );
    _expectBox(
      tester,
      'verified',
      find.text('Verified').first,
      const Rect.fromLTWH(101, 184.63, 78.26, 21.2),
    );
    _expectBox(
      tester,
      'resident profile',
      find.text('Resident Profile'),
      const Rect.fromLTWH(89, 254.49, 238, 17.67),
    );

    await _pump(
      tester,
      const AccountCanvas(
        frame: AccountFrame.inbox,
        title: 'Messages',
        showBack: true,
      ),
    );
    _expectBox(
      tester,
      'header',
      find.text('Messages'),
      const Rect.fromLTWH(0, 0, 390, 104),
    );
    _expectBox(
      tester,
      'All',
      find.text('All'),
      const Rect.fromLTWH(16, 132, 44.59, 36),
    );
    _expectBox(
      tester,
      'Unread',
      find.text('Unread'),
      const Rect.fromLTWH(67.59, 132, 72.56, 36),
    );
    _expectBox(
      tester,
      'BPLO',
      find.text('BPLO'),
      const Rect.fromLTWH(89, 195, 208.73, 17.67),
    );
    _expectBox(
      tester,
      'count',
      find.text('1').first,
      const Rect.fromLTWH(334.45, 220.5, 22.55, 19.67),
    );

    await _pump(
      tester,
      const AccountCanvas(
        frame: AccountFrame.inboxEmpty,
        title: 'Messages',
        showBack: true,
      ),
    );
    _expectBox(
      tester,
      'empty',
      find.text('No messages yet'),
      const Rect.fromLTWH(16, 180, 358, 294.33),
    );
    _expectBox(
      tester,
      'empty title',
      find.text('No messages yet'),
      const Rect.fromLTWH(34, 294, 322, 20.33),
    );
    _expectBox(
      tester,
      'empty button',
      find.text('Message an office'),
      const Rect.fromLTWH(34, 373.33, 322, 48),
    );

    await _pump(
      tester,
      const AccountCanvas(
        frame: AccountFrame.thread,
        title: 'MSWDO',
        subtitle: 'Municipal Social Welfare and Development Office',
        subtitleLines: 2,
        showBack: true,
        showBell: false,
        bubbles: AccountSpecimen.mswdoBubbles,
      ),
    );
    _expectBox(
      tester,
      'mswdo header',
      find.text('MSWDO'),
      const Rect.fromLTWH(0, 0, 390, 121),
    );
    _expectBox(
      tester,
      'Mon',
      find.text('Mon'),
      const Rect.fromLTWH(174.1, 143.67, 41.79, 19.67),
    );
    _expectBox(
      tester,
      'first bubble',
      find.textContaining('Paano po'),
      const Rect.fromLTWH(104, 175.33, 270, 76.55),
    );
    _expectBox(
      tester,
      'office bubble',
      find.textContaining('Pumunta'),
      const Rect.fromLTWH(16, 283.55, 270, 97.4),
    );
    _expectBox(
      tester,
      'salamat',
      find.text('Salamat po sa impormasyon.'),
      const Rect.fromLTWH(104, 503.97, 270, 38.85),
    );

    await _pump(
      tester,
      const AccountCanvas(
        frame: AccountFrame.thread,
        title: 'Treasury',
        subtitle: "Municipal Treasurer's Office",
        showBack: true,
        showBell: false,
        bubbles: AccountSpecimen.treasurerBubbles,
      ),
    );
    _expectBox(
      tester,
      'td bubble',
      find.text('TD No. 00-0000-00000 po (sample).'),
      const Rect.fromLTWH(104, 376.76, 270, 38.85),
    );

    await _pump(
      tester,
      const AccountCanvas(
        frame: AccountFrame.privacy,
        title: 'Privacy Notice',
        showBack: true,
        showBell: false,
      ),
    );
    _expectBox(
      tester,
      'draft',
      find.text('DRAFT · LGU-approved text to be inserted'),
      const Rect.fromLTWH(16, 122.67, 246.18, 19.67),
    );
    _expectBox(
      tester,
      'notice card',
      find.text('What we collect'),
      const Rect.fromLTWH(16, 206.33, 358, 315.67),
    );
    _expectBox(
      tester,
      'sample',
      find.text('SAMPLE'),
      const Rect.fromLTWH(231.73, 482.5, 64.33, 22.5),
    );

    await _pump(
      tester,
      const AccountCanvas(
        frame: AccountFrame.about,
        title: 'Photo credits & about',
        showBack: true,
        showBell: false,
      ),
    );
    _expectBox(
      tester,
      'about card',
      find.text('Taytay Resident App'),
      const Rect.fromLTWH(16, 120, 358, 176.33),
    );
    _expectBox(
      tester,
      'photo credits',
      find.text('Photo credits'),
      const Rect.fromLTWH(16, 312.33, 358, 19),
    );

    await _pump(
      tester,
      const AccountCanvas(
        frame: AccountFrame.banners,
        title: 'Office banner photos',
        showBack: true,
        showBell: false,
      ),
    );
    _expectBox(
      tester,
      'intro',
      find.textContaining('Wikimedia'),
      const Rect.fromLTWH(18, 120, 354, 61.5),
    );
    _expectBox(
      tester,
      'intro replace',
      find.text('Replace').first,
      const Rect.fromLTWH(302.98, 120, 61.85, 22.5),
    );
    _expectBox(
      tester,
      'hall',
      find.text('Taytay Municipal Hall'),
      const Rect.fromLTWH(33, 308.17, 324, 16.33),
    );
  });
}
