import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/storage/offline_policy.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';

/// Holds the written offline policy against what the code actually does.
///
/// The Master Command asks for the policy first and the implementation second.
/// This is what makes that ordering mean something a year later: an undocumented
/// cache becomes an accidental one, and the way it becomes accidental is that
/// somebody adds a path to make a screen faster and nobody records why.
void main() {
  group('the policy and the cache agree', () {
    test('the allow-list is exactly what the policy calls cacheable', () {
      // Both directions. A path in the cache and not the policy is an
      // undocumented cache; a path in the policy and not the cache is a promise
      // the app does not keep.
      expect(PublicCache.defaultAllowedPaths, unorderedEquals(cacheablePaths));
    });

    test('nothing under `me/` is cacheable', () {
      // The boundary the whole policy turns on: public municipal content is the
      // same for everybody, and anything about one resident is not cached at
      // all, because a shared handset is ordinary here.
      for (final String path in PublicCache.defaultAllowedPaths) {
        expect(path.startsWith('me/'), isFalse, reason: path);
      }
    });

    test('every rule says why, in more than a word', () {
      // A policy line with no reason is a line the next person deletes or
      // widens, because they cannot tell which it was.
      for (final OfflineRule rule in offlinePolicy) {
        expect(
          rule.because.trim().length,
          greaterThan(40),
          reason: rule.feature,
        );
        expect(rule.feature.trim(), isNotEmpty);
      }
    });

    test('authority-shaped values are never cached, not merely uncached', () {
      // Distinct from `onlineOnly`: these must be re-read on every use even when
      // a connection exists, because a cached "verified" is a permission the
      // server did not grant today.
      final Set<String> neverCached = <String>{
        for (final OfflineRule rule in offlinePolicy)
          if (rule.posture == OfflinePosture.neverCached) rule.feature,
      };
      expect(
        neverCached,
        containsAll(<String>[
          'Verification tier',
          'Digital ID and its QR',
          'Event availability',
        ]),
      );
    });
  });

  group('the cache refuses what the policy forbids', () {
    test('an authenticated response is never stored, whatever its path', () {
      // The rule that makes the allow-list safe: even a path on it cannot be
      // cached once there is a caller behind the request, because the server
      // downgrades the directive to `private` at that moment.
      final PublicCache cache = PublicCache();
      for (final String path in PublicCache.defaultAllowedPaths) {
        cache.store<String>(
          key: PublicCache.keyFor(path),
          value: 'x',
          authenticated: true,
        );
      }
      expect(cache.size, 0);
    });

    test('a path outside the allow-list is refused even unauthenticated', () {
      final PublicCache cache = PublicCache()
        ..store<String>(
          key: PublicCache.keyFor('me/cases'),
          value: 'x',
          authenticated: false,
        );
      expect(cache.size, 0);
    });

    test('the key carries the query, so page 3 is not served for page 1', () {
      expect(
        PublicCache.keyFor('services', const <String, String>{'page': '1'}),
        isNot(
          PublicCache.keyFor('services', const <String, String>{'page': '3'}),
        ),
      );
    });
  });

  group('a stale read announces itself', () {
    test('readAllowingStale reports freshness rather than hiding it', () {
      // "Last updated" beats a silently old screen. The value comes back with
      // its age attached so the screen has to say something about it.
      final PublicCache cache = PublicCache()
        ..store<String>(
          key: PublicCache.keyFor('services'),
          value: 'catalogue',
          authenticated: false,
        );

      final CachedRead<String>? read = cache.readAllowingStale<String>(
        PublicCache.keyFor('services'),
      );
      expect(read, isNotNull);
      expect(read!.value, 'catalogue');
      expect(read.storedAt, isNotNull);
      expect(read.isFresh, isTrue);
    });
  });

  group('no offline write queue exists, and that is the decision', () {
    test('nothing in lib queues a write for later', () {
      // The Master Command allows queuing genuinely idempotent writes. This app
      // does not, and the reason is that the set of writes it has are the wrong
      // ones for it: an assistance submission, a document upload and an event
      // registration are all things whose meaning depends on *when* they
      // arrive. A registration queued on Tuesday and sent on Thursday claims a
      // place at an event that filled on Wednesday; an assistance draft
      // submitted from a queue reaches the office after the resident has already
      // walked in and asked in person.
      //
      // What the app does instead is TAB 25's `UnsentNotice`: it says "not
      // sent", never "saved", so a resident knows the office has not been told
      // and chases it themselves. Recorded as a test so that adding a queue is a
      // deliberate act with this reasoning in front of whoever adds it.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final String source = entity.readAsStringSync();
        for (final String marker in <String>[
          'OutboxQueue',
          'PendingWriteQueue',
          'queueForRetry',
          'replayPendingWrites',
        ]) {
          if (source.contains(marker)) {
            offenders.add('${entity.path}: $marker');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });
}
