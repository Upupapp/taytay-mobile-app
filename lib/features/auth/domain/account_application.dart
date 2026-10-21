/// What the registration wizard holds until a citizen registration route exists.
///
/// The live repository declines registration. This object names the fields
/// the screen collected without putting them in [toString].
class AccountApplication {
  const AccountApplication({
    required this.email,
    required this.mobile,
    required this.givenName,
    required this.familyName,
  });

  final String email;
  final String mobile;
  final String givenName;
  final String familyName;

  @override
  String toString() => 'AccountApplication(redacted)';
}
