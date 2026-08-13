import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_dependencies.dart';

/// Resumes what a resident was doing, once the session can support it.
///
/// ---
///
/// **Where the resumption rule is actually enforced.** This widget does not
/// decide anything: it asks `IntentController.takeIfSatisfied`, which evaluates
/// the *current* session against the intent's requirement using the same
/// `AccessPolicy` the router uses. If the session still does not meet the gate —
/// a resident who signed in but is not yet verified — the intent stays held and
/// nothing happens. It cannot resume early, and passing through a gate does not
/// make the action permitted: the server authorises whatever request follows.
///
/// **Resumption is a navigation, not an action.** The resumer never performs the
/// thing the resident was trying to do. It takes them to the screen where they
/// can do it, or — for intents whose screens are not built yet — confirms that
/// they now can. Silently completing an action minutes after someone tapped a
/// button, on the other side of a sign-in flow, is not a thing an app should do
/// on a resident's behalf.
///
/// Wrap it around a screen that is reachable after a gate, typically the home
/// screen.
class IntentResumer extends StatefulWidget {
  const IntentResumer({required this.child, super.key});

  final Widget child;

  @override
  State<IntentResumer> createState() => _IntentResumerState();
}

class _IntentResumerState extends State<IntentResumer> {
  AppDependencies? _dependencies;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppDependencies.of(context);
    if (identical(dependencies, _dependencies)) return;

    _dependencies?.session.removeListener(_tryResume);
    _dependencies = dependencies..session.addListener(_tryResume);

    // A resident may arrive here already satisfying the gate — for example by
    // resuming a session that was restored after the intent was recorded.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryResume());
  }

  @override
  void dispose() {
    _dependencies?.session.removeListener(_tryResume);
    super.dispose();
  }

  void _tryResume() {
    if (!mounted) return;
    final dependencies = _dependencies;
    if (dependencies == null) return;

    final intent = dependencies.intents.takeIfSatisfied(
      dependencies.session.state,
    );
    if (intent == null) return;

    final destination = intent.kind.destination;
    if (destination != null) {
      GoRouter.of(context).goNamed(destination.routeName);
      return;
    }

    // No screen for this intent yet. Confirm rather than navigate, so the
    // resident learns the gate is behind them.
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('You can now ${intent.kind.description}.')),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
