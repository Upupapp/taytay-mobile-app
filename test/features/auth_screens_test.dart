import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/auth/domain/auth_repository.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_screen.dart';
import 'package:taytay_resident/shared/widgets/taytay_thread.dart';

import 'auth_session_test.dart' show FakeAuthRepository, FakeLocalAuthenticator;

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Boots the whole app with an injectable auth repository and local
/// authenticator, so sign-in and the app lock can be driven end to end.
Future<AppDependencies> boot(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  FakeLocalAuthenticator? authenticator,
  StoredSession? stored,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final sessionStore = InMemorySessionStore();
  if (stored != null) await sessionStore.write(stored);

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: authenticator ?? FakeLocalAuthenticator(),
  );
  final dependencies = AppDependencies(
    config: base.config,
    session: base.session,
    launch: base.launch,
    intents: base.intents,
    appLock: base.appLock,
    apiClient: base.apiClient,
    cache: base.cache,
    network: base.network,
    telemetry: base.telemetry,
    authRepository: auth ?? base.authRepository,
    deviceSessionRepository: base.deviceSessionRepository,
    platformRepository: base.platformRepository,
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    serviceRequestRepository: base.serviceRequestRepository,
    requirementRepository: base.requirementRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    onDispose: base.onDispose,
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
  return dependencies;
}

/// Navigates by name, as the app itself does.
Future<void> goTo(WidgetTester tester, String routeName) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).goNamed(routeName);
  await tester.pumpAndSettle();
}

bool _contains(Widget widget, bool Function(Widget widget) match) {
  if (match(widget)) return true;
  if (widget is Positioned) return _contains(widget.child, match);
  if (widget is ProxyWidget) return _contains(widget.child, match);
  if (widget is SingleChildRenderObjectWidget) {
    final child = widget.child;
    return child != null && _contains(child, match);
  }
  if (widget is MultiChildRenderObjectWidget) {
    return widget.children.any((child) => _contains(child, match));
  }
  return false;
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('sign-in, two steps', () {
    testWidgets('asks for a number, then a code', (tester) async {
      final auth = FakeAuthRepository();
      await boot(tester, auth: auth);
      await goTo(tester, 'sign-in');

      expect(find.text('Welcome to Taytay LGU IDS'), findsOneWidget);
      expect(find.text('Mobile number'), findsOneWidget);
      // No password field anywhere: the contract has none for a citizen.
      expect(find.text('Password'), findsNothing);

      await tester.enterText(find.byType(TextFormField), '09171234567');
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your code'), findsOneWidget);
      expect(find.text('One-time code'), findsOneWidget);
      // The number is masked on the screen that confirms it back.
      expect(find.textContaining('0917 ••• 4567'), findsOneWidget);
      expect(find.textContaining('09171234567'), findsNothing);
    });

    testWidgets('the form sits on the white sheet and clears AA', (
      tester,
    ) async {
      await boot(tester);
      await goTo(tester, 'sign-in');

      final sheet = find.byKey(signInFormSheetKey);
      expect(sheet, findsOneWidget);
      expect(tester.widget<Material>(sheet).color, Colors.white);

      const lines = <String>[
        'Welcome to Taytay LGU IDS',
        'Enter your mobile number and we will send you a one-time code. '
            'There is no password to remember.',
        'Taytay LGU uses your mobile number to sign you in and to contact '
            'you about your requests. It is never shared for advertising.',
        'Trouble signing in?',
        'Continue as guest',
      ];
      for (final line in lines) {
        expect(
          find.descendant(of: sheet, matching: find.text(line)),
          findsOneWidget,
          reason: line,
        );
      }

      // The stitch is a sibling behind the sheet, not a paint over the field.
      final stack = tester.widget<Stack>(
        find.byKey(const Key('sign-in-stack')),
      );
      final threadAt = stack.children.indexWhere(
        (child) => _contains(child, (widget) => widget is SignInThreadOverlay),
      );
      final sheetAt = stack.children.indexWhere(
        (child) =>
            _contains(child, (widget) => widget.key == signInFormSheetKey),
      );
      expect(threadAt, greaterThanOrEqualTo(0));
      expect(sheetAt, greaterThan(threadAt));

      RenderObject? ancestor = tester.renderObject(sheet).parent;
      RenderRepaintBoundary? boundary;
      while (ancestor != null) {
        if (ancestor is RenderRepaintBoundary) {
          boundary = ancestor;
          break;
        }
        ancestor = ancestor.parent;
      }
      expect(boundary, isNotNull);

      Future<List<int>> capture() async {
        final image = await tester.runAsync(() => boundary!.toImage());
        final captured = image!;
        final bytes = await tester.runAsync(
          () => captured.toByteData(format: ui.ImageByteFormat.rawRgba),
        );
        final packed = <int>[
          captured.width,
          captured.height,
          ...bytes!.buffer.asUint8List(),
        ];
        captured.dispose();
        return packed;
      }

      Color pixelAt(List<int> packed, Offset global) {
        final width = packed[0];
        final height = packed[1];
        final local = boundary!.globalToLocal(global);
        final x = local.dx.round().clamp(0, width - 1);
        final y = local.dy.round().clamp(0, height - 1);
        final i = 2 + (y * width + x) * 4;
        return Color.fromARGB(
          packed[i + 3],
          packed[i],
          packed[i + 1],
          packed[i + 2],
        );
      }

      for (final line in lines) {
        await reveal(tester, find.text(line));
        final rect = tester.getRect(find.text(line));
        final sheetRect = tester.getRect(sheet);
        final packed = await capture();
        // Left padding of the sheet, level with the line.
        final background = pixelAt(
          packed,
          Offset(sheetRect.left + 8, rect.center.dy),
        );
        expect(
          contrastRatio(background, Colors.white),
          lessThan(1.2),
          reason: '$line background $background rect $rect sheet $sheetRect',
        );
        Color? ink;
        for (var y = rect.top + 2; y < rect.bottom - 1 && ink == null; y += 1) {
          for (var x = rect.left + 2; x < rect.right - 1; x += 1) {
            final color = pixelAt(packed, Offset(x, y));
            if (contrastRatio(color, background) >= 4.5) {
              ink = color;
              break;
            }
          }
        }
        expect(ink, isNotNull, reason: '$line has no AA ink on $background');
      }
    });

    testWidgets(
      'a valid code signs the resident in without navigating itself',
      (tester) async {
        final auth = FakeAuthRepository(
          verifyOutcome: const Ok<AuthOutcome>(
            AuthOutcome(
              resident: ResidentSession(
                accountId: 'acct-1',
                accessLevel: AccessLevel.unverified,
                displayName: 'Ana',
              ),
              accessToken: 'token',
            ),
          ),
        );
        final dependencies = await boot(tester, auth: auth);
        await goTo(tester, 'sign-in');

        await tester.enterText(find.byType(TextFormField), '09171234567');
        await tester.tap(find.text('Send one-time code'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), '123456');
        await tester.tap(
          find.descendant(
            of: find.byType(Form),
            matching: find.text('Sign in'),
          ),
        );
        await tester.pumpAndSettle();

        expect(dependencies.session.state, isA<AuthenticatedSession>());
        // The router reacted; the screen did not route itself.
        expect(find.text('Kumusta, Ana!'), findsOneWidget);
      },
    );

    testWidgets('a refused code says nothing about the account', (
      tester,
    ) async {
      final auth = FakeAuthRepository(
        verifyOutcome: const Err<AuthOutcome>(NotFoundFailure()),
      );
      await boot(tester, auth: auth);
      await goTo(tester, 'sign-in');

      await tester.enterText(find.byType(TextFormField), '09171234567');
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '999999');
      await tester.tap(
        find.descendant(of: find.byType(Form), matching: find.text('Sign in')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('That code did not work'), findsOneWidget);
      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ')
          .toLowerCase();
      for (final leak in <String>[
        'not registered',
        'no account',
        'not found',
        'does not exist',
      ]) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }
    });

    testWidgets('the code step offers a resend and a way back', (tester) async {
      await boot(tester, auth: FakeAuthRepository());
      await goTo(tester, 'sign-in');

      await tester.enterText(find.byType(TextFormField), '09171234567');
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();

      // Cooling down, so the label counts rather than inviting a wasted attempt.
      expect(find.textContaining('Send a new code in'), findsOneWidget);

      await tester.tap(find.text('Use a different number'));
      await tester.pumpAndSettle();
      expect(find.text('Mobile number'), findsOneWidget);
    });

    testWidgets('a guest can leave sign-in without an account', (tester) async {
      await boot(tester);
      await goTo(tester, 'sign-in');

      await reveal(tester, find.text('Continue as guest'));
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      expect(find.text('Kumusta!'), findsOneWidget);
    });
  });

  group('help for someone who cannot sign in', () {
    testWidgets('explains there is no password and collects nothing', (
      tester,
    ) async {
      await boot(tester);
      await goTo(tester, 'sign-in-help');

      expect(find.text('There is no password to reset'), findsOneWidget);
      // No form: this screen cannot be used to test whether a number exists.
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('gives a real route for a lost number, and a warning', (
      tester,
    ) async {
      await boot(tester);
      await goTo(tester, 'sign-in-help');

      await reveal(tester, find.text('You no longer have that number'));
      expect(find.textContaining('municipal hall'), findsWidgets);

      await reveal(tester, find.text('What we will never ask you'));
      expect(
        find.textContaining('never ask for your one-time code'),
        findsOneWidget,
      );
    });
  });

  group('signing out — acceptance 2', () {
    testWidgets('guest browsing stays available afterwards', (tester) async {
      final dependencies = await boot(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await goTo(tester, 'security');

      await reveal(tester, find.text('Sign out of this device'));
      await tester.tap(find.text('Sign out of this device'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out of this device?'), findsOneWidget);
      expect(find.textContaining('as a guest'), findsWidgets);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sign out'),
        ),
      );
      await tester.pumpAndSettle();

      expect(dependencies.session.accessLevel, AccessLevel.guest);

      // The point of the acceptance: public services are still reachable.
      await goTo(tester, 'home');
      expect(find.text('Kumusta!'), findsOneWidget);
      expect(find.textContaining('no account needed'), findsOneWidget);
    });

    testWidgets('cancelling keeps the resident signed in', (tester) async {
      final dependencies = await boot(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await goTo(tester, 'security');

      await reveal(tester, find.text('Sign out of this device'));
      await tester.tap(find.text('Sign out of this device'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dependencies.session.state, isA<AuthenticatedSession>());
    });
  });

  group('session expiry', () {
    testWidgets('explains itself and offers both ways forward', (tester) async {
      final dependencies = await boot(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await goTo(tester, 'digital-id');
      expect(find.text('MUNICIPALITY OF TAYTAY'), findsOneWidget);

      // Simulates a 401 arriving from any in-flight request.
      await dependencies.session.handleUnauthenticated();
      await tester.pumpAndSettle();

      expect(find.text('Your session ended'), findsOneWidget);

      // TAB 06. This used to assert "Nothing you submitted has been lost." That
      // sentence was narrowly true and read as something else: this app queues
      // nothing (DL-118), so anything typed and not yet sent when a session dies
      // is gone. The sheet now says which is which, and the old promise is
      // asserted ABSENT so it cannot come back as a kindness.
      expect(
        find.textContaining('Nothing you submitted has been lost'),
        findsNothing,
      );
      expect(
        find.textContaining('not kept on this phone'),
        findsOneWidget,
        reason: 'the resident is told what was actually lost',
      );
      expect(find.text('Sign in again'), findsOneWidget);
      expect(find.text('Continue as guest'), findsWidgets);
    });

    testWidgets('continuing as a guest leaves the resident on public content', (
      tester,
    ) async {
      final dependencies = await boot(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await goTo(tester, 'digital-id');
      await dependencies.session.handleUnauthenticated();
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Continue as guest'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kumusta!'), findsOneWidget);
    });

    testWidgets('a deliberate sign-out is not explained as an expiry', (
      tester,
    ) async {
      final dependencies = await boot(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );

      await dependencies.session.signOut();
      await tester.pumpAndSettle();

      // The resident asked for this. Explaining it would be noise.
      expect(find.text('Your session ended'), findsNothing);
    });
  });

  group('app lock', () {
    testWidgets('covers the app after backgrounding, and unlocks', (
      tester,
    ) async {
      final authenticator = FakeLocalAuthenticator();
      final dependencies = await boot(
        tester,
        authenticator: authenticator,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );

      await dependencies.appLock.load();
      await dependencies.appLock.enable();
      await tester.pumpAndSettle();

      dependencies.appLock.markBackgrounded();
      await tester.pumpAndSettle();

      expect(find.text('Taytay LGU IDS is locked'), findsOneWidget);
      // The content underneath is not merely covered — it is not built.
      expect(find.text('Kumusta!'), findsNothing);

      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Taytay LGU IDS is locked'), findsNothing);
    });

    testWidgets('always offers a way out that does not need the sensor', (
      tester,
    ) async {
      final authenticator = FakeLocalAuthenticator();
      final dependencies = await boot(
        tester,
        authenticator: authenticator,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );
      await dependencies.appLock.load();
      await dependencies.appLock.enable();
      dependencies.appLock.markBackgrounded();
      await tester.pumpAndSettle();

      // The sensor now refuses everything. The resident must not be trapped.
      authenticator.outcome = LocalUnlockOutcome.failed;
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Taytay LGU IDS is locked'), findsOneWidget);

      await tester.tap(find.text('Sign out instead'));
      await tester.pumpAndSettle();

      expect(dependencies.session.accessLevel, AccessLevel.guest);
      expect(find.text('Taytay LGU IDS is locked'), findsNothing);
    });

    testWidgets('a guest is never shown the lock screen', (tester) async {
      final dependencies = await boot(tester);

      dependencies.appLock.markBackgrounded();
      await tester.pumpAndSettle();

      expect(find.text('Taytay LGU IDS is locked'), findsNothing);
      expect(find.text('Kumusta!'), findsOneWidget);
    });
  });

  group('sign-in and security screen', () {
    testWidgets('says why the lock is unavailable rather than hiding it', (
      tester,
    ) async {
      await boot(
        tester,
        authenticator: FakeLocalAuthenticator(
          reported: LocalUnlockAvailability.unsupported,
        ),
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.unverified,
          ),
          accessToken: 'token',
        ),
      );
      await goTo(tester, 'security');

      expect(find.text('Lock this app'), findsOneWidget);
      expect(
        find.textContaining('cannot show an unlock prompt'),
        findsOneWidget,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
    });

    testWidgets('states that the lock is not identity proof', (tester) async {
      await boot(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.unverified,
          ),
          accessToken: 'token',
        ),
      );
      await goTo(tester, 'security');

      expect(
        find.textContaining('not how Taytay LGU knows who you are'),
        findsOneWidget,
      );
    });

    testWidgets('a failed sign-in check says so, and shows no fake devices', (
      tester,
    ) async {
      await boot(
        tester,
        stored: const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.unverified,
          ),
          accessToken: 'token',
        ),
      );
      await goTo(tester, 'security');

      await reveal(tester, find.text('Check my devices'));
      await tester.tap(find.text('Check my devices'));
      await tester.pumpAndSettle();

      // Wired at TAB 03, so this is a real request that could not leave the
      // device — and the copy must not be reassuring. A resident who came here
      // to check for an intruder and is told "not available yet" has learned
      // nothing; one told the check failed knows to try again.
      expect(find.text('Could not check your sign-ins'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // No fabricated rows either way. Keyed on the row's own icon rather than
      // its copy: "This device" is also a section heading on this screen, and a
      // test that matches the heading passes for the wrong reason.
      expect(find.byIcon(Icons.smartphone_outlined), findsNothing);
      expect(find.text('Sign out all 2 other devices'), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('sign-in is usable at 200% text scale', (tester) async {
      await boot(
        tester,
        auth: FakeAuthRepository(),
        textScaler: const TextScaler.linear(2),
      );
      await goTo(tester, 'sign-in');

      await reveal(tester, find.text('Mobile number'));
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextFormField), '09171234567');
      await reveal(tester, find.text('Send one-time code'));
      await tester.tap(find.text('Send one-time code'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Enter your code'), findsOneWidget);
    });
  });
}
