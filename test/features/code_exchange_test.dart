import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/auth/data/code_challenge_book.dart';
import 'package:taytay_resident/features/auth/domain/code_exchange.dart';

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

  test('a resend inside 60 seconds keeps the same code', () {
    book.requestReset('juana.delacruz@example.com');
    now = now.add(const Duration(seconds: 30));
    final Result<CodeAcceptance> again = book.requestReset(
      'juana.delacruz@example.com',
    );
    expect((again as Ok<CodeAcceptance>).value.accepted, isTrue);
    final Result<PasswordResetGrant> grant = book.verifyReset(
      email: 'juana.delacruz@example.com',
      code: CodeExchangeRules.sampleCode,
    );
    final PasswordResetGrant value = (grant as Ok<PasswordResetGrant>).value;
    expect(value.resetToken, 'example-reset-token-not-a-secret');
    expect(value.expiresAt.difference(now), CodeExchangeRules.resetTokenLife);
    expect(value.toString(), 'PasswordResetGrant(redacted)');
    expect(value.toString(), isNot(contains('example-reset-token')));
  });

  test('five wrong codes lock, and 000000 does not spend an attempt', () {
    book.sendEmailCode();
    final Result<EmailVerified> expired = book.verifyEmailCode(
      CodeExchangeRules.expiredSentinel,
    );
    expect(expired.failureOrNull, isA<ValidationFailure>());
    for (var i = 0; i < 4; i++) {
      final Result<EmailVerified> wrong = book.verifyEmailCode('111111');
      final ValidationFailure failure =
          wrong.failureOrNull! as ValidationFailure;
      expect(failure.fieldErrors['code'], <String>[CodeExchangeRules.wrong]);
    }
    final Result<EmailVerified> locked = book.verifyEmailCode('111111');
    final ValidationFailure failure =
        locked.failureOrNull! as ValidationFailure;
    expect(failure.fieldErrors['code'], <String>[CodeExchangeRules.locked]);
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
    expect(
      (result.failureOrNull! as ValidationFailure).fieldErrors['code'],
      <String>[CodeExchangeRules.expired],
    );
  });

  test('countdown formatting matches the designs', () {
    expect(
      CodeExchangeRules.countdown(const Duration(minutes: 8, seconds: 42)),
      '8:42',
    );
    expect(CodeExchangeRules.countdown(const Duration(seconds: 42)), '0:42');
  });
}
