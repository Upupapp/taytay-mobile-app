import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/page_policy.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/documents/upload_policy.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_pages.dart';
import 'package:taytay_resident/features/messaging/data/office_messaging_gap_repository.dart';
import 'package:taytay_resident/features/messaging/domain/message_send_failure.dart';
import 'package:taytay_resident/features/messaging/domain/office_messaging_repository.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String mediaId = '11111111-1111-4111-8111-111111111111';
  const String key = '22222222-2222-4222-8222-222222222222';

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
      expect(firstPage.items.single.ownerAccountId, 'acct-1');
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
      final Result<OfficeMessage> result =
          await OfficeMessagingApiRepository(
            apiClient: _client(transport),
          ).reply(
            threadId: 'thread-1',
            body: 'Saan po',
            idempotencyKey: key,
            mediaId: mediaId,
          );

      expect(transport.requests.single.method, HttpMethod.post);
      expect(transport.requests.single.path, 'threads/thread-1/messages');
      expect(transport.requests.single.file, isNull);
      expect(transport.requests.single.body, <String, Object?>{
        'body': 'Saan po',
        'media_id': mediaId,
        'idempotency_key': key,
      });
      // The header the server ignores, for the transport's own retry.
      expect(transport.requests.single.headers['Idempotency-Key'], key);
      expect(result, isA<Ok<OfficeMessage>>());
    });

    test('a reply with a file uses multipart and drops media_id', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(_envelope('reply-2')),
      ]);
      final OutgoingFile file = OutgoingFile(
        bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x0A]),
        fileName: 'Juana Dela Cruz.pdf',
        mimeType: 'application/pdf',
      );
      await OfficeMessagingApiRepository(apiClient: _client(transport)).reply(
        threadId: 'thread-1',
        body: 'Ito po',
        idempotencyKey: key,
        mediaId: mediaId,
        file: file,
      );

      final MultipartFile? part = transport.requests.single.file;
      expect(part?.field, 'file');
      expect(part?.filename, 'Juana Dela Cruz.pdf');
      expect(part?.mimeType, 'application/pdf');
      // With a file the body becomes multipart fields, the key among them.
      expect(transport.requests.single.body, <String, Object?>{
        'body': 'Ito po',
        'idempotency_key': key,
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
        idempotencyKey: key,
        mediaId: mediaId,
      );
      await repository.send(
        officeId: 'office-1',
        topic: 'Cedula',
        body: 'Ito po',
        idempotencyKey: '33333333-3333-4333-8333-333333333333',
        mediaId: mediaId,
        file: OutgoingFile(
          bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0x00]),
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
        'idempotency_key': key,
      });
      expect(transport.requests[0].headers['Idempotency-Key'], key);
      expect(transport.requests[1].file?.field, 'file');
      expect(transport.requests[1].body, <String, Object?>{
        'office_id': 'office-1',
        'subject': 'Cedula',
        'body': 'Ito po',
        'idempotency_key': '33333333-3333-4333-8333-333333333333',
      });
    });

    test(
      'a replayed send answers 200 or 201, and both are the message',
      () async {
        // The server answers a repeat with the first message: 201 when that
        // message opened the thread, 200 when it joined one already open.
        final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
          _ok(_envelope('made-1'), status: 201),
          _ok(_envelope('made-1')),
        ]);
        final OfficeMessagingApiRepository repository =
            OfficeMessagingApiRepository(apiClient: _client(transport));

        final List<Result<OfficeMessage>> answers = <Result<OfficeMessage>>[
          for (int i = 0; i < 2; i++)
            await repository.send(
              officeId: 'office-1',
              topic: 'Cedula',
              body: 'Saan po',
              idempotencyKey: key,
            ),
        ];

        for (final Result<OfficeMessage> answer in answers) {
          expect(answer.valueOrNull?.id, 'made-1');
        }
        expect(
          transport.requests.map((ApiRequest r) => r.body),
          everyElement(containsPair('idempotency_key', key)),
        );
      },
    );

    test('an empty file is refused before a request', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[]);
      final Result<OfficeMessage> result =
          await OfficeMessagingApiRepository(
            apiClient: _client(transport),
          ).reply(
            threadId: 'thread-1',
            body: 'Saan po',
            idempotencyKey: key,
            file: OutgoingFile(
              bytes: Uint8List(0),
              fileName: 'empty.pdf',
              mimeType: 'application/pdf',
            ),
          );

      expect(transport.requests, isEmpty);
      expect(result, isA<Err<OfficeMessage>>());
    });

    test('has_more false stops the page even when a cursor is named', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(<Object?>[_threadJson('thread-1')], cursor: 'unused', more: false),
        _ok(<Object?>[_officeJson()]),
      ]);
      final Result<Paginated<OfficeThread>> result =
          await OfficeMessagingApiRepository(
            apiClient: _client(transport),
          ).listThreads();
      final Paginated<OfficeThread> page =
          (result as Ok<Paginated<OfficeThread>>).value;
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, 'unused');
    });

    test('a channel page larger than 50 is capped at 50', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        _ok(<Object?>[_threadJson('thread-1')]),
        _ok(<Object?>[_officeJson()]),
      ]);
      final ApiClient client = _client(transport)..pages = PagePolicy.adopt(80);
      await OfficeMessagingApiRepository(apiClient: client).listThreads();
      expect(transport.requests.first.query['limit'], '50');
    });

    test(
      'an attachment over 8 MB or of the wrong type is not uploaded',
      () async {
        final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[]);
        final OfficeMessagingApiRepository repository =
            OfficeMessagingApiRepository(apiClient: _client(transport));
        final Uint8List tooBig = Uint8List(UploadPolicy.fallback.maxBytes + 1);
        tooBig[0] = 0xFF;
        tooBig[1] = 0xD8;
        tooBig[2] = 0xFF;

        final Result<OfficeMessage> large = await repository.reply(
          threadId: 'thread-1',
          body: 'Saan po',
          idempotencyKey: key,
          file: OutgoingFile(
            bytes: tooBig,
            fileName: 'scan.jpg',
            mimeType: 'image/jpeg',
          ),
        );
        final Result<OfficeMessage> kind = await repository.reply(
          threadId: 'thread-1',
          body: 'Saan po',
          idempotencyKey: key,
          file: OutgoingFile(
            bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
            fileName: 'notes.txt',
            mimeType: 'text/plain',
          ),
        );

        expect(transport.requests, isEmpty);
        expect(large, isA<Err<OfficeMessage>>());
        expect(kind, isA<Err<OfficeMessage>>());

        final Result<OfficeMessage> disguised = await repository.reply(
          threadId: 'thread-1',
          body: 'Saan po',
          idempotencyKey: key,
          file: OutgoingFile(
            bytes: Uint8List.fromList(<int>[0x00, 0x11, 0x22, 0x33]),
            fileName: 'photo.jpg',
            mimeType: 'image/jpeg',
          ),
        );
        expect(transport.requests, isEmpty);
        expect(disguised, isA<Err<OfficeMessage>>());
      },
    );

    test('reply failures keep the status and hide the operator text', () async {
      final List<({int status, String code, Type type})> cases =
          <({int status, String code, Type type})>[
            (
              status: 401,
              code: 'UNAUTHENTICATED',
              type: UnauthenticatedFailure,
            ),
            (status: 403, code: 'FORBIDDEN', type: ForbiddenFailure),
            (status: 404, code: 'NOT_FOUND', type: NotFoundFailure),
            (status: 409, code: 'CONFLICT', type: ConflictFailure),
            (
              status: 413,
              code: 'PAYLOAD_TOO_LARGE',
              type: UnacceptableUploadFailure,
            ),
            (status: 422, code: 'VALIDATION_FAILED', type: ValidationFailure),
          ];
      for (final ({int status, String code, Type type}) item in cases) {
        final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
          _failure(item.status, item.code),
        ]);
        final Result<OfficeMessage> result = await OfficeMessagingApiRepository(
          apiClient: _client(transport),
        ).reply(threadId: 'thread-1', body: 'Saan po', idempotencyKey: key);
        expect(result, isA<Err<OfficeMessage>>(), reason: '${item.status}');
        final AppFailure failure = (result as Err<OfficeMessage>).failure;
        expect(failure.runtimeType, item.type, reason: '${item.status}');
        expect(failure.residentMessage, isNot(contains('operator-only')));
      }
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

      await tester.tap(find.byKey(const Key('account-thread-menu')));
      await tester.pumpAndSettle();
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
      expect(find.byKey(const Key('account-thread-menu')), findsNothing);
    });

    testWidgets('Close is hidden when the thread is already closed', (
      tester,
    ) async {
      await _pumpThread(tester, _Desk(status: 'closed'));
      expect(find.byKey(const Key('account-thread-menu')), findsNothing);
      expect(find.byKey(const Key('account-thread-field')), findsNothing);
      expect(find.text('This conversation is closed.'), findsOneWidget);
    });

    testWidgets('Close is hidden when the resident does not own the thread', (
      tester,
    ) async {
      await _pumpThread(tester, _Desk(residentId: 'acct-other'));
      expect(find.byKey(const Key('account-thread-menu')), findsNothing);
      expect(find.byKey(const Key('account-thread-field')), findsOneWidget);
    });

    testWidgets('a failed load hides Close and the composer', (tester) async {
      await _pumpThread(
        tester,
        _Desk(loadFailure: const NetworkFailure(debugMessage: 'operator-only')),
      );
      expect(find.byKey(const Key('account-thread-menu')), findsNothing);
      expect(find.byKey(const Key('account-thread-field')), findsNothing);
      expect(find.text('operator-only'), findsNothing);
      expect(find.textContaining('offline'), findsOneWidget);
    });

    testWidgets('a 409 on reply marks the thread closed and hides Close', (
      tester,
    ) async {
      final _Desk desk = _Desk(
        replyFailure: const ConflictFailure(debugMessage: 'operator-only'),
      );
      await _pumpThread(tester, desk);
      expect(find.byKey(const Key('account-thread-menu')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Ulit',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      expect(find.text('operator-only'), findsNothing);
      expect(find.textContaining('already submitted'), findsOneWidget);
      expect(find.text('This conversation is closed.'), findsOneWidget);
      expect(find.byKey(const Key('account-thread-menu')), findsNothing);
      expect(find.byKey(const Key('account-thread-field')), findsNothing);
    });

    testWidgets('a second tap does not send twice', (tester) async {
      final Completer<void> gate = Completer<void>();
      final _Desk desk = _Desk(holdReply: gate);
      await _pumpThread(tester, desk);
      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Sandali',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();
      expect(desk.replyStarts, 1);
      final GestureDetector send = tester.widget<GestureDetector>(
        find.byKey(const Key('account-thread-send')),
      );
      expect(send.onTap, isNull);
      expect(
        tester
            .getSemantics(find.byKey(const Key('account-thread-send')))
            .flagsCollection
            .isEnabled
            .name,
        'isFalse',
      );
      gate.complete();
      await tester.pump();
      expect(desk.replies, hasLength(1));
    });

    testWidgets(
      'a reply whose answer was lost says so, and its retry keeps the key',
      (tester) async {
        final _Desk desk = _Desk(
          replyFailure: const TimeoutFailure(debugMessage: 'operator-only'),
        );
        await _pumpThread(tester, desk);
        await tester.enterText(
          find.byKey(const Key('account-thread-field')),
          'Saan po ang pila?',
        );
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();

        expect(find.text(MessageAct.reply.unconfirmed), findsOneWidget);
        expect(find.textContaining('will not be posted twice'), findsOneWidget);
        expect(find.textContaining('Nothing was sent'), findsNothing);
        expect(find.text('operator-only'), findsNothing);
        // The words stay in the composer, ready to send again unchanged.
        expect(find.text('Saan po ang pila?'), findsOneWidget);

        // A connection dropped after sending is just as unknown.
        desk.replyFailure = const NetworkFailure(mayHaveArrived: true);
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();
        expect(find.text(MessageAct.reply.unconfirmed), findsOneWidget);

        desk.replyFailure = null;
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();

        expect(desk.replies.single.body, 'Saan po ang pila?');
        expect(desk.replyKeys, hasLength(3));
        expect(desk.replyKeys.toSet(), hasLength(1));
        expect(desk.replyKeys.first, matches(_uuidV4));

        // Once it went, the same words again are a new message.
        await tester.enterText(
          find.byKey(const Key('account-thread-field')),
          'Saan po ang pila?',
        );
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();
        expect(desk.replyKeys, hasLength(4));
        expect(desk.replyKeys.last, isNot(desk.replyKeys.first));
      },
    );

    testWidgets(
      'after a lost answer, a retry that fails before sending is still not '
      'confirmed (D-192)',
      (tester) async {
        final _Desk desk = _Desk(replyFailure: const TimeoutFailure());
        await _pumpThread(tester, desk);
        await tester.enterText(
          find.byKey(const Key('account-thread-field')),
          'Saan po ang pila?',
        );
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();
        expect(find.text(MessageAct.reply.unconfirmed), findsOneWidget);

        // Offline now. This try never left the phone, but the first one may
        // have reached the office, so it is not "Nothing was sent".
        desk.replyFailure = const NetworkFailure();
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();
        expect(find.text(MessageAct.reply.unconfirmed), findsOneWidget);
        expect(find.textContaining('Nothing was sent'), findsNothing);
        expect(desk.replyKeys.toSet(), hasLength(1));

        // Once a reply goes through, a failure before sending is said plainly.
        desk.replyFailure = null;
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();
        expect(desk.replies, hasLength(1));
        desk.replyFailure = const NetworkFailure();
        await tester.enterText(
          find.byKey(const Key('account-thread-field')),
          'Salamat po',
        );
        await tester.tap(find.byKey(const Key('account-thread-send')));
        await tester.pump();
        expect(
          find.text(
            'Nothing was sent. ${const NetworkFailure().residentMessage}',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('other words or another file are a new reply with a new key', (
      tester,
    ) async {
      final _Picker picker = _Picker();
      final _Desk desk = _Desk(replyFailure: const TimeoutFailure());
      await _pumpThread(tester, desk, picker: picker);

      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Saan po',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Saan po ang pila?',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      picker.next = CapturedDocument(
        bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0x00]),
        fileName: 'note.jpg',
        mimeType: 'image/jpeg',
        source: DocumentSource.file,
      );
      await tester.tap(find.byKey(const Key('account-thread-attach')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      expect(desk.replyKeys, hasLength(3));
      expect(desk.replyKeys.toSet(), hasLength(3));
      for (final String sent in desk.replyKeys) {
        expect(sent, matches(_uuidV4));
      }
    });

    testWidgets('only a failure before sending says nothing was sent', (
      tester,
    ) async {
      final _Desk desk = _Desk(
        replyFailure: const NetworkFailure(debugMessage: 'operator-only'),
      );
      await _pumpThread(tester, desk);
      await tester.enterText(
        find.byKey(const Key('account-thread-field')),
        'Sandali',
      );
      await tester.tap(find.byKey(const Key('account-thread-send')));
      await tester.pump();

      expect(
        find.text(
          'Nothing was sent. ${const NetworkFailure().residentMessage}',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('could not confirm'), findsNothing);
      expect(find.text('operator-only'), findsNothing);
    });

    testWidgets('a 409 on close marks the thread closed', (tester) async {
      final _Desk desk = _Desk(
        closeFailure: const ConflictFailure(debugMessage: 'operator-only'),
      );
      await _pumpThread(tester, desk);
      await tester.tap(find.byKey(const Key('account-thread-menu')));
      await tester.pumpAndSettle();
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
      expect(find.text('operator-only'), findsNothing);
      expect(find.textContaining('already submitted'), findsOneWidget);
      expect(find.text('This conversation is closed.'), findsOneWidget);
      expect(find.byKey(const Key('account-thread-menu')), findsNothing);
      expect(find.byKey(const Key('account-thread-field')), findsNothing);
    });

    testWidgets('Close stays hidden when the messages fail to load', (
      tester,
    ) async {
      await _pumpThread(
        tester,
        _Desk(
          messageFailure: const NetworkFailure(debugMessage: 'operator-only'),
        ),
      );
      expect(find.byKey(const Key('account-thread-menu')), findsNothing);
      expect(find.byKey(const Key('account-thread-field')), findsNothing);
      expect(find.text('operator-only'), findsNothing);
      expect(find.textContaining('offline'), findsOneWidget);
    });

    testWidgets('an older page drops a message already on screen', (
      tester,
    ) async {
      final _Desk desk = _Desk(messagesHaveMore: true);
      await _pumpThread(tester, desk);
      tester.view.physicalSize = const Size(400, 240);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pump();

      expect(desk.messageCursors, contains('older'));
      tester.view.physicalSize = const Size(400, 900);
      await tester.pump();
      expect(
        find.text('A synthetic note.', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('An older', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('an older page failure is shown and can be retried', (
      tester,
    ) async {
      final _Desk desk = _Desk(
        messagesHaveMore: true,
        olderPageFailure: const NetworkFailure(debugMessage: 'operator-only'),
      );
      await _pumpThread(tester, desk);
      tester.view.physicalSize = const Size(400, 240);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pump();

      expect(find.text('operator-only'), findsNothing);
      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.byKey(const Key('thread-load-more-retry')), findsOneWidget);
      desk.releaseNextPage = true;
      tester
          .widget<GestureDetector>(
            find.byKey(
              const Key('thread-load-more-retry'),
              skipOffstage: false,
            ),
          )
          .onTap!();
      await tester.pump();
      tester.view.physicalSize = const Size(400, 900);
      await tester.pump();
      expect(
        find.textContaining('An older', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('A synthetic note.', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('the inbox asks for the next cursor', (tester) async {
      tester.view.physicalSize = const Size(300, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final _Desk desk = _Desk(hasMore: true);
      final AppDependencies dependencies = await _restored(desk);
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

    testWidgets('has_more false does not ask for another page', (tester) async {
      tester.view.physicalSize = const Size(300, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final _Desk desk = _Desk();
      final AppDependencies dependencies = await _restored(desk);
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

      expect(desk.threadCursors, <String?>[null]);
    });

    testWidgets('a next cursor is ignored when has_more is false', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(300, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final _Desk desk = _Desk(idleCursor: 'still-there');
      final AppDependencies dependencies = await _restored(desk);
      addTearDown(dependencies.dispose);
      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: dependencies,
          child: const MaterialApp(home: MessagesInboxScreen()),
        ),
      );
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      expect(desk.threadCursors, <String?>[null]);
    });

    testWidgets(
      'a failed next page can be retried and duplicates are dropped',
      (tester) async {
        tester.view.physicalSize = const Size(300, 160);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final _Desk desk = _Desk(
          hasMore: true,
          threadPageFailure: const NetworkFailure(
            debugMessage: 'operator-only',
          ),
        );
        final AppDependencies dependencies = await _restored(desk);
        addTearDown(dependencies.dispose);
        await tester.pumpWidget(
          AppDependenciesScope(
            dependencies: dependencies,
            child: const MaterialApp(home: MessagesInboxScreen()),
          ),
        );
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();

        expect(desk.threadCursors, contains('page-2'));
        expect(find.text('operator-only'), findsNothing);
        expect(find.byKey(const Key('inbox-load-more-retry')), findsOneWidget);
        tester.view.physicalSize = const Size(400, 900);
        await tester.pump();
        desk.releaseNextPage = true;
        await tester.tap(find.byKey(const Key('inbox-load-more-retry')));
        await tester.pump();

        expect(find.text('Assessor'), findsOneWidget);
        expect(find.text('Treasury'), findsOneWidget);
      },
    );
  });
}

Map<String, Object?> _threadJson(String id) => <String, Object?>{
  'id': id,
  'resident_id': 'acct-1',
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

Result<ApiHttpResponse> _failure(int status, String code) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{
            'code': code,
            'message': 'operator-only text',
            'details': <String, Object?>{},
            'request_id': 'req-err',
          },
        }),
        headers: const <String, String>{'x-request-id': 'req-err'},
      ),
    );

Result<ApiHttpResponse> _ok(
  Object? data, {
  String? cursor,
  bool more = false,
  int status = 200,
}) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: status,
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
  _Desk({
    List<OfficeMessage>? messages,
    this.hasMore = false,
    this.residentId = 'acct-1',
    this.status = 'open',
    this.loadFailure,
    this.messageFailure,
    this.olderPageFailure,
    this.threadPageFailure,
    this.closeFailure,
    this.replyFailure,
    this.holdReply,
    this.idleCursor,
    this.messagesHaveMore = false,
  }) : messages = messages ?? _note;

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
  final String residentId;
  final String status;
  final AppFailure? loadFailure;
  final AppFailure? messageFailure;
  final AppFailure? olderPageFailure;
  final AppFailure? threadPageFailure;
  final AppFailure? closeFailure;
  final Completer<void>? holdReply;
  final String? idleCursor;
  final bool messagesHaveMore;
  bool releaseNextPage = false;
  final List<String> reads = <String>[];
  final List<String> closed = <String>[];
  final List<String?> threadCursors = <String?>[];
  final List<String?> messageCursors = <String?>[];
  final List<_Reply> replies = <_Reply>[];
  AppFailure? replyFailure;
  int replyStarts = 0;

  /// The key every reply attempt carried, refused ones included.
  final List<String> replyKeys = <String>[];

  OfficeThread get _thread => OfficeThread(
    id: 'thread-1',
    officeId: 'office-1',
    officeName: 'Treasury',
    topic: 'Cedula',
    preview: 'A synthetic note.',
    updatedAt: DateTime.utc(2026, 10, 1),
    status: status,
    ownerAccountId: residentId,
    sample: false,
  );

  OfficeThread get _next => OfficeThread(
    id: 'thread-2',
    officeId: 'office-2',
    officeName: 'Assessor',
    topic: 'Tax',
    preview: 'Another synthetic note.',
    updatedAt: DateTime.utc(2026, 10, 2),
    status: 'open',
    ownerAccountId: residentId,
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
      final AppFailure? failure = threadPageFailure;
      if (failure != null && !releaseNextPage) {
        return Err<Paginated<OfficeThread>>(failure);
      }
      return Ok<Paginated<OfficeThread>>(
        Paginated<OfficeThread>.single(<OfficeThread>[_thread, _next]),
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
        nextCursor: hasMore ? 'page-2' : idleCursor,
      ),
    );
  }

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) async {
    final AppFailure? failure = loadFailure;
    if (failure != null) return Err<OfficeThread>(failure);
    return Ok<OfficeThread>(_thread);
  }

  @override
  Future<Result<Paginated<OfficeMessage>>> listMessages(
    String threadId, {
    int page = 1,
    int? perPage,
    String? cursor,
  }) async {
    messageCursors.add(cursor);
    if (cursor == null && messageFailure != null) {
      return Err<Paginated<OfficeMessage>>(messageFailure!);
    }
    if (cursor != null) {
      if (olderPageFailure != null && !releaseNextPage) {
        return Err<Paginated<OfficeMessage>>(olderPageFailure!);
      }
      return Ok<Paginated<OfficeMessage>>(
        Paginated<OfficeMessage>.single(<OfficeMessage>[
          messages.first,
          OfficeMessage(
            id: 'm0',
            threadId: threadId,
            body: 'An older synthetic note.',
            sentAt: DateTime.utc(2026, 9, 30),
            fromResident: true,
          ),
        ]),
      );
    }
    if (!messagesHaveMore) {
      return Ok<Paginated<OfficeMessage>>(
        Paginated<OfficeMessage>.single(messages),
      );
    }
    return Ok<Paginated<OfficeMessage>>(
      Paginated<OfficeMessage>(
        items: messages,
        page: 1,
        perPage: 25,
        total: 2,
        totalPages: 2,
        hasMore: true,
        nextCursor: 'older',
      ),
    );
  }

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async => const Err<OfficeMessage>(NetworkFailure());

  @override
  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async {
    replyStarts++;
    replyKeys.add(idempotencyKey);
    final Completer<void>? hold = holdReply;
    if (hold != null) await hold.future;
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
    final AppFailure? failure = closeFailure;
    if (failure != null) return Err<void>(failure);
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
  final AppDependencies dependencies = await _restored(desk, picker: picker);
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
  final InMemorySessionStore sessionStore = InMemorySessionStore();
  await sessionStore.write(
    const StoredSession(
      resident: ResidentSession(
        accountId: 'acct-1',
        accessLevel: AccessLevel.verified,
      ),
      accessToken: 'token',
    ),
  );
  final AppDependencies base = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    secrets: secrets,
    sessionStore: sessionStore,
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

Future<AppDependencies> _restored(_Desk desk, {DocumentPicker? picker}) async {
  final AppDependencies dependencies = await _dependencies(
    desk,
    picker: picker,
  );
  await dependencies.session.restore();
  return dependencies;
}
