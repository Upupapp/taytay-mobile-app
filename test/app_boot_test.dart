import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

AppConfig _config({String environment = 'dev', String baseUrl = ''}) =>
    AppConfig.from(
      rawEnvironment: environment,
      rawApiBaseUrl: baseUrl,
      isReleaseBuild: false,
    );

/// Boots the app with injected storage so the test controls both the session
/// and the launch state a real cold start would find.
///
/// [welcomeSeen] defaults to true: these tests are about a *returning*
/// resident's startup and access behaviour. First-launch routing is covered in
/// `test/features/welcome_and_gates_test.dart`.
Future<AppDependencies> _pumpApp(
  WidgetTester tester, {
  StoredSession? stored,
  AppConfig? config,
  bool welcomeSeen = true,
}) async {
  // A phone-shaped surface: the 800x600 default is shorter than any device, and
  // a ListView only builds what fits, so content below the fold is genuinely
  // absent from the tree.
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = InMemorySessionStore();
  if (stored != null) await store.write(stored);

  final secrets = InMemorySecretStore();
  if (welcomeSeen) {
    await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  }

  final dependencies = AppDependencies.build(
    config: config ?? _config(),
    sessionStore: store,
    secrets: secrets,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  return dependencies;
}

/// Opens the digital-ID entry point.
///
/// TAB 11 replaced the Home tile list with a dashboard, so the per-capability
/// entries now live on the Profile destination. The gate behaviour under test is
/// unchanged; only the path a resident takes to reach it moved.
Future<void> openDigitalIdEntry(WidgetTester tester) async {
  await openProfileShortcut(tester, 'Hold your Taytay digital ID');
}

/// Opens the account entry point, for the same reason.
Future<void> openAccountEntry(WidgetTester tester) async {
  await openProfileShortcut(tester, 'Manage your account');
}

/// Taps a shortcut on the Profile screen, scrolling to it first.
///
/// TAB 12 put the account and LGU-verified field sections above the shortcut
/// list, so on a phone-sized surface the shortcuts start below the fold — and a
/// `ListView` only builds what fits, so an un-scrolled tap misses a widget that
/// is genuinely absent from the tree.
Future<void> openProfileShortcut(WidgetTester tester, String label) async {
  await tester.tap(find.text('Profile').last);
  await tester.pumpAndSettle();
  await revealInProfile(tester, find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// The Profile screen's own scrollable.
///
/// `find.byType(Scrollable).first` is wrong inside the shell: an
/// `IndexedStack` keeps all five branches alive, so Home's list is in the tree
/// too and scrolling it never reveals anything on Profile. Anchoring on the
/// Profile app bar picks the right one.
Finder profileScrollable() => find
    .descendant(
      of: find
          .ancestor(
            of: find.widgetWithText(AppBar, 'Profile'),
            matching: find.byType(Scaffold),
          )
          .first,
      matching: find.byType(Scrollable),
    )
    .first;

/// Scrolls [finder] into view within the Profile list.
///
/// A bounded drag loop rather than `scrollUntilVisible`, for two reasons that
/// both bite here: the target may match several tiles once built (which that
/// helper rejects), and `.first` on a not-yet-built finder throws rather than
/// resolving to empty.
Future<void> revealInProfile(WidgetTester tester, Finder finder) async {
  final scrollable = profileScrollable();
  for (var attempt = 0; attempt < 15 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(scrollable, const Offset(0, -220));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
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
      expect(find.textContaining('no account needed'), findsOneWidget);
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
      expect(find.textContaining('verified Taytay resident'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    });
  });

  group('access gating end to end', () {
    testWidgets('a guest tapping the digital ID is sent to sign in', (
      tester,
    ) async {
      await _pumpApp(tester);
      await _settle(tester);

      await openDigitalIdEntry(tester);

      // TAB 06: the tile now explains the gate and holds the intent before
      // sending the resident on.
      expect(find.text('Sign in to continue'), findsOneWidget);
      // Scoped to the sheet: the home card behind it also offers "Sign in".
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Sign in'),
        ),
      );
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

      await openDigitalIdEntry(tester);

      // TAB 06: the verification gate explains, then takes them there.
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Verify your identity'),
        ),
        findsOneWidget,
      );
      // Scoped to the sheet: the home card behind it also offers this action.
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Start verification'),
        ),
      );
      await tester.pumpAndSettle();

      // TAB 08 replaced the placeholder with the real status screen.
      expect(find.text('Identity verification'), findsWidgets);
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

      await openDigitalIdEntry(tester);

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

      await openAccountEntry(tester);
      expect(find.text('Account'), findsWidgets);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // TAB 09: signing out is confirmed first, because it cannot be undone
      // without a new one-time code. The dialog is where the resident is told
      // what they keep.
      expect(find.text('Sign out of this device?'), findsOneWidget);
      expect(find.textContaining('as a guest'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sign out'),
        ),
      );
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

      await openDigitalIdEntry(tester);
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

      await tester.tap(find.text('Sign in').first);
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

      await tester.tap(find.text('Sign in').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '09171234567');
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();

      // TAB 09: sign-in renders only a `SignInMessage`, never a failure view.
      // The operator-facing debug text is no longer surfaced here even in a dev
      // build, because on this screen it would name the endpoint that refused —
      // and that is one step from naming *why* it refused.
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
      expect(find.textContaining('Identity endpoints'), findsNothing);
      // Nothing distinguishes an unknown number from any other refusal.
      expect(find.textContaining('not registered'), findsNothing);
      expect(find.textContaining('no account'), findsNothing);
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
