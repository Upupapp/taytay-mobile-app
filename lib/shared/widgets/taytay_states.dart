import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import '../../core/motion/motion_tokens.dart';
import 'taytay_buttons.dart';
import 'taytay_icon.dart';

/// A white card with the resident radius and shadow.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: BrandColors.cardLine),
        boxShadow: TaytayShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

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
    const base = Color(0xFFE3E8F2);
    if (reduced) {
      return _bar(base);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return _bar(Color.lerp(base, const Color(0xFFF7F8FC), t)!);
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

/// Nothing to show. The sentence says what is empty and what to do.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // gen2 `.empty` is 28×18. The icon disc is 72; the glyph inside is 32.
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: BrandColors.chipGreyBg,
              shape: BoxShape.circle,
            ),
            child: const TaytayIcon(
              icon: TaytayIcons.inbox,
              semanticLabel: '',
              excludeSemantics: true,
              size: 32,
              color: BrandColors.listMeta,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.emptyTitle.copyWith(
              color: BrandColors.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyCompact.copyWith(
              color: BrandColors.textSecondary,
            ),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            PrimaryButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// The device could not reach Taytay LGU. Retry is optional.
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
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const TaytayIcon(
            icon: TaytayIcons.wifiOff,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.xl,
            color: BrandColors.danger,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleCompact.copyWith(
              color: BrandColors.textPrimary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyStyle.copyWith(
              color: BrandColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            PrimaryButton(
              label: 'Try again',
              onPressed: onRetry,
              expand: false,
            ),
          ],
        ],
      ),
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
