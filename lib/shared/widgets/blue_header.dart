import 'package:flutter/material.dart';

import '../../core/design/brand_assets.dart';
import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import 'taytay_back_button.dart';
import 'taytay_icon.dart';

/// The blue header of every in-app screen (CSS `.soft header.bar`).
///
/// The 150° navy → blue → sky gradient, a white circle top-right and a gold
/// circle bottom-left, and 28 px bottom corners. No gold bottom line and no
/// shadow.
///
/// One row: [leading] (usually [HeaderSeal]) or a back control, the title
/// block, then [actions] ([HeaderIconButton]s). [bottom] sits below the row:
/// a search field, filter chips, a greeting. A main tab whose glass body rides
/// up over the header passes [overlap], which leaves the 46 px the body
/// covers.
///
/// The title is 18 / 700 on a tab and 15 / 600 beside a back control
/// (design/README.md "Header bar title").
class BlueHeader extends StatelessWidget {
  const BlueHeader({
    this.title,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.backEnabled = true,
    this.actions = const <Widget>[],
    this.bottom,
    this.overlap = false,
    this.includeSafeArea = true,
    super.key,
  }) : assert(
         title == null || titleWidget == null,
         'Pass a title or a titleWidget, not both.',
       );

  final String? title;
  final String? subtitle;

  /// Replaces the title block, e.g. Home's two-line municipal name.
  final Widget? titleWidget;

  /// Shown when [showBack] is false. Usually a [HeaderSeal].
  final Widget? leading;

  final bool showBack;

  /// Overrides the back control's default, which pops or returns home.
  final VoidCallback? onBack;
  final bool backEnabled;

  final List<Widget> actions;
  final Widget? bottom;

  /// Leaves room for a glass body that rides 32 px up over the header.
  final bool overlap;

  /// False when the header is not at the top of the screen (the gallery).
  final bool includeSafeArea;

  @override
  Widget build(BuildContext context) {
    final double safeTop = includeSafeArea
        ? MediaQuery.paddingOf(context).top
        : 0;
    final Widget? bottom = this.bottom;
    final double bottomPadding = overlap
        ? 46
        : bottom != null
        ? 22
        : 18;

    final Widget row = Row(
      children: <Widget>[
        if (showBack)
          TaytayBackButton(
            onPressed: onBack,
            translucent: true,
            enabled: backEnabled,
          )
        else if (leading case final Widget leading)
          leading,
        if (showBack || leading != null) const SizedBox(width: Spacing.md),
        Expanded(child: titleWidget ?? _titleBlock()),
        for (final Widget action in actions) ...<Widget>[
          const SizedBox(width: Spacing.xs),
          action,
        ],
      ],
    );

    return ClipRRect(
      borderRadius: HeaderShapes.radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: BrandGradients.header.toLinearGradient(),
        ),
        child: Stack(
          children: <Widget>[
            for (final HeaderCircle circle in HeaderShapes.circles)
              _circle(circle),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                safeTop + (bottom != null ? Spacing.lg : 14),
                Spacing.lg,
                bottomPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  row,
                  if (bottom != null) ...<Widget>[
                    const SizedBox(height: Spacing.section),
                    bottom,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBlock() {
    final String? title = this.title;
    final String? subtitle = this.subtitle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null)
          Semantics(
            header: true,
            child: Text(
              title,
              style:
                  (showBack
                          ? AppTypography.headerTitle
                          : AppTypography.pageTitle)
                      .copyWith(color: BrandColors.white),
            ),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xxs),
            child: Text(
              subtitle,
              style: AppTypography.headerSubtitle.copyWith(
                color: BrandColors.onHeaderMuted,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _circle(HeaderCircle circle) {
    return Positioned(
      top: circle.top,
      right: circle.right,
      bottom: circle.bottom,
      left: circle.left,
      width: circle.diameter,
      height: circle.diameter,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: circle.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// The official seal in the header's white circle (CSS `.soft .seal`, 38 px
/// with a 2 px pad). The file is drawn unaltered.
class HeaderSeal extends StatelessWidget {
  const HeaderSeal({this.diameter = ComponentSizes.seal, super.key});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    const BrandAsset seal = BrandAssets.municipalSeal;
    return Semantics(
      label: seal.semanticLabel,
      image: true,
      child: Container(
        width: diameter,
        height: diameter,
        padding: const EdgeInsets.all(2),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: BrandColors.white,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          seal.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// A round button on the blue header (CSS `.soft .ib`): a 44 px disc of white
/// at 14% inside a 48 px target, with an optional red count badge.
///
/// The badge is not read out: put the count in [semanticLabel] ("Notifications,
/// 2 unread"). The count itself comes from the API; pass null for none.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.badgeCount,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final int? count = badgeCount;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: A11y.minTapTarget,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: onPressed,
            radius: ComponentSizes.headerIconButton / 2,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: ComponentSizes.headerIconButton,
                  height: ComponentSizes.headerIconButton,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BrandColors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: TaytayIcon(
                    icon: icon,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: 22,
                    color: BrandColors.white,
                  ),
                ),
                if (count != null && count > 0)
                  Positioned(top: 4, right: 4, child: _Badge(count: count)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BrandColors.red,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: BrandColors.blue, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.category.copyWith(
          fontSize: 10,
          letterSpacing: 0,
          color: BrandColors.white,
        ),
      ),
    );
  }
}
