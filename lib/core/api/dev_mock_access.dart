/// Development credential for the Node API.
///
/// In dev the server accepts `Authorization: Bearer mock:<role>:<id>` in place
/// of a Firebase ID token. The role segment is part of that credential string.
/// It is not a permission field: Article 3 still forbids a role, tier, or scope
/// of its own.
///
/// The Role enum on the Taytay LGU IDS API is `guest`, `registered`,
/// `verified`, `staff`, and `admin`. This resident app mints only
/// [registeredRole] and [verifiedRole]. `guest` has no bearer. `staff` and
/// `admin` are other channels.
abstract final class DevMockAccess {
  static const String registeredRole = 'registered';
  static const String verifiedRole = 'verified';

  static const Set<String> mintedRoles = <String>{registeredRole, verifiedRole};

  /// `mock:<role>:<id>`, or null when [id] cannot be one token segment or
  /// [role] is not a role this app mints.
  static String? tryToken({required String id, String role = verifiedRole}) {
    if (id.isEmpty || id.contains(':')) return null;
    if (!mintedRoles.contains(role)) return null;
    return 'mock:$role:$id';
  }
}
