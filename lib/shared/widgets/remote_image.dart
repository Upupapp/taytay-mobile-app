import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';

/// A picture the LGU published, decoded at the size it will actually be drawn.
///
/// ---
///
/// ## Why this exists rather than `Image.network` at each call site
///
/// `Image.network` decodes at the source resolution. A 4000×3000 cover photo
/// uploaded from a staff phone becomes roughly **48 MB of ARGB in memory** —
/// per card. Three of those on screen while a resident scrolls is enough to get
/// the app killed on the sub-2 GB Android devices a large part of Taytay uses,
/// and the picture is being drawn into a 360 dp-wide card either way.
///
/// So this widget measures the box it was given, multiplies by the device pixel
/// ratio, and hands the result to `cacheWidth`. The decoded bitmap is then the
/// size of the hole it goes in. The same 4000×3000 photo in a 360×203 dp card
/// on a 3× screen decodes to 1080×608 — about **2.6 MB**, an 18× reduction, and
/// visually identical because the extra pixels were never displayable.
///
/// ## Thumbnail versus full size
///
/// [maxDecodeWidth] is the ceiling for a full-size view — a photo opened on its
/// own is allowed more pixels than the same photo in a list. Callers in a feed
/// pass nothing and get the measured size; a detail screen can raise it.
///
/// ## Caching
///
/// Flutter's own `ImageCache` holds decoded frames keyed by URL and dimensions,
/// which is what makes scrolling back up free. It is **in memory**, and this app
/// keeps it that way for the same reason `PublicCache` is in memory: a disk
/// cache is a file whose contents must be reviewed on every future change to
/// what passes through it, and the first authenticated URL that reaches it is
/// personal data at rest outside the keystore. The cost is one refetch per cold
/// start, on public pictures.
///
/// [configureImageCache] raises the budget once at startup, because the default
/// 100 MB / 1000 entries is generous for a feed of municipal photographs and the
/// entry count is what actually matters here.
///
/// ## The placeholder reserves the space
///
/// The box is sized before the bytes arrive, so a picture landing does not push
/// the text a resident is reading down the screen. That is a correctness
/// property, not a polish one: a tap that lands on the wrong card because the
/// layout moved is a resident opening the wrong announcement.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.semanticLabel,
    this.maxDecodeWidth = feedDecodeCeiling,
    this.placeholderIcon = Icons.image_outlined,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.showProgress = false,
    super.key,
  });

  final String url;
  final BoxFit fit;

  /// Present only when the LGU wrote one. A description this app invented for a
  /// picture it cannot see is worse than silence.
  final String? semanticLabel;

  /// Ceiling on the decoded width, in physical pixels.
  final int maxDecodeWidth;

  final IconData placeholderIcon;
  final IconData errorIcon;

  /// Whether the placeholder shows a spinner. Off in lists — a screen of
  /// spinners reads as broken.
  final bool showProgress;

  /// Enough for a full-width card on a 3× phone, with headroom.
  static const int feedDecodeCeiling = 1440;

  /// For a picture opened on its own.
  static const int fullScreenDecodeCeiling = 2560;

  /// Raises Flutter's decoded-image budget once, at startup.
  ///
  /// Called from the composition root rather than from a widget: an image cache
  /// resized during a scroll evicts everything it currently holds, which is the
  /// opposite of the intent.
  static void configureImageCache() {
    final cache = PaintingBinding.instance.imageCache;
    // Municipal photographs, right-sized on decode: more entries at a smaller
    // average size beats the default's assumption of a few large ones.
    cache.maximumSize = 300;
    cache.maximumSizeBytes = 64 << 20; // 64 MB
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The pixel ratio of the view this widget is actually in — not the
        // primary display, which is the wrong one on an external screen.
        final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
        // An unbounded box (a horizontally scrolling row) has no width to
        // measure, so fall back to the view's own width rather than decoding
        // at source resolution.
        final logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final decodeWidth = math.min(
          maxDecodeWidth,
          math.max(1, (logicalWidth * ratio).round()),
        );

        return Image.network(
          url,
          fit: fit,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          // The whole point: decode to the size it will be drawn at.
          cacheWidth: decodeWidth,
          // Keeps the previous frame while a new URL loads, so a rebuild does
          // not blink the card.
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : _Placeholder(
                  icon: placeholderIcon,
                  showProgress: showProgress,
                  scheme: theme.colorScheme,
                ),
          // A picture that will not load must never take the content down with
          // it: the words are the part that matters in an advisory.
          errorBuilder: (context, error, stackTrace) => _Placeholder(
            icon: errorIcon,
            showProgress: false,
            scheme: theme.colorScheme,
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.showProgress,
    required this.scheme,
  });

  final IconData icon;
  final bool showProgress;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: showProgress
            ? const SizedBox(
                width: IconSizes.md,
                height: IconSizes.md,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
