/// Development credential for the Node API.
///
/// In dev the server accepts `Authorization: Bearer mock:<role>:<id>` in place
/// of a Firebase ID token. The role segment is part of that credential string.
/// It is not a permission field: Article 3 still forbids a role, tier, or scope
/// of its own. This client mints only [residentRole].
///
/// The spelling of the role is the resident word. The OpenAPI enum on
/// `cursor/sprint-0-foundation-b3f2` was not readable from this environment, so
/// a different spelling in that file would replace this constant.
abstract final class DevMockAccess {
  static const String residentRole = 'resident';

  /// `mock:<role>:<id>`, or null when [id] cannot be one token segment.
  static String? tryToken({required String id}) {
    if (id.isEmpty || id.contains(':')) return null;
    return 'mock:$residentRole:$id';
  }
}
