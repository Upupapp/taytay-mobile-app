import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/links/external_link_service.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/events/domain/event_repository.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/domain/home_emphasis.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/news/domain/announcement_repository.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/services/domain/assistance_case.dart';
import 'package:taytay_resident/features/services/domain/assistance_history.dart';
import 'package:taytay_resident/features/services/domain/assistance_intake.dart';
import 'package:taytay_resident/features/services/domain/service_request_repository.dart';
import 'package:taytay_resident/features/verification/domain/correctable_field.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';

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
    String? category,
  }) async =>
      Ok<Paginated<Announcement>>(Paginated<Announcement>.single(items));

  @override
  Future<Result<Announcement>> loadAnnouncement(String id) async =>
      const Err<Announcement>(ServerFailure());

  @override
  Future<Result<List<NewsCategory>>> listCategories() async =>
      const Ok<List<NewsCategory>>(NewsCategory.catalogue);

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

/// Counts notification reads. Home must not call this for a guest.
class CountingNotificationRepository implements NotificationRepository {
  int listCalls = 0;

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 20,
  }) async {
    listCalls++;
    return const Err<Paginated<ResidentNotification>>(ServerFailure());
  }

  @override
  Future<Result<void>> markRead(String id) async => const Ok<void>(null);

  @override
  Future<Result<void>> markAllRead() async => const Ok<void>(null);

  @override
  Future<Result<NotificationPreferences>> loadPreferences() async =>
      const Err<NotificationPreferences>(ServerFailure());

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async => const Ok<void>(null);

  @override
  Future<Result<String>> registerPushToken(String token) async =>
      const Err<String>(ServerFailure());
}

AppConfig config({String dataMode = ''}) => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
  rawDataMode: dataMode,
);

typedef Booted = ({
  AppDependencies dependencies,
  CountingRequestRepository requests,
  CountingVerificationRepository verification,
  CountingNotificationRepository notifications,
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
  String dataMode = '',
  ExternalLinkService? links,
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
  final notifications = CountingNotificationRepository();

  final base = AppDependencies.build(
    config: config(dataMode: dataMode),
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
    externalLinks: links ?? base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: notifications,
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
    notifications: notifications,
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
    test('every level gets the same public sections, in one order', () {
      const order = <HomeSection>[
        HomeSection.greeting,
        HomeSection.carousel,
        HomeSection.quickActions,
        HomeSection.news,
        HomeSection.hotline,
      ];
      for (final level in AccessLevel.values) {
        final sections = HomeEmphasis.forLevel(level).sections;
        expect(
          sections.where((section) => section != HomeSection.statusCard),
          orderedEquals(order),
          reason: level.name,
        );
      }
    });

    test('only an unverified resident and a guest get a status card', () {
      expect(
        HomeEmphasis.forLevel(
          AccessLevel.verified,
        ).contains(HomeSection.statusCard),
        isFalse,
      );
      expect(
        HomeEmphasis.forLevel(AccessLevel.guest).sections.first,
        HomeSection.greeting,
      );
      expect(
        HomeEmphasis.forLevel(
          AccessLevel.guest,
        ).contains(HomeSection.statusCard),
        isTrue,
      );
      expect(
        HomeEmphasis.forLevel(
          AccessLevel.unverified,
        ).contains(HomeSection.statusCard),
        isTrue,
      );
    });

    test('no level is offered a personal section — acceptance 3', () {
      for (final level in AccessLevel.values) {
        expect(
          HomeEmphasis.forLevel(level).personalSections,
          isEmpty,
          reason: level.name,
        );
      }
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

      expect(find.textContaining(', Bisita!'), findsOneWidget);
      expect(find.text('Browsing as guest'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Ano ang kailangan mo?'), findsOneWidget);
    });

    testWidgets('Create account is the full label on one line', (tester) async {
      await bootHome(tester, size: const Size(390, 844));

      final Text label = tester.widget<Text>(find.text('Create account'));
      expect(label.style?.fontSize, 14);
      expect(label.style?.fontWeight, FontWeight.w800);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
      expect(label.maxLines, 1);

      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.text('Create account'),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.text.toPlainText(), 'Create account');
      // The full label is one line, and its glyphs sit inside the button.
      final List<TextBox> boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 14),
      );
      expect(boxes, isNotEmpty);
      expect(boxes.map((TextBox box) => box.top.round()).toSet(), hasLength(1));
      final double right = boxes
          .map((TextBox box) => box.right)
          .reduce((double a, double b) => a > b ? a : b);
      expect(right, lessThanOrEqualTo(paragraph.size.width + 0.01));
      expect(
        paragraph.size.width + 0.01,
        greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
      );

      final Padding padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('Create account'),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect((padding.padding as EdgeInsets).horizontal, 28);
    });

    testWidgets('the sign-in invitation is present but not coercive', (
      tester,
    ) async {
      await bootHome(tester);

      expect(find.text('Browsing as guest'), findsOneWidget);
      expect(find.text('Sign up to message offices.'), findsOneWidget);
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

      expect(find.text('Latest Balita'), findsOneWidget);
      expect(find.text('Water interruption advisory'), findsOneWidget);
      expect(find.text('Medical mission'), findsNothing);
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
      expect(booted.notifications.listCalls, 0);
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
      expect(find.textContaining(', Ana!'), findsOneWidget);

      await booted.dependencies.session.signOut();
      await tester.pumpAndSettle();

      final rendered = renderedText(tester);
      expect(rendered, isNot(contains('ana')));
      expect(rendered, contains('bisita'));
    });
  });

  group('Home answers "what can I do now?" — acceptance 1', () {
    testWidgets('an unverified resident is told the one step left', (
      tester,
    ) async {
      await bootHome(tester, level: AccessLevel.unverified);

      expect(find.text('Verification pending'), findsOneWidget);
      expect(
        find.textContaining('Messaging offices unlocks once verified.'),
        findsOneWidget,
      );
    });

    testWidgets('a verified resident has no status card', (tester) async {
      await bootHome(tester, level: AccessLevel.verified);

      expect(find.text('Verification pending'), findsNothing);
      expect(find.text('Browsing as guest'), findsNothing);
      expect(find.textContaining(', Ana!'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);
    });

    testWidgets('the status card follows the session, not a fetched case', (
      tester,
    ) async {
      final booted = await bootHome(
        tester,
        level: AccessLevel.unverified,
        verificationDetail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.needsMoreInformation,
          rawState: 'needs_info',
        ),
      );

      // Home does not read the verification case. The card is the session.
      expect(booted.verification.statusCalls, 0);
      expect(find.text('Verification pending'), findsOneWidget);
      expect(find.text('More information needed'), findsNothing);
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

      expect(find.text('Latest Balita'), findsNothing);
      expect(find.text('Coming up in Taytay'), findsNothing);
      expect(find.text('Ano ang kailangan mo?'), findsOneWidget);
      expect(find.text('Browsing as guest'), findsOneWidget);
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
      expect(find.textContaining(', Bisita!'), findsOneWidget);
    });

    testWidgets('Home renders on a wide surface beside the rail', (
      tester,
    ) async {
      await bootHome(tester, size: const Size(1000, 1200));

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.textContaining(', Bisita!'), findsOneWidget);
    });

    testWidgets('the carousel stays put unless a test arms autoplay', (
      tester,
    ) async {
      await _pumpCarousel(tester, autoplay: false, reduced: false);
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page ?? 0,
        closeTo(0, 0.01),
      );

      await tester.pump(const Duration(seconds: 6));
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page ?? 0,
        closeTo(0, 0.01),
      );
    });

    testWidgets('autoplay advances when a test arms it', (tester) async {
      await _pumpCarousel(tester, autoplay: true, reduced: false);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, 0.01),
      );
    });

    testWidgets('reduced motion pauses autoplay', (tester) async {
      await _pumpCarousel(tester, autoplay: true, reduced: true);
      await tester.pump(const Duration(seconds: 6));
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page ?? 0,
        closeTo(0, 0.01),
      );
    });

    testWidgets('a reused canvas still honours a new initial slide', (
      tester,
    ) async {
      Future<void> show(int slide) {
        return tester.pumpWidget(
          MaterialApp(
            home: HomeCanvas(
              greeting: 'Magandang gabi!',
              slides: _slides,
              initialSlide: slide,
            ),
          ),
        );
      }

      await show(0);
      await tester.pump();
      expect(find.text('First slide'), findsOneWidget);

      await show(1);
      await tester.pump();
      expect(find.text('Second slide'), findsOneWidget);
      expect(find.text('First slide'), findsNothing);
    });

    testWidgets('pull to refresh shows the skeleton line', (tester) async {
      // The skeleton news heading sits below the fold of the default 600 dp
      // test surface, and the list builds children lazily.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeCanvas(
            greeting: 'Magandang gabi, Juana!',
            slides: <HomeSlide>[],
            refreshing: true,
          ),
        ),
      );

      expect(find.text('Updating Balita and advisories…'), findsOneWidget);
      expect(find.text('Magandang gabi, Juana!'), findsOneWidget);
      expect(find.text('Ano ang maitutulong namin ngayon?'), findsNothing);
      expect(find.text('Latest Balita'), findsOneWidget);
    });
  });

  group('the bell and the hotline', () {
    testWidgets('a guest bell opens sign-in', (tester) async {
      await bootHome(tester);
      await tester.tap(find.byKey(const Key('home-bell')));
      await tester.pumpAndSettle();

      expect(find.text('Maligayang pagbabalik!'), findsOneWidget);
    });

    testWidgets('a signed-in bell opens the notification centre', (
      tester,
    ) async {
      await bootHome(tester, level: AccessLevel.unverified);
      await tester.tap(find.byKey(const Key('home-bell')));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('a call with no dialer shows a toast', (tester) async {
      await bootHome(
        tester,
        dataMode: 'mock',
        links: const UnavailableExternalLinkService(),
      );
      await tester.scrollUntilVisible(
        find.text('All hotlines'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('All hotlines'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency hotlines'), findsOneWidget);
      await tester.tap(
        find.bySemanticsLabel('Call Sagip Taytay Command Center'),
      );
      await tester.pump();

      expect(
        find.text('This phone has no app that can place a call.'),
        findsOneWidget,
      );
    });
  });
}

const List<HomeSlide> _slides = <HomeSlide>[
  HomeSlide(
    eyebrow: 'BALITA',
    title: 'First slide',
    body: 'One.',
    action: 'Open',
    photoAsset: 'assets/photos/municipal_hall.jpg',
    credit: 'Photo credit',
    routeName: 'news',
  ),
  HomeSlide(
    eyebrow: 'TULONG',
    title: 'Second slide',
    body: 'Two.',
    action: 'Open',
    photoAsset: 'assets/photos/parish_church.jpg',
    credit: 'Photo credit',
    routeName: 'programs',
  ),
];

Future<void> _pumpCarousel(
  WidgetTester tester, {
  required bool autoplay,
  required bool reduced,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData.fromView(
          tester.view,
        ).copyWith(disableAnimations: reduced),
        child: HomeCanvas(
          greeting: 'Magandang gabi!',
          slides: _slides,
          autoplayInTests: autoplay,
        ),
      ),
    ),
  );
  await tester.pump();
}
