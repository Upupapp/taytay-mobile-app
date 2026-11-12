import 'dart:typed_data';

/// What the registration wizard sends as the verification request.
///
/// By the time this is built the Firebase account exists, the profile is saved
/// ([RegistrationProfile]) and consent is recorded. Only the ID type and the
/// photos leave from here. Bytes stay out of [toString].
class AccountApplication {
  const AccountApplication({
    required this.email,
    required this.password,
    required this.mobile,
    required this.givenName,
    required this.familyName,
    required this.barangay,
    this.hasGovernmentId = false,
    this.selfieTaken = false,
    this.idTypeLabel = 'PhilSys National ID',
    this.noticeVersion = noticeDraft,
    this.idFrontBytes,
    this.idFrontName,
    this.idFrontMime,
    this.idBackBytes,
    this.idBackName,
    this.idBackMime,
    this.selfieBytes,
    this.selfieName,
    this.selfieMime,
    this.idempotencyKey,
  });

  /// The screen says the privacy notice is still a draft.
  static const String noticeDraft = 'draft';

  final String email;

  /// Kept on the draft. It is not written to a staff route and never logged.
  final String password;

  final String mobile;
  final String givenName;
  final String familyName;
  final String barangay;
  final bool hasGovernmentId;
  final bool selfieTaken;

  /// The label the resident picked. The repository maps it to the wire enum.
  final String idTypeLabel;

  /// Kept for the draft the screen used to label itself with.
  ///
  /// `submitProfile` does not send this. Consent versions come from
  /// `GET /app/config` (`privacy_version` and `terms_version`).
  final String noticeVersion;

  final Uint8List? idFrontBytes;
  final String? idFrontName;
  final String? idFrontMime;
  final Uint8List? idBackBytes;
  final String? idBackName;
  final String? idBackMime;
  final Uint8List? selfieBytes;
  final String? selfieName;
  final String? selfieMime;

  /// The send's idempotency key (a UUID v4), minted when the resident first
  /// presses Submit and the same on every retry of that send, so a retry
  /// cannot open a second request (D-213). Null sends none.
  final String? idempotencyKey;

  @override
  String toString() => 'AccountApplication(redacted)';
}

/// What the wizard writes to `PATCH /me` once the account exists.
///
/// The Node API creates the profile row with no name, email or barangay on the
/// first `GET /me`, and `POST /auth/email-otp/send` refuses a profile with no
/// email. So these are saved before a code is asked for.
///
/// One [fullName], because `ProfilePatch` has one `name` (gap 4). [barangayId]
/// is the UUID `GET /barangays` published, never a typed name. Nothing here is
/// authority-shaped, and [toString] is redacted.
class RegistrationProfile {
  const RegistrationProfile({
    required this.givenName,
    required this.familyName,
    required this.mobile,
    required this.email,
    required this.barangayId,
    this.street = '',
  });

  final String givenName;
  final String familyName;

  /// Digits only, as `09XXXXXXXXX`.
  final String mobile;
  final String email;
  final String barangayId;

  /// The "Street / Purok" line. Empty clears it on the server.
  final String street;

  String get fullName => '${givenName.trim()} ${familyName.trim()}'.trim();

  @override
  String toString() => 'RegistrationProfile(redacted)';
}

/// What `PATCH /me` answered that the wizard needs next.
class SavedProfile {
  const SavedProfile({required this.emailVerified});

  /// `email_verified` on the profile the server returned. True only when the
  /// saved email was already confirmed with a code, so no new code is needed.
  final bool emailVerified;

  @override
  String toString() => 'SavedProfile(emailVerified: $emailVerified)';
}
