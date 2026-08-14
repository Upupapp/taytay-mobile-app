import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_level.dart';
import '../../../core/session/session_state.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/home_hero.dart';
import '../../../shared/widgets/next_action_card.dart';
import '../domain/home_emphasis.dart';
import 'home_sections.dart';

/// Home: what a resident can do right now, in the order that matters to them.
///
/// ---
///
/// **One Taytay identity, three emphases.** The hero, the catalogue, the
/// announcements and the events are the same for everyone, in the same order.
/// What changes is the single next-action card near the top, and — for a
/// verified resident — a summary of their own requests above the public
/// content, because what the LGU needs *from them* outranks what the LGU is
/// telling everyone.
///
/// **Not a dashboard.** There are no counts, no progress rings and no
/// percentages anywhere on this screen. This app has no authoritative source for
/// "3 pending" or "60% complete", and a fabricated figure on a government
/// service is worse than an absent one. Every card describes a state and a step.
///
/// **A guest's Home issues no `/me/` request.** The personal sections are chosen
/// by `HomeEmphasis`, and every read is additionally gated on
/// `CapabilityService` — the same evaluation the router and every tile use. A
/// guest therefore has nothing personal to leak into a screenshot, a log or a
/// cache, because nothing personal was ever fetched (acceptance 3).
///
/// **Missing content is absent, not apologetic.** Unlike a destination screen —
/// where the resident navigated deliberately and deserves an explanation — an
/// unavailable section on Home simply does not render. A summary screen that is
/// mostly "not available yet" answers acceptance 1 with a shrug. What never
/// disappears is the hero, the catalogue and the municipal hall, so Home is
/// always worth opening.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);

    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        final session = dependencies.session.state;
        final emphasis = HomeEmphasis.forLevel(session.accessLevel);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Taytay LGU IDS'),
            actions: <Widget>[
              IconButton(
                onPressed: () => context.goNamed(AppRoute.profile.routeName),
                icon: const Icon(Icons.account_circle_outlined),
                tooltip: 'Profile',
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[
                for (final section in emphasis.sections) ...<Widget>[
                  _build(context, session, section),
                  const SizedBox(height: Spacing.xl),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _build(
    BuildContext context,
    SessionState session,
    HomeSection section,
  ) => switch (section) {
    HomeSection.hero => _Hero(session: session),
    HomeSection.nextAction => _NextAction(session: session),
    HomeSection.news => const HomeNewsSection(),
    HomeSection.events => const HomeEventsSection(),
    HomeSection.services => const HomeServicesSection(),
    HomeSection.requests => const HomeRequestsSection(),
    HomeSection.municipalHall => const HomeMunicipalHallSection(),
  };
}

/// The banner. The only place a resident's name appears on Home.
class _Hero extends StatelessWidget {
  const _Hero({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    // First name only, and only when the server supplied one. Data
    // minimisation: the session holds a greeting name and nothing else, so
    // there is nothing more here to show even by mistake.
    final name = session.residentOrNull?.displayName;

    return HomeHero(
      title: name == null ? 'Kumusta!' : 'Kumusta, $name!',
      subtitle: switch (session.accessLevel) {
        AccessLevel.guest =>
          'Municipal services, announcements and events for Taytay, Rizal. '
              'Browse freely — no account needed.',
        AccessLevel.unverified =>
          'Your Taytay LGU account is set up. One step left to unlock your '
              'digital ID and service applications.',
        AccessLevel.verified =>
          'You are a verified Taytay resident. Everything in this app is open '
              'to you.',
      },
      // A switch rather than an equality test: exhaustive over the level, so a
      // new access level cannot silently fall into the wrong branch.
      action: switch (session.accessLevel) {
        AccessLevel.guest => AppButton(
          label: 'Sign in',
          variant: AppButtonVariant.secondary,
          fullWidth: false,
          onPressed: () => context.goNamed(AppRoute.signIn.routeName),
        ),
        AccessLevel.unverified || AccessLevel.verified => null,
      },
    );
  }
}

/// The single "what can I do now?" card.
///
/// For a guest it is written entirely from fixed copy — it reads nothing, so
/// there is nothing to disclose. For a signed-in resident it reflects the
/// verification status the server reports.
///
/// **Non-coercive by design.** The guest card describes what an account is for
/// and leaves; it does not interrupt, does not appear as a modal, does not
/// repeat, and is not required to reach anything else on the screen. A
/// government service that nags is a government service people stop opening.
class _NextAction extends StatelessWidget {
  const _NextAction({required this.session});

  final SessionState session;

  @override
  Widget build(BuildContext context) {
    return switch (session.accessLevel) {
      AccessLevel.guest => NextActionCard(
        tone: NextActionTone.invitation,
        title: 'Your Taytay ID, on your phone',
        body:
            'With a Taytay LGU account you can hold your digital ID and apply '
            'for municipal services. Signing in takes a mobile number and a '
            'one-time code — no password to remember.',
        primaryAction: AppButton(
          label: 'Sign in',
          fullWidth: false,
          onPressed: () => context.goNamed(AppRoute.signIn.routeName),
        ),
        secondaryAction: TextButton(
          onPressed: () => context.goNamed(AppRoute.services.routeName),
          child: const Text('Just browsing'),
        ),
      ),
      // Gated on the central service, so this card cannot appear for a session
      // that could not open the screen it points at.
      AccessLevel.unverified ||
      AccessLevel.verified => const HomeVerificationSection(),
    };
  }
}
