import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'form_page.dart';
import 'icon_tile.dart';
import 'taytay_icon.dart';

/// RegID `.add`: an empty file slot, a 2 px dashed outline on white with a
/// plus disc and [label] in blue. One button; disabled (muted) when
/// [onPressed] is null. [error] turns the outline red; the screen says why
/// in words beside it, so colour is never the only signal.
class UploadSlot extends StatelessWidget {
  const UploadSlot({
    required this.label,
    required this.onPressed,
    this.error = false,
    super.key,
  });

  /// The minimum height (CSS `min-height: 96px`).
  static const double minHeight = 96;

  final String label;
  final VoidCallback? onPressed;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final Color ink = onPressed == null ? BrandColors.muted : BrandColors.blue;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: BrandColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: CustomPaint(
            painter: _DashedOutline(
              colour: error ? BrandColors.red : BrandColors.line2,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: const ShapeDecoration(
                        color: BrandColors.blue50,
                        shape: CircleBorder(),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.sm),
                        child: TaytayIcon(
                          icon: TaytayIcons.plus,
                          semanticLabel: '',
                          excludeSemantics: true,
                          size: IconSizes.sm,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm - Spacing.xxs),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.listTitle.copyWith(
                        fontWeight: AppTypography.strong,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// RegID `.file`: a file that has been chosen — a gradient tile, [title],
/// a green check with [status], and one text action (Change, Remove).
///
/// The file itself is never drawn back: a photo of an ID stays off the
/// screen once it is chosen.
class AttachedFileCard extends StatelessWidget {
  const AttachedFileCard({
    required this.title,
    required this.status,
    this.icon = TaytayIcons.fileText,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  });

  final String title;
  final String status;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final String? actionLabel = this.actionLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.background,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.section,
          Spacing.md,
          Spacing.xs,
          Spacing.md,
        ),
        child: Row(
          children: <Widget>[
            IconTile.lucide(icon: icon),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Row(
                    children: <Widget>[
                      const TaytayIcon(
                        icon: TaytayIcons.circleCheck,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: IconSizes.sm - Spacing.xs,
                        color: BrandColors.green,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Flexible(
                        child: Text(
                          status,
                          style: AppTypography.small.copyWith(
                            fontWeight: AppTypography.strong,
                            color: BrandColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              AuthLink(actionLabel, key: actionKey, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

/// `.add { border: 2px dashed var(--line2); border-radius: 16px }`.
class _DashedOutline extends CustomPainter {
  const _DashedOutline({required this.colour});

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 2;
    final Paint paint = Paint()
      ..color = colour
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    final Path outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(stroke / 2),
          const Radius.circular(Radii.lg),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOutline oldDelegate) =>
      oldDelegate.colour != colour;
}
