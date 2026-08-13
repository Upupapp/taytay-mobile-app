import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';

AppConfig _config({String environment = 'dev', String baseUrl = ''}) =>
    AppConfig.from(
      rawEnvironment: environment,
      rawApiBaseUrl: baseUrl,
      isReleaseBuild: false,
    );

/// Boots the app with an injected store so the test controls the session that
/// gets restored, exactly as a real cold start would find it.
Future<AppDependencies> _pumpApp(
  WidgetTester tester, {
  StoredSession? stored,
  AppConfig? config,
}) async {
  final store = InMemorySessionStore();
  if (stored != null) await store.write(stored);

  final dependencies = AppDependencies.build(
    config: config ?? _config(),
    sessionStore: store,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  return dependencies;
}

/// Lets the splash's minimum-display delay and the restore future settle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  group('cold start', () {
    testWidgets('shows the splash first, then lands a guest on home', (
      tester,
    ) async {
      final dependencies = await _pumpApp(tester);

      // Before restore completes, the session is unresolved and the splash holds.
      expect(dependencies.session.state, isA<SessionRestoring>());
      expect(find.text('Taytay LGU IDS'), findsOneWidget);

      await _settle(tester);

      expect(dependencies.session.state, const GuestSession());
      expect(find.text('Kumusta!'), findsOneWidget);
      expect(find.text('You are browsing as a guest'), findsOneWidget);
    });

    testWidgets('resumes a stored session without asking to sign in again', (
      tester,
    ) async {
      final dependencies = await _pumpApp(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
            displayName: 'Ana',
          ),
          accessToken: 'token',
        ),
      );

      await _settle(tester);

      expect(dependencies.session.accessLevel, AccessLevel.verified);
      expect(find.text('Kumusta, Ana!'), findsOneWidget);
      expect(find.text('Verified resident'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    });
  });

  group('access gating end to end', () {
    testWidgets('a guest tapping the digital ID is sent to sign in', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _settle(tester);

      await tester.tap(find.text('My Taytay digital ID'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
      expect(find.text('Mobile number'), findsOneWidget);
    });

    testWidgets('an unverified resident tapping the ID lands on verification', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.unverified,
          ),
          accessToken: 'token',
        ),
      );
      await _settle(tester);

      await tester.tap(find.text('My Taytay digital ID'));
      await tester.pumpAndSettle();

      expect(find.text('Verify your identity with Taytay LGU'), findsOneWidget);
    });

    testWidgets('a verified resident reaches the digital ID', (tester) async {
      await _pumpApp(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await _settle(tester);

      await tester.tap(find.text('My Taytay digital ID'));
      await tester.pumpAndSettle();

      expect(find.text('My Taytay ID'), findsOneWidget);
      expect(find.text('MUNICIPALITY OF TAYTAY'), findsOneWidget);
    });

    testWidgets('signing out moves the resident off a protected screen', (
      tester,
    ) async {
      final dependencies = await _pumpApp(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await _settle(tester);

      await tester.tap(find.text('Account and preferences'));
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsWidgets);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // The router reacts to the session, not to the button: the account screen
      // requires authentication, so signing out cannot leave the resident on it.
      expect(dependencies.session.accessLevel, AccessLevel.guest);
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
    });

    testWidgets('an expired session moves the resident off and explains why', (
      tester,
    ) async {
      final dependencies = await _pumpApp(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await _settle(tester);

      await tester.tap(find.text('My Taytay digital ID'));
      await tester.pumpAndSettle();
      expect(find.text('MUNICIPALITY OF TAYTAY'), findsOneWidget);

      // Simulates a 401 arriving from any in-flight request.
      await dependencies.session.handleUnauthenticated();
      await tester.pumpAndSettle();

      expect(find.text('MUNICIPALITY OF TAYTAY'), findsNothing);
      // The resident is told why, rather than silently finding a sign-in form.
      expect(
        find.textContaining('Your session ended for your security'),
        findsOneWidget,
      );
    });
  });

  group('sign-in screen', () {
    testWidgets('validates the mobile number before sending anything', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _settle(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your mobile number.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '12345');
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter an 11-digit mobile number starting with 09.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a resident-safe failure, never the server text', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _settle(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '09171234567');
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('temporarily unavailable'),
        findsOneWidget,
      );
      // The operator-facing detail only appears because this is a dev build.
      expect(find.textContaining('Identity endpoints'), findsOneWidget);
    });
  });

  group('misconfigured build', () {
    testWidgets('refuses to start rather than call the wrong backend', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        config: _config(
          environment: 'prod',
          baseUrl: 'http://api.taytay.gov.ph/api/v1',
        ),
      );
      await tester.pump();

      expect(
        find.text('This build is not configured correctly and cannot start.'),
        findsOneWidget,
      );
      expect(find.text('Kumusta!'), findsNothing);
    });
  });

  group('environment badge', () {
    testWidgets('is visible in a dev build', (tester) async {
      await _pumpApp(tester);
      await _settle(tester);

      final banner = tester.widget<Banner>(find.byType(Banner).first);
      expect(banner.message, 'DEV');
    });

    testWidgets('is absent in a production build', (tester) async {
      await _pumpApp(tester, config: _config(environment: 'prod'));
      await _settle(tester);

      expect(find.byType(Banner), findsNothing);
    });
  });
}
