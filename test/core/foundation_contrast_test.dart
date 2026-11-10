import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/brand_gradients.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';

void main() {
  test('ink gold is readable on the light surfaces', () {
    expect(
      contrastRatio(BrandColors.inkGold, BrandColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(BrandColors.inkGold, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(BrandColors.textMuted, BrandColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(BrandColors.textSecondary, BrandColors.surfaceMuted),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('white and seal gold clear the navy header, including the glow', () {
    for (final BrandGradient gradient in <BrandGradient>[
      BrandGradients.inAppHeader,
      BrandGradients.woven,
    ]) {
      expect(gradient.worstCaseContrastRatio(), greaterThanOrEqualTo(4.5));
      for (final stop in gradient.colors) {
        expect(
          contrastRatio(Colors.white, WovenGoldGlow.blendOver(stop)),
          greaterThanOrEqualTo(4.5),
          reason: gradient.name,
        );
      }
    }
    // Gold *text* sits on the navy half: the woven field's eyebrows, and the
    // redesign header's brand line at its top-left. 4.5:1 there.
    for (final stop in BrandGradients.woven.colors) {
      expect(
        contrastRatio(BrandColors.sealGold, stop),
        greaterThanOrEqualTo(4.5),
        reason: 'woven',
      );
    }
    for (final stop in <Color>[BrandColors.navy, BrandColors.blue]) {
      expect(
        contrastRatio(BrandColors.sealGold, stop),
        greaterThanOrEqualTo(4.5),
        reason: 'header, navy half',
      );
    }
    // Redesign: the header now runs out to sky (#2D54E0), where gold is 4.3:1.
    // Gold there is a fill or accent (avatar, progress bar, the 16% circle),
    // never text, so it is held to the 3:1 of a meaningful graphic.
    const BrandGradient goldOnHeader = BrandGradient(
      name: 'goldOnHeader',
      colors: <Color>[BrandColors.navy, BrandColors.blue, BrandColors.sky],
      onColor: BrandColors.sealGold,
    );
    expect(
      goldOnHeader.worstCaseContrastRatio(),
      greaterThanOrEqualTo(A11y.minLargeTextContrastRatio),
    );
  });

  test('the gold button label clears the gold fill', () {
    expect(
      contrastRatio(BrandColors.taytayBlueDark, BrandColors.sealGold),
      greaterThanOrEqualTo(4.5),
    );
  });
}
