import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/push_registration.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';

/// Records what it was asked to withdraw, and can refuse.
class RecordingWithdrawal implements PushRegistrationWithdrawal {
  RecordingWithdrawal({this.succeeds = true});

  final bool succeeds;
  final List<String> withdrawn = <String>[];

  @override
  Future<bool> withdraw(String deviceId) async {
    withdrawn.add(deviceId);
    return succeeds;
  }
}

/// Fails the way a network does: slowly, and by throwing.
class HostileWithdrawal implements PushRegistrationWithdrawal {
  @override
  Future<bool> withdraw(String deviceId) async =>
      throw StateError('the network is gone');
}

const ResidentSession resident = ResidentSession(
  accountId: 'acct-1',
  displayName: 'Maria',
  accessLevel: AccessLevel.verified,
);

Future<SessionController> signedIn(
  SessionStore store,
  PushRegistrationWithdrawal? withdrawal, {
  String? deviceId,
}) async {
  await store.write(
    StoredSession(resident: resident, accessToken: 'tok', deviceId: deviceId),
  );
  final controller = SessionController(store: store);
  if (withdrawal != null) controller.bindPushRegistration(withdrawal);
  await controller.restore();
  return controller;
}

void main() {
  group('F27 — a registration does not outlive its session', () {
    test('signing out withdraws this device, and only this device', () async {
      final withdrawal = RecordingWithdrawal();
      final controller = await signedIn(
        InMemorySessionStore(),
        withdrawal,
        deviceId: 'device-abc',
      );

      await controller.signOut();

      expect(withdrawal.withdrawn, <String>['device-abc']);
      expect(controller.state, isA<GuestSession>());
    });

    test('an expiring session withdraws too', () async {
      // The other way a session ends. A path that forgets is the one that
      // matters, because it is the one nobody demonstrates by hand.
      final withdrawal = RecordingWithdrawal();
      final controller = await signedIn(
        InMemorySessionStore(),
        withdrawal,
        deviceId: 'device-abc',
      );

      await controller.handleUnauthenticated();

      expect(withdrawal.withdrawn, <String>['device-abc']);
    });

    test('nothing registered means nothing is deleted', () async {
      // Deleting a device this install did not register is not this app's
      // business, and a `null` id is the normal state for a build with no push.
      final withdrawal = RecordingWithdrawal();
      final controller = await signedIn(InMemorySessionStore(), withdrawal);

      await controller.signOut();

      expect(withdrawal.withdrawn, isEmpty);
    });

    test('the id is remembered when a registration is made', () async {
      final store = InMemorySessionStore();
      final controller = await signedIn(store, RecordingWithdrawal());

      await controller.rememberDeviceRegistration('device-xyz');

      expect((await store.read())?.deviceId, 'device-xyz');
    });
  });

  group('a resident who asks to sign out is signed out', () {
    test('a refused withdrawal does not hold the session open', () async {
      final withdrawal = RecordingWithdrawal(succeeds: false);
      final controller = await signedIn(
        InMemorySessionStore(),
        withdrawal,
        deviceId: 'device-abc',
      );

      await controller.signOut();

      expect(controller.state, isA<GuestSession>());
      expect(
        controller.lastWithdrawalSucceeded,
        isFalse,
        reason:
            'the failure is kept, because a registration that outlived its '
            'session is the condition F27 is about',
      );
    });

    test('a withdrawal that throws does not take the sign-out with it', () async {
      // The contract says implementations must not throw. This asserts what
      // happens when one does anyway — the resident still gets signed out,
      // because holding a local session open on a server's behaviour at the
      // exact moment somebody is trying to leave is the worst available outcome.
      final controller = await signedIn(
        InMemorySessionStore(),
        HostileWithdrawal(),
        deviceId: 'device-abc',
      );

      await expectLater(controller.signOut(), completes);
      expect(controller.state, isA<GuestSession>());
    });

    test('the token is still present while the withdrawal runs', () async {
      // Ordering, asserted rather than assumed: the call needs the very
      // credential the sign-out is about to discard, so it must happen first.
      final store = InMemorySessionStore();
      late String? tokenDuringWithdrawal;

      final controller = await signedIn(
        store,
        _Inspecting(() async {
          tokenDuringWithdrawal = (await store.read())?.accessToken;
        }),
        deviceId: 'device-abc',
      );

      await controller.signOut();

      expect(tokenDuringWithdrawal, 'tok');
      expect(await store.read(), isNull);
    });
  });
}

class _Inspecting implements PushRegistrationWithdrawal {
  _Inspecting(this.onWithdraw);

  final Future<void> Function() onWithdraw;

  @override
  Future<bool> withdraw(String deviceId) async {
    await onWithdraw();
    return true;
  }
}
