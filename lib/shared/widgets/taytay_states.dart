import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_glyphs.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import '../../core/motion/motion_tokens.dart';
import 'error_state.dart';
import 'taytay_glyph.dart';
import 'taytay_icon.dart';

/// A loading block. Shimmer is decorative and disappears under reduced motion.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    this.width,
    this.height = 16,
    this.radius = Radii.md,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.emphasised,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    const base = BrandColors.line2;
    if (reduced) {
      return _bar(base);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return _bar(Color.lerp(base, BrandColors.background, t) ?? base);
      },
    );
  }

  Widget _bar(Color color) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
  }
}

/// Nothing to show (CSS `.es`). The title says what is empty, the sentence
/// what to do, and the art makes it read as a state rather than a fault.
///
/// [illustration] picks the art (null draws none); [boxed] puts the state on
/// a white card; [primaryAction] makes the action the solid blue pill.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.illustration = TaytayIllustration.noResults,
    this.boxed = false,
    this.primaryAction = false,
    this.actionIcon,
    this.actionKey,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final TaytayIllustration? illustration;
  final bool boxed;
  final bool primaryAction;
  final IconData? actionIcon;

  /// Key on the action button, for a test or a capture to find it.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final String? actionLabel = this.actionLabel;
    final TaytayIllustration? illustration = this.illustration;
    return StatePanel(
      art: illustration == null
          ? const SizedBox.shrink()
          : IllustrationArt(illustration),
      title: title,
      message: message,
      boxed: boxed,
      action: actionLabel == null
          ? null
          : StateActionButton(
              label: actionLabel,
              onPressed: onAction,
              primary: primaryAction,
              icon: actionIcon,
              key: actionKey,
            ),
    );
  }
}

/// The device could not reach Taytay LGU. Retry is optional.
///
/// Drawn as [ErrorState] with the offline illustration.
class OfflineError extends StatelessWidget {
  const OfflineError({
    required this.onRetry,
    this.title = 'You are offline',
    this.message =
        'Taytay LGU could not be reached. Check your connection and try again.',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: title,
      message: message,
      onRetry: onRetry,
      offline: true,
    );
  }
}

/// A short confirmation. Shown as a widget in the gallery and as a snackbar
/// from [showTaytayToast]. The text is the signal; nothing here is haptic-only.
class TaytayToast extends StatelessWidget {
  const TaytayToast({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.taytayBlueDark,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          children: <Widget>[
            const TaytayIcon(
              icon: TaytayIcons.circleCheck,
              semanticLabel: '',
              excludeSemantics: true,
              color: BrandColors.sealGold,
              size: IconSizes.sm,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyStyle.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [message] in a floating snackbar. Announced because snackbars are
/// live regions in Material.
void showTaytayToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: TaytayToast(message: message),
      ),
    );
}
