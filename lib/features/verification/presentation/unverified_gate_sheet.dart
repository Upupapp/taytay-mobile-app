import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import 's3_chrome.dart';

/// Which verified-only action the gate is explaining.
enum VerifiedOnlyAction { digitalId, message, other }

/// Dark scrim over the whole messages page, header included.
///
/// Tuned so the navy band and the office cards read at the design's dimmed
/// values. It covers the first 300 px, which is the header.
abstract final class GateScrim {
  static const Color color = Color.fromRGBO(0, 24, 84, 0.34);

  static Color at(double t) => Color.fromRGBO(0, 24, 84, 0.34 * t);
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
    return Material(
      color: BrandColors.surfaceCard,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            const _DragHandle(),
            const SizedBox(height: 26),
            const IconTile(
              icon: TaytayIcons.lock,
              fill: BrandColors.chipAmberBg,
              ink: BrandColors.warning,
              size: 28,
              iconSize: 16,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _lead,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: BrandColors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: <Widget>[
                const Text(
                  'Your verification is',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: BrandColors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
                StatusChip(label: statusLabel, tone: StatusTone.pending),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Continue verification',
              onPressed: onContinue,
            ),
            const SizedBox(height: 2),
            TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, A11y.minTapTarget),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: BrandColors.textSecondary,
              ),
              child: const Text(
                'Not now',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  decoration: TextDecoration.none,
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
    return const SizedBox(
      height: 12,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFD6DCE8),
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          child: SizedBox(width: 36, height: 4),
        ),
      ),
    );
  }
}

/// The messages list behind `03-04`: office cards under the navy header.
class GateBackdrop extends StatelessWidget {
  const GateBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BrandColors.surface,
      child: Column(
        children: <Widget>[
          const S3Header(title: 'Messages', subtitle: 'Municipal offices'),
          Expanded(
            child: ListView(
              padding: s3PagePadding,
              children: const <Widget>[
                _OfficeCard(
                  title: "Municipal Treasurer's Office",
                  detail: 'Real property tax, payments',
                ),
                SizedBox(height: s3CardGap),
                _OfficeCard(
                  title: 'Business Permits & Licensing Office',
                  detail: 'Permits and renewals',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return S3Card(
      child: Row(
        children: <Widget>[
          const IconTile(
            icon: TaytayIcons.landmark,
            fill: BrandColors.chipBlueBg,
            ink: BrandColors.taytayBlue,
            size: 44,
            iconSize: 22,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: BrandColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    color: BrandColors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const TaytayIcon(
            icon: TaytayIcons.chevronRight,
            semanticLabel: '',
            excludeSemantics: true,
            size: 18,
            color: BrandColors.chevron,
          ),
        ],
      ),
    );
  }
}

/// `03-04` composed the way the design is drawn: dimmed list, then the sheet.
///
/// The sheet's top edge is the design's y = 1579 device px.
class UnverifiedGatePreview extends StatelessWidget {
  const UnverifiedGatePreview({super.key});

  static const double sheetTop = 1579 / 3;

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: <Widget>[
        GateBackdrop(),
        ModalBarrier(color: GateScrim.color, dismissible: false),
        Positioned(
          top: sheetTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: UnverifiedGateSheet(
            action: VerifiedOnlyAction.message,
            onContinue: _noop,
            onDismiss: _noop,
            fill: true,
          ),
        ),
      ],
    );
  }
}

void _noop() {}
