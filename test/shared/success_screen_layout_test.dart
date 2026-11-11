import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/shared/widgets/success_screen.dart';
import 'package:taytay_resident/shared/widgets/wave_header.dart';

import '../support/layout_matrix.dart';

/// F1, item 4: a long subtitle on [SuccessScreen] ran over the wave header's
/// decorative dot field (bottom right). The centred title block now keeps
/// clear of it on both sides.
void main() {
  const String longTitle = 'Your request to the municipal office was sent';
  const String longSubtitle =
      "We'll notify you in this app when the office answers, and the whole "
      'conversation is saved in My Account › Messages, where you can read it '
      'again or add to it at any time.';

  Widget screen() => const SuccessScreen(
    title: longTitle,
    message: longSubtitle,
    details: <SuccessDetail>[SuccessDetail(label: 'To', value: 'BPLO')],
    primaryLabel: 'Go to Messages',
    onPrimary: _noop,
    secondaryLabel: 'Back to Directory',
    onSecondary: _noop,
    showBack: true,
    onBack: _noop,
  );

  Future<void> pumpAt(WidgetTester tester, double width, double scale) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = Size(width, 1600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      layoutHost(screen(), textScale: scale, scrollable: false),
    );
    await tester.pump();
  }

  void expectClearOfDots(WidgetTester tester, String at) {
    final Rect dots = tester.getRect(find.byKey(WaveHeader.dotFieldKey));
    for (final String text in <String>[longTitle, longSubtitle]) {
      final Rect box = tester.getRect(find.text(text));
      expect(
        box.overlaps(dots),
        isFalse,
        reason: '$at: "$text" ($box) runs over the dot field ($dots)',
      );
    }
  }

  testWidgets('a long subtitle at 360 dp and 200% text clears the dots', (
    tester,
  ) async {
    await pumpAt(tester, 360, 2);
    expectClearOfDots(tester, '360 dp, 200%');
  });

  testWidgets('the title block clears the dots on every phone and scale', (
    tester,
  ) async {
    for (final double width in layoutWidths) {
      for (final double scale in layoutTextScales) {
        await pumpAt(tester, width, scale);
        expectClearOfDots(tester, '$width dp, ${scale}x');
      }
    }
  });

  testWidgets('the centred block stays centred', (tester) async {
    await pumpAt(tester, 360, 2);
    final Rect subtitle = tester.getRect(find.text(longSubtitle));
    expect((subtitle.center.dx - 180).abs(), lessThan(1));
  });

  testWidgets('a long subtitle lays out at 360 / 375 / 430 and 200%', (
    tester,
  ) async {
    await expectCleanLayouts(tester, screen, scrollable: false);
  });
}

void _noop() {}
