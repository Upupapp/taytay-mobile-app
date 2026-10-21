import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/resident_record.dart';
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
        'Continue',
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
    return Scaffold(
      backgroundColor: BrandColors.surface,
      body: Column(
        children: <Widget>[
          S3Header(title: title, subtitle: subtitle, onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 29, 20, 12),
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
                  ProfileWizardStep.submitted => const _Submitted(),
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
    final name = record.displayName.isEmpty ? 'Your name' : record.displayName;
    final barangay = record.barangayName.isEmpty
        ? 'Taytay'
        : record.barangayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(0, 2.2),
          child: Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: BrandColors.textPrimary,
            ),
          ),
        ),
        ),
        const SizedBox(height: 1),
        Transform.translate(
          offset: const Offset(0, -1),
          child: Row(
          children: <Widget>[
            const CircleAvatar(
              radius: 11,
              backgroundColor: BrandColors.surfaceMuted,
              child: Text(
                'JD',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.taytayBlue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Brgy. $barangay, Taytay,',
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
            const StatusChip(label: 'Pending review', tone: StatusTone.pending),
          ],
        ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: const Padding(
          padding: EdgeInsets.only(left: 30, top: 2),
          child: Text(
            'Rizal',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: BrandColors.textSecondary,
            ),
          ),
        ),
        ),
        const SizedBox(height: 16),
        Transform.translate(
          offset: const Offset(0, -1.3),
          child: Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Profile completeness',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: BrandColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${record.completeness}%',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: BrandColors.taytayBlue,
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 8),
        Transform.translate(
          offset: const Offset(0, -4),
          child: ClipRRect(
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
        ),
        const SizedBox(height: 8),
        Transform.translate(
          offset: const Offset(0, -6),
          child: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Complete all sections to submit your profile to Taytay LGU.',
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: BrandColors.textSecondary,
            ),
          ),
        ),
        ),
        const SizedBox(height: 44),
        _SplitRow(
          title: 'Personal information',
          detail: record.personalComplete ? 'Complete' : 'Not started',
          detailColor: BrandColors.success,
          marks: 1,
          titleShift: -4.7,
          markShift: -12,
          detailShift: -13.7,
          bottom: 23,
          onTap: onPersonal,
        ),
        _JoinedRow(
          icon: TaytayIcons.house,
          title: 'Household & address',
          detail: record.householdStarted ? 'In progress' : 'Not started',
          detailColor: BrandColors.warning,
          onTap: onHousehold,
        ),
        const _JoinedRow(
          icon: TaytayIcons.fileText,
          title: 'Supporting documents',
          detail: 'Optional',
          detailColor: BrandColors.textSecondary,
          shift: 1.33,
        ),
        _SplitRow(
          title: 'Review & submit',
          detail: 'Not started',
          detailColor: BrandColors.textSecondary,
          marks: 2,
          titleShift: -0.7,
          markShift: -7,
          detailShift: -12.33,
          onTap: onReview,
        ),
      ],
    );
  }
}

/// Title, then one or two icon marks, then the detail. Each is its own run.
class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.title,
    required this.detail,
    required this.detailColor,
    required this.marks,
    this.titleShift = 0,
    this.markShift = 0,
    this.detailShift = 0,
    this.bottom = 22,
    this.onTap,
  });

  final String title;
  final String detail;
  final Color detailColor;
  final int marks;
  final double titleShift;
  final double markShift;
  final double detailShift;
  final double bottom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Transform.translate(
              offset: Offset(0, titleShift),
              child: Row(
              children: <Widget>[
                const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                ),
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
            const SizedBox(height: 4),
            for (var i = 0; i < marks; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 4),
              Transform.translate(
                offset: Offset(0, markShift),
                child: Container(
                width: 14,
                height: 4,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: BrandColors.taytayBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ),
            ],
            const SizedBox(height: 4),
            Transform.translate(
              offset: Offset(0, detailShift),
              child: Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                detail,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: detailColor,
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

/// Title and detail share one run because a bar bridges them.
class _JoinedRow extends StatelessWidget {
  const _JoinedRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.detailColor,
    this.onTap,
    this.shift = 0,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color detailColor;
  final VoidCallback? onTap;
  final double shift;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Transform.translate(
          offset: Offset(0, shift),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 28,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(width: 3, height: 40, color: BrandColors.taytayBlue),
                  TaytayIcon(
                    icon: icon,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: 18,
                    color: BrandColors.taytayBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: detailColor,
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
        _Pair(
          left: _Field(label: 'First name', value: record.givenName),
          right: _Field(label: 'Middle name', value: record.middleName),
        ),
        _Pair(
          left: _Field(label: 'Last name', value: record.familyName),
          right: _Field(label: 'Suffix', value: record.suffix),
        ),
        _Pair(
          left: _Field(label: 'Sex', value: record.sex, valueDrop: 0),
          right: _Field(
            label: 'Birthdate',
            value: _birth(record.birthdate),
            valueDrop: 0,
          ),
        ),
        _Pair(
          left: _Field(label: 'Civil status', value: record.civilStatus),
          right: _Field(label: 'Age', value: _age(record.birthdate)),
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(top: 32, bottom: 8),
            child: Text(
              'Contact',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: BrandColors.textPrimary,
              ),
            ),
          ),
        ),
        _Field(
          label: 'Mobile number',
          value: record.mobile,
          trailing: record.mobileVerified ? 'Verified' : null,
        ),
        _Field(label: 'Email', value: record.email),
      ],
    );
  }
}

class _Household extends StatelessWidget {
  const _Household({required this.record});

  final ResidentRecord record;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -1.5),
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
          ),
        ),
        const SizedBox(height: 8),
        _Field(label: 'Barangay', value: record.barangayName),
        Transform.translate(
          offset: const Offset(0, -6),
          child: const Wrap(
            spacing: 8,
            runSpacing: 0,
            children: <Widget>[
              _Chip('Dolores'),
              _Chip('Muzon'),
              _Chip('San Juan'),
              _Chip('Santa Ana'),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
        _Pair(
          left: _Field(label: 'House no. / Street', value: record.street),
          right: _Field(label: 'Purok / Sitio', value: record.purok),
        ),
        _Field(
          label: 'Municipality / Province',
          value: '${record.municipality}, ${record.province}',
        ),
        const SizedBox(height: 10),
        Text(
          _streetLine(record),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.15,
            color: BrandColors.taytayBlue,
          ),
        ),
        Text(
          record.province,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.15,
            color: BrandColors.taytayBlue,
          ),
        ),
        const SizedBox(height: 57),
        const Text(
          'Household',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: BrandColors.textPrimary,
          ),
        ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Pair(
          left: _Field(label: 'Years at this address', value: record.yearsAtAddress),
          right: _Field(label: 'Household members', value: record.memberCount),
        ),
        _Field(label: 'Residence type', value: record.residenceType),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _EditHeader(title: 'Personal information', onEdit: onEditPersonal),
        _Line(label: 'Name', value: record.displayName),
        _Line(
          label: 'Sex · Birthdate',
          value: '${record.sex} · ${_birth(record.birthdate)}',
        ),
        _Line(label: 'Civil status', value: record.civilStatus),
        _Line(label: 'Mobile', value: record.mobile),
        const SizedBox(height: 35),
        _EditHeader(title: 'Household & address', onEdit: onEditHousehold),
        _Line(label: 'Address', value: _shortAddress(record)),
        _Line(
          label: 'Barangay',
          value: '${record.barangayName}, ${record.municipality}, ${record.province}',
        ),
        _Line(label: 'Years at address', value: record.yearsAtAddress),
        _Line(label: 'Household members', value: record.memberCount),
        const SizedBox(height: 35),
        Transform.translate(
          offset: const Offset(0, 1.33),
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: GestureDetector(
                onTap: onCertified == null
                    ? null
                    : () => onCertified!(!certified),
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: certified
                        ? BrandColors.taytayBlue
                        : BrandColors.surfaceCard,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: BrandColors.taytayBlue, width: 2),
                  ),
                  child: certified
                      ? const TaytayIcon(
                          icon: TaytayIcons.check,
                          semanticLabel: 'Certified',
                          size: 12,
                          color: Colors.white,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'I certify that the information is true and correct,\n'
                'and I consent to its processing under the Data\n'
                'Privacy Act of 2012 per Taytay LGU\'s Privacy\n'
                'Notice.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: BrandColors.textSecondary,
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
  const _Submitted();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        SizedBox(height: 68),
        TaytayIcon(
          icon: TaytayIcons.checkCircle,
          semanticLabel: 'Submitted',
          size: 40,
          color: BrandColors.success,
        ),
        SizedBox(height: 42),
        Text(
          'Profile submitted',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: BrandColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Your resident profile was sent to Taytay LGU. We\'ll\n'
            'notify you when it has been reviewed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: BrandColors.textSecondary,
            ),
          ),
        ),
        SizedBox(height: 9.3),
        StatusChip(label: 'Pending review', tone: StatusTone.pending),
        SizedBox(height: 50),
        ProgressRow(
          icon: TaytayIcons.check,
          title: 'Submitted',
          detail: 'Oct 20, 2026 · 8:40 PM',
        ),
        ProgressRow(
          icon: TaytayIcons.clock,
          title: 'LGU review',
          detail: 'Usually 1–3 working days',
          iconDark: false,
          titleShift: 3.67,
          detailShift: 1,
        ),
        ProgressRow(
          icon: TaytayIcons.badgeCheck,
          title: 'Profile verified',
          detail: '',
          iconDark: false,
          showDetail: false,
          titleShift: 4,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: BrandColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                'Edit',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: BrandColors.taytayBlue,
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
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: BrandColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: BrandColors.textPrimary,
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
    this.trailing,
    this.valueDrop = 1,
  });

  final String label;
  final String value;
  final String? trailing;

  /// Shifts the value ink down without changing the row's layout height.
  /// One logical px is 3 device px. The personal-info values sit 4 device px
  /// high except the sex row, which is already on its line.
  final double valueDrop;

  @override
  Widget build(BuildContext context) {
    final String? mark = trailing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            ),
          ),
          const SizedBox(height: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: BrandColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5DCEC)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10 + valueDrop, 12, 10 - valueDrop),
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
                      ),
                    ),
                  ),
                  if (mark != null)
                    Text(
                      mark,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.success,
                      ),
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

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = label == 'San Juan';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD6E2F8) : BrandColors.surfaceCard,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: selected ? const Color(0xFFD6E2F8) : const Color(0xFFD5DCEC),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w600,
              color: selected ? BrandColors.taytayBlue : BrandColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

String _streetLine(ResidentRecord record) {
  final parts = <String>[
    record.street,
    if (record.purok.isNotEmpty) 'Purok ${record.purok}',
    if (record.barangayName.isNotEmpty) 'Brgy. ${record.barangayName}',
    record.municipality,
  ].where((String part) => part.isNotEmpty);
  return parts.join(', ');
}

String _shortAddress(ResidentRecord record) {
  final parts = <String>[
    record.street,
    if (record.purok.isNotEmpty) 'Purok ${record.purok}',
  ].where((String part) => part.isNotEmpty);
  return parts.join(', ');
}

String _birth(String iso) {
  final parts = iso.split('-');
  if (parts.length != 3) return iso;
  const months = <String>[
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
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return iso;
  return '${months[month - 1]} $day, ${parts[0]}';
}

String _age(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  final today = DateTime(2026, 10, 21);
  var age = today.year - parsed.year;
  if (today.month < parsed.month ||
      (today.month == parsed.month && today.day < parsed.day)) {
    age -= 1;
  }
  return '$age';
}
