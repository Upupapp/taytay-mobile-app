import 'package:flutter/widgets.dart';

import '../core/api/api_client.dart';
import '../core/api/api_transport.dart';
import '../core/api/auth_coordinator.dart';
import '../core/api/http_api_transport.dart';
import '../core/config/app_config.dart';
import '../core/intent/intent_controller.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_store.dart';
import '../core/startup/launch_controller.dart';
import '../core/storage/keystore_session_store.dart';
import '../core/storage/public_cache.dart';
import '../core/storage/secure_secret_store.dart';
import '../features/auth/data/pending_backend_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/credential/data/planned_credential_repository.dart';
import '../features/credential/domain/credential_repository.dart';
import '../features/notifications/data/planned_notification_repository.dart';
import '../features/notifications/domain/notification_repository.dart';
import '../features/platform/data/platform_api_repository.dart';
import '../features/platform/domain/platform_repository.dart';
import '../features/profile/data/planned_resident_profile_repository.dart';
import '../features/profile/domain/resident_profile_repository.dart';
import '../features/registration/data/planned_registration_repository.dart';
import '../features/registration/domain/registration_domain.dart';
import '../features/services/data/planned_service_request_repository.dart';
import '../features/services/data/service_catalog_api_repository.dart';
import '../features/services/domain/service_catalog_repository.dart';
import '../features/services/domain/service_request_repository.dart';
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
    required this.apiClient,
    required this.cache,
    required this.authRepository,
    required this.platformRepository,
    required this.serviceCatalogRepository,
    required this.residentProfileRepository,
    required this.registrationRepository,
    required this.credentialRepository,
    required this.verificationRepository,
    required this.serviceRequestRepository,
    required this.notificationRepository,
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
  }) {
    final secretStore = secrets ?? KeystoreSecretStore();
    final store = sessionStore ?? KeystoreSessionStore(secrets: secretStore);
    final publicCache = cache ?? PublicCache();
    final session = SessionController(store: store);
    final launch = LaunchController(secrets: secretStore);
    final intents = IntentController();

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
    );

    return AppDependencies(
      config: config,
      session: session,
      launch: launch,
      intents: intents,
      apiClient: apiClient,
      cache: publicCache,
      authRepository: const PendingBackendAuthRepository(),
      platformRepository: PlatformApiRepository(apiClient: apiClient),
      serviceCatalogRepository: ServiceCatalogApiRepository(
        apiClient: apiClient,
      ),
      // Backed by modules the committed boundary map lists as planned. Each
      // declines honestly rather than mocking a response.
      residentProfileRepository: const PlannedResidentProfileRepository(),
      registrationRepository: const PlannedRegistrationRepository(),
      credentialRepository: const PlannedCredentialRepository(),
      verificationRepository: const PlannedVerificationRepository(),
      serviceRequestRepository: const PlannedServiceRequestRepository(),
      notificationRepository: const PlannedNotificationRepository(),
      onDispose: httpTransport is HttpApiTransport ? httpTransport.close : null,
    );
  }

  final AppConfig config;
  final SessionController session;

  /// First-launch state. Presentation only — it grants nothing.
  final LaunchController launch;

  /// The one action a resident was part-way through when a gate stopped them.
  final IntentController intents;
  final ApiClient apiClient;
  final PublicCache cache;

  final AuthRepository authRepository;
  final PlatformRepository platformRepository;
  final ServiceCatalogRepository serviceCatalogRepository;
  final ResidentProfileRepository residentProfileRepository;

  /// Citizen registration and identity verification submission.
  final RegistrationRepository registrationRepository;
  final CredentialRepository credentialRepository;
  final VerificationRepository verificationRepository;
  final ServiceRequestRepository serviceRequestRepository;
  final NotificationRepository notificationRepository;

  /// Releases the transport's connection pool, when it owns one.
  final void Function()? onDispose;

  void dispose() {
    session.dispose();
    launch.dispose();
    intents.dispose();
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
