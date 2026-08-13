import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/intent/intent_controller.dart';
import 'package:taytay_resident/core/intent/resident_intent.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/router/route_guard.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

const SessionState restoring = SessionRestoring();
const SessionState guest = GuestSession();
const SessionState expired = GuestSession(
  endedReason: SessionEndedReason.expired,
);
const SessionState unverified = AuthenticatedSession(
  ResidentSession(accountId: 'a', accessLevel: AccessLevel.unverified),
);
const SessionState verified = AuthenticatedSession(
  ResidentSession(accountId: 'a', accessLevel: AccessLevel.verified),
);

/// A secret store that fails every operation, for the degraded-read path.
class _FailingSecretStore implements SecretStore {
  @override
  Future<void> clear() async => throw StateError('keystore unavailable');

  @override
  Future<void> delete(String key) async => throw StateError('unavailable');

  @override
  Future<String?> read(String key) async => throw StateError('unavailable');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('unavailable');
}

void main() {
  group('LaunchController', () {
    test('starts restoring — never "not seen" before it is read', () {
      // Reporting firstLaunch before the read would flash the welcome scenes at
      // a returning resident on every cold start.
      final controller = LaunchController(secrets: InMemorySecretStore());
      expect(controller.state, LaunchState.restoring);
      expect(controller.isResolved, isFalse);
    });

    test('a fresh install resolves to first launch', () async {
      final controller = LaunchController(secrets: InMemorySecretStore());
      await controller.restore();
      expect(controller.state, LaunchState.firstLaunch);
      expect(controller.isFirstLaunch, isTrue);
    });

    test('completing the welcome persists, so it is not shown again', () async {
      final secrets = InMemorySecretStore();
      final first = LaunchController(secrets: secrets);
      await first.restore();
      await first.markWelcomeCompleted();
      expect(first.state, LaunchState.returning);

      // A later launch, a new controller, the same install.
      final second = LaunchController(secrets: secrets);
      await second.restore();
      expect(second.state, LaunchState.returning);
    });

    test('skipping counts as completed — no onboarding trap', () async {
      // Skip and finish call the same method deliberately: re-asking would
      // override a decision the resident already made.
      final secrets = InMemorySecretStore();
      final controller = LaunchController(secrets: secrets);
      await controller.restore();
      await controller.markWelcomeCompleted();

      expect(
        await secrets.read(LaunchController.welcomeCompletedKey),
        isNotNull,
      );
    });

    test('a keystore read failure degrades to showing the welcome', () async {
      // Showing it twice is a minor annoyance; skipping it for a genuine
      // first-time resident means they never learn what the app asks for.
      final controller = LaunchController(secrets: _FailingSecretStore());
      await controller.restore();
      expect(controller.state, LaunchState.firstLaunch);
    });

    test('a keystore write failure never blocks entry to the app', () async {
      final controller = LaunchController(secrets: _FailingSecretStore());
      await controller.restore();
      await controller.markWelcomeCompleted();
      expect(controller.state, LaunchState.returning);
    });

    test('notifies listeners when the state resolves', () async {
      final controller = LaunchController(secrets: InMemorySecretStore());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.restore();
      await controller.markWelcomeCompleted();

      expect(notifications, 2);
    });
  });

  group('startup routing', () {
    test('holds on the splash while either input is still restoring', () {
      // Session known but launch unread is just as undecided as the reverse.
      expect(
        resolveRedirect(
          session: guest,
          location: AppRoute.home.path,
          launch: LaunchState.restoring,
        ),
        AppRoute.splash.path,
      );
      expect(
        resolveRedirect(
          session: restoring,
          location: AppRoute.home.path,
        ),
        AppRoute.splash.path,
      );
      expect(
        resolveRedirect(
          session: restoring,
          location: AppRoute.splash.path,
          launch: LaunchState.restoring,
        ),
        isNull,
      );
    });

    test('first launch goes from splash to the welcome scenes', () {
      expect(
        resolveRedirect(
          session: guest,
          location: AppRoute.splash.path,
          launch: LaunchState.firstLaunch,
        ),
        AppRoute.onboarding.path,
      );
    });

    test('a returning guest goes straight to home', () {
      expect(
        resolveRedirect(
          session: guest,
          location: AppRoute.splash.path,
          launch: LaunchState.returning,
        ),
        AppRoute.home.path,
      );
    });

    test('an authenticated resident is never sent through the welcome', () {
      for (final session in <SessionState>[unverified, verified]) {
        expect(
          resolveRedirect(
            session: session,
            location: AppRoute.splash.path,
            launch: LaunchState.returning,
          ),
          AppRoute.home.path,
        );
      }
    });

    test('an expired session lands on sign-in, which explains why', () {
      // The reason travels on the session, so the sign-in screen can say the
      // session ended rather than appearing without explanation.
      expect(
        resolveRedirect(
          session: expired,
          location: AppRoute.splash.path,
        ),
        AppRoute.home.path,
      );
      expect(
        resolveRedirect(session: expired, location: AppRoute.account.path),
        startsWith(AppRoute.signIn.path),
      );
      expect((expired as GuestSession).endedReason, SessionEndedReason.expired);
    });

    test('the welcome route is escapable and never a redirect target', () {
      // No session state is trapped on onboarding: it is public, and the guard
      // only routes *into* it from the splash on a genuine first launch.
      for (final session in <SessionState>[guest, unverified, verified]) {
        expect(
          resolveRedirect(
            session: session,
            location: AppRoute.onboarding.path,
            launch: LaunchState.firstLaunch,
          ),
          isNull,
          reason: '$session must be able to leave onboarding',
        );
      }
      expect(AppRoute.onboarding.requirement, AccessRequirement.public);
    });

    test('first launch does not weaken any access requirement', () {
      // Being new is not a capability: a guest on first launch still cannot
      // reach the digital ID.
      expect(
        resolveRedirect(
          session: guest,
          location: AppRoute.digitalId.path,
          launch: LaunchState.firstLaunch,
        ),
        startsWith(AppRoute.signIn.path),
      );
      expect(
        resolveRedirect(
          session: unverified,
          location: AppRoute.digitalId.path,
          launch: LaunchState.firstLaunch,
        ),
        AppRoute.verification.path,
      );
    });
  });

  group('ResidentIntent — bounded and non-sensitive', () {
    test('rejects a target id that is not an opaque identifier', () {
      // Free text here would be a channel for personal data into a gate sheet.
      for (final hostile in <String>[
        'I want to complain about my neighbour',
        'https://example.test/steal',
        'juan dela cruz',
        '09171234567 please call me',
      ]) {
        expect(
          () => ResidentIntent(
            kind: ResidentIntentKind.likePost,
            targetId: hostile,
            createdAt: DateTime(2026, 8, 14),
          ),
          throwsAssertionError,
          reason: hostile,
        );
      }
    });

    test('accepts UUIDs and stable service codes', () {
      for (final safe in <String>[
        '018f2c8a-0a01-7000-8000-00000000c001',
        'CEDULA',
        'post_123',
      ]) {
        expect(
          ResidentIntent(
            kind: ResidentIntentKind.likePost,
            targetId: safe,
            createdAt: DateTime(2026, 8, 14),
          ).targetId,
          safe,
        );
      }
    });

    test('toString reveals neither the target nor anything personal', () {
      final intent = ResidentIntent(
        kind: ResidentIntentKind.likePost,
        targetId: 'post_secret',
        createdAt: DateTime(2026, 8, 14),
      );
      expect(intent.toString(), isNot(contains('post_secret')));
    });

    test('every kind declares a gate and fixed, non-resident copy', () {
      for (final kind in ResidentIntentKind.values) {
        expect(kind.description, isNotEmpty, reason: kind.name);
        expect(
          kind.requirement,
          isNot(AccessRequirement.public),
          reason: '${kind.name} would need no gate at all',
        );
      }
    });

    test('the credential intent requires verification, not merely an account', () {
      expect(
        ResidentIntentKind.viewDigitalId.requirement,
        AccessRequirement.verified,
      );
      expect(
        ResidentIntentKind.applyForService.requirement,
        AccessRequirement.verified,
      );
      expect(
        ResidentIntentKind.likePost.requirement,
        AccessRequirement.authenticated,
      );
    });

    test('expires after a bounded lifetime', () {
      final created = DateTime(2026, 8, 14, 12);
      final intent = ResidentIntent(
        kind: ResidentIntentKind.likePost,
        createdAt: created,
      );

      expect(intent.isExpired(created.add(const Duration(minutes: 9))), isFalse);
      expect(intent.isExpired(created.add(ResidentIntent.ttl)), isTrue);
      expect(ResidentIntent.ttl, lessThanOrEqualTo(const Duration(minutes: 15)));
    });
  });

  group('IntentController', () {
    late DateTime now;
    late IntentController controller;

    setUp(() {
      now = DateTime(2026, 8, 14, 12);
      controller = IntentController(clock: () => now);
    });

    tearDown(() => controller.dispose());

    test('holds at most one intent', () {
      controller
        ..remember(ResidentIntentKind.likePost, targetId: 'post_1')
        ..remember(ResidentIntentKind.registerForEvent, targetId: 'event_2');

      expect(controller.pending!.kind, ResidentIntentKind.registerForEvent);
    });

    test('drops an expired intent on read', () {
      controller.remember(ResidentIntentKind.likePost);
      now = now.add(ResidentIntent.ttl);

      expect(controller.pending, isNull);
      expect(controller.hasPending, isFalse);
    });

    test('does not resume while the session still fails the gate', () {
      controller.remember(ResidentIntentKind.viewDigitalId);

      // A guest, and then an account that is signed in but not verified.
      expect(controller.takeIfSatisfied(guest), isNull);
      expect(controller.takeIfSatisfied(unverified), isNull);
      // Still held: the resident is on their way to the same goal.
      expect(controller.hasPending, isTrue);
    });

    test('resumes once the session satisfies the gate, then forgets it', () {
      controller.remember(ResidentIntentKind.viewDigitalId);

      final resumed = controller.takeIfSatisfied(verified);
      expect(resumed?.kind, ResidentIntentKind.viewDigitalId);

      // Consumed: a rebuild must not replay it.
      expect(controller.takeIfSatisfied(verified), isNull);
      expect(controller.hasPending, isFalse);
    });

    test('never resumes while the session is still restoring', () {
      controller.remember(ResidentIntentKind.viewDigitalId);
      expect(controller.takeIfSatisfied(restoring), isNull);
      expect(controller.hasPending, isTrue);
    });

    test('an expired intent is never resumed even when satisfied', () {
      controller.remember(ResidentIntentKind.viewDigitalId);
      now = now.add(ResidentIntent.ttl);
      expect(controller.takeIfSatisfied(verified), isNull);
    });

    test('a session change clears whatever was held', () {
      // Resuming an action for a different account is the failure this prevents.
      controller.remember(ResidentIntentKind.viewDigitalId);
      controller.onSessionChanged();

      expect(controller.hasPending, isFalse);
      expect(controller.takeIfSatisfied(verified), isNull);
    });

    test('an authenticated-only intent resumes for an unverified resident', () {
      controller.remember(ResidentIntentKind.likePost);
      expect(controller.takeIfSatisfied(unverified)?.kind,
          ResidentIntentKind.likePost);
    });

    test('notifies listeners on remember, resume and clear', () {
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.remember(ResidentIntentKind.likePost);
      controller.takeIfSatisfied(unverified);
      controller.remember(ResidentIntentKind.likePost);
      controller.clear();

      expect(notifications, 4);
    });

    test('clearing nothing does not notify', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.clear();
      expect(notifications, 0);
    });

    test('resumption destinations exist only for built screens', () {
      // Intents whose backend modules are planned (TAB 05 gap D-2) deliberately
      // have no destination, rather than an invented one that would only fail.
      expect(ResidentIntentKind.viewDigitalId.destination, AppRoute.digitalId);
      expect(
        ResidentIntentKind.manageNotifications.destination,
        AppRoute.account,
      );
      for (final kind in <ResidentIntentKind>[
        ResidentIntentKind.likePost,
        ResidentIntentKind.commentOnPost,
        ResidentIntentKind.registerForEvent,
        ResidentIntentKind.applyForService,
        ResidentIntentKind.saveService,
      ]) {
        expect(kind.destination, isNull, reason: kind.name);
      }
    });

    test('a destination never contradicts the intent it resumes', () {
      // If a destination existed that needed *more* than the intent declared,
      // resuming would land the resident on a screen the guard bounces them off.
      for (final kind in ResidentIntentKind.values) {
        final destination = kind.destination;
        if (destination == null) continue;
        expect(
          destination.requirement.minimumLevel.rank,
          lessThanOrEqualTo(kind.requirement.minimumLevel.rank),
          reason: kind.name,
        );
      }
    });
  });
}
