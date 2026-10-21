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
              child: MunicipalHeaderTitles(title: title, subtitle: subtitle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title is a 16 dp block. The subtitle is 11 dp text on a 16 dp line.
///
/// The designs put the title ink at y 157 and the subtitle at y 229 on a
/// 3× frame. A 1.2 line box sat the title low and the subtitle high.
class MunicipalHeaderTitles extends StatelessWidget {
  const MunicipalHeaderTitles({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  static const TextStyle _title = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1,
    color: Colors.white,
    decoration: TextDecoration.none,
  );

  static const TextStyle _subtitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1,
    color: Color(0xCCFFFFFF),
    decoration: TextDecoration.none,
  );

  static const StrutStyle _titleStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 1,
    forceStrutHeight: true,
  );

  static const StrutStyle _subtitleStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    height: 16 / 11,
    leadingDistribution: TextLeadingDistribution.even,
    forceStrutHeight: true,
  );

  static const TextHeightBehavior _block = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 14 image px at the 3× capture. The same amount above the title
        // keeps the title ink where it is while the subtitle moves down
        // onto the design's y 229 line. The column stays inside the 44 dp row.
        const SizedBox(height: 14 / 3),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _title,
          strutStyle: _titleStrut,
          textHeightBehavior: _block,
        ),
        const SizedBox(height: 14 / 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _subtitle,
          strutStyle: _subtitleStrut,
          textHeightBehavior: _block,
        ),
      ],
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
