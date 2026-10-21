import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
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
  DocumentPicker? documentPicker,
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
    documentPicker: documentPicker ?? base.documentPicker,
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
  group('sign-in, email or mobile and a password', () {
    testWidgets('asks for an identifier and a password', (tester) async {
      final auth = FakeAuthRepository();
      await boot(tester, auth: auth);
      await goTo(tester, 'sign-in');

      expect(find.text('Maligayang pagbabalik!'), findsOneWidget);
      expect(find.text('Email or mobile number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      // The debug session simulator is not on this screen.
      expect(find.text('Session simulator'), findsNothing);
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
        'Maligayang pagbabalik!',
        'Sign in to your Taytay resident account.',
        'Forgot password?',
        'Create an account',
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
      // Walk the element tree: the sheet key lives inside the sheet widget's
      // build, so it is not a field on the stack's child configuration.
      final stackElement = tester.element(
        find.byKey(const Key('sign-in-stack')),
      );
      final layers = <Element>[];
      stackElement.visitChildren(layers.add);
      bool subtree(Element element, bool Function(Element node) match) {
        if (match(element)) return true;
        var found = false;
        element.visitChildren((child) {
          found = found || subtree(child, match);
        });
        return found;
      }

      final threadAt = layers.indexWhere(
        (layer) => subtree(layer, (node) => node.widget is SignInThreadOverlay),
      );
      final sheetAt = layers.indexWhere(
        (layer) =>
            subtree(layer, (node) => node.widget.key == signInFormSheetKey),
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

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'juana.delacruz@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'password-sample',
        );
        await tester.tap(
          find.descendant(
            of: find.byType(Form),
            matching: find.text('Sign in'),
          ),
        );
        await tester.pumpAndSettle();

        expect(dependencies.session.state, isA<AuthenticatedSession>());
        // The router reacted; the screen did not route itself.
        expect(find.textContaining(', Ana!'), findsOneWidget);
      },
    );

    testWidgets('a refused password says nothing about the account', (
      tester,
    ) async {
      final auth = FakeAuthRepository(
        passwordOutcome: const Err<AuthOutcome>(UnauthenticatedFailure()),
      );
      await boot(tester, auth: auth);
      await goTo(tester, 'sign-in');

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'juana.delacruz@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'wrong-password',
      );
      await tester.tap(
        find.descendant(of: find.byType(Form), matching: find.text('Sign in')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Incorrect email or password'),
        findsOneWidget,
      );
      expect(find.textContaining('not registered'), findsNothing);
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

    testWidgets('forgot password is a screen, and sign-in has a way back', (
      tester,
    ) async {
      await boot(tester, auth: FakeAuthRepository());
      await goTo(tester, 'sign-in');

      expect(find.byType(BackButton), findsNothing);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('Send reset code'), findsOneWidget);
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Maligayang pagbabalik!'), findsOneWidget);
    });

    testWidgets('a guest can leave sign-in without an account', (tester) async {
      await boot(tester);
      await goTo(tester, 'sign-in');

      await reveal(tester, find.text('Continue as guest'));
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      expect(find.textContaining(', Bisita!'), findsOneWidget);
    });
  });

  group('help for someone who cannot sign in', () {
    testWidgets('points at reset and collects nothing', (tester) async {
      await boot(tester);
      await goTo(tester, 'sign-in-help');

      expect(find.text('Forgot your password?'), findsOneWidget);
      // No form: this screen cannot be used to test whether an account exists.
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
      expect(find.textContaining(', Bisita!'), findsOneWidget);
      expect(find.text('Browsing as guest'), findsOneWidget);
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

      expect(find.textContaining(', Bisita!'), findsOneWidget);
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
      expect(find.textContaining(', Bisita!'), findsNothing);

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
      expect(find.textContaining(', Bisita!'), findsOneWidget);
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

      await reveal(tester, find.text('Email or mobile number'));
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'juana.delacruz@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password-sample',
      );
      await reveal(
        tester,
        find.descendant(of: find.byType(Form), matching: find.text('Sign in')),
      );
      await tester.tap(
        find.descendant(of: find.byType(Form), matching: find.text('Sign in')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining(', Ana!'), findsNothing);
      expect(find.text('Maligayang pagbabalik!'), findsNothing);
    });
  });
}
