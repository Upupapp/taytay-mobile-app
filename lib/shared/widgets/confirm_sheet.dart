import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/haptics/app_haptics.dart';
import 'app_banner.dart';
import 'app_button.dart';
import 'app_sheet.dart';

/// Asks before something a resident cannot undo.
///
/// ---
///
/// ## Why `consequence` is required
///
/// A confirmation that only says "Are you sure?" tests whether somebody meant to
/// tap, not whether they understand what happens. The useful part is the
/// sentence naming the thing they lose — a place at an event that will go to the
/// next person on the waitlist, a consent the office will stop relying on, a
/// session on another device.
///
/// So it is a required parameter rather than an optional one. A caller that has
/// nothing to put there is probably confirming something that does not need
/// confirming, and a dialog nobody needs is how residents learn to dismiss the
/// ones that matter.
///
/// ## Why the destructive action is never the default
///
/// `confirmLabel` describes the action in its own words — "Give up my place",
/// not "OK" — so the button says what it does even when read out of context by a
/// screen reader. Cancel comes second visually but is the safe path: dismissing
/// the sheet by any means returns `false`.
abstract final class ConfirmSheet {
  /// Returns whether the resident confirmed.
  ///
  /// A swipe-away, a back gesture and the cancel button all return `false`.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String consequence,
    required String confirmLabel,
    String? detail,
    bool isDestructive = true,
    String cancelLabel = 'Keep it as it is',
  }) async {
    final confirmed = await AppSheet.show<bool>(
      context: context,
      title: title,
      builder: (context) => _ConfirmBody(
        consequence: consequence,
        detail: detail,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return confirmed ?? false;
  }
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({
    required this.consequence,
    required this.detail,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  final String consequence;
  final String? detail;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppBanner(
          tone: isDestructive ? BannerTone.warning : BannerTone.info,
          title: 'What happens',
          message: consequence,
        ),

        if (detail != null) ...<Widget>[
          const SizedBox(height: Spacing.md),
          Text(detail!, style: theme.textTheme.bodyMedium),
        ],

        const SizedBox(height: Spacing.xl),
        AppButton(
          label: confirmLabel,
          variant: isDestructive
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          // A warning haptic, not a confirm one: this is the moment to pause,
          // and the feedback should not feel like success.
          hapticIntent: HapticIntent.warning,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: Spacing.sm),
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
