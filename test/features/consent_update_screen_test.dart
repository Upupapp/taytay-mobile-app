import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/privacy_notice.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';
import 'package:taytay_resident/shared/widgets/consent_check_card.dart';
import 'package:taytay_resident/shared/widgets/legal_text_sheet.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';
import 'package:taytay_resident/shared/widgets/taytay_buttons.dart';
import 'package:taytay_resident/shared/widgets/wave_header.dart';

import '../core/consent_gate_test.dart' show FakeConfig, FakeConsents;
import '../support/layout_matrix.dart';

/// Terms published on 06 Nov 2026 (Manila) as `terms-3`; the Privacy Notice
/// still the server's placeholder, under `privacy-3`.
AppBootstrap _current({
  String terms = 'terms-3',
  String privacy = 'privacy-2',
}) => AppBootstrap(
  service: '',
  apiVersion: '',
  timezone: 'Asia/Manila',
  channel: 'citizen-mobile',
  defaultPageSize: 25,
  minimumVersion: '',
  features: FeatureFlags.none,
  support: SupportContact.none,
  termsVersion: terms,
  privacyVersion: privacy,
  terms: TermsOfUse(
    version: 'terms-3',
    updatedAt: DateTime.utc(2026, 11, 6, 2),
    bodyMarkdown: '# Terms of Use\nSample terms for this test.',
  ),
  privacyNotice: PrivacyNotice(
    version: PublishedText.placeholderVersion,
    updatedAt: DateTime.utc(2026),
    bodyMarkdown: 'This is a placeholder privacy notice.',
  ),
);

Future<AppDependencies> _boot(
  WidgetTester tester, {
  required FakeConsents consents,
  AppBootstrap? current,
  bool signedIn = true,
  TextScaler textScaler = TextScaler.noScaling,
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
  if (signedIn) {
    await store.write(
      const StoredSession(
        resident: ResidentSession(
          accountId: 'acct-sample',
          accessLevel: AccessLevel.verified,
          displayName: 'Ana',
        ),
        accessToken: 'token-sample',
      ),
    );
  }

  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: '',
      isReleaseBuild: false,
      rawDataMode: 'mock',
      rawMockLatencyMs: '0',
    ),
    secrets: secrets,
    sessionStore: store,
  );
  // The base's own gate reads the dev mock, which names no version; it is
  // let go so only the gate under test listens.
  base.consentGate.dispose();
  final AppDependencies dependencies = AppDependencies(
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
    platformRepository: FakeConfig(<Result<AppBootstrap>>[
      Ok<AppBootstrap>(current ?? _current()),
    ]),
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
    accountControlsRepository: consents,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    mockBehavior: base.mockBehavior,
    socialServices: base.socialServiceRepository,
    officeMessaging: base.officeMessagingRepository,
    issuance: base.issuanceRepository,
    passwordClient: base.accountPasswordClient,
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

String _path(WidgetTester tester) => GoRouter.of(
  tester.element(find.byType(Scaffold).first),
).routerDelegate.currentConfiguration.uri.path;

void _go(WidgetTester tester, String location) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Ticks every text the screen asks for that is not ticked yet, then presses
/// "I agree". Each text is its own act (D-208).
Future<void> _agree(WidgetTester tester) async {
  for (final String key in <String>[
    'consent-tick-terms',
    'consent-tick-privacy',
  ]) {
    final Finder tick = find.byKey(Key(key));
    if (tick.evaluate().isEmpty) continue;
    if (tester.widget<ConsentCheckCard>(tick).value) continue;
    await tester.ensureVisible(tick);
    await _tap(tester, tick);
  }
  await tester.ensureVisible(find.byKey(const Key('consent-agree')));
  await _tap(tester, find.byKey(const Key('consent-agree')));
}

FakeConsents _acceptedBefore() =>
    FakeConsents(accepted: <String>['terms-2', 'privacy-2']);

void main() {
  group('a new Terms of Use or Privacy Notice version', () {
    testWidgets('a signed-in resident opening the app is asked first', (
      tester,
    ) async {
      await _boot(tester, consents: _acceptedBefore());

      expect(_path(tester), AppRoute.consentUpdate.path);
      expect(find.text('The Terms of Use have changed'), findsOneWidget);
      expect(
        find.text('The Terms of Use were updated on 06 Nov 2026.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('consent-read-terms')), findsOneWidget);
      expect(find.byKey(const Key('consent-read-privacy')), findsNothing);
      expect(find.text('I agree'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      // A gate, not a page in a stack.
      expect(find.byType(TaytayBackButton), findsNothing);

      // Account features wait until they agree.
      _go(tester, '/account');
      await tester.pumpAndSettle();
      expect(_path(tester), AppRoute.consentUpdate.path);
    });

    testWidgets('the notice fits 360/375/430 dp at 100% and 200% text', (
      tester,
    ) async {
      for (final double width in layoutWidths) {
        for (final double scale in layoutTextScales) {
          // A fresh app each time: the root element is not reused.
          await tester.pumpWidget(const SizedBox.shrink());
          await _boot(
            tester,
            consents: _acceptedBefore(),
            size: Size(width, 800),
            textScaler: TextScaler.linear(scale),
          );
          expect(tester.takeException(), isNull, reason: '$width × $scale');
          expect(find.byType(WaveHeader), findsOneWidget);
          expect(find.byKey(const Key('consent-agree')), findsOneWidget);
        }
      }
    });

    testWidgets('agreeing records the version and continues', (tester) async {
      final FakeConsents consents = _acceptedBefore();
      await _boot(tester, consents: consents);

      await _agree(tester);

      expect(consents.posted, <String>['terms-3']);
      expect(_path(tester), AppRoute.home.path);
      expect(find.text('The Terms of Use have changed'), findsNothing);
      _go(tester, '/account');
      await tester.pumpAndSettle();
      expect(_path(tester), '/account');
    });

    testWidgets('both changed, under one version: both said, one record', (
      tester,
    ) async {
      final FakeConsents consents = _acceptedBefore();
      await _boot(
        tester,
        consents: consents,
        current: _current(terms: '2026-11', privacy: '2026-11'),
      );

      expect(
        find.text('The Terms of Use and the Privacy Notice have changed'),
        findsOneWidget,
      );
      // The Terms text published is `terms-3`, not `2026-11`: no date.
      expect(find.text('The Terms of Use were updated.'), findsOneWidget);
      expect(find.text('The Privacy Notice was updated.'), findsOneWidget);

      await _agree(tester);
      // One version string, two texts: two acts, each with its kind.
      expect(consents.posted, <String>['2026-11', '2026-11']);
      expect(consents.postedKinds, <ConsentKind>[
        ConsentKind.privacy,
        ConsentKind.terms,
      ]);
    });

    testWidgets('each owed text is its own unticked act (D-208)', (
      tester,
    ) async {
      final FakeConsents consents = _acceptedBefore();
      await _boot(
        tester,
        consents: consents,
        current: _current(terms: 'terms-3', privacy: 'privacy-3'),
      );
      final Finder terms = find.byKey(const Key('consent-tick-terms'));
      final Finder privacy = find.byKey(const Key('consent-tick-privacy'));
      expect(tester.widget<ConsentCheckCard>(terms).value, isFalse);
      expect(tester.widget<ConsentCheckCard>(privacy).value, isFalse);
      expect(find.text(termsConsentLabel), findsOneWidget);
      expect(find.text(privacyConsentLabel), findsOneWidget);
      PrimaryButton agree() =>
          tester.widget<PrimaryButton>(find.byKey(const Key('consent-agree')));
      expect(agree().onPressed, isNull);

      await tester.ensureVisible(terms);
      await _tap(tester, terms);
      // One tick is not agreement to both.
      expect(agree().onPressed, isNull);
      await tester.ensureVisible(privacy);
      await _tap(tester, privacy);
      expect(agree().onPressed, isNotNull);
      expect(consents.posted, isEmpty);
    });

    testWidgets('a resident with only the older single tick is asked again', (
      tester,
    ) async {
      final FakeConsents consents = FakeConsents(
        combined: <String>['terms-3', 'privacy-2'],
      );
      await _boot(tester, consents: consents);
      expect(_path(tester), AppRoute.consentUpdate.path);
      expect(
        find.text('The Terms of Use and the Privacy Notice have changed'),
        findsOneWidget,
      );
      await _agree(tester);
      expect(consents.postedKinds, <ConsentKind>[
        ConsentKind.privacy,
        ConsentKind.terms,
      ]);
      expect(_path(tester), AppRoute.home.path);
    });

    testWidgets('a text not written yet still opens, and says so', (
      tester,
    ) async {
      await _boot(
        tester,
        consents: _acceptedBefore(),
        current: _current(terms: 'terms-2', privacy: 'privacy-3'),
      );
      expect(find.text('The Privacy Notice has changed'), findsOneWidget);
      expect(find.text('The Privacy Notice was updated.'), findsOneWidget);

      await _tap(tester, find.byKey(const Key('consent-read-privacy')));
      expect(find.byType(LegalTextSheet), findsOneWidget);
      expect(find.text(privacyNoticeNotPublishedYet), findsOneWidget);
      expect(find.textContaining('placeholder'), findsNothing);
    });

    testWidgets('the published Terms open in the sheet', (tester) async {
      await _boot(tester, consents: _acceptedBefore());
      await _tap(tester, find.byKey(const Key('consent-read-terms')));
      expect(find.byType(LegalTextSheet), findsOneWidget);
      expect(find.text('Sample terms for this test.'), findsOneWidget);
      expect(find.text(termsNotPublishedYet), findsNothing);
    });

    testWidgets('a failed agreement is never called recorded', (tester) async {
      final FakeConsents consents = _acceptedBefore();
      consents.acceptAnswers.add(const Err<ConsentRecord>(TimeoutFailure()));
      await _boot(tester, consents: consents);

      await _agree(tester);

      expect(_path(tester), AppRoute.consentUpdate.path);
      expect(
        find.textContaining(
          'We could not confirm that your agreement was recorded',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Your agreement was recorded'), findsNothing);
      expect(find.textContaining('has recorded'), findsNothing);

      // The server cannot record it: the resident is let in without it.
      await _tap(tester, find.byKey(const Key('consent-continue')));
      expect(_path(tester), AppRoute.home.path);
      expect(consents.held.map((ConsentRecord c) => c.key), <String>[
        'terms-2',
        'privacy-2',
      ]);
    });

    testWidgets('a refused agreement says it was not recorded', (tester) async {
      final FakeConsents consents = _acceptedBefore();
      consents.acceptAnswers.add(
        const Err<ConsentRecord>(ServerFailure(isTemporary: true)),
      );
      await _boot(tester, consents: consents);

      await _agree(tester);
      expect(
        find.textContaining('Your agreement was not recorded.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('consent-continue')), findsOneWidget);

      // Agreeing again goes through.
      await _agree(tester);
      expect(_path(tester), AppRoute.home.path);
    });

    testWidgets('signing out returns to guest browsing', (tester) async {
      final AppDependencies dependencies = await _boot(
        tester,
        consents: _acceptedBefore(),
      );

      await _tap(tester, find.byKey(const Key('consent-sign-out')));

      expect(dependencies.session.state, isA<GuestSession>());
      expect(_path(tester), AppRoute.home.path);
      _go(tester, '/news');
      await tester.pumpAndSettle();
      expect(_path(tester), '/news');
    });

    testWidgets('a failed consents read leaves the app open', (tester) async {
      final FakeConsents consents = _acceptedBefore()
        ..listFailure = const NetworkFailure();
      await _boot(tester, consents: consents);

      expect(_path(tester), AppRoute.home.path);
      expect(find.text('The Terms of Use have changed'), findsNothing);
      _go(tester, '/account');
      await tester.pumpAndSettle();
      expect(_path(tester), '/account');
    });

    testWidgets('a guest is never shown it', (tester) async {
      final FakeConsents consents = FakeConsents();
      await _boot(tester, consents: consents, signedIn: false);

      expect(_path(tester), AppRoute.home.path);
      expect(consents.lists, 0);
    });

    testWidgets('it reads at 200% text and to a screen reader', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _boot(
        tester,
        consents: _acceptedBefore(),
        current: _current(terms: 'terms-3', privacy: 'privacy-3'),
        textScaler: const TextScaler.linear(2),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(
          find.text('The Terms of Use and the Privacy Notice have changed'),
        ),
        isSemantics(isHeader: true),
      );
      for (final String key in <String>[
        'consent-read-terms',
        'consent-read-privacy',
        'consent-agree',
        'consent-sign-out',
      ]) {
        final Finder button = find.byKey(Key(key));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(button),
          isSemantics(isButton: true),
          reason: key,
        );
        final Size size = tester.getSize(button);
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
      }
      // The reading order is the order on screen: what changed, how to read
      // it, then the two ways on.
      final double readTop = tester
          .getTopLeft(find.byKey(const Key('consent-read-terms')))
          .dy;
      final double agreeTop = tester
          .getTopLeft(find.byKey(const Key('consent-agree')))
          .dy;
      final double signOutTop = tester
          .getTopLeft(find.byKey(const Key('consent-sign-out')))
          .dy;
      expect(readTop, lessThan(agreeTop));
      expect(agreeTop, lessThan(signOutTop));
      semantics.dispose();
    });
  });
}
