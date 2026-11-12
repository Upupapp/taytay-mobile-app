import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/consent_check_card.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/upload_slot.dart';
import '../domain/resident_sector.dart';
import 'sector_apply_controller.dart';
import 'sectors_copy.dart';

/// Apply for a sector, drawn from parameters: step 1 (choose), step 2 (the
/// photo and the confirmation, also while sending) and the result.
///
/// Left out of the mock-ups because `POST /me/sector-applications` takes only
/// the sector and the proof: the solo-parent reason and the number of
/// children, and the ID number with its two dates. Staff read those from the
/// photo when they record the sector. The senior-citizen option is not
/// greyed out by birth date: the office decides who qualifies (D-215).
class SectorApplyCanvas extends StatelessWidget {
  const SectorApplyCanvas({
    required this.step,
    required this.policy,
    this.chosen,
    this.proof,
    this.refused,
    this.confirmed = false,
    this.failure,
    this.filed,
    this.onChoose,
    this.onNext,
    this.onStepBack,
    this.onAddPhoto,
    this.onConfirm,
    this.onSend,
    this.onSectors,
    this.onHome,
    super.key,
  });

  final SectorApplyStep step;
  final UploadPolicy policy;
  final ResidentSector? chosen;
  final CapturedDocument? proof;
  final ({DocumentRejection reason, int bytes})? refused;
  final bool confirmed;
  final AppFailure? failure;
  final SectorApplication? filed;

  final ValueChanged<ResidentSector>? onChoose;
  final VoidCallback? onNext;

  /// Step 2's back: to step 1. Step 1's back leaves the flow.
  final VoidCallback? onStepBack;
  final VoidCallback? onAddPhoto;
  final ValueChanged<bool>? onConfirm;
  final VoidCallback? onSend;
  final VoidCallback? onSectors;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      SectorApplyStep.choose => _Choose(canvas: this),
      SectorApplyStep.proof || SectorApplyStep.sending => _Proof(canvas: this),
      SectorApplyStep.sent => _Sent(canvas: this),
    };
  }
}

/// `SectorApply.dc.html`: the three sectors as radio cards.
class _Choose extends StatelessWidget {
  const _Choose({required this.canvas});

  final SectorApplyCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<ResidentSector>? onChoose = canvas.onChoose;
    return AuthFormPage(
      pageKey: const Key('sector-apply-choose'),
      title: SectorsCopy.chooseTitle,
      subtitle: SectorsCopy.chooseSubtitle,
      stepLabel: SectorsCopy.stepOne,
      progress: 1 / 3,
      progressSemanticLabel: SectorsCopy.stepOne,
      footer: AppButton(
        key: const Key('sector-apply-next'),
        label: SectorsCopy.next,
        onPressed: canvas.chosen == null ? null : canvas.onNext,
      ),
      child: Semantics(
        label: SectorsCopy.choiceGroup,
        container: true,
        child: RadioGroup<ResidentSector>(
          groupValue: canvas.chosen,
          onChanged: (ResidentSector? value) {
            if (value != null) onChoose?.call(value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ResidentSector sector in ResidentSector.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: _SectorChoice(
                    sector: sector,
                    selected: sector == canvas.chosen,
                    onTap: onChoose == null ? null : () => onChoose(sector),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CSS `.opt`: a radio, the sector and what to have ready. Selected, it turns
/// soft blue with a blue outline, as a ticked consent card does.
class _SectorChoice extends StatelessWidget {
  const _SectorChoice({
    required this.sector,
    required this.selected,
    this.onTap,
  });

  final ResidentSector sector;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius corners = BorderRadius.circular(Radii.lg);
    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('sector-choice-${sector.name}'),
          borderRadius: corners,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.reduced(context)
                ? MotionTokens.instant
                : MotionTokens.fast,
            padding: const EdgeInsets.fromLTRB(
              Spacing.xs,
              Spacing.md,
              Spacing.lg,
              Spacing.md,
            ),
            decoration: BoxDecoration(
              color: selected ? BrandColors.blue50 : BrandColors.background,
              borderRadius: corners,
              border: Border.all(
                color: selected ? BrandColors.blue : BrandColors.transparent,
                width: FocusRing.borderWidth,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Radio<ResidentSector>(value: sector),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          SectorsCopy.label(sector),
                          style: AppTypography.listTitle.copyWith(
                            color: BrandColors.ink,
                          ),
                        ),
                        const SizedBox(height: Spacing.xxs),
                        Text(
                          SectorsCopy.choiceNote(sector),
                          style: AppTypography.listDetail.copyWith(
                            color: BrandColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `SectorProof.dc.html`: the photo, what it is for, the confirmation and
/// the send.
class _Proof extends StatelessWidget {
  const _Proof({required this.canvas});

  final SectorApplyCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final ResidentSector sector = canvas.chosen ?? ResidentSector.soloParent;
    final bool sending = canvas.step == SectorApplyStep.sending;
    final CapturedDocument? proof = canvas.proof;
    final ({DocumentRejection reason, int bytes})? refused = canvas.refused;
    final String? problem = refused == null
        ? null
        : localisedDocumentRejection(
            context,
            refused.reason,
            actualBytes: refused.bytes,
            policy: canvas.policy,
          );
    final AppFailure? failure = canvas.failure;
    final ValueChanged<bool>? onConfirm = canvas.onConfirm;
    final bool ready = proof != null && canvas.confirmed;
    return AuthFormPage(
      pageKey: const Key('sector-apply-proof'),
      title: SectorsCopy.proofTitle(sector),
      subtitle: SectorsCopy.proofSubtitle,
      stepLabel: SectorsCopy.stepTwo,
      progress: 2 / 3,
      progressSemanticLabel: SectorsCopy.stepTwo,
      onBack: canvas.onStepBack,
      backEnabled: !sending,
      footer: AppButton(
        key: const Key('sector-apply-send'),
        label: SectorsCopy.send,
        loading: sending,
        hapticIntent: HapticIntent.confirm,
        onPressed: ready && !sending ? canvas.onSend : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            SectorsCopy.photoLabel,
            style: AppTypography.label.copyWith(color: BrandColors.text),
          ),
          const SizedBox(height: Spacing.sm),
          if (proof != null)
            AttachedFileCard(
              icon: TaytayIcons.image,
              title: SectorsCopy.idName(sector),
              status: SectorsCopy.photoAdded(proof.readableSize),
              actionLabel: SectorsCopy.change,
              actionKey: const Key('sector-apply-change'),
              onAction: sending ? null : canvas.onAddPhoto,
            )
          else
            UploadSlot(
              key: const Key('sector-apply-add'),
              label: SectorsCopy.addPhoto,
              error: problem != null,
              onPressed: sending ? null : canvas.onAddPhoto,
            ),
          if (problem != null) ...<Widget>[
            const SizedBox(height: Spacing.xs + Spacing.xxs),
            Semantics(
              liveRegion: true,
              child: Text(
                problem,
                key: const Key('sector-apply-refused'),
                style: AppTypography.fieldHelp.copyWith(
                  color: BrandColors.danger,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: Spacing.formGap),
          const SoftNote(message: SectorsCopy.photoNote, live: false),
          const SizedBox(height: Spacing.formGap),
          ConsentCheckCard(
            key: const Key('sector-apply-confirm'),
            value: canvas.confirmed,
            onChanged: sending || onConfirm == null ? null : onConfirm,
            label: SectorsCopy.confirmLabel,
            description: SectorsCopy.confirmDescription,
          ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: Spacing.formGap),
            _SendFailure(failure: failure),
          ],
        ],
      ),
    );
  }
}

/// Says whether anything reached the office, in this app's words; never the
/// server's message (Article 5.5).
class _SendFailure extends StatelessWidget {
  const _SendFailure({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final ({String title, String body}) copy = sectorSendFailure(failure);
    final String? reference = failure.requestId;
    return SoftNote(
      key: const Key('sector-apply-failure'),
      tone: failure.outcomeUnknown ? NoteTone.warning : NoteTone.error,
      heading: copy.title,
      message: reference == null
          ? copy.body
          : '${copy.body} Reference: $reference',
    );
  }
}

/// What a resident reads when the application did not go through.
({String title, String body}) sectorSendFailure(AppFailure failure) {
  if (failure.outcomeUnknown) {
    return (title: SectorsCopy.unconfirmedTitle, body: SectorsCopy.unconfirmed);
  }
  if (failure is NetworkFailure || failure is TimeoutFailure) {
    return (title: SectorsCopy.offlineTitle, body: SectorsCopy.offline);
  }
  if (failure is ValidationFailure || failure is UnacceptableUploadFailure) {
    return (title: SectorsCopy.refusedTitle, body: SectorsCopy.refused);
  }
  if (failure is ConflictFailure) {
    return (title: SectorsCopy.waitingTitle, body: SectorsCopy.waiting);
  }
  if (failure is ForbiddenFailure) {
    return (title: SectorsCopy.notOpenTitle, body: SectorsCopy.notOpen);
  }
  return (title: SectorsCopy.failedSendTitle, body: SectorsCopy.failedSend);
}

/// `SectorSent.dc.html`: the receipt and what happens next.
class _Sent extends StatelessWidget {
  const _Sent({required this.canvas});

  final SectorApplyCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final SectorApplication? filed = canvas.filed;
    final ResidentSector sector =
        filed?.sector ?? canvas.chosen ?? ResidentSector.soloParent;
    final DateTime? sentAt = filed?.submittedAt;
    final String? when = sentAt == null
        ? null
        : '${ManilaTime.formatDate(sentAt)}, ${ManilaTime.formatTime(sentAt)}';
    final VoidCallback? onSectors = canvas.onSectors;
    return Scaffold(
      key: const Key('sector-apply-sent'),
      backgroundColor: BrandColors.white,
      body: SuccessScreen(
        title: SectorsCopy.sentTitle,
        message: SectorsCopy.sentSubtitle(sector),
        details: <SuccessDetail>[
          SuccessDetail(
            label: SectorsCopy.sentSector,
            value: SectorsCopy.label(sector),
          ),
          if (when != null)
            SuccessDetail(label: SectorsCopy.sentAt, value: when),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SettingsSectionTitle(SectorsCopy.nextHeading),
            Timeline(
              steps: <TimelineStep>[
                TimelineStep(
                  icon: TaytayIcons.check,
                  title: SectorsCopy.stepSent,
                  detail: when ?? '',
                  tone: TimelineTone.done,
                ),
                const TimelineStep(
                  icon: TaytayIcons.clock,
                  title: SectorsCopy.stepCheck,
                  detail: SectorsCopy.stepCheckDetail,
                  tone: TimelineTone.current,
                ),
                const TimelineStep(
                  icon: TaytayIcons.users,
                  title: SectorsCopy.stepAdded,
                  detail: SectorsCopy.stepAddedDetail,
                  tone: TimelineTone.upcoming,
                ),
              ],
            ),
          ],
        ),
        primaryLabel: SectorsCopy.backToSectors,
        onPrimary: onSectors,
        secondaryLabel: SectorsCopy.home,
        onSecondary: canvas.onHome,
        showBack: true,
        onBack: onSectors,
      ),
    );
  }
}
