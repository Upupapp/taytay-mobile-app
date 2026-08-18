/// This build's version, as `major.minor.patch`.
///
/// A constant rather than a package lookup. `package_info_plus` would answer the
/// same question and would be the only dependency in this app added solely to
/// read a string the build already knows — Article 1 asks for a stated reason
/// per dependency, and "to avoid maintaining one line" is not one.
///
/// The risk of a hand-maintained constant is that it drifts from `pubspec.yaml`,
/// so it does not get to: `test/core/app_version_test.dart` reads the pubspec and
/// fails when the two disagree. That check costs nothing and runs on every
/// commit, which is more than a runtime lookup would guarantee.
///
/// Compared against the server's published minimum by `SupportedVersion`.
const String appVersion = '1.0.0';
