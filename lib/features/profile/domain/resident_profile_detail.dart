import 'package:flutter/foundation.dart';

import 'profile_fields.dart';

/// The resident's own record, as this app is willing to hold it.
///
/// ---
///
/// **A map keyed by a closed enum, not a class with a field per column.** Two
/// consequences, both deliberate:
///
/// 1. There is no property for a registry identifier, a staff note, a risk
///    score, an audit entry or a household member, because [ResidentProfileField]
///    has no case for one. The shape is the first privacy control; the decoder
///    is the second.
/// 2. Every value is optional. The `ResidentProfile` module is `planned`, so a
///    partially-populated record is the normal case, not an error — and a screen
///    that renders "not on file yet" per field degrades far better than one that
///    fails because a column was absent.
///
/// **Values are strings, already formatted by the server.** The app does not
/// parse a birth date into a `DateTime` and re-render it: reformatting a
/// government record is how "03/04/1990" becomes the wrong date in a different
/// locale, and the app has no reason to compute anything from it.
@immutable
class ResidentProfileDetail {
  const ResidentProfileDetail({
    this.values = const <ResidentProfileField, String>{},
    this.verificationTier,
  });

  /// Only fields this app names. Anything else was dropped at the decoder.
  final Map<ResidentProfileField, String> values;

  /// The server's own tier string, unmapped. `AccessLevel.fromVerificationTier`
  /// is the only thing that interprets it, and it fails closed.
  final String? verificationTier;

  String? valueOf(ResidentProfileField field) => values[field];

  bool has(ResidentProfileField field) {
    final value = values[field];
    return value != null && value.isNotEmpty;
  }

  /// Whether the LGU holds anything at all under [ownership].
  bool hasAny(FieldOwnership ownership) =>
      ResidentProfileField.ownedBy(ownership).any(has);

  /// Redacted in full. Every value in here is personal data about a named
  /// resident, and this is exactly the object that reaches a crash report.
  @override
  String toString() => 'ResidentProfileDetail(fields: ${values.length})';
}

/// What a resident may change about their own contact details.
///
/// Mirrors `PATCH /api/v1/me/profile`, which the matrix restricts to **contact
/// fields only**. Nothing else can be expressed by this type, so no caller can
/// assemble a request that asks the server to change a canonical field — the
/// server would refuse it, and a refusal a resident sees after filling in a form
/// is a worse experience than a form that never offered the field.
@immutable
class ContactDetailsUpdate {
  const ContactDetailsUpdate({this.mobileNumber, this.emailAddress});

  /// `null` means "leave unchanged"; an empty string is not sent.
  final String? mobileNumber;
  final String? emailAddress;

  bool get isEmpty =>
      (mobileNumber == null || mobileNumber!.isEmpty) &&
      (emailAddress == null || emailAddress!.isEmpty);

  /// The fields this update touches. Used to prove, in a test, that it can
  /// never carry anything the resident does not own.
  Set<ResidentProfileField> get touchedFields => <ResidentProfileField>{
    if (mobileNumber != null && mobileNumber!.isNotEmpty)
      ResidentProfileField.mobileNumber,
    if (emailAddress != null && emailAddress!.isNotEmpty)
      ResidentProfileField.emailAddress,
  };

  /// Redacted: a mobile number and an email address are both personal data
  /// under RA 10173.
  @override
  String toString() => 'ContactDetailsUpdate(${touchedFields.length} fields)';
}
