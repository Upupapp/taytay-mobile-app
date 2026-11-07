import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/directory/data/office_catalogue.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/messaging/data/office_messaging_gap_repository.dart';
import 'package:taytay_resident/features/messaging/domain/message_send_failure.dart';
import 'package:taytay_resident/features/messaging/domain/office_messaging_repository.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_repository.dart';
import 'package:taytay_resident/features/verification/presentation/unverified_gate_sheet.dart';

AppConfig _mockConfig() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
  rawDataMode: 'mock',
  rawMockLatencyMs: '0',
);

AppConfig _liveConfig() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<Result<ApiHttpResponse>> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> _ok(Object? data) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{
      'data': data,
      'meta': <String, Object?>{
        'request_id': 'req-offices',
        'pagination': <String, Object?>{'has_more': false},
      },
    }),
    headers: const <String, String>{'x-request-id': 'req-offices'},
  ),
);

Map<String, Object?> _officeJson() => <String, Object?>{
  'id': '11111111-1111-1111-1111-111111111111',
  'name': 'Live Treasury',
  'slug': 'treasury',
  'description': 'Pays the cedula.',
  'phone': '8284-4715',
  'category': 'Taxes',
  'created_at': '2026-08-16T02:00:00Z',
  'updated_at': '2026-08-16T02:00:00Z',
};

/// Answers `GET offices/treasury` with a live office, which publishes no
/// topics, and fails everything else as offline.
class _OfficeOnly implements ApiTransport {
  final List<String> paths = <String>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    paths.add(request.path);
    if (request.path == 'offices/treasury') return _ok(_officeJson());
    return const Err<ApiHttpResponse>(NetworkFailure());
  }
}

class _RecordingMessaging implements OfficeMessagingRepository {
  Result<OfficeMessage> sendResult = Ok<OfficeMessage>(
    OfficeMessage(
      id: 'msg-1',
      threadId: 'thread-1',
      body: 'sent',
      sentAt: DateTime.utc(2026, 8, 16),
      fromResident: true,
    ),
  );

  final List<
    ({
      String officeId,
      String topic,
      String body,
      String? mediaId,
      bool hasFile,
    })
  >
  sent =
      <
        ({
          String officeId,
          String topic,
          String body,
          String? mediaId,
          bool hasFile,
        })
      >[];

  final List<String> threadLoads = <String>[];
  final List<String> messageLoads = <String>[];
  final List<String> reads = <String>[];
  final List<String> replies = <String>[];
  final List<String?> cursors = <String?>[];

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async {
    sent.add((
      officeId: officeId,
      topic: topic,
      body: body,
      mediaId: mediaId,
      hasFile: file != null,
    ));
    sendKeys.add(idempotencyKey);
    if (sendAnswers.isNotEmpty) return sendAnswers.removeAt(0);
    return sendResult;
  }

  /// Answers taken in order before [sendResult].
  final List<Result<OfficeMessage>> sendAnswers = <Result<OfficeMessage>>[];

  /// The key each send carried.
  final List<String> sendKeys = <String>[];

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) async {
    threadLoads.add(threadId);
    return Ok(
      OfficeThread(
        id: threadId,
        officeId: 'uuid-treasury',
        officeSlug: 'treasury',
        officeName: 'Treasury',
        topic: 'Cedula',
        preview: 'Where is the cedula desk?',
        updatedAt: DateTime.utc(2026, 8, 16, 2),
        sample: false,
      ),
    );
  }

  @override
  Future<Result<Paginated<OfficeMessage>>> listMessages(
    String threadId, {
    int page = 1,
    int? perPage,
    String? cursor,
  }) async {
    messageLoads.add(threadId);
    cursors.add(cursor);
    return Ok(
      Paginated<OfficeMessage>.single(<OfficeMessage>[
        OfficeMessage(
          id: 'msg-live',
          threadId: threadId,
          body: 'Where is the cedula desk?',
          sentAt: DateTime.utc(2026, 8, 16, 2),
          fromResident: true,
          senderId: 'acct-1',
        ),
      ]),
    );
  }

  @override
  Future<Result<Paginated<OfficeThread>>> listThreads({
    int page = 1,
    int? perPage,
    String? cursor,
  }) async => const Ok(Paginated<OfficeThread>.single(<OfficeThread>[]));

  @override
  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async {
    replies.add(body);
    return sendResult;
  }

  @override
  Future<Result<void>> closeThread(String threadId) async => const Ok(null);

  @override
  Future<Result<void>> markThreadRead(String threadId) async {
    reads.add(threadId);
    return const Ok(null);
  }
}

class _TierProfile implements ResidentProfileRepository {
  _TierProfile(this.tier);

  final String tier;

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async {
    return Ok(ResidentProfileDetail(verificationTier: tier));
  }

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async {
    return Ok(ResidentProfileSummary(verificationTier: tier));
  }

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async => const Ok(null);

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async => const Ok(null);
}

Future<({AppDependencies dependencies, _RecordingMessaging messaging})> _boot(
  WidgetTester tester, {
  AccessLevel level = AccessLevel.verified,
  String location = '/services',
  _RecordingMessaging? messaging,
  ResidentProfileRepository? profile,
  AppConfig? config,
  ApiTransport? transport,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
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
  final base = AppDependencies.build(
    config: config ?? _mockConfig(),
    transport: transport,
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  final _RecordingMessaging recorder = messaging ?? _RecordingMessaging();
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
    residentProfileRepository: profile ?? base.residentProfileRepository,
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
    officeMessaging: recorder,
    onDispose: base.onDispose,
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
  return (dependencies: dependencies, messaging: recorder);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a live catalogue reads GET /offices and GET /offices/{slug}', () async {
    final transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[_officeJson()]),
      _ok(_officeJson()),
    ]);
    final client = ApiClient(
      config: _liveConfig(),
      transport: transport,
      accessTokenProvider: () async => 'tok',
    );

    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load(mock: false, api: client);
    expect(transport.requests.single.path, 'offices');
    expect(transport.requests.single.method, HttpMethod.get);
    expect(transport.requests.single.headers['Authorization'], isNull);
    expect(catalogue.offices.single.id, 'treasury');
    expect(
      catalogue.offices.single.serverId,
      '11111111-1111-1111-1111-111111111111',
    );
    expect(catalogue.offices.single.wireId, catalogue.offices.single.serverId);

    final Office? office = await OfficeCatalogue.byId(
      'treasury',
      mock: false,
      api: client,
    );
    expect(transport.requests.last.path, 'offices/treasury');
    expect(office?.name, 'Live Treasury');
    expect(office?.phone, '8284-4715');
  });

  test('starting a thread posts office_id, subject and body', () async {
    final transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<String, Object?>{
        'thread': <String, Object?>{
          'id': 'thread-live',
          'office_id': '11111111-1111-1111-1111-111111111111',
          'subject': 'Cedula',
          'created_at': '2026-08-16T02:00:00Z',
        },
        'message': <String, Object?>{
          'id': 'msg-live',
          'thread_id': 'thread-live',
          'body': 'Saan po ang pila?',
          'created_at': '2026-08-16T02:00:00Z',
        },
      }),
    ]);
    final client = ApiClient(
      config: _liveConfig(),
      transport: transport,
      accessTokenProvider: () async => 'tok',
    );
    final result = await OfficeMessagingApiRepository(apiClient: client).send(
      officeId: '11111111-1111-1111-1111-111111111111',
      topic: 'Cedula',
      body: 'Saan po ang pila?',
      idempotencyKey: '22222222-2222-4222-8222-222222222222',
    );

    expect(transport.requests.single.method, HttpMethod.post);
    expect(transport.requests.single.path, 'threads');
    expect(transport.requests.single.body, <String, Object?>{
      'office_id': '11111111-1111-1111-1111-111111111111',
      'subject': 'Cedula',
      'body': 'Saan po ang pila?',
      'idempotency_key': '22222222-2222-4222-8222-222222222222',
    });
    expect(result, isA<Ok<OfficeMessage>>());
  });

  test('a thread label uses short_name from GET /offices', () async {
    final transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[
        <String, Object?>{
          'id': 'thread-live',
          'office_id': '11111111-1111-1111-1111-111111111111',
          'office_slug': 'treasury',
          'subject': 'Cedula',
          'created_at': '2026-08-16T02:00:00Z',
          'updated_at': '2026-08-16T02:00:00Z',
        },
      ]),
      _ok(<Object?>[
        <String, Object?>{
          'id': '11111111-1111-1111-1111-111111111111',
          'name': "Municipal Treasurer's Office",
          'slug': 'treasury',
          'short_name': 'Treasury',
          'created_at': '2026-08-16T02:00:00Z',
          'updated_at': '2026-08-16T02:00:00Z',
        },
      ]),
    ]);
    final client = ApiClient(
      config: _liveConfig(),
      transport: transport,
      accessTokenProvider: () async => 'tok',
    );
    final Result<Paginated<OfficeThread>> result =
        await OfficeMessagingApiRepository(apiClient: client).listThreads();
    expect(result, isA<Ok<Paginated<OfficeThread>>>());
    expect(
      (result as Ok<Paginated<OfficeThread>>).value.items.single.officeName,
      'Treasury',
    );
    expect(transport.requests.first.query['limit'], isNotNull);
    expect(transport.requests[1].path, 'offices');
  });

  test('a null short_name falls through to the office name', () async {
    final transport = _Scripted(<Result<ApiHttpResponse>>[
      _ok(<Object?>[
        <String, Object?>{
          'id': 'thread-live',
          'office_id': '11111111-1111-1111-1111-111111111111',
          'office_slug': 'assessor',
          'subject': 'Tax',
          'created_at': '2026-08-16T02:00:00Z',
        },
      ]),
      _ok(<Object?>[
        <String, Object?>{
          'id': '11111111-1111-1111-1111-111111111111',
          'name': 'Municipal Assessor',
          'slug': 'assessor',
          'short_name': null,
          'created_at': '2026-08-16T02:00:00Z',
          'updated_at': '2026-08-16T02:00:00Z',
        },
      ]),
    ]);
    final client = ApiClient(
      config: _liveConfig(),
      transport: transport,
      accessTokenProvider: () async => 'tok',
    );
    final Result<Paginated<OfficeThread>> result =
        await OfficeMessagingApiRepository(apiClient: client).listThreads();
    expect(
      (result as Ok<Paginated<OfficeThread>>).value.items.single.officeName,
      'Municipal Assessor',
    );
  });

  test(
    'the dev mock still reads the fixture and does not call the API',
    () async {
      final transport = _Scripted(<Result<ApiHttpResponse>>[]);
      final client = ApiClient(
        config: _mockConfig(),
        transport: transport,
        accessTokenProvider: () async => null,
      );
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load(mock: true, api: client);
      expect(transport.requests, isEmpty);
      expect(catalogue.offices, hasLength(9));
      final Office? bplo = await OfficeCatalogue.byId('bplo', mock: true);
      expect(bplo?.wireId, 'bplo');
      expect(bplo?.topics, contains('New business registration'));
    },
  );

  testWidgets('the thread loads through the messaging repository', (
    tester,
  ) async {
    final booted = await _boot(tester, location: '/messages/thread-9');

    expect(booted.messaging.threadLoads, <String>['thread-9']);
    expect(booted.messaging.messageLoads, <String>['thread-9']);
    expect(find.textContaining('cedula'), findsOneWidget);
    expect(find.text('Treasury'), findsWidgets);
    expect(find.textContaining('Magandang araw'), findsNothing);
  });

  testWidgets('the sent screen uses the office on the route', (tester) async {
    await _boot(tester, location: '/offices/bplo/message/sent');

    expect(find.textContaining('(02) 8284-4788'), findsOneWidget);
    expect(find.textContaining('0985-488-3352'), findsNothing);
  });

  testWidgets('an empty message is refused and the draft is not sent', (
    tester,
  ) async {
    final booted = await _boot(tester, location: '/offices/bplo/message');

    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();

    expect(find.text('Write a message before sending.'), findsOneWidget);
    expect(booted.messaging.sent, isEmpty);
    expect(find.text('Message sent'), findsNothing);
  });

  testWidgets('compose posts the chosen topic and the typed message', (
    tester,
  ) async {
    final booted = await _boot(tester, location: '/offices/bplo/message');

    await tester.tap(find.byKey(const Key('directory-topic')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New business registration'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('directory-message-field')),
      'Saan po ang pila?',
    );
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();

    expect(booted.messaging.sent, hasLength(1));
    expect(booted.messaging.sent.single.officeId, 'bplo');
    expect(booted.messaging.sent.single.topic, 'New business registration');
    expect(booted.messaging.sent.single.body, 'Saan po ang pila?');
    expect(booted.messaging.sent.single.body, isNot(contains('Magandang')));
    expect(find.text('Message sent'), findsWidgets);
  });

  testWidgets(
    'a first message whose answer was lost keeps its key when sent again',
    (tester) async {
      final _RecordingMessaging messaging = _RecordingMessaging()
        ..sendAnswers.addAll(<Result<OfficeMessage>>[
          const Err<OfficeMessage>(TimeoutFailure(debugMessage: 'operator')),
          const Err<OfficeMessage>(NetworkFailure(mayHaveArrived: true)),
        ]);
      final booted = await _boot(
        tester,
        location: '/offices/bplo/message',
        messaging: messaging,
      );

      await tester.enterText(
        find.byKey(const Key('directory-message-field')),
        'Saan po ang pila?',
      );
      await tester.tap(find.byKey(const Key('directory-send')));
      await tester.pumpAndSettle();

      expect(find.text(MessageAct.start.unconfirmed), findsOneWidget);
      expect(find.textContaining('will not be posted twice'), findsOneWidget);
      expect(find.textContaining('check Messages'), findsOneWidget);
      expect(find.textContaining('Nothing was sent'), findsNothing);
      expect(find.text('operator'), findsNothing);
      expect(find.text('Message sent'), findsNothing);

      await tester.tap(find.byKey(const Key('directory-send')));
      await tester.pumpAndSettle();
      expect(find.text(MessageAct.start.unconfirmed), findsOneWidget);
      await tester.tap(find.byKey(const Key('directory-send')));
      await tester.pumpAndSettle();

      expect(find.text('Message sent'), findsWidgets);
      expect(booted.messaging.sendKeys, hasLength(3));
      expect(booted.messaging.sendKeys.toSet(), hasLength(1));
      expect(
        booted.messaging.sendKeys.first.length,
        36,
        reason: 'a UUID, as the Node API requires',
      );
    },
  );

  testWidgets('other words or another topic are a new message with a new key', (
    tester,
  ) async {
    final _RecordingMessaging messaging = _RecordingMessaging()
      ..sendAnswers.addAll(<Result<OfficeMessage>>[
        const Err<OfficeMessage>(TimeoutFailure()),
        const Err<OfficeMessage>(TimeoutFailure()),
        const Err<OfficeMessage>(TimeoutFailure()),
      ]);
    final booted = await _boot(
      tester,
      location: '/offices/bplo/message',
      messaging: messaging,
    );

    await tester.enterText(
      find.byKey(const Key('directory-message-field')),
      'Saan po',
    );
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('directory-message-field')),
      'Saan po ang pila?',
    );
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('directory-topic')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New business registration'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();

    expect(booted.messaging.sendKeys, hasLength(3));
    expect(booted.messaging.sendKeys.toSet(), hasLength(3));
  });

  testWidgets('a 409 on a first message is said generically, never retried', (
    tester,
  ) async {
    const String serverText =
        'That idempotency key was already used for a different message.';
    final _RecordingMessaging messaging = _RecordingMessaging()
      ..sendAnswers.add(
        const Err<OfficeMessage>(ConflictFailure(debugMessage: serverText)),
      );
    final booted = await _boot(
      tester,
      location: '/offices/bplo/message',
      messaging: messaging,
    );

    await tester.enterText(
      find.byKey(const Key('directory-message-field')),
      'Saan po ang pila?',
    );
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Open Messages to check'), findsOneWidget);
    expect(find.textContaining(serverText), findsNothing);
    expect(find.textContaining('already submitted'), findsNothing);
    // Nothing repeated it behind the resident's back.
    expect(booted.messaging.sendKeys, hasLength(1));

    // The refused key is let go: pressing Send again is a new message.
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();
    expect(booted.messaging.sendKeys, hasLength(2));
    expect(
      booted.messaging.sendKeys.last,
      isNot(booted.messaging.sendKeys.first),
    );
  });

  testWidgets('a live office with no topics sends under a fixed subject', (
    tester,
  ) async {
    final _OfficeOnly transport = _OfficeOnly();
    final booted = await _boot(
      tester,
      location: '/offices/treasury/message',
      config: _liveConfig(),
      transport: transport,
    );

    expect(transport.paths, contains('offices/treasury'));
    expect(find.text(Office.generalTopic), findsOneWidget);
    // Nothing to choose, so the field opens no picker.
    await tester.tap(find.byKey(const Key('directory-topic')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);

    await tester.enterText(
      find.byKey(const Key('directory-message-field')),
      'Saan po ang pila?',
    );
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();

    expect(find.text('Choose a topic before sending.'), findsNothing);
    expect(booted.messaging.sent, hasLength(1));
    expect(
      booted.messaging.sent.single.officeId,
      '11111111-1111-1111-1111-111111111111',
    );
    // The staff inbox lists the subject, so it never carries the message.
    expect(booted.messaging.sent.single.topic, Office.generalTopic);
    expect(booted.messaging.sent.single.body, 'Saan po ang pila?');
  });

  test('the compose subject prefers a published topic', () {
    Office office({String? topic, List<String> topics = const <String>[]}) =>
        Office(
          id: 'x',
          shortName: 'X',
          name: 'X',
          listName: 'X',
          category: '',
          listLine: '',
          icon: OfficeIcon.building2,
          keywords: const <String>[],
          eyebrow: '',
          summary: '',
          heroAsset: '',
          heroFocus: 0.5,
          insetAsset: '',
          representative: false,
          credit: '',
          messageable: true,
          callLabel: 'Call',
          callIsEmergency: false,
          phone: '',
          directionsQuery: '',
          facts: const <OfficeFact>[],
          services: const <OfficeServiceLine>[],
          topic: topic,
          topics: topics,
        );

    expect(office().composeTopic, Office.generalTopic);
    expect(office().offersTopics, isFalse);
    expect(office(topic: '  ').composeTopic, Office.generalTopic);
    expect(office(topic: 'Cedula').composeTopic, 'Cedula');
    expect(
      office(topics: <String>['Permit', 'Renewal']).composeTopic,
      'Permit',
    );
    expect(office(topics: <String>['Permit']).offersTopics, isTrue);
  });

  testWidgets('the office list filters by name and by service', (tester) async {
    await _boot(tester);

    await tester.enterText(find.byType(TextField).first, 'e-BOSS');
    await tester.pumpAndSettle();

    expect(find.textContaining('BPLO'), findsWidgets);
    expect(find.text('MSWDO'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'passport');
    await tester.pumpAndSettle();
    expect(find.textContaining('BPLO'), findsNothing);
    expect(find.text('MSWDO'), findsNothing);
  });

  testWidgets('the search specimen filters both fields', (tester) async {
    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load();
    await tester.pumpWidget(
      MaterialApp(
        home: DirectoryCanvas(
          frame: DirectoryFrame.searchSpecimen,
          offices: catalogue.offices,
          chips: catalogue.chips,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Treasurer'), findsWidgets);
    expect(find.text('No offices found for “passport”'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('directory-search-cedula')),
        matching: find.byType(TextField),
      ),
      'passport',
    );
    await tester.pump();

    expect(find.textContaining('Treasurer'), findsNothing);
    expect(find.textContaining('0 results for “passport”'), findsOneWidget);
  });

  testWidgets('a 403 on send refetches /me and opens the verification gate', (
    tester,
  ) async {
    final messaging = _RecordingMessaging()
      ..sendResult = const Err(ForbiddenFailure());
    final booted = await _boot(
      tester,
      location: '/offices/bplo/message',
      messaging: messaging,
      profile: _TierProfile('pending'),
    );

    expect(booted.dependencies.session.state.accessLevel, AccessLevel.verified);
    await tester.enterText(
      find.byKey(const Key('directory-message-field')),
      'Hello',
    );
    await tester.tap(find.byKey(const Key('directory-send')));
    await tester.pumpAndSettle();

    expect(
      booted.dependencies.session.state.accessLevel,
      AccessLevel.unverified,
    );
    expect(find.byType(UnverifiedGateSheet), findsOneWidget);
    expect(find.text('Verify your account to message offices'), findsOneWidget);
    expect(find.text('Message sent'), findsNothing);
  });

  testWidgets('a guest who taps Message is sent to sign in', (tester) async {
    await _boot(tester, level: AccessLevel.guest, location: '/offices/bplo');

    await tester.tap(find.byKey(const Key('directory-message')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.byType(UnverifiedGateSheet), findsNothing);
    expect(find.text('Verify your account to message offices'), findsNothing);
  });

  testWidgets('a signed-in unverified resident gets the verification gate', (
    tester,
  ) async {
    await _boot(
      tester,
      level: AccessLevel.unverified,
      location: '/offices/bplo',
    );

    await tester.tap(find.byKey(const Key('directory-message')));
    await tester.pumpAndSettle();

    expect(find.byType(UnverifiedGateSheet), findsOneWidget);
    expect(find.text('Verify your account to message offices'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsNothing);
  });
}
