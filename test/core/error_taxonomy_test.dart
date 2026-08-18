import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/api_error_code.dart';
import 'package:taytay_resident/core/result/app_failure.dart';
import 'package:taytay_resident/core/result/failure_context.dart';

/// TAB 14's sweep, held as assertions.
///
/// Thirteen repositories were wired across TABs 02–13 and each surfaced error
/// paths nothing had exercised. This is the check that they speak with one voice
/// rather than thirteen dialects of "something went wrong".
void main() {
  /// Every failure the taxonomy can produce, built once.
  final List<AppFailure> everyFailure = <AppFailure>[
    const NetworkFailure(),
    const TimeoutFailure(),
    const UnauthenticatedFailure(),
    const ForbiddenFailure(),
    const NotFoundFailure(),
    const ValidationFailure(),
    const ConflictFailure(),
    const ConflictFailure(isInvalidStateTransition: true),
    const RateLimitedFailure(),
    const ServerFailure(),
    const ServerFailure(isTemporary: true),
    const ServerFailure(isTemporary: true, isMaintenance: true),
    const ContractFailure(),
    const UnacceptableUploadFailure(isTooLarge: true),
    const UnacceptableUploadFailure(isTooLarge: false),
    const UnexpectedFailure(),
  ];

  group('every failure says something a resident can act on', () {
    test('none is empty, and none names a developer concept', () {
      // The taxonomy's own copy is the last line of defence: it is what appears
      // when no screen supplied a context.
      for (final AppFailure failure in everyFailure) {
        expect(
          failure.residentMessage.trim(),
          isNotEmpty,
          reason: failure.kind,
        );
        for (final String jargon in <String>[
          'null',
          'exception',
          'endpoint',
          'repository',
          'HTTP',
          '4xx',
          'module',
          'API',
        ]) {
          expect(
            failure.residentMessage.toLowerCase(),
            isNot(contains(jargon.toLowerCase())),
            reason: '${failure.kind} says "$jargon"',
          );
        }
      }
    });

    test('nothing blames the resident for a fault that is not theirs', () {
      for (final AppFailure failure in <AppFailure>[
        const NetworkFailure(),
        const ServerFailure(),
        const ContractFailure(),
        const UnexpectedFailure(),
      ]) {
        expect(
          failure.residentMessage.toLowerCase(),
          isNot(anyOf(contains('you entered'), contains('invalid'))),
          reason: failure.kind,
        );
      }
    });

    test('offline, unreachable and server fault are three sentences', () {
      // Three different situations with three different next steps, and a
      // resident who is told the wrong one goes to a barangay hall over their
      // own wifi.
      final Set<String> messages = <String>{
        const NetworkFailure().residentMessage,
        const ServerFailure(isTemporary: true).residentMessage,
        const ServerFailure().residentMessage,
      };
      expect(messages, hasLength(3));
    });
  });

  group('the affordance matches what could actually happen next', () {
    test('a throttle is never offered as "try again now"', () {
      // The server has said when to come back. A button beside it spends a
      // resident's data teaching them nothing.
      expect(
        const RateLimitedFailure().affordance,
        FailureAffordance.retryAfter,
      );
    });

    test('a refused file offers no retry, because the same file will fail', () {
      for (final bool tooLarge in <bool>[true, false]) {
        expect(
          UnacceptableUploadFailure(isTooLarge: tooLarge).affordance,
          FailureAffordance.terminal,
        );
      }
    });

    test('connectivity failures do offer one', () {
      for (final AppFailure failure in <AppFailure>[
        const NetworkFailure(),
        const TimeoutFailure(),
      ]) {
        expect(
          failure.affordance,
          FailureAffordance.retryNow,
          reason: failure.kind,
        );
      }
    });

    test('a permission refusal offers nothing to press', () {
      expect(const ForbiddenFailure().affordance, FailureAffordance.terminal);
    });
  });

  group('context sharpens the codes that mean several things', () {
    test('one conflict, three different sentences', () {
      const ConflictFailure conflict = ConflictFailure();
      final Set<String> readings = <String>{
        contextualResidentMessage(conflict, FailureContext.eventRegistration),
        contextualResidentMessage(
          conflict,
          FailureContext.assistanceSubmission,
        ),
        contextualResidentMessage(conflict, FailureContext.correction),
      };
      expect(readings, hasLength(3));

      // And each says what actually happened rather than that something
      // conflicted.
      expect(
        contextualResidentMessage(conflict, FailureContext.eventRegistration),
        contains('filled up'),
      );
      expect(
        contextualResidentMessage(
          conflict,
          FailureContext.assistanceSubmission,
        ),
        contains('already been sent'),
      );
    });

    test('an upload refusal does not blame the resident', () {
      // A 403 on an upload usually means the case moved on. Telling somebody
      // they are not allowed is the worse guess and the one they cannot act on.
      final String message = contextualResidentMessage(
        const ForbiddenFailure(),
        FailureContext.documentUpload,
      );
      expect(message, isNot(contains('not allowed')));
      expect(message, contains('not accepting'));
    });

    test('an unmapped pairing falls back rather than inventing', () {
      // Most failures mean the same thing everywhere. Inventing a variant per
      // screen gives thirteen features thirteen dialects of one sentence.
      const NetworkFailure offline = NetworkFailure();
      for (final FailureContext context in FailureContext.values) {
        expect(
          contextualResidentMessage(offline, context),
          offline.residentMessage,
          reason: context.name,
        );
      }
    });
  });

  group('operator-facing text never reaches a resident', () {
    test('a server message is never used as resident copy', () {
      // Article 5.5. The server's `message` is written once, in one language,
      // for an operator — and would arrive untranslated in front of a Filipino
      // reader even if it were safe to show.
      const String operatorText = 'SQLSTATE[23000]: constraint violation';
      for (final ApiErrorCode code in ApiErrorCode.values) {
        final AppFailure failure = failureFromApiError(
          statusCode: 500,
          code: code,
          message: operatorText,
        );
        expect(
          failure.residentMessage,
          isNot(contains('SQLSTATE')),
          reason: code.wireValue,
        );
        // It is kept, because a support desk needs it.
        expect(failure.debugMessage, operatorText, reason: code.wireValue);
      }
    });

    test('no resident-facing widget reads debugMessage unguarded', () {
      // The planned stubs carried developer-facing text deliberately, and it
      // must not have survived the wiring.
      //
      // Scoped to what a resident can actually see. Everywhere else in `lib`
      // *constructs* a debugMessage — that is the field's purpose, and a check
      // that flagged the taxonomy for naming its own property would be noise
      // somebody switches off. The rule is that nothing which renders reads it,
      // and the one permitted reader guards on the environment.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity entity in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final String path = entity.path.replaceAll(r'\', '/');
        final bool isResidentVisible =
            path.contains('/presentation/') ||
            path.contains('/shared/widgets/');
        if (!isResidentVisible) continue;

        final String source = entity.readAsStringSync();
        if (!source.contains('debugMessage')) continue;
        // `FailureView` shows it behind an environment gate, and a release build
        // sets that false — so a resident never meets it and a tester on a dev
        // build still can.
        if (source.contains('allowsDiagnosticsUi')) continue;
        offenders.add(path);
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('a reference is always available when it matters', () {
    test('a terminal failure keeps the request id the server issued', () {
      for (final AppFailure failure in everyFailure) {
        if (failure.affordance != FailureAffordance.terminal) continue;
        final AppFailure withId = failureFromApiError(
          statusCode: 500,
          code: ApiErrorCode.serverError,
          requestId: 'req-abc',
        );
        expect(withId.requestId, 'req-abc', reason: failure.kind);
      }
    });
  });
}
