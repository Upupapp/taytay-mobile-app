import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import 'taytay_states.dart';

/// The shape of the content that is coming.
enum SkeletonLayout {
  /// Rows with a 44 px tile and two lines: Directory, Account, notifications.
  list,

  /// Rows with two lines and a 76 px thumbnail: Balita, events.
  feed,

  /// Stacked 120 px cards: Home tiles, programmes.
  cards,

  /// A wide photo, a title and a paragraph: a detail page.
  detail,

  /// Lines of a paragraph, [LoadingSkeleton.count] of them: a notice being
  /// read in a dialog, a short list of names in a picker.
  text,

  /// One photo-shaped block: a photo opening in a dialog.
  photo,
}

/// The loading state of a data screen: grey blocks shaped like what will
/// replace them, so nothing jumps when it lands. The shimmer stops under
/// reduced motion ([SkeletonBlock]).
///
/// Read out once as [semanticLabel]; the blocks themselves are silent.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    this.layout = SkeletonLayout.list,
    this.count = 3,
    this.semanticLabel = 'Loading',
    super.key,
  });

  final SkeletonLayout layout;

  /// Rows, cards or lines drawn. Ignored by [SkeletonLayout.detail] and
  /// [SkeletonLayout.photo].
  final int count;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      container: true,
      child: ExcludeSemantics(
        child: switch (layout) {
          SkeletonLayout.list => _card(<Widget>[
            for (var i = 0; i < count; i++) _listRow(),
          ]),
          SkeletonLayout.feed => _card(<Widget>[
            for (var i = 0; i < count; i++) _feedRow(),
          ]),
          SkeletonLayout.cards => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var i = 0; i < count; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : Spacing.section),
                  child: const SkeletonBlock(height: 120, radius: Radii.card),
                ),
            ],
          ),
          SkeletonLayout.detail => _detail(),
          SkeletonLayout.text => _text(count),
          SkeletonLayout.photo => const SkeletonBlock(
            height: ComponentSizes.skeletonPhoto,
            radius: Radii.md,
          ),
        },
      ),
    );
  }

  static Widget _card(List<Widget> rows) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.white,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    );
  }

  static Widget _lines({double first = 0.7, double second = 0.45}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FractionallySizedBox(
          widthFactor: first,
          child: const SkeletonBlock(height: 13, radius: Radii.xs),
        ),
        const SizedBox(height: Spacing.sm),
        FractionallySizedBox(
          widthFactor: second,
          child: const SkeletonBlock(height: 11, radius: Radii.xs),
        ),
      ],
    );
  }

  static Widget _listRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          const SkeletonBlock(
            width: ComponentSizes.tile,
            height: ComponentSizes.tile,
            radius: Radii.tile,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: _lines()),
        ],
      ),
    );
  }

  static Widget _feedRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: _lines(first: 0.9, second: 0.35)),
          const SizedBox(width: 14),
          const SkeletonBlock(width: 76, height: 76, radius: 16),
        ],
      ),
    );
  }

  static Widget _detail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SkeletonBlock(height: 220, radius: Radii.cardLarge),
        const SizedBox(height: Spacing.xl),
        const FractionallySizedBox(
          widthFactor: 0.6,
          child: SkeletonBlock(height: 20, radius: Radii.xs),
        ),
        const SizedBox(height: Spacing.md),
        for (final double width in const <double>[1, 0.95, 0.8])
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: FractionallySizedBox(
              widthFactor: width,
              child: const SkeletonBlock(height: 12, radius: Radii.xs),
            ),
          ),
      ],
    );
  }

  static Widget _text(int lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < lines; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : Spacing.sm),
            child: FractionallySizedBox(
              // The last line of a paragraph stops short, as text does.
              widthFactor: i == lines - 1 ? 0.6 : 1,
              child: const SkeletonBlock(height: 12, radius: Radii.xs),
            ),
          ),
      ],
    );
  }
}
