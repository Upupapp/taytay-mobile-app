import 'dart:typed_data';

/// What the registration wizard holds until a citizen registration route exists.
///
/// Creating the account still declines. Consent and a verification request are
/// posted from this draft once a session exists. Bytes stay out of [toString].
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

  /// `POST me/consents` body. There is no published notice version yet.
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

  @override
  String toString() => 'AccountApplication(redacted)';
}
