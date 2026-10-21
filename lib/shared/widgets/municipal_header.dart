import 'package:flutter/material.dart';

import '../../core/design/brand_assets.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import 'taytay_back_button.dart';
import 'taytay_headers.dart';

/// Navy header for hotlines and notifications. CSS `.hd`: padding 46×16×14,
/// 38 dp seal, 16/800 title, 11/600 subtitle.
class MunicipalHeader extends StatelessWidget {
  const MunicipalHeader({
    required this.title,
    required this.subtitle,
    this.onBack,
    this.plainSeal = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  /// Directory headers draw the seal in a white circle with no gold ring.
  /// Welcome and the woven header keep the ring.
  final bool plainSeal;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, (top == 0 ? 46 : top), 16, 14),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 44,
              height: 44,
              child: OverflowBox(
                minWidth: 48,
                maxWidth: 48,
                minHeight: 48,
                maxHeight: 48,
                child: TaytayBackButton(onPressed: onBack, translucent: true),
              ),
            ),
            const SizedBox(width: 11),
            plainSeal
                ? const _PlainSeal()
                : const FramedSeal(
                    diameter: 38,
                    shadowBlur: 8,
                    shadowOffsetY: 2,
                  ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headerTitle.copyWith(
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headerSubtitle.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 38 dp white circle, 2 dp pad, unaltered seal. No gold ring.
class _PlainSeal extends StatelessWidget {
  const _PlainSeal();

  @override
  Widget build(BuildContext context) {
    const BrandAsset seal = BrandAssets.municipalSeal;
    return Semantics(
      label: seal.semanticLabel,
      image: true,
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          seal.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: seal.semanticLabel,
        ),
      ),
    );
  }
}
