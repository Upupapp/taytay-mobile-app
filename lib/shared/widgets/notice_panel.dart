import 'package:flutter/material.dart';

import '../../core/design/brand_gradients.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import 'surface_cards.dart';
import 'taytay_icon.dart';

/// One titled point of a [NoticePanel] (CSS `.pt`).
class NoticePoint {
  const NoticePoint({
    required this.title,
    required this.body,
    this.trailing,
    this.suffix = '',
  });

  final String title;
  final String body;

  /// Drawn inline after [body], e.g. a SAMPLE tag on an unconfirmed contact.
  final Widget? trailing;

  /// Text after [trailing], such as the closing full stop.
  final String suffix;
}

/// The notice summary of the redesign (`RegTerms.dc.html` `.pn`): a
/// gradient icon, a bold title with its source line, an optional draft
/// [badge], an [intro] paragraph, and the [points] in a white inner card,
/// one per row with a hairline between.
///
/// On a white page (RegTerms) it fills `#F4F6FA`; on the soft grey page
/// pass [onWhite] false for a white card.
class NoticePanel extends StatelessWidget {
  const NoticePanel({
    required this.title,
    required this.icon,
    this.subtitle,
    this.badge,
    this.intro,
    this.points = const <NoticePoint>[],
    this.footer,
    this.onWhite = true,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? subtitle;

  /// Under the title, e.g. the gold DRAFT pill.
  final Widget? badge;
  final String? intro;
  final List<NoticePoint> points;

  /// Under the points, e.g. a closing sentence.
  final Widget? footer;
  final bool onWhite;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final String? intro = this.intro;
    final Widget? badge = this.badge;
    final Widget? footer = this.footer;
    final BrandGradient tile = BrandGradients.tile(TileTone.blue);
    return SoftCard(
      filled: onWhite,
      radius: Radii.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: ComponentSizes.tile,
                height: ComponentSizes.tile,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: tile.toLinearGradient(),
                  borderRadius: BorderRadius.circular(Radii.tile),
                ),
                child: TaytayIcon(
                  icon: icon,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: IconSizes.sm,
                  color: tile.onColor,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: AppTypography.listTitle.copyWith(
                          fontWeight: AppTypography.strong,
                          color: BrandColors.ink,
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTypography.small.copyWith(
                          color: BrandColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (badge != null) ...<Widget>[
            const SizedBox(height: Spacing.section),
            Align(alignment: AlignmentDirectional.centerStart, child: badge),
          ],
          if (intro != null) ...<Widget>[
            const SizedBox(height: Spacing.section),
            Text(
              intro,
              style: AppTypography.bodyStyle.copyWith(
                color: BrandColors.text,
                height: 1.55,
              ),
            ),
          ],
          if (points.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.section),
            SoftCard(
              filled: !onWhite,
              radius: Radii.lg,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (var i = 0; i < points.length; i++) ...<Widget>[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: BrandColors.divider,
                      ),
                    _Point(point: points[i]),
                  ],
                ],
              ),
            ),
          ],
          if (footer != null) ...<Widget>[
            const SizedBox(height: Spacing.section),
            footer,
          ],
        ],
      ),
    );
  }
}

/// The gold pill that marks text the LGU has not approved yet.
class DraftPill extends StatelessWidget {
  const DraftPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: BrandColors.gold50,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + Spacing.xxs,
          vertical: Spacing.xs,
        ),
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            fontWeight: AppTypography.black,
            color: BrandColors.goldInk,
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.point});

  final NoticePoint point;

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = point.trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              point.title,
              style: AppTypography.listDetail.copyWith(
                fontWeight: AppTypography.strong,
                color: BrandColors.blue,
              ),
            ),
          ),
          const SizedBox(height: Spacing.xxs),
          Text.rich(
            TextSpan(
              text: point.body,
              children: <InlineSpan>[
                if (trailing != null) ...<InlineSpan>[
                  const TextSpan(text: ' '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: trailing,
                  ),
                ],
                if (point.suffix.isNotEmpty) TextSpan(text: point.suffix),
              ],
            ),
            style: AppTypography.listDetail.copyWith(
              color: BrandColors.text,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
