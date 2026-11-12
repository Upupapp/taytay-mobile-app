import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/result/result.dart';
import '../../core/session/biometric_consent_controller.dart';
import '../../features/citizen_api/domain/citizen_contract.dart';
import 'app_dialog.dart';
import 'consent_check_card.dart';
import 'legal_text_sheet.dart';
import 'soft_note.dart';

/// The words of the selfie's consent, the in-person way and withdrawal, in
/// one place so registration, verification and the consents screen say the
/// same thing (D-209, D-210).
abstract final class BiometricConsentCopy {
  static const String dialogTitle = 'Your consent before a selfie';

  static const String whatHeading = 'What the app collects, and why';

  /// What is collected and why, before the text (RA 10173 s.3(b): specific
  /// and informed; NPC Circular 2023-04: one purpose, said plainly).
  static const String what =
      'A selfie: a photo of your face. Taytay LGU staff compare it with the '
      'photo on your ID to confirm that this account is yours, and it is the '
      'photo on your Taytay digital ID once you are verified. A photo of a '
      'face used to confirm who someone is counts as biometric data, so the '
      'app asks for your consent before the camera opens.';

  static const String textHeading = 'The consent Taytay LGU published';

  /// Free consent: refusing costs the resident nothing they are entitled to.
  static const String choice =
      'Agreeing is your choice. If you do not agree, you can still be '
      'verified in person, without a selfie. You can withdraw this consent at '
      'any time under Account, Consents and account requests; withdrawing '
      'erases your selfies.';

  static const String tick =
      'I agree that Taytay LGU may take and use my selfie as described above.';

  static String version(String version) => 'Version $version';

  static const String agree = 'Agree and continue';
  static const String recording = 'Recording your consent…';
  static const String decline = "No, I'll verify in person";

  static const String unavailableHeading =
      'Selfie verification is not available yet';
  static const String unavailable =
      'Taytay LGU has not yet published the consent the app needs before it '
      'can take a selfie, so no selfie can be sent for now. Your account '
      'works without it.';

  static const String inPersonHeading = 'Verify in person';
  static const String inPerson =
      'Bring a valid ID to the MSWDO. Staff check it and verify your account. '
      'No selfie is taken.';

  static const String declinedHeading = 'No selfie was taken';
  static const String declined =
      'You did not agree to the selfie consent, and that is fine. Nothing was '
      'recorded or sent.';

  static const String failedHeading = 'Could not check the selfie consent';
  static const String failed =
      'No selfie can be taken until the app knows where your consent stands. '
      'Check your connection and try again.';

  static const String notRecorded =
      'Your consent was not recorded, so no selfie was taken. You can try '
      'again.';
  static const String notConfirmed =
      'We could not confirm that your consent was recorded, so no selfie was '
      'taken yet. Trying again is safe: it is recorded only once.';

  /// What withdrawing does, said before the button (NPC Circular 2023-04:
  /// the consequences of withdrawal are explained).
  static const String withdrawEffects =
      'Withdrawing erases every selfie you sent, in the same moment. A '
      'verification request still waiting for review then needs a new selfie '
      'before staff can approve it, and a Taytay digital ID loses its photo. '
      'What was already done stays as it is: a withdrawal is not backdated.';

  static const String withdrawButton = 'Withdraw the selfie consent';
  static const String withdrawTitle = 'Withdraw the selfie consent?';
  static const String withdrawConfirm = 'Withdraw and erase my selfies';
  static const String withdrawCancel = 'Keep my consent';
}

/// What the resident did with the consent dialog.
enum BiometricConsentChoice {
  /// The server recorded the consent: the camera may open.
  agreed,

  /// "No, I'll verify in person".
  declined,

  /// Closed without choosing. Nothing changes.
  dismissed,
}

/// Opens the consent before a selfie, in a centred dialog (a decision,
/// DESIGN_SYSTEM.md §8 rule 3), unless it already stands.
///
/// Resolves [BiometricConsentChoice.agreed] only when [controller] says the
/// server took the consent, so a caller opens the camera on that and nothing
/// else. A status that is not [BiometricConsentOwed] is not asked about:
/// given is agreed, anything else is dismissed and the screen's own note
/// says why.
Future<BiometricConsentChoice> ensureBiometricConsent(
  BuildContext context,
  BiometricConsentController controller,
) async {
  final BiometricConsentStatus status = controller.status;
  if (status is BiometricConsentGiven) return BiometricConsentChoice.agreed;
  if (status is! BiometricConsentOwed) return BiometricConsentChoice.dismissed;
  final BiometricConsentChoice? choice =
      await AppDialog.show<BiometricConsentChoice>(
        context: context,
        title: BiometricConsentCopy.dialogTitle,
        builder: (BuildContext dialog) =>
            BiometricConsentPanel(controller: controller, status: status),
      );
  if (choice == BiometricConsentChoice.agreed && controller.allowsSelfie) {
    return BiometricConsentChoice.agreed;
  }
  return choice == BiometricConsentChoice.declined
      ? BiometricConsentChoice.declined
      : BiometricConsentChoice.dismissed;
}

/// The inside of the consent dialog: why, the published text, an unticked
/// tick, Agree and the in-person way. It draws its own actions, because
/// Agree follows the tick and the recording.
class BiometricConsentPanel extends StatefulWidget {
  const BiometricConsentPanel({
    required this.controller,
    required this.status,
    super.key,
  });

  final BiometricConsentController controller;
  final BiometricConsentOwed status;

  @override
  State<BiometricConsentPanel> createState() => _BiometricConsentPanelState();
}

/// The tick inside the consent dialog.
const Key biometricConsentTickKey = Key('biometric-consent-tick');

/// The dialog's Agree button.
const Key biometricConsentAgreeKey = Key('biometric-consent-agree');

/// The dialog's in-person button.
const Key biometricConsentDeclineKey = Key('biometric-consent-decline');

class _BiometricConsentPanelState extends State<BiometricConsentPanel> {
  bool _ticked = false;

  Future<void> _agree() async {
    final bool recorded = await widget.controller.agree();
    if (!mounted || !recorded) return;
    Navigator.of(context).pop(BiometricConsentChoice.agreed);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final bool recording = widget.controller.isRecording;
        final AppFailure? failure = widget.controller.recordFailure;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SoftNote(
              heading: BiometricConsentCopy.whatHeading,
              message: BiometricConsentCopy.what,
              live: false,
            ),
            const SizedBox(height: Spacing.lg),
            Semantics(
              header: true,
              child: Text(
                BiometricConsentCopy.textHeading,
                style: AppTypography.sectionTitle.copyWith(
                  color: BrandColors.ink,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              BiometricConsentCopy.version(widget.status.version),
              style: AppTypography.small.copyWith(color: BrandColors.muted),
            ),
            const SizedBox(height: Spacing.sm),
            NoticeTextColumn(markdown: widget.status.text.bodyMarkdown),
            const SizedBox(height: Spacing.lg),
            Text(
              BiometricConsentCopy.choice,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
            ),
            const SizedBox(height: Spacing.md),
            ConsentCheckCard(
              key: biometricConsentTickKey,
              value: _ticked,
              onChanged: recording
                  ? null
                  : (bool value) => setState(() => _ticked = value),
              label: BiometricConsentCopy.tick,
            ),
            if (failure != null) ...<Widget>[
              const SizedBox(height: Spacing.md),
              SoftNote(
                tone: NoteTone.error,
                message: failure.outcomeUnknown
                    ? BiometricConsentCopy.notConfirmed
                    : BiometricConsentCopy.notRecorded,
              ),
            ],
            const SizedBox(height: Spacing.lg),
            AppDialogActions(
              primary: DialogButton(
                key: biometricConsentAgreeKey,
                label: recording
                    ? BiometricConsentCopy.recording
                    : BiometricConsentCopy.agree,
                loading: recording,
                hapticIntent: HapticIntent.confirm,
                onPressed: _ticked && !recording ? _agree : null,
              ),
              text: DialogButton(
                key: biometricConsentDeclineKey,
                label: BiometricConsentCopy.decline,
                onPressed: recording
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop(BiometricConsentChoice.declined),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The in-person way to be verified, without a selfie (D-210).
///
/// Shown wherever a selfie is not available or was declined. The office's
/// name, address and hours are the directory's (`GET /offices/mswdo`), never
/// written into the app; while they are unknown the note names the MSWDO
/// alone, which is still true.
class InPersonVerificationNote extends StatelessWidget {
  const InPersonVerificationNote({this.office, super.key});

  final MunicipalOffice? office;

  @override
  Widget build(BuildContext context) {
    final MunicipalOffice? known = office;
    final List<String> lines = <String>[
      if (known != null && known.name.trim().isNotEmpty) known.name.trim(),
      if (known != null && known.address.trim().isNotEmpty)
        known.address.trim(),
      if (known != null && known.hours.trim().isNotEmpty)
        'Hours: ${known.hours.trim()}',
      if (known != null && known.phone.trim().isNotEmpty)
        'Phone: ${known.phone.trim()}',
    ];
    final String details = lines.isEmpty ? '' : '\n\n${lines.join('\n')}';
    return SoftNote(
      key: inPersonVerificationNoteKey,
      heading: BiometricConsentCopy.inPersonHeading,
      message: '${BiometricConsentCopy.inPerson}$details',
      live: false,
    );
  }
}

/// The in-person note.
const Key inPersonVerificationNoteKey = Key('in-person-verification');
