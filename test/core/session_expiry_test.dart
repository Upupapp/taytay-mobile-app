import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/auth_coordinator.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/push_registration.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';

const ResidentSession _resident = ResidentSession(
  accountId: 'acct-1',
  displayName: 'Maria',
  accessLevel: AccessLevel.verified,
);

/// Counts withdrawals and yields, so a second caller can interleave.
class _SlowWithdrawal implements PushRegistrationWithdrawal {
  int calls = 0;

  @override
  Future<bool> withdraw(String deviceId) async {
    calls++;
    // A real network call yields. Without this the race cannot happen in a
    // test, and a test that cannot reproduce the race proves nothing about it.
    await Future<void>.delayed(Duration.zero);
    return true;
  }
}

/// Counts how many times the app told anybody the session ended.
class _NoticeCounter {
  int expired = 0;

  void watch(SessionController controller) {
    SessionState? last;
    controller.addListener(() {
      final state = controller.state;
      final ended =
          state is GuestSession &&
          state.endedReason == SessionEndedReason.expired &&
          last is! GuestSession;
      if (ended) expired++;
      last = state;
    });
  }
}

Future<SessionController> _signedIn(
  SessionStore store,
  PushRegistrationWithdrawal withdrawal,
) async {
  await store.write(
    const StoredSession(
      resident: _resident,
      accessToken: 'tok',
      deviceId: 'device-1',
    ),
  );
  final controller = SessionController(store: store)
    ..bindPushRegistration(withdrawal);
  await controller.restore();
  return controller;
}

void main() {
  group('F22 — one expiry is one sign-out', () {
    test('ten concurrent 401s end the session once', () async {
      // The condition a resident on a municipal connection actually meets: a
      // screen fires several requests, the token dies, and every one of them
      // comes back 401 at the same moment.
      final withdrawal = _SlowWithdrawal();
      final controller = await _signedIn(InMemorySessionStore(), withdrawal);
      final notices = _NoticeCounter()..watch(controller);

      await Future.wait(<Future<void>>[
        for (int i = 0; i < 10; i++) controller.handleUnauthenticated(),
      ]);

      expect(controller.state, isA<GuestSession>());
      expect(
        notices.expired,
        1,
        reason: 'the resident is told once, not ten times',
      );
      expect(
        withdrawal.calls,
        1,
        reason:
            'ten DELETE me/devices calls for one expiry is nine requests sent '
            'with a credential the server has already refused',
      );
    });

    test('a later expiry after signing in again still reports', () async {
      // Idempotence must not become "only ever once per process".
      final withdrawal = _SlowWithdrawal();
      final store = InMemorySessionStore();
      final controller = await _signedIn(store, withdrawal);

      await controller.handleUnauthenticated();
      await controller.signIn(resident: _resident, accessToken: 'tok-2');
      await controller.handleUnauthenticated();

      expect(controller.state, isA<GuestSession>());
    });

    test('an expiry racing a deliberate sign-out does not double up', () async {
      // Resume checks the clock while a request is failing. Both paths end the
      // session and both must not run the teardown twice.
      final withdrawal = _SlowWithdrawal();
      final controller = await _signedIn(InMemorySessionStore(), withdrawal);

      await Future.wait(<Future<void>>[
        controller.handleUnauthenticated(),
        controller.signOut(),
      ]);

      expect(controller.state, isA<GuestSession>());
      expect(withdrawal.calls, 1);
    });
  });

  group('no refresh is attempted, because none exists', () {
    test(
      'a coordinator with no refresher invalidates instead of retrying',
      () async {
        // F22's recorded decision: there is no refresh endpoint on the server, and
        // a client-side approximation — retry loops, speculative re-auth — is a
        // fiction that fails differently on every connection.
        int invalidations = 0;
        final coordinator = AuthCoordinator(
          onSessionInvalidated: () async => invalidations++,
        );

        expect(coordinator.canRefresh, isFalse);
        expect(await coordinator.handleUnauthenticated(), AuthRecovery.failed);
        expect(invalidations, 1);
      },
    );

    test('concurrent 401s share one recovery attempt', () async {
      int invalidations = 0;
      final coordinator = AuthCoordinator(
        onSessionInvalidated: () async {
          await Future<void>.delayed(Duration.zero);
          invalidations++;
        },
      );

      await Future.wait(<Future<AuthRecovery>>[
        for (int i = 0; i < 10; i++) coordinator.handleUnauthenticated(),
      ]);

      expect(invalidations, 1);
    });

    test('the composition root registers no refresher', () async {
      // The source, deliberately. A behavioural test would pass just as well
      // against a build that had quietly acquired one — and acquiring one is the
      // change this guard exists to catch, because it would mean somebody had
      // built a refresh against an endpoint that does not exist.
      final String source = await File(
        'lib/app/app_dependencies.dart',
      ).readAsString();

      expect(
        source,
        contains('AuthCoordinator('),
        reason: 'the coordinator is still wired at all',
      );
      expect(
        source,
        isNot(contains('refresher:')),
        reason:
            'a TokenRefresher is registered. There is no refresh endpoint at '
            'the pinned baseline; see F22 in docs/frontend/open-work.md before '
            'deciding this is correct.',
      );
    });
  });

  group('the resident is told which of the three things happened', () {
    test(
      'expiry, deliberate sign-out and a network failure read differently',
      () async {
        // A resident dropped on the sign-in screen with one generic sentence
        // cannot tell whether something went wrong, whether they did it, or
        // whether to try again.
        final String en = await File('lib/l10n/app_en.arb').readAsString();
        final Map<String, dynamic> strings =
            jsonDecode(en) as Map<String, dynamic>;

        final List<String> variants = <String>[
          strings['signInNoticeExpired'] as String,
          strings['signInNoticeSignedOut'] as String,
          strings['signInOffline'] as String,
        ];

        expect(
          variants.toSet(),
          hasLength(3),
          reason: 'two of the three say the same thing',
        );
      },
    );

    test('the session-ended sheet does not claim work was kept', () async {
      // It used to say "Nothing you submitted has been lost." Narrowly true and
      // read as something else: this app queues nothing (DL-118), so anything
      // typed and not sent when a session dies is gone. Promising otherwise is
      // the one unacceptable outcome.
      for (final String path in <String>[
        'lib/l10n/app_en.arb',
        'lib/l10n/app_fil.arb',
      ]) {
        final Map<String, dynamic> strings =
            jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
        final String unsent = strings['sessionEndedUnsent'] as String;

        expect(
          unsent.toLowerCase(),
          isNot(contains('nothing')),
          reason: '$path promises nothing was lost',
        );
        expect(unsent, isNotEmpty, reason: '$path says nothing at all');
      }
    });

    test('every session-ending string exists in both locales', () async {
      const List<String> keys = <String>[
        'sessionEndedTitle',
        'sessionEndedBody',
        'sessionEndedUnsent',
        'sessionEndedSignInAgain',
        'signInNoticeExpired',
        'signInNoticeSignedOut',
        'signInNoticeReturnTo',
      ];

      for (final String path in <String>[
        'lib/l10n/app_en.arb',
        'lib/l10n/app_fil.arb',
      ]) {
        final Map<String, dynamic> strings =
            jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
        for (final String key in keys) {
          expect(strings[key], isA<String>(), reason: '$path is missing $key');
        }
      }
    });
  });
}
