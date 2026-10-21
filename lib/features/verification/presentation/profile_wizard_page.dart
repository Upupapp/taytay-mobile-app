import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/resident_record.dart';
import 'manila_stamp.dart';
import 's3_chrome.dart';
import 's3_stroke.dart';

/// The five resident-profile frames, `03-05` through `03-09`.
enum ProfileWizardStep { overview, personal, household, review, submitted }

/// One frame of the profile wizard. The screen that hosts it fetches [record].
class ProfileWizardPage extends StatelessWidget {
  const ProfileWizardPage({
    required this.step,
    required this.record,
    this.onBack,
    this.onPersonal,
    this.onHousehold,
    this.onReview,
    this.onContinue,
    this.onEditPersonal,
    this.onEditHousehold,
    this.certified = true,
    this.onCertified,
    this.submittedAt,
    super.key,
  });

  final ProfileWizardStep step;
  final ResidentRecord record;
  final VoidCallback? onBack;
  final VoidCallback? onPersonal;
  final VoidCallback? onHousehold;
  final VoidCallback? onReview;
  final VoidCallback? onContinue;
  final VoidCallback? onEditPersonal;
  final VoidCallback? onEditHousehold;
  final bool certified;
  final ValueChanged<bool>? onCertified;

  /// `created_at` on the current verification request. The submitted frame
  /// formats it. A missing instant stays blank.
  final DateTime? submittedAt;

  @override
  Widget build(BuildContext context) {
    final (String title, String subtitle, String? footer) = switch (step) {
      ProfileWizardStep.overview => (
        'Resident Profile',
        'Bayan ng Taytay · Rizal',
        null,
      ),
      ProfileWizardStep.personal => (
        'Personal information',
        'Step 1 of 2',
        'Save & continue',
      ),
      ProfileWizardStep.household => (
        'Household & address',
        'Step 2 of 2',
        'Save & continue',
      ),
      ProfileWizardStep.review => (
        'Review & submit',
        'Bayan ng Taytay · Rizal',
        'Submit to Taytay LGU',
      ),
      ProfileWizardStep.submitted => (
        'Resident Profile',
        'Bayan ng Taytay · Rizal',
        'Back to profile',
      ),
    };
    final DateTime? sent = submittedAt;
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: Column(
        children: <Widget>[
          S3Header(title: title, subtitle: subtitle, onBack: onBack),
          Expanded(
            child: ListView(
              padding: s3PagePadding,
              children: <Widget>[
                switch (step) {
                  ProfileWizardStep.overview => _Overview(
                    record: record,
                    onPersonal: onPersonal,
                    onHousehold: onHousehold,
                    onReview: onReview,
                  ),
                  ProfileWizardStep.personal => _Personal(record: record),
                  ProfileWizardStep.household => _Household(record: record),
                  ProfileWizardStep.review => _Review(
                    record: record,
                    certified: certified,
                    onCertified: onCertified,
                    onEditPersonal: onEditPersonal,
                    onEditHousehold: onEditHousehold,
                  ),
                  ProfileWizardStep.submitted => _Submitted(
                    submittedAt: sent == null ? '' : formatManilaStamp(sent),
                  ),
                },
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
              child: PrimaryButton(
                label: footer,
                onPressed: certified || step != ProfileWizardStep.review
                    ? onContinue
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.record,
    this.onPersonal,
    this.onHousehold,
    this.onReview,
  });

  final ResidentRecord record;
  final VoidCallback? onPersonal;
  final VoidCallback? onHousehold;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final String name = record.displayName;
    final (String chip, StatusTone tone) = switch (record.verificationTier) {
      'verified' => ('Verified', StatusTone.verified),
      'rejected' => ('Needs correction', StatusTone.correction),
      _ => ('Pending review', StatusTone.pending),
    };
    final String place = <String>[
      if (record.barangayName.isNotEmpty) 'Brgy. ${record.barangayName}',
      record.municipality,
      record.province,
    ].where((String part) => part.isNotEmpty).join(', ');
    return Column(
      children: <Widget>[
        S3Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _Avatar(initials: _initials(record)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name.isEmpty ? 'Your name' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: s3Type(
                            14,
                            AppTypography.black,
                            BrandColors.textPrimary,
                          ),
                        ),
                        S3Lines(
                          place,
                          size: 13,
                          weight: AppTypography.body,
                          color: BrandColors.textSecondary,
                          height: 1.5,
                        ),
                      ],
                    ),
                  ),
                  StatusChip(label: chip, tone: tone),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Profile completeness',
                        style: s3Type(
                          12,
                          AppTypography.black,
                          BrandColors.fieldInk,
                        ),
                      ),
                    ),
                    Text(
                      '${record.completeness}%',
                      style: s3Type(
                        12,
                        AppTypography.black,
                        BrandColors.taytayBlue,
                      ),
                    ),
                  ],
                ),
              ),
              _Bar(value: record.completeness / 100),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  'Complete all sections to submit your profile to Taytay LGU.',
                  style: s3Type(11, FontWeight.w400, BrandColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: s3CardGap),
        S3Card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: <Widget>[
              _SectionRow(
                icon: S3StrokeIcon.user,
                title: 'Personal information',
                chip: record.personalComplete ? 'Complete' : 'Not started',
                tone: record.personalComplete
                    ? StatusTone.verified
                    : StatusTone.neutral,
                onTap: onPersonal,
              ),
              _SectionRow(
                icon: S3StrokeIcon.house,
                title: 'Household & address',
                chip: record.householdStarted ? 'In progress' : 'Not started',
                tone: record.householdStarted
                    ? StatusTone.pending
                    : StatusTone.neutral,
                onTap: onHousehold,
              ),
              const _SectionRow(
                icon: S3StrokeIcon.paperclip,
                title: 'Supporting documents',
                chip: 'Optional',
                tone: StatusTone.neutral,
              ),
              _SectionRow(
                icon: S3StrokeIcon.listChecks,
                title: 'Review & submit',
                chip: 'Not started',
                tone: StatusTone.neutral,
                onTap: onReview,
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: BrandColors.chipBlueBg,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: s3Type(16, AppTypography.black, BrandColors.taytayBlue),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final double fraction = value.clamp(0, 1);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: Color(0xFFE6EAF2)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      BrandColors.taytayBlue,
                      BrandColors.taytayBlueLight,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.title,
    required this.chip,
    required this.tone,
    this.onTap,
    this.last = false,
  });

  final S3StrokeIcon icon;
  final String title;
  final String chip;
  final StatusTone tone;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final Widget row = DecoratedBox(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEEF1F6))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 12, 0, last ? 12 : 12 + 5 / 3),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandColors.chipBlueBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: identical(icon, S3StrokeIcon.listChecks)
                  ? const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: S3StrokeIcon.listChecks,
                    )
                  : icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // The user glyph has a gap under the title. Height 1 keeps the
                  // descender of "Personal" above that gap. Other rows keep the
                  // 1.26 line so their icons stay joined to the title.
                  identical(icon, S3StrokeIcon.user)
                      ? SizedBox(
                          height: 18,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2 / 3),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  leadingDistribution:
                                      TextLeadingDistribution.even,
                                  color: BrandColors.fieldInk,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: s3Type(
                            14,
                            AppTypography.black,
                            BrandColors.fieldInk,
                          ),
                        ),
                  const SizedBox(height: 3),
                  identical(icon, S3StrokeIcon.listChecks)
                      ? Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            ExcludeSemantics(
                              child: Visibility(
                                visible: false,
                                maintainSize: true,
                                maintainState: true,
                                maintainAnimation: true,
                                child: StatusChip(
                                  label: chip,
                                  tone: tone,
                                  icon: false,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              left: 0,
                              child: StatusChip(
                                label: chip,
                                tone: tone,
                                icon: false,
                              ),
                            ),
                          ],
                        )
                      : StatusChip(label: chip, tone: tone, icon: false),
                ],
              ),
            ),
            const TaytayIcon(
              icon: TaytayIcons.chevronRight,
              semanticLabel: '',
              excludeSemantics: true,
              size: 18,
              color: BrandColors.chevron,
            ),
          ],
        ),
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap == null) return row;
    return InkWell(onTap: tap, child: row);
  }
}

class _Personal extends StatelessWidget {
  const _Personal({required this.record});

  final ResidentRecord record;

  @override
  Widget build(BuildContext context) {
    final String suffix = record.suffix.trim();
    return Column(
      children: <Widget>[
        S3Card(
          child: Column(
            children: <Widget>[
              _Pair(
                left: S3Field(
                  label: 'First name',
                  asterisk: true,
                  value: _shown(record.givenName),
                  top: 0,
                ),
                right: S3Field(
                  label: 'Middle name',
                  value: _shown(record.middleName),
                  top: 0,
                ),
              ),
              _Pair(
                left: S3Field(
                  label: 'Last name',
                  asterisk: true,
                  value: _shown(record.familyName),
                ),
                right: S3Field(
                  label: 'Suffix',
                  value: suffix.isEmpty ? 'e.g. Jr.' : suffix,
                  readOnly: suffix.isEmpty,
                ),
                narrowRight: true,
              ),
              _Pair(
                left: S3Field(
                  label: 'Sex',
                  asterisk: true,
                  value: _shown(record.sex),
                  chevron: true,
                ),
                right: S3Field(
                  label: 'Birthdate',
                  asterisk: true,
                  value: _birth(record.birthdate),
                  trailing: S3StrokeIcon.calendar,
                ),
              ),
              _Pair(
                left: S3Field(
                  label: 'Civil status',
                  asterisk: true,
                  value: _shown(record.civilStatus),
                  chevron: true,
                ),
                right: S3Field(
                  label: 'Age',
                  value: _age(record.birthdate),
                  readOnly: true,
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
              Text(
                'Contact',
                style: s3Type(14, AppTypography.black, BrandColors.textPrimary),
              ),
              S3Field(
                label: 'Mobile number',
                asterisk: true,
                value: _shown(record.mobile),
                trailing: record.mobileVerified
                    ? const StatusChip(
                        label: 'Verified',
                        tone: StatusTone.verified,
                      )
                    : null,
              ),
              S3Field(
                label: 'Email',
                value: _shown(record.email),
                readOnly: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Household extends StatelessWidget {
  const _Household({required this.record});

  final ResidentRecord record;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        S3Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Address',
                style: s3Type(14, AppTypography.black, BrandColors.textPrimary),
              ),
              S3Field(
                label: 'Barangay',
                asterisk: true,
                value: _shown(record.barangayName),
                chevron: true,
                below: const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    'Dolores · Muzon · San Isidro · San Juan · Santa Ana',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: s3Line,
                      leadingDistribution: TextLeadingDistribution.even,
                      color: BrandColors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              _Pair(
                left: S3Field(
                  label: 'House no. / Street',
                  asterisk: true,
                  value: _shown(record.street),
                ),
                right: S3Field(
                  label: 'Purok / Sitio',
                  value: _purok(record.purok),
                ),
                narrowRight: true,
              ),
              S3Field(
                label: 'Municipality / Province',
                value: '${record.municipality}, ${record.province}',
                readOnly: true,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.chipBlueBg,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10 - 2 / 3),
                    child: Text(
                      record.addressLine,
                      style: s3Type(
                        12,
                        AppTypography.strong,
                        BrandColors.taytayBlue,
                      ),
                    ),
                  ),
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
              Text(
                'Household',
                style: s3Type(14, AppTypography.black, BrandColors.textPrimary),
              ),
              _Pair(
                left: S3Field(
                  label: 'Years at this address',
                  asterisk: true,
                  value: _shown(record.yearsAtAddress),
                ),
                right: S3Field(
                  label: 'Household members',
                  value: _shown(record.memberCount),
                ),
              ),
              S3Field(
                label: 'Residence type',
                value: _shown(record.residenceType),
                chevron: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({
    required this.record,
    required this.certified,
    this.onCertified,
    this.onEditPersonal,
    this.onEditHousehold,
  });

  final ResidentRecord record;
  final bool certified;
  final ValueChanged<bool>? onCertified;
  final VoidCallback? onEditPersonal;
  final VoidCallback? onEditHousehold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        S3Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _EditHeader(
                title: 'Personal information',
                onEdit: onEditPersonal,
              ),
              _Line(label: 'Name', value: record.displayName),
              _Line(
                label: 'Sex · Birthdate',
                value: '${record.sex} · ${_birth(record.birthdate)}',
              ),
              _Line(label: 'Civil status', value: record.civilStatus),
              _Line(label: 'Mobile', value: record.mobile, last: true),
            ],
          ),
        ),
        const SizedBox(height: s3CardGap),
        S3Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _EditHeader(
                title: 'Household & address',
                onEdit: onEditHousehold,
              ),
              _Line(label: 'Address', value: _shortAddress(record)),
              _Line(
                label: 'Barangay',
                value:
                    '${record.barangayName}, ${record.municipality}, ${record.province}',
              ),
              _Line(label: 'Years at address', value: record.yearsAtAddress),
              _Line(
                label: 'Household members',
                value: record.memberCount,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: s3CardGap),
        S3Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ConsentBox(checked: certified, onChanged: onCertified),
              const SizedBox(width: 10),
              const Expanded(
                child: S3Lines(
                  'I certify that the information is true and correct, '
                  'and I consent to its processing under the Data '
                  "Privacy Act of 2012 per Taytay LGU's Privacy Notice.",
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
    );
  }
}

class _ConsentBox extends StatelessWidget {
  const _ConsentBox({required this.checked, this.onChanged});

  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final Widget box = SizedBox(
      width: 20,
      height: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: checked ? BrandColors.taytayBlue : BrandColors.surfaceCard,
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          border: checked
              ? null
              : Border.all(color: BrandColors.taytayBlue, width: 1.5),
        ),
        child: checked
            ? const Icon(TaytayIcons.check, size: 14, color: Colors.white)
            : null,
      ),
    );
    final ValueChanged<bool>? change = onChanged;
    if (change == null) return box;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        box,
        Positioned(
          left: -14,
          top: -14,
          width: A11y.minTapTarget,
          height: A11y.minTapTarget,
          child: InkWell(onTap: () => change(!checked)),
        ),
      ],
    );
  }
}

class _Submitted extends StatelessWidget {
  const _Submitted({required this.submittedAt});

  final String submittedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 60),
          child: Column(
            children: <Widget>[
              IconTile(
                icon: TaytayIcons.circleCheck,
                fill: BrandColors.chipGreenBg,
                ink: BrandColors.success,
                size: 88,
                iconSize: 44,
              ),
              SizedBox(height: 16),
              Text(
                'Profile submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: s3Line,
                  leadingDistribution: TextLeadingDistribution.even,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: S3Lines(
                  "Your resident profile was sent to Taytay LGU. We'll "
                  'notify you when it has been reviewed.',
                  size: 13,
                  weight: AppTypography.body,
                  color: BrandColors.textSecondary,
                  height: 1.5,
                  align: TextAlign.center,
                ),
              ),
              SizedBox(height: 10),
              StatusChip(label: 'Pending review', tone: StatusTone.pending),
            ],
          ),
        ),
        const SizedBox(height: 26 + 2 / 3),
        S3Card(
          child: Timeline(
            steps: <TimelineStep>[
              TimelineStep(
                icon: TaytayIcons.check,
                title: 'Submitted',
                detail: submittedAt.isEmpty ? '—' : submittedAt,
                tone: TimelineTone.done,
              ),
              const TimelineStep(
                icon: TaytayIcons.clock,
                title: 'LGU review',
                detail: 'Usually 1–3 working days',
                tone: TimelineTone.current,
              ),
              const TimelineStep(
                icon: TaytayIcons.badgeCheck,
                title: 'Profile verified',
                tone: TimelineTone.upcoming,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({required this.title, this.onEdit});

  final String title;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: s3Type(14, AppTypography.black, BrandColors.textPrimary),
          ),
        ),
        _EditLink(onEdit: onEdit),
      ],
    );
  }
}

class _EditLink extends StatelessWidget {
  const _EditLink({this.onEdit});

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      'Edit',
      style: s3Type(12, AppTypography.black, BrandColors.taytayBlue),
    );
    final VoidCallback? tap = onEdit;
    if (tap == null) return label;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        label,
        Positioned(
          right: -12,
          top: -16,
          width: A11y.minTapTarget,
          height: A11y.minTapTarget,
          child: InkWell(onTap: tap),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    // 13×1.26 rounds to 16. The extra keeps the CSS pitch of 8 + 16.38.
    // The last line has no trailing gap; that gap belongs to the next card.
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: last ? 0 : 13 * s3Line - 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: s3Type(13, FontWeight.w400, BrandColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: s3Type(13, AppTypography.strong, BrandColors.fieldInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({
    required this.left,
    required this.right,
    this.narrowRight = false,
  });

  final Widget left;
  final Widget right;
  final bool narrowRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(flex: 5, child: left),
        const SizedBox(width: 10),
        Expanded(flex: narrowRight ? 3 : 5, child: right),
      ],
    );
  }
}

String _shown(String value) => value.trim().isEmpty ? '—' : value.trim();

String _purok(String value) {
  final String purok = value.trim();
  if (purok.isEmpty) return '—';
  if (purok.toLowerCase().startsWith('purok')) return purok;
  return 'Purok $purok';
}

String _initials(ResidentRecord record) {
  final String given = record.givenName.trim();
  final String family = record.familyName.trim();
  final String mark =
      '${given.isEmpty ? '' : given[0]}${family.isEmpty ? '' : family[0]}';
  return mark.isEmpty ? '?' : mark.toUpperCase();
}

String _shortAddress(ResidentRecord record) {
  final Iterable<String> parts = <String>[
    record.street,
    if (record.purok.isNotEmpty) 'Purok ${record.purok}',
  ].where((String part) => part.isNotEmpty);
  return parts.join(', ');
}

String _birth(String iso) {
  final List<String> parts = iso.split('-');
  if (parts.length != 3) return iso.isEmpty ? '—' : iso;
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final int? month = int.tryParse(parts[1]);
  final int? day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return iso;
  return '${months[month - 1]} $day, ${parts[0]}';
}

String _age(String iso) {
  final DateTime? parsed = DateTime.tryParse(iso);
  if (parsed == null) return '—';
  final DateTime today = DateTime(2026, 10, 21);
  var age = today.year - parsed.year;
  if (today.month < parsed.month ||
      (today.month == parsed.month && today.day < parsed.day)) {
    age -= 1;
  }
  return '$age';
}
