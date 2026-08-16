import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/network/network_monitor.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';

class _ScriptedTransport implements ApiTransport {
  _ScriptedTransport(this.responses);

  /// Replayed in order; the last one repeats.
  final List<Result<ApiHttpResponse>> responses;
  int calls = 0;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}

Result<ApiHttpResponse> _json(int status, Object body) => Ok<ApiHttpResponse>(
  ApiHttpResponse(statusCode: status, body: jsonEncode(body)),
);

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

void main() {
  // ── NetworkMonitor ──────────────────────────────────────────────────────

  group('NetworkMonitor', () {
    test('starts unknown — which is not the same as offline', () {
      final monitor = NetworkMonitor();
      expect(monitor.status, NetworkStatus.unknown);
      expect(monitor.isUnreachable, isFalse);
      expect(monitor.shouldWarn, isFalse);
      expect(monitor.lastReachableAt, isNull);
    });

    test('a success makes the office reachable and stamps the time', () {
      final now = DateTime.utc(2026, 8, 16, 2);
      final monitor = NetworkMonitor(clock: () => now);

      monitor.recordOutcome(null);

      expect(monitor.status, NetworkStatus.reachable);
      expect(monitor.lastReachableAt, now);
      expect(monitor.unreachableSince, isNull);
    });

    test('a network failure is unreachable; a server refusal is not', () {
      final monitor = NetworkMonitor();

      monitor.recordOutcome(const NetworkFailure());
      expect(monitor.status, NetworkStatus.unreachable);

      // A 403 is the server speaking. Telling somebody to check their data
      // balance over a permission decision sends them out for nothing.
      monitor.recordOutcome(const ForbiddenFailure());
      expect(monitor.status, NetworkStatus.reachable);
    });

    test('every server-produced failure counts as reachable', () {
      final monitor = NetworkMonitor();
      const failures = <AppFailure>[
        ForbiddenFailure(),
        NotFoundFailure(),
        ValidationFailure(),
        ConflictFailure(),
        RateLimitedFailure(),
        ServerFailure(),
        UnauthenticatedFailure(),
        ContractFailure(),
      ];

      for (final failure in failures) {
        monitor.recordOutcome(const NetworkFailure());
        monitor.recordOutcome(failure);
        expect(
          monitor.status,
          NetworkStatus.reachable,
          reason: '${failure.kind} came from the server',
        );
      }
    });

    test('a timeout is unreachable', () {
      final monitor = NetworkMonitor()..recordOutcome(const TimeoutFailure());
      expect(monitor.status, NetworkStatus.unreachable);
    });

    test('one failure does not warn; two in a row do', () {
      final monitor = NetworkMonitor();

      monitor.recordOutcome(const NetworkFailure());
      // One dropped request is ordinary on the connections many residents have.
      expect(monitor.isUnreachable, isTrue);
      expect(monitor.shouldWarn, isFalse);

      monitor.recordOutcome(const NetworkFailure());
      expect(monitor.shouldWarn, isTrue);
    });

    test('a success clears the run and the warning', () {
      final monitor = NetworkMonitor()
        ..recordOutcome(const NetworkFailure())
        ..recordOutcome(const NetworkFailure());
      expect(monitor.shouldWarn, isTrue);

      monitor.recordOutcome(null);
      expect(monitor.shouldWarn, isFalse);
      expect(monitor.consecutiveFailures, 0);
    });

    test('unreachableSince is the start of the run, not the last failure', () {
      var now = DateTime.utc(2026, 8, 16, 2);
      final monitor = NetworkMonitor(clock: () => now);

      monitor.recordOutcome(const NetworkFailure());
      final started = monitor.unreachableSince;

      now = now.add(const Duration(minutes: 3));
      monitor.recordOutcome(const NetworkFailure());

      expect(monitor.unreachableSince, started);
    });

    test('it notifies when the verdict changes', () {
      final monitor = NetworkMonitor();
      var notifications = 0;
      monitor.addListener(() => notifications++);

      monitor.recordOutcome(null);
      expect(notifications, 1, reason: 'unknown → reachable');

      // A run of successes must not rebuild the shell per page of a feed.
      monitor
        ..recordOutcome(null)
        ..recordOutcome(null);
      expect(notifications, 1);

      monitor.recordOutcome(const NetworkFailure());
      expect(notifications, 2);
    });

    test('reset returns to unknown', () {
      final monitor = NetworkMonitor()..recordOutcome(const NetworkFailure());
      monitor.reset();
      expect(monitor.status, NetworkStatus.unknown);
      expect(monitor.consecutiveFailures, 0);
    });

    test('toString carries no URL, payload or identifier', () {
      final monitor = NetworkMonitor()..recordOutcome(const NetworkFailure());
      final text = monitor.toString();
      expect(text, isNot(contains('http')));
      expect(text, isNot(contains('/')));
    });
  });

  // ── The client tells the monitor ────────────────────────────────────────

  group('ApiClient reports outcomes', () {
    test('a transport failure moves the monitor to unreachable', () async {
      final monitor = NetworkMonitor();
      final client = ApiClient(
        config: _config(),
        transport: _ScriptedTransport(<Result<ApiHttpResponse>>[
          const Err<ApiHttpResponse>(NetworkFailure()),
        ]),
        networkMonitor: monitor,
      );

      await client.send<Object?>(
        method: HttpMethod.get,
        path: 'services',
        authenticated: false,
        decode: (data) => data,
      );

      expect(monitor.status, NetworkStatus.unreachable);
    });

    test('a 403 leaves the monitor reachable', () async {
      final monitor = NetworkMonitor();
      final client = ApiClient(
        config: _config(),
        transport: _ScriptedTransport(<Result<ApiHttpResponse>>[
          _json(403, <String, Object?>{
            'error': <String, Object?>{'code': 'FORBIDDEN', 'message': 'no'},
          }),
        ]),
        networkMonitor: monitor,
      );

      await client.send<Object?>(
        method: HttpMethod.get,
        path: 'services',
        authenticated: false,
        decode: (data) => data,
      );

      expect(monitor.status, NetworkStatus.reachable);
    });

    test('a request never attempted is not counted', () async {
      final monitor = NetworkMonitor();
      final client = ApiClient(
        config: _config(),
        transport: _ScriptedTransport(<Result<ApiHttpResponse>>[
          _json(200, <String, Object?>{'data': <String, Object?>{}}),
        ]),
        networkMonitor: monitor,
      );

      // Authenticated with no token: refused before the transport is reached,
      // so it says nothing about the connection.
      await client.send<Object?>(
        method: HttpMethod.get,
        path: 'me',
        authenticated: true,
        decode: (data) => data,
      );

      expect(monitor.status, NetworkStatus.unknown);
    });
  });

  // ── PublicCache ─────────────────────────────────────────────────────────

  group('PublicCache keys', () {
    test('the query is part of the key', () {
      expect(
        PublicCache.keyFor('services', <String, String>{'page': '1'}),
        isNot(PublicCache.keyFor('services', <String, String>{'page': '3'})),
      );
    });

    test('parameter order does not create a second entry', () {
      expect(
        PublicCache.keyFor('services', <String, String>{
          'page': '1',
          'per_page': '25',
        }),
        PublicCache.keyFor('services', <String, String>{
          'per_page': '25',
          'page': '1',
        }),
      );
    });

    test('page 3 is never served to a request for page 1', () {
      final cache = PublicCache()
        ..store<String>(
          key: PublicCache.keyFor('services', <String, String>{'page': '3'}),
          value: 'third page',
          authenticated: false,
        );

      expect(
        cache.read<String>(
          PublicCache.keyFor('services', <String, String>{'page': '1'}),
        ),
        isNull,
      );
    });

    test('the allow-list is checked against the path, not the whole key', () {
      final cache = PublicCache();

      expect(
        cache.store<String>(
          key: PublicCache.keyFor('events', <String, String>{'scope': 'past'}),
          value: 'x',
          authenticated: false,
        ),
        isTrue,
      );
      expect(
        cache.store<String>(
          key: PublicCache.keyFor('me/requests', <String, String>{'page': '1'}),
          value: 'x',
          authenticated: false,
        ),
        isFalse,
      );
    });

    test('an authenticated response is refused whatever the path', () {
      final cache = PublicCache();
      expect(
        cache.store<String>(key: 'services', value: 'x', authenticated: true),
        isFalse,
      );
      expect(cache.size, 0);
    });
  });

  group('PublicCache staleness', () {
    test('read still evicts a stale entry', () {
      var now = DateTime.utc(2026, 8, 16, 2);
      final cache = PublicCache(clock: () => now)
        ..store<String>(key: 'services', value: 'x', authenticated: false);

      now = now.add(const Duration(minutes: 6));
      expect(cache.read<String>('services'), isNull);
      expect(cache.size, 0);
    });

    test('readAllowingStale returns the value with its age, and keeps it', () {
      var now = DateTime.utc(2026, 8, 16, 2);
      final cache = PublicCache(
        clock: () => now,
      )..store<String>(key: 'events', value: 'yesterday', authenticated: false);
      final storedAt = now;

      now = now.add(const Duration(hours: 9));
      final read = cache.readAllowingStale<String>('events');

      expect(read, isNotNull);
      expect(read!.value, 'yesterday');
      expect(read.isFresh, isFalse);
      expect(read.storedAt, storedAt);
      expect(cache.size, 1, reason: 'the offline path does not evict');
    });

    test('a fresh entry reports itself fresh', () {
      final cache = PublicCache()
        ..store<String>(key: 'events', value: 'now', authenticated: false);
      expect(cache.readAllowingStale<String>('events')!.isFresh, isTrue);
    });

    test('a type mismatch returns null instead of throwing', () {
      final cache = PublicCache()
        ..store<String>(key: 'services', value: 'x', authenticated: false);
      expect(cache.readAllowingStale<int>('services'), isNull);
    });

    test('storedAt is the fetch time, not the expiry', () {
      final now = DateTime.utc(2026, 8, 16, 2);
      final cache = PublicCache(clock: () => now)
        ..store<String>(key: 'health', value: 'ok', authenticated: false);

      expect(cache.readAllowingStale<String>('health')!.storedAt, now);
    });
  });

  group('PublicCache capacity', () {
    test('the oldest entries go first when the ceiling is passed', () {
      var now = DateTime.utc(2026, 8, 16, 2);
      final cache = PublicCache(
        maxEntries: 3,
        clock: () => now,
        defaultTtl: const Duration(hours: 1),
      );

      for (var i = 0; i < 5; i++) {
        cache.store<String>(
          key: PublicCache.keyFor('events', <String, String>{'page': '$i'}),
          value: 'page $i',
          authenticated: false,
        );
        now = now.add(const Duration(seconds: 1));
      }

      expect(cache.size, 3);
      expect(
        cache.read<String>(
          PublicCache.keyFor('events', <String, String>{'page': '0'}),
        ),
        isNull,
      );
      expect(
        cache.read<String>(
          PublicCache.keyFor('events', <String, String>{'page': '4'}),
        ),
        'page 4',
      );
    });
  });
}
