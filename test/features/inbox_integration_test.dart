import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_pages.dart';
import 'package:taytay_resident/features/messaging/data/office_messaging_gap_repository.dart';
import 'package:taytay_resident/features/messaging/domain/office_messaging_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String mediaId = '11111111-1111-4111-8111-111111111111';

  group('the thread routes', () {
    test('a page sends limit and the next page sends the cursor', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(<Object?>[_threadJson('thread-1')], cursor: 'page-2', more: true),
        _ok(<Object?>[_officeJson()]),
        _ok(<Object?>[_threadJson('thread-2')]),
        _ok(<Object?>[_officeJson()]),
      ]);
      final OfficeMessagingApiRepository repository =
          OfficeMessagingApiRepository(apiClient: _client(transport));

      final Result<Paginated<OfficeThread>> first = await repository
          .listThreads();
      final Result<Paginated<OfficeThread>> second = await repository
          .listThreads(cursor: 'page-2');

      expect(transport.requests[0].path, 'threads');
      expect(transport.requests[0].query['limit'], '25');
      expect(transport.requests[0].query.containsKey('cursor'), isFalse);
      final Paginated<OfficeThread> firstPage =
          (first as Ok<Paginated<OfficeThread>>).value;
      expect(firstPage.nextCursor, 'page-2');
      expect(firstPage.hasMore, isTrue);
      expect(transport.requests[2].query['cursor'], 'page-2');
      final Paginated<OfficeThread> secondPage =
          (second as Ok<Paginated<OfficeThread>>).value;
      expect(secondPage.items.single.id, 'thread-2');
      expect(secondPage.hasMore, isFalse);
    });

    test('messages page with the cursor and keep attachments', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(
          <Object?>[
            _messageJson('m1', attachments: <String>[mediaId]),
          ],
          cursor: 'older',
          more: true,
        ),
        _ok(<Object?>[_messageJson('m2')]),
      ]);
      final OfficeMessagingApiRepository repository =
          OfficeMessagingApiRepository(apiClient: _client(transport));

      final Result<Paginated<OfficeMessage>> first = await repository
          .listMessages('thread-1');
      await repository.listMessages('thread-1', cursor: 'older');

      expect(transport.requests[0].path, 'threads/thread-1/messages');
      expect(transport.requests[0].query['limit'], '25');
      expect(transport.requests[0].query.containsKey('cursor'), isFalse);
      expect(transport.requests[1].query['cursor'], 'older');
      final OfficeMessage message =
          (first as Ok<Paginated<OfficeMessage>>).value.items.single;
      expect(message.attachments.single.mediaId, mediaId);
      expect(message.toString(), 'OfficeMessage(m1)');
      expect(message.attachments.single.toString(), 'MessageAttachment');
    });

    test('a reply with media_id is JSON and does not upload', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(_envelope('reply-1')),
      ]);
      final Result<OfficeMessage> result = await OfficeMessagingApiRepository(
        apiClient: _client(transport),
      ).reply(threadId: 'thread-1', body: 'Saan po', mediaId: mediaId);

      expect(transport.requests.single.method, HttpMethod.post);
      expect(transport.requests.single.path, 'threads/thread-1/messages');
      expect(transport.requests.single.file, isNull);
      expect(transport.requests.single.body, <String, Object?>{
        'body': 'Saan po',
        'media_id': mediaId,
      });
      expect(result, isA<Ok<OfficeMessage>>());
    });

    test('a reply with a file uses multipart and drops media_id', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(_envelope('reply-2')),
      ]);
      final OutgoingFile file = OutgoingFile(
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        fileName: 'Juana Dela Cruz.pdf',
        mimeType: 'application/pdf',
      );
      await OfficeMessagingApiRepository(apiClient: _client(transport)).reply(
        threadId: 'thread-1',
        body: 'Ito po',
        mediaId: mediaId,
        file: file,
      );

      final MultipartFile? part = transport.requests.single.file;
      expect(part?.field, 'file');
      expect(part?.filename, 'Juana Dela Cruz.pdf');
      expect(part?.mimeType, 'application/pdf');
      expect(transport.requests.single.body, <String, Object?>{
        'body': 'Ito po',
      });
      expect(file.toString(), isNot(contains('Juana')));
    });

    test('starting a thread can send media_id or a file', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(_envelope('made-1')),
        _ok(_envelope('made-2')),
      ]);
      final OfficeMessagingApiRepository repository =
          OfficeMessagingApiRepository(apiClient: _client(transport));

      await repository.send(
        officeId: 'office-1',
        topic: 'Cedula',
        body: 'Saan po',
        mediaId: mediaId,
      );
      await repository.send(
        officeId: 'office-1',
        topic: 'Cedula',
        body: 'Ito po',
        mediaId: mediaId,
        file: OutgoingFile(
          bytes: Uint8List.fromList(<int>[9]),
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
        ),
      );

      expect(transport.requests[0].path, 'threads');
      expect(transport.requests[0].file, isNull);
      expect(transport.requests[0].body, <String, Object?>{
        'office_id': 'office-1',
        'subject': 'Cedula',
        'body': 'Saan po',
        'media_id': mediaId,
      });
      expect(transport.requests[1].file?.field, 'file');
      expect(transport.requests[1].body, <String, Object?>{
        'office_id': 'office-1',
        'subject': 'Cedula',
        'body': 'Ito po',
      });
    });

    test('an empty file is refused before a request', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[]);
      final Result<OfficeMessage> result =
          await OfficeMessagingApiRepository(apiClient: _client(transport))
              .reply(
                threadId: 'thread-1',
                body: 'Saan po',
                file: OutgoingFile(
                  bytes: Uint8List(0),
                  fileName: 'empty.pdf',
                  mimeType: 'application/pdf',
                ),
              );

      expect(transport.requests, isEmpty);
      expect(result, isA<Err<OfficeMessage>>());
    });

    test('read and close post to the thread', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(_threadJson('thread-1')),
        _ok(_threadJson('thread-1')),
      ]);
      final OfficeMessagingApiRepository repository =
          OfficeMessagingApiRepository(apiClient: _client(transport));

      expect(await repository.markThreadRead('thread-1'), isA<Ok<void>>());
      expect(await repository.closeThread('thread-1'), isA<Ok<void>>());
      expect(transport.requests[0].path, 'threads/thread-1/read');
      expect(transport.requests[1].path, 'threads/thread-1/close');
      expect(transport.requests[0].method, HttpMethod.post);
    });
  });

  group('the account thread', () {
    testWidgets('opening marks the thread read and a reply posts the text', (
      tester,
    ) async {
      final _Desk desk = _Desk();
      await _pumpThread(tester, desk);

      expect(desk.reads, <String>['thread-1']);
      expect(find.text('Write a message before sending.'), findsNothing);

      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();
      expect(find.text('Write a message before sending.'), findsOneWidget);
      expect(desk.replies, isEmpty);

      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Saan po ang pila?',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      expect(desk.replies.single.body, 'Saan po ang pila?');
      expect(desk.replies.single.mediaId, isNull);
      expect(desk.replies.single.file, isNull);
      expect(find.text('Saan po ang pila?'), findsOneWidget);
    });

    testWidgets('an existing attachment is sent as media_id', (tester) async {
      final _Desk desk = _Desk(
        messages: <OfficeMessage>[
          OfficeMessage(
            id: 'm1',
            threadId: 'thread-1',
            body: 'A synthetic note.',
            sentAt: DateTime.utc(2026, 10, 1),
            fromResident: false,
            attachments: const <MessageAttachment>[
              MessageAttachment(mediaId: mediaId),
            ],
          ),
        ],
      );
      await _pumpThread(tester, desk);

      expect(find.text(mediaId), findsNothing);
      await tester.tap(find.byKey(const Key('thread-media-$mediaId')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Ito po',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      expect(desk.replies.single.mediaId, mediaId);
      expect(desk.replies.single.file, isNull);
    });

    testWidgets('a new file is sent as file and a refusal stays on screen', (
      tester,
    ) async {
      final _Picker picker = _Picker();
      final _Desk desk = _Desk();
      await _pumpThread(tester, desk, picker: picker);

      picker.next = CapturedDocument(
        bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0x00]),
        fileName: 'note.jpg',
        mimeType: 'image/jpeg',
        source: DocumentSource.file,
      );
      await tester.tap(find.byKey(const Key('account-thread-attach')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Ito po',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      expect(desk.replies.single.file?.mimeType, 'image/jpeg');
      expect(desk.replies.single.mediaId, isNull);
      expect(desk.replies.single.file?.bytes, picker.next!.bytes);

      desk.replyFailure = const ValidationFailure(
        debugMessage: 'operator-only text',
      );
      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Ulit',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      expect(find.text('operator-only text'), findsNothing);
      expect(find.textContaining('highlighted details'), findsOneWidget);
    });

    testWidgets('the resident can close their own thread', (tester) async {
      final _Desk desk = _Desk();
      await _pumpThread(tester, desk);

      await tester.tap(find.byKey(const Key('account-thread-close')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Close conversation'),
        ),
      );
      await tester.pumpAndSettle();

      expect(desk.closed, <String>['thread-1']);
      expect(find.text('This conversation is closed.'), findsOneWidget);
      expect(find.byKey(const Key('account-thread-field')), findsNothing);
    });

    testWidgets('the inbox asks for the next cursor', (tester) async {
      tester.view.physicalSize = const Size(300, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final _Desk desk = _Desk(hasMore: true);
      final AppDependencies dependencies = await _dependencies(desk);
      addTearDown(dependencies.dispose);
      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: dependencies,
          child: const MaterialApp(home: MessagesInboxScreen()),
        ),
      );
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      expect(desk.threadCursors, contains('page-2'));
    });
  });
}

Map<String, Object?> _threadJson(String id) => <String, Object?>{
  'id': id,
  'office_id': 'office-1',
  'office_slug': 'treasury',
  'subject': 'Cedula',
  'status': 'open',
  'unread': true,
  'unread_count': 1,
  'last_message_preview': 'A synthetic note.',
  'created_at': '2026-10-01T00:00:00Z',
  'updated_at': '2026-10-01T00:00:00Z',
};

Map<String, Object?> _officeJson() => <String, Object?>{
  'id': 'office-1',
  'name': 'Municipal Treasurer',
  'slug': 'treasury',
  'short_name': 'Treasury',
  'created_at': '2026-10-01T00:00:00Z',
  'updated_at': '2026-10-01T00:00:00Z',
};

Map<String, Object?> _messageJson(
  String id, {
  List<String> attachments = const <String>[],
}) => <String, Object?>{
  'id': id,
  'thread_id': 'thread-1',
  'sender_id': 'acct-1',
  'body': 'A synthetic note.',
  'attachments': <Object?>[
    for (final String media in attachments) <String, String>{'media_id': media},
  ],
  'created_at': '2026-10-01T00:00:00Z',
};

Map<String, Object?> _envelope(String messageId) => <String, Object?>{
  'thread': _threadJson('thread-1'),
  'message': _messageJson(messageId),
};

Result<ApiHttpResponse> _ok(
  Object? data, {
  String? cursor,
  bool more = false,
}) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{
      'data': data,
      'meta': <String, Object?>{
        'request_id': 'req-threads',
        'pagination': <String, Object?>{
          'has_more': more,
          'next_cursor': cursor,
        },
      },
    }),
    headers: const <String, String>{'x-request-id': 'req-threads'},
  ),
);

ApiClient _client(_Scripted transport) => ApiClient(
  config: AppConfig.from(
    rawEnvironment: 'dev',
    rawApiBaseUrl: 'https://example.test/api/v1',
    isReleaseBuild: false,
  ),
  transport: transport,
  accessTokenProvider: () async => 'token',
);

class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<Result<ApiHttpResponse>> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.removeAt(0);
  }
}

class _Reply {
  _Reply({required this.body, this.mediaId, this.file});

  final String body;
  final String? mediaId;
  final OutgoingFile? file;
}

class _Desk implements OfficeMessagingRepository {
  _Desk({List<OfficeMessage>? messages, this.hasMore = false})
    : messages = messages ?? _note;

  static final List<OfficeMessage> _note = <OfficeMessage>[
    OfficeMessage(
      id: 'm1',
      threadId: 'thread-1',
      body: 'A synthetic note.',
      sentAt: DateTime.utc(2026, 10, 1),
      fromResident: false,
    ),
  ];

  final List<OfficeMessage> messages;
  final bool hasMore;
  final List<String> reads = <String>[];
  final List<String> closed = <String>[];
  final List<String?> threadCursors = <String?>[];
  final List<_Reply> replies = <_Reply>[];
  AppFailure? replyFailure;

  OfficeThread get _thread => OfficeThread(
    id: 'thread-1',
    officeId: 'office-1',
    officeName: 'Treasury',
    topic: 'Cedula',
    preview: 'A synthetic note.',
    updatedAt: DateTime.utc(2026, 10, 1),
    status: 'open',
    sample: false,
  );

  @override
  Future<Result<Paginated<OfficeThread>>> listThreads({
    int page = 1,
    int? perPage,
    String? cursor,
  }) async {
    threadCursors.add(cursor);
    if (cursor != null) {
      return Ok<Paginated<OfficeThread>>(
        Paginated<OfficeThread>.single(<OfficeThread>[_thread]),
      );
    }
    return Ok<Paginated<OfficeThread>>(
      Paginated<OfficeThread>(
        items: <OfficeThread>[_thread],
        page: 1,
        perPage: 25,
        total: hasMore ? 2 : 1,
        totalPages: hasMore ? 2 : 1,
        hasMore: hasMore,
        nextCursor: hasMore ? 'page-2' : null,
      ),
    );
  }

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) async =>
      Ok<OfficeThread>(_thread);

  @override
  Future<Result<Paginated<OfficeMessage>>> listMessages(
    String threadId, {
    int page = 1,
    int? perPage,
    String? cursor,
  }) async =>
      Ok<Paginated<OfficeMessage>>(Paginated<OfficeMessage>.single(messages));

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
    String? mediaId,
    OutgoingFile? file,
  }) async => const Err<OfficeMessage>(NetworkFailure());

  @override
  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
    String? mediaId,
    OutgoingFile? file,
  }) async {
    final AppFailure? failure = replyFailure;
    if (failure != null) return Err<OfficeMessage>(failure);
    replies.add(_Reply(body: body, mediaId: mediaId, file: file));
    return Ok<OfficeMessage>(
      OfficeMessage(
        id: 'reply-${replies.length}',
        threadId: threadId,
        body: body,
        sentAt: DateTime.utc(2026, 10, 1, 1),
        fromResident: true,
        attachments: mediaId == null
            ? const <MessageAttachment>[]
            : <MessageAttachment>[MessageAttachment(mediaId: mediaId)],
      ),
    );
  }

  @override
  Future<Result<void>> closeThread(String threadId) async {
    closed.add(threadId);
    return const Ok<void>(null);
  }

  @override
  Future<Result<void>> markThreadRead(String threadId) async {
    reads.add(threadId);
    return const Ok<void>(null);
  }
}

class _Picker implements DocumentPicker {
  CapturedDocument? next;

  @override
  Future<CapturedDocument?> pick(
    DocumentSource source,
    UploadPolicy policy,
  ) async => next;

  @override
  bool supports(DocumentSource source) => source == DocumentSource.file;
}

Future<void> _pumpThread(
  WidgetTester tester,
  _Desk desk, {
  DocumentPicker? picker,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final AppDependencies dependencies = await _dependencies(
    desk,
    picker: picker,
  );
  addTearDown(dependencies.dispose);
  await tester.pumpWidget(
    AppDependenciesScope(
      dependencies: dependencies,
      child: const MaterialApp(home: AccountThreadScreen(threadId: 'thread-1')),
    ),
  );
  await tester.pump();
}

Future<AppDependencies> _dependencies(
  _Desk desk, {
  DocumentPicker? picker,
}) async {
  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  return AppDependencies(
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
    documentPicker: picker ?? const UnavailableDocumentPicker(),
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: base.barangayDirectory,
    platform: base.platform,
    officeMessaging: desk,
    onDispose: base.onDispose,
  );
}
