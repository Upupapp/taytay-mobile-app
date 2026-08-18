import '../session/access_policy.dart';

/// Every destination in the app, with the access it requires.
///
/// The requirement lives *next to the path*, not in a separate table and not
/// inside the screen, so that adding a route forces the author to answer "who
/// may see this?" in the same edit. `AppRouter` reads only from here; a route
/// that is not in this enum cannot be registered.
///
/// ---
///
/// **Path parameters.** Some routes carry one opaque server identifier —
/// `/news/:postId`, `/requests/:requestId`. That identifier arrives from a push
/// notification, an SMS or a printed QR code, so it is attacker-writable and is
/// validated on the way in (`DeepLink`), never trusted on the way out. A route
/// declares its parameters here so the matcher, the guard and the link builder
/// all read one definition.
enum AppRoute {
  /// Cold-start screen. Holds until the session is restored.
  splash('splash', '/', AccessRequirement.public),

  /// First-run introduction. Public: it explains what the app is *before*
  /// asking anyone to hand over identity information.
  onboarding('onboarding', '/onboarding', AccessRequirement.public),

  /// The server will not serve this build. Blocking, and public — a resident
  /// who cannot sign in must still be able to be told why.
  updateRequired(
    'update-required',
    '/update-required',
    AccessRequirement.public,
  ),

  /// The office's system is down. Public for the same reason, and reachable
  /// while cached public content still is.
  maintenance('maintenance', '/maintenance', AccessRequirement.public),

  /// Sign-in. Public by definition.
  signIn('sign-in', '/sign-in', AccessRequirement.public),

  /// Help for a resident who cannot sign in. Public: the people who need it are
  /// by definition the people who could not authenticate, and it collects
  /// nothing and looks nothing up.
  signInHelp('sign-in-help', '/sign-in-help', AccessRequirement.public),

  /// Citizen registration. Public: a person without an account is exactly who
  /// needs it, and the flow itself is what creates the account.
  register('register', '/register', AccessRequirement.public),

  // ---------------------------------------------------------------------------
  // The five shell destinations. Fixed, in this order, for every access level.
  // ---------------------------------------------------------------------------
  /// Resident dashboard.
  ///
  /// Public on purpose. A guest can browse LGU services, announcements and
  /// office information without an account: requiring registration to read
  /// public-service information would exclude residents who cannot or will not
  /// register, and would collect personal data with no purpose behind it.
  home('home', '/home', AccessRequirement.public),

  /// The municipal service catalogue. Public — the backend says so explicitly:
  /// `GET /api/v1/services` is unauthenticated because "citizens must be able to
  /// browse it before registering".
  services('services', '/services', AccessRequirement.public),

  /// One catalogue entry, addressed by its stable code rather than its UUID.
  ///
  /// A code is what a municipal office quotes, it is legible in a link, and it
  /// survives a re-seed of the catalogue. Public, like the list it comes from.
  serviceDetail(
    'service-detail',
    '/services/:serviceCode',
    AccessRequirement.public,
    parameters: <String>['serviceCode'],
  ),

  /// Announcements (`balita`). Public: `GET /api/v1/announcements`.
  news('news', '/news', AccessRequirement.public),

  /// One announcement, by opaque id. The target of a push notification.
  newsPost(
    'news-post',
    '/news/:postId',
    AccessRequirement.public,
    parameters: <String>['postId'],
  ),

  /// LGU events. Public: `GET /api/v1/events`.
  events('events', '/events', AccessRequirement.public),

  /// One event, by opaque id.
  eventDetail(
    'event-detail',
    '/events/:eventId',
    AccessRequirement.public,
    parameters: <String>['eventId'],
  ),

  /// Registering for one event.
  ///
  /// **Authenticated, not verified** — and that is the server's call, not a
  /// guess. Whether an unverified resident may register is a per-event policy
  /// (`EventRegistrationForm.allowsUnverifiedResidents`): a barangay clean-up
  /// may take anyone with an account, a cash-aid orientation may not. Gating the
  /// route at `verified` would refuse the first case; gating it at `public`
  /// would open a `/me`-scoped write to a guest. `authenticated` is the honest
  /// floor, and the screen shows a verification gate when the form asks for one.
  eventRegistration(
    'event-registration',
    '/events/:eventId/register',
    AccessRequirement.authenticated,
    parameters: <String>['eventId'],
  ),

  /// The resident's own area. **Public**, and deliberately so: it is the fifth
  /// tab, it must exist for a guest, and for a guest it shows the way in rather
  /// than a locked door. Everything inside it that needs an account declares
  /// its own requirement.
  profile('profile', '/profile', AccessRequirement.public),

  /// The contact details a resident owns and may change. Authenticated: there
  /// is nothing to edit without an account.
  profileContact(
    'profile-contact',
    '/profile/contact',
    AccessRequirement.authenticated,
  ),

  /// Privacy, rights and retention. **Public**, and deliberately so: someone
  /// deciding whether to register should be able to read what they would be
  /// agreeing to first, and the screen is fixed copy that discloses nothing by
  /// being opened.
  profilePrivacy(
    'profile-privacy',
    '/profile/privacy',
    AccessRequirement.public,
  ),

  // ---------------------------------------------------------------------------
  // Destinations reached from inside the shell.
  // ---------------------------------------------------------------------------
  /// Settings, help, privacy and accessibility.
  ///
  /// **Public.** Acceptance 1 of TAB 24 is that privacy text is reachable
  /// without login, and the reasoning goes further: somebody deciding whether to
  /// register should be able to read what they would be agreeing to, find out
  /// how to reach the LGU, and turn motion down — all before handing over a
  /// mobile number. The account sections are absent for a guest rather than
  /// present and locked.
  settings('settings', '/settings', AccessRequirement.public),

  /// Help and FAQs. Public: it collects nothing and looks nothing up, and the
  /// people who need it most are the ones without an account.
  help('help', '/settings/help', AccessRequirement.public),

  /// Consent history and account requests. Authenticated — it is a record about
  /// one person.
  privacyControls(
    'privacy-controls',
    '/settings/privacy',
    AccessRequirement.authenticated,
  ),

  /// Account and preferences — needs an account, verified or not.
  account('account', '/account', AccessRequirement.authenticated),

  /// Everything Taytay LGU has sent this resident.
  ///
  /// Authenticated: a notification is addressed to a person, and there is
  /// nothing to show somebody without an account. A guest reading public
  /// advisories does it in the newsfeed, which is open to them.
  notifications(
    'notifications',
    '/notifications',
    AccessRequirement.authenticated,
  ),

  /// What a resident chooses to be told about.
  notificationSettings(
    'notification-settings',
    '/notifications/settings',
    AccessRequirement.authenticated,
  ),

  /// Sign-in and security: app lock, device sign-out, other sessions.
  /// Authenticated, because every control on it acts on a session that must
  /// exist for the screen to mean anything.
  security('security', '/security', AccessRequirement.authenticated),

  /// Identity verification: status, next step, and the submission flow.
  /// Authenticated but explicitly *not* verified — this is how a resident
  /// becomes verified.
  verification(
    'verification',
    '/verification',
    AccessRequirement.authenticated,
  ),

  /// The form that opens a KYC case: name, date of birth, sex, barangay,
  /// street address. Authenticated and explicitly *not* verified, for the same
  /// reason as its parent — this is how a resident becomes verified, so
  /// requiring verification to reach it would close the only door to it.
  ///
  /// Unreachable in any meaningful sense until backend `api-baseline-2026-08`:
  /// `POST me/kyc` required a barangay identifier no route published (F14).
  verificationClaim(
    'verification-claim',
    '/verification/start',
    AccessRequirement.authenticated,
  ),

  /// The resident's own assistance requests. Verified only: an assistance
  /// request is an act on the resident's civil record.
  requests('requests', '/requests', AccessRequirement.verified),

  /// One assistance request, by opaque id.
  requestDetail(
    'request-detail',
    '/requests/:requestId',
    AccessRequirement.verified,
    parameters: <String>['requestId'],
  ),

  /// The documents outstanding on one assistance request.
  requestRequirements(
    'request-requirements',
    '/requests/:requestId/requirements',
    AccessRequirement.verified,
    parameters: <String>['requestId'],
  ),

  /// Applying for one service. Verified only, like the requests it produces.
  ///
  /// **A top-level path, not a child of `/services/:serviceCode`.** The
  /// catalogue is public and this is not, so nesting would put a verified-only
  /// route inside a public branch — reachable, but only because the guard says
  /// no on the way in. Keeping the boundary visible in the path means a reader
  /// can see which parts of the app are open by looking at the table.
  ///
  /// It is also full-screen rather than a shell destination: a resident
  /// part-way through an application should not be invited to wander into
  /// another tab by a navigation bar under their thumb.
  applyForService(
    'apply-for-service',
    '/apply/:serviceCode',
    AccessRequirement.verified,
    parameters: <String>['serviceCode'],
  ),

  /// Assistance programmes. **Authenticated**, because the committed citizen
  /// row is `GET /api/v1/programs?status=active` with bearer auth — unlike the
  /// service catalogue, which is public. The line is the server's.
  /// Public, because the server publishes it that way.
  ///
  /// This route required an account until TAB 07. `GET programs` carries no
  /// `auth:sanctum` and never has — so the app was withholding information the
  /// municipality had deliberately made public, from exactly the residents least
  /// likely to already have an account.
  programs('programs', '/programs', AccessRequirement.public),

  /// One programme, by its stable code.
  programDetail(
    'program-detail',
    '/programs/:programId',
    AccessRequirement.public,
    parameters: <String>['programId'],
  ),

  /// The resident's own household and family summary. Verified only: it is a
  /// statement about a home and the people the LGU serves there.
  ///
  /// **No identifier in the path, ever.** The read is `/me`-scoped, so there is
  /// nothing to put in one — and a household id in a URL is the shape that
  /// invites registry browsing.
  household('household', '/household', AccessRequirement.verified),

  /// Reporting an error in that record. Raises a question; changes nothing.
  householdCorrection(
    'household-correction',
    '/household/correction',
    AccessRequirement.verified,
  ),

  /// The resident's LGU digital ID. Verified residents only: a credential is a
  /// statement by the LGU about a person whose identity it has confirmed.
  digitalId('digital-id', '/digital-id', AccessRequirement.verified);

  const AppRoute(
    this.routeName,
    this.path,
    this.requirement, {
    this.parameters = const <String>[],
  });

  /// Name used for `goNamed` navigation. Stable; screens never hard-code paths.
  final String routeName;

  /// `go_router` path pattern, and the deep-link target.
  final String path;

  /// Who may see it. See `AccessPolicy` — this gates navigation, not authority.
  final AccessRequirement requirement;

  /// Names of the `:segments` in [path], in order.
  final List<String> parameters;

  bool get isParameterised => parameters.isNotEmpty;

  /// Query parameter carrying the destination a resident was pushed off, so
  /// sign-in can return them to it.
  static const String redirectQueryParam = 'from';

  /// The five primary destinations, in their fixed order.
  ///
  /// **The same five for a guest, an unverified resident and a verified
  /// resident.** Navigation that rearranges itself as a person's status changes
  /// makes the app unlearnable: the tab someone reached for yesterday is
  /// somewhere else today, and the change happens at the exact moment they are
  /// least sure of themselves. See `ShellDestination`.
  static const List<AppRoute> shellDestinations = <AppRoute>[
    home,
    services,
    news,
    events,
    profile,
  ];

  /// Builds a concrete location from this route's pattern.
  ///
  /// Throws in debug if a required parameter is missing — a wiring bug, not a
  /// runtime condition. Values are percent-encoded: they are opaque server ids,
  /// but encoding them means a malformed one produces a 404 rather than a path
  /// that traverses somewhere else.
  String location([Map<String, String> arguments = const <String, String>{}]) {
    var result = path;
    for (final name in parameters) {
      final value = arguments[name];
      assert(value != null, 'Route $routeName needs a "$name" parameter.');
      result = result.replaceAll(':$name', Uri.encodeComponent(value ?? ''));
    }
    return result;
  }

  /// Finds the route a concrete path belongs to.
  ///
  /// Exact matches win over parameterised ones, so `/news` resolves to the list
  /// rather than being read as a post whose id is empty.
  static AppRoute? forPath(String path) {
    for (final route in AppRoute.values) {
      if (!route.isParameterised && route.path == path) return route;
    }
    for (final route in AppRoute.values) {
      if (route.isParameterised && route._matcher.hasMatch(path)) return route;
    }
    return null;
  }

  /// Extracts this route's parameters from a concrete path, or `null` when the
  /// path does not belong to it.
  Map<String, String>? parametersOf(String concretePath) {
    final match = _matcher.firstMatch(concretePath);
    if (match == null) return null;
    return <String, String>{
      for (var i = 0; i < parameters.length; i++)
        parameters[i]: Uri.decodeComponent(match.group(i + 1) ?? ''),
    };
  }

  /// A pattern that matches this route's concrete paths.
  ///
  /// Each `:segment` becomes `([^/]+)` — one non-empty segment that **cannot
  /// contain a slash**. That single restriction is what stops `/news/../../x`
  /// or an id carrying its own path from resolving to a different route than
  /// the one the guard evaluated.
  RegExp get _matcher {
    final escaped = path
        .split('/')
        .map(
          (segment) =>
              segment.startsWith(':') ? '([^/]+)' : RegExp.escape(segment),
        )
        .join('/');
    return RegExp('^$escaped\$');
  }
}
