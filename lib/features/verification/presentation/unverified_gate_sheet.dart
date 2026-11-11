import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/icon_tile.dart';

/// Which verified-only action the gate is explaining.
enum VerifiedOnlyAction {
  // Which verified-only action the sheet is explaining.
  digitalId,
  message,
  other,
}

/// `03-04`. The same gate for every verified-only action, shown in a
/// centred dialog (`AccessGateSheet` opens it through `AppDialog.show`, with
/// [title] as the dialog's title and [icon] above it; design rule: popups are
/// centred). The name is kept for its callers and tests.
///
/// This widget is the dialog's content: what the action needs, and the two
/// buttons. It explains. It does not grant. The route guard is what keeps a
/// verified-only screen from opening.
class UnverifiedGateSheet extends StatelessWidget {
  const UnverifiedGateSheet({
    required this.action,
    required this.onContinue,
    required this.onDismiss,
    super.key,
  });

  final VerifiedOnlyAction action;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  /// The gate's lock tile: the dialog's hero icon.
  static const Widget icon = IconTile.lucide(
    icon: TaytayIcons.lock,
    tone: TileTone.gold,
    tileSize: IconTileSize.large,
  );

  /// What the gate says about the resident's own verification (D-201): only
  /// that the account is not verified, which is why the gate is showing. The
  /// session holds no more than that — not whether an ID was sent, is being
  /// reviewed or was refused — so the gate names no stage. The verification
  /// screen it leads to reads the real one.
  static const String notVerifiedYet = 'Your account is not verified yet.';

  /// The gate's button (D-204). Neutral for the same reason as
  /// [notVerifiedYet]: "Continue verification" is the label for a resident
  /// part-way through (`ResidentVerificationStage.inProgress`), and the gate
  /// cannot tell whether this resident has started. The verification screen
  /// it opens offers the stage's own action.
  static const String goToVerification = 'Go to verification';

  static VerifiedOnlyAction actionFor(ResidentIntentKind intent) =>
      switch (intent) {
        ResidentIntentKind.viewDigitalId => VerifiedOnlyAction.digitalId,
        ResidentIntentKind.messageOffice => VerifiedOnlyAction.message,
        _ => VerifiedOnlyAction.other,
      };

  /// The dialog's title for [action].
  static String titleFor(VerifiedOnlyAction action) => switch (action) {
    VerifiedOnlyAction.digitalId =>
      'Verify your account to open your digital ID',
    VerifiedOnlyAction.message => 'Verify your account to message offices',
    VerifiedOnlyAction.other => 'Verify your account to continue',
  };

  String get title => titleFor(action);

  String get _lead => switch (action) {
    VerifiedOnlyAction.message =>
      'Messaging municipal offices is for verified Taytay residents.',
    VerifiedOnlyAction.digitalId =>
      'Your Taytay digital ID is for verified Taytay residents.',
    VerifiedOnlyAction.other => 'This action is for verified Taytay residents.',
  };

  /// The gate's sentence: what the action needs, then [notVerifiedYet].
  String get message => '$_lead $notVerifiedYet';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
        ),
        AppDialogActions(
          primary: DialogButton(label: goToVerification, onPressed: onContinue),
          text: DialogButton(label: 'Not now', onPressed: onDismiss),
        ),
      ],
    );
  }
}
