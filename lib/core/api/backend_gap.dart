import '../result/result.dart';

/// An operation whose backend **module is implemented** and whose **endpoint
/// does not exist**.
///
/// ---
///
/// **The third statement, and the one the re-baseline had no word for.** Before
/// `backend@api-baseline-2026-08` this app had exactly one sentence for every
/// absent thing — "the module is planned" — and it flattened three different
/// situations into it. They have different owners and different remedies, so
/// they are now different types:
///
/// | Statement | Who is blocked | Remedy |
/// | --- | --- | --- |
/// | `PlannedModule` | the backend has not built the module | backend roadmap |
/// | [BackendGap] | the module is built; **this route is not** | a named backend change |
/// | `UnwiredRepository` | the route serves; we have not called it | an indexed TAB here |
///
/// The middle row is the dangerous one. It looks like wiring work from the app
/// side and like finished work from the backend side, so it is the row that gets
/// planned around by both and closed by neither. Every member here carries the
/// finding id it was raised under so that TAB 24's launch dossier can state it
/// as accepted-or-closed with an artifact, rather than discovering it.
///
/// Resident-visible behaviour matches the other two — a temporary
/// [ServerFailure] — because "not built", "not routed" and "not connected" are
/// the same afternoon to somebody standing in a barangay hall. Only
/// `AppFailure.debugMessage` distinguishes them, for logs and support tooling.
enum BackendGap {
  /// **F15 — no resident can create their own account.**
  ///
  /// The entire public `Identity` surface is sign-in: `auth/otp` answers "if
  /// that number is registered, a code has been sent to it", and
  /// `AuthenticationService::requestSignInCode` returns null for a number it
  /// does not already hold. Citizen accounts are created by staff at
  /// `POST admin/residents` and bound to a login at
  /// `POST admin/residents/{resident}/account-links` — both admin-console
  /// surfaces this app is forbidden to call.
  ///
  /// So onboarding is **staff-mediated by construction**, and this app ships a
  /// seven-field self-registration wizard with no server counterpart. That is a
  /// product decision to confirm with the LGU, not a defect to code around: an
  /// app that let a resident believe they had enrolled themselves would send
  /// them to a counter that has never heard of them.
  residentSelfRegistration(
    finding: 'F15',
    missing: 'any route that creates a citizen account',
    servedInstead:
        'POST admin/residents + POST admin/residents/{resident}/account-links '
        '(admin-console channel only)',
  ),

  /// **F16 — a sign-in code is issued, recorded, and never sent.**
  ///
  /// `AuthenticationController::requestCode` calls `requestSignInCode`, then
  /// `unset($code)` — deliberately, so the code is neither returned nor logged,
  /// which is right. What is missing is the other half: nothing dispatches it.
  /// The comment there still says delivery waits on the `Notification` module,
  /// and that comment is stale in the same way this app was — `Notification` has
  /// been implemented since backend TAB 20, and it has no awareness of sign-in
  /// codes at all.
  ///
  /// This is why it matters here rather than only in a backend backlog: TAB 02's
  /// definition of done is a resident signing in by OTP on a physical device.
  /// No amount of correct client wiring reaches it while the code never leaves
  /// the server.
  signInCodeDelivery(
    finding: 'F16',
    missing: 'delivery of the issued sign-in code over any channel',
    servedInstead: 'the code is persisted against the account and discarded',
  ),

  /// **F14 — no resident-facing barangay directory.**
  ///
  /// The registration and profile flows need Taytay's barangays to offer an
  /// address. The only barangay routes at the baseline are
  /// `POST staff/{staff}/barangays` and its delete — `AccessControl` staff
  /// scoping, a staff surface. Hardcoding the list in the app was considered and
  /// rejected: barangay boundaries and names are municipal records, and a client
  /// copy is a second source of truth that goes wrong quietly.
  barangayDirectory(
    finding: 'F14',
    missing: 'a public or resident-scoped barangay reference list',
    servedInstead: 'staff scope grants only (staff/{staff}/barangays)',
  ),

  /// **F23 — a KYC correction cannot be filed the way the office asks for it.**
  ///
  /// `POST me/profile/corrections` takes named fields. This app groups what a
  /// resident recognises — "your details", "proof of identity" — because those
  /// are the categories a reviewer flags. The two do not line up: "your details"
  /// is three fields and a document is none of them, and choosing one on the
  /// resident's behalf files a correction against something the office never
  /// questioned.
  ///
  /// Closing it needs a decision rather than code: either this app models
  /// corrections per field, or the server accepts a KYC-shaped one. Until then
  /// the categories that map to exactly one field are sent and the rest decline,
  /// because a correction filed against the wrong field is worse than one not
  /// filed — the resident believes the office has been told.
  kycFieldCorrections(
    finding: 'F23',
    missing: 'a correction route keyed the way a KYC reviewer flags items',
    servedInstead: 'POST me/profile/corrections, keyed by named field',
  ),

  /// **F13 — no route closes, erases or deletes an account.**
  ///
  /// `Audit` serves consents and acknowledgements, so most of the privacy screen
  /// has somewhere to go. Closure does not: no module publishes it at the
  /// baseline. Google Play and the App Store both require an in-app account
  /// deletion path, so this is a launch blocker owned by TAB 22 — and it needs
  /// the retention schedule from TAB 18 before it can even be specified, because
  /// a municipal record cannot always simply be erased and the screen has to say
  /// what is deleted and what is kept by law.
  accountClosure(
    finding: 'F13',
    missing: 'account closure / erasure request',
    servedInstead: 'nothing',
  );

  const BackendGap({
    required this.finding,
    required this.missing,
    required this.servedInstead,
  });

  /// The finding id in `docs/integration/backend-baseline.md`.
  final String finding;

  /// What the contract does not publish.
  final String missing;

  /// What it publishes in its place, if anything.
  final String servedInstead;
}

/// The honest failure for an operation the backend has no route for.
Err<T> backendGapFailure<T>(BackendGap gap, String operation) => Err<T>(
  ServerFailure(
    isTemporary: true,
    debugMessage:
        'No endpoint serves "$operation": ${gap.missing} '
        '(${gap.finding}). Served instead: ${gap.servedInstead}.',
  ),
);
