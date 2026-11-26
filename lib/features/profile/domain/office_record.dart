import 'package:flutter/foundation.dart';

/// The registry record the MSWDO office keeps about the resident, as `GET /me`
/// sends it in `office_record` (backend ADR 0016, D-235).
///
/// ---
///
/// **The office's record, read under her own session.** A
/// `registry_record_updated` notice names which details the office changed
/// ("your name and birth date") and never their values, because a notice can
/// be read on a locked phone by whoever holds it. The values are here, behind
/// the sign-in, so she can see what the office now holds.
///
/// **Read-only, always.** Nothing in this app writes it. If it is wrong, she
/// asks at the office with her ID; the office corrects it with a reason and the
/// earlier value kept (ADR 0015, ADR 0016).
@immutable
class OfficeRecord {
  const OfficeRecord({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.barangayId,
    this.middleName,
    this.suffix,
    this.sex,
  });

  final String firstName;
  final String? middleName;
  final String lastName;
  final String? suffix;

  /// Null for a value this build does not know, never a guess.
  final OfficeRecordSex? sex;

  /// The calendar date as sent, `YYYY-MM-DD`. A date, not an instant: no
  /// timezone is applied to it, ever.
  final String birthDate;

  /// The barangay's id. A screen names it from the barangay list and never
  /// shows the id (D-228).
  final String barangayId;

  /// The four name parts, in the order a Filipino name is written.
  String get fullName => <String?>[
    firstName,
    middleName,
    lastName,
    suffix,
  ].whereType<String>().where((String part) => part.isNotEmpty).join(' ');

  /// `Mar 3, 1990`, from the date's own digits, or the value as sent when it
  /// is not a `YYYY-MM-DD` date. Written out rather than numeric, as the
  /// decision date is (`manilaDecisionDate`), so `03/04/1990` cannot be read
  /// two ways.
  String get birthDateLabel {
    final RegExpMatch? match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(birthDate);
    if (match == null) return birthDate;
    final int year = int.parse(match.group(1)!);
    final int month = int.parse(match.group(2)!);
    final int day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return birthDate;
    return '${_months[month - 1]} $day, $year';
  }

  static const List<String> _months = <String>[
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

  /// Redacted in full: every value here is personal data about a named
  /// resident.
  @override
  String toString() => 'OfficeRecord(redacted)';
}

/// `office_record.sex`. The registry records one of two values.
enum OfficeRecordSex {
  female('female', 'Female'),
  male('male', 'Male');

  const OfficeRecordSex(this.wireValue, this.label);

  final String wireValue;

  /// What the profile shows.
  final String label;

  /// Null for anything else, so an unknown value is never named.
  static OfficeRecordSex? parse(Object? raw) {
    for (final OfficeRecordSex sex in values) {
      if (sex.wireValue == raw) return sex;
    }
    return null;
  }
}

/// What the resident reads about her record at the office (D-235). Literal
/// English, as the account screens are.
abstract final class OfficeRecordCopy {
  static const String title = 'Your record at the MSWDO office';

  static const String keptByOffice =
      'The office keeps this record. If something here is wrong, visit the '
      'MSWDO office with your ID.';

  static const String name = 'Name';
  static const String sex = 'Sex';
  static const String birthDate = 'Birth date';
  static const String barangay = 'Barangay';

  /// A value the record has and this build cannot name: an unknown sex, or a
  /// barangay the list does not hold. Never the raw id.
  static const String notShown = 'Ask the MSWDO office';
}
