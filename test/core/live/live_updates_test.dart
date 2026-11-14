import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/auth_coordinator.dart';
import 'package:taytay_resident/core/api/change_stream.dart';
import 'package:taytay_resident/core/api/http_api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/live/live_updates.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';

/// D-218: the change stream is open only in the foreground, for somebody
/// signed in; it reconnects with backoff, at once after `expired`; it never
/// polls; and every screen hears a change at most once per window.

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Hands out one stream per open, unless a scripted answer is queued.
class _Opener {
  final List<StreamController<String>> opened = <StreamController<String>>[];
  final List<ChangeStreamOpening> script = <ChangeStreamOpening>[];
  Completer<ChangeStreamOpening>? hold;
  int calls = 0;

  Future<ChangeStreamOpening> call() async {
    calls++;
    final Completer<ChangeStreamOpening>? held = hold;
    if (held != null) return held.future;
    if (script.isNotEmpty) return script.removeAt(0);
    opened.add(StreamController<String>());
    return ChangeStreamOpen(opened.last.stream);
  }

  StreamController<String> get latest => opened.last;

  void closeAll() {
    for (final StreamController<String> controller in opened) {
      unawaited(controller.close());
    }
  }
}

const String _split = 'data: Piña\n\n';

const String _ready =
    'retry: 1000\n: connected\n\nevent: ready\n'
    'data: {"topics":["news","verification","threads"]}\n\n';

String _change(List<String> topics) =>
    'event: change\ndata: ${jsonEncode(<String, Object?>{'topics': topics})}\n\n';

Future<SessionController> _signedIn() async {
  final SessionController session = SessionController(
    store: InMemorySessionStore(),
  );
  await session.signIn(
    resident: const ResidentSession(
      accountId: 'acct-1',
      accessLevel: AccessLevel.unverified,
    ),
    accessToken: 'token-1',
  );
  return session;
}

void main() {
  group('LiveUpdates', () {
    late _Opener opener;
    late DateTime now;
    LiveUpdates? live;

    LiveUpdates build(SessionController session) {
      final LiveUpdates created = LiveUpdates(
        open: opener.call,
        session: session,
        random: Random(7),
        clock: () => now,
      );
      live = created;
      return created;
    }

    Future<void> wait(WidgetTester tester, Duration duration) async {
      now = now.add(duration);
      await tester.pump(duration);
    }

    setUp(() {
      opener = _Opener();
      now = DateTime.utc(2026, 11, 15, 8);
      live = null;
    });

    /// Ends the test with no timer pending: the stream's watchdog and
    /// backoff belong to [live], and go with it.
    void finish() {
      live?.dispose();
      live = null;
    }

    tearDown(() {
      finish();
      opener.closeAll();
    });

    testWidgets('connects only when resumed and signed in, and closes on '
        'inactive, paused and sign-out', (WidgetTester tester) async {
      final SessionController session = SessionController(
        store: InMemorySessionStore(),
      );
      final LiveUpdates updates = build(session);

      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(opener.calls, 0, reason: 'a guest has no stream');

      await session.signIn(
        resident: const ResidentSession(
          accountId: 'acct-1',
          accessLevel: AccessLevel.unverified,
        ),
        accessToken: 'token-1',
      );
      await tester.pump();
      expect(opener.calls, 1);
      expect(updates.status, LiveStatus.open);
      expect(opener.latest.hasListener, isTrue);

      for (final AppLifecycleState away in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.detached,
      ]) {
        updates.handleLifecycle(away);
        await tester.pump();
        expect(updates.status, LiveStatus.idle, reason: '$away');
        expect(opener.latest.hasListener, isFalse, reason: '$away');
        updates.handleLifecycle(AppLifecycleState.resumed);
        await tester.pump();
        expect(updates.status, LiveStatus.open);
      }

      await session.signOut();
      await tester.pump();
      expect(updates.status, LiveStatus.idle);
      expect(opener.latest.hasListener, isFalse);
      finish();
    });

    testWidgets('a 404 or 501 turns live updates off, and nothing polls', (
      WidgetTester tester,
    ) async {
      final SessionController session = await _signedIn();
      opener.script.add(const ChangeStreamNotOffered());
      final LiveUpdates updates = build(session);
      var reads = 0;
      updates.listen(<String>{'news'}, () => reads++);

      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(updates.status, LiveStatus.off);

      await wait(tester, const Duration(minutes: 10));
      expect(opener.calls, 1, reason: 'no stream is asked for again');

      // Coming back still re-reads what is on screen, once, with no stream.
      updates.handleLifecycle(AppLifecycleState.paused);
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(reads, 1);
      expect(opener.calls, 1);
      finish();
    });

    testWidgets('expired reopens at once; a drop waits out the backoff', (
      WidgetTester tester,
    ) async {
      final LiveUpdates updates = build(await _signedIn());
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      opener.latest.add(_ready);
      await tester.pump();

      opener.latest.add('event: expired\ndata: {}\n\n');
      await tester.pump();
      expect(opener.calls, 2, reason: 'expired reopens without waiting');
      expect(opener.opened.first.hasListener, isFalse);

      opener.latest.add(_ready);
      await tester.pump();
      await opener.latest.close();
      await tester.pump();
      expect(updates.status, LiveStatus.waiting);
      await wait(tester, const Duration(milliseconds: 900));
      expect(opener.calls, 2, reason: 'never sooner than a second');
      await wait(tester, const Duration(milliseconds: 400));
      expect(opener.calls, 3);
      finish();
    });

    testWidgets('expired before ready backs off rather than looping', (
      WidgetTester tester,
    ) async {
      final LiveUpdates updates = build(await _signedIn());
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      opener.latest.add('event: expired\ndata: {}\n\n');
      await tester.pump();
      expect(opener.calls, 1);
      expect(updates.status, LiveStatus.waiting);
      finish();
    });

    testWidgets('a reconnect after the first ready and every resync re-read '
        'every listener; the first ready does not', (
      WidgetTester tester,
    ) async {
      final LiveUpdates updates = build(await _signedIn());
      var news = 0;
      var threads = 0;
      updates
        ..listen(<String>{'news'}, () => news++)
        ..listen(<String>{'threads'}, () => threads++);
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();

      opener.latest.add(_ready);
      await tester.pump();
      expect((news, threads), (0, 0));

      opener.latest.add(_change(<String>['news', 'unknown-topic']));
      await tester.pump();
      expect((news, threads), (1, 0));

      await wait(tester, const Duration(seconds: 3));
      opener.latest.add('event: resync\ndata: {}\n\n');
      await tester.pump();
      expect((news, threads), (2, 1));

      await wait(tester, const Duration(seconds: 3));
      opener.latest.add('event: expired\ndata: {}\n\n');
      await tester.pump();
      opener.latest.add(_ready);
      await tester.pump();
      expect((news, threads), (3, 2), reason: 'a reconnect re-reads');
      finish();
    });

    testWidgets('each listener runs at once, then once at the end of the '
        'window, however many changes arrived', (WidgetTester tester) async {
      final LiveUpdates updates = build(await _signedIn());
      var reads = 0;
      updates.listen(<String>{'verification'}, () => reads++);
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      opener.latest.add(_ready);
      await tester.pump();

      for (var i = 0; i < 5; i++) {
        opener.latest.add(_change(<String>['verification']));
        await wait(tester, const Duration(milliseconds: 100));
      }
      expect(reads, 1, reason: 'leading');

      await wait(tester, const Duration(seconds: 2));
      expect(reads, 2, reason: 'trailing');

      await wait(tester, const Duration(seconds: 10));
      expect(reads, 2, reason: 'nothing owed, nothing run');
      finish();
    });

    testWidgets('a return to the foreground re-reads once the stream is '
        'ready, or after the grace period', (WidgetTester tester) async {
      final LiveUpdates updates = build(await _signedIn());
      var reads = 0;
      updates.listen(<String>{'news'}, () => reads++);
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      opener.latest.add(_ready);
      await tester.pump();

      updates
        ..handleLifecycle(AppLifecycleState.paused)
        ..handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(reads, 0, reason: 'waits for ready');
      opener.latest.add(_ready);
      await tester.pump();
      expect(reads, 1);

      // A stream that takes too long to open does not hold the re-read back.
      await wait(tester, const Duration(seconds: 3));
      opener.hold = Completer<ChangeStreamOpening>();
      updates
        ..handleLifecycle(AppLifecycleState.paused)
        ..handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(reads, 1);
      await wait(tester, const Duration(seconds: 3));
      expect(reads, 2);
      updates.handleLifecycle(AppLifecycleState.paused);
      opener.hold?.complete(const ChangeStreamNotOffered());
      await tester.pump();
      finish();
    });

    testWidgets('a silent stream is presumed dead and reopened', (
      WidgetTester tester,
    ) async {
      final LiveUpdates updates = build(await _signedIn());
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      opener.latest.add(_ready);
      await tester.pump();

      await wait(tester, const Duration(seconds: 50));
      opener.latest.add(': ping\n\n');
      await wait(tester, const Duration(seconds: 50));
      expect(updates.status, LiveStatus.open, reason: 'a ping is a sign');

      // Sixty seconds after the ping, the stream is dropped and waits out the
      // backoff; after it, a new stream is open.
      await wait(tester, const Duration(milliseconds: 10500));
      expect(updates.status, LiveStatus.waiting);
      expect(opener.opened.first.hasListener, isFalse);
      await wait(tester, const Duration(seconds: 2));
      expect(opener.calls, 2);
      expect(updates.status, LiveStatus.open);
      finish();
    });

    testWidgets('a refusal asking again cannot change waits for the next '
        'return; a network failure backs off', (WidgetTester tester) async {
      final LiveUpdates updates = build(await _signedIn());
      opener.script.add(const ChangeStreamFailed(ForbiddenFailure()));
      updates.handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(updates.status, LiveStatus.idle);
      await wait(tester, const Duration(minutes: 5));
      expect(opener.calls, 1);

      opener.script.add(const ChangeStreamFailed(NetworkFailure()));
      updates
        ..handleLifecycle(AppLifecycleState.paused)
        ..handleLifecycle(AppLifecycleState.resumed);
      await tester.pump();
      expect(opener.calls, 2);
      expect(updates.status, LiveStatus.waiting);
      await wait(tester, const Duration(milliseconds: 1300));
      expect(opener.calls, 3);
      finish();
    });

    test('the backoff doubles from one second to thirty, spread by a '
        'quarter, never under the server\'s retry', () async {
      final LiveUpdates updates = build(await _signedIn());
      const List<int> bases = <int>[1, 2, 4, 8, 16, 30, 30, 30];
      for (var attempt = 0; attempt < bases.length; attempt++) {
        final int ms = updates.delayFor(attempt).inMilliseconds;
        final int base = bases[attempt] * 1000;
        expect(ms, greaterThanOrEqualTo(max(1000, (base * 0.75).floor())));
        expect(ms, lessThanOrEqualTo(min(30000, (base * 1.25).ceil())));
      }
    });

    test('a disabled instance never calls a listener', () {
      final LiveUpdates disabled = LiveUpdates.disabled();
      var reads = 0;
      disabled
        ..listen(<String>{'news'}, () => reads++)
        ..handleLifecycle(AppLifecycleState.resumed)
        ..handleLifecycle(AppLifecycleState.paused)
        ..handleLifecycle(AppLifecycleState.resumed);
      expect(reads, 0);
      expect(disabled.status, LiveStatus.off);
      disabled.dispose();
    });
  });

  group('ApiClient.openChangeStream', () {
    test('sends the bearer, the channel and text/event-stream, and puts no '
        'token in the URL', () async {
      final _StreamingTransport transport = _StreamingTransport()
        ..answers.add(_streamOk());
      final ApiClient client = ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'token-1',
      );

      final ChangeStreamOpening opening = await client.openChangeStream();

      expect(opening, isA<ChangeStreamOpen>());
      final ApiRequest request = transport.requests.single;
      expect(request.method, HttpMethod.get);
      expect(request.path, ApiClient.changeStreamPath);
      expect(request.query, isEmpty);
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.headers['Accept'], 'text/event-stream');
      expect(request.headers['X-Client-Channel'], 'citizen-mobile');
      expect(request.headers.containsKey('Cache-Control'), isFalse);
      expect(request.headers.containsKey('Last-Event-ID'), isFalse);
      expect(request.toString(), isNot(contains('token-1')));
    });

    test('a 401 refreshes the token once and opens again', () async {
      var token = 'old';
      final _StreamingTransport transport = _StreamingTransport()
        ..answers.addAll(<Result<ApiStreamResponse>>[
          _refused(401, 'UNAUTHENTICATED'),
          _streamOk(),
        ]);
      final ApiClient client = ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => token,
        authCoordinator: AuthCoordinator(
          refresher: _Refresher(() => token = 'fresh'),
        ),
      );

      final ChangeStreamOpening opening = await client.openChangeStream();

      expect(opening, isA<ChangeStreamOpen>());
      expect(
        transport.requests.map((ApiRequest r) => r.headers['Authorization']),
        <String>['Bearer old', 'Bearer fresh'],
      );
    });

    test('404, 501, a 2xx that is not a stream, and a transport that cannot '
        'stream are all "not offered"', () async {
      for (final Result<ApiStreamResponse> answer
          in <Result<ApiStreamResponse>>[
            _refused(404, 'NOT_FOUND'),
            _refused(501, 'NOT_IMPLEMENTED'),
            _streamOk(type: 'application/json'),
          ]) {
        final _StreamingTransport transport = _StreamingTransport()
          ..answers.add(answer);
        final ApiClient client = ApiClient(
          config: _config(),
          transport: transport,
          accessTokenProvider: () async => 'token-1',
        );
        expect(await client.openChangeStream(), isA<ChangeStreamNotOffered>());
      }

      final ApiClient plain = ApiClient(
        config: _config(),
        transport: _PlainTransport(),
        accessTokenProvider: () async => 'token-1',
      );
      expect(await plain.openChangeStream(), isA<ChangeStreamNotOffered>());
    });

    test('a refusal is a failure the caller can judge', () async {
      final _StreamingTransport transport = _StreamingTransport()
        ..answers.add(_refused(403, 'FORBIDDEN'));
      final ApiClient client = ApiClient(
        config: _config(),
        transport: transport,
        accessTokenProvider: () async => 'token-1',
      );
      final ChangeStreamOpening opening = await client.openChangeStream();
      expect(opening, isA<ChangeStreamFailed>());
      expect((opening as ChangeStreamFailed).failure, isA<ForbiddenFailure>());
    });
  });

  group('HttpApiTransport.openStream', () {
    test('hands the body over as text, a split character intact', () async {
      late http.BaseRequest seen;
      final MockClient client = MockClient.streaming((
        http.BaseRequest request,
        http.ByteStream body,
      ) async {
        seen = request;
        // U+00F1 is two bytes in UTF-8; the cut falls between them.
        final List<int> bytes = utf8.encode(_split);
        final int cut = bytes.indexOf(0xC3) + 1;
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable(<List<int>>[
            bytes.sublist(0, cut),
            bytes.sublist(cut),
          ]),
          200,
          headers: <String, String>{'content-type': 'text/event-stream'},
        );
      });
      final HttpApiTransport transport = HttpApiTransport(
        config: _config(),
        client: client,
      );

      final Result<ApiStreamResponse> result = await transport.openStream(
        const ApiRequest(
          method: HttpMethod.get,
          path: 'changes',
          headers: <String, String>{'Accept': 'text/event-stream'},
        ),
      );

      final ApiStreamResponse response = result.valueOrNull!;
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], 'text/event-stream');
      expect(await response.text.join(), _split);
      expect(seen.url.toString(), 'https://example.test/api/v1/changes');
      expect(seen.headers['Accept'], 'text/event-stream');
    });
  });
}

class _Refresher implements TokenRefresher {
  _Refresher(this._onRefresh);

  final void Function() _onRefresh;

  @override
  Future<String?> refresh() async {
    _onRefresh();
    return 'fresh';
  }
}

class _StreamingTransport implements ApiTransport, StreamingApiTransport {
  final List<ApiRequest> requests = <ApiRequest>[];
  final List<Result<ApiStreamResponse>> answers = <Result<ApiStreamResponse>>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      const Err<ApiHttpResponse>(NetworkFailure());

  @override
  Future<Result<ApiStreamResponse>> openStream(ApiRequest request) async {
    requests.add(request);
    return answers.removeAt(0);
  }
}

class _PlainTransport implements ApiTransport {
  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      const Err<ApiHttpResponse>(NetworkFailure());
}

Result<ApiStreamResponse> _streamOk({String type = 'text/event-stream'}) =>
    Ok<ApiStreamResponse>(
      ApiStreamResponse(
        statusCode: 200,
        headers: <String, String>{'content-type': type},
        text: const Stream<String>.empty(),
      ),
    );

Result<ApiStreamResponse> _refused(int status, String code) =>
    Ok<ApiStreamResponse>(
      ApiStreamResponse(
        statusCode: status,
        headers: const <String, String>{'content-type': 'application/json'},
        text: Stream<String>.value(
          jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': code,
              'message': 'operator text',
              'request_id': 'req-1',
            },
          }),
        ),
      ),
    );
