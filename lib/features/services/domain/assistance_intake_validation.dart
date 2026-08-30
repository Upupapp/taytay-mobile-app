import '../../../core/forms/field_error.dart';
import '../../../core/forms/validation_message.dart';
import 'assistance_intake.dart';

/// Validation for the assistance intake wizard.
///
/// ---
///
/// **Client-side validation is a courtesy, never a gate.** It saves a resident a
/// round trip on an obvious mistake — an empty required box, a date typed as
/// text. The server validates again and its answer is the one that counts.
///
/// Two rules follow from that, and they are the reason this file is short:
///
/// 1. **Nothing here is stricter than what the server declared.** A length is
///    only enforced when the form carried one; a question is only required when
///    the form said so. The app never adds a rule of its own, because a rule the
///    client invented rejects an application the office would have accepted, and
///    there is no appeal path inside an app.
/// 2. **Nothing here decides eligibility.** Whether a resident qualifies is a
///    server decision (backend ADR 0002). This file checks that a form is filled
///    in, and has no opinion at all about whether it should succeed.
abstract final class AssistanceIntakeValidation {
  static List<FieldError> validateContext(AssistanceIntakeDraft draft) {
    if (draft.contextConfirmed) return const <FieldError>[];
    return const <FieldError>[
      FieldError(
        field: 'context_confirmed',
        kind: ValidationMessage.confirmDetails,
        message:
            'Confirm these are your details before you continue, so the office '
            'files this against the right record.',
      ),
    ];
  }

  static List<FieldError> validateNarrative(
    AssistanceIntakeDraft draft,
    AssistanceIntakeForm form,
  ) {
    final errors = <FieldError>[];
    final narrative = draft.narrative.trim();

    if (narrative.isEmpty) {
      errors.add(
        const FieldError(
          field: 'narrative',
          kind: ValidationMessage.narrativeMissing,
          message: 'Describe what you need help with, in your own words.',
        ),
      );
      return errors;
    }

    final maximum = form.narrativeMaxLength;
    if (maximum != null && narrative.length > maximum) {
      errors.add(
        FieldError(
          field: 'narrative',
          kind: ValidationMessage.narrativeTooLong,
          limit: maximum,
          message:
              'Shorten this to $maximum characters or fewer. The office can ask '
              'you for more detail later.',
        ),
      );
    }
    return errors;
  }

  /// Checks the server's own questions against the answers given.
  static List<FieldError> validateQuestions(
    AssistanceIntakeDraft draft,
    AssistanceIntakeForm form,
  ) {
    final errors = <FieldError>[];

    for (final question in form.questions) {
      // A question this build cannot render is not a question the resident
      // failed to answer. It blocks the whole submission elsewhere, with an
      // explanation; reporting it as a field error would tell someone to fix
      // something they were never shown.
      if (!question.isRenderable) continue;

      final answer = draft.answerFor(question.key);
      if (_isBlank(answer)) {
        if (question.isRequired) {
          errors.add(
            FieldError(
              field: question.key,
              kind: _missingKind(question),
              subject: question.prompt,
              message: _missingMessage(question),
            ),
          );
        }
        continue;
      }

      final typeError = _typeError(question, answer);
      if (typeError != null) {
        errors.add(typeError);
        continue;
      }

      final lengthError = _lengthError(question, answer);
      if (lengthError != null) errors.add(lengthError);
    }
    return errors;
  }

  static List<FieldError> validateConsent(
    AssistanceIntakeDraft draft,
    AssistanceIntakeForm form,
  ) => <FieldError>[
    for (final consent in form.requiredConsents)
      if (!draft.hasConsent(consent.key))
        FieldError(
          field: 'consent_${consent.key}',
          kind: ValidationMessage.consentRequired,
          subject: consent.label,
          message: 'You need to accept "${consent.label}" to continue.',
        ),
  ];

  /// Validates whichever step is current.
  ///
  /// The document step is deliberately not validated: uploading is TAB 16's
  /// flow, and the office accepts documents brought to the counter, so a
  /// resident must never be blocked here for not having a file on their phone.
  static List<FieldError> validateStep(
    IntakeStep step,
    AssistanceIntakeDraft draft,
    AssistanceIntakeForm form,
  ) => switch (step) {
    IntakeStep.context => validateContext(draft),
    IntakeStep.describe => validateNarrative(draft, form),
    IntakeStep.questions => validateQuestions(draft, form),
    IntakeStep.consent => validateConsent(draft, form),
    IntakeStep.documents ||
    IntakeStep.review ||
    IntakeStep.submitting ||
    IntakeStep.outcome => const <FieldError>[],
  };

  /// Everything wrong across every input step.
  ///
  /// Run before submission so the review screen cannot send a form that a step
  /// would have rejected — a resident can reach review by editing backwards and
  /// clearing a field on the way.
  static List<FieldError> validateAll(
    AssistanceIntakeDraft draft,
    AssistanceIntakeForm form,
  ) => <FieldError>[
    ...validateContext(draft),
    ...validateNarrative(draft, form),
    ...validateQuestions(draft, form),
    ...validateConsent(draft, form),
  ];

  static bool _isBlank(Object? answer) => switch (answer) {
    null => true,
    final String value => value.trim().isEmpty,
    final List<Object?> value => value.isEmpty,
    // A `false` on a yes/no question is an answer, not a blank. Treating it as
    // missing would make "no" impossible to give.
    _ => false,
  };

  /// The kind that matches [_missingMessage], so the two cannot drift.
  static ValidationMessage _missingKind(IntakeQuestion question) =>
      switch (question.kind.known) {
        IntakeAnswerKind.singleChoice || IntakeAnswerKind.multipleChoice =>
          ValidationMessage.answerMissingChoice,
        IntakeAnswerKind.yesNo => ValidationMessage.answerMissingYesNo,
        IntakeAnswerKind.date => ValidationMessage.answerMissingDate,
        IntakeAnswerKind.number => ValidationMessage.answerMissingNumber,
        _ => ValidationMessage.answerMissingGeneric,
      };

  static String _missingMessage(IntakeQuestion question) =>
      switch (question.kind.known) {
        IntakeAnswerKind.singleChoice || IntakeAnswerKind.multipleChoice =>
          'Choose an answer for "${question.prompt}".',
        IntakeAnswerKind.yesNo => 'Answer yes or no to "${question.prompt}".',
        IntakeAnswerKind.date => 'Enter a date for "${question.prompt}".',
        IntakeAnswerKind.number => 'Enter a number for "${question.prompt}".',
        _ => 'Answer "${question.prompt}".',
      };

  /// Catches an answer whose type does not match the kind the server declared.
  ///
  /// Only reachable for a number question: the numeric field keeps the raw text
  /// when it will not parse, so that the resident is told "that is not a
  /// number" rather than the app quietly sending a string the server rejects
  /// with a message they never see. This is the server's own declaration being
  /// enforced, not a rule the app invented.
  static FieldError? _typeError(IntakeQuestion question, Object? answer) {
    if (question.kind.known != IntakeAnswerKind.number) return null;
    if (answer is num) return null;

    return FieldError(
      field: question.key,
      kind: ValidationMessage.answerNotANumber,
      subject: question.prompt,
      message: 'Enter "${question.prompt}" as a number, with digits only.',
    );
  }

  static FieldError? _lengthError(IntakeQuestion question, Object? answer) {
    final maximum = question.maxLength;
    if (maximum == null || answer is! String) return null;
    if (answer.trim().length <= maximum) return null;

    return FieldError(
      field: question.key,
      kind: ValidationMessage.answerTooLong,
      limit: maximum,
      message: 'Shorten this to $maximum characters or fewer.',
    );
  }
}
