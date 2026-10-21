import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/field_correction_note.dart';
import 's3_chrome.dart';

/// `03-01` Pending review.
class PendingStatusPage extends StatelessWidget {
  const PendingStatusPage({this.onBack, super.key});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 30),
          const _StatusMark(
            icon: TaytayIcons.clock,
            fill: Color(0xFFFFF4D6),
            ink: BrandColors.warning,
            diameter: 60,
          ),
          const SizedBox(height: 11),
          const _Headline("We're reviewing your account"),
          const SizedBox(height: 4),
          const StatusChip(label: 'Pending review', tone: StatusTone.pending),
          const SizedBox(height: 5),
          Transform.translate(
            offset: const Offset(0, 1),
            child: const _CenteredCopy(
              'Taytay LGU staff are checking your valid ID and\n'
              'selfie. This usually takes 1–3 working days. No action\n'
              'needed.',
            ),
          ),
          const SizedBox(height: 46),
          Transform.translate(
            offset: const Offset(0, 2.33),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Progress',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: BrandColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const ProgressRow(
            icon: TaytayIcons.user,
            title: 'Account created',
            detail: 'Oct 20, 2026 · 8:12 PM',
            rowShift: 1,
          ),
          const ProgressRow(
            icon: TaytayIcons.mail,
            title: 'Email confirmed',
            detail: 'juana.delacruz@example.com',
          ),
          const ProgressRow(
            icon: TaytayIcons.idCard,
            title: 'Valid ID and selfie received',
            detail: 'PhilSys National ID',
          ),
          const ProgressRow(
            icon: TaytayIcons.clock,
            title: 'LGU review',
            detail: 'In queue',
            iconDark: false,
            titleShift: 3.33,
            detailShift: 1,
          ),
          const ProgressRow(
            icon: TaytayIcons.badgeCheck,
            title: 'Verified',
            detail: 'Unlocks document requests and messaging offices',
            iconDark: false,
            bottom: 16,
            titleShift: 3.67,
            detailShift: 1,
          ),
          const SizedBox(height: 28),
          Transform.translate(
            offset: const Offset(0, 3),
            child: const _CenteredCopy(
              'While pending you can browse services,',
            ),
          ),
          const SizedBox(height: 2),
          const _IconLine(
            icon: TaytayIcons.newspaper,
            text: 'news and events, and use emergency',
            shift: 0.67,
          ),
          const SizedBox(height: 2),
          const _CenteredCopy('hotlines.'),
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
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final VoidCallback? onProfile;
  final VoidCallback? onDigitalId;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      footer: 'Go to Home',
      onFooter: onHome,
      child: Column(
        children: <Widget>[
          const SizedBox(height: 26),
          const _StatusMark(
            icon: TaytayIcons.check,
            fill: Color(0xFFE5F6EE),
            ink: BrandColors.success,
            diameter: 58,
          ),
          const SizedBox(height: 16),
          Transform.translate(
            offset: const Offset(0, 1),
            child: const _Headline('Your account is verified'),
          ),
          const SizedBox(height: 4),
          Transform.translate(
            offset: const Offset(0, 1.33),
            child: const StatusChip(label: 'Verified', tone: StatusTone.verified),
          ),
          const SizedBox(height: 5),
          Transform.translate(
            offset: const Offset(0, 1.33),
            child: const _CenteredCopy(
              'Verified by Taytay LGU on Oct 22, 2026. You now\n'
              'have full access to resident services.',
            ),
          ),
          const SizedBox(height: 49),
          Transform.translate(
            offset: const Offset(0, -2),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'You can now',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: BrandColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _ActionRow(
            icon: TaytayIcons.fileText,
            title: 'Request documents',
            detail: 'Certificates, clearances and permits',
          ),
          _ActionRow(
            icon: TaytayIcons.messageCircle,
            title: 'Message municipal offices',
            detail: 'Ask questions and follow up requests',
            onTap: onMessage,
          ),
          _ActionRow(
            icon: TaytayIcons.idCard,
            title: 'Use your Taytay digital ID',
            detail: 'Show it at the municipal hall',
            onTap: onDigitalId,
            shift: -2.33,
          ),
          const SizedBox(height: 34),
          _ProfilePrompt(onTap: onProfile),
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
    this.reason =
        'The ID photo is blurred and the name can\'t be read. '
        'Please upload a clearer photo of the front of your ID.',
    this.notes = const <FieldCorrectionNote>[],
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onResubmit;
  final String reason;
  final List<FieldCorrectionNote> notes;

  @override
  Widget build(BuildContext context) {
    return _StatusScaffold(
      title: 'Verification status',
      onBack: onBack,
      footer: 'Resubmit for verification',
      onFooter: onResubmit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 34),
          Transform.translate(
            offset: const Offset(0, 1.33),
            child: const _CorrectionBanner(),
          ),
          const SizedBox(height: 8),
          Transform.translate(
            offset: const Offset(0, -1.67),
            child: _ReasonCard(reason: reason),
          ),
          if (notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            for (final FieldCorrectionNote note in notes) _FieldNote(note: note),
          ],
          const SizedBox(height: 22),
          Transform.translate(
            offset: const Offset(0, -1),
            child: const Text(
              'Send a new valid ID',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: BrandColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _ReadonlyField(
            label: 'Type of ID',
            value: 'PhilSys National ID',
            labelShift: -1,
            valueShift: -1.33,
          ),
          const _LinkField(
            label: 'Front of ID',
            value: 'Upload new photo',
            labelShift: -3,
            valueShift: 4.67,
          ),
          const _LinkField(
            label: 'Back of ID (optional)',
            value: 'Add',
            labelShift: 9,
            valueShift: 16.67,
          ),
          const _LinkField(
            label: 'Selfie',
            value: 'Previous selfie kept',
            trailing: 'Retake',
            labelShift: 21,
            valueShift: 27,
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 28),
          Text(
            'Not verified',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: BrandColors.textPrimary,
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
              height: 1.35,
              color: BrandColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({
    required this.icon,
    required this.fill,
    required this.ink,
    required this.diameter,
  });

  final IconData icon;
  final Color fill;
  final Color ink;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: TaytayIcon(
        icon: icon,
        semanticLabel: '',
        excludeSemantics: true,
        size: diameter * 0.42,
        color: ink,
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: BrandColors.textPrimary,
      ),
    );
  }
}

class _CenteredCopy extends StatelessWidget {
  const _CenteredCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: BrandColors.textSecondary,
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text, this.shift = 0});

  final IconData icon;
  final String text;
  final double shift;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, shift),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(0, -1),
          child: TaytayIcon(
            icon: icon,
            semanticLabel: '',
            excludeSemantics: true,
            size: 18,
            color: BrandColors.taytayBlue,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.1,
            color: BrandColors.textSecondary,
          ),
        ),
      ],
      ),
    );
  }
}

/// Headline and chip share one dark run. A danger bar bridges the gap
/// between them, which is the line the design draws as one block.
class _CorrectionBanner extends StatelessWidget {
  const _CorrectionBanner();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFFDECEC),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ColoredBox(
              color: BrandColors.danger,
              child: SizedBox(width: 4),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 2, 12, 2),
                child: Column(
                  children: <Widget>[
                    Text(
                      'Needs correction',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: BrandColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    StatusChip(
                      label: 'Needs correction',
                      tone: StatusTone.correction,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFFDF3F3),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const ColoredBox(
              color: BrandColors.danger,
              child: SizedBox(width: 4),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
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
                        height: 1.1,
                        color: BrandColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: BrandColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reviewed Oct 21, 2026 (sample)',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        color: BrandColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Complete your Resident Profile',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: BrandColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '60% complete',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: BrandColors.inkGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.onTap,
    this.shift = 0,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final double shift;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Transform.translate(
              offset: Offset(0, shift),
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TaytayIcon(
                  icon: icon,
                  semanticLabel: '',
                  excludeSemantics: true,
                  color: BrandColors.taytayBlue,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: BrandColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    this.labelShift = 0,
    this.valueShift = 0,
  });

  final String label;
  final String value;
  final double labelShift;
  final double valueShift;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Transform.translate(
            offset: Offset(0, labelShift),
            child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: BrandColors.textSecondary,
            ),
            ),
          ),
          const SizedBox(height: 10),
          Transform.translate(
            offset: Offset(0, valueShift),
            child: DecoratedBox(
            decoration: BoxDecoration(
              color: BrandColors.surfaceCard,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: const Color(0xFFD5DCEC)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: BrandColors.textPrimary,
                      ),
                    ),
                  ),
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
          ),
          ),
        ],
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.label,
    required this.value,
    this.trailing,
    this.labelShift = 0,
    this.valueShift = 0,
  });

  final String label;
  final String value;
  final String? trailing;
  final double labelShift;
  final double valueShift;

  @override
  Widget build(BuildContext context) {
    final String? extra = trailing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Transform.translate(
            offset: Offset(0, labelShift),
            child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: BrandColors.textSecondary,
            ),
            ),
          ),
          const SizedBox(height: 12),
          Transform.translate(
            offset: Offset(0, valueShift),
            child: Row(
            children: <Widget>[
              if (extra == null)
                const TaytayIcon(
                  icon: TaytayIcons.plus,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 16,
                  color: BrandColors.taytayBlue,
                ),
              if (extra == null) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: extra == null
                        ? BrandColors.taytayBlue
                        : BrandColors.textPrimary,
                  ),
                ),
              ),
              if (extra != null)
                Text(
                  extra,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: <Widget>[child],
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
