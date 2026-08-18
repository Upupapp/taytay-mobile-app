import 'package:flutter/foundation.dart';

/// Sex as the civil registry records it.
///
/// ---
///
/// **Two values because the server accepts two, and the server accepts two
/// because this is matched against a PSA birth record.** `POST me/kyc`
/// validates `in:female,male`; `ResidentMatcher` then compares the claim to the
/// canonical registry, and a value the registry cannot hold matches nothing.
///
/// This is therefore **not a gender field** and must not be widened into one. A
/// resident's gender is theirs; what this asks is which of two words appears on
/// the document the office will check the claim against. If the product ever
/// wants to record gender identity, that is a separate field on the resident
/// profile with its own consent basis — not this one relabelled.
enum ClaimedSex {
  female('female'),
  male('male');

  const ClaimedSex(this.wireValue);

  /// Sent as-is. The app never sends an index or a boolean: a numeric sex is
  /// unreadable in an audit log and a boolean has to decide which one is true.
  final String wireValue;
}

/// What a resident claims about themselves when opening a KYC case.
///
/// ---
///
/// **This is a claim, not a record.** Nothing here is believed. `POST me/kyc`
/// writes it to `claimed_*` columns on a case, a reviewer compares it against
/// the canonical registry, and the resident's actual profile is only ever
/// written by the office. The naming is deliberate and should stay that way —
/// a `ResidentDetails` type here would invite a future reader to display these
/// values back as though the LGU had confirmed them.
///
/// **The barangay travels as a code.** F14: the only identifier `POST me/kyc`
/// accepted was the `barangays` auto-increment primary key, which no route
/// published, so no resident could open a case at all. The directory now
/// publishes a UUID and a stable slug, and the slug is what a claim is filed
/// against — see `BarangayDirectory`.
///
/// **No mobile number, no email, no PhilSys number.** The account already
/// carries the first two and the server takes them from the authenticated
/// actor; the third is what the office looks up, never what an applicant
/// asserts. A field here is a field in a municipal review queue forever.
@immutable
class KycClaim {
  const KycClaim({
    required this.givenName,
    required this.familyName,
    required this.birthDate,
    required this.sex,
    required this.barangayCode,
    required this.streetAddress,
    this.middleName = '',
    this.suffix = '',
  });

  final String givenName;

  /// Optional: many Filipino records carry one, some do not. An absent middle
  /// name is a fact about the record, not an incomplete form.
  final String middleName;

  final String familyName;

  /// Optional: Jr, Sr, III.
  final String suffix;

  /// Date only. The time of day a person was born is not something the office
  /// asks for, and carrying one invites a timezone bug that shifts a birthday
  /// across midnight and fails a match.
  final DateTime birthDate;

  final ClaimedSex sex;

  /// The `code` slug from `GET barangays`, never a locally invented key and
  /// never the integer primary key.
  final String barangayCode;

  final String streetAddress;

  /// Whether every field the server requires has something in it.
  ///
  /// Checked here rather than only in the form so that a second caller — a
  /// resumed draft, a deep link — cannot post a claim the server will refuse
  /// with a 422 the resident can do nothing about.
  bool get isComplete =>
      givenName.trim().isNotEmpty &&
      familyName.trim().isNotEmpty &&
      barangayCode.trim().isNotEmpty &&
      streetAddress.trim().isNotEmpty;

  /// Redacted: this object is a person's name, birth date and home address.
  ///
  /// Article 5.2. It reaches a log the first time somebody interpolates a claim
  /// into an error message, and a municipal system does not get to un-log a
  /// resident's address.
  @override
  String toString() => 'KycClaim(redacted)';
}
