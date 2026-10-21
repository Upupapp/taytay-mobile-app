/// What the registration wizard holds until a citizen registration route exists.
///
/// The live repository declines registration. This object names the fields
/// the screen collected without putting them in [toString].
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
  });

  final String email;

  /// Kept on the draft. It is not written to a staff route and never logged.
  final String password;

  final String mobile;
  final String givenName;
  final String familyName;
  final String barangay;
  final bool hasGovernmentId;
  final bool selfieTaken;

  @override
  String toString() => 'AccountApplication(redacted)';
}
