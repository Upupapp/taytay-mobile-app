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

/// The routes this app calls, sorted by path then method.
const List<BackendRoute> backendRoutes = <BackendRoute>[
  BackendRoute('GET', 'app/bootstrap', 'platform_api_repository.dart'),
  BackendRoute('POST', 'auth/otp', 'auth_api_repository.dart'),
  BackendRoute('POST', 'auth/otp/verify', 'auth_api_repository.dart'),
  BackendRoute('DELETE', 'auth/tokens/current', 'auth_api_repository.dart'),
  BackendRoute('GET', 'barangays', 'barangay_api_repository.dart'),
  BackendRoute('GET', 'events', 'event_api_repository.dart'),
  BackendRoute('GET', 'events/{}', 'event_api_repository.dart'),
  BackendRoute('DELETE', 'events/{}/registration', 'event_api_repository.dart'),
  BackendRoute('POST', 'events/{}/registration', 'event_api_repository.dart'),
  BackendRoute('GET', 'health', 'platform_api_repository.dart'),
  BackendRoute('GET', 'me', 'auth_api_repository.dart'),
  BackendRoute(
    'GET',
    'me/assistance-history',
    'assistance_api_repository.dart',
  ),
  BackendRoute('GET', 'me/assistance/drafts', 'assistance_api_repository.dart'),
  BackendRoute(
    'POST',
    'me/assistance/drafts',
    'assistance_api_repository.dart',
  ),
  BackendRoute(
    'DELETE',
    'me/assistance/drafts/{}',
    'assistance_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'me/assistance/drafts/{}/submit',
    'assistance_api_repository.dart',
  ),
  BackendRoute('GET', 'me/cases/{}', 'assistance_api_repository.dart'),
  BackendRoute(
    'GET',
    'me/cases/{}/requirements',
    'requirement_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'me/cases/{}/requirements/{}/documents',
    'requirement_api_repository.dart',
  ),
  BackendRoute('GET', 'me/credential', 'credential_api_repository.dart'),
  BackendRoute('POST', 'me/credential/qr', 'credential_api_repository.dart'),
  BackendRoute('POST', 'me/devices', 'notification_api_repository.dart'),
  BackendRoute('DELETE', 'me/devices/{}', 'notification_api_repository.dart'),
  BackendRoute('GET', 'me/household', 'household_api_repository.dart'),
  BackendRoute('GET', 'me/kyc', 'kyc_api_repository.dart'),
  BackendRoute('POST', 'me/kyc', 'kyc_api_repository.dart'),
  BackendRoute('POST', 'me/kyc/submit', 'kyc_api_repository.dart'),
  // F28 — the documents a KYC case had nowhere to put.
  BackendRoute('POST', 'me/kyc/documents', 'kyc_api_repository.dart'),
  BackendRoute('GET', 'me/kyc/documents', 'kyc_api_repository.dart'),
  BackendRoute(
    'GET',
    'me/notification-preferences',
    'notification_api_repository.dart',
  ),
  BackendRoute(
    'PUT',
    'me/notification-preferences',
    'notification_api_repository.dart',
  ),
  BackendRoute('GET', 'me/notifications', 'notification_api_repository.dart'),
  BackendRoute(
    'POST',
    'me/notifications/read-all',
    'notification_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'me/notifications/{}/read',
    'notification_api_repository.dart',
  ),
  BackendRoute('GET', 'me/privacy/consents', 'privacy_api_repository.dart'),
  BackendRoute(
    'DELETE',
    'me/privacy/consents/{}',
    'privacy_api_repository.dart',
  ),
  BackendRoute('GET', 'me/profile', 'auth_api_repository.dart'),
  BackendRoute(
    'POST',
    'me/profile/corrections',
    'resident_profile_api_repository.dart',
  ),
  BackendRoute('GET', 'me/sessions', 'session_api_repository.dart'),
  BackendRoute('POST', 'me/sessions/revoke-all', 'session_api_repository.dart'),
  BackendRoute('DELETE', 'me/sessions/{}', 'session_api_repository.dart'),
  BackendRoute('GET', 'newsfeed', 'newsfeed_api_repository.dart'),
  BackendRoute(
    'DELETE',
    'newsfeed-comments/{}',
    'newsfeed_api_repository.dart',
  ),
  BackendRoute(
    'POST',
    'newsfeed-comments/{}/reports',
    'newsfeed_api_repository.dart',
  ),
  BackendRoute('GET', 'newsfeed/{}', 'newsfeed_api_repository.dart'),
  BackendRoute('GET', 'newsfeed/{}/comments', 'newsfeed_api_repository.dart'),
  BackendRoute('POST', 'newsfeed/{}/comments', 'newsfeed_api_repository.dart'),
  BackendRoute(
    'DELETE',
    'newsfeed/{}/reaction',
    'newsfeed_api_repository.dart',
  ),
  BackendRoute('POST', 'newsfeed/{}/reaction', 'newsfeed_api_repository.dart'),
  BackendRoute('GET', 'programs', 'program_api_repository.dart'),
  BackendRoute('GET', 'programs/{}', 'program_api_repository.dart'),
  BackendRoute('GET', 'services', 'service_catalog_api_repository.dart'),
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
const List<String> routesAheadOfBaseline = <String>[
  'GET barangays',
  'POST newsfeed-comments/{}/reports',
];
