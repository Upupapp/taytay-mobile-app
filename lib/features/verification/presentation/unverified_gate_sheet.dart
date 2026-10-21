import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import 's3_chrome.dart';

/// Which verified-only action the gate is explaining.
enum VerifiedOnlyAction {
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
    super.key,
  });

  final VerifiedOnlyAction action;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;
  final String statusLabel;

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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.surfaceCard,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TaytayIcon(
              icon: TaytayIcons.clock,
              semanticLabel: '',
              excludeSemantics: true,
              size: 28,
              color: BrandColors.warning,
            ),
            const SizedBox(height: 29),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: BrandColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _bodyLead,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: BrandColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                  color: BrandColors.textSecondary,
                ),
                children: <InlineSpan>[
                  const TextSpan(text: 'residents. Your verification is '),
                  TextSpan(
                    text: statusLabel,
                    style: const TextStyle(
                      color: BrandColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Transform.translate(
              offset: const Offset(0, -1),
              child: PrimaryButton(
                label: 'Continue verification',
                onPressed: onContinue,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Text(
                  'Not now',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: BrandColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _bodyLead => switch (action) {
    VerifiedOnlyAction.message =>
      'Messaging municipal offices is for verified Taytay',
    VerifiedOnlyAction.digitalId =>
      'Your Taytay digital ID is for verified Taytay',
    VerifiedOnlyAction.other => 'This action is for verified Taytay',
  };
}

/// The messages list behind `03-04`, dimmed, for the side-by-side.
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
              padding: const EdgeInsets.fromLTRB(16, 34, 16, 16),
              children: const <Widget>[
                _OfficeRow(
                  title: "Municipal Treasurer's Office",
                  detail: 'Real property tax, payments',
                ),
                SizedBox(height: 38),
                _OfficeRow(
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

class _OfficeRow extends StatelessWidget {
  const _OfficeRow({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TaytayIcon(
            icon: TaytayIcons.landmark,
            semanticLabel: '',
            excludeSemantics: true,
            color: BrandColors.taytayBlue,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: BrandColors.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: BrandColors.textSecondary,
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

/// `03-04` composed the way the design is drawn: list, then the sheet.
class UnverifiedGatePreview extends StatelessWidget {
  const UnverifiedGatePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const GateBackdrop(),
        const ModalBarrier(
          color: Color.fromRGBO(136, 136, 156, 0.66),
          dismissible: false,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: UnverifiedGateSheet(
            action: VerifiedOnlyAction.message,
            onContinue: () {},
            onDismiss: () {},
          ),
        ),
      ],
    );
  }
}
