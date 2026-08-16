import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/design/app_theme.dart';
import '../core/design/design_tokens.dart';
import '../core/l10n/app_locales.dart';
import '../core/router/app_router.dart';
import '../core/telemetry/telemetry_route_observer.dart';
import '../features/auth/presentation/app_lock_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/session_expired_sheet.dart';
import 'app_dependencies.dart';

/// Application root.
///
/// Owns exactly three things: the dependency scope, the themes, and the router.
/// Anything else that appears here is a responsibility that has escaped a
/// feature.
class TaytayResidentApp extends StatefulWidget {
  const TaytayResidentApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<TaytayResidentApp> createState() => _TaytayResidentAppState();
}

class _TaytayResidentAppState extends State<TaytayResidentApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter _router = buildAppRouter(
    observers: <NavigatorObserver>[
      TelemetryRouteObserver(widget.dependencies.telemetry),
    ],
    session: widget.dependencies.session,
    launch: widget.dependencies.launch,
    navigatorKey: _navigatorKey,
  );

  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();

    // Reads the app-lock preference and asks the platform what it can do. Until
    // it completes the lock reports "off", which is the right default: a lock
    // that has not been confirmed to exist must not hide the app.
    unawaited(widget.dependencies.appLock.load());

    _lifecycle = AppLifecycleListener(
      // Leaving the foreground is the moment the phone might change hands.
      onHide: widget.dependencies.appLock.markBackgrounded,
      onPause: widget.dependencies.appLock.markBackgrounded,
      // Coming back is the moment to notice a token whose own `expires_at` has
      // passed, rather than letting the resident open a screen that can only
      // fail. Fails safe: it can end a session, never extend one.
      onResume: () =>
          unawaited(widget.dependencies.session.endSessionIfTokenExpired()),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.dependencies.config;

    if (!config.isUsable) {
      // A build whose API target is wrong must fail loudly here rather than
      // quietly talk to the wrong environment. See AppConfig.
      return _MisconfiguredApp(config: config);
    }

    return AppDependenciesScope(
      dependencies: widget.dependencies,
      child: MaterialApp.router(
        title: 'Taytay LGU IDS',
        debugShowCheckedModeBanner: false,

        // Both app copy and Material's own widget strings. Without the second,
        // a Filipino build would show translated content inside untranslated
        // chrome — a date picker and a "Back" button still in English.
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppLocales.supported,
        // The device's preference decides, matched on the language subtag so
        // `fil_PH` resolves to Filipino rather than falling through to English
        // on a region mismatch. There is no in-app switcher: a resident who has
        // told their phone they read Filipino has already answered.
        localeResolutionCallback: AppLocales.resolve,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        // Follows the OS setting. Dark mode is an accessibility feature for
        // light-sensitive residents, not a preference toggle to postpone.
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          // Order matters. The lock is innermost so it covers the router's
          // output on every route including a cold-start deep link; the expiry
          // watcher is outside it so it survives route changes, and shows its
          // sheet against the router's own navigator.
          final app = AppTheme.applyAccessibilityMediaQuery(
            context: context,
            child: SessionExpiryWatcher(
              session: widget.dependencies.session,
              navigatorKey: _navigatorKey,
              child: _AppLockGate(
                dependencies: widget.dependencies,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
          return config.environment.allowsDiagnosticsUi
              ? _EnvironmentBanner(
                  label: config.environment.badgeLabel,
                  child: app,
                )
              : app;
        },
      ),
    );
  }
}

/// Replaces the app's content with the lock screen while the local lock is
/// unsatisfied.
///
/// It *replaces* rather than overlays, so the content underneath is not built
/// and cannot appear in the OS task switcher's screenshot, which is the very
/// place a locked app most often leaks what it was showing.
class _AppLockGate extends StatelessWidget {
  const _AppLockGate({required this.dependencies, required this.child});

  final AppDependencies dependencies;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lock = dependencies.appLock;
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        if (!lock.isLocked) return child;
        return AppLockScreen(
          lock: lock,
          onUnlock: lock.unlock,
          onSignOut: () async {
            // Sign-out is the escape hatch, so it must not depend on the
            // network: the local session is cleared regardless of what the
            // server-side revocation returns.
            await dependencies.authRepository.signOut();
            await dependencies.session.signOut();
          },
        );
      },
    );
  }
}

/// Corner ribbon shown in non-production builds only.
///
/// Its purpose is to stop a staging build being mistaken for the real thing
/// during LGU acceptance testing — the moment when someone enters real personal
/// data into the wrong environment.
class _EnvironmentBanner extends StatelessWidget {
  const _EnvironmentBanner({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Banner(
      message: label,
      location: BannerLocation.topEnd,
      color: BrandColors.warning,
      child: child,
    );
  }
}

/// Shown when configuration is unusable. Deliberately dependency-free: it must
/// render even when nothing else was built.
class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.settings_suggest_outlined, size: 48),
                const SizedBox(height: Spacing.lg),
                const Text(
                  'This build is not configured correctly and cannot start.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Spacing.lg),
                for (final issue in config.issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Text('• ${issue.message}'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
