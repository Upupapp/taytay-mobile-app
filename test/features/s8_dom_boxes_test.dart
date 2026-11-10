import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/typography.dart';
import 'package:taytay_resident/features/account/presentation/s8_space.dart';

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

void main() {
  // Only plain tests remain here, so nothing else starts the binding that
  // `rootBundle` needs.
  TestWidgetsFlutterBinding.ensureInitialized();
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

  // Redesign P3c: the "08 DOM boxes" test pinned the retired 08-01…08-10
  // Account mock-up box by box and was skipped since Phase 1. Account now
  // follows design/mobile/screens/Account.dc.html; its layout is checked by
  // test/features/redesign_p3c_layout_test.dart (rows, avatar, ID button,
  // glass list, 360/375/430 × 200%), so the old box test was deleted.
}
