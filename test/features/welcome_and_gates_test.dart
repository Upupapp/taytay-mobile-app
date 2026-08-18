import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/intent/resident_intent.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/auth/domain/sign_in_challenge.dart';

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Boots the whole app with injected storage, so launch state and session are
/// exactly what a real cold start would find.
Future<AppDependencies> boot(
  WidgetTester tester, {
  bool welcomeSeen = false,
  StoredSession? stored,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  // A phone-shaped surface. The 800x600 default is landscape-ish and shorter
  // than any device a resident holds, and a `ListView` only builds what fits —
  // so content below the fold is genuinely absent from the tree and an
  // assertion about it fails for reasons that have nothing to do with the code.
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  if (welcomeSeen) {
    await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  }

  final sessionStore = InMemorySessionStore();
  if (stored != null) await sessionStore.write(stored);

  final dependencies = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
  );
  addTearDown(dependencies.dispose);

  // Derived from the real test view, then overridden only where the test cares.
  // A bare `MediaQueryData()` here would carry `size: Size.zero`, and because
  // `MaterialApp` reuses an existing MediaQuery rather than creating one, the
  // whole app would lay out at zero height — every off-screen tap then misses
  // and the failure looks like a logic bug.
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(disableAnimations: disableAnimations, textScaler: textScaler),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  return dependencies;
}

/// Lets the splash minimum-display delay and both restores settle.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

/// Taps [finder] and settles.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
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

const StoredSession verifiedSession = StoredSession(
  resident: ResidentSession(
    accountId: 'acct-1',
    accessLevel: AccessLevel.verified,
  ),
  accessToken: 'token',
);

const StoredSession unverifiedSession = StoredSession(
  resident: ResidentSession(
    accountId: 'acct-1',
    accessLevel: AccessLevel.unverified,
  ),
  accessToken: 'token',
);

void main() {
  setUp(MotionPreference.reset);
  tearDown(MotionPreference.reset);

  group('startup routing', () {
    testWidgets('a first launch lands on the welcome scenes', (tester) async {
      final dependencies = await boot(tester);
      await settle(tester);

      expect(dependencies.launch.state, LaunchState.firstLaunch);
      expect(find.text('Municipal services in one place'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('a returning guest skips the welcome entirely', (tester) async {
      await boot(tester, welcomeSeen: true);
      await settle(tester);

      expect(find.text('Municipal services in one place'), findsNothing);
      expect(find.textContaining('no account needed'), findsOneWidget);
    });

    testWidgets('a returning verified resident lands on home', (tester) async {
      final dependencies = await boot(
        tester,
        welcomeSeen: true,
        stored: verifiedSession,
      );
      await settle(tester);

      expect(dependencies.session.accessLevel, AccessLevel.verified);
      expect(find.textContaining('verified Taytay resident'), findsOneWidget);
    });

    testWidgets('an unverified resident lands on home with the next step', (
      tester,
    ) async {
      await boot(tester, welcomeSeen: true, stored: unverifiedSession);
      await settle(tester);

      expect(find.text('One step to go'), findsOneWidget);
    });

    testWidgets('an expired session drops to guest and explains why', (
      tester,
    ) async {
      final dependencies = await boot(
        tester,
        welcomeSeen: true,
        stored: verifiedSession,
      );
      await settle(tester);

      // A 401 arriving from any in-flight request.
      await dependencies.session.handleUnauthenticated();
      await tester.pumpAndSettle();

      expect(dependencies.session.accessLevel, AccessLevel.guest);
      expect(find.textContaining('no account needed'), findsOneWidget);

      // The reason survives, so sign-in can say the session ended.
      final session = dependencies.session.state as GuestSession;
      expect(session.endedReason, SessionEndedReason.expired);
    });

    testWidgets('an expired session clears any held intent', (tester) async {
      final dependencies = await boot(
        tester,
        welcomeSeen: true,
        stored: verifiedSession,
      );
      await settle(tester);

      dependencies.intents.remember(ResidentIntentKind.viewDigitalId);
      // Invalidation goes through the coordinator, which clears intents.
      await dependencies.session.handleUnauthenticated();
      dependencies.intents.onSessionChanged();
      await tester.pumpAndSettle();

      expect(dependencies.intents.hasPending, isFalse);
    });
  });

  group('welcome scenes — no trap', () {
    testWidgets('skip marks the welcome done and enters the app', (
      tester,
    ) async {
      final dependencies = await boot(tester);
      await settle(tester);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(dependencies.launch.state, LaunchState.returning);
      expect(find.textContaining('no account needed'), findsOneWidget);
    });

    testWidgets('a skipped welcome is not shown again on the next launch', (
      tester,
    ) async {
      // Re-asking would override a decision the resident already made.
      final secrets = InMemorySecretStore();
      final first = LaunchController(secrets: secrets);
      await first.restore();
      await first.markWelcomeCompleted();

      final second = LaunchController(secrets: secrets);
      await second.restore();
      expect(second.state, LaunchState.returning);
    });

    testWidgets('continue as guest is explicit on the last scene', (
      tester,
    ) async {
      final dependencies = await boot(tester);
      await settle(tester);

      // Walk to the last scene.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Continue as guest'), findsOneWidget);
      expect(
        find.text('You can browse municipal services without an account.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      expect(dependencies.launch.state, LaunchState.returning);
      expect(find.textContaining('no account needed'), findsOneWidget);
    });

    testWidgets('progress is announced as text, not only as dots', (
      tester,
    ) async {
      await boot(tester);
      await settle(tester);

      expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    });

    testWidgets('scene titles are marked as headers', (tester) async {
      await boot(tester);
      await settle(tester);

      final semantics = tester.getSemantics(
        find.text('Municipal services in one place'),
      );
      expect(semantics.flagsCollection.isHeader, isTrue);
    });

    testWidgets('the welcome survives a 200% text scale', (tester) async {
      await boot(tester, textScaler: const TextScaler.linear(2));
      await settle(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('scene transitions work under reduced motion', (tester) async {
      await boot(tester, disableAnimations: true);
      await settle(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your Taytay ID, on your phone'), findsOneWidget);
    });

    testWidgets('the in-app reduced-motion preference also applies', (
      tester,
    ) async {
      MotionPreference.set(MotionPreference.reduced);
      await boot(tester);
      await settle(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('access gates preserve intent', () {
    testWidgets('a guest tapping the digital ID meets the sign-in gate', (
      tester,
    ) async {
      final dependencies = await boot(tester, welcomeSeen: true);
      await settle(tester);

      await openDigitalIdEntry(tester);

      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.textContaining('open your digital ID'), findsOneWidget);
      // The intent is held while they pass the gate.
      expect(
        dependencies.intents.pending?.kind,
        ResidentIntentKind.viewDigitalId,
      );
    });

    testWidgets('an unverified resident meets the verification gate', (
      tester,
    ) async {
      await boot(tester, welcomeSeen: true, stored: unverifiedSession);
      await settle(tester);

      await openDigitalIdEntry(tester);

      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Verify your identity'),
        ),
        findsOneWidget,
      );
      expect(find.text('Start verification'), findsWidgets);
    });

    testWidgets('dismissing a gate forgets the intent', (tester) async {
      final dependencies = await boot(tester, welcomeSeen: true);
      await settle(tester);

      await openDigitalIdEntry(tester);
      await tapVisible(tester, find.text('Keep browsing'));

      expect(dependencies.intents.hasPending, isFalse);
      // And they are back where they were — the Profile screen the gate was
      // opened from — not stranded on a sheet or bounced to sign-in.
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.widgetWithText(AppBar, 'Profile'), findsOneWidget);
      expect(find.text('Welcome to Taytay LGU IDS'), findsNothing);
    });

    testWidgets('the gate never grants access by itself', (tester) async {
      final dependencies = await boot(tester, welcomeSeen: true);
      await settle(tester);

      await openDigitalIdEntry(tester);

      // Showing the sheet changed nothing about what the resident may do.
      expect(dependencies.session.accessLevel, AccessLevel.guest);
      expect(find.text('MUNICIPALITY OF TAYTAY'), findsNothing);
    });

    testWidgets('a verified resident is not gated at all', (tester) async {
      final dependencies = await boot(
        tester,
        welcomeSeen: true,
        stored: verifiedSession,
      );
      await settle(tester);

      await openDigitalIdEntry(tester);

      expect(find.text('Sign in to continue'), findsNothing);
      expect(find.text('MUNICIPALITY OF TAYTAY'), findsOneWidget);
      expect(dependencies.intents.hasPending, isFalse);
    });

    testWidgets('a held intent resumes once the session satisfies it', (
      tester,
    ) async {
      final dependencies = await boot(tester, welcomeSeen: true);
      await settle(tester);

      // The gate records the intent; here it is held directly so the test is
      // about resumption rather than about sheet mechanics, which the gate
      // tests above already cover.
      dependencies.intents.remember(ResidentIntentKind.viewDigitalId);
      expect(dependencies.intents.hasPending, isTrue);

      // The session becomes verified — as a completed sign-in would make it.
      await dependencies.session.signIn(
        resident: verifiedSession.resident,
        accessToken: 'token',
      );
      await tester.pumpAndSettle();

      expect(dependencies.intents.hasPending, isFalse);
      expect(find.text('MUNICIPALITY OF TAYTAY'), findsOneWidget);
    });

    testWidgets('an intent does not resume on a session that still fails it', (
      tester,
    ) async {
      final dependencies = await boot(tester, welcomeSeen: true);
      await settle(tester);

      dependencies.intents.remember(ResidentIntentKind.viewDigitalId);
      // Signing in, but not verified: the gate is still not satisfied.
      await dependencies.session.signIn(
        resident: unverifiedSession.resident,
        accessToken: 'token',
      );
      await tester.pumpAndSettle();

      expect(dependencies.intents.hasPending, isTrue);
      expect(find.text('MUNICIPALITY OF TAYTAY'), findsNothing);
    });
  });

  group('honest seams for absent backends', () {
    testWidgets('sign-in reports the real failure, never a fake success', (
      tester,
    ) async {
      await boot(tester, welcomeSeen: true);
      await settle(tester);

      await tester.tap(find.text('Sign in').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '09171234567');
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();

      // The repository is wired now, so this is a real request that could not
      // leave the device. What must never happen is the screen advancing to the
      // code step as though a code had been sent.
      expect(
        SignInMessage.values.any(
          (m) => find.textContaining(m.text).evaluate().isNotEmpty,
        ),
        isTrue,
        reason: 'no resident-facing sign-in message was shown',
      );
      expect(find.text('Send one-time code'), findsOneWidget);
    });

    testWidgets('verification explains rather than collecting documents', (
      tester,
    ) async {
      await boot(tester, welcomeSeen: true, stored: unverifiedSession);
      await settle(tester);

      // TAB 11: Home's next-action card is the route to verification for an
      // unverified resident. With no status loaded it says what is true from
      // the session alone and offers to check.
      expect(find.text('One step to go'), findsOneWidget);
      await tapVisible(tester, find.text('Check my status'));

      // TAB 08: the status screen declines honestly because the Verification
      // module is unbuilt, rather than showing an invented status or
      // collecting documents it cannot send.
      expect(find.text('Could not check your status'), findsOneWidget);
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  });
}
