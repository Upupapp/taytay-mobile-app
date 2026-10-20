import 'package:flutter/material.dart';

import '../../core/design/brand_assets.dart';
import '../../core/design/design_tokens.dart';

/// Renders the Municipality of Taytay mark.
///
/// **This is the only widget permitted to render official artwork**, and it is
/// deliberately hard to misuse: it exposes a size and nothing else. There is no
/// `color`, no `colorBlendMode`, no `fit`, no `borderRadius`, no `shape` and no
/// `transform` parameter. The woven header's circle is a separate container
/// around this same file. The PNG is not recoloured, cropped or recompressed.
///
/// When [BrandAssets.municipalSeal] is registered, that artwork is drawn with
/// `BoxFit.contain` — preserving its aspect ratio exactly — inside its required
/// clear space.
///
/// When it is not registered, a
/// **typographic wordmark** is drawn instead. The fallback is deliberately not
/// seal-like: it is a rounded rectangle with the letter T and the municipality's
/// name, which nobody could mistake for an official seal. An approximated seal
/// would be indistinguishable from the real one to a resident, and that is the
/// failure mode worth designing against.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 96, this.showWordmark = false, super.key})
    : assert(
        size >= SealIntegrityRules.minRenderedSize,
        'The mark is illegible below SealIntegrityRules.minRenderedSize.',
      );

  /// Rendered size of the mark itself, excluding clear space.
  final double size;

  /// Whether to render the municipality name beneath the mark.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final clearSpace = size * SealIntegrityRules.clearSpaceRatio;
    const seal = BrandAssets.municipalSeal;

    return Semantics(
      label: seal.semanticLabel,
      image: true,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.all(clearSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: size,
              height: size,
              // Exact reproduction: contain preserves the intrinsic aspect
              // ratio, and no colour filter is applied.
              child: Image.asset(seal.assetPath, fit: BoxFit.contain),
            ),
            if (showWordmark) ...<Widget>[
              SizedBox(height: clearSpace + Spacing.xs),
              _Wordmark(compact: size < 64),
            ],
          ],
        ),
      ),
    );
  }
}

/// The municipality's name, set as type.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Taytay LGU IDS',
          textAlign: TextAlign.center,
          style:
              (compact
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (!compact) ...<Widget>[
          const SizedBox(height: Spacing.xxs),
          Text(
            'Municipality of Taytay, Rizal',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
