import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/events/domain/event_repository.dart';
import 'package:taytay_resident/features/home/domain/home_emphasis.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/services/domain/assistance_case.dart';
import 'package:taytay_resident/features/services/domain/assistance_history.dart';
import 'package:taytay_resident/features/services/domain/assistance_intake.dart';
import 'package:taytay_resident/features/services/domain/service_request_repository.dart';
import 'package:taytay_resident/features/verification/domain/correctable_field.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
import 'package:taytay_resident/shared/widgets/next_action_card.dart';

/// Counts every `/me/` read so a test can assert a guest issued none.
class CountingRequestRepository implements ServiceRequestRepository {
  int listCalls = 0;

  @override
  Future<Result<Paginated<ServiceRequest>>> listOwnRequests({
    int page = 1,
    int perPage = 20,
  }) async {
    listCalls++;
    return const Err<Paginated<ServiceRequest>>(ServerFailure());
  }

  @override
  Future<Result<ServiceRequest>> loadOwnRequest(String id) async =>
      const Err<ServiceRequest>(ServerFailure());

  @override
  Future<Result<AssistanceCaseDetail>> loadOwnCase(String id) async =>
      const Err<AssistanceCaseDetail>(ServerFailure());

  @override
  Future<Result<Paginated<AssistanceHistoryEntry>>> listOwnHistory({
    required HistoryScope scope,
    int page = 1,
    int perPage = 25,
  }) async {
    listCalls++;
    return const Err<Paginated<AssistanceHistoryEntry>>(ServerFailure());
  }

  @override
  Future<Result<AssistanceIntakeForm>> loadIntakeForm(
    String serviceCode,
  ) async => const Err<AssistanceIntakeForm>(ServerFailure());

  @override
  Future<Result<ServiceRequest>> submitRequest({
    required String serviceCode,
    required String narrative,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required List<String> attachmentIds,
    required String idempotencyKey,
  }) async => const Err<ServiceRequest>(ServerFailure());

  @override
  Future<Result<void>> cancelOwnRequest({
    required String id,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());
}

/// Counts verification reads for the same reason.
class CountingVerificationRepository implements VerificationRepository {
  CountingVerificationRepository({this.detail});

  VerificationStatusDetail? detail;
  int statusCalls = 0;

  @override
  Future<Result<VerificationStatusDetail>> loadOwnStatusDetail() async {
    statusCalls++;
    final value = detail;
    return value == null
        ? const Err<VerificationStatusDetail>(ServerFailure())
        : Ok<VerificationStatusDetail>(value);
  }

  @override
  Future<Result<VerificationStatus>> loadOwnStatus() async =>
      const Err<VerificationStatus>(ServerFailure());

  @override
  Future<Result<void>> submitCorrections({
    required Map<CorrectableField, String> corrections,
    required String idempotencyKey,
  }) async => const Ok<void>(null);

  @override
  Future<Result<KycDocument>> attachDocument({
    required KycDocumentType type,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String idempotencyKey,
  }) async => const Err<KycDocument>(ServerFailure());

  @override
  Future<Result<List<KycDocument>>> loadDocuments() async =>
      const Ok<List<KycDocument>>(<KycDocument>[]);

  @override
  Future<Result<VerificationStatus>> openCase({
    required KycClaim claim,
    required String idempotencyKey,
  }) async => const Err<VerificationStatus>(ServerFailure());

  @override
  Future<Result<void>> submitForReview({
    required List<String> documentUploadIds,
    required String idempotencyKey,
  }) async => const Ok<void>(null);
}

/// Serves public content so the preview sections can be exercised.
class StubAnnouncementRepository implements AnnouncementRepository {
  StubAnnouncementRepository(this.items);

  final List<Announcement> items;

  @override
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page = 1,
    int perPage = 20,
  }) async =>
      Ok<Paginated<Announcement>>(Paginated<Announcement>.single(items));

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async =>
      const Err<Announcement>(ServerFailure());

  // Home never interacts with a post; these exist to satisfy the contract and
  // decline if anything ever tried.
  @override
  Future<Result<Paginated<PostComment>>> listComments(
    String postId, {
    int page = 1,
    int perPage = 20,
  }) async => const Err<Paginated<PostComment>>(ServerFailure());

  @override
  Future<Result<ReactionOutcome>> setReaction({
    required String postId,
    required ReactionKind reaction,
    required String idempotencyKey,
  }) async => const Err<ReactionOutcome>(ServerFailure());

  @override
  Future<Result<ReactionOutcome>> clearReaction({
    required String postId,
    required String idempotencyKey,
  }) async => const Err<ReactionOutcome>(ServerFailure());

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String body,
    required String idempotencyKey,
    String? parentId,
  }) async => const Err<PostComment>(ServerFailure());

  @override
  Future<Result<void>> deleteOwnComment({
    required String postId,
    required String commentId,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());

  @override
  Future<Result<void>> reportComment({
    required String postId,
    required String commentId,
    required ReportReason reason,
    required String idempotencyKey,
  }) async => const Err<void>(ServerFailure());
}

class StubEventRepository implements EventRepository {
  StubEventRepository(this.items);

  final List<LguEvent> items;

  @override
  Future<Result<Paginated<LguEvent>>> listEvents({
    EventScope scope = EventScope.upcoming,
    int page = 1,
    int perPage = 20,
  }) async => Ok<Paginated<LguEvent>>(Paginated<LguEvent>.single(items));

  @override
  Future<Result<LguEvent>> loadEvent(String id) async =>
      const Err<LguEvent>(ServerFailure());

  @override
  Future<Result<EventRegistrationForm>> loadRegistrationForm(
    String eventId,
  ) async => const Err<EventRegistrationForm>(ServerFailure());

  @override
  Future<Result<RegistrationAttempt>> register({
    required String eventId,
    required Map<String, Object?> answers,
    required List<String> consentKeys,
    required String idempotencyKey,
  }) async => const Err<RegistrationAttempt>(ServerFailure());

  @override
  Future<Result<EventRegistration>> cancelRegistration({
    required String eventId,
    required String registrationId,
    required String idempotencyKey,
  }) async => const Err<EventRegistration>(ServerFailure());
}

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

typedef Booted = ({
  AppDependencies dependencies,
  CountingRequestRepository requests,
  CountingVerificationRepository verification,
});

Future<Booted> bootHome(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.guest,
  List<Announcement> announcements = const <Announcement>[],
  List<LguEvent> events = const <LguEvent>[],
  VerificationStatusDetail? verificationDetail,
  Size size = const Size(400, 1400),
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
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

  final requests = CountingRequestRepository();
  final verification = CountingVerificationRepository(
    detail: verificationDetail,
  );

  final base = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
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
    announcementRepository: StubAnnouncementRepository(announcements),
    eventRepository: StubEventRepository(events),
    residentProfileRepository: base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: verification,
    serviceRequestRepository: requests,
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
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  return (
    dependencies: dependencies,
    requests: requests,
    verification: verification,
  );
}

/// Everything Home currently renders, as one lower-case string.
String renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ')
    .toLowerCase();

void main() {
  group('emphasis is declared, not improvised', () {
    test('every access level gets a hero, an action and a way to the hall', () {
      for (final level in AccessLevel.values) {
        final emphasis = HomeEmphasis.forLevel(level);
        expect(emphasis.contains(HomeSection.hero), isTrue, reason: level.name);
        expect(
          emphasis.contains(HomeSection.nextAction),
          isTrue,
          reason: level.name,
        );
        // The route that works when the software does not.
        expect(
          emphasis.sections.last,
          HomeSection.municipalHall,
          reason: level.name,
        );
      }
    });

    test('public content is offered at every level, in the same order', () {
      for (final level in AccessLevel.values) {
        final sections = HomeEmphasis.forLevel(level).sections;
        expect(sections.contains(HomeSection.services), isTrue);
        expect(
          sections.indexOf(HomeSection.services),
          lessThan(sections.indexOf(HomeSection.news)),
          reason: level.name,
        );
        expect(
          sections.indexOf(HomeSection.news),
          lessThan(sections.indexOf(HomeSection.events)),
          reason: level.name,
        );
      }
    });

    test('a guest is offered no personal section at all — acceptance 3', () {
      expect(
        HomeEmphasis.forLevel(AccessLevel.guest).personalSections,
        isEmpty,
      );
      expect(
        HomeEmphasis.forLevel(AccessLevel.unverified).personalSections,
        isEmpty,
      );
      expect(
        HomeEmphasis.forLevel(AccessLevel.verified).personalSections,
        contains(HomeSection.requests),
      );
    });

    test('what the LGU needs comes before what it announces', () {
      final verified = HomeEmphasis.forLevel(AccessLevel.verified).sections;
      expect(
        verified.indexOf(HomeSection.nextAction),
        lessThan(verified.indexOf(HomeSection.news)),
      );
      expect(
        verified.indexOf(HomeSection.requests),
        lessThan(verified.indexOf(HomeSection.news)),
      );
    });

    test('no section appears twice', () {
      for (final level in AccessLevel.values) {
        final sections = HomeEmphasis.forLevel(level).sections;
        expect(
          sections.toSet(),
          hasLength(sections.length),
          reason: level.name,
        );
      }
    });
  });

  group('guest Home is useful without signing up — acceptance 2', () {
    testWidgets('it welcomes, explains and offers somewhere to go', (
      tester,
    ) async {
      await bootHome(tester);

      expect(find.text('Kumusta!'), findsOneWidget);
      expect(find.textContaining('no account needed'), findsOneWidget);
      // Public content and the always-present fallback.
      expect(find.text('Municipal services'), findsOneWidget);
      expect(find.text('Taytay Municipal Hall'), findsOneWidget);
    });

    testWidgets('the sign-in invitation is present but not coercive', (
      tester,
    ) async {
      await bootHome(tester);

      expect(find.byType(NextActionCard), findsOneWidget);
      expect(find.text('Your Taytay ID, on your phone'), findsOneWidget);
      // Offered, with an equally visible way to decline, and no modal.
      expect(find.text('Just browsing'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('public content still appears for a guest', (tester) async {
      await bootHome(
        tester,
        announcements: <Announcement>[
          const Announcement(
            id: 'a1',
            title: 'Water interruption advisory',
            body: 'Service will pause on Tuesday.',
          ),
        ],
        events: <LguEvent>[
          const LguEvent(
            id: 'e1',
            title: 'Medical mission',
            description: 'Free check-ups.',
            venue: EventVenue(name: 'Barangay hall'),
          ),
        ],
      );

      expect(find.text('Latest from Taytay LGU'), findsOneWidget);
      expect(find.text('Water interruption advisory'), findsOneWidget);
      expect(find.text('Coming up in Taytay'), findsOneWidget);
      expect(find.text('Medical mission'), findsOneWidget);
    });
  });

  group('a guest reads nothing personal — acceptance 3', () {
    testWidgets('no /me/ repository is called', (tester) async {
      final booted = await bootHome(tester);

      // The strongest form of the guarantee: not "nothing was shown" but
      // "nothing was ever fetched", so there is nothing in a cache, a log or a
      // screenshot either.
      expect(booted.requests.listCalls, 0);
      expect(booted.verification.statusCalls, 0);
    });

    testWidgets('no personal wording appears anywhere on the screen', (
      tester,
    ) async {
      await bootHome(tester);
      final rendered = renderedText(tester);

      for (final leak in <String>[
        'your requests',
        'reference',
        'verified',
        'household',
        'acct-',
        'ana',
      ]) {
        expect(rendered, isNot(contains(leak)), reason: leak);
      }
    });

    testWidgets('signing out removes personal content immediately', (
      tester,
    ) async {
      final booted = await bootHome(tester, level: AccessLevel.verified);
      expect(find.textContaining('verified Taytay resident'), findsOneWidget);

      await booted.dependencies.session.signOut();
      await tester.pumpAndSettle();

      final rendered = renderedText(tester);
      expect(rendered, isNot(contains('ana')));
      expect(rendered, contains('no account needed'));
    });
  });

  group('Home answers "what can I do now?" — acceptance 1', () {
    testWidgets('an unverified resident is told the one step left', (
      tester,
    ) async {
      await bootHome(tester, level: AccessLevel.unverified);

      expect(find.byType(NextActionCard), findsOneWidget);
      expect(find.text('One step to go'), findsOneWidget);
      expect(find.text('Check my status'), findsOneWidget);
    });

    testWidgets('a verified resident is pointed at their ID', (tester) async {
      await bootHome(
        tester,
        level: AccessLevel.verified,
        verificationDetail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.verified,
          rawState: 'approved',
        ),
      );

      expect(find.text('Open my digital ID'), findsOneWidget);
    });

    testWidgets('a flagged verification says so, in the LGU words', (
      tester,
    ) async {
      await bootHome(
        tester,
        level: AccessLevel.unverified,
        verificationDetail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.needsMoreInformation,
          rawState: 'needs_info',
        ),
      );

      // Reuses TAB 08's vocabulary rather than re-deriving status, so Home and
      // the verification screen cannot disagree.
      expect(find.text('More information needed'), findsOneWidget);
    });

    testWidgets('exactly one next-action card, never a wall of them', (
      tester,
    ) async {
      for (final level in AccessLevel.values) {
        await bootHome(tester, level: level);
        expect(find.byType(NextActionCard), findsOneWidget, reason: level.name);
      }
    });
  });

  group('it is not a dashboard', () {
    testWidgets('no counts, percentages or progress rings appear', (
      tester,
    ) async {
      await bootHome(
        tester,
        level: AccessLevel.verified,
        announcements: <Announcement>[
          const Announcement(id: 'a1', title: 'Advisory', body: 'Body.'),
        ],
      );

      final rendered = renderedText(tester);
      // No fabricated figures: this app has no authoritative source for any of
      // them, and an invented number on a government service is worse than none.
      expect(rendered, isNot(matches(RegExp(r'\b\d+\s*(pending|new|unread)'))));
      expect(rendered, isNot(contains('%')));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('no turnaround promise appears on Home', (tester) async {
      await bootHome(tester, level: AccessLevel.unverified);
      final rendered = renderedText(tester);

      expect(
        rendered,
        isNot(matches(RegExp(r'\b\d+\s*(day|days|week|weeks)\b'))),
      );
      expect(rendered, isNot(contains('guarantee')));
    });

    test('no Home source file fabricates sample content', () {
      // A sample announcement on a municipal app is a fabricated statement by a
      // local government; a sample event sends people to a hall on a date that
      // was never announced.
      final offenders = <String>[];
      for (final file
          in Directory('lib/features/home')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file
            .readAsStringSync()
            .split('\n')
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        for (final pattern in <RegExp>[
          RegExp(r'\bLguEvent\('),
          RegExp(r'\bAnnouncement\('),
          RegExp(r'\bServiceRequest\('),
        ]) {
          if (pattern.hasMatch(source)) offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('missing content is absent, not apologetic', () {
    testWidgets('an unavailable section disappears rather than apologising', (
      tester,
    ) async {
      // No announcements and no events: the declining default repositories.
      await bootHome(tester);

      expect(find.text('Latest from Taytay LGU'), findsNothing);
      expect(find.text('Coming up in Taytay'), findsNothing);
      // What never disappears is what keeps Home worth opening.
      expect(find.text('Municipal services'), findsOneWidget);
      expect(find.text('Taytay Municipal Hall'), findsOneWidget);
      expect(find.byType(NextActionCard), findsOneWidget);
    });

    testWidgets('a verified resident with no requests sees no empty box', (
      tester,
    ) async {
      await bootHome(tester, level: AccessLevel.verified);
      expect(find.text('Your requests'), findsNothing);
    });
  });

  group('accessibility and responsiveness', () {
    testWidgets('Home survives a 200% text scale', (tester) async {
      await bootHome(
        tester,
        textScaler: const TextScaler.linear(2),
        size: const Size(400, 2400),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Kumusta!'), findsOneWidget);
    });

    testWidgets('Home renders on a wide surface beside the rail', (
      tester,
    ) async {
      await bootHome(tester, size: const Size(1000, 1200));

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Kumusta!'), findsOneWidget);
    });

    testWidgets('the hero animates only when motion is allowed', (
      tester,
    ) async {
      await bootHome(tester);
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });

    testWidgets('the hero does not animate under reduced motion', (
      tester,
    ) async {
      // The hero's fade is decorative, so reduced motion removes it entirely
      // rather than shortening it. It is the most repeated animation in the app
      // — every visit to Home — and so the one most worth suppressing.
      await bootHome(tester, disableAnimations: true);

      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(find.text('Kumusta!'), findsOneWidget);
    });
  });
}
