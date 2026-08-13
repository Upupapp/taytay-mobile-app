import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';

const ResidentSession _unverified = ResidentSession(
  accountId: 'acct-1',
  accessLevel: AccessLevel.unverified,
);
const ResidentSession _verified = ResidentSession(
  accountId: 'acct-1',
  accessLevel: AccessLevel.verified,
);

void main() {
  group('AccessLevel', () {
    test('is ordered guest < unverified < verified', () {
      expect(AccessLevel.verified.satisfies(AccessLevel.unverified), isTrue);
      expect(AccessLevel.unverified.satisfies(AccessLevel.verified), isFalse);
      expect(AccessLevel.guest.satisfies(AccessLevel.guest), isTrue);
      expect(AccessLevel.guest.isAuthenticated, isFalse);
      expect(AccessLevel.unverified.isAuthenticated, isTrue);
    });

    test('an unknown verification tier is never read as verified', () {
      // Fail closed: a tier this build has not heard of must not be trusted.
      expect(
        AccessLevel.fromVerificationTier('verified'),
        AccessLevel.verified,
      );
      for (final tier in <String?>[
        null,
        '',
        'pending',
        'VERIFIED',
        'tier_3',
        'admin',
      ]) {
        expect(
          AccessLevel.fromVerificationTier(tier),
          AccessLevel.unverified,
          reason: 'tier: $tier',
        );
      }
    });
  });

  group('SessionState', () {
    test('restoring is unresolved and is not treated as signed in', () {
      const state = SessionRestoring();
      expect(state.isResolved, isFalse);
      expect(state.accessLevel, AccessLevel.guest);
      expect(state.residentOrNull, isNull);
    });

    test('guest and authenticated states are resolved', () {
      expect(const GuestSession().isResolved, isTrue);
      expect(const AuthenticatedSession(_verified).isResolved, isTrue);
      expect(
        const AuthenticatedSession(_verified).accessLevel,
        AccessLevel.verified,
      );
    });

    test('toString reveals no personal data', () {
      const resident = ResidentSession(
        accountId: 'acct-secret',
        accessLevel: AccessLevel.verified,
        displayName: 'Juan',
      );
      final text = const AuthenticatedSession(resident).toString();
      expect(text, isNot(contains('acct-secret')));
      expect(text, isNot(contains('Juan')));
    });
  });

  group('SessionController', () {
    late SessionController controller;
    late InMemorySessionStore store;

    setUp(() {
      store = InMemorySessionStore();
      controller = SessionController(store: store);
    });

    tearDown(() => controller.dispose());

    test('starts in the restoring state', () {
      expect(controller.state, isA<SessionRestoring>());
    });

    test('restore with nothing stored produces a guest session', () async {
      await controller.restore();
      expect(controller.state, const GuestSession());
    });

    test('restore resumes a stored session', () async {
      await store.write(
        const StoredSession(resident: _verified, accessToken: 'token'),
      );
      await controller.restore();

      expect(controller.state, const AuthenticatedSession(_verified));
      expect(await controller.currentAccessToken(), 'token');
    });

    test('signIn persists the session and notifies listeners', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.signIn(resident: _unverified, accessToken: 'token');

      expect(controller.state, const AuthenticatedSession(_unverified));
      expect(await store.read(), isNotNull);
      expect(notifications, 1);
    });

    test('signOut clears storage and records the reason', () async {
      await controller.signIn(resident: _verified, accessToken: 'token');
      await controller.signOut();

      expect(
        controller.state,
        const GuestSession(endedReason: SessionEndedReason.signedOut),
      );
      expect(await store.read(), isNull);
      expect(await controller.currentAccessToken(), isNull);
    });

    test('a 401 ends the session as expired and wipes the token', () async {
      await controller.signIn(resident: _verified, accessToken: 'token');
      await controller.handleUnauthenticated();

      expect(
        controller.state,
        const GuestSession(endedReason: SessionEndedReason.expired),
      );
      expect(await store.read(), isNull);
    });

    test('concurrent 401s end the session once', () async {
      await controller.signIn(resident: _verified, accessToken: 'token');

      var notifications = 0;
      controller.addListener(() => notifications++);

      await Future.wait<void>(<Future<void>>[
        controller.handleUnauthenticated(),
        controller.handleUnauthenticated(),
        controller.handleUnauthenticated(),
      ]);

      expect(notifications, 1);
    });

    test('a verification tier from the server upgrades the level', () async {
      await controller.signIn(resident: _unverified, accessToken: 'token');
      controller.applyVerificationTier('verified');

      expect(controller.accessLevel, AccessLevel.verified);
    });

    test('a verification tier cannot promote a guest', () async {
      await controller.restore();
      controller.applyVerificationTier('verified');

      expect(controller.state, const GuestSession());
      expect(controller.accessLevel, AccessLevel.guest);
    });
  });

  group('AccessPolicy', () {
    AccessDecision decide(SessionState session, AccessRequirement requirement) =>
        AccessPolicy.evaluate(session: session, requirement: requirement);

    test('public routes are open to everyone, even while restoring', () {
      for (final session in <SessionState>[
        const SessionRestoring(),
        const GuestSession(),
        const AuthenticatedSession(_unverified),
        const AuthenticatedSession(_verified),
      ]) {
        expect(
          decide(session, AccessRequirement.public),
          const AccessAllowed(),
          reason: '$session',
        );
      }
    });

    test('a protected route waits while the session is restoring', () {
      expect(
        decide(const SessionRestoring(), AccessRequirement.authenticated),
        const AccessPending(),
      );
      expect(
        decide(const SessionRestoring(), AccessRequirement.verified),
        const AccessPending(),
      );
    });

    test('a guest is sent to authenticate', () {
      expect(
        decide(const GuestSession(), AccessRequirement.authenticated),
        const AccessNeedsAuthentication(),
      );
      expect(
        decide(const GuestSession(), AccessRequirement.verified),
        const AccessNeedsAuthentication(),
      );
    });

    test('an unverified resident may use authenticated routes only', () {
      expect(
        decide(
          const AuthenticatedSession(_unverified),
          AccessRequirement.authenticated,
        ),
        const AccessAllowed(),
      );
      expect(
        decide(
          const AuthenticatedSession(_unverified),
          AccessRequirement.verified,
        ),
        const AccessNeedsVerification(),
      );
    });

    test('a verified resident may use everything', () {
      for (final requirement in AccessRequirement.values) {
        expect(
          decide(const AuthenticatedSession(_verified), requirement),
          const AccessAllowed(),
          reason: requirement.name,
        );
      }
    });
  });
}
