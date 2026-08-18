import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────
//
// Obviously synthetic. No real resident, consent or record.

final DateTime fixedGrant = DateTime.utc(2026, 3, 2, 4);

ConsentRecord consent({
  String key = 'c-notify',
  String label = 'Messages about your applications',
  String statement =
      'Taytay LGU may send you messages about applications you make.',
  DateTime? grantedAt,
  DateTime? withdrawnAt,
  bool isWithdrawable = true,
  String? withheldReason,
}) => ConsentRecord(
  key: key,
  label: label,
  statement: statement,
  grantedAt: grantedAt ?? fixedGrant,
  withdrawnAt: withdrawnAt,
  isWithdrawable: isWithdrawable,
  withheldReason: withheldReason,
);

/// A repository whose every answer the test states outright.
class ScriptedAccountControlsRepository implements AccountControlsRepository {
  ScriptedAccountControlsRepository({this.controls, this.consents});

  AccountControls? controls;
  List<ConsentRecord>? consents;

  bool withdrawFails = false;
  bool closureFails = false;

  final List<String> withdrawn = <String>[];
  final List<String> withdrawKeys = <String>[];
  final List<bool> closures = <bool>[];
  final List<String> closureKeys = <String>[];

  @override
  Future<Result<AccountControls>> loadControls() async {
    final value = controls;
    return value == null
        ? const Err<AccountControls>(ServerFailure(isTemporary: true))
        : Ok<AccountControls>(value);
  }

  @override
  Future<Result<List<ConsentRecord>>> listConsents() async {
    final value = consents;
    return value == null
        ? const Err<List<ConsentRecord>>(ServerFailure(isTemporary: true))
        : Ok<List<ConsentRecord>>(value);
  }

  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
  }) async {
    withdrawn.add(key);
    withdrawKeys.add(idempotencyKey);
    if (withdrawFails) {
      return const Err<ConsentRecord>(NetworkFailure());
    }
    final record = consent(key: key, withdrawnAt: DateTime.utc(2026, 8, 16));
    consents = <ConsentRecord>[record];
    return Ok<ConsentRecord>(record);
  }

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) async => const Ok<void>(null);

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) async {
    closures.add(permanent);
    closureKeys.add(idempotencyKey);
    return closureFails
        ? const Err<void>(NetworkFailure())
        : const Ok<void>(null);
  }
}

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef BootedSettings = ({
  AppDependencies dependencies,
  ScriptedAccountControlsRepository controls,
});

Future<BootedSettings> bootSettings(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  AccountControls? controls,
  List<ConsentRecord>? consents,
  AccountControlsRepository? repositoryOverride,
  String location = '/settings',
  Size size = const Size(400, 4000),
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
        resident: ResidentSession(
          accountId: 'acct-1',
          accessLevel: level,
          displayName: 'Ana',
        ),
        accessToken: 'token',
      ),
    );
  }

  final scripted = ScriptedAccountControlsRepository(
    controls: controls,
    consents: consents,
  );

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
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
    authRepository: base.authRepository,
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
    accountControlsRepository: repositoryOverride ?? scripted,
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

  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();

  return (dependencies: dependencies, controls: scripted);
}

void main() {
  setUp(MotionPreference.reset);
  tearDown(MotionPreference.reset);

  // ── Access ──────────────────────────────────────────────────────────────
  //
  // Acceptance 1: privacy and help are reachable without an account. Tested
  // from every session state, denied path included.

  group('Settings access', () {
    testWidgets('a guest reads settings without signing in', (tester) async {
      await bootSettings(tester, level: AccessLevel.guest);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy notice'), findsOneWidget);
      expect(find.text('Help and contacting Taytay LGU'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign in'), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('a guest is offered no account sections at all', (
      tester,
    ) async {
      await bootSettings(tester, level: AccessLevel.guest);

      // Absent, not present-and-disabled: a wall of locked rows tells somebody
      // the app is not for them.
      expect(find.text('Your account'), findsNothing);
      expect(find.text('Account'), findsNothing);
      expect(find.text('Sign-in and security'), findsNothing);
      expect(find.text('Notifications'), findsNothing);
      expect(find.text('Your consents and account requests'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('an unverified resident gets the account sections', (
      tester,
    ) async {
      await bootSettings(tester, level: AccessLevel.unverified);

      expect(find.text('Your account'), findsOneWidget);
      expect(find.text('Sign-in and security'), findsOneWidget);
      expect(find.text('Your consents and account requests'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('a guest reads help without signing in', (tester) async {
      await bootSettings(
        tester,
        level: AccessLevel.guest,
        location: '/settings/help',
      );

      expect(find.text('Getting help'), findsOneWidget);
      expect(
        find.text('Do I need an account to use this app?'),
        findsOneWidget,
      );
    });

    testWidgets('privacy controls are not reachable by a guest', (
      tester,
    ) async {
      await bootSettings(
        tester,
        level: AccessLevel.guest,
        location: '/settings/privacy',
      );

      // The guard redirects rather than rendering the screen.
      expect(find.text('Consents and account requests'), findsNothing);
    });
  });

  // ── Help ────────────────────────────────────────────────────────────────

  group('Help', () {
    testWidgets('invents no phone number, address or opening hours', (
      tester,
    ) async {
      await bootSettings(
        tester,
        level: AccessLevel.guest,
        location: '/settings/help',
      );

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ');

      // A landline, a mobile number, or "open ... to ..." hours would each be
      // this app publishing something it cannot verify.
      expect(RegExp(r'\(0?2\)\s*\d').hasMatch(rendered), isFalse);
      expect(RegExp(r'09\d{9}').hasMatch(rendered), isFalse);
      expect(
        RegExp(r'\d{1,2}\s*(am|pm)', caseSensitive: false).hasMatch(rendered),
        isFalse,
      );
    });

    testWidgets('an answer opens on tap', (tester) async {
      await bootSettings(
        tester,
        level: AccessLevel.guest,
        location: '/settings/help',
      );

      await tester.tap(find.text('I lost my phone.'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in on your new phone'), findsOneWidget);
    });
  });

  // ── Accessibility controls ──────────────────────────────────────────────

  group('Accessibility controls', () {
    testWidgets('reduce motion is a device preference the resident sets', (
      tester,
    ) async {
      await bootSettings(tester, level: AccessLevel.guest);

      expect(MotionPreference.current, MotionPreference.system);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Reduce motion'));
      await tester.pumpAndSettle();

      expect(MotionPreference.current, MotionPreference.reduced);
    });

    testWidgets('the OS setting wins and cannot be turned off in the app', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await bootSettings(tester, level: AccessLevel.guest);

      final tile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Reduce motion'),
      );
      expect(tile.value, isTrue);
      // Disabled, so an app switch cannot override somebody who already asked
      // their phone for less motion.
      expect(tile.onChanged, isNull);
    });
  });

  // ── Account controls ────────────────────────────────────────────────────
  //
  // Acceptance 3: no unsupported legal promise is invented in the UI.

  group('Account controls', () {
    testWidgets('offers nothing when the backend allows nothing', (
      tester,
    ) async {
      await bootSettings(
        tester,
        controls: AccountControls.none,
        consents: const <ConsentRecord>[],
        location: '/settings/privacy',
      );

      expect(find.text('Ask to erase my account'), findsNothing);
      expect(find.text('Ask to switch off my account'), findsNothing);
      expect(find.text('Ask for a correction'), findsNothing);
      expect(
        find.textContaining('not switched on in this app yet'),
        findsOneWidget,
      );
    });

    testWidgets('erasure is offered only when the server says so', (
      tester,
    ) async {
      await bootSettings(
        tester,
        controls: const AccountControls(
          canRequestDeletion: true,
          deletionPolicyNote:
              'Taytay LGU keeps some records for as long as the law requires.',
        ),
        consents: const <ConsentRecord>[],
        location: '/settings/privacy',
      );

      expect(find.text('Ask to erase my account'), findsOneWidget);
      expect(find.text('Ask to switch off my account'), findsNothing);
    });

    testWidgets('erasure is confirmed, and dismissing sends nothing', (
      tester,
    ) async {
      final booted = await bootSettings(
        tester,
        controls: const AccountControls(canRequestDeletion: true),
        consents: const <ConsentRecord>[],
        location: '/settings/privacy',
      );

      await tester.tap(find.text('Ask to erase my account'));
      await tester.pumpAndSettle();

      expect(find.text('What happens'), findsOneWidget);
      // The sheet names the consequence rather than asking "are you sure".
      expect(find.textContaining('It is a request, not'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(booted.controls.closures, isEmpty);
    });

    testWidgets('confirming sends one request with an idempotency key', (
      tester,
    ) async {
      final booted = await bootSettings(
        tester,
        controls: const AccountControls(canRequestDeletion: true),
        consents: const <ConsentRecord>[],
        location: '/settings/privacy',
      );

      await tester.tap(find.text('Ask to erase my account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send the request'));
      await tester.pumpAndSettle();

      expect(booted.controls.closures, <bool>[true]);
      expect(booted.controls.closureKeys.single, isNotEmpty);
      expect(find.textContaining('has your request'), findsOneWidget);
    });

    testWidgets('a failed request says nothing was asked for', (tester) async {
      final booted = await bootSettings(
        tester,
        controls: const AccountControls(canRequestDeactivation: true),
        consents: const <ConsentRecord>[],
        location: '/settings/privacy',
      );
      booted.controls.closureFails = true;

      await tester.tap(find.text('Ask to switch off my account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send the request'));
      await tester.pumpAndSettle();

      expect(find.textContaining('nothing has been asked for'), findsOneWidget);
    });
  });

  // ── Consents ────────────────────────────────────────────────────────────

  group('Consent history', () {
    testWidgets('a withdrawn consent keeps its row', (tester) async {
      await bootSettings(
        tester,
        controls: const AccountControls(canWithdrawConsent: true),
        consents: <ConsentRecord>[
          consent(withdrawnAt: DateTime.utc(2026, 6, 1)),
        ],
        location: '/settings/privacy',
      );

      // The record is the point: removing the row would erase the evidence it
      // exists to provide.
      expect(find.text('Messages about your applications'), findsOneWidget);
      expect(find.textContaining('Withdrawn'), findsOneWidget);
      expect(find.text('Withdraw this consent'), findsNothing);
    });

    testWidgets('a consent the office cannot operate without says why', (
      tester,
    ) async {
      await bootSettings(
        tester,
        controls: const AccountControls(canWithdrawConsent: true),
        consents: <ConsentRecord>[
          consent(
            isWithdrawable: false,
            withheldReason:
                'Taytay LGU needs this to process the application you made.',
          ),
        ],
        location: '/settings/privacy',
      );

      expect(find.text('Withdraw this consent'), findsNothing);
      expect(
        find.textContaining('needs this to process the application'),
        findsOneWidget,
      );
    });

    testWidgets('withdrawing is confirmed and keyed', (tester) async {
      final booted = await bootSettings(
        tester,
        controls: const AccountControls(canWithdrawConsent: true),
        consents: <ConsentRecord>[consent()],
        location: '/settings/privacy',
      );

      await tester.tap(find.text('Withdraw this consent'));
      await tester.pumpAndSettle();

      expect(find.text('What happens'), findsOneWidget);
      expect(find.textContaining('not backdated'), findsOneWidget);

      await tester.tap(find.text('Withdraw it'));
      await tester.pumpAndSettle();

      expect(booted.controls.withdrawn, <String>['c-notify']);
      expect(booted.controls.withdrawKeys.single, isNotEmpty);
      expect(find.textContaining('recorded your withdrawal'), findsOneWidget);
    });

    testWidgets('a failed withdrawal says nothing changed', (tester) async {
      final booted = await bootSettings(
        tester,
        controls: const AccountControls(canWithdrawConsent: true),
        consents: <ConsentRecord>[consent()],
        location: '/settings/privacy',
      );
      booted.controls.withdrawFails = true;

      await tester.tap(find.text('Withdraw this consent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Withdraw it'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing has changed'), findsOneWidget);
    });

    testWidgets('an unavailable consent history does not read as an error', (
      tester,
    ) async {
      await bootSettings(
        tester,
        controls: AccountControls.none,
        location: '/settings/privacy',
      );

      expect(find.textContaining('has not switched on'), findsOneWidget);
    });
  });

  // ── Privacy of copy ─────────────────────────────────────────────────────

  group('Copy', () {
    testWidgets('no server message reaches a resident', (tester) async {
      await bootSettings(
        tester,
        controls: AccountControls.none,
        location: '/settings/privacy',
      );

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join(' ');

      expect(rendered.toLowerCase(), isNot(contains('server')));
      expect(rendered, isNot(contains('500')));
      expect(rendered.toLowerCase(), isNot(contains('exception')));
    });

    testWidgets('settings stay usable at the largest text size', (
      tester,
    ) async {
      await bootSettings(
        tester,
        level: AccessLevel.verified,
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 8000),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  // ── Sign out ────────────────────────────────────────────────────────────

  group('Sign out', () {
    testWidgets('is confirmed, and dismissing keeps the session', (
      tester,
    ) async {
      final booted = await bootSettings(tester, level: AccessLevel.verified);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing you have sent'), findsOneWidget);

      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();

      expect(
        booted.dependencies.session.state.accessLevel,
        AccessLevel.verified,
      );
    });
  });

  // ── Types ───────────────────────────────────────────────────────────────

  group('AccountControls', () {
    test('defaults to allowing nothing', () {
      const controls = AccountControls();
      expect(controls.canRequestDataCorrection, isFalse);
      expect(controls.canRequestDeactivation, isFalse);
      expect(controls.canRequestDeletion, isFalse);
      expect(controls.canWithdrawConsent, isFalse);
      expect(controls.requiresReauthentication, isFalse);
      expect(controls.deletionPolicyNote, isNull);
      expect(controls.hasAnyAccountRequest, isFalse);
    });

    test('toString carries no policy note', () {
      const controls = AccountControls(
        deletionPolicyNote: 'Kept for ten years under municipal rule.',
      );
      expect(controls.toString(), isNot(contains('municipal rule')));
    });
  });

  group('ConsentRecord', () {
    test('is active until it is withdrawn', () {
      expect(consent().isActive, isTrue);
      expect(consent(withdrawnAt: fixedGrant).isActive, isFalse);
    });

    test('toString carries no statement', () {
      expect(
        consent(statement: 'A long sentence about processing.').toString(),
        isNot(contains('processing')),
      );
    });
  });
}
