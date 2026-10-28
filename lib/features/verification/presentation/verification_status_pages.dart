import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/field_correction_note.dart';
import 's3_chrome.dart';

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
    super.key,
  });

  final VoidCallback? onBack;
  final String accountCreated;
  final String email;
  final String idType;

  /// `submitted_at`, already formatted. Empty leaves the progress card as drawn.
  final String submittedOn;

  /// `message` the resident sent with a correction. Empty hides the line.
  final String residentMessage;

  /// Labels for `submitted_categories`. Empty hides the list.
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      child: Column(
        children: <Widget>[
          S3Card(
            child: Column(
              children: <Widget>[
                const IconTile(
                  icon: TaytayIcons.hourglass,
                  fill: BrandColors.chipAmberBg,
                  ink: BrandColors.warning,
                  size: 60,
                  iconSize: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  "We're reviewing your account",
                  textAlign: TextAlign.center,
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const StatusChip(
                  label: 'Pending review',
                  tone: StatusTone.pending,
                ),
                const SizedBox(height: 6),
                const S3Lines(
                  'Taytay LGU staff are checking your valid ID and '
                  'selfie. This usually takes 1–3 working days. No action '
                  'needed.',
                  size: 13,
                  weight: AppTypography.body,
                  color: BrandColors.textSecondary,
                  height: 1.5,
                  align: TextAlign.center,
                ),
                if (residentMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  S3Lines(
                    residentMessage,
                    size: 13,
                    weight: AppTypography.body,
                    color: BrandColors.textSecondary,
                    height: 1.5,
                    align: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          S3Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Progress',
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
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
                if (submittedOn.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Submitted $submittedOn',
                      style: s3Type(
                        12,
                        FontWeight.w400,
                        BrandColors.textSecondary,
                      ),
                    ),
                  ),
                if (categories.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'What Taytay LGU has from you',
                    style: s3Type(
                      14,
                      AppTypography.black,
                      BrandColors.textPrimary,
                    ),
                  ),
                  for (final String label in categories)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: s3Type(
                          13,
                          AppTypography.body,
                          BrandColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          const S3Card(
            child: Row(
              children: <Widget>[
                IconTile(
                  icon: TaytayIcons.info,
                  fill: BrandColors.chipBlueBg,
                  ink: BrandColors.taytayBlue,
                  size: 44,
                  iconSize: 22,
                  radius: 12,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: S3Lines(
                    'While pending you can browse services, '
                    'news and events, and use emergency hotlines.',
                    size: 13,
                    weight: AppTypography.body,
                    color: BrandColors.textSecondary,
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

/// `03-02` Verified.
class VerifiedStatusPage extends StatelessWidget {
  const VerifiedStatusPage({
    this.onBack,
    this.onHome,
    this.onProfile,
    this.onDigitalId,
    this.onMessage,
    this.verifiedOn = '',
    this.completeness,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final VoidCallback? onProfile;
  final VoidCallback? onDigitalId;
  final VoidCallback? onMessage;

  /// Date the server says the account was verified. Empty hides the date.
  final String verifiedOn;

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
        children: <Widget>[
          S3Card(
            child: Column(
              children: <Widget>[
                const IconTile(
                  icon: TaytayIcons.badgeCheck,
                  fill: BrandColors.chipGreenBg,
                  ink: BrandColors.success,
                  size: 60,
                  iconSize: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account is verified',
                  textAlign: TextAlign.center,
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const StatusChip(label: 'Verified', tone: StatusTone.verified),
                const SizedBox(height: 6),
                S3Lines(
                  body,
                  size: 13,
                  weight: AppTypography.body,
                  color: BrandColors.textSecondary,
                  height: 1.5,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          S3Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'You can now',
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
                Timeline(
                  steps: <TimelineStep>[
                    const TimelineStep(
                      icon: TaytayIcons.check,
                      title: 'Request documents',
                      detail: 'Certificates, clearances and permits',
                      tone: TimelineTone.navy,
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
          const SizedBox(height: s3CardGap),
          S3Card(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: onProfile,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    const IconTile(
                      icon: TaytayIcons.user,
                      fill: BrandColors.chipGreyBg,
                      ink: BrandColors.textSecondary,
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
                            'Complete your Resident Profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: s3Type(
                              14,
                              AppTypography.black,
                              BrandColors.textPrimary,
                            ),
                          ),
                          if (percent != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: S3Lines(
                                '$percent% complete',
                                size: 13,
                                weight: AppTypography.body,
                                color: BrandColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      TaytayIcons.chevronRight,
                      size: 18,
                      color: BrandColors.chevron,
                    ),
                  ],
                ),
              ),
            ),
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
    this.notice = '',
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onResubmit;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          S3Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    IconTile(
                      icon: TaytayIcons.triangleAlert,
                      fill: BrandColors.chipRedBg,
                      ink: BrandColors.danger,
                      size: 44,
                      iconSize: 22,
                      radius: 12,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Needs correction',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: s3Line,
                              leadingDistribution: TextLeadingDistribution.even,
                              color: BrandColors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 4),
                          StatusChip(
                            label: 'Needs correction',
                            tone: StatusTone.correction,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ReasonBox(reason: shown, reviewed: reviewed),
                for (final FieldCorrectionNote note in notes) ...<Widget>[
                  const SizedBox(height: 10),
                  _FieldNote(note: note),
                ],
                if (residentMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Your message',
                    style: s3Type(
                      14,
                      AppTypography.strong,
                      BrandColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  S3Lines(
                    residentMessage,
                    size: 13,
                    weight: AppTypography.body,
                    color: BrandColors.textSecondary,
                    height: 1.5,
                  ),
                ],
                if (submittedOn.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Submitted $submittedOn',
                    style: s3Type(
                      11,
                      FontWeight.w400,
                      BrandColors.textSecondary,
                    ),
                  ),
                ],
                if (categories.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'What Taytay LGU has from you',
                    style: s3Type(
                      14,
                      AppTypography.black,
                      BrandColors.textPrimary,
                    ),
                  ),
                  for (final String label in categories)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: s3Type(
                          13,
                          AppTypography.body,
                          BrandColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          // One logical px under the shared 12. The reason card's border
          // box is that much taller than the design's card edge.
          const SizedBox(height: 11),
          S3Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Send a new valid ID',
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
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
                  leading: const TaytayIcon(
                    icon: TaytayIcons.plus,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: 16,
                    color: BrandColors.taytayBlue,
                  ),
                ),
                S3Field(
                  label: 'Back of ID (optional)',
                  value: backValue,
                  dashed: true,
                  onTap: onBackPhoto,
                  leading: const TaytayIcon(
                    icon: TaytayIcons.plus,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: 16,
                    color: BrandColors.taytayBlue,
                  ),
                ),
                if (selfieKept)
                  S3Field(
                    label: 'Selfie',
                    value: selfieValue,
                    readOnly: true,
                    onTap: onRetake,
                    leading: const TaytayIcon(
                      icon: TaytayIcons.check,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: 16,
                      color: BrandColors.success,
                    ),
                    trailing: const Text(
                      'Retake',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: s3Line,
                        leadingDistribution: TextLeadingDistribution.even,
                        color: BrandColors.taytayBlue,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  )
                else
                  S3Field(
                    label: 'Selfie',
                    value: selfieValue,
                    dashed: true,
                    onTap: onRetake,
                    leading: const TaytayIcon(
                      icon: TaytayIcons.plus,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: 16,
                      color: BrandColors.taytayBlue,
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
    final Widget card = S3Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Not verified',
            style: s3Type(14, AppTypography.black, BrandColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const S3Lines(
            'Taytay LGU has not confirmed this account. '
            'You can browse services while you complete your resident profile.',
            size: 13,
            weight: AppTypography.body,
            color: BrandColors.textSecondary,
            height: 1.5,
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
                const SizedBox(height: s3CardGap),
                extra,
              ],
            ),
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '—' : value.trim();

/// Reason callout. The 3px danger border follows the 8px radius, so the
/// run starts at the top of the curve rather than after a clipped bar.
class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.reason, required this.reviewed});

  final String reason;
  final String reviewed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _ReasonBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'REASON FROM TAYTAY LGU',
              style: s3Type(11, AppTypography.black, BrandColors.danger),
            ),
            const SizedBox(height: 4),
            S3Lines(
              reason,
              size: 13,
              weight: AppTypography.body,
              color: const Color(0xFF3A1A1A),
              height: 1.5,
            ),
            if (reviewed.isNotEmpty) ...<Widget>[
              const SizedBox(height: 5),
              Text(
                'Reviewed $reviewed',
                style: s3Type(11, FontWeight.w400, BrandColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReasonBorder extends CustomPainter {
  const _ReasonBorder();

  static const Color _fill = Color(0xFFFDF3F3);

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = _fill);
    canvas.save();
    canvas.clipRRect(rect);
    // The left border, including the corner curve. CSS `border-left` does this.
    canvas.clipRect(Rect.fromLTWH(0, 0, 8, size.height));
    canvas.drawRRect(
      rect.deflate(1.5),
      Paint()
        ..color = BrandColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          style: s3Type(14, AppTypography.strong, BrandColors.textPrimary),
        ),
        const SizedBox(height: 4),
        S3Lines(
          note.note,
          size: 13,
          weight: AppTypography.body,
          color: BrandColors.danger,
          height: 1.5,
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
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: Column(
        children: <Widget>[
          S3Header(
            title: title,
            subtitle: 'Bayan ng Taytay · Rizal',
            onBack: onBack,
          ),
          Expanded(
            child: ListView(padding: s3PagePadding, children: <Widget>[child]),
          ),
          if (notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                notice,
                style: s3Type(13, AppTypography.body, BrandColors.danger),
              ),
            ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
              child: PrimaryButton(label: label, onPressed: onFooter),
            ),
        ],
      ),
    );
  }
}
