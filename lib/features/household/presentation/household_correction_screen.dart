import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../domain/household_summary.dart';

/// Report an error in the household record.
///
/// ---
///
/// **This raises a question; it never makes a change** (acceptance 3). The
/// resident picks one category from a closed list, and that is the entire
/// payload. There is no target value, no replacement address, no person and no
/// household identifier, so nothing sent from here could be interpreted by any
/// server as an instruction to rewrite canonical membership — today or after the
/// endpoint exists.
///
/// **There is no free-text box, deliberately.** A text field on a household
/// screen invites a resident to type the things this app must never hold: a
/// relative's medical condition, why somebody left, an allegation about another
/// household. That text would sit in memory, in a crash report and in the OS
/// task-switcher snapshot — for a submission that currently has nowhere to go.
/// A category routes them to the right counter, which is what the correction
/// needs; the detail belongs to the conversation with the person who can act.
///
/// **Nobody can be moved between households from here.** There is no category
/// for it and no field that could name a destination. Household composition is a
/// registry decision with eligibility consequences for two households at once,
/// and it is not something one member of one of them should be able to start
/// from a phone.
///
/// **The municipal hall is always the answer, not the fallback.** Even when the
/// endpoint exists, a correction is reviewed by a person; the counter is where
/// evidence is shown and the record is actually changed. So the route is stated
/// up front rather than offered after a failure.
class HouseholdCorrectionScreen extends StatefulWidget {
  const HouseholdCorrectionScreen({super.key});

  @override
  State<HouseholdCorrectionScreen> createState() =>
      _HouseholdCorrectionScreenState();
}

class _HouseholdCorrectionScreenState extends State<HouseholdCorrectionScreen> {
  HouseholdCorrectionKind? _selected;
  bool _sending = false;
  bool _sent = false;
  AppFailure? _failure;

  /// One key per attempt, reused on retry: two identical corrections in a
  /// municipal queue is a real cost to the office that has to close one.
  String? _idempotencyKey;

  Future<void> _send() async {
    final kind = _selected;
    if (kind == null || _sending) return;

    final dependencies = AppDependencies.of(context);
    final reduced = Motion.reduced(context);

    setState(() {
      _sending = true;
      _failure = null;
      _sent = false;
    });
    _idempotencyKey ??= DateTime.now().microsecondsSinceEpoch.toString();

    final result = await dependencies.householdRepository
        .submitCorrectionRequest(
          request: HouseholdCorrectionRequest(kind: kind),
          idempotencyKey: _idempotencyKey!,
        );
    if (!mounted) return;

    setState(() {
      _sending = false;
      result.fold(
        onOk: (_) {
          _sent = true;
          // Spent. A further report is a new question, not a replay.
          _idempotencyKey = null;
        },
        onErr: (failure) => _failure = failure,
      );
    });

    await AppHaptics.fire(
      _sent ? HapticIntent.confirm : HapticIntent.error,
      suppressed: reduced,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormPage(
      title: 'Report an error',
      subtitle: 'Household and family',
      // The whole form, Send included, sits inside the gate: an account that
      // may not read the household record is not offered a way to report on
      // it either.
      child: CapabilityGate(
        capability: ResidentCapability.viewHouseholdSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                'What looks wrong?',
                style: AppTypography.pageTitle.copyWith(color: BrandColors.ink),
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Pick the closest one. Taytay LGU staff will check the record — '
              'nothing changes until they do.',
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
            ),
            const SizedBox(height: Spacing.lg),

            SoftCard(
              filled: true,
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
              child: Column(
                children: <Widget>[
                  for (final kind in HouseholdCorrectionKind.values)
                    RadioListTile<HouseholdCorrectionKind>(
                      value: kind,
                      // ignore: deprecated_member_use
                      groupValue: _selected,
                      // ignore: deprecated_member_use
                      onChanged: _sent
                          ? null
                          : (value) => setState(() => _selected = value),
                      title: Text(
                        householdCorrectionCopy(context, kind).label,
                        style: AppTypography.listTitle.copyWith(
                          color: BrandColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        householdCorrectionCopy(context, kind).description,
                        style: AppTypography.listDetail.copyWith(
                          color: BrandColors.muted,
                        ),
                      ),
                      isThreeLine: false,
                    ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.formGap),
            const SoftNote(
              tone: NoteTone.warning,
              live: false,
              heading: 'Please do not type personal details here',
              message:
                  'This app asks only what kind of thing is wrong. Names, '
                  'health information and reasons belong in the conversation '
                  'with staff, who can record them properly and act on them.',
            ),
            const SizedBox(height: Spacing.md),
            const SoftNote(
              live: false,
              heading: 'Bring it to the municipal hall',
              message:
                  'Household records are changed by Taytay LGU staff after '
                  'they look at your documents. Visit the municipal hall with '
                  'a valid ID — you do not need this app or your phone to be '
                  'served there.',
            ),

            if (_sent) ...<Widget>[
              const SizedBox(height: Spacing.md),
              const SoftNote(
                tone: NoteTone.success,
                heading: 'Taytay LGU has your report',
                message:
                    'Staff will check the record. Nothing has been changed '
                    'yet, and you will be told what they find.',
              ),
            ],
            if (_failure != null) ...<Widget>[
              const SizedBox(height: Spacing.md),
              const SoftNote(
                tone: NoteTone.warning,
                heading: 'Could not send your report',
                message:
                    'Taytay LGU has not switched on household reports in '
                    'this app yet. Nothing was sent, and nothing has changed. '
                    'The municipal hall can take it in person.',
              ),
            ],

            const SizedBox(height: Spacing.formGap),
            AppButton(
              label: 'Send report',
              loading: _sending,
              onPressed: _selected == null || _sending || _sent ? null : _send,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Sending this does not change your household record.',
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(color: BrandColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
