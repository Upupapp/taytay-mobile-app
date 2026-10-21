import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/resident_record.dart';
import 'manila_stamp.dart';
import 's3_chrome.dart';

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
    final String name = record.displayName.isEmpty
        ? 'Your name'
        : record.displayName;
    final String barangay = record.barangayName.isEmpty
        ? 'Taytay'
        : record.barangayName;
    final (String chip, StatusTone tone) = switch (record.verificationTier) {
      'verified' => ('Verified', StatusTone.verified),
      'rejected' => ('Needs correction', StatusTone.correction),
      _ => ('Pending review', StatusTone.pending),
    };
    return Column(
      children: <Widget>[
        S3Card(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 26,
                backgroundColor: BrandColors.chipBlueBg,
                child: Text(
                  _initials(record),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: BrandColors.taytayBlue,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: BrandColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        Text(
                          'Brgy. $barangay, Taytay',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            color: BrandColors.textSecondary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        StatusChip(label: chip, tone: tone),
                      ],
                    ),
                    const Text(
                      'Rizal',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        color: BrandColors.textSecondary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        S3Card(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Profile completeness',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: BrandColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  Text(
                    '${record.completeness}%',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: BrandColors.taytayBlue,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: record.completeness / 100,
                    backgroundColor: BrandColors.surfaceMuted,
                    color: BrandColors.taytayBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete all sections to submit your profile to Taytay LGU.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: BrandColors.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _SectionCard(
          icon: TaytayIcons.user,
          title: 'Personal information',
          chip: record.personalComplete ? 'Complete' : 'Not started',
          tone: record.personalComplete
              ? StatusTone.verified
              : StatusTone.neutral,
          onTap: onPersonal,
        ),
        const SizedBox(height: 10),
        _SectionCard(
          icon: TaytayIcons.house,
          title: 'Household & address',
          chip: record.householdStarted ? 'In progress' : 'Not started',
          tone: record.householdStarted
              ? StatusTone.pending
              : StatusTone.neutral,
          onTap: onHousehold,
        ),
        const SizedBox(height: 10),
        const _SectionCard(
          icon: TaytayIcons.fileText,
          title: 'Supporting documents',
          chip: 'Optional',
          tone: StatusTone.neutral,
        ),
        const SizedBox(height: 10),
        _SectionCard(
          icon: TaytayIcons.badgeCheck,
          title: 'Review & submit',
          chip: 'Not started',
          tone: StatusTone.neutral,
          onTap: onReview,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.chip,
    required this.tone,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String chip;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return S3Card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Row(
            children: <Widget>[
              IconTile(
                icon: icon,
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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: BrandColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StatusChip(label: chip, tone: tone),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const TaytayIcon(
                icon: TaytayIcons.chevronRight,
                semanticLabel: '',
                excludeSemantics: true,
                size: 18,
                color: BrandColors.taytayBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Personal extends StatelessWidget {
  const _Personal({required this.record});

  final ResidentRecord record;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        S3Card(
          child: Column(
            children: <Widget>[
              _Pair(
                left: _Field(label: 'First name', value: record.givenName),
                right: _Field(label: 'Middle name', value: record.middleName),
              ),
              _Pair(
                left: _Field(label: 'Last name', value: record.familyName),
                right: _Field(label: 'Suffix', value: record.suffix),
              ),
              _Pair(
                left: _Field(label: 'Sex', value: record.sex),
                right: _Field(
                  label: 'Birthdate',
                  value: _birth(record.birthdate),
                ),
              ),
              _Pair(
                left: _Field(label: 'Civil status', value: record.civilStatus),
                right: _Field(label: 'Age', value: _age(record.birthdate)),
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
                'Contact',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Mobile number',
                value: record.mobile,
                verified: record.mobileVerified,
              ),
              _Field(label: 'Email', value: record.email),
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
              const Text(
                'Address',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              _Field(label: 'Barangay', value: record.barangayName),
              const _BarangayChips(),
              const SizedBox(height: 8),
              _Pair(
                left: _Field(label: 'House no. / Street', value: record.street),
                right: _Field(label: 'Purok / Sitio', value: record.purok),
              ),
              _Field(
                label: 'Municipality / Province',
                value: '${record.municipality}, ${record.province}',
              ),
              const SizedBox(height: 4),
              Text(
                _streetLine(record),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: BrandColors.taytayBlue,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                record.province,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: BrandColors.taytayBlue,
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
                'Household',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              _Pair(
                left: _Field(
                  label: 'Years at this address',
                  value: record.yearsAtAddress,
                ),
                right: _Field(
                  label: 'Household members',
                  value: record.memberCount,
                ),
              ),
              _Field(label: 'Residence type', value: record.residenceType),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarangayChips extends StatelessWidget {
  const _BarangayChips();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _BarangayChip('Dolores'),
        _BarangayChip('Muzon'),
        _BarangayChip('San Juan'),
        _BarangayChip('Santa Ana'),
      ],
    );
  }
}

class _BarangayChip extends StatelessWidget {
  const _BarangayChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool selected = label == 'San Juan';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? BrandColors.chipBlueBg : BrandColors.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(
          color: selected ? BrandColors.taytayBlue : const Color(0xFFD5DCEC),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: selected
                ? BrandColors.taytayBlue
                : BrandColors.textSecondary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
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
              _Line(label: 'Mobile', value: record.mobile),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
              _Line(label: 'Household members', value: record.memberCount),
            ],
          ),
        ),
        const SizedBox(height: 8),
        S3Card(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: certified,
                onChanged: onCertified == null
                    ? null
                    : (bool? value) => onCertified!(value ?? false),
                activeColor: BrandColors.taytayBlue,
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'I certify that the information is true and correct, '
                    'and I consent to its processing under the Data '
                    'Privacy Act of 2012 per Taytay LGU\'s Privacy Notice.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: BrandColors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        const SizedBox(height: 45),
        const S3Card(
          child: Column(
            children: <Widget>[
              IconTile(
                icon: TaytayIcons.check,
                fill: BrandColors.chipGreenBg,
                ink: BrandColors.success,
                size: 60,
                iconSize: 28,
              ),
              SizedBox(height: 42),
              Text(
                'Profile submitted',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Your resident profile was sent to Taytay LGU. We'll "
                'notify you when it has been reviewed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: BrandColors.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 10),
              StatusChip(label: 'Pending review', tone: StatusTone.pending),
            ],
          ),
        ),
        const SizedBox(height: s3CardGap),
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
    // The label stays on one line. The 48 dp Edit target hangs off that
    // line so the row keeps the design's height.
    return SizedBox(
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Positioned(
            right: -8,
            top: -10,
            child: TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, A11y.minTapTarget),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: BrandColors.taytayBlue,
              ),
              child: const Text(
                'Edit',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: BrandColors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.verified = false,
  });

  final String label;
  final String value;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: BrandColors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: BrandColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5DCEC)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      value.isEmpty ? '—' : value,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BrandColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  if (verified)
                    const StatusChip(
                      label: 'Verified',
                      tone: StatusTone.verified,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initials(ResidentRecord record) {
  final String given = record.givenName.trim();
  final String family = record.familyName.trim();
  final String mark =
      '${given.isEmpty ? '' : given[0]}${family.isEmpty ? '' : family[0]}';
  return mark.isEmpty ? '?' : mark.toUpperCase();
}

String _streetLine(ResidentRecord record) {
  final Iterable<String> parts = <String>[
    record.street,
    if (record.purok.isNotEmpty) 'Purok ${record.purok}',
    if (record.barangayName.isNotEmpty) 'Brgy. ${record.barangayName}',
    record.municipality,
  ].where((String part) => part.isNotEmpty);
  return parts.join(', ');
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
  if (parts.length != 3) return iso;
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
  if (parsed == null) return '';
  final DateTime today = DateTime(2026, 10, 21);
  var age = today.year - parsed.year;
  if (today.month < parsed.month ||
      (today.month == parsed.month && today.day < parsed.day)) {
    age -= 1;
  }
  return '$age';
}
