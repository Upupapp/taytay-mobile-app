import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/profile_copy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../platform/domain/verification_review_time.dart';
import '../domain/field_correction_note.dart';
import 'review_time_copy.dart';
import 's3_chrome.dart';

// The verification status pages follow the Account pattern of the redesign:
// the blue header with the back control over the `#F4F6FA` page, a status
// card (gradient tile, the status in words on a pill), then soft cards and
// lists. The ID slots on the correction and start pages are RegID's fields.

/// `03-01` Pending review.
///
/// [accountCreated], [email] and [idType] come from `/me` and the current
/// verification request. Empty means the server did not send them.
class PendingStatusPage extends StatelessWidget {
  const PendingStatusPage({
    this.onBack,
    this.accountCreated = '',
    this.email = '',
    this.idType = '',
    this.submittedOn = '',
    this.residentMessage = '',
    this.categories = const <String>[],
    this.reviewTime = VerificationReviewTime.notSent,
    this.selfieNotice,
    super.key,
  });

  final VoidCallback? onBack;

  /// What happened to the selfie, when the resident has something to do
  /// about it: it was erased after a withdrawal (D-212). Drawn under the
  /// status card, and "No action needed" is then not said.
  final Widget? selfieNotice;
  final String accountCreated;
  final String email;
  final String idType;

  /// `verification_review_working_days` from `GET /app/config`. Not sent keeps
  /// the bundled range; not stated drops the sentence (D-200).
  final VerificationReviewTime reviewTime;

  /// `submitted_at`, already formatted. Empty leaves the progress card as drawn.
  final String submittedOn;

  /// `message` the resident sent with a correction. Empty hides the line.
  final String residentMessage;

  /// Labels for `submitted_categories`. Empty hides the list.
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String? reviewSentence = ReviewTimeCopy.sentence(reviewTime, s);
    return _StatusScaffold(
      title: s.verifStatusTitle,
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StatusCard(
            icon: TaytayIcons.hourglass,
            tone: TileTone.gold,
            title: s.verifPendingTitle,
            chip: StatusChip(
              label: s.verifPendingChip,
              tone: StatusTone.pending,
            ),
            body: <String>[
              <String>[
                s.verifPendingBody,
                ?reviewSentence,
                if (selfieNotice == null) s.verifNoActionNeeded,
              ].join(' '),
              if (residentMessage.isNotEmpty) residentMessage,
            ],
          ),
          if (selfieNotice case final Widget notice) ...<Widget>[
            const SizedBox(height: Spacing.section),
            notice,
          ],
          const SizedBox(height: Spacing.section),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _CardTitle(s.verifProgress),
                const SizedBox(height: Spacing.xs),
                Timeline(
                  steps: <TimelineStep>[
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifStepAccountCreated,
                      detail: _orDash(accountCreated),
                      tone: TimelineTone.done,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifStepEmailConfirmed,
                      detail: _orDash(email),
                      tone: TimelineTone.done,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifStepIdReceived,
                      detail: _orDash(idType),
                      tone: TimelineTone.done,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.clock,
                      title: s.verifStepLguReview,
                      detail: s.verifStepInQueue,
                      tone: TimelineTone.current,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.badgeCheck,
                      title: s.verifyStageVerifiedLabel,
                      detail: s.verifStepVerifiedDetail,
                      tone: TimelineTone.upcoming,
                    ),
                  ],
                ),
                if (submittedOn.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  _Small(s.verifSubmittedOn(submittedOn)),
                ],
                if (categories.isNotEmpty) _Categories(labels: categories),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),
          SoftNote(live: false, message: s.verifPendingBrowseNote),
        ],
      ),
    );
  }
}

/// `03-02` Verified.
class VerifiedStatusPage extends StatelessWidget {
  const VerifiedStatusPage({
    this.onBack,
    this.onHome,
    this.onProfile,
    this.onDigitalId,
    this.onMessage,
    this.onRequestDocuments,
    this.onTulong,
    this.onMyRequests,
    this.verifiedOn = '',
    this.method = '',
    this.replaced = '',
    this.completeness,
    this.linkedToOfficeRecord,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final VoidCallback? onProfile;
  final VoidCallback? onDigitalId;
  final VoidCallback? onMessage;

  /// `linked_to_office_record` from `GET /me` (D-226). True says the account
  /// is linked; false and unknown keep the note that explains the link.
  final bool? linkedToOfficeRecord;

  /// Opens the document-request catalogue.
  final VoidCallback? onRequestDocuments;

  /// Opens Tulong, where a programme page that takes applications offers
  /// Apply (D-226).
  final VoidCallback? onTulong;

  /// Opens My requests (D-223).
  final VoidCallback? onMyRequests;

  /// Date the server says the account was verified. Empty hides the date.
  final String verifiedOn;

  /// How the account was verified, in words (`verification_method`, D-210).
  /// Empty says nothing about it.
  final String method;

  /// What became of a selfie request the office closed when it verified the
  /// account in person (`superseded`). Empty hides the line.
  final String replaced;

  /// Profile completeness when the screen that owns the record has it.
  final int? completeness;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String body = verifiedOn.isEmpty
        ? s.verifVerifiedBody
        : s.verifVerifiedBodyOn(verifiedOn);
    final int? percent = completeness;
    return _StatusScaffold(
      title: s.verifStatusTitle,
      onBack: onBack,
      footer: s.verifGoHome,
      onFooter: onHome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StatusCard(
            icon: TaytayIcons.badgeCheck,
            tone: TileTone.green,
            title: s.verifVerifiedTitle,
            chip: StatusChip(
              label: s.verifyStageVerifiedLabel,
              tone: StatusTone.verified,
            ),
            body: <String>[
              body,
              if (method.isNotEmpty) method,
              if (replaced.isNotEmpty) replaced,
            ],
          ),
          const SizedBox(height: Spacing.section),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _CardTitle(s.verifYouCanNow),
                const SizedBox(height: Spacing.xs),
                Timeline(
                  steps: <TimelineStep>[
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifCanRequestDocuments,
                      detail: s.verifCanRequestDocumentsDetail,
                      tone: TimelineTone.navy,
                      onTap: onRequestDocuments,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifCanMessage,
                      detail: s.verifCanMessageDetail,
                      tone: TimelineTone.navy,
                      onTap: onMessage,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifCanUseId,
                      detail: s.verifCanUseIdDetail,
                      tone: TimelineTone.navy,
                      onTap: onDigitalId,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifiedApplyStep,
                      detail: s.verifiedApplyStepDetail,
                      tone: TimelineTone.navy,
                      onTap: onTulong,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: s.verifiedRequestsStep,
                      detail: s.verifiedRequestsStepDetail,
                      tone: TimelineTone.navy,
                      onTap: onMyRequests,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),
          // The account link (ADR 0004, decision 1): without it My requests
          // reads empty and Apply is refused, and nothing else says why.
          SoftNote(
            key: const Key('verified-link-note'),
            live: false,
            message: linkedToOfficeRecord == true
                ? s.verifiedLinkedNote
                : s.verifiedLinkNote,
          ),
          const SizedBox(height: Spacing.section),
          SettingsList(
            children: <Widget>[
              SettingsRow(
                icon: TaytayIcons.user,
                title: s.verifCompleteProfile,
                detail: percent == null
                    ? null
                    : s.verifPercentComplete(percent),
                progress: percent == null ? null : percent / 100,
                onTap: onProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `03-03` Needs correction, including per-field notes when the office sent them.
class NeedsCorrectionPage extends StatelessWidget {
  const NeedsCorrectionPage({
    this.onBack,
    this.onResubmit,
    this.reason = '',
    this.notes = const <FieldCorrectionNote>[],
    this.idType = '',
    this.reviewedOn = '',
    this.submittedOn = '',
    this.residentMessage = '',
    this.categories = const <String>[],
    this.frontValue,
    this.backValue,
    this.selfieValue,
    this.selfieKept = true,
    this.onFront,
    this.onBackPhoto,
    this.onRetake,
    this.onCheckName,
    this.notice = '',
    this.selfieNotice,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onResubmit;

  /// What stands in the way of a selfie, or what happened to the last one
  /// (D-209, D-210): drawn above the photos.
  final Widget? selfieNotice;
  final String reason;
  final List<FieldCorrectionNote> notes;
  final String idType;
  final String reviewedOn;
  final String submittedOn;
  final String residentMessage;
  final List<String> categories;

  /// What each photo slot says. Null says the design's words, in the
  /// resident's language: "Upload new photo", "Add", "Previous selfie kept".
  final String? frontValue;
  final String? backValue;
  final String? selfieValue;

  /// The design's kept-selfie row. False draws an upload row instead, for a
  /// resident who has not sent one.
  final bool selfieKept;
  final VoidCallback? onFront;
  final VoidCallback? onBackPhoto;
  final VoidCallback? onRetake;

  /// Opens Edit profile, where a rejected resident can change their name.
  final VoidCallback? onCheckName;
  final String notice;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String shown = reason.trim().isEmpty
        ? s.verifCorrectionFallbackReason
        : reason.trim();
    final String reviewed = reviewedOn.trim();
    final String front = frontValue ?? s.verifUploadNewPhoto;
    final String back = backValue ?? s.verifAddPhoto;
    final String selfie = selfieValue ?? s.verifPreviousSelfieKept;
    return _StatusScaffold(
      title: s.verifStatusTitle,
      onBack: onBack,
      footer: s.verifResubmit,
      onFooter: onResubmit,
      notice: notice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const IconTile.lucide(
                      icon: TaytayIcons.triangleAlert,
                      tone: TileTone.red,
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            s.verifNeedsCorrection,
                            style: AppTypography.sectionTitle.copyWith(
                              color: BrandColors.ink,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          StatusChip(
                            label: s.verifNeedsCorrection,
                            tone: StatusTone.correction,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.section),
                _ReasonBox(reason: shown, reviewed: reviewed),
                for (final FieldCorrectionNote note in notes) ...<Widget>[
                  const SizedBox(height: Spacing.md),
                  _FieldNote(note: note),
                ],
                if (residentMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.md),
                  Text(
                    s.verifYourMessage,
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  _Body(residentMessage),
                ],
                if (submittedOn.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  _Small(s.verifSubmittedOn(submittedOn)),
                ],
                if (categories.isNotEmpty) _Categories(labels: categories),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),
          NameCheckNote(onCheckName: onCheckName),
          const SizedBox(height: Spacing.section),
          if (selfieNotice case final Widget notice) ...<Widget>[
            notice,
            const SizedBox(height: Spacing.section),
          ],
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _CardTitle(s.verifSendNewValidId),
                S3Field(
                  label: s.verifIdType,
                  asterisk: true,
                  value: _orDash(idType),
                  chevron: true,
                ),
                S3Field(
                  label: s.verifIdFront,
                  asterisk: true,
                  value: front,
                  dashed: true,
                  onTap: onFront,
                  leading: const _Plus(),
                ),
                S3Field(
                  label: s.verifIdBackOptional,
                  value: back,
                  dashed: true,
                  onTap: onBackPhoto,
                  leading: const _Plus(),
                ),
                if (selfieKept)
                  S3Field(
                    label: s.verifSelfie,
                    value: selfie,
                    readOnly: true,
                    onTap: onRetake,
                    leading: const TaytayIcon(
                      icon: TaytayIcons.circleCheck,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: IconSizes.sm,
                      color: BrandColors.green,
                    ),
                    trailing: Text(
                      s.verifRetake,
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.blue,
                      ),
                    ),
                  )
                else
                  S3Field(
                    label: s.verifSelfie,
                    value: selfie,
                    dashed: true,
                    onTap: onRetake,
                    leading: const _Plus(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Unknown and not-yet-started tiers. Never the verified screen.
class UnverifiedStatusPage extends StatelessWidget {
  const UnverifiedStatusPage({
    this.onBack,
    this.onStart,
    this.below,
    this.notice = '',
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onStart;

  /// Extra card under the status, used once the resident starts. Null leaves
  /// the page as drawn.
  final Widget? below;
  final String notice;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final Widget card = SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconTile.lucide(icon: TaytayIcons.shieldCheck),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.verifNotVerified,
                  style: AppTypography.sectionTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                _Body(s.verifNotVerifiedBody),
              ],
            ),
          ),
        ],
      ),
    );
    final Widget? extra = below;
    return _StatusScaffold(
      title: s.verifStatusTitle,
      onBack: onBack,
      footer: s.verifyActionStart,
      onFooter: onStart,
      notice: notice,
      child: extra == null
          ? card
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                card,
                const SizedBox(height: Spacing.section),
                extra,
              ],
            ),
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '—' : value.trim();

/// Said before an ID is sent: Taytay LGU checks that the ID shows the name on
/// the account, and the name cannot change while it does (D-195).
///
/// On the start and the resubmit pages, ahead of the photos, because a
/// resident who changes their name first does not pick the photos twice.
/// Drawn as RegID's `.namechk`: a filled card with the statement.
class NameCheckNote extends StatelessWidget {
  const NameCheckNote({this.onCheckName, super.key});

  /// Opens Edit profile. Null draws the sentence alone.
  final VoidCallback? onCheckName;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? open = onCheckName;
    final copy = nameCheckCopy(context);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SettingsIcon(icon: TaytayIcons.idCard),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      copy.beforeSendingTitle,
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    _Body(copy.beforeSending),
                  ],
                ),
              ),
            ],
          ),
          if (open != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            SecondaryButton(
              key: const Key('verification-check-name'),
              label: copy.checkName,
              onPressed: open,
            ),
          ],
        ],
      ),
    );
  }
}

/// The status card at the top of a page: a large gradient tile, the status
/// as a title and on a pill, and what it means.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.chip,
    required this.body,
  });

  final IconData icon;
  final TileTone tone;
  final String title;
  final Widget chip;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(Spacing.formGutter),
      child: Column(
        children: <Widget>[
          IconTile.lucide(icon: icon, tone: tone, tileSize: IconTileSize.large),
          const SizedBox(height: Spacing.md),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.pageTitle.copyWith(color: BrandColors.ink),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          chip,
          for (final String line in body) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            _Body(line, align: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: AppTypography.sectionTitle.copyWith(color: BrandColors.ink),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text, {this.align = TextAlign.start});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
  );
}

class _Small extends StatelessWidget {
  const _Small(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.small.copyWith(color: BrandColors.muted));
}

class _Plus extends StatelessWidget {
  const _Plus();

  @override
  Widget build(BuildContext context) => const TaytayIcon(
    icon: TaytayIcons.plus,
    semanticLabel: '',
    excludeSemantics: true,
    size: IconSizes.sm,
    color: BrandColors.blue,
  );
}

/// What the office already holds from the resident, as it named it.
class _Categories extends StatelessWidget {
  const _Categories({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.of(context).verifHeldFromYou,
            style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
          ),
          for (final String label in labels)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Text(
                label,
                style: AppTypography.bodyStyle.copyWith(
                  color: BrandColors.text,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The office's reason, in its own words, under the category label.
class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.reason, required this.reviewed});

  final String reason;
  final String reviewed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.red50,
        borderRadius: BorderRadius.circular(Radii.note),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.section,
          vertical: Spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.of(context).verifReasonHeading,
              style: AppTypography.category.copyWith(color: BrandColors.redInk),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              reason,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.ink),
            ),
            if (reviewed.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.xs),
              _Small(AppStrings.of(context).verifReviewedOn(reviewed)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FieldNote extends StatelessWidget {
  const _FieldNote({required this.note});

  final FieldCorrectionNote note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          note.label,
          style: AppTypography.listTitle.copyWith(color: BrandColors.ink),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          note.note,
          style: AppTypography.bodyStyle.copyWith(color: BrandColors.redInk),
        ),
      ],
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.title,
    required this.child,
    this.onBack,
    this.footer,
    this.onFooter,
    this.notice = '',
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final String? footer;
  final VoidCallback? onFooter;
  final String notice;

  @override
  Widget build(BuildContext context) {
    final String? label = footer;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          S3Header(
            title: title,
            subtitle: 'Bayan ng Taytay · Rizal',
            onBack: onBack,
          ),
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.section,
                Spacing.lg,
                Spacing.xl,
              ),
              children: <Widget>[child],
            ),
          ),
          if (notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                0,
                Spacing.lg,
                Spacing.sm,
              ),
              child: SoftNote(tone: NoteTone.error, message: notice),
            ),
          if (label != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.formGutter,
                Spacing.sm,
                Spacing.formGutter,
                Spacing.xl + safeBottom,
              ),
              child: PrimaryButton(label: label, onPressed: onFooter),
            ),
        ],
      ),
    );
  }
}
