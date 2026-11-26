import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../profile/domain/office_record.dart';
import '../../registration/domain/registration_domain.dart';

/// The resident's record at the MSWDO office, read-only (D-235).
///
/// ---
///
/// **What a `registry_record_updated` notice points at.** The notice names
/// which details the office changed and never their values, because a notice
/// can be read on a locked phone; the values are here, behind her sign-in, from
/// `GET /me` `office_record` (backend ADR 0016).
///
/// **Nothing here can be edited**, and nothing pretends it can: no chevron, no
/// field. The one sentence under it says how a wrong value is corrected. The
/// barangay is named from the barangay list and never shown as its id
/// (D-228); one the list cannot name, and a sex this build does not know, say
/// to ask the office rather than show a raw value.
class OfficeRecordSection extends StatelessWidget {
  const OfficeRecordSection({
    required this.record,
    required this.barangays,
    super.key,
  });

  final OfficeRecord record;

  /// `GET /barangays`, already read by the screen. Empty when it failed.
  final List<Barangay> barangays;

  @override
  Widget build(BuildContext context) {
    final String barangay =
        barangayFor(record.barangayId, barangays)?.name ??
        OfficeRecordCopy.notShown;
    return SoftCard(
      key: officeRecordSectionKey,
      filled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              OfficeRecordCopy.title,
              style: AppTypography.listTitle.copyWith(
                fontWeight: AppTypography.strong,
                color: BrandColors.ink,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          _Row(label: OfficeRecordCopy.name, value: record.fullName),
          _Row(
            label: OfficeRecordCopy.sex,
            value: record.sex?.label ?? OfficeRecordCopy.notShown,
          ),
          _Row(label: OfficeRecordCopy.birthDate, value: record.birthDateLabel),
          _Row(label: OfficeRecordCopy.barangay, value: barangay),
          const SizedBox(height: Spacing.sm),
          Text(
            OfficeRecordCopy.keptByOffice,
            style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Finds the section in a test.
const Key officeRecordSectionKey = Key('office-record-section');

/// One label over its value, read as one line by a screen reader.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              value,
              style: AppTypography.fieldValue.copyWith(color: BrandColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
