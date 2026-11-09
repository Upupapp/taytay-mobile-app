import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/deep_link.dart';
import 'package:taytay_resident/features/events/data/event_api_repository.dart';
import 'package:taytay_resident/features/events/domain/event_repository.dart';
import 'package:taytay_resident/features/events/domain/event_send_failure.dart';
import 'package:taytay_resident/features/events/presentation/event_detail_screen.dart'
    show openToWords;
import 'package:taytay_resident/features/notifications/data/notification_api_repository.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';

/// The events repository against the Node API's resident routes (backend
/// `580acbb`, DL-192; D-191).
///
/// Every method, every error code the wiring brief names, the capacity race,
/// a lost answer and the key that makes trying again safe, and an answer the
/// app cannot read.
class _Scripted implements ApiTransport {
  _Scripted([List<Result<ApiHttpResponse>>? responses])
    : responses = responses ?? <Result<ApiHttpResponse>>[];

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

Result<ApiHttpResponse> _ok(
  Object? data, {
  Map<String, Object?>? meta,
  int status = 200,
}) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: status,
    body: jsonEncode(<String, Object?>{
      'data': data,
      'meta': meta ?? <String, Object?>{'request_id': 'req-ok'},
    }),
    headers: const <String, String>{'x-request-id': 'req-ok'},
  ),
);

Result<ApiHttpResponse> _page(
  List<Object?> rows, {
  bool hasMore = false,
  String? nextCursor,
}) => _ok(
  rows,
  meta: <String, Object?>{
    'request_id': 'req-page',
    'pagination': <String, Object?>{
      'has_more': hasMore,
      'next_cursor': nextCursor,
    },
  },
);

Result<ApiHttpResponse> _error(int status, String code) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: status,
    body: jsonEncode(<String, Object?>{
      'error': <String, Object?>{
        'code': code,
        'message': 'operator text that a resident must never read',
        'details': <String, Object?>{},
        'request_id': 'req-$status',
      },
    }),
    headers: <String, String>{'x-request-id': 'req-$status'},
  ),
);

Result<ApiHttpResponse> _raw(int status, String body) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: status,
    body: body,
    headers: const <String, String>{'x-request-id': 'req-raw'},
  ),
);

ApiClient _client(ApiTransport transport, {String? token = 'resident-token'}) =>
    ApiClient(
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
      ),
      transport: transport,
      accessTokenProvider: () async => token,
    );

bool _sentBearer(ApiRequest request) =>
    request.headers.keys.any((String k) => k.toLowerCase() == 'authorization');

bool _sentKeyHeader(ApiRequest request) => request.headers.keys.any(
  (String k) => k.toLowerCase() == 'idempotency-key',
);

Map<String, Object?> _body(ApiRequest request) =>
    request.body! as Map<String, Object?>;

const String _eventId = '5b0a3f7e-1d2c-4b6a-9e1f-0c2d3e4f5a6b';
const String _registrationId = '7c1b4e8f-2a3d-4c5b-8f60-1a2b3c4d5e6f';
const String _key = '0f8e7d6c-5b4a-4938-8271-605f4e3d2c1b';

/// A synthetic event shaped like `ResidentEvent`.
Map<String, Object?> _event({
  String id = _eventId,
  String status = 'published',
  String state = 'open',
  String description = 'Free check-ups for SAMPLE residents.',
  String summary = 'Free check-ups.',
  Object? capacity = 120,
  Object? cover = const <String, Object?>{
    'url': 'https://example.test/covers/sample.jpg',
    'alt_text': 'A SAMPLE covered court',
  },
  Object? myRegistration,
  bool detail = false,
  Object? openTo,
  bool allowsUnverified = false,
}) => <String, Object?>{
  'id': id,
  'title': 'SAMPLE medical mission',
  'summary': summary,
  'description': description,
  'category': 'medical-mission',
  'category_label': 'Medical mission',
  'status': status,
  'starts_at': '2026-12-05T00:00:00.000Z',
  'ends_at': '2026-12-05T08:00:00.000Z',
  'venue': <String, Object?>{
    'name': 'SAMPLE covered court',
    'address': '',
    'map_url': 'https://maps.example.test/court',
    'barangay_id': null,
    'barangay_name': null,
  },
  'organiser': 'SAMPLE health office',
  'contact': <String, Object?>{
    'name': 'Desk officer',
    'office': 'SAMPLE health office',
    'phone': null,
  },
  'cover_image': cover,
  'capacity': capacity,
  'what_to_bring': 'A valid ID.',
  'registration': <String, Object?>{
    'required': true,
    'opens_at': null,
    'closes_at': null,
    'availability': state == 'registered' || state == 'waitlisted'
        ? 'open'
        : state,
    'joins_waitlist': false,
    'state': state,
    'words': 'The office sentence, which the app does not show.',
    'rules': 'Residents of Taytay.',
    'open_to': ?openTo,
    if (openTo != null)
      'open_to_words': 'The office sentence for who may register.',
  },
  'my_registration': myRegistration,
  if (detail)
    'registration_form': <String, Object?>{
      'fields': <Object?>[],
      'consents': <Object?>[],
      'allows_unverified_residents': allowsUnverified,
      'can_cancel': true,
      'notice': 'Bring the reference you are given.',
    },
};

/// A synthetic `ResidentEventRegistration`.
Map<String, Object?> _own({
  String state = 'registered',
  Object? attendance,
  bool canCancel = true,
}) => <String, Object?>{
  'id': _registrationId,
  'event_id': _eventId,
  'reference': 'ER-2026-000123',
  'state': state,
  'registered_at': '2026-11-08T01:00:00.000Z',
  'attendance': attendance,
  'can_cancel': canCancel,
  'instructions': 'A valid ID.',
};

Map<String, Object?> _outcome(String outcome, {Object? registration}) =>
    <String, Object?>{
      'outcome': outcome,
      'words': 'The office sentence, which the app does not show.',
      'registration': registration,
    };

Future<Result<RegistrationAttempt>> _register(
  EventApiRepository repository, {
  String key = _key,
}) => repository.register(
  eventId: _eventId,
  answers: const <String, Object?>{},
  consentKeys: const <String>[],
  idempotencyKey: key,
);

Future<Result<EventRegistration>> _cancel(
  EventApiRepository repository, {
  String key = _key,
}) => repository.cancelRegistration(
  eventId: _eventId,
  registrationId: _registrationId,
  idempotencyKey: key,
);

void main() {
  late _Scripted transport;
  late EventApiRepository repository;

  setUp(() {
    transport = _Scripted();
    repository = EventApiRepository(apiClient: _client(transport));
  });

  group('listEvents — GET events', () {
    test('asks for the scope and a bounded limit, and decodes every row '
        'without a seats-left number', () async {
      transport.responses.add(
        _page(<Object?>[
          _event(myRegistration: _own()),
          _event(id: 'e-2', description: '', capacity: null, cover: null),
        ]),
      );

      final Result<Paginated<LguEvent>> result = await repository.listEvents(
        perPage: 10,
      );

      final ApiRequest request = transport.requests.single;
      expect(request.method, HttpMethod.get);
      expect(request.path, 'events');
      expect(request.query, <String, String>{
        'scope': 'upcoming',
        'limit': '10',
      });
      // A public read still carries the resident's token, so each row can say
      // whether they hold a place.
      expect(_sentBearer(request), isTrue);

      final Paginated<LguEvent> page = result.valueOrNull!;
      expect(page.hasMore, isFalse);
      final LguEvent first = page.items.first;
      expect(first.id, _eventId);
      expect(first.title, 'SAMPLE medical mission');
      expect(first.description, 'Free check-ups for SAMPLE residents.');
      expect(first.category, 'Medical mission');
      expect(first.startsAt, DateTime.utc(2026, 12, 5));
      expect(first.endsAt, DateTime.utc(2026, 12, 5, 8));
      expect(first.venue?.name, 'SAMPLE covered court');
      expect(first.venue?.address, isNull, reason: 'an empty address is none');
      expect(first.venue?.hasSafeDirections, isTrue);
      expect(first.organiser, 'SAMPLE health office');
      expect(first.contact, 'Desk officer, SAMPLE health office');
      expect(first.coverImageUrl, 'https://example.test/covers/sample.jpg');
      expect(first.coverAltText, 'A SAMPLE covered court');
      expect(first.whatToBring, 'A valid ID.');
      expect(first.registrationRules, 'Residents of Taytay.');
      expect(first.shareUrl, isNull);
      expect(first.capacity.capacity, 120);
      expect(
        first.capacity.remaining,
        isNull,
        reason: 'No seats-left number is ever sent, and none is computed.',
      );
      expect(first.capacity.isFull, isFalse);
      expect(first.registrationState?.known, EventRegistrationState.open);
      expect(first.publicationState?.known, PublicationState.published);
      expect(first.isResidentVisible, isTrue);
      expect(first.isCalledOff, isFalse);
      expect(first.myRegistration?.reference, 'ER-2026-000123');

      final LguEvent second = page.items.last;
      expect(second.description, 'Free check-ups.', reason: 'summary fills in');
      expect(second.capacity.isStated, isFalse);
      expect(second.coverImageUrl, isNull);
      expect(second.myRegistration, isNull);
    });

    test('a called-off event is shown and says so; completed is shown; '
        '"not_required" is a walk-in event', () async {
      transport.responses.add(
        _page(<Object?>[
          _event(status: 'cancelled', state: 'closed'),
          _event(id: 'e-2', status: 'completed', state: 'closed'),
          _event(id: 'e-3', state: 'not_required'),
        ]),
      );

      final List<LguEvent> items = (await repository.listEvents(
        scope: EventScope.past,
      )).valueOrNull!.items;

      expect(transport.requests.single.query['scope'], 'past');
      expect(items[0].isResidentVisible, isTrue);
      expect(items[0].isCalledOff, isTrue);
      expect(items[0].publicationState?.known, isNull);
      expect(items[0].registrationState?.known, EventRegistrationState.closed);
      expect(items[1].isResidentVisible, isTrue);
      expect(items[1].isCalledOff, isFalse);
      expect(items[2].registrationState?.raw, 'not_required');
      expect(
        items[2].registrationState?.known,
        EventRegistrationState.notRequired,
      );
    });

    test(
      "a cover's address is only a sign, http included; its words are kept",
      () async {
        // Behind a proxy that ends TLS the API writes its own origin as
        // http://. The address is never requested (D-193): the bytes are read
        // from `events/{id}/cover` on the configured base.
        transport.responses.add(
          _page(<Object?>[
            _event(
              cover: const <String, Object?>{
                'url': 'http://example.test/api/v1/events/e-1/cover',
                'alt_text': '  Volunteers at the covered court  ',
              },
            ),
            _event(
              id: 'e-2',
              cover: const <String, Object?>{'url': '', 'alt_text': 'x'},
            ),
          ]),
        );

        final List<LguEvent> items =
            (await repository.listEvents()).valueOrNull!.items;
        expect(
          items.first.coverImageUrl,
          'http://example.test/api/v1/events/e-1/cover',
        );
        expect(items.first.coverAltText, 'Volunteers at the covered court');
        // No address, no cover: an empty one is not a sign of anything.
        expect(items.last.coverImageUrl, isNull);
      },
    );

    test('pages by cursor, per scope, and page 1 starts again', () async {
      transport.responses.addAll(<Result<ApiHttpResponse>>[
        _page(<Object?>[_event()], hasMore: true, nextCursor: 'c-upcoming'),
        _page(
          <Object?>[_event(id: 'e-past')],
          hasMore: true,
          nextCursor: 'c-past',
        ),
        _page(<Object?>[_event(id: 'e-2')]),
        _page(<Object?>[_event()]),
      ]);

      await repository.listEvents();
      await repository.listEvents(scope: EventScope.past);
      final Paginated<LguEvent> second = (await repository.listEvents(
        page: 2,
      )).valueOrNull!;
      await repository.listEvents();

      expect(transport.requests[2].query['cursor'], 'c-upcoming');
      expect(transport.requests[2].query['scope'], 'upcoming');
      expect(second.items.single.id, 'e-2');
      expect(second.hasMore, isFalse);
      expect(transport.requests[3].query.containsKey('cursor'), isFalse);
    });

    test('past the last page nothing is asked, so nothing repeats', () async {
      transport.responses.add(_page(<Object?>[_event()]));

      await repository.listEvents();
      final Paginated<LguEvent> next = (await repository.listEvents(
        page: 2,
      )).valueOrNull!;

      expect(transport.requests, hasLength(1));
      expect(next.items, isEmpty);
      expect(next.hasMore, isFalse);
    });

    test('the limit never exceeds the route ceiling of 50', () async {
      transport.responses.add(_page(<Object?>[]));
      await repository.listEvents(perPage: 100);
      expect(transport.requests.single.query['limit'], '50');
    });

    test('"My events" needs the account: a guest sends nothing', () async {
      final _Scripted guestTransport = _Scripted();
      final EventApiRepository guest = EventApiRepository(
        apiClient: _client(guestTransport, token: null),
      );

      final Result<Paginated<LguEvent>> mine = await guest.listEvents(
        scope: EventScope.registered,
      );

      expect(mine.failureOrNull, isA<UnauthenticatedFailure>());
      expect(guestTransport.requests, isEmpty);
      expect(EventScope.registered.needsAccount, isTrue);
    });

    test('a guest reads upcoming events anonymously', () async {
      final _Scripted guestTransport = _Scripted(<Result<ApiHttpResponse>>[
        _page(<Object?>[_event()]),
      ]);
      final EventApiRepository guest = EventApiRepository(
        apiClient: _client(guestTransport, token: null),
      );

      final Result<Paginated<LguEvent>> listed = await guest.listEvents();

      expect(listed.isOk, isTrue);
      expect(_sentBearer(guestTransport.requests.single), isFalse);
    });

    test('a staff token on "My events" is a 403, passed through', () async {
      transport.responses.add(_error(403, 'FORBIDDEN'));
      final Result<Paginated<LguEvent>> mine = await repository.listEvents(
        scope: EventScope.registered,
      );
      expect(transport.requests.single.query['scope'], 'registered');
      expect(mine.failureOrNull, isA<ForbiddenFailure>());
    });

    test('an unknown query key is a 422, passed through', () async {
      transport.responses.add(_error(422, 'VALIDATION_FAILED'));
      final Result<Paginated<LguEvent>> listed = await repository.listEvents();
      expect(listed.failureOrNull, isA<ValidationFailure>());
    });

    group('an unreadable page is a contract failure, never "no events"', () {
      for (final (String name, Result<ApiHttpResponse> response)
          in <(String, Result<ApiHttpResponse>)>[
            (
              'data is not a list',
              _ok(<String, Object?>{'events': <Object?>[]}),
            ),
            (
              'a row has no id',
              _page(<Object?>[
                <String, Object?>{'title': 'No id'},
              ]),
            ),
            ('a row is not an object', _page(<Object?>['e-1'])),
            ('no pagination', _ok(<Object?>[_event()])),
            (
              'more promised with no cursor',
              _page(<Object?>[_event()], hasMore: true),
            ),
            (
              'a malformed registration',
              _page(<Object?>[
                _event(myRegistration: <String, Object?>{'id': 'r'}),
              ]),
            ),
            ('a body that is not JSON', _raw(200, '<html>login</html>')),
          ]) {
        test(name, () async {
          transport.responses.add(response);
          final Result<Paginated<LguEvent>> listed = await repository
              .listEvents();
          expect(listed.failureOrNull, isA<ContractFailure>());
        });
      }
    });
  });

  group('loadEvent and loadRegistrationForm — GET events/{id}', () {
    test('loads one event with the resident\'s own registration', () async {
      transport.responses.add(
        _ok(
          _event(
            detail: true,
            state: 'waitlisted',
            myRegistration: _own(state: 'waitlisted', attendance: 'attended'),
          ),
        ),
      );

      final LguEvent event = (await repository.loadEvent(
        _eventId,
      )).valueOrNull!;

      expect(transport.requests.single.path, 'events/$_eventId');
      expect(_sentBearer(transport.requests.single), isTrue);
      expect(event.isRegistered, isTrue);
      final EventRegistration mine = event.myRegistration!;
      expect(mine.id, _registrationId);
      expect(mine.eventId, _eventId);
      expect(mine.isWaitlisted, isTrue);
      expect(mine.waitlistPosition, isNull, reason: 'never sent');
      expect(mine.attendance?.known, AttendanceResult.attended);
      expect(mine.registeredAt, DateTime.utc(2026, 11, 8, 1));
      expect(mine.instructions, 'A valid ID.');
      expect(mine.isCancellable, isTrue);
    });

    test('attendance is null until the office completes the event, never '
        'read as absent', () async {
      transport.responses.add(_ok(_event(myRegistration: _own())));
      final LguEvent event = (await repository.loadEvent(
        _eventId,
      )).valueOrNull!;
      expect(event.myRegistration?.attendance, isNull);
    });

    test('the form comes from the event read: nothing asked, verified '
        'accounts only, cancellable', () async {
      transport.responses.add(_ok(_event(detail: true)));

      final EventRegistrationForm form = (await repository.loadRegistrationForm(
        _eventId,
      )).valueOrNull!;

      expect(transport.requests.single.path, 'events/$_eventId');
      expect(form.eventId, _eventId);
      expect(form.eventTitle, 'SAMPLE medical mission');
      expect(form.fields, isEmpty);
      expect(form.consents, isEmpty);
      expect(form.allowsUnverifiedResidents, isFalse);
      expect(form.canCancel, isTrue);
      expect(form.notice, 'Bring the reference you are given.');
    });

    test('a form missing from the read promises nothing', () async {
      transport.responses.add(_ok(_event()));
      final EventRegistrationForm form = (await repository.loadRegistrationForm(
        _eventId,
      )).valueOrNull!;
      expect(form.allowsUnverifiedResidents, isFalse);
      expect(form.canCancel, isFalse);
    });

    test('a draft, archived or unknown event is a 404', () async {
      transport.responses.add(_error(404, 'NOT_FOUND'));
      final Result<LguEvent> loaded = await repository.loadEvent(_eventId);
      expect(loaded.failureOrNull, isA<NotFoundFailure>());
      expect(loaded.failureOrNull?.requestId, 'req-404');
    });

    test('a non-uuid id is a 422', () async {
      transport.responses.add(_error(422, 'VALIDATION_FAILED'));
      final Result<LguEvent> loaded = await repository.loadEvent('not-a-uuid');
      expect(loaded.failureOrNull, isA<ValidationFailure>());
    });

    test('an unreadable event is a contract failure', () async {
      transport.responses.addAll(<Result<ApiHttpResponse>>[
        _ok(null),
        _ok(<String, Object?>{'id': _eventId}),
      ]);
      expect(
        (await repository.loadEvent(_eventId)).failureOrNull,
        isA<ContractFailure>(),
      );
      expect(
        (await repository.loadRegistrationForm(_eventId)).failureOrNull,
        isA<ContractFailure>(),
      );
    });
  });

  group('register — POST events/{id}/registrations', () {
    test('sends the key in the body only, and a place is registered', () async {
      transport.responses.add(
        _ok(_outcome('registered', registration: _own()), status: 201),
      );

      final RegistrationAttempt attempt = (await _register(
        repository,
      )).valueOrNull!;

      final ApiRequest request = transport.requests.single;
      expect(request.method, HttpMethod.post);
      expect(request.path, 'events/$_eventId/registrations');
      expect(_sentBearer(request), isTrue);
      expect(_body(request), <String, Object?>{'idempotency_key': _key});
      expect(
        _sentKeyHeader(request),
        isFalse,
        reason: 'The API allows four request headers; the key is a body field.',
      );

      expect(attempt.outcome, RegistrationOutcome.registered);
      expect(attempt.isHeld, isTrue);
      expect(attempt.registration?.reference, 'ER-2026-000123');
      expect(attempt.requestId, 'req-ok');
      expect(attempt.residentMessage, contains('Taytay LGU has your place'));
      expect(attempt.residentMessage, isNot(contains('office sentence')));
    });

    test('a full event that keeps a waitlist waitlists', () async {
      transport.responses.add(
        _ok(
          _outcome('waitlisted', registration: _own(state: 'waitlisted')),
          status: 201,
        ),
      );
      final RegistrationAttempt attempt = (await _register(
        repository,
      )).valueOrNull!;
      expect(attempt.outcome, RegistrationOutcome.waitlisted);
      expect(attempt.isHeld, isTrue);
      expect(attempt.registration?.isWaitlisted, isTrue);
      expect(attempt.registration?.waitlistPosition, isNull);
    });

    test('full and closed are outcomes in a 200, not failures', () async {
      transport.responses.addAll(<Result<ApiHttpResponse>>[
        _ok(_outcome('full')),
        _ok(_outcome('closed', registration: _own(state: 'cancelled'))),
      ]);

      final RegistrationAttempt full = (await _register(
        repository,
      )).valueOrNull!;
      final RegistrationAttempt closed = (await _register(
        repository,
      )).valueOrNull!;

      expect(full.outcome, RegistrationOutcome.full);
      expect(full.isHeld, isFalse);
      expect(full.registration, isNull);
      expect(full.residentMessage, contains('keeps no waitlist'));
      expect(closed.outcome, RegistrationOutcome.closed);
      expect(closed.registration?.isCancelled, isTrue);
      expect(closed.residentMessage, contains('closed'));
    });

    test('the capacity race: one resident gets the last place, the other '
        'reads a calm outcome', () async {
      final _Scripted firstPhone = _Scripted(<Result<ApiHttpResponse>>[
        _ok(_outcome('registered', registration: _own()), status: 201),
      ]);
      final _Scripted secondPhone = _Scripted(<Result<ApiHttpResponse>>[
        _ok(_outcome('full')),
      ]);
      final _Scripted thirdPhone = _Scripted(<Result<ApiHttpResponse>>[
        _ok(
          _outcome('waitlisted', registration: _own(state: 'waitlisted')),
          status: 201,
        ),
      ]);

      final List<Result<RegistrationAttempt>> results =
          await Future.wait<Result<RegistrationAttempt>>(
            <Future<Result<RegistrationAttempt>>>[
              _register(EventApiRepository(apiClient: _client(firstPhone))),
              _register(
                EventApiRepository(apiClient: _client(secondPhone)),
                key: 'a1b2c3d4-0000-4000-8000-000000000002',
              ),
              _register(
                EventApiRepository(apiClient: _client(thirdPhone)),
                key: 'a1b2c3d4-0000-4000-8000-000000000003',
              ),
            ],
          );

      expect(results.every((Result<RegistrationAttempt> r) => r.isOk), isTrue);
      final List<RegistrationOutcome> outcomes = <RegistrationOutcome>[
        for (final Result<RegistrationAttempt> r in results)
          r.valueOrNull!.outcome,
      ];
      expect(outcomes, <RegistrationOutcome>[
        RegistrationOutcome.registered,
        RegistrationOutcome.full,
        RegistrationOutcome.waitlisted,
      ]);
      for (final Result<RegistrationAttempt> r in results) {
        expect(
          r.valueOrNull!.residentMessage.toLowerCase(),
          isNot(contains('error')),
        );
      }
    });

    test('a retry with the same key is answered with the first outcome, '
        'and carries that same key', () async {
      transport.responses.addAll(<Result<ApiHttpResponse>>[
        const Err<ApiHttpResponse>(TimeoutFailure()),
        _ok(_outcome('registered', registration: _own())),
      ]);

      final Result<RegistrationAttempt> lost = await _register(repository);
      final Result<RegistrationAttempt> retried = await _register(repository);

      expect(lost.failureOrNull, isA<TimeoutFailure>());
      expect(lost.failureOrNull!.outcomeUnknown, isTrue);
      expect(retried.valueOrNull?.outcome, RegistrationOutcome.registered);
      expect(transport.requests, hasLength(2));
      expect(
        transport.requests.map((ApiRequest r) => _body(r)['idempotency_key']),
        <Object?>[_key, _key],
      );
    });

    test('the transport does not repeat a registration on its own', () async {
      // Without an Idempotency-Key header the retry policy treats the POST as
      // unrepeatable; the resident retries, with the same key, after reading
      // that it is safe.
      transport.responses.add(
        const Err<ApiHttpResponse>(NetworkFailure(mayHaveArrived: true)),
      );
      final Result<RegistrationAttempt> lost = await _register(repository);
      expect(transport.requests, hasLength(1));
      expect(lost.failureOrNull!.outcomeUnknown, isTrue);
    });

    group('each refusal the brief names is a refused outcome, in the app\'s '
        'own words', () {
      for (final (int status, String code, String expected)
          in <(int, String, String)>[
            (403, 'VERIFICATION_REQUIRED', 'Verify your account first'),
            (403, 'FORBIDDEN', 'not available for this account'),
            (404, 'NOT_FOUND', 'no longer listed'),
            (409, 'CONFLICT', 'not taking registrations'),
            (422, 'VALIDATION_FAILED', 'could not accept this registration'),
          ]) {
        test('$status $code', () async {
          transport.responses.add(_error(status, code));

          final Result<RegistrationAttempt> result = await _register(
            repository,
          );

          final RegistrationAttempt attempt = result.valueOrNull!;
          expect(attempt.outcome, RegistrationOutcome.refused);
          expect(attempt.isHeld, isFalse);
          expect(attempt.registration, isNull);
          expect(attempt.requestId, 'req-$status');
          expect(attempt.residentMessage, contains(expected));
          expect(attempt.residentMessage, isNot(contains('operator text')));
          // A refusal says this send was turned away, not what an earlier
          // send under the same key did.
          expect(
            attempt.residentMessage.toLowerCase(),
            isNot(contains('nothing was registered')),
          );
        });
      }
    });

    test('a 401 stays a failure, so the session ends in one place', () async {
      transport.responses.add(_error(401, 'UNAUTHENTICATED'));
      final Result<RegistrationAttempt> result = await _register(repository);
      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
    });

    test('a guest sends nothing', () async {
      final _Scripted guestTransport = _Scripted();
      final Result<RegistrationAttempt> result = await _register(
        EventApiRepository(apiClient: _client(guestTransport, token: null)),
      );
      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(guestTransport.requests, isEmpty);
    });

    group('no answer the app can use stays a failure, and only a refusal is '
        'not "unknown"', () {
      for (final (String name, Result<ApiHttpResponse> response, bool unknown)
          in <(String, Result<ApiHttpResponse>, bool)>[
            ('a timeout', const Err<ApiHttpResponse>(TimeoutFailure()), true),
            (
              'a connection dropped after sending',
              const Err<ApiHttpResponse>(NetworkFailure(mayHaveArrived: true)),
              true,
            ),
            (
              'a connection that failed before sending',
              const Err<ApiHttpResponse>(NetworkFailure()),
              false,
            ),
            ('a 500', _error(500, 'INTERNAL_ERROR'), true),
            ('a 503', _error(503, 'SERVICE_UNAVAILABLE'), false),
            ('a 429', _error(429, 'RATE_LIMITED'), false),
          ]) {
        test(name, () async {
          transport.responses.add(response);
          final AppFailure failure = (await _register(
            repository,
          )).failureOrNull!;
          expect(failure.outcomeUnknown, unknown);
          expect(
            registrationSendFailure(failure).toLowerCase(),
            unknown
                ? allOf(
                    contains('could not confirm'),
                    contains('trying again is safe'),
                    isNot(contains('nothing was')),
                    isNot(contains('not registered')),
                  )
                : isNot(contains('could not confirm')),
          );
        });
      }
    });

    group('an unreadable answer is a contract failure, never a blank', () {
      for (final (String name, Result<ApiHttpResponse> response)
          in <(String, Result<ApiHttpResponse>)>[
            ('an outcome this build does not know', _ok(_outcome('pending'))),
            ('no outcome', _ok(<String, Object?>{'registration': null})),
            ('data is not an object', _ok(<Object?>[])),
            (
              'a malformed registration',
              _ok(
                _outcome(
                  'registered',
                  registration: <String, Object?>{'id': 'r'},
                ),
              ),
            ),
            ('a body that is not JSON', _raw(201, 'Created')),
          ]) {
        test(name, () async {
          transport.responses.add(response);
          final AppFailure failure = (await _register(
            repository,
          )).failureOrNull!;
          expect(failure, isA<ContractFailure>());
          expect(
            failure.outcomeUnknown,
            isTrue,
            reason: 'It may be a place the resident holds.',
          );
        });
      }
    });

    test('answers from a future form are sent, never dropped', () async {
      transport.responses.add(_error(422, 'VALIDATION_FAILED'));
      await repository.register(
        eventId: _eventId,
        answers: const <String, Object?>{'companions': 2},
        consentKeys: const <String>['health'],
        idempotencyKey: _key,
      );
      expect(_body(transport.requests.single), <String, Object?>{
        'idempotency_key': _key,
        'answers': <String, Object?>{'companions': 2},
        'consent_keys': <String>['health'],
      });
    });
  });

  group('cancelRegistration — POST events/{id}/registrations/{rid}/cancel', () {
    test(
      'sends the key in the body only and adopts the server answer',
      () async {
        transport.responses.add(
          _ok(_own(state: 'cancelled', canCancel: false)),
        );

        final EventRegistration cancelled = (await _cancel(
          repository,
        )).valueOrNull!;

        final ApiRequest request = transport.requests.single;
        expect(request.method, HttpMethod.post);
        expect(
          request.path,
          'events/$_eventId/registrations/$_registrationId/cancel',
        );
        expect(_sentBearer(request), isTrue);
        expect(_body(request), <String, Object?>{'idempotency_key': _key});
        expect(_sentKeyHeader(request), isFalse);
        expect(cancelled.isCancelled, isTrue);
        expect(cancelled.isCancellable, isFalse);
      },
    );

    test(
      'a late retry with the same key answers the place as it stands',
      () async {
        transport.responses.addAll(<Result<ApiHttpResponse>>[
          const Err<ApiHttpResponse>(TimeoutFailure()),
          _ok(_own()),
        ]);

        final Result<EventRegistration> lost = await _cancel(repository);
        final Result<EventRegistration> retried = await _cancel(repository);

        expect(lost.failureOrNull!.outcomeUnknown, isTrue);
        expect(retried.valueOrNull?.isActive, isTrue);
        expect(
          transport.requests.map((ApiRequest r) => _body(r)['idempotency_key']),
          <Object?>[_key, _key],
        );
      },
    );

    for (final (int status, String code, Type expected)
        in <(int, String, Type)>[
          (409, 'CONFLICT', ConflictFailure),
          (404, 'NOT_FOUND', NotFoundFailure),
          (422, 'VALIDATION_FAILED', ValidationFailure),
          (401, 'UNAUTHENTICATED', UnauthenticatedFailure),
        ]) {
      test('$status $code is passed through as a failure', () async {
        transport.responses.add(_error(status, code));
        final AppFailure failure = (await _cancel(repository)).failureOrNull!;
        expect(failure.runtimeType, expected);
        expect(failure.outcomeUnknown, isFalse);
      });
    }

    test('an unreadable answer is a contract failure', () async {
      transport.responses.add(_ok(<String, Object?>{'state': 'cancelled'}));
      final AppFailure failure = (await _cancel(repository)).failureOrNull!;
      expect(failure, isA<ContractFailure>());
    });
  });

  group('who may register — open_to (D-194)', () {
    test('reads the office\'s setting on every event', () async {
      transport.responses.add(
        _page(<Object?>[
          _event(id: 'e-1', openTo: 'verified_residents'),
          _event(id: 'e-2', openTo: 'app_accounts'),
          _event(id: 'e-3', openTo: 'members_only'),
          _event(id: 'e-4'),
        ]),
      );

      final List<LguEvent> items =
          (await repository.listEvents()).valueOrNull!.items;

      expect(items[0].openTo?.known, EventEligibility.verifiedResidents);
      expect(items[1].openTo?.known, EventEligibility.appAccounts);
      expect(
        items[2].openTo?.known,
        isNull,
        reason: 'a value this build does not know is kept, and decides nothing',
      );
      expect(items[2].openTo?.raw, 'members_only');
      expect(items[3].openTo, isNull);
    });

    test('an event open to every app account lets an unverified resident '
        'into the form', () async {
      transport.responses.add(
        _ok(
          _event(detail: true, openTo: 'app_accounts', allowsUnverified: true),
        ),
      );

      final EventRegistrationForm form = (await repository.loadRegistrationForm(
        _eventId,
      )).valueOrNull!;

      expect(form.allowsUnverifiedResidents, isTrue);
    });

    test('the event page says who may register, and nothing for a walk-in '
        'event or a value it does not know', () async {
      transport.responses.add(
        _page(<Object?>[
          _event(id: 'e-1', openTo: 'verified_residents'),
          _event(id: 'e-2', openTo: 'app_accounts'),
          _event(id: 'e-3', openTo: 'app_accounts', state: 'not_required'),
          _event(id: 'e-4', openTo: 'members_only'),
        ]),
      );

      final List<LguEvent> items =
          (await repository.listEvents()).valueOrNull!.items;

      expect(openToWords(items[0]), contains('ID Taytay LGU has verified'));
      expect(openToWords(items[1]), contains('do not need a verified ID'));
      expect(openToWords(items[2]), isNull);
      expect(openToWords(items[3]), isNull);
    });

    test('a correction keeps who may register on the event the resident '
        'holds a place at', () async {
      transport.responses.add(
        _ok(_event(openTo: 'app_accounts', myRegistration: _own())),
      );
      final LguEvent event = (await repository.loadEvent(
        _eventId,
      )).valueOrNull!;
      final LguEvent cancelled = event.withRegistration(event.myRegistration!);
      expect(cancelled.openTo?.known, EventEligibility.appAccounts);
    });
  });

  group('the event registration notification', () {
    test('a correction notice opens the event it names, like any other '
        '(D-194)', () async {
      transport.responses.add(
        _ok(<Object?>[
          <String, Object?>{
            'id': 'n-2',
            'type': 'event_registration_updated',
            'title': 'An event you registered for has changed',
            'body':
                '“SAMPLE medical mission” has changed. The venue is now '
                'SAMPLE gym (it was SAMPLE covered court). Your registration '
                'still stands. If you can no longer go, you can give up your '
                'place in the app.',
            'subject_id': _eventId,
            'read_at': null,
            'created_at': '2026-11-09T05:20:00Z',
          },
        ]),
      );

      final ResidentNotification notification =
          (await NotificationApiRepository(
            apiClient: _client(transport),
          ).listOwn()).valueOrNull!.items.single;

      expect(notification.body, contains('it was SAMPLE covered court'));
      final DeepLinkResult link = DeepLink.resolve(notification.target);
      final DeepLinkTarget target = (link as DeepLinkResolved).target;
      expect(target.route, AppRoute.eventDetail);
      expect(target.location, '/events/$_eventId');
    });

    test('opens the event it names', () async {
      transport.responses.add(
        _ok(<Object?>[
          <String, Object?>{
            'id': 'n-1',
            'type': 'event_registration_updated',
            'title': 'Your event registration changed',
            'body': 'The office moved your place.',
            'subject_id': _eventId,
            'read_at': null,
            'created_at': '2026-11-08T05:20:00Z',
          },
        ]),
      );

      final Result<Paginated<ResidentNotification>> result =
          await NotificationApiRepository(
            apiClient: _client(transport),
          ).listOwn();
      final ResidentNotification notification =
          result.valueOrNull!.items.single;

      final DeepLinkResult link = DeepLink.resolve(notification.target);
      expect(link, isA<DeepLinkResolved>());
      final DeepLinkTarget target = (link as DeepLinkResolved).target;
      expect(target.route, AppRoute.eventDetail);
      expect(target.location, '/events/$_eventId');
    });
  });
}
