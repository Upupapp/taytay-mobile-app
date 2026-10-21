import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';

/// An arch-clipped picture with a credit chip.
///
/// [credit] is required. A photograph without a credit line does not ship.
/// When [image] is null the arch shows a labelled placeholder rather than a
/// borrowed picture.
class ArchPhoto extends StatelessWidget {
  const ArchPhoto({
    required this.credit,
    this.image,
    this.caption,
    this.height = 220,
    super.key,
  });

  final ImageProvider<Object>? image;
  final String credit;
  final String? caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(
      top: Radius.circular(Radii.arch),
      bottom: Radius.circular(Radii.lg),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (image != null)
                  Image(image: image!, fit: BoxFit.cover)
                else
                  const ColoredBox(
                    color: BrandColors.surfaceMuted,
                    child: Center(
                      child: Text(
                        'Photo placeholder',
                        style: AppTypography.label,
                      ),
                    ),
                  ),
                Positioned(
                  left: Spacing.md,
                  right: Spacing.md,
                  bottom: Spacing.md,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: BrandColors.taytayBlueDark.withValues(
                          alpha: 0.82,
                        ),
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.xs,
                        ),
                        child: Text(
                          credit,
                          style: AppTypography.labelStrong.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: AppTypography.label.copyWith(color: BrandColors.inkGold),
          ),
        ],
      ],
    );
  }
}
