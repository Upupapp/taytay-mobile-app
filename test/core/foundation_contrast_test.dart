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
    for (final gradient in <BrandGradient>[
      BrandGradients.inAppHeader,
      BrandGradients.woven,
    ]) {
      expect(gradient.worstCaseContrastRatio(), greaterThanOrEqualTo(4.5));
      for (final stop in gradient.colors) {
        expect(
          contrastRatio(BrandColors.sealGold, stop),
          greaterThanOrEqualTo(4.5),
          reason: gradient.name,
        );
        expect(
          contrastRatio(Colors.white, WovenGoldGlow.blendOver(stop)),
          greaterThanOrEqualTo(4.5),
          reason: gradient.name,
        );
      }
    }
  });

  test('the gold button label clears the gold fill', () {
    expect(
      contrastRatio(BrandColors.taytayBlueDark, BrandColors.sealGold),
      greaterThanOrEqualTo(4.5),
    );
  });
}
