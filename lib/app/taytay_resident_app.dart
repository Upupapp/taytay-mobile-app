import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/config/app_environment.dart';
import '../core/design/app_theme.dart';
import '../core/design/design_tokens.dart';
import '../core/design/taytay_icons.dart';
import '../core/l10n/app_locales.dart';
import '../core/router/app_router.dart';
import '../core/telemetry/telemetry_route_observer.dart';
import '../features/auth/presentation/app_lock_screen.dart';
import '../l10n/app_localizations.dart';
import '../shared/widgets/session_expired_sheet.dart';
import '../shared/widgets/taytay_icon.dart';
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

  /// Null until the first usable frame. Dispose must not force this into
  /// existence: a misconfigured build renders [_MisconfiguredApp] with no
  /// router, and reading a `late` field here would build one on the way out.
  GoRouter? _router;

  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();

    // The stop screen is the whole app when configuration cannot start.
    // A lock read or a bootstrap request would do the work that screen
    // exists to prevent.
    if (widget.dependencies.config.isUsable) {
      // Reads the app-lock preference and asks the platform what it can do.
      // Until it completes the lock reports "off", which is the right default:
      // a lock that has not been confirmed to exist must not hide the app.
      unawaited(widget.dependencies.appLock.load());

      // Asks the server what it expects of this build: minimum supported
      // version, feature flags, support contact.
      //
      // FIRED, NOT AWAITED. Nothing here draws a frame, and nothing waits on
      // it. Startup must not sit on the network — a resident on a weak
      // connection gets the app, and a request that never answers leaves the
      // permissive defaults in place rather than a spinner or a lock-out.
      unawaited(widget.dependencies.platform.refresh());
    }

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

  GoRouter _buildRouter() {
    return buildAppRouter(
      observers: <NavigatorObserver>[
        TelemetryRouteObserver(widget.dependencies.telemetry),
      ],
      session: widget.dependencies.session,
      launch: widget.dependencies.launch,
      platform: widget.dependencies.platform,
      navigatorKey: _navigatorKey,
      allowDevRoutes:
          widget.dependencies.config.environment == AppEnvironment.dev,
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _router?.dispose();
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
        // Decision D9: the mockups are light, and the dark scheme is a later
        // pass. The dark ThemeData stays built so contrast tests can see it.
        // The running app does not follow the OS into dark until that pass.
        themeMode: AppTheme.themeMode,
        routerConfig: _router ??= _buildRouter(),
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

/// Shown when configuration is unusable.
///
/// Theme, type, and one Lucide glyph. No session, router, or repository: it
/// has to render when nothing else was built. Material Icons are not bundled,
/// so the mark is [TaytayIcons.settings].
class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - Spacing.xl * 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _ConfigStopBanner(issues: config.issues),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Error-banner treatment: error container, on-error ink, the banner radius,
/// and the theme's title and body roles. The glyph is Lucide, not a Material
/// icon.
class _ConfigStopBanner extends StatelessWidget {
  const _ConfigStopBanner({required this.issues});

  final List<ConfigIssue> issues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onErrorContainer;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: foreground.withValues(alpha: 0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TaytayIcon(
              icon: TaytayIcons.settings,
              semanticLabel: 'Configuration',
              size: IconSizes.md,
              color: foreground,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'This build is not configured correctly and cannot start.',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                  for (final issue in issues) ...<Widget>[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      issue.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
