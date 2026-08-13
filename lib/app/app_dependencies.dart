import 'package:flutter/widgets.dart';

import '../core/api/api_client.dart';
import '../core/api/api_transport.dart';
import '../core/config/app_config.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_store.dart';
import '../features/auth/data/pending_backend_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/platform/data/platform_api_repository.dart';
import '../features/platform/domain/platform_repository.dart';

/// The composition root: every long-lived object the app needs, built once.
///
/// Wiring lives here rather than in service locators or globals so that a test
/// can construct the whole app with a fake transport and a fake session store
/// and nothing else has to know. A feature never reaches for a singleton — it
/// receives what it needs from [AppDependencies.of].
class AppDependencies {
  AppDependencies({
    required this.config,
    required this.session,
    required this.apiClient,
    required this.authRepository,
    required this.platformRepository,
  });

  /// Builds the production graph.
  ///
  /// [transport] and [sessionStore] are injectable because those two are the
  /// app's only contact with the outside world.
  factory AppDependencies.build({
    required AppConfig config,
    ApiTransport? transport,
    SessionStore? sessionStore,
  }) {
    final session = SessionController(
      store: sessionStore ?? InMemorySessionStore(),
    );
    final apiClient = ApiClient(
      config: config,
      transport: transport ?? const UnconfiguredApiTransport(),
      accessTokenProvider: session.currentAccessToken,
      // A 401 anywhere in the app ends the session exactly once, here, rather
      // than being handled (or forgotten) at each call site.
      onUnauthenticated: session.handleUnauthenticated,
    );
    return AppDependencies(
      config: config,
      session: session,
      apiClient: apiClient,
      authRepository: const PendingBackendAuthRepository(),
      platformRepository: PlatformApiRepository(apiClient: apiClient),
    );
  }

  final AppConfig config;
  final SessionController session;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final PlatformRepository platformRepository;

  void dispose() => session.dispose();

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
