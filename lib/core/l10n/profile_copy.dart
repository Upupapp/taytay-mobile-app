import 'package:flutter/widgets.dart';

import '../../features/profile/domain/barangay_lock.dart';
import '../../features/profile/domain/name_lock.dart';
import '../../features/profile/domain/office_record.dart';
import '../../features/profile/domain/verification_decision.dart';
import '../../l10n/app_localizations.dart';

// Resident-facing copy for the profile domain's values, which live in
// `features/profile/domain/` with no `BuildContext`: the name check, the
// barangay held by the office, and the office's own record (D-237).
//
// Each keeps its English in the domain as the no-context fallback, the
// arrangement `AppFailure.residentMessage` uses; a screen comes through here.
// The sentences with no domain logic behind them (`NameCheckCopy.asPrinted`
// and the rest) are plain keys, named beside each constant below.

/// The one sentence under the name on Edit profile. Mirrors
/// [NameLock.explanation].
String nameLockExplanation(BuildContext context, NameLock lock) {
  final strings = AppStrings.of(context);
  return switch (lock) {
    NameLock.open => strings.profNameAsPrinted,
    NameLock.underReview => strings.profNameUnderReview,
    NameLock.checked => strings.profNameChecked,
    NameLock.unknown => strings.profNameUnknown,
  };
}

/// [NameCheckCopy], in the resident's language. One record so a screen that
/// shows several of these reads them in one call.
///
/// `fieldLabel` is the profile's own "Full name" key, so the two can never
/// disagree; `tooLong` carries [NameLock.maxLength].
({
  String fieldLabel,
  String asPrinted,
  String beforeSendingTitle,
  String beforeSending,
  String checkName,
  String emptyName,
  String tooLong,
})
nameCheckCopy(BuildContext context) {
  final strings = AppStrings.of(context);
  return (
    fieldLabel: strings.profileFieldFullName,
    asPrinted: strings.profNameAsPrinted,
    beforeSendingTitle: strings.profNameBeforeSendingTitle,
    beforeSending: strings.profNameBeforeSending,
    checkName: strings.profNameCheckName,
    emptyName: strings.profNameEmpty,
    tooLong: strings.profNameTooLong(NameLock.maxLength),
  );
}

/// [BarangayLock]'s three sentences, in the resident's language.
({String heldNote, String refusedTitle, String refused}) barangayLockCopy(
  BuildContext context,
) {
  final strings = AppStrings.of(context);
  return (
    heldNote: strings.profBarangayHeldNote,
    refusedTitle: strings.profBarangayRefusedTitle,
    refused: strings.profBarangayRefused,
  );
}

/// [OfficeRecordCopy], in the resident's language. `sex` and `barangay` are
/// the profile's own field names, so the record and the profile name a field
/// the same way.
({
  String title,
  String keptByOffice,
  String name,
  String sex,
  String birthDate,
  String barangay,
  String notShown,
})
officeRecordCopy(BuildContext context) {
  final strings = AppStrings.of(context);
  return (
    title: strings.profOfficeRecordTitle,
    keptByOffice: strings.profOfficeRecordKeptByOffice,
    name: strings.profOfficeRecordName,
    sex: strings.profileFieldSex,
    birthDate: strings.profOfficeRecordBirthDate,
    barangay: strings.profileFieldBarangay,
    notShown: strings.profOfficeRecordNotShown,
  );
}

/// What the profile shows for the office's recorded sex. Mirrors
/// [OfficeRecordSex.label].
String officeRecordSexLabel(BuildContext context, OfficeRecordSex sex) {
  final strings = AppStrings.of(context);
  return switch (sex) {
    OfficeRecordSex.female => strings.profSexFemale,
    OfficeRecordSex.male => strings.profSexMale,
  };
}

/// [OfficeRecord.birthDateLabel] with the month named in the reader's
/// language (`Ago 5, 1990`). The order of month, day and year is the same in
/// both, so the two can never name different days.
String officeRecordBirthDate(BuildContext context, OfficeRecord record) =>
    record.birthDateLabelIn(Localizations.localeOf(context).languageCode);

/// [manilaDecisionDate] with the month named in the reader's language.
String? verificationDecisionDate(BuildContext context, DateTime? instant) =>
    manilaDecisionDate(
      instant,
      languageCode: Localizations.localeOf(context).languageCode,
    );
