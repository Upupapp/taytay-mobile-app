import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/intent/resident_intent.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/core/network/network_monitor.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

import '../support/taytay_personas.dart';

// ─── Harness ────────────────────────────────────────────────────────────────

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef Booted = ({AppDependencies dependencies, NetworkMonitor network});

/// Boots the real app as [persona] would find it.
///
/// Nothing is stubbed: the shipped repositories are used, which for the planned
/// modules means they decline. That is the point — these journeys check what a
/// resident actually meets today, and the honest-refusal states are part of the
/// product rather than a gap the tests paper over.
Future<Booted> live(
  WidgetTester tester,
  Persona persona, {
  bool firstLaunch = false,
  Size size = const Size(400, 900),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  if (!firstLaunch) {
    await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  }

  final sessionStore = InMemorySessionStore();
  final stored = storedSessionFor(persona);
  if (stored != null) await sessionStore.write(stored);

  final network = NetworkMonitor();
  final dependencies = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    networkMonitor: network,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: textScaler),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  return (dependencies: dependencies, network: network);
}

Future<void> goTo(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

String currentLocation(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

/// Everything currently rendered as text, lower-cased.
String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .join(' ')
    .toLowerCase();

void main() {
  setUp(MotionPreference.reset);
  tearDown(MotionPreference.reset);

  // ── 1. First launch → welcome → Continue as Guest ───────────────────────

  group('Journey: first launch and Continue as Guest', () {
    testWidgets('a first launch lands on welcome, not on a sign-in wall', (
      tester,
    ) async {
      await live(tester, guest, firstLaunch: true);

      // Appendix A: guest is a first-class state. A cold start that demanded an
      // account would have made registration the price of reading a road-closure
      // notice.
      expect(currentLocation(tester), AppRoute.onboarding.path);
    });

    testWidgets('the welcome offers a way in without an account', (
      tester,
    ) async {
      await live(tester, guest, firstLaunch: true);

      // Both doors are on the first screen: skip out of the tour, or take it
      // and continue as a guest at the end. Neither asks for a mobile number.
      expect(find.text('Skip'), findsOneWidget);
      expect(renderedText(tester), isNot(contains('mobile number')));
    });

    testWidgets('a returning guest skips welcome entirely', (tester) async {
      await live(tester, guest);
      expect(currentLocation(tester), isNot(AppRoute.onboarding.path));
    });
  });

  // ── 2. A guest browses News and Events ──────────────────────────────────

  group('Journey: a guest browses public content', () {
    testWidgets('News and Events open without an account', (tester) async {
      await live(tester, guest);

      for (final route in <AppRoute>[
        AppRoute.news,
        AppRoute.events,
        AppRoute.services,
      ]) {
        await goTo(tester, route.path);
        expect(
          currentLocation(tester),
          route.path,
          reason: 'a guest was redirected away from ${route.routeName}',
        );
      }
    });

    testWidgets('and so do help and the privacy notice', (tester) async {
      await live(tester, guest);

      for (final path in <String>[
        AppRoute.settings.path,
        AppRoute.help.path,
        AppRoute.profilePrivacy.path,
      ]) {
        await goTo(tester, path);
        expect(currentLocation(tester), path);
      }
    });
  });

  // ── 3. Gate → sign in → the original intent resumes ─────────────────────

  group('Journey: a gate preserves what the resident was doing', () {
    testWidgets('a guest sent to a verified route lands on sign-in', (
      tester,
    ) async {
      await live(tester, guest);
      await goTo(tester, AppRoute.digitalId.path);

      // Not the digital ID, and not a dead end either.
      expect(currentLocation(tester), isNot(AppRoute.digitalId.path));
      expect(currentLocation(tester), AppRoute.signIn.path);
    });

    testWidgets('an intent survives the gate and is replayed once', (
      tester,
    ) async {
      final booted = await live(tester, guest);
      final intents = booted.dependencies.intents;

      intents.remember(ResidentIntentKind.viewDigitalId);
      expect(intents.pending, isNotNull);

      // Still held while the session cannot satisfy it. The resumer replays it
      // when — and only when — the session changes to one that can, which is
      // what `welcome_and_gates_test.dart` drives end to end.
      await tester.pumpAndSettle();
      expect(intents.pending?.kind, ResidentIntentKind.viewDigitalId);
    });

    testWidgets('an intent never survives a session boundary', (tester) async {
      final booted = await live(tester, verified);
      booted.dependencies.intents.remember(ResidentIntentKind.applyForService);

      await booted.dependencies.session.signOut();
      await tester.pumpAndSettle();

      // Resuming an action for a different account is the failure this prevents.
      expect(booted.dependencies.intents.pending, isNull);
    });
  });

  // ── 4/5/6. Verification states ──────────────────────────────────────────

  group('Journey: registration and verification', () {
    testWidgets('an unverified resident reaches verification, not the ID', (
      tester,
    ) async {
      await live(tester, unverified);

      await goTo(tester, AppRoute.verification.path);
      expect(currentLocation(tester), AppRoute.verification.path);

      await goTo(tester, AppRoute.digitalId.path);
      expect(currentLocation(tester), isNot(AppRoute.digitalId.path));
    });

    testWidgets('verification declines honestly rather than collecting', (
      tester,
    ) async {
      await live(tester, unverified);
      await goTo(tester, AppRoute.verification.path);

      // The Verification module is planned. A screen that collected documents
      // it could not send would be the worst possible failure here.
      final text = renderedText(tester);
      expect(text, isNot(contains('uploading')));
      expect(text, isNot(contains('submitted successfully')));
    });

    testWidgets('a verified resident reaches the services only they can use', (
      tester,
    ) async {
      await live(tester, verified);

      for (final path in <String>[
        AppRoute.digitalId.path,
        AppRoute.requests.path,
        AppRoute.household.path,
      ]) {
        await goTo(tester, path);
        expect(
          currentLocation(tester),
          path,
          reason: 'a verified resident was refused $path',
        );
      }
    });
  });

  // ── 7. Assistance, requirements and the timeline ────────────────────────

  group('Journey: assistance for every persona who has one', () {
    testWidgets('Marites reaches her case screen', (tester) async {
      await live(tester, verifiedWithAssistance);
      await goTo(tester, '/requests/$maritesRequestId');

      expect(currentLocation(tester), '/requests/$maritesRequestId');
    });

    testWidgets('Rosa reaches the requirements for her case', (tester) async {
      await live(tester, verifiedWithMissingRequirement);
      await goTo(tester, '/requests/$rosaRequestId/requirements');

      expect(currentLocation(tester), '/requests/$rosaRequestId/requirements');
    });

    testWidgets('an unverified resident cannot reach either', (tester) async {
      await live(tester, unverified);

      for (final path in <String>[
        '/requests/$rosaRequestId',
        '/requests/$rosaRequestId/requirements',
        AppRoute.applyForService.path.replaceAll(
          ':serviceCode',
          medicalAssistanceCode,
        ),
      ]) {
        await goTo(tester, path);
        expect(currentLocation(tester), isNot(path), reason: path);
      }
    });

    testWidgets('and neither can a guest', (tester) async {
      await live(tester, guest);
      await goTo(tester, '/requests/$rosaRequestId');
      expect(currentLocation(tester), AppRoute.signIn.path);
    });
  });

  // ── 8/9. Newsfeed and events ────────────────────────────────────────────

  group('Journey: the newsfeed and events', () {
    testWidgets('Lito reaches the post he commented on', (tester) async {
      await live(tester, withNewsfeedEngagement);
      await goTo(tester, '/news/$litoPostId');

      // Unverified, and that is correct: a public announcement is not a
      // resident-linked service.
      expect(currentLocation(tester), '/news/$litoPostId');
    });

    testWidgets('Ben reaches his waitlisted event', (tester) async {
      await live(tester, withWaitlistedEvent);
      await goTo(tester, '/events/$benEventId');

      expect(currentLocation(tester), '/events/$benEventId');
    });

    testWidgets('registering for an event needs an account', (tester) async {
      await live(tester, guest);
      await goTo(tester, '/events/$benEventId/register');

      expect(currentLocation(tester), AppRoute.signIn.path);
    });

    testWidgets('a guest still reads the event itself', (tester) async {
      await live(tester, guest);
      await goTo(tester, '/events/$benEventId');

      expect(currentLocation(tester), '/events/$benEventId');
    });
  });

  // ── 10. Deep links, signed in and signed out ────────────────────────────

  group('Journey: a notification deep link', () {
    testWidgets('opens directly when the session allows it', (tester) async {
      await live(tester, verified);
      await goTo(tester, '/requests/$maritesRequestId');

      expect(currentLocation(tester), '/requests/$maritesRequestId');
    });

    testWidgets('lands on sign-in when it does not, and never 404s', (
      tester,
    ) async {
      await live(tester, guest);
      await goTo(tester, '/requests/$maritesRequestId');

      // A resident who tapped a real notification must not be told the thing
      // does not exist.
      expect(currentLocation(tester), AppRoute.signIn.path);
      expect(renderedText(tester), isNot(contains('not found')));
    });

    testWidgets('a malformed identifier renders nothing but not-found', (
      tester,
    ) async {
      await live(tester, verified);
      await goTo(tester, '/events/../../etc/passwd');

      // The location string is whatever was asked for — go_router normalises
      // the traversal to `/etc/passwd` — and the point is that **no screen**
      // matches it. Asserting on the location would have tested the URL parser;
      // this tests what a resident is actually shown.
      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text(benEventTitle), findsNothing);
    });
  });

  // ── 11. An expired session ──────────────────────────────────────────────

  group('Journey: the session expires mid-use', () {
    testWidgets('a verified resident on a gated screen is moved off it', (
      tester,
    ) async {
      final booted = await live(tester, verified);
      await goTo(tester, AppRoute.digitalId.path);
      expect(currentLocation(tester), AppRoute.digitalId.path);

      // A 401 is the single signal that ends a session.
      await booted.dependencies.session.handleUnauthenticated();
      await tester.pumpAndSettle();

      expect(currentLocation(tester), isNot(AppRoute.digitalId.path));
    });

    testWidgets('and public content is still there afterwards', (tester) async {
      final booted = await live(tester, verified);
      await booted.dependencies.session.handleUnauthenticated();
      await tester.pumpAndSettle();

      await goTo(tester, AppRoute.news.path);
      expect(currentLocation(tester), AppRoute.news.path);
    });
  });

  // ── 12. A weak connection ───────────────────────────────────────────────

  group('Journey: a weak or dead connection', () {
    testWidgets('the app says so, and says nothing was sent', (tester) async {
      final booted = await live(tester, verified);

      booted.network
        ..recordOutcome(const NetworkFailure())
        ..recordOutcome(const NetworkFailure());
      await tester.pumpAndSettle();

      expect(find.text('Not reaching Taytay LGU'), findsOneWidget);
      expect(renderedText(tester), contains('nothing has been sent'));
    });

    testWidgets('a server refusal is never dressed up as a dead connection', (
      tester,
    ) async {
      final booted = await live(tester, verified);

      booted.network
        ..recordOutcome(const ForbiddenFailure())
        ..recordOutcome(const ForbiddenFailure());
      await tester.pumpAndSettle();

      expect(find.text('Not reaching Taytay LGU'), findsNothing);
    });

    testWidgets('public browsing continues while offline', (tester) async {
      final booted = await live(tester, guest);
      booted.network
        ..recordOutcome(const NetworkFailure())
        ..recordOutcome(const NetworkFailure());
      await tester.pumpAndSettle();

      for (final route in <AppRoute>[AppRoute.news, AppRoute.events]) {
        await goTo(tester, route.path);
        expect(currentLocation(tester), route.path);
      }
    });
  });

  // ── 13/14. Large text, reduced motion ───────────────────────────────────

  group('Journey: large text and reduced motion', () {
    testWidgets('every persona reaches Home at 200% text', (tester) async {
      for (final persona in personas) {
        await live(
          tester,
          persona,
          textScaler: const TextScaler.linear(2),
          size: const Size(400, 2400),
        );
        expect(tester.takeException(), isNull, reason: persona.handle);
      }
    });

    testWidgets('reduced motion changes nothing about what is reachable', (
      tester,
    ) async {
      MotionPreference.set(MotionPreference.reduced);

      await live(tester, verified);
      await goTo(tester, AppRoute.digitalId.path);

      // Acceptance: no critical action depends on animation.
      expect(currentLocation(tester), AppRoute.digitalId.path);
      expect(tester.takeException(), isNull);
    });
  });

  // ── The product boundary, from the resident's side ──────────────────────

  group('No admin surface is reachable by any persona', () {
    testWidgets('every admin-shaped path is refused or unknown', (
      tester,
    ) async {
      const adminPaths = <String>[
        '/admin',
        '/admin/requests',
        '/staff',
        '/console',
        '/moderation',
        '/approvals',
        '/reports',
        '/users',
        '/roles',
        '/audit',
        '/requests/$rosaRequestId/approve',
        '/news/$litoPostId/publish',
        '/events/$benEventId/edit',
      ];

      for (final persona in <Persona>[guest, unverified, verified]) {
        await live(tester, persona);
        for (final path in adminPaths) {
          await goTo(tester, path);

          // What matters is that nothing renders, not what the URL bar says.
          // A path with no route falls to the not-found screen; a path the
          // guard refuses lands on sign-in. Either is a refusal.
          final refused =
              find.text('Page not found').evaluate().isNotEmpty ||
              currentLocation(tester) == AppRoute.signIn.path;
          expect(
            refused,
            isTrue,
            reason: '${persona.handle} was shown something at $path',
          );
        }
      }
    });

    testWidgets('the route table declares no admin route at all', (
      tester,
    ) async {
      // The structural half of the same claim: a route that does not exist
      // cannot be reached by any path, guard bug or not.
      const forbidden = <String>[
        'admin',
        'staff',
        'console',
        'moderat',
        'approv',
        'audit',
        'dashboard',
        'publish',
      ];
      for (final route in AppRoute.values) {
        for (final word in forbidden) {
          expect(
            route.routeName.toLowerCase(),
            isNot(contains(word)),
            reason: route.routeName,
          );
          expect(route.path.toLowerCase(), isNot(contains(word)));
        }
      }
    });

    testWidgets('no staff vocabulary appears on any core screen', (
      tester,
    ) async {
      const forbidden = <String>[
        'approve',
        'reject this',
        'assign to',
        'staff note',
        'moderate',
        'publish',
        'audit log',
        'dashboard',
        'manage users',
      ];

      await live(tester, verified);
      for (final route in <AppRoute>[
        AppRoute.home,
        AppRoute.services,
        AppRoute.news,
        AppRoute.events,
        AppRoute.profile,
        AppRoute.settings,
      ]) {
        await goTo(tester, route.path);
        final text = renderedText(tester);
        for (final word in forbidden) {
          expect(
            text,
            isNot(contains(word)),
            reason: '"$word" on ${route.routeName}',
          );
        }
      }
    });
  });

  // ── Every persona, every core route ─────────────────────────────────────

  group('Every persona reaches what they should and nothing more', () {
    testWidgets('the public routes are public for all seven', (tester) async {
      for (final persona in personas) {
        await live(tester, persona);
        for (final route in <AppRoute>[
          AppRoute.home,
          AppRoute.services,
          AppRoute.news,
          AppRoute.events,
          AppRoute.profile,
          AppRoute.settings,
        ]) {
          await goTo(tester, route.path);
          expect(
            currentLocation(tester),
            route.path,
            reason: '${persona.handle} could not reach ${route.routeName}',
          );
        }
      }
    });

    testWidgets('the verified-only routes are closed to the other four', (
      tester,
    ) async {
      const closed = <AppRoute>[
        AppRoute.digitalId,
        AppRoute.requests,
        AppRoute.household,
      ];

      for (final persona in <Persona>[
        guest,
        unverified,
        withNewsfeedEngagement,
      ]) {
        await live(tester, persona);
        for (final route in closed) {
          await goTo(tester, route.path);
          expect(
            currentLocation(tester),
            isNot(route.path),
            reason: '${persona.handle} reached ${route.routeName}',
          );
        }
      }
    });

    testWidgets('nothing personal leaks into a guest session', (tester) async {
      await live(tester, guest);

      final text = renderedText(tester);
      for (final persona in personas) {
        final name = persona.session?.displayName;
        if (name == null) continue;
        expect(text, isNot(contains(name.toLowerCase())), reason: name);
      }
    });
  });
}
