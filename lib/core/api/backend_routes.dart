/// Every `api/v1` route this app calls, declared.
///
/// ## Why a list of routes and not only a list of modules
///
/// `backend_baseline.dart` pins a tag and
/// `docs/integration/backend-baseline.md` records which *modules* existed at it.
/// TAB 00 of the front-end sequence found that this is not enough, and the way
/// it found out is the argument for this file: two wired features —
/// `GET barangays` and `POST newsfeed-comments/{comment}/reports` — call routes
/// that **do not exist at the pinned commit**. They arrived in the thirty-three
/// backend commits after it.
///
/// The module guard passed anyway, and could not have done otherwise. Both
/// routes were added inside modules that were already `implemented` at the tag,
/// so no module's status changed. A module table answers *does this module
/// exist*; a client needs *does this route exist*, and those are different
/// questions with the same shape.
///
/// So the routes are declared here, and two guards read them:
///
///  * `test/integration/backend_routes_test.dart` — every `ApiClient.send` call
///    in `lib/` appears below, and every row below is actually called. It runs
///    in `flutter test` and catches *us* drifting.
///  * `tool/check_backend_routes.sh` — every row below exists in the backend at
///    the pinned baseline. It needs the backend clone and catches *the contract*
///    drifting.
///
/// Path parameters are written `{}` rather than named. What varies is which
/// segment is dynamic, never what it is called here, and a name in this file
/// would be a second vocabulary nobody maintains.
library;

/// One route: the method, the path template, and the repository that calls it.
///
/// [caller] is the file name rather than the class, because a repository that is
/// renamed keeps its file and a reader chasing a route wants somewhere to open.
final class BackendRoute {
  const BackendRoute(this.method, this.path, this.caller);

  final String method;
  final String path;
  final String caller;

  @override
  String toString() => '$method $path';
}

/// The citizen routes this app calls on the Taytay LGU IDS API, sorted by path
/// then method. Admin paths are absent. Historical PHP paths that the Node
/// contract does not publish are not called.
const List<BackendRoute> backendRoutes = <BackendRoute>[
  BackendRoute('GET', 'app/config', 'platform_api_repository.dart'),
  BackendRoute('POST', 'auth/email-otp/send', 'auth_api_repository.dart'),
  BackendRoute('POST', 'auth/email-otp/verify', 'auth_api_repository.dart'),
  BackendRoute(
    'POST',
    'auth/password-reset/complete',
    'auth_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'auth/password-reset/request',
    'auth_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'auth/password-reset/verify',
    'auth_api_repository.dart',
  ),
  BackendRoute('GET', 'barangays', 'barangay_api_repository.dart'),
  BackendRoute('GET', 'health', 'platform_api_repository.dart'),
  BackendRoute('GET', 'home', 'node_citizen_api.dart'),
  BackendRoute('GET', 'hotlines', 'node_citizen_api.dart'),
  BackendRoute('POST', 'households', 'household_api_repository.dart'),
  BackendRoute('DELETE', 'households/current', 'household_api_repository.dart'),
  BackendRoute('GET', 'households/current', 'household_api_repository.dart'),
  BackendRoute('PATCH', 'households/current', 'household_api_repository.dart'),
  BackendRoute(
    'POST',
    'households/current/leave',
    'household_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'households/current/members',
    'household_api_repository.dart',
  ),
  BackendRoute(
    'DELETE',
    'households/current/members/{}',
    'household_api_repository.dart',
  ),
  BackendRoute(
    'PATCH',
    'households/current/members/{}',
    'household_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'households/current/transfer',
    'household_api_repository.dart',
  ),
  BackendRoute(
    'GET',
    'households/invitations/current',
    'household_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'households/invitations/{}/accept',
    'household_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'households/invitations/{}/decline',
    'household_api_repository.dart',
  ),
  BackendRoute('GET', 'me', 'resident_profile_api_repository.dart'),
  BackendRoute('PATCH', 'me', 'resident_profile_api_repository.dart'),
  BackendRoute('POST', 'me/avatar', 'resident_profile_api_repository.dart'),
  BackendRoute('POST', 'me/close', 'privacy_api_repository.dart'),
  BackendRoute('GET', 'me/consents', 'privacy_api_repository.dart'),
  BackendRoute('POST', 'me/consents', 'privacy_api_repository.dart'),
  BackendRoute('DELETE', 'me/devices', 'notification_api_repository.dart'),
  BackendRoute('POST', 'me/devices', 'notification_api_repository.dart'),
  BackendRoute('GET', 'me/digital-id', 'credential_api_repository.dart'),
  BackendRoute(
    'GET',
    'me/notification-preferences',
    'notification_api_repository.dart',
  ),
  BackendRoute(
    'PATCH',
    'me/notification-preferences',
    'notification_api_repository.dart',
  ),
  BackendRoute('POST', 'me/verification-requests', 'kyc_api_repository.dart'),
  BackendRoute(
    'GET',
    'me/verification-requests/current',
    'kyc_api_repository.dart',
  ),
  BackendRoute('POST', 'media', 'node_citizen_api.dart'),
  BackendRoute('GET', 'media/{}', 'node_citizen_api.dart'),
  BackendRoute('GET', 'news', 'newsfeed_api_repository.dart'),
  BackendRoute('GET', 'news/{}', 'newsfeed_api_repository.dart'),
  BackendRoute('GET', 'notifications', 'notification_api_repository.dart'),
  BackendRoute(
    'POST',
    'notifications/read',
    'notification_api_repository.dart',
  ),
  BackendRoute(
    'GET',
    'notifications/unread-count',
    'notification_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'notifications/{}/read',
    'notification_api_repository.dart',
  ),
  BackendRoute('GET', 'offices', 'node_citizen_api.dart'),
  BackendRoute('GET', 'offices/{}', 'node_citizen_api.dart'),
  BackendRoute('GET', 'services', 'service_catalog_api_repository.dart'),
  BackendRoute('GET', 'services/{}', 'service_catalog_api_repository.dart'),
  BackendRoute('GET', 'threads', 'office_messaging_gap_repository.dart'),
  BackendRoute('POST', 'threads', 'office_messaging_gap_repository.dart'),
  BackendRoute('GET', 'threads/{}', 'office_messaging_gap_repository.dart'),
  BackendRoute(
    'POST',
    'threads/{}/close',
    'office_messaging_gap_repository.dart',
  ),
  BackendRoute(
    'GET',
    'threads/{}/messages',
    'office_messaging_gap_repository.dart',
  ),
  BackendRoute(
    'POST',
    'threads/{}/messages',
    'office_messaging_gap_repository.dart',
  ),
  BackendRoute(
    'POST',
    'threads/{}/read',
    'office_messaging_gap_repository.dart',
  ),
];

/// Routes this app calls that do **not** exist at the pinned baseline.
///
/// **This is a ratchet, not an allowance.** `tool/check_backend_routes.sh` fails
/// if a route is missing from the baseline and absent from this list — so a
/// third one cannot arrive quietly — and it fails *equally* if this list names a
/// route that the baseline turns out to have, so the list cannot outlive the
/// problem it records. A permanently red guard is one people learn to skip; a
/// list that can only shrink is one that closes.
///
/// Both entries are finding **C-09** in `docs/frontend/open-work.md`. They close
/// by moving the baseline forward to a tag that includes them, which is blocked
/// on the backend repository being still long enough to tag — not by editing
/// this list.
/// Empty. The live contract is the vendored Node OpenAPI, not the PHP pin.
/// The four historical C-09 paths are no longer called.
const List<String> routesAheadOfBaseline = <String>[];
