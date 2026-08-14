import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/shell/presentation/shell_destinations.dart';

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Boots the app at a chosen surface size and access level.
Future<AppDependencies> boot(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  Size size = const Size(400, 900),
  String? initialLocation,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final sessionStore = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await sessionStore.write(
      StoredSession(
        resident: ResidentSession(accountId: 'acct-1', accessLevel: level),
        accessToken: 'token',
      ),
    );
  }

  final dependencies = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
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

  if (initialLocation != null) {
    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go(initialLocation);
    await tester.pumpAndSettle();
  }
  return dependencies;
}

Future<void> tapDestination(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('the bottom navigation is simple and stable — acceptance 3', () {
    for (final level in AccessLevel.values) {
      testWidgets('a ${level.name} sees the same five destinations', (
        tester,
      ) async {
        await boot(tester, level: level);

        expect(find.byType(NavigationBar), findsOneWidget);
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.destinations, hasLength(5));

        for (final destination in ShellDestination.values) {
          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(destination.label),
            ),
            findsOneWidget,
            reason: '${destination.label} for ${level.name}',
          );
        }
      });
    }

    testWidgets('no destination is added or hidden by verification', (
      tester,
    ) async {
      final dependencies = await boot(tester, level: AccessLevel.unverified);
      final before = tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .destinations
          .length;

      dependencies.session.applyVerificationTier('verified');
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .destinations
            .length,
        before,
      );
    });

    testWidgets('no admin or staff entry appears anywhere in the shell', (
      tester,
    ) async {
      await boot(tester, level: AccessLevel.verified);
      for (final word in <String>['Admin', 'Staff', 'Console', 'Approve']) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
    });
  });

  group('destinations open and keep their own stack', () {
    testWidgets('each of the five opens its screen', (tester) async {
      await boot(tester);

      await tapDestination(tester, 'Services');
      expect(find.widgetWithText(AppBar, 'Services'), findsOneWidget);

      await tapDestination(tester, 'News');
      expect(find.widgetWithText(AppBar, 'News'), findsOneWidget);

      await tapDestination(tester, 'Events');
      expect(find.widgetWithText(AppBar, 'Events'), findsOneWidget);

      await tapDestination(tester, 'Profile');
      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);

      await tapDestination(tester, 'Home');
      expect(find.text('Kumusta!'), findsOneWidget);
    });

    testWidgets('a branch keeps its place while another is visited', (
      tester,
    ) async {
      await boot(tester, initialLocation: '/news/abc123');
      expect(find.widgetWithText(AppBar, 'Announcement'), findsOneWidget);

      await tapDestination(tester, 'Services');
      expect(find.widgetWithText(AppBar, 'Services'), findsOneWidget);

      // Back to News: still on the announcement, not reset to the list.
      await tapDestination(tester, 'News');
      expect(find.widgetWithText(AppBar, 'Announcement'), findsOneWidget);
    });

    testWidgets('re-tapping the current destination returns to its root', (
      tester,
    ) async {
      await boot(tester, initialLocation: '/news/abc123');
      expect(find.widgetWithText(AppBar, 'Announcement'), findsOneWidget);

      // The escape hatch from a screen a resident deep-linked into.
      await tapDestination(tester, 'News');
      expect(find.widgetWithText(AppBar, 'News'), findsOneWidget);
    });
  });

  group('responsive layout keeps one information architecture', () {
    testWidgets('a wide surface uses a rail, not a bar', (tester) async {
      await boot(tester, size: const Size(1000, 900));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations, hasLength(5));
      expect(rail.extended, isTrue);
    });

    testWidgets('a medium surface uses a collapsed rail', (tester) async {
      await boot(tester, size: const Size(700, 900));

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
      expect(rail.destinations, hasLength(5));
    });

    testWidgets('the rail navigates to the same routes as the bar', (
      tester,
    ) async {
      await boot(tester, size: const Size(1000, 900));

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Events'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Events'), findsOneWidget);
    });
  });

  group('gated content explains itself — acceptance 2', () {
    testWidgets('Profile opens for a guest and offers the way in', (
      tester,
    ) async {
      await boot(tester);
      await tapDestination(tester, 'Profile');

      expect(find.text('You are browsing as a guest'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      // Locked entries state what they need rather than disappearing.
      expect(find.text('Sign-in required'), findsWidgets);
    });

    testWidgets('an unverified resident sees what verification unlocks', (
      tester,
    ) async {
      await boot(tester, level: AccessLevel.unverified);
      await tapDestination(tester, 'Profile');

      expect(find.text('Verification required'), findsWidgets);
      expect(find.text('Verify my identity'), findsWidgets);
    });

    testWidgets('a verified resident sees the honest availability answer', (
      tester,
    ) async {
      await boot(tester, level: AccessLevel.verified);
      await tapDestination(tester, 'Profile');

      // Access is fine; the LGU has not switched these on. Different sentence.
      expect(find.text('Not available yet'), findsWidgets);
      expect(find.text('Verification required'), findsNothing);
    });

    testWidgets('a guest deep-linking into a request lands on sign-in', (
      tester,
    ) async {
      await boot(tester, initialLocation: '/requests/r-1');

      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
      expect(find.text('Request status'), findsNothing);
    });

    testWidgets('an unverified resident deep-linking lands on verification', (
      tester,
    ) async {
      await boot(
        tester,
        level: AccessLevel.unverified,
        initialLocation: '/requests/r-1/requirements',
      );

      expect(find.text('Identity verification'), findsWidgets);
      expect(find.text('Documents needed'), findsNothing);
    });
  });

  group('deep-link targets are handled honestly', () {
    testWidgets('a malformed identifier is refused without claiming a fault', (
      tester,
    ) async {
      // `%20` decodes to a space, which is not a valid opaque identifier.
      await boot(tester, initialLocation: '/news/a%20b');

      expect(find.text('This announcement is not available'), findsOneWidget);
      expect(find.text('See all announcements'), findsOneWidget);
    });

    testWidgets('an unresolvable post offers the list, not an error', (
      tester,
    ) async {
      await boot(tester, initialLocation: '/news/abc123');
      await tester.pumpAndSettle();

      expect(find.text('This announcement is not available'), findsOneWidget);
      expect(find.textContaining('newer version'), findsOneWidget);
    });

    testWidgets('an unknown path reaches the not-found screen', (tester) async {
      await boot(tester, initialLocation: '/nope');

      expect(
        find.text('That link does not lead anywhere in this app.'),
        findsOneWidget,
      );
      expect(find.text('Go to home'), findsOneWidget);
    });

    testWidgets('opening a request performs no action on it', (tester) async {
      await boot(
        tester,
        level: AccessLevel.verified,
        initialLocation: '/requests/r-1/requirements',
      );
      await tester.pumpAndSettle();

      // No submit, cancel or confirm anywhere on a screen a link can open.
      for (final action in <String>[
        'Submit',
        'Cancel request',
        'Confirm',
        'Acknowledge',
      ]) {
        expect(find.widgetWithText(FilledButton, action), findsNothing);
        expect(find.widgetWithText(TextButton, action), findsNothing);
      }
    });
  });

  group('accessibility', () {
    testWidgets('the five destinations survive a 200% text scale', (
      tester,
    ) async {
      await boot(tester, textScaler: const TextScaler.linear(2));

      expect(tester.takeException(), isNull);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations, hasLength(5));
    });
  });
}
