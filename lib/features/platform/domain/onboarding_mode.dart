/// How a resident comes to have an account, as the platform actually works.
///
/// ## The question this does not answer
///
/// **Whether residents should be able to enrol themselves is the LGU's decision,
/// and TAB 03 does not take it.** Manual-tasks item 5 puts it fairly: either
/// onboarding is staff-mediated, and the wizard this app ships should not be
/// offered, or residents self-enrol, and the backend needs a route plus an
/// identity-assurance policy the municipality has not written. Nobody can pick
/// that from the code.
///
/// What the client can do is stop being *wrong today*. There is no
/// self-registration route on the server — the public `Identity` surface is
/// sign-in only, and citizen accounts are created by staff on the admin console
/// — so a resident who downloads this app fills in seven fields and meets a dead
/// end. An app that says "sign in with the number the office registered" is
/// honest; a wizard that cannot complete is a promise the platform cannot keep.
///
/// ## Why it is read from the server
///
/// The same arrangement `digital_id` already uses: both states ship in one
/// build, and the server decides which one a resident sees. That is what lets
/// the municipality change its mind without a store release — and it means the
/// day the decision arrives it costs a line of configuration rather than a
/// sprint. F16 taught that lesson expensively enough to reuse.
///
/// The flag is `self_registration` on `app/bootstrap`'s `features`. The backend
/// does not publish it today, which is correct: it has no route to back it, and
/// an absent flag resolves to [staffMediated], the state the platform is
/// actually in.
enum OnboardingMode {
  /// Accounts are created by staff at the MSWDO office. The default.
  ///
  /// Chosen as the default because it describes the platform as it stands. A
  /// default that describes reality is the safe one; a default that describes
  /// an intention is a bug waiting for the intention to change.
  staffMediated,

  /// Residents enrol themselves. Requires a server route that does not yet
  /// exist — the flag being on without one would be a server misconfiguration,
  /// not a client bug.
  selfEnrolled;

  /// Reads the mode from the bootstrap flag.
  ///
  /// An absent flag is not an error and is not logged as one. Most responses
  /// will not carry it.
  static OnboardingMode fromFlag(bool selfRegistrationEnabled) =>
      selfRegistrationEnabled
      ? OnboardingMode.selfEnrolled
      : OnboardingMode.staffMediated;

  bool get allowsSelfRegistration => this == OnboardingMode.selfEnrolled;
}
