import 'package:flutter/material.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/design/typography.dart';
import 'package:taytay_resident/features/verification/presentation/s3_chrome.dart';
import 'package:taytay_resident/features/verification/presentation/unverified_gate_sheet.dart';
import 'package:taytay_resident/shared/widgets/app_dialog.dart';
import 'package:taytay_resident/shared/widgets/surface_cards.dart';

// Redesign Phase 4: the `03-04` specimen moved here from
// unverified_gate_sheet.dart. It names sample offices, and sample names do not
// ship in lib/; only tests and recordings compose this frame.

/// The messages list behind `03-04`: office cards under the navy header.
class GateBackdrop extends StatelessWidget {
  const GateBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: BrandColors.background,
      child: Column(
        children: <Widget>[
          S3Header(title: 'Messages', subtitle: 'Municipal offices'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: Column(
                children: <Widget>[
                  Opacity(
                    opacity: 0.55,
                    child: _OfficeCard(
                      title: "Municipal Treasurer's Office",
                      detail: 'Real property tax, payments',
                    ),
                  ),
                  SizedBox(height: Spacing.md),
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
    return SoftCard(
      child: Row(
        children: <Widget>[
          const IconTile.lucide(icon: TaytayIcons.landmark),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                Text(
                  detail,
                  style: AppTypography.listDetail.copyWith(
                    color: BrandColors.muted,
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

/// `03-04` composed the way the app shows it: dimmed list, then the gate.
///
/// F1: the gate is a centred dialog (design rule: popups are centred), so the
/// panel sits in the middle with the dialog's inset, not on the bottom edge.
class UnverifiedGatePreview extends StatelessWidget {
  const UnverifiedGatePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const GateBackdrop(),
        ModalBarrier(color: GateScrim.color, dismissible: false),
        unverifiedGateDialog(VerifiedOnlyAction.message),
      ],
    );
  }
}

void _noop() {}

/// The verification gate drawn as `AccessGateSheet` opens it — the theme's
/// dialog, the lock tile, the title, the gate — without opening a route, for
/// a still frame.
Widget unverifiedGateDialog(VerifiedOnlyAction action) {
  return Dialog(
    insetPadding: AppDialog.panelInset,
    child: AppDialogPanel(
      title: UnverifiedGateSheet.titleFor(action),
      icon: UnverifiedGateSheet.icon,
      child: UnverifiedGateSheet(
        action: action,
        onContinue: _noop,
        onDismiss: _noop,
      ),
    ),
  );
}

/// Scrim over the specimen's messages page, from the theme's navy at the
/// design's dimming.
abstract final class GateScrim {
  static const double _alpha = 0.35;

  static final Color color = BrandColors.navy.withValues(alpha: _alpha);

  static Color at(double t) => BrandColors.navy.withValues(alpha: _alpha * t);
}
