import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/motion/motion_tokens.dart';

/// A skeleton placeholder shaped like the content that is coming.
///
/// Preferred over a spinner for content, because it preserves the layout: a
/// spinner that is replaced by content causes a reflow, and on a slow connection
/// the resident's thumb is already moving toward where something used to be.
///
/// **Under reduced motion the shimmer stops entirely** and a static block is
/// drawn. A shimmer is a looping animation covering a large area — precisely the
/// kind a resident who asked for less motion asked to be rid of.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    this.width,
    this.height = 16,
    this.borderRadius,
    super.key,
  });

  /// A skeleton line of text.
  const AppSkeleton.text({double? width, super.key})
    : width = width,
      height = 14,
      borderRadius = null;

  /// A skeleton block — an image, an avatar, a card.
  const AppSkeleton.block({
    required double this.width,
    required this.height,
    this.borderRadius,
    super.key,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduced = Motion.reduced(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(Radii.sm);

    // Repeat is started and stopped in build rather than initState so that a
    // mid-session change to the reduced-motion setting takes effect.
    if (reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }

    final base = scheme.surfaceContainerHighest;

    // Excluded from semantics: a screen reader should hear the loading state
    // announced once by the surrounding surface, not a run of empty shapes.
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: reduced
            ? DecoratedBox(
                decoration: BoxDecoration(color: base, borderRadius: radius),
              )
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      base,
                      scheme.surfaceContainer,
                      _controller.value,
                    ),
                    borderRadius: radius,
                  ),
                ),
              ),
      ),
    );
  }
}

/// A determinate-size spinner with an accessible name.
///
/// Used for actions rather than content — a button submitting, a sheet
/// confirming. Content uses [AppSkeleton].
class AppSpinner extends StatelessWidget {
  const AppSpinner({
    this.size = IconSizes.lg,
    this.label = 'Loading',
    super.key,
  });

  final double size;

  /// Announced to screen readers. A spinner with no name is a progress
  /// indicator nobody can perceive.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

/// Full-surface loading state: a spinner with a caption, centred.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({this.message = 'Loading…', super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppSpinner(label: message),
            const SizedBox(height: Spacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
