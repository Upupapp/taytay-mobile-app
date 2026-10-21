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
    super.key,
  });

  final VoidCallback? onBack;
  final String accountCreated;
  final String email;
  final String idType;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      child: Column(
        children: <Widget>[
          const S3Card(
            child: Column(
              children: <Widget>[
                IconTile(
                  icon: TaytayIcons.clock,
                  fill: BrandColors.chipAmberBg,
                  ink: BrandColors.warning,
                  size: 60,
                  iconSize: 28,
                ),
                SizedBox(height: 10),
                Text(
                  "We're reviewing your account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: BrandColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 6),
                StatusChip(label: 'Pending review', tone: StatusTone.pending),
                SizedBox(height: 6),
                Text(
                  'Taytay LGU staff are checking your valid ID and '
                  'selfie. This usually takes 1–3 working days. No action '
                  'needed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: BrandColors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          S3Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: BrandColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 14),
                Timeline(
                  steps: <TimelineStep>[
                    TimelineStep(
                      icon: TaytayIcons.user,
                      title: 'Account created',
                      detail: _orDash(accountCreated),
                      tone: TimelineTone.done,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.mail,
                      title: 'Email confirmed',
                      detail: _orDash(email),
                      tone: TimelineTone.done,
                    ),
                    TimelineStep(
                      icon: TaytayIcons.idCard,
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
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          const S3Card(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconTile(
                  icon: TaytayIcons.newspaper,
                  fill: BrandColors.chipBlueBg,
                  ink: BrandColors.taytayBlue,
                  size: 36,
                  iconSize: 18,
                  radius: 10,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'While pending you can browse services, '
                    'news and events, and use emergency hotlines.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: BrandColors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
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
                  icon: TaytayIcons.check,
                  fill: BrandColors.chipGreenBg,
                  ink: BrandColors.success,
                  size: 56,
                  iconSize: 26,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your account is verified',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: BrandColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                const StatusChip(label: 'Verified', tone: StatusTone.verified),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: BrandColors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          S3Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'You can now',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: BrandColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                const CheckLine(
                  title: 'Request documents',
                  detail: 'Certificates, clearances and permits',
                ),
                CheckLine(
                  title: 'Message municipal offices',
                  detail: 'Ask questions and follow up requests',
                  onTap: onMessage,
                ),
                CheckLine(
                  title: 'Use your Taytay digital ID',
                  detail: 'Show it at the municipal hall',
                  onTap: onDigitalId,
                ),
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          S3Card(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: InkWell(
              onTap: onProfile,
              borderRadius: BorderRadius.circular(Radii.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 8),
                    const IconTile(
                      icon: TaytayIcons.user,
                      fill: BrandColors.chipBlueBg,
                      ink: BrandColors.taytayBlue,
                      size: 40,
                      iconSize: 20,
                      radius: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Complete your Resident Profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: BrandColors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          if (completeness != null)
                            Text(
                              '$completeness% complete',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: BrandColors.inkGold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const TaytayIcon(
                      icon: TaytayIcons.chevronRight,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: 18,
                      color: BrandColors.taytayBlue,
                    ),
                    const SizedBox(width: 8),
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
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onResubmit;
  final String reason;
  final List<FieldCorrectionNote> notes;
  final String idType;
  final String reviewedOn;

  @override
  Widget build(BuildContext context) {
    final String shown = reason.trim().isEmpty
        ? 'Taytay LGU needs a correction before it can finish checking.'
        : reason.trim();
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      footer: 'Resubmit for verification',
      onFooter: onResubmit,
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
                      size: 40,
                      iconSize: 20,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: BrandColors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 6),
                          StatusChip(
                            label: 'Needs correction',
                            tone: StatusTone.correction,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF3F3),
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(
                      color: BrandColors.danger.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'REASON FROM TAYTAY LGU',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            height: 1.2,
                            color: BrandColors.textSecondary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shown,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                            color: BrandColors.textPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (reviewedOn.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            'Reviewed $reviewedOn',
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              color: BrandColors.textMuted,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                for (final FieldCorrectionNote note in notes) ...<Widget>[
                  const SizedBox(height: 10),
                  _FieldNote(note: note),
                ],
              ],
            ),
          ),
          const SizedBox(height: s3CardGap),
          S3Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Send a new valid ID',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: BrandColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Type of ID', requiredMark: true),
                const SizedBox(height: 6),
                _ValueBox(value: _orDash(idType), chevron: true),
                const SizedBox(height: 14),
                const _FieldLabel('Front of ID', requiredMark: true),
                const SizedBox(height: 6),
                const _DashedUpload(label: 'Upload new photo'),
                const SizedBox(height: 14),
                const _FieldLabel('Back of ID (optional)'),
                const SizedBox(height: 6),
                const _DashedUpload(label: 'Add'),
                const SizedBox(height: 14),
                const _FieldLabel('Selfie'),
                const SizedBox(height: 6),
                const _KeptSelfie(),
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
  const UnverifiedStatusPage({this.onBack, this.onStart, super.key});

  final VoidCallback? onBack;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      footer: 'Start verification',
      onFooter: onStart,
      child: const S3Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Not verified',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Taytay LGU has not confirmed this account. '
              'You can browse services while you complete your resident profile.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: BrandColors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '—' : value.trim();

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.requiredMark = false});

  final String label;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: BrandColors.textSecondary,
          decoration: TextDecoration.none,
        ),
        children: <InlineSpan>[
          if (requiredMark)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: BrandColors.danger),
            ),
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.value, this.chevron = false});

  final String value;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: const Color(0xFFD5DCEC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            if (chevron)
              const TaytayIcon(
                icon: TaytayIcons.chevronDown,
                semanticLabel: '',
                excludeSemantics: true,
                size: 16,
                color: BrandColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedUpload extends StatelessWidget {
  const _DashedUpload({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashBoxPainter(),
      child: SizedBox(
        height: 72,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.plus,
                semanticLabel: '',
                excludeSemantics: true,
                size: 16,
                color: BrandColors.taytayBlue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: BrandColors.taytayBlue,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashBoxPainter extends CustomPainter {
  const _DashBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFD5DCEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final double next = distance + 5;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KeptSelfie extends StatelessWidget {
  const _KeptSelfie();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
      child: const Row(
        children: <Widget>[
          IconTile(
            icon: TaytayIcons.check,
            fill: BrandColors.success,
            ink: Colors.white,
            size: 28,
            iconSize: 16,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Previous selfie kept',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Text(
            'Retake',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: BrandColors.taytayBlue,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldNote extends StatelessWidget {
  const _FieldNote({required this.note});

  final FieldCorrectionNote note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: BrandColors.danger.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              note.label,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note.note,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: BrandColors.danger,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
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
  });

  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final String? footer;
  final VoidCallback? onFooter;

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
