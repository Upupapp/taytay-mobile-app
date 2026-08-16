import 'package:flutter/widgets.dart';

import '../core/api/api_client.dart';
import '../core/api/api_transport.dart';
import '../core/api/auth_coordinator.dart';
import '../core/api/http_api_transport.dart';
import '../core/config/app_config.dart';
import '../core/documents/document_capture.dart';
import '../core/documents/platform_document_picker.dart';
import '../core/intent/intent_controller.dart';
import '../core/links/external_link_service.dart';
import '../core/links/platform_external_link_service.dart';
import '../core/network/network_monitor.dart';
import '../core/session/app_lock_controller.dart';
import '../core/session/local_authenticator.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_store.dart';
import '../core/sharing/platform_share_service.dart';
import '../core/sharing/share_service.dart';
import '../core/startup/launch_controller.dart';
import '../core/storage/keystore_session_store.dart';
import '../core/storage/public_cache.dart';
import '../core/storage/secure_secret_store.dart';
import '../features/auth/data/pending_backend_auth_repository.dart';
import '../features/auth/data/planned_device_session_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/device_session_repository.dart';
import '../features/credential/data/planned_credential_repository.dart';
import '../features/credential/domain/credential_repository.dart';
import '../features/events/data/planned_event_repository.dart';
import '../features/events/domain/event_repository.dart';
import '../features/household/data/planned_household_repository.dart';
import '../features/household/domain/household_repository.dart';
import '../features/news/data/planned_announcement_repository.dart';
import '../features/news/domain/announcement_repository.dart';
import '../features/notifications/data/planned_notification_repository.dart';
import '../features/notifications/domain/notification_repository.dart';
import '../features/platform/data/platform_api_repository.dart';
import '../features/platform/domain/platform_repository.dart';
import '../features/profile/data/planned_resident_profile_repository.dart';
import '../features/profile/domain/resident_profile_repository.dart';
import '../features/programs/data/planned_program_repository.dart';
import '../features/programs/domain/program_repository.dart';
import '../features/registration/data/planned_registration_repository.dart';
import '../features/registration/domain/registration_domain.dart';
import '../features/requirements/data/planned_requirement_repository.dart';
import '../features/requirements/domain/resident_requirement.dart';
import '../features/services/data/planned_service_request_repository.dart';
import '../features/services/data/service_catalog_api_repository.dart';
import '../features/services/domain/service_catalog_repository.dart';
import '../features/services/domain/service_request_repository.dart';
import '../features/settings/data/planned_account_controls_repository.dart';
import '../features/settings/domain/account_controls.dart';
import '../features/verification/data/planned_verification_repository.dart';
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
    required this.credentialRepository,
    required this.verificationRepository,
    required this.serviceRequestRepository,
    required this.requirementRepository,
    required this.notificationRepository,
    required this.documentPicker,
    required this.shareService,
    required this.externalLinks,
    required this.accountControlsRepository,
    this.onDispose,
  });

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
    LocalAuthenticator? localAuthenticator,
    DocumentPicker? documentPicker,
    ShareService? shareService,
    ExternalLinkService? externalLinks,
  }) {
    final secretStore = secrets ?? KeystoreSecretStore();
    final store = sessionStore ?? KeystoreSessionStore(secrets: secretStore);
    final publicCache = cache ?? PublicCache();
    final network = networkMonitor ?? NetworkMonitor();
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

    // Fail closed: with no refresher registered — and the committed backend
    // publishes no refresh endpoint — a 401 ends the session rather than being
    // retried or ignored.
    final authCoordinator = AuthCoordinator(
      onSessionInvalidated: () async {
        await session.handleUnauthenticated();
        // A held intent must never survive a session boundary: resuming an
        // action for a different account is the failure this prevents.
        intents.onSessionChanged();
        // Nothing personal is in the public cache by construction, but a
        // resident handing the phone back should not see the previous session's
        // screens repopulate from memory.
        publicCache.clear();
      },
    );

    final httpTransport = transport ?? HttpApiTransport(config: config);

    final apiClient = ApiClient(
      config: config,
      transport: httpTransport,
      accessTokenProvider: session.currentAccessToken,
      onUnauthenticated: session.handleUnauthenticated,
      authCoordinator: authCoordinator,
      cache: publicCache,
      networkMonitor: network,
    );

    return AppDependencies(
      config: config,
      session: session,
      launch: launch,
      intents: intents,
      appLock: appLock,
      apiClient: apiClient,
      cache: publicCache,
      network: network,
      authRepository: const PendingBackendAuthRepository(),
      deviceSessionRepository: const PlannedDeviceSessionRepository(),
      platformRepository: PlatformApiRepository(apiClient: apiClient),
      serviceCatalogRepository: ServiceCatalogApiRepository(
        apiClient: apiClient,
      ),
      programRepository: const PlannedProgramRepository(),
      announcementRepository: const PlannedAnnouncementRepository(),
      eventRepository: const PlannedEventRepository(),
      // Backed by modules the committed boundary map lists as planned. Each
      // declines honestly rather than mocking a response.
      residentProfileRepository: const PlannedResidentProfileRepository(),
      householdRepository: const PlannedHouseholdRepository(),
      registrationRepository: const PlannedRegistrationRepository(),
      credentialRepository: const PlannedCredentialRepository(),
      verificationRepository: const PlannedVerificationRepository(),
      serviceRequestRepository: const PlannedServiceRequestRepository(),
      requirementRepository: const PlannedRequirementRepository(),
      notificationRepository: const PlannedNotificationRepository(),
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
      accountControlsRepository: const PlannedAccountControlsRepository(),
      onDispose: httpTransport is HttpApiTransport ? httpTransport.close : null,
    );
  }

  final AppConfig config;
  final SessionController session;

  /// First-launch state. Presentation only — it grants nothing.
  final LaunchController launch;

  /// The one action a resident was part-way through when a gate stopped them.
  final IntentController intents;

  /// Optional local unlock over an already-signed-in app. Device convenience
  /// only — it grants nothing and proves nothing to the server.
  final AppLockController appLock;
  final ApiClient apiClient;
  final PublicCache cache;

  /// Whether Taytay LGU is reachable, inferred from the outcome of real
  /// requests rather than from a radio flag. See [NetworkMonitor].
  final NetworkMonitor network;

  final AuthRepository authRepository;

  /// Listing and revoking other sessions. No endpoint exists yet; the shipped
  /// implementation declines rather than showing a fabricated device list.
  final DeviceSessionRepository deviceSessionRepository;
  final PlatformRepository platformRepository;
  final ServiceCatalogRepository serviceCatalogRepository;

  /// Assistance programmes, in the citizen projection. Bearer-authenticated by
  /// contract, and `planned`, so the shipped implementation declines rather than
  /// inventing an offer of public money in the LGU's name.
  final ProgramRepository programRepository;

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
  final CredentialRepository credentialRepository;
  final VerificationRepository verificationRepository;
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

  /// Releases the transport's connection pool, when it owns one.
  final void Function()? onDispose;

  void dispose() {
    appLock.dispose();
    session.dispose();
    launch.dispose();
    intents.dispose();
    network.dispose();
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
