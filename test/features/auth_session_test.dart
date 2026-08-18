import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/app_lock_controller.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_controller.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/auth/data/planned_device_session_repository.dart';
import 'package:taytay_resident/features/auth/domain/auth_repository.dart';
import 'package:taytay_resident/features/auth/domain/sign_in_challenge.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_controller.dart';

/// An [AuthRepository] each test dictates.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.requestOutcome, this.verifyOutcome});

  Result<void>? requestOutcome;
  Result<AuthOutcome>? verifyOutcome;

  int requestCalls = 0;
  int verifyCalls = 0;
  final List<String> codesSeen = <String>[];

  @override
  Future<Result<void>> requestOneTimeCode({
    required String mobileNumber,
  }) async {
    requestCalls++;
    return requestOutcome ?? const Ok<void>(null);
  }

  @override
  Future<Result<AuthOutcome>> verifyOneTimeCode({
    required String mobileNumber,
    required String code,
  }) async {
    verifyCalls++;
    codesSeen.add(code);
    return verifyOutcome ??
        const Ok<AuthOutcome>(
          AuthOutcome(
            resident: ResidentSession(
              accountId: 'acct-1',
              accessLevel: AccessLevel.unverified,
            ),
            accessToken: 'token',
          ),
        );
  }

  @override
  Future<Result<void>> signOut() async => const Ok<void>(null);
}

/// A [LocalAuthenticator] each test dictates. Nothing here talks to a platform.
class FakeLocalAuthenticator implements LocalAuthenticator {
  FakeLocalAuthenticator({
    this.reported = LocalUnlockAvailability.available,
    this.outcome = LocalUnlockOutcome.unlocked,
  });

  LocalUnlockAvailability reported;
  LocalUnlockOutcome outcome;
  int prompts = 0;

  @override
  Future<LocalUnlockAvailability> availability() async => reported;

  @override
  Future<LocalUnlockOutcome> authenticate({required String reason}) async {
    prompts++;
    return outcome;
  }
}

Future<SessionController> signedIn(
  SessionStore store, {
  DateTime Function()? clock,
  DateTime? expiresAt,
}) async {
  final controller = SessionController(store: store, clock: clock);
  await controller.signIn(
    resident: const ResidentSession(
      accountId: 'acct-1',
      accessLevel: AccessLevel.unverified,
    ),
    accessToken: 'token',
    expiresAt: expiresAt,
  );
  return controller;
}

void main() {
  group('identifiers and codes', () {
    test('only a Philippine mobile number is accepted', () {
      expect(SignInIdentifier.validate('09171234567'), isNull);
      expect(SignInIdentifier.validate(''), isNotNull);
      expect(SignInIdentifier.validate('12345'), isNotNull);
      expect(SignInIdentifier.validate('0917123456'), isNotNull);
      expect(SignInIdentifier.validate('19171234567'), isNotNull);
    });

    test('validation talks about the input, never about the account', () {
      // A message that mentioned an account would be the enumeration oracle
      // this whole flow is built to avoid.
      for (final input in <String>['', '12345', 'abc']) {
        final message = SignInIdentifier.validate(input)!.toLowerCase();
        for (final leak in <String>[
          'account',
          'registered',
          'not found',
          'exists',
        ]) {
          expect(message, isNot(contains(leak)), reason: '$input/$leak');
        }
      }
    });

    test('a masked number hides its middle digits', () {
      final masked = SignInIdentifier.mask('09171234567');
      expect(masked, '0917 ••• 4567');
      expect(masked, isNot(contains('123')));
    });

    test('the code must be exactly the expected number of digits', () {
      expect(OneTimeCodeRules.validate('123456'), isNull);
      expect(OneTimeCodeRules.validate(''), isNotNull);
      expect(OneTimeCodeRules.validate('12345'), isNotNull);
      expect(OneTimeCodeRules.validate('1234567'), isNotNull);
      expect(OneTimeCodeRules.validate('12345a'), isNotNull);
    });
  });

  group('non-enumeration — acceptance 3', () {
    test('every refusal that could identify an account gives one message', () {
      // These are precisely the codes a server might use to distinguish "no
      // such number" from "wrong code". Collapsing them is the control.
      const indistinguishable = <AppFailure>[
        NotFoundFailure(),
        ForbiddenFailure(),
        ValidationFailure(),
        ConflictFailure(),
        UnauthenticatedFailure(),
      ];

      for (final failure in indistinguishable) {
        expect(
          SignInFeedback.forFailure(failure),
          SignInMessage.codeNotAccepted,
          reason: failure.kind,
        );
      }
    });

    test('no message distinguishes a known from an unknown number', () {
      for (final message in SignInMessage.values) {
        final copy = message.text.toLowerCase();
        for (final leak in <String>[
          'not registered',
          'no account',
          'unknown number',
          'does not exist',
          'already registered',
          'user not found',
          'invalid user',
        ]) {
          expect(copy, isNot(contains(leak)), reason: '${message.name}/$leak');
        }
      }
    });

    test('the code-sent message is conditional, never a confirmation', () {
      // "We sent you a code" confirms the number is registered. "If that number
      // is registered" does not.
      expect(SignInMessage.codeSent.text, startsWith('If '));
    });

    test('rate limiting is the one refusal kept separate', () {
      // Safe: it says "not now" regardless of whether the number exists.
      expect(
        SignInFeedback.forFailure(const RateLimitedFailure()),
        SignInMessage.tooManyAttempts,
      );
      expect(
        SignInFeedback.forFailure(
          const RateLimitedFailure(retryAfter: Duration(seconds: 30)),
        ),
        SignInMessage.tooManyAttempts,
      );
    });

    test('transport problems are reported as themselves', () {
      expect(
        SignInFeedback.forFailure(const NetworkFailure()),
        SignInMessage.offline,
      );
      expect(
        SignInFeedback.forFailure(const TimeoutFailure()),
        SignInMessage.timedOut,
      );
      expect(
        SignInFeedback.forFailure(const ServerFailure(isTemporary: true)),
        SignInMessage.serviceUnavailable,
      );
      expect(
        SignInFeedback.forFailure(const ContractFailure()),
        SignInMessage.unexpected,
      );
    });

    test('no resident-facing message carries the server debug text', () {
      const failure = ServerFailure(
        debugMessage: 'Identity endpoints are not available in this build.',
      );
      final message = SignInFeedback.forFailure(failure);
      expect(message.text, isNot(contains('Identity endpoints')));
    });
  });

  group('sign-in controller', () {
    test('a successful request advances to the code step', () async {
      final repository = FakeAuthRepository();
      final controller = SignInController(
        repository: repository,
        session: SessionController(store: InMemorySessionStore()),
      );
      addTearDown(controller.dispose);

      expect(controller.step, SignInStep.identifier);
      await controller.requestCode('09171234567');

      expect(controller.step, SignInStep.code);
      expect(controller.message, SignInMessage.codeSent);
      expect(controller.maskedMobileNumber, '0917 ••• 4567');
    });

    test('a failed request stays on the number step', () async {
      final repository = FakeAuthRepository(
        requestOutcome: const Err<void>(NetworkFailure()),
      );
      final controller = SignInController(
        repository: repository,
        session: SessionController(store: InMemorySessionStore()),
      );
      addTearDown(controller.dispose);

      await controller.requestCode('09171234567');
      expect(controller.step, SignInStep.identifier);
      expect(controller.message, SignInMessage.offline);
    });

    test('verifying establishes the session through the controller', () async {
      final store = InMemorySessionStore();
      final session = SessionController(store: store);
      final deadline = DateTime.now().toUtc().add(const Duration(hours: 2));
      final repository = FakeAuthRepository(
        verifyOutcome: Ok<AuthOutcome>(
          AuthOutcome(
            resident: const ResidentSession(
              accountId: 'acct-1',
              accessLevel: AccessLevel.verified,
            ),
            accessToken: 'server-token',
            expiresAt: deadline,
          ),
        ),
      );
      final controller = SignInController(
        repository: repository,
        session: session,
      );
      addTearDown(controller.dispose);

      await controller.requestCode('09171234567');
      final signedInOk = await controller.verifyCode('123456');

      expect(signedInOk, isTrue);
      expect(session.state, isA<AuthenticatedSession>());
      // The level came from the server's response, not from the app.
      expect(session.accessLevel, AccessLevel.verified);
      // And the server's own deadline was carried into storage.
      expect((await store.read())!.expiresAt, deadline);
    });

    test('a refused code keeps the resident on the code step', () async {
      final repository = FakeAuthRepository(
        verifyOutcome: const Err<AuthOutcome>(NotFoundFailure()),
      );
      final session = SessionController(store: InMemorySessionStore());
      final controller = SignInController(
        repository: repository,
        session: session,
      );
      addTearDown(controller.dispose);

      await controller.requestCode('09171234567');
      final signedInOk = await controller.verifyCode('123456');

      expect(signedInOk, isFalse);
      expect(controller.step, SignInStep.code);
      expect(controller.message, SignInMessage.codeNotAccepted);
      expect(session.state, isNot(isA<AuthenticatedSession>()));
    });

    test(
      'a successful sign-in leaves nothing about the attempt behind',
      () async {
        final repository = FakeAuthRepository();
        final controller = SignInController(
          repository: repository,
          session: SessionController(store: InMemorySessionStore()),
        );
        addTearDown(controller.dispose);

        await controller.requestCode('09171234567');
        await controller.verifyCode('123456');

        expect(controller.mobileNumber, isEmpty);
        expect(controller.step, SignInStep.identifier);
      },
    );

    test('resend is blocked until the cooldown elapses', () async {
      var now = DateTime.utc(2026, 8, 14, 9);
      final repository = FakeAuthRepository();
      final controller = SignInController(
        repository: repository,
        session: SessionController(store: InMemorySessionStore()),
        clock: () => now,
      );
      addTearDown(controller.dispose);

      await controller.requestCode('09171234567');
      expect(controller.canResend, isFalse);
      expect(
        controller.resendCooldownSeconds,
        OneTimeCodeRules.resendCooldown.inSeconds,
      );

      await controller.resendCode();
      expect(repository.requestCalls, 1, reason: 'the resend was blocked');

      now = now.add(OneTimeCodeRules.resendCooldown);
      expect(controller.canResend, isTrue);
      await controller.resendCode();
      expect(repository.requestCalls, 2);
      // Resending does not send the resident back a step.
      expect(controller.step, SignInStep.code);
    });

    test(
      'changing the number returns to step one and clears the cooldown',
      () async {
        final controller = SignInController(
          repository: FakeAuthRepository(),
          session: SessionController(store: InMemorySessionStore()),
        );
        addTearDown(controller.dispose);

        await controller.requestCode('09171234567');
        controller.changeNumber();

        expect(controller.step, SignInStep.identifier);
        expect(controller.resendCooldownSeconds, 0);
        expect(controller.message, isNull);
      },
    );

    test('toString carries neither the number nor a code', () async {
      final controller = SignInController(
        repository: FakeAuthRepository(),
        session: SessionController(store: InMemorySessionStore()),
      );
      addTearDown(controller.dispose);

      await controller.requestCode('09171234567');
      final rendered = controller.toString();

      expect(rendered, isNot(contains('09171234567')));
      expect(rendered, isNot(contains('4567')));
    });

    test('an outcome object does not render its token', () {
      const outcome = AuthOutcome(
        resident: ResidentSession(
          accountId: 'acct-1',
          accessLevel: AccessLevel.verified,
        ),
        accessToken: 'super-secret-token',
      );
      expect(outcome.toString(), isNot(contains('super-secret-token')));
      expect(outcome.toString(), isNot(contains('acct-1')));
    });
  });

  group('token lifetime — acceptance 1', () {
    test('an expired stored session is not resumed', () async {
      final store = InMemorySessionStore();
      await store.write(
        StoredSession(
          resident: const ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
          expiresAt: DateTime.utc(2026, 8, 14, 8),
        ),
      );

      final controller = SessionController(
        store: store,
        clock: () => DateTime.utc(2026, 8, 14, 9),
      );
      await controller.restore();

      expect(controller.state, isA<GuestSession>());
      expect(
        (controller.state as GuestSession).endedReason,
        SessionEndedReason.expired,
      );
      // Cleared, not merely ignored: a dead token must not stay on the device.
      expect(await store.read(), isNull);
    });

    test('a session with an unknown lifetime is resumed', () async {
      final store = InMemorySessionStore();
      await store.write(
        const StoredSession(
          resident: ResidentSession(
            accountId: 'acct-1',
            accessLevel: AccessLevel.verified,
          ),
          accessToken: 'token',
        ),
      );

      final controller = SessionController(store: store);
      await controller.restore();

      // No `expires_at` means "the server has not said", not "expired".
      expect(controller.state, isA<AuthenticatedSession>());
      expect(controller.accessLevel, AccessLevel.verified);
    });

    test('an expired token is withheld from the transport', () async {
      final store = InMemorySessionStore();
      final controller = await signedIn(
        store,
        clock: () => DateTime.utc(2026, 8, 14, 9),
        expiresAt: DateTime.utc(2026, 8, 14, 8),
      );

      expect(await controller.currentAccessToken(), isNull);
    });

    test('a live token is still provided', () async {
      final store = InMemorySessionStore();
      final controller = await signedIn(
        store,
        clock: () => DateTime.utc(2026, 8, 14, 9),
        expiresAt: DateTime.utc(2026, 8, 14, 10),
      );

      expect(await controller.currentAccessToken(), 'token');
    });

    test('resume ends a session whose deadline has passed', () async {
      var now = DateTime.utc(2026, 8, 14, 9);
      final store = InMemorySessionStore();
      final controller = await signedIn(
        store,
        clock: () => now,
        expiresAt: DateTime.utc(2026, 8, 14, 10),
      );

      expect(await controller.endSessionIfTokenExpired(), isFalse);
      expect(controller.state, isA<AuthenticatedSession>());

      now = DateTime.utc(2026, 8, 14, 11);
      expect(await controller.endSessionIfTokenExpired(), isTrue);
      expect(controller.state, isA<GuestSession>());
      expect(
        (controller.state as GuestSession).endedReason,
        SessionEndedReason.expired,
      );
    });

    test(
      'the expiry check can only take access away, never grant it',
      () async {
        final controller = SessionController(store: InMemorySessionStore());
        await controller.restore();
        expect(controller.state, const GuestSession());

        // A guest calling it must not acquire anything.
        expect(await controller.endSessionIfTokenExpired(), isFalse);
        expect(controller.accessLevel, AccessLevel.guest);
      },
    );

    test('signing out leaves nothing on the device', () async {
      final store = InMemorySessionStore();
      final controller = await signedIn(store);

      await controller.signOut();

      expect(await store.read(), isNull);
      expect(await controller.currentAccessToken(), isNull);
      expect(
        (controller.state as GuestSession).endedReason,
        SessionEndedReason.signedOut,
      );
    });

    test('guest access survives signing out — acceptance 2', () async {
      final controller = await signedIn(InMemorySessionStore());
      await controller.signOut();

      // Not "no session": a guest session, which every public route allows.
      expect(controller.state, isA<GuestSession>());
      expect(controller.accessLevel, AccessLevel.guest);
    });
  });

  group('app lock', () {
    late InMemorySecretStore secrets;
    late SessionController session;

    setUp(() async {
      secrets = InMemorySecretStore();
      session = await signedIn(InMemorySessionStore());
    });

    AppLockController lockWith(FakeLocalAuthenticator authenticator) {
      final lock = AppLockController(
        session: session,
        authenticator: authenticator,
        secrets: secrets,
      );
      addTearDown(lock.dispose);
      return lock;
    }

    test('is off until the resident turns it on', () async {
      final lock = lockWith(FakeLocalAuthenticator());
      await lock.load();

      expect(lock.isEnabled, isFalse);
      expect(lock.state, AppLockState.disabled);
      expect(lock.isLocked, isFalse);
    });

    test('cannot be enabled on a device that cannot satisfy it', () async {
      final lock = lockWith(
        FakeLocalAuthenticator(reported: LocalUnlockAvailability.unsupported),
      );
      await lock.load();

      expect(lock.canEnable, isFalse);
      expect(await lock.enable(), LocalUnlockOutcome.unavailable);
      expect(lock.isEnabled, isFalse);
    });

    test('enabling requires passing the prompt once', () async {
      final authenticator = FakeLocalAuthenticator(
        outcome: LocalUnlockOutcome.failed,
      );
      final lock = lockWith(authenticator);
      await lock.load();

      expect(await lock.enable(), LocalUnlockOutcome.failed);
      expect(lock.isEnabled, isFalse);
      expect(authenticator.prompts, 1);

      // A resident must not be able to switch on a lock they cannot pass.
      expect(await secrets.read(SecretKeys.appLockEnabled), isNull);
    });

    test(
      'backgrounding locks an enabled app, and unlocking reveals it',
      () async {
        final authenticator = FakeLocalAuthenticator();
        final lock = lockWith(authenticator);
        await lock.load();
        await lock.enable();

        expect(lock.state, AppLockState.unlocked);

        lock.markBackgrounded();
        expect(lock.state, AppLockState.locked);
        expect(lock.isLocked, isTrue);

        expect(await lock.unlock(), LocalUnlockOutcome.unlocked);
        expect(lock.state, AppLockState.unlocked);
      },
    );

    test('a refused unlock leaves the app locked', () async {
      final authenticator = FakeLocalAuthenticator();
      final lock = lockWith(authenticator);
      await lock.load();
      await lock.enable();
      lock.markBackgrounded();

      authenticator.outcome = LocalUnlockOutcome.failed;
      expect(await lock.unlock(), LocalUnlockOutcome.failed);
      expect(lock.isLocked, isTrue);
      expect(lock.lastOutcome, LocalUnlockOutcome.failed);
    });

    test('a guest is never locked out — acceptance 2', () async {
      final lock = lockWith(FakeLocalAuthenticator());
      await lock.load();
      await lock.enable();
      lock.markBackgrounded();
      expect(lock.isLocked, isTrue);

      await session.signOut();

      // The lock protected a session that no longer exists. Leaving it up would
      // hide public services behind a prompt for no one's benefit.
      expect(lock.isLocked, isFalse);
      expect(lock.state, AppLockState.disabled);
    });

    test('signing in is never met with an unlock prompt', () async {
      // Regression: a guest backgrounding the app used to arm the lock, which
      // then sprang the instant they signed in — a resident would enter a code
      // and be shown a prompt for their trouble.
      final lock = lockWith(FakeLocalAuthenticator());
      await lock.load();
      await lock.enable();

      await session.signOut();
      lock.markBackgrounded();

      await session.signIn(
        resident: const ResidentSession(
          accountId: 'acct-2',
          accessLevel: AccessLevel.unverified,
        ),
        accessToken: 'token',
      );

      expect(lock.isLocked, isFalse);
      expect(lock.state, AppLockState.unlocked);
    });

    test('a refused prompt leaves no listener thinking it is open', () async {
      // Regression: `enable()` returned early on refusal without notifying, so
      // the settings switch stayed disabled until something else rebuilt.
      final lock = lockWith(
        FakeLocalAuthenticator(outcome: LocalUnlockOutcome.cancelled),
      );
      await lock.load();

      var notifications = 0;
      lock.addListener(() => notifications++);

      expect(await lock.enable(), LocalUnlockOutcome.cancelled);
      expect(lock.isPrompting, isFalse);
      // Once for the prompt opening, once for it closing.
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test(
      'disabling needs no unlock, so a broken sensor cannot trap anyone',
      () async {
        final authenticator = FakeLocalAuthenticator();
        final lock = lockWith(authenticator);
        await lock.load();
        await lock.enable();
        final promptsAfterEnable = authenticator.prompts;

        await lock.disable();

        expect(lock.isEnabled, isFalse);
        expect(authenticator.prompts, promptsAfterEnable);
        expect(await secrets.read(SecretKeys.appLockEnabled), isNull);
      },
    );

    test('a lock the device can no longer satisfy reads as off', () async {
      final authenticator = FakeLocalAuthenticator();
      final lock = lockWith(authenticator);
      await lock.load();
      await lock.enable();
      expect(await secrets.read(SecretKeys.appLockEnabled), isNotNull);

      // The resident removed their fingerprint and screen lock.
      authenticator.reported = LocalUnlockAvailability.unsupported;
      final reloaded = lockWith(authenticator);
      await reloaded.load();

      // Off, not permanently locked — the alternative bricks the app.
      expect(reloaded.isEnabled, isFalse);
      expect(reloaded.isLocked, isFalse);
    });

    test('the preference survives signing out and back in', () async {
      final lock = lockWith(FakeLocalAuthenticator());
      await lock.load();
      await lock.enable();

      await session.signOut();
      // A device preference, not a session one: clearing it on sign-out would
      // silently switch a resident's lock off.
      expect(await secrets.read(SecretKeys.appLockEnabled), isNotNull);
    });

    test('the lock never changes the access level', () async {
      final lock = lockWith(FakeLocalAuthenticator());
      await lock.load();
      await lock.enable();
      lock.markBackgrounded();

      // Locked and unlocked are the same authority. The server would accept the
      // same token either way; this only hides pixels.
      expect(session.accessLevel, AccessLevel.unverified);
      await lock.unlock();
      expect(session.accessLevel, AccessLevel.unverified);
    });
  });

  group('honest seams for absent endpoints', () {
    test('device sessions decline rather than fabricate a list', () async {
      const repository = PlannedDeviceSessionRepository();

      final list = await repository.listActiveSessions();
      expect(list.isErr, isTrue);
      // A fabricated list would reassure a resident checking for an intruder.
      expect(list.valueOrNull, isNull);

      final revoked = await repository.revokeSession(sessionId: 'anything');
      expect(revoked.isErr, isTrue);
    });

    test('the declining reason is operator-facing only', () async {
      final result = await const PlannedDeviceSessionRepository()
          .listActiveSessions();
      final failure = result.failureOrNull!;

      expect(failure.debugMessage, isNotNull);
      // The resident sees the taxonomy's own copy, never the debug text.
      expect(failure.residentMessage, isNot(contains('endpoint')));
    });

    // Sign-out's local-first guarantee moved with the repository: it is proven
    // against the wired implementation in `auth_api_test.dart`, where a server
    // that refuses, times out or never answers still produces `Ok`.

    test('no refresh is attempted, because none is published', () async {
      // TAB 05 built the coordinator and left the refresher unregistered. TAB 09
      // deliberately did not add one: the committed contract has no refresh
      // endpoint, and inventing a path would be a contract the server never
      // agreed to. Recorded here so removing the seam is a deliberate act.
      final store = InMemorySessionStore();
      final controller = await signedIn(store);

      await controller.handleUnauthenticated();

      expect(controller.state, isA<GuestSession>());
      expect(await store.read(), isNull);
    });
  });
}
