import 'package:flutter/material.dart';

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

/// Dark scrim over the whole messages page, header included.
///
/// Tuned so the navy band and the office cards read at the design's dimmed
/// values. It covers the first 300 px, which is the header.
abstract final class GateScrim {
  /// `rgba(6, 35, 88, .35)` over the messages page.
  static const Color color = Color.fromRGBO(6, 35, 88, 0.35);

  static Color at(double t) => Color.fromRGBO(6, 35, 88, 0.35 * t);
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
    final TextStyle body = s3Type(
      13,
      AppTypography.body,
      BrandColors.textSecondary,
      height: 1.5,
    );
    return Material(
      color: BrandColors.surfaceCard,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        // Handle margin-top -8 against padding-top 22 lands the bar at 14.
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            const _DragHandle(),
            const SizedBox(height: 16),
            const IconTile(
              icon: TaytayIcons.lock,
              fill: BrandColors.chipAmberBg,
              ink: BrandColors.warning,
              size: 60,
              iconSize: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: s3Type(18, AppTypography.black, BrandColors.textPrimary),
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Continue verification',
              onPressed: onContinue,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: InkWell(
                onTap: onDismiss,
                child: Center(
                  child: Text(
                    'Not now',
                    style: s3Type(
                      15,
                      AppTypography.black,
                      BrandColors.textSecondary,
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
          color: Color(0xFFD6DCE8),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        child: SizedBox(width: 40, height: 4),
      ),
    );
  }
}

/// The messages list behind `03-04`: office cards under the navy header.
class GateBackdrop extends StatelessWidget {
  const GateBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: BrandColors.surface,
      child: Column(
        children: <Widget>[
          S3Header(title: 'Messages', subtitle: 'Municipal offices'),
          Expanded(
            child: Padding(
              padding: s3PagePadding,
              child: Column(
                children: <Widget>[
                  Opacity(
                    opacity: 0.55,
                    child: _OfficeCard(
                      title: "Municipal Treasurer's Office",
                      detail: 'Real property tax, payments',
                    ),
                  ),
                  SizedBox(height: s3CardGap),
                  Opacity(
                    opacity: 0.55,
                    child: _OfficeCard(
                      title: 'Business Permits & Licensing Office',
                      detail: 'Permits and renewals',
                    ),
                  ),
                ],
              ),
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
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: s3Type(
                    13,
                    AppTypography.body,
                    BrandColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `03-04` composed the way the design is drawn: dimmed list, then the sheet.
///
/// The sheet is anchored to the bottom, the way the design draws it.
class UnverifiedGatePreview extends StatelessWidget {
  const UnverifiedGatePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: <Widget>[
        GateBackdrop(),
        ModalBarrier(color: GateScrim.color, dismissible: false),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: UnverifiedGateSheet(
            action: VerifiedOnlyAction.message,
            onContinue: _noop,
            onDismiss: _noop,
          ),
        ),
      ],
    );
  }
}

void _noop() {}
