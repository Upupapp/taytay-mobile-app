import '../result/result.dart';

/// A repository whose backend module **is implemented** and which this app has
/// **not yet called**.
///
/// ---
///
/// **Why this exists as a separate thing from `PlannedModule`.** Until the
/// re-baseline at `backend@api-baseline-2026-08`, every stub in this app said
/// the same sentence: the module is planned, there is no endpoint. For four
/// modules that had since shipped, and for four repositories whose module was
/// never the one named, that sentence was false — and because it was a claim
/// about the *server*, nobody reading the app could tell. The app declined
/// roughly seventy endpoints that were serving, including every route a
/// resident needs to sign in.
///
/// So the two statements are now different types:
///
/// * `PlannedModule` / `plannedBackendFailure` — **the backend has not built
///   this.** Nothing this repository can do changes it. Exactly two modules
///   qualify at the baseline, and neither has a repository here.
/// * [UnwiredRepository] / [unwiredRepositoryFailure] — **the backend serves
///   this and we have not wired it.** It is our work, it has an owner, and it
///   has an indexed TAB.
///
/// Keeping them apart is the whole mechanism. A stub that says "planned" reads
/// as *waiting on somebody else* and is invisible in a status review; a stub
/// that says "unwired, TAB 07" is a work item with a name on it. [wiredBy] is
/// what makes the backlog readable out of the source rather than out of a
/// document that drifts — which is how this app came to be nine months behind
/// its own server.
///
/// The resident-visible behaviour is identical to the planned case and
/// deliberately so: a temporary [ServerFailure], because from where the resident
/// is standing "not built" and "not connected" are the same afternoon. Only
/// `AppFailure.debugMessage` differs, and that is for logs and support tooling
/// (see `app_failure.dart`), never for a screen.
enum UnwiredRepository {
  auth(
    module: 'Identity',
    wiredBy: 'TAB 02',
    endpoints: <String>[
      'POST auth/otp',
      'POST auth/otp/verify',
      'POST auth/tokens',
      'POST auth/tokens/mfa',
      'POST auth/password/forgot',
      'DELETE auth/tokens/current',
    ],
  ),
  deviceSessions(
    module: 'Identity',
    wiredBy: 'TAB 03',
    endpoints: <String>[
      'GET me/sessions',
      'DELETE me/sessions/{session}',
      'POST me/sessions/revoke-all',
      'GET me/devices',
      'POST me/devices',
      'DELETE me/devices/{device}',
    ],
  ),
  registration(
    module: 'Identity + ResidentProfile',
    wiredBy: 'TAB 02',
    endpoints: <String>[
      'POST auth/otp',
      'POST auth/otp/verify',
      'POST me/contact/verify',
      'POST me/contact/verify/confirm',
    ],
  ),
  residentProfile(
    module: 'ResidentProfile',
    wiredBy: 'TAB 04',
    endpoints: <String>['GET me', 'GET me/profile'],
  ),

  /// The resident's **own KYC**, which is `ResidentProfile` — not the backend's
  /// `Verification` module.
  ///
  /// This one was mis-filed on a shared English word, and it is the sharpest
  /// instance of the class the re-baseline was written to find. `Verification`
  /// owns "verification attempts, scan events, verifier registry,
  /// offline-verification key distribution" — a *verifier* scanning a resident's
  /// QR, which belongs to the `verifier-device` channel and which this app is
  /// forbidden to build (CLAUDE.md, and the Master Command's TAB 06 §6). What
  /// the resident does — open an attempt, submit documents, read the outcome,
  /// answer a correction — is KYC, and `me/kyc` has been serving it since
  /// backend TAB 06.
  ///
  /// Shrinking `PlannedModule` to two members did not catch this: the name it
  /// referenced still existed and still meant something real, just not this.
  /// Only reading the two contracts side by side did.
  residentKyc(
    module: 'ResidentProfile',
    wiredBy: 'TAB 04',
    endpoints: <String>[
      'GET me/kyc',
      'POST me/kyc',
      'POST me/kyc/submit',
      'GET me/profile/corrections',
      'POST me/profile/corrections',
      'DELETE me/profile/corrections/{correction}',
    ],
  ),
  household(
    module: 'ResidentProfile',
    wiredBy: 'TAB 05',
    endpoints: <String>['GET me/household'],
  ),

  /// Built, and switched off at the server.
  ///
  /// The only repository here whose module carries a second axis: `Credential`
  /// is **implemented and feature-flagged off**. Wiring it is TAB 06's job;
  /// *enabling* it is a coordinated server-side change the LGU makes, surfaced
  /// to this app as `digital_id` on `GET app/bootstrap`. Both states must ship
  /// in one build, so neither "planned" nor a hardcoded constant is the right
  /// statement — the flag is.
  credential(
    module: 'Credential (implemented, feature-flagged off)',
    wiredBy: 'TAB 06',
    endpoints: <String>['GET me/credential', 'POST me/credential/qr'],
  ),
  programs(
    module: 'ServiceCatalog',
    wiredBy: 'TAB 07',
    endpoints: <String>['GET programs', 'GET programs/{program}'],
  ),
  serviceRequests(
    module: 'Welfare',
    wiredBy: 'TAB 08 (drafts) · TAB 09 (cases, history)',
    endpoints: <String>[
      'GET me/assistance/drafts',
      'POST me/assistance/drafts',
      'PATCH me/assistance/drafts/{draft}',
      'DELETE me/assistance/drafts/{draft}',
      'POST me/assistance/drafts/{draft}/submit',
      'GET me/cases',
      'GET me/cases/{case}',
      'POST me/cases/{case}/cancel',
      'GET me/assistance-history',
      'GET me/referrals',
    ],
  ),
  requirements(
    module: 'Welfare + Files',
    wiredBy: 'TAB 10',
    endpoints: <String>[
      'GET me/cases/{case}/requirements',
      'POST me/cases/{case}/requirements/{requirement}/documents',
      'POST me/cases/{case}/requirements/{requirement}/documents/{version}/access',
      'GET documents/{handle}',
    ],
  ),

  /// The newsfeed. The app calls it "announcements" and asks for a path that has
  /// never existed on this backend: `GET announcements` returns nothing from any
  /// module at the baseline, while `Content` has served `GET newsfeed` since
  /// backend TAB 23. A wrong path and a wrong module status are separate errors
  /// and this repository carried both.
  newsfeed(
    module: 'Content',
    wiredBy: 'TAB 11',
    endpoints: <String>[
      'GET newsfeed',
      'GET newsfeed/{post}',
      'GET newsfeed/{post}/comments',
      'POST newsfeed/{post}/comments',
      'POST newsfeed/{post}/reaction',
      'DELETE newsfeed/{post}/reaction',
      'POST newsfeed/{post}/share',
      'PATCH newsfeed-comments/{comment}',
      'DELETE newsfeed-comments/{comment}',
    ],
  ),
  events(
    module: 'Events',
    wiredBy: 'TAB 12',
    endpoints: <String>[
      'GET events',
      'GET events/{event}',
      'POST events/{event}/registration',
      'DELETE events/{event}/registration',
      'GET me/event-registrations',
      'GET me/event-registrations/{registration}',
    ],
  ),
  notifications(
    module: 'Notification',
    wiredBy: 'TAB 13',
    endpoints: <String>[
      'GET me/notifications',
      'POST me/notifications/{notification}/read',
      'POST me/notifications/read-all',
      'GET me/notification-preferences',
      'PUT me/notification-preferences',
    ],
  ),

  /// Consent and privacy records are served; **account closure is not**.
  ///
  /// `Audit` publishes `me/privacy/consents` and the acknowledgement route, so
  /// the consent half of this repository has somewhere to go today. No module
  /// publishes a route that closes, erases or deletes an account at the
  /// baseline — see `docs/integration/backend-baseline.md` §"Genuine gaps",
  /// finding F13. Both stores require an in-app deletion path, so that is a
  /// launch blocker owned by TAB 22 and it is a *backend* gap, not a wiring one.
  accountControls(
    module: 'Audit (consents) · no module (closure)',
    wiredBy: 'TAB 18 (consents) · TAB 22 (closure, blocked on F13)',
    endpoints: <String>[
      'GET me/privacy/consents',
      'POST me/privacy/consents',
      'DELETE me/privacy/consents/{purpose}',
      'POST me/privacy/acknowledgement',
    ],
  );

  const UnwiredRepository({
    required this.module,
    required this.wiredBy,
    required this.endpoints,
  });

  /// The backend module that serves this repository's endpoints, as the
  /// committed boundary map names it at the baseline tag.
  final String module;

  /// The indexed TAB that wires it. This is the backlog, and it is here rather
  /// than in a document because a document is what went stale.
  final String wiredBy;

  /// The routes it must call, relative to the `/api/v1` base. Verified present
  /// at `backend@api-baseline-2026-08`; see `docs/integration/backend-baseline.md`.
  final List<String> endpoints;
}

/// The honest failure for an operation whose endpoint exists and is not yet called.
///
/// Same resident-visible outcome as `plannedBackendFailure` — a temporary
/// [ServerFailure] — and a debug message that says whose work it is.
Err<T> unwiredRepositoryFailure<T>(
  UnwiredRepository repository,
  String operation,
) => Err<T>(
  ServerFailure(
    isTemporary: true,
    debugMessage:
        '${repository.module} serves "$operation" at '
        '${repository.endpoints.join(', ')}, and this app has not wired it '
        'yet. Wired by ${repository.wiredBy}.',
  ),
);
