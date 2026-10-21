import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/auth/domain/code_exchange.dart';
import 'package:taytay_resident/features/mock_data/data/mock/code_challenge_book.dart';

void main() {
  late DateTime now;
  late CodeChallengeBook book;

  setUp(() {
    now = DateTime.utc(2026, 10, 21, 1);
    book = CodeChallengeBook(now: () => now);
  });

  test('a reset request is accepted and does not name the account', () async {
    final Result<CodeAcceptance> result = book.requestReset(
      'juana.delacruz@example.com',
    );
    expect((result as Ok<CodeAcceptance>).value.accepted, isTrue);
    expect(result.toString(), isNot(contains('juana')));
  });

  test(
    'a resend inside 60 seconds is rate limited with the remaining wait',
    () {
      final Result<CodeAcceptance> first = book.requestReset(
        'juana.delacruz@example.com',
      );
      expect((first as Ok<CodeAcceptance>).value.retryAfterSeconds, 60);
      now = now.add(const Duration(seconds: 30));
      final Result<CodeAcceptance> again = book.requestReset(
        'juana.delacruz@example.com',
      );
      final RateLimitedFailure limited =
          again.failureOrNull! as RateLimitedFailure;
      expect(limited.retryAfter, const Duration(seconds: 30));
      final Result<PasswordResetGrant> grant = book.verifyReset(
        email: 'juana.delacruz@example.com',
        code: CodeExchangeRules.sampleCode,
      );
      final PasswordResetGrant value = (grant as Ok<PasswordResetGrant>).value;
      expect(value.resetToken, 'example-reset-token-not-a-secret');
      expect(value.expiresAt.difference(now), CodeExchangeRules.resetTokenLife);
      expect(value.toString(), 'PasswordResetGrant(redacted)');
      expect(value.toString(), isNot(contains('example-reset-token')));
    },
  );

  test('five wrong codes lock, and 000000 does not spend an attempt', () {
    book.sendEmailCode();
    final Result<EmailVerified> expired = book.verifyEmailCode(
      CodeExchangeRules.expiredSentinel,
    );
    final CodeExchangeFailure expiredFailure =
        expired.failureOrNull! as CodeExchangeFailure;
    expect(expiredFailure.exchangeKind, CodeExchangeKind.expired);
    expect(expiredFailure.attemptsRemaining, 5);
    for (var i = 0; i < 4; i++) {
      final Result<EmailVerified> wrong = book.verifyEmailCode('111111');
      final CodeExchangeFailure failure =
          wrong.failureOrNull! as CodeExchangeFailure;
      expect(failure.exchangeKind, CodeExchangeKind.invalid);
      expect(failure.attemptsRemaining, 4 - i);
    }
    final Result<EmailVerified> locked = book.verifyEmailCode('111111');
    final CodeExchangeFailure failure =
        locked.failureOrNull! as CodeExchangeFailure;
    expect(failure.exchangeKind, CodeExchangeKind.locked);
    expect(failure.attemptsRemaining, 0);
    final Result<EmailVerified> sample = book.verifyEmailCode(
      CodeExchangeRules.sampleCode,
    );
    expect(sample.isOk, isFalse);
  });

  test('a weak password does not spend the reset token', () {
    book.requestReset('juana.delacruz@example.com');
    final PasswordResetGrant grant =
        (book.verifyReset(
                  email: 'juana.delacruz@example.com',
                  code: CodeExchangeRules.sampleCode,
                )
                as Ok<PasswordResetGrant>)
            .value;
    final Result<PasswordUpdated> weak = book.complete(
      resetToken: grant.resetToken,
      newPassword: 'password',
    );
    expect(
      (weak.failureOrNull! as ValidationFailure).fieldErrors['new_password'],
      <String>[CodeExchangeRules.weak],
    );
    final Result<PasswordUpdated> updated = book.complete(
      resetToken: grant.resetToken,
      newPassword: 'Password1',
    );
    expect((updated as Ok<PasswordUpdated>).value.updated, isTrue);
    final Result<PasswordUpdated> spent = book.complete(
      resetToken: grant.resetToken,
      newPassword: 'Password1',
    );
    expect(spent.isOk, isFalse);
  });

  test('a code older than 10 minutes is expired', () {
    book.sendEmailCode();
    now = now.add(const Duration(minutes: 10));
    final Result<EmailVerified> result = book.verifyEmailCode(
      CodeExchangeRules.sampleCode,
    );
    final CodeExchangeFailure failure =
        result.failureOrNull! as CodeExchangeFailure;
    expect(failure.exchangeKind, CodeExchangeKind.expired);
    expect(failure.attemptsRemaining, 5);
  });

  test('a 503 leaves the counters and a 202 clears the live count', () {
    const CodeAttemptView start = CodeAttemptView(
      attemptsRemaining: 3,
      wrong: true,
    );
    final DateTime at = DateTime.utc(2026, 10, 21, 2);
    final CodeAttemptView down = start.applyFailure(
      const ServerFailure(isTemporary: true),
      at,
    );
    expect(down.unavailable, isTrue);
    expect(down.attemptsRemaining, 3);
    expect(down.resendAt, isNull);
    expect(down.wrong, isFalse);

    final CodeAttemptView fresh = down.applyAcceptance(
      const CodeAcceptance(accepted: true, retryAfterSeconds: 60),
      at,
    );
    expect(fresh.attemptsRemaining, isNull);
    expect(fresh.unavailable, isFalse);
    expect(fresh.resendAt, at.add(const Duration(seconds: 60)));

    final CodeAttemptView kept = start.applyFailure(
      const ValidationFailure(),
      at,
    );
    expect(kept.attemptsRemaining, 3);
    expect(kept.wrong, isTrue);
  });

  test('countdown formatting matches the designs', () {
    expect(
      CodeExchangeRules.countdown(const Duration(minutes: 8, seconds: 42)),
      '8:42',
    );
    expect(CodeExchangeRules.countdown(const Duration(seconds: 42)), '0:42');
  });

  test('the hold clock is mm:ss over a 900 second bar', () {
    expect(
      CodeExchangeRules.holdClock(const Duration(minutes: 14, seconds: 32)),
      '14:32',
    );
    expect(CodeExchangeRules.holdClock(Duration.zero), '00:00');
    expect(CodeExchangeRules.holdClock(const Duration(minutes: 20)), '15:00');
    expect(
      CodeExchangeRules.holdProgress(const Duration(minutes: 14, seconds: 32)),
      closeTo((900 - 872) / 900, 0.0001),
    );
    expect(CodeExchangeRules.holdProgress(Duration.zero), 1);
    final DateTime now = DateTime.utc(2026, 8, 29, 12);
    final CodeHold ready = CodeHold.fromWait(
      origin: CodeHoldOrigin.passwordReset,
      email: 'juana.delacruz@example.com',
      now: now,
      wait: Duration.zero,
    );
    expect(ready.readyAt(now), isTrue);
    final CodeHold waiting = CodeHold.fromWait(
      origin: CodeHoldOrigin.emailVerification,
      email: 'juana.delacruz@example.com',
      now: now,
      wait: const Duration(seconds: 872),
    );
    expect(waiting.readyAt(now), isFalse);
    expect(waiting.resumeAt, now.add(const Duration(seconds: 872)));
  });
}
