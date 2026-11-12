import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../platform/domain/verification_review_time.dart';
import '../../profile/domain/name_lock.dart';
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
    final String? reviewSentence = ReviewTimeCopy.sentence(reviewTime);
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StatusCard(
            icon: TaytayIcons.hourglass,
            tone: TileTone.gold,
            title: "We're reviewing your account",
            chip: const StatusChip(
              label: 'Pending review',
              tone: StatusTone.pending,
            ),
            body: <String>[
              <String>[
                'Taytay LGU staff are checking your valid ID and selfie.',
                ?reviewSentence,
                if (selfieNotice == null) 'No action needed.',
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
                const _CardTitle('Progress'),
                const SizedBox(height: Spacing.xs),
                Timeline(
                  steps: <TimelineStep>[
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: 'Account created',
                      detail: _orDash(accountCreated),
                      tone: TimelineTone.done,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: 'Email confirmed',
                      detail: _orDash(email),
                      tone: TimelineTone.done,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: 'Valid ID and selfie received',
                      detail: _orDash(idType),
                      tone: TimelineTone.done,
                    ),
                    const TimelineStep(
                      icon: TaytayIcons.clock,
                      title: 'LGU review',
                      detail: 'In queue',
                      tone: TimelineTone.current,
                    ),
                    const TimelineStep(
                      icon: TaytayIcons.badgeCheck,
                      title: 'Verified',
                      detail: 'Unlocks document requests and messaging offices',
                      tone: TimelineTone.upcoming,
                    ),
                  ],
                ),
                if (submittedOn.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  _Small('Submitted $submittedOn'),
                ],
                if (categories.isNotEmpty) _Categories(labels: categories),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),
          const SoftNote(
            live: false,
            message:
                'While pending you can browse services, news and events, and '
                'use emergency hotlines.',
          ),
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
    this.verifiedOn = '',
    this.method = '',
    this.replaced = '',
    this.completeness,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final VoidCallback? onProfile;
  final VoidCallback? onDigitalId;
  final VoidCallback? onMessage;

  /// Opens the document-request catalogue.
  final VoidCallback? onRequestDocuments;

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
    final String body = verifiedOn.isEmpty
        ? 'You now have full access to resident services.'
        : 'Verified by Taytay LGU on $verifiedOn. You now '
              'have full access to resident services.';
    final int? percent = completeness;
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      footer: 'Go to Home',
      onFooter: onHome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StatusCard(
            icon: TaytayIcons.badgeCheck,
            tone: TileTone.green,
            title: 'Your account is verified',
            chip: const StatusChip(
              label: 'Verified',
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
                const _CardTitle('You can now'),
                const SizedBox(height: Spacing.xs),
                Timeline(
                  steps: <TimelineStep>[
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: 'Request documents',
                      detail: 'Certificates, clearances and permits',
                      tone: TimelineTone.navy,
                      onTap: onRequestDocuments,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: 'Message municipal offices',
                      detail: 'Ask questions and follow up requests',
                      tone: TimelineTone.navy,
                      onTap: onMessage,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.check,
                      title: 'Use your Taytay digital ID',
                      detail: 'Show it at the municipal hall',
                      tone: TimelineTone.navy,
                      onTap: onDigitalId,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),
          SettingsList(
            children: <Widget>[
              SettingsRow(
                icon: TaytayIcons.user,
                title: 'Complete your Resident Profile',
                detail: percent == null ? null : '$percent% complete',
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
    this.frontValue = 'Upload new photo',
    this.backValue = 'Add',
    this.selfieValue = 'Previous selfie kept',
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
  final String frontValue;
  final String backValue;
  final String selfieValue;

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
    final String shown = reason.trim().isEmpty
        ? 'Taytay LGU needs a correction before it can finish checking.'
        : reason.trim();
    final String reviewed = reviewedOn.trim();
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      footer: 'Resubmit for verification',
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
                            'Needs correction',
                            style: AppTypography.sectionTitle.copyWith(
                              color: BrandColors.ink,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          const StatusChip(
                            label: 'Needs correction',
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
                    'Your message',
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  _Body(residentMessage),
                ],
                if (submittedOn.isNotEmpty) ...<Widget>[
                  const SizedBox(height: Spacing.sm),
                  _Small('Submitted $submittedOn'),
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
                const _CardTitle('Send a new valid ID'),
                S3Field(
                  label: 'Type of ID',
                  asterisk: true,
                  value: _orDash(idType),
                  chevron: true,
                ),
                S3Field(
                  label: 'Front of ID',
                  asterisk: true,
                  value: frontValue,
                  dashed: true,
                  onTap: onFront,
                  leading: const _Plus(),
                ),
                S3Field(
                  label: 'Back of ID (optional)',
                  value: backValue,
                  dashed: true,
                  onTap: onBackPhoto,
                  leading: const _Plus(),
                ),
                if (selfieKept)
                  S3Field(
                    label: 'Selfie',
                    value: selfieValue,
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
                      'Retake',
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.blue,
                      ),
                    ),
                  )
                else
                  S3Field(
                    label: 'Selfie',
                    value: selfieValue,
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
                  'Not verified',
                  style: AppTypography.sectionTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                const _Body(
                  'Taytay LGU has not confirmed this account. You can browse '
                  'services while you complete your resident profile.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final Widget? extra = below;
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      footer: 'Start verification',
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
                      NameCheckCopy.beforeSendingTitle,
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    const _Body(NameCheckCopy.beforeSending),
                  ],
                ),
              ),
            ],
          ),
          if (open != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            SecondaryButton(
              key: const Key('verification-check-name'),
              label: NameCheckCopy.checkName,
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
            'What Taytay LGU has from you',
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
              'REASON FROM TAYTAY LGU',
              style: AppTypography.category.copyWith(color: BrandColors.redInk),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              reason,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.ink),
            ),
            if (reviewed.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.xs),
              _Small('Reviewed $reviewed'),
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
