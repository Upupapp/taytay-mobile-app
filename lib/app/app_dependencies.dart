import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/api/api_client.dart';
import '../core/api/api_transport.dart';
import '../core/api/auth_coordinator.dart';
import '../core/api/http_api_transport.dart';
import '../core/api/media_bytes_api.dart';
import '../core/config/app_config.dart';
import '../core/documents/document_capture.dart';
import '../core/documents/platform_document_picker.dart';
import '../core/intent/intent_controller.dart';
import '../core/links/external_link_service.dart';
import '../core/links/platform_external_link_service.dart';
import '../core/mock/mock_behavior.dart';
import '../core/network/network_monitor.dart';
import '../core/session/app_lock_controller.dart';
import '../core/session/consent_gate_controller.dart';
import '../core/session/local_authenticator.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_state.dart';
import '../core/session/session_store.dart';
import '../core/sharing/platform_share_service.dart';
import '../core/sharing/share_service.dart';
import '../core/startup/launch_controller.dart';
import '../core/startup/platform_controller.dart';
import '../core/storage/keystore_session_store.dart';
import '../core/storage/public_cache.dart';
import '../core/storage/secure_secret_store.dart';
import '../core/telemetry/telemetry.dart';
import '../features/account/data/firebase_account_password_client.dart';
import '../features/account/data/mock_account_password_client.dart';
import '../features/account/domain/account_password_client.dart';
import '../features/auth/data/auth_api_repository.dart';
import '../features/auth/data/firebase_identity.dart';
import '../features/auth/data/session_api_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/device_session_repository.dart';
import '../features/citizen_api/data/node_citizen_api.dart';
import '../features/credential/data/credential_api_repository.dart';
import '../features/credential/domain/credential_repository.dart';
import '../features/events/data/event_api_repository.dart';
import '../features/events/domain/event_repository.dart';
import '../features/household/data/household_api_repository.dart';
import '../features/household/domain/household_repository.dart';
import '../features/issuance/data/issuance_api_repository.dart';
import '../features/issuance/data/mock_issuance_repository.dart';
import '../features/issuance/domain/issuance_repository.dart';
import '../features/messaging/data/office_messaging_gap_repository.dart';
import '../features/messaging/domain/office_messaging_repository.dart';
import '../features/mock_data/data/mock/resident_record_mock.dart';
import '../features/mock_data/data/mock/taytay_mocks.dart';
import '../features/news/data/newsfeed_api_repository.dart';
import '../features/news/domain/announcement_repository.dart';
import '../features/notifications/data/notification_api_repository.dart';
import '../features/notifications/domain/notification_repository.dart';
import '../features/platform/data/platform_api_repository.dart';
import '../features/platform/domain/platform_repository.dart';
import '../features/profile/data/resident_profile_api_repository.dart';
import '../features/profile/domain/resident_profile_repository.dart';
import '../features/programs/data/program_api_repository.dart';
import '../features/programs/domain/program_repository.dart';
import '../features/registration/data/barangay_api_repository.dart';
import '../features/registration/data/planned_registration_repository.dart';
import '../features/registration/domain/registration_domain.dart';
import '../features/requirements/data/requirement_api_repository.dart';
import '../features/requirements/domain/resident_requirement.dart';
import '../features/sectors/data/mock_sector_repository.dart';
import '../features/sectors/data/sector_api_repository.dart';
import '../features/sectors/domain/sector_repository.dart';
import '../features/services/data/assistance_api_repository.dart';
import '../features/services/data/service_catalog_api_repository.dart';
import '../features/services/domain/service_catalog_repository.dart';
import '../features/services/domain/service_request_repository.dart';
import '../features/settings/data/privacy_api_repository.dart';
import '../features/settings/domain/account_controls.dart';
import '../features/tulong/data/mock_social_service_repository.dart';
import '../features/tulong/data/social_service_api_repository.dart';
import '../features/tulong/domain/social_service_repository.dart';
import '../features/verification/data/kyc_api_repository.dart';
import '../features/verification/data/resident_record_api_repository.dart';
import '../features/verification/domain/resident_record_repository.dart';
import '../features/verification/domain/verification_repository.dart';

/// The composition root: every long-lived object the app needs, built once.
///
/// Wiring lives here rather than in service locators or globals so that a test
/// can construct the whole app with a fake transport and a fake secret store and
/// nothing else has to know. A feature never reaches for a singleton — it
/// receives what it needs from [AppDependencies.of].
class AppDependencies {
  AppDependencies({
    required this.config,
    required this.session,
    required this.launch,
    required this.intents,
    required this.appLock,
    required this.apiClient,
    required this.cache,
    required this.network,
    required this.telemetry,
    required this.authRepository,
    required this.deviceSessionRepository,
    required this.platformRepository,
    required this.serviceCatalogRepository,
    required this.programRepository,
    required this.announcementRepository,
    required this.eventRepository,
    required this.residentProfileRepository,
    required this.householdRepository,
    required this.registrationRepository,
    required this.barangayDirectory,
    required this.credentialRepository,
    required this.verificationRepository,
    this.residentRecordRepository,
    required this.serviceRequestRepository,
    required this.requirementRepository,
    required this.notificationRepository,
    required this.documentPicker,
    required this.shareService,
    required this.externalLinks,
    required this.accountControlsRepository,
    required this.platform,
    this.mockBehavior,
    SocialServiceRepository? socialServices,
    OfficeMessagingRepository? officeMessaging,
    IssuanceRepository? issuance,
    SectorRepository? sectors,
    AccountPasswordClient? passwordClient,
    ConsentGateController? consentGate,
    this.clock = DateTime.now,
    this.onDispose,
  }) : consentGate =
           consentGate ??
           ConsentGateController(
             session: session,
             platform: platformRepository,
             consents: accountControlsRepository,
             clock: clock,
           ),
       officeMessagingRepository =
           officeMessaging ??
           OfficeMessagingApiRepository(apiClient: apiClient),
       socialServiceRepository =
           socialServices ?? SocialServiceApiRepository(apiClient: apiClient),
       issuanceRepository =
           issuance ?? IssuanceApiRepository(apiClient: apiClient),
       sectorRepository = sectors ?? SectorApiRepository(apiClient: apiClient),
       accountPasswordClient =
           passwordClient ?? const FirebaseAccountPasswordClient(),
       citizenApi = NodeCitizenApi(apiClient: apiClient),
       mediaBytes = MediaBytesApi(apiClient: apiClient);

  /// Builds the production graph.
  ///
  /// [transport] and [secrets] are injectable because they are the app's only
  /// two contacts with the outside world — the network and the platform
  /// keystore. Everything else is pure Dart above them.
  factory AppDependencies.build({
    required AppConfig config,
    ApiTransport? transport,
    SecretStore? secrets,
    SessionStore? sessionStore,
    PublicCache? cache,
    NetworkMonitor? networkMonitor,
    TelemetrySink? telemetrySink,
    LocalAuthenticator? localAuthenticator,
    DocumentPicker? documentPicker,
    ShareService? shareService,
    ExternalLinkService? externalLinks,
  }) {
    final secretStore = secrets ?? KeystoreSecretStore();
    final store = sessionStore ?? KeystoreSessionStore(secrets: secretStore);
    final publicCache = cache ?? PublicCache();
    final network = networkMonitor ?? NetworkMonitor();
    // Off by default and off in every shipped build: `DisabledTelemetrySink`
    // reports itself unavailable, so nothing is collected until the
    // municipality names a service and a resident agrees separately.
    final telemetry = Telemetry(
      sink: telemetrySink ?? const DisabledTelemetrySink(),
      secrets: secretStore,
    );
    final session = SessionController(store: store);
    final launch = LaunchController(secrets: secretStore);
    final intents = IntentController();
    // Defaults to the real platform prompt. Tests inject
    // `UnavailableLocalAuthenticator`, which reports the feature as absent
    // rather than pretending it succeeded.
    final appLock = AppLockController(
      session: session,
      authenticator: localAuthenticator ?? PlatformLocalAuthenticator(),
      secrets: secretStore,
    );

    // Constructing this does not talk to Firebase. Dev mock never calls it.
    final FirebaseAuthIdentity identity = FirebaseAuthIdentity();

    // ── The session boundary, in one place ──────────────────────────────
    //
    // A held intent must never survive a change of account, and neither must
    // anything the previous session put on screen. Wiring that to the `401`
    // path alone left a hole a shared phone walks straight through: a resident
    // who *signs out* deliberately kept their pending intent, and the next
    // person to sign in on the same handset had it replayed as them. In Taytay
    // one smartphone per household is ordinary, so that is a real afternoon and
    // not a hypothetical.
    //
    // So the boundary is observed on the **session itself** rather than on any
    // of the three routes into it. Sign-out, expiry and a future account switch
    // all pass through here, and none of them can be added later without it.
    String? lastAccountId;
    session.addListener(() {
      final state = session.state;
      // Still reading the store: nothing has changed yet, and clearing here
      // would drop an intent captured before a cold start finished.
      if (!state.isResolved) return;

      final accountId = state.residentOrNull?.accountId;
      final previous = lastAccountId;
      lastAccountId = accountId;

      // **Signing in is not a boundary — it is the resume.** A guest who met a
      // gate, went and registered, and came back is the entire reason an intent
      // is held; clearing it here would make the gate a dead end.
      //
      // What is a boundary: a session **ending** (sign-out or expiry), and one
      // account replacing another. Both leave a held intent belonging to
      // somebody who is no longer the person holding the phone.
      final ended = previous != null && accountId == null;
      final swapped =
          previous != null && accountId != null && previous != accountId;
      if (!ended && !swapped) return;

      intents.onSessionChanged();
      // Nothing personal is in the public cache by construction, but a
      // resident handing the phone back should not see the previous session's
      // screens repopulate from memory.
      publicCache.clear();
      // Settings sign-out clears the app session only. Firebase still holds
      // the user until this boundary ends it. A swap is the new sign-in.
      if (ended && !config.usesMockData) {
        unawaited(identity.signOut());
      }
    });

    // Live calls refresh the Firebase ID token. There is no HTTP refresh
    // route. Dev mock keeps its minted bearer, and a 401 ends that session.
    final authCoordinator = AuthCoordinator(
      onSessionInvalidated: session.handleUnauthenticated,
      refresher: config.usesMockData
          ? null
          : FirebaseTokenRefresher(identity: identity, session: session),
    );

    final httpTransport = transport ?? HttpApiTransport(config: config);

    // Late-bound so the client can tell the startup layer about a `503` while
    // the startup layer's own repository is built on the client. The knot is
    // real — maintenance is observed on the same connection that reports it —
    // and a nullable holder is a smaller price than a second client.
    late final PlatformController platform;

    final apiClient = ApiClient(
      config: config,
      transport: httpTransport,
      accessTokenProvider: () async {
        if (!config.usesMockData && session.state is AuthenticatedSession) {
          final String? token = await identity.idToken();
          if (token != null && token.isNotEmpty) return token;
        }
        return session.currentAccessToken();
      },
      onUnauthenticated: session.handleUnauthenticated,
      authCoordinator: authCoordinator,
      cache: publicCache,
      networkMonitor: network,
      onOutcome: (failure) => platform.observe(failure),
    );

    // Dev mocks stand in only when AppConfig has already accepted the flag.
    // A release build, and staging and production, never reach this branch:
    // they refuse to start.
    final mock = config.usesMockData
        ? MockBehaviorController.fromConfig(config)
        : null;

    final PlatformRepository platformRepository = mock == null
        ? PlatformApiRepository(apiClient: apiClient)
        : MockPlatformRepository(mock);
    final BarangayDirectory barangayDirectory = mock == null
        ? BarangayApiRepository(apiClient: apiClient)
        : MockBarangayDirectory(mock);
    platform = PlatformController(
      repository: platformRepository,
      telemetry: telemetry,
      // TAB 05: the page size the server chose for this channel reaches every
      // paged repository through the one client they all already hold.
      onPagePolicy: (policy) => apiClient.pages = policy,
    );

    // ── F27: the session boundary can now withdraw what this install registered
    //
    // Bound here rather than passed to the constructor because the cycle has to
    // be broken somewhere: this repository needs `apiClient`, `apiClient` needs
    // `session` for its bearer token, and `session` needs this to withdraw a
    // registration before it discards that token.
    late final NotificationRepository notifications;
    if (mock == null) {
      final api = NotificationApiRepository(apiClient: apiClient);
      notifications = api;
      session.bindPushRegistration(api);
    } else {
      final mocked = MockNotificationRepository(mock);
      notifications = mocked;
      session.bindPushRegistration(mocked);
    }

    return AppDependencies(
      config: config,
      session: session,
      launch: launch,
      intents: intents,
      appLock: appLock,
      apiClient: apiClient,
      cache: publicCache,
      network: network,
      telemetry: telemetry,
      authRepository: mock == null
          ? AuthApiRepository(
              apiClient: apiClient,
              identity: identity,
              telemetry: telemetry,
            )
          : MockAuthRepository(mock),
      deviceSessionRepository: mock == null
          ? SessionApiRepository(apiClient: apiClient)
          : MockDeviceSessionRepository(mock),
      platformRepository: platformRepository,
      platform: platform,
      serviceCatalogRepository: mock == null
          ? ServiceCatalogApiRepository(apiClient: apiClient)
          : MockServiceCatalogRepository(mock),
      programRepository: mock == null
          ? ProgramApiRepository(apiClient: apiClient)
          : MockProgramRepository(mock),
      socialServices: mock == null
          ? SocialServiceApiRepository(apiClient: apiClient)
          : MockSocialServiceRepository(mock),
      announcementRepository: mock == null
          ? NewsfeedApiRepository(apiClient: apiClient)
          : MockAnnouncementRepository(mock),
      eventRepository: mock == null
          ? EventApiRepository(apiClient: apiClient, telemetry: telemetry)
          : MockEventRepository(mock),
      // Live builds decline where the contract has no endpoint. A dev mock
      // build substitutes synthetic fixtures behind the same interfaces.
      residentProfileRepository: mock == null
          ? ResidentProfileApiRepository(apiClient: apiClient)
          : MockProfileRepository(mock),
      householdRepository: mock == null
          ? HouseholdApiRepository(apiClient: apiClient)
          : MockHouseholdRepository(mock),
      registrationRepository: mock == null
          ? PlannedRegistrationRepository(directory: barangayDirectory)
          : MockRegistrationRepository(mock, barangayDirectory),
      barangayDirectory: barangayDirectory,
      credentialRepository: mock == null
          ? CredentialApiRepository(apiClient: apiClient)
          : MockCredentialRepository(mock),
      verificationRepository: mock == null
          ? KycApiRepository(apiClient: apiClient, telemetry: telemetry)
          : MockVerificationRepository(mock),
      residentRecordRepository: mock == null
          ? ResidentRecordApiRepository(apiClient: apiClient)
          : MockResidentRecordRepository(mock),
      serviceRequestRepository: mock == null
          ? AssistanceApiRepository(apiClient: apiClient, telemetry: telemetry)
          : MockServiceRequestRepository(mock),
      requirementRepository: mock == null
          ? RequirementApiRepository(apiClient: apiClient, telemetry: telemetry)
          : MockRequirementRepository(mock),
      notificationRepository: notifications,
      // Defaults to the real system pickers. Tests inject
      // `UnavailableDocumentPicker`, which reports every source as absent
      // rather than pretending a camera opened.
      documentPicker: documentPicker ?? PlatformDocumentPicker(),
      // Defaults to the OS share sheet, which falls back to the clipboard on a
      // device that has none. Tests inject `UnavailableShareService`.
      shareService: shareService ?? const PlatformShareService(),
      // Defaults to the OS launcher, which refuses anything that is not https.
      // Tests inject `UnavailableExternalLinkService`.
      externalLinks: externalLinks ?? const PlatformExternalLinkService(),
      accountControlsRepository: mock == null
          ? PrivacyApiRepository(apiClient: apiClient)
          : MockAccountControlsRepository(mock),
      mockBehavior: mock,
      officeMessaging: mock == null
          ? OfficeMessagingApiRepository(apiClient: apiClient)
          : MockOfficeMessagingRepository(mock),
      issuance: mock == null
          ? IssuanceApiRepository(apiClient: apiClient)
          : MockIssuanceRepository(mock),
      sectors: mock == null
          ? SectorApiRepository(apiClient: apiClient)
          : MockSectorRepository(mock),
      passwordClient: mock == null
          ? const FirebaseAccountPasswordClient()
          : MockAccountPasswordClient(),
      onDispose: httpTransport is HttpApiTransport ? httpTransport.close : null,
    );
  }

  /// What the server said at startup: minimum supported version, feature flags,
  /// support contact — and, from a live `503`, whether it is in maintenance.
  ///
  /// Read by the route guard. Never blocks a first frame; see
  /// [PlatformController].
  final PlatformController platform;

  /// What the app calls "now".
  ///
  /// Injectable at the composition root rather than read from `DateTime.now`
  /// inside each controller. Two reasons, and only the second was foreseen:
  ///
  /// * A widget test that asserts a date-derived label — "Today", "Earlier this
  ///   week" — against a fixture pinned to a calendar date passes on the day it
  ///   is written and fails every day after. That is not hypothetical: the inbox
  ///   text-scale test began failing two days after it was committed, and the
  ///   release gate was red on arrival at this machine. The controller under it
  ///   already took a clock; nothing threaded one through the app, so the test
  ///   harness had no way to reach it.
  /// * Later work needs one seam rather than a habit. A registration window and
  ///   an event's capacity are decided by the server, not by a device clock a
  ///   resident can set (Master Command TAB 12), and "inject clocks everywhere"
  ///   is easier to hold as one field than as a rule people remember.
  ///
  /// Production never passes it, so the default is the real clock.
  final DateTime Function() clock;

  final AppConfig config;
  final SessionController session;

  /// First-launch state. Presentation only — it grants nothing.
  final LaunchController launch;

  /// The one action a resident was part-way through when a gate stopped them.
  final IntentController intents;

  /// Optional local unlock over an already-signed-in app. Device convenience
  /// only — it grants nothing and proves nothing to the server.
  final AppLockController appLock;

  /// Asks a signed-in resident to accept a Terms of Use or Privacy Notice
  /// version published after they last agreed. Built from [session],
  /// [platformRepository] and [accountControlsRepository] unless a test
  /// supplies one.
  final ConsentGateController consentGate;
  final ApiClient apiClient;
  final PublicCache cache;

  /// Whether Taytay LGU is reachable, inferred from the outcome of real
  /// requests rather than from a radio flag. See [NetworkMonitor].
  final NetworkMonitor network;

  /// Operational telemetry, off unless the resident agreed, the build permits
  /// it **and** a sink exists. The shipped build fails all three. See
  /// [Telemetry].
  final Telemetry telemetry;

  final AuthRepository authRepository;

  /// Listing and revoking other sessions. No endpoint exists yet; the shipped
  /// implementation declines rather than showing a fabricated device list.
  final DeviceSessionRepository deviceSessionRepository;
  final PlatformRepository platformRepository;
  final ServiceCatalogRepository serviceCatalogRepository;

  /// Assistance programmes. The Node contract has no programme resource.
  /// Tulong reads [socialServiceRepository] instead. This one still declines.
  final ProgramRepository programRepository;

  /// Published social services. `GET /services`. Public.
  final SocialServiceRepository socialServiceRepository;

  /// Public municipal content. Both endpoints are committed and `planned`, so
  /// both shipped implementations decline rather than inventing announcements
  /// or event dates in the LGU's name.
  final AnnouncementRepository announcementRepository;
  final EventRepository eventRepository;
  final ResidentProfileRepository residentProfileRepository;

  /// The resident's own household. `/me`-scoped and identifier-free: the only
  /// household route in the committed contract is staff-scoped, so this
  /// declines rather than reaching for it.
  final HouseholdRepository householdRepository;

  /// Citizen registration and identity verification submission.
  final RegistrationRepository registrationRepository;

  /// Taytay's barangays, as the server publishes them.
  ///
  /// Its own dependency rather than a method on one repository, because a KYC
  /// claim, a profile correction and a household address all need the list and
  /// none of them is registration. Exposed here so the KYC claim form can read
  /// it without going through a repository that declines everything else (F15).
  final BarangayDirectory barangayDirectory;
  final CredentialRepository credentialRepository;
  final VerificationRepository verificationRepository;

  /// The profile wizard's own record. Null only in tests that never open it.
  /// A dev mock build supplies [MockResidentRecordRepository]; every other
  /// build talks to `/me` and `/households/current`.
  final ResidentRecordRepository? residentRecordRepository;
  final ServiceRequestRepository serviceRequestRepository;

  /// The documents one request is waiting on, and their uploads. Same
  /// `ServiceDelivery` module as the requests themselves, and equally `planned`,
  /// so the shipped implementation declines rather than reporting that a
  /// barangay clearance reached the LGU when nothing left the phone.
  final RequirementRepository requirementRepository;

  final NotificationRepository notificationRepository;

  /// The device seam for choosing a document — camera, photo library, or the
  /// system file picker. An interface so the whole upload flow is testable
  /// without a platform channel.
  final DocumentPicker documentPicker;

  /// Passing **public** content to another app through the OS share sheet.
  /// Nothing personal is ever handed to it, and a device without a sheet
  /// degrades to copying rather than throwing.
  final ShareService shareService;

  /// Opening an `https` link the **server** supplied — a map for a municipal
  /// venue. Refuses every other scheme, so a mistaken or hostile payload cannot
  /// open a `javascript:`, `intent:` or `file:` URI.
  final ExternalLinkService externalLinks;

  /// What a resident may ask the office to do with their own account, and the
  /// consent history behind it. Every control defaults to unavailable: a
  /// deletion button on a government app is a statement about a civil record,
  /// and it is not this client's to make.
  final AccountControlsRepository accountControlsRepository;

  /// Resident-to-office messages. Live calls are the thread routes (F31 closed).
  /// A dev mock build supplies synthetic threads.
  final OfficeMessagingRepository officeMessagingRepository;

  /// Document requests: the public catalogue and the resident's own requests
  /// (`issuance-types`, `me/issuance-requests`). A dev mock build supplies
  /// synthetic offices and requests.
  final IssuanceRepository issuanceRepository;

  /// The resident's own non-sensitive sectors and sector applications
  /// (`me/sectors`, `me/sector-applications`, D-215). A dev mock build
  /// supplies synthetic ones.
  final SectorRepository sectorRepository;

  /// In-session password change. Firebase on a live build, a mock in dev.
  final AccountPasswordClient accountPasswordClient;

  /// Home, offices, and media on the Node contract.
  final NodeCitizenApi citizenApi;

  /// Public cover and hero bytes. The path is relative to [ApiClient].
  final MediaBytesApi mediaBytes;

  /// Latency and failure for dev mocks. Null on a live build.
  final MockBehaviorController? mockBehavior;

  /// Releases the transport's connection pool, when it owns one.
  final void Function()? onDispose;

  void dispose() {
    mockBehavior?.dispose();
    appLock.dispose();
    consentGate.dispose();
    session.dispose();
    launch.dispose();
    intents.dispose();
    network.dispose();
    telemetry.dispose();
    mediaBytes.clear();
    cache.clear();
    onDispose?.call();
  }

  /// Reads the dependencies provided above this widget.
  ///
  /// Throws when none are in scope: that is a wiring bug at development time,
  /// not a runtime condition worth degrading for.
  static AppDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    assert(scope != null, 'No AppDependenciesScope found above this widget.');
    return scope!.dependencies;
  }
}

/// Makes [AppDependencies] available to the widget tree.
class AppDependenciesScope extends InheritedWidget {
  const AppDependenciesScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final AppDependencies dependencies;

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) =>
      oldWidget.dependencies != dependencies;
}
