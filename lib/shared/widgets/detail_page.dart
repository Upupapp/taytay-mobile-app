import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'blue_header.dart';
import 'taytay_back_button.dart';
import 'taytay_icon.dart';

/// `Office.dc.html` `.hero`: a full-width photo with a navy scrim at the top,
/// the translucent back control and the seal over it, and an optional credit
/// pill above where the sheet starts.
///
/// The page puts a [DetailSheet] under it inside
/// `GlassOverlap(amount: Radii.sheetLarge)`, so the sheet's corners ride up
/// over the photo. A page with no photo uses a `BlueHeader(showBack: true)`
/// instead and no overlap.
class DetailHero extends StatelessWidget {
  const DetailHero({required this.photo, this.onBack, this.credit, super.key});

  /// The photo's height under the status bar (CSS `.hero` 250 px).
  static const double photoHeight = 250;

  /// Fills the hero. It carries its own semantics label.
  final Widget photo;
  final VoidCallback? onBack;

  /// Image credit from the API. Not drawn when null or empty.
  final String? credit;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    final String? credit = this.credit;
    return SizedBox(
      height: photoHeight + top,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(color: BrandColors.navy, child: photo),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  BrandColors.navy.withValues(alpha: 0.55),
                  BrandColors.navy.withValues(alpha: 0),
                ],
                stops: const <double>[0, 0.38],
              ),
            ),
          ),
          Positioned(
            left: Spacing.lg,
            right: Spacing.lg,
            top: top + Spacing.section,
            child: Row(
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: A11y.backButtonVisual,
                      height: A11y.backButtonVisual,
                      decoration: BoxDecoration(
                        color: BrandColors.navy.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    TaytayBackButton(onPressed: onBack, translucent: true),
                  ],
                ),
                const Spacer(),
                const HeaderSeal(),
              ],
            ),
          ),
          if (credit != null && credit.isNotEmpty)
            Positioned(
              left: Spacing.lg,
              right: Spacing.section,
              bottom: Radii.sheetLarge + Spacing.section,
              child: Align(
                alignment: Alignment.centerRight,
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrandColors.navy.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm + Spacing.xxs,
                        vertical: Spacing.xs,
                      ),
                      child: Text(
                        credit,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.tiny.copyWith(
                          fontWeight: AppTypography.medium,
                          color: BrandColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `Office.dc.html` `.sheet`: white, 28 px top corners, 22 / 20 padding.
/// The children are stacked full width; the caller spaces them
/// (`Spacing.formGap` between parts, as in the mock-up).
class DetailSheet extends StatelessWidget {
  const DetailSheet({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Radii.sheetLarge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.formGutter,
          Spacing.xl - Spacing.xxs,
          Spacing.formGutter,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// `Office.dc.html` `.fact`: a 36 px soft square with the icon, the label
/// over the value, and a hairline under the row.
///
/// With [onTap] the whole row is one button (key [tapKey]) with a chevron,
/// announced as "label, value".
class DetailFactRow extends StatelessWidget {
  const DetailFactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
    this.tapKey,
    this.divider = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Drawn after the value, e.g. a sample tag.
  final Widget? trailing;
  final VoidCallback? onTap;
  final Key? tapKey;

  /// The hairline under the row.
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = this.trailing;
    final VoidCallback? onTap = this.onTap;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.section),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: ComponentSizes.tileSmall,
            height: ComponentSizes.tileSmall,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BrandColors.background,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: TaytayIcon(
              icon: icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.blue,
            ),
          ),
          const SizedBox(width: Spacing.section),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AppTypography.small.copyWith(
                    fontWeight: AppTypography.medium,
                    color: BrandColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Spacing.xs + Spacing.xxs,
                  children: <Widget>[
                    Text(
                      value,
                      style: AppTypography.bodyStyle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: Spacing.sm),
            const Padding(
              padding: EdgeInsets.only(top: Spacing.sm),
              child: TaytayIcon(
                icon: TaytayIcons.chevronRight,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: BrandColors.chevron,
              ),
            ),
          ],
        ],
      ),
    );
    final Widget lined = divider
        ? DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: BrandColors.divider)),
            ),
            child: row,
          )
        : row;
    if (onTap == null) return lined;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: InkWell(key: tapKey, onTap: onTap, child: lined),
    );
  }
}
