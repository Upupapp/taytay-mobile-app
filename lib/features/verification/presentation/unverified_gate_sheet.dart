import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import 's3_chrome.dart';

/// Which verified-only action the gate is explaining.
enum VerifiedOnlyAction {
  // Which verified-only action the sheet is explaining.
  digitalId,
  message,
  other,
}

/// `03-04`. The same sheet for every verified-only action.
///
/// It explains. It does not grant. The route guard is what keeps a
/// verified-only screen from opening.
class UnverifiedGateSheet extends StatelessWidget {
  const UnverifiedGateSheet({
    required this.action,
    required this.onContinue,
    required this.onDismiss,
    this.statusLabel = 'Pending review',
    this.fill = false,
    super.key,
  });

  final VerifiedOnlyAction action;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;
  final String statusLabel;

  /// Stretch to the positioned frame used by the design preview.
  final bool fill;

  static VerifiedOnlyAction actionFor(ResidentIntentKind intent) =>
      switch (intent) {
        ResidentIntentKind.viewDigitalId => VerifiedOnlyAction.digitalId,
        ResidentIntentKind.messageOffice => VerifiedOnlyAction.message,
        _ => VerifiedOnlyAction.other,
      };

  String get title => switch (action) {
    VerifiedOnlyAction.digitalId =>
      'Verify your account to open your digital ID',
    VerifiedOnlyAction.message => 'Verify your account to message offices',
    VerifiedOnlyAction.other => 'Verify your account to continue',
  };

  String get _lead => switch (action) {
    VerifiedOnlyAction.message =>
      'Messaging municipal offices is for verified Taytay residents.',
    VerifiedOnlyAction.digitalId =>
      'Your Taytay digital ID is for verified Taytay residents.',
    VerifiedOnlyAction.other => 'This action is for verified Taytay residents.',
  };

  @override
  Widget build(BuildContext context) {
    final TextStyle body = AppTypography.bodyStyle.copyWith(
      color: BrandColors.text,
    );
    return Material(
      color: BrandColors.white,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(Radii.sheet),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.formGutter,
          Spacing.section,
          Spacing.formGutter,
          Spacing.xl,
        ),
        child: Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            const _DragHandle(),
            const SizedBox(height: Spacing.lg),
            const IconTile.lucide(
              icon: TaytayIcons.lock,
              tone: TileTone.gold,
              tileSize: IconTileSize.large,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.pageTitle.copyWith(color: BrandColors.ink),
            ),
            const SizedBox(height: Spacing.sm),
            Text.rich(
              TextSpan(
                style: body,
                children: <InlineSpan>[
                  TextSpan(text: '$_lead Your verification is '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: StatusChip(
                      label: statusLabel,
                      tone: StatusTone.pending,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            PrimaryButton(
              label: 'Continue verification',
              onPressed: onContinue,
            ),
            const SizedBox(height: Spacing.sm),
            SizedBox(
              height: A11y.minTapTarget,
              width: double.infinity,
              child: InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(Radii.button),
                child: Center(
                  child: Text(
                    'Not now',
                    style: AppTypography.button.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.line2,
          borderRadius: BorderRadius.all(Radius.circular(Radii.pill)),
        ),
        child: SizedBox(width: Spacing.xxxl - Spacing.sm, height: Spacing.xs),
      ),
    );
  }
}
