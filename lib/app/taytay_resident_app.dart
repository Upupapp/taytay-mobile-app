import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/design/app_theme.dart';
import '../core/design/design_tokens.dart';
import '../core/router/app_router.dart';
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
  late final GoRouter _router = buildAppRouter(
    session: widget.dependencies.session,
    launch: widget.dependencies.launch,
  );

  @override
  void dispose() {
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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        // Follows the OS setting. Dark mode is an accessibility feature for
        // light-sensitive residents, not a preference toggle to postpone.
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          final app = AppTheme.applyAccessibilityMediaQuery(
            context: context,
            child: child ?? const SizedBox.shrink(),
          );
          return config.environment.allowsDiagnosticsUi
              ? _EnvironmentBanner(label: config.environment.badgeLabel, child: app)
              : app;
        },
      ),
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
