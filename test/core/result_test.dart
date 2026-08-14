import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';

void main() {
  group('Result', () {
    test('map transforms a success and leaves a failure alone', () {
      expect(const Ok<int>(2).map((v) => v * 3), const Ok<int>(6));

      const failure = NetworkFailure();
      expect(
        const Err<int>(failure).map((v) => v * 3),
        const Err<int>(failure),
      );
    });

    test('flatMap chains only on success', () {
      final chained = const Ok<int>(2).flatMap((v) => Ok<String>('$v'));
      expect(chained, const Ok<String>('2'));

      final short = const Err<int>(
        TimeoutFailure(),
      ).flatMap((v) => Ok<String>('$v'));
      expect(short.isErr, isTrue);
    });

    test('fold collapses both branches', () {
      expect(
        const Ok<int>(1).fold(onOk: (v) => 'ok', onErr: (f) => 'err'),
        'ok',
      );
      expect(
        const Err<int>(
          NetworkFailure(),
        ).fold(onOk: (v) => 'ok', onErr: (f) => 'err'),
        'err',
      );
    });

    test('guard converts a throw into UnexpectedFailure', () {
      final result = Result<int>.guard(
        () => throw StateError('boom'),
        context: 'test',
      );
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect((result.failureOrNull! as UnexpectedFailure).debugContext, 'test');
    });
  });

  group('ApiErrorCode', () {
    test('parses every canonical wire value from the backend contract', () {
      const canonical = <String, ApiErrorCode>{
        'BAD_REQUEST': ApiErrorCode.badRequest,
        'UNAUTHENTICATED': ApiErrorCode.unauthenticated,
        'FORBIDDEN': ApiErrorCode.forbidden,
        'NOT_FOUND': ApiErrorCode.notFound,
        'METHOD_NOT_ALLOWED': ApiErrorCode.methodNotAllowed,
        'CONFLICT': ApiErrorCode.conflict,
        'INVALID_STATE_TRANSITION': ApiErrorCode.invalidStateTransition,
        'VALIDATION_FAILED': ApiErrorCode.validationFailed,
        'RATE_LIMITED': ApiErrorCode.rateLimited,
        'SERVER_ERROR': ApiErrorCode.serverError,
        'SERVICE_UNAVAILABLE': ApiErrorCode.serviceUnavailable,
      };
      canonical.forEach((wire, expected) {
        expect(ApiErrorCode.parse(wire), expected, reason: wire);
      });
    });

    test(
      'an unrecognised or absent code degrades to unknown, never throws',
      () {
        // The server may add codes without a version bump (conventions §1).
        expect(ApiErrorCode.parse('SOMETHING_NEW'), ApiErrorCode.unknown);
        expect(ApiErrorCode.parse(null), ApiErrorCode.unknown);
      },
    );
  });

  group('failureFromApiError', () {
    test('maps codes onto the failure taxonomy', () {
      AppFailure map(ApiErrorCode code, {int status = 400}) =>
          failureFromApiError(statusCode: status, code: code);

      expect(map(ApiErrorCode.unauthenticated), isA<UnauthenticatedFailure>());
      expect(map(ApiErrorCode.forbidden), isA<ForbiddenFailure>());
      expect(map(ApiErrorCode.notFound), isA<NotFoundFailure>());
      expect(map(ApiErrorCode.validationFailed), isA<ValidationFailure>());
      expect(map(ApiErrorCode.conflict), isA<ConflictFailure>());
      expect(map(ApiErrorCode.rateLimited), isA<RateLimitedFailure>());
      expect(map(ApiErrorCode.serverError), isA<ServerFailure>());
      expect(map(ApiErrorCode.serviceUnavailable), isA<ServerFailure>());
    });

    test('INVALID_STATE_TRANSITION is a conflict that says so', () {
      final failure =
          failureFromApiError(
                statusCode: 409,
                code: ApiErrorCode.invalidStateTransition,
              )
              as ConflictFailure;
      expect(failure.isInvalidStateTransition, isTrue);
      expect(failure.kind, 'invalid_state_transition');
    });

    test('SERVICE_UNAVAILABLE is temporary and retryable', () {
      final failure =
          failureFromApiError(
                statusCode: 503,
                code: ApiErrorCode.serviceUnavailable,
              )
              as ServerFailure;
      expect(failure.isTemporary, isTrue);
      expect(failure.isRetryable, isTrue);
    });

    test('an unknown code falls back to the HTTP status', () {
      expect(
        failureFromApiError(statusCode: 401, code: ApiErrorCode.unknown),
        isA<UnauthenticatedFailure>(),
      );
      expect(
        failureFromApiError(statusCode: 502, code: ApiErrorCode.unknown),
        isA<ServerFailure>(),
      );
      expect(
        failureFromApiError(statusCode: 418, code: ApiErrorCode.unknown),
        isA<UnexpectedFailure>(),
      );
    });

    test('only 401 asks for re-authentication', () {
      expect(
        failureFromApiError(
          statusCode: 401,
          code: ApiErrorCode.unauthenticated,
        ).requiresReauthentication,
        isTrue,
      );
      expect(
        failureFromApiError(
          statusCode: 403,
          code: ApiErrorCode.forbidden,
        ).requiresReauthentication,
        isFalse,
      );
    });
  });

  group('resident-facing copy', () {
    // The server's `message` is operator-facing by contract and must never be
    // rendered. These assertions are the guard against it leaking into the UI.
    test('never repeats the server message', () {
      const serverMessage = 'SQLSTATE[23000]: Integrity constraint violation';
      final failures = <AppFailure>[
        const NetworkFailure(debugMessage: serverMessage),
        const TimeoutFailure(debugMessage: serverMessage),
        const UnauthenticatedFailure(debugMessage: serverMessage),
        const ForbiddenFailure(debugMessage: serverMessage),
        const NotFoundFailure(debugMessage: serverMessage),
        const ValidationFailure(debugMessage: serverMessage),
        const ConflictFailure(debugMessage: serverMessage),
        const RateLimitedFailure(debugMessage: serverMessage),
        const ServerFailure(debugMessage: serverMessage),
        const ContractFailure(debugMessage: serverMessage),
        const UnexpectedFailure(debugMessage: serverMessage),
      ];

      for (final failure in failures) {
        expect(
          failure.residentMessage,
          isNot(contains(serverMessage)),
          reason: failure.kind,
        );
        expect(failure.residentMessage, isNotEmpty, reason: failure.kind);
      }
    });

    test('rate limiting tells the resident how long to wait when known', () {
      expect(
        const RateLimitedFailure(
          retryAfter: Duration(seconds: 30),
        ).residentMessage,
        contains('30 seconds'),
      );
      expect(
        const RateLimitedFailure().residentMessage,
        contains('wait a moment'),
      );
    });

    test('validation exposes per-field messages for the field that failed', () {
      const failure = ValidationFailure(
        fieldErrors: <String, List<String>>{
          'mobile_number': <String>['The mobile number field is required.'],
        },
      );
      expect(
        failure.firstErrorFor('mobile_number'),
        'The mobile number field is required.',
      );
      expect(failure.firstErrorFor('email'), isNull);
    });
  });
}
