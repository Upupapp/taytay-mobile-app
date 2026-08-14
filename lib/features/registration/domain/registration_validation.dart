import 'package:flutter/foundation.dart';

import 'registration_domain.dart';

/// One field that needs fixing, named so an error summary can link to it.
@immutable
class FieldError {
  const FieldError({required this.field, required this.message});

  /// Stable key matching the field's own identifier, e.g. `family_name`.
  final String field;

  /// Resident-facing. Says what to do, not what went wrong internally.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldError && other.field == field && other.message == message);

  @override
  int get hashCode => Object.hash(field, message);

  @override
  String toString() => 'FieldError($field)';
}

/// Validation for the registration wizard.
///
/// ---
///
/// **Client-side validation is a courtesy, never a gate.** It saves a resident a
/// round trip on an obvious mistake. The server validates again and its answer
/// is the one that counts — so nothing here is permissive where the server is
/// strict, and nothing here rejects input the server would have accepted.
///
/// Where a rule is a genuine judgement call, it errs toward *accepting* the
/// resident's input. A name-validation rule that rejects a legitimate Filipino
/// name — a single-word name, a name with `ñ`, an apostrophe, a hyphen — locks a
/// resident out of a government service over punctuation, and there is no
/// appeal path in an app.
abstract final class RegistrationValidation {
  /// Philippine mobile numbers: 11 digits beginning `09`.
  static final RegExp _mobile = RegExp(r'^09\d{9}$');

  /// The one-time code length is not published in the committed contract, so no
  /// length is enforced beyond "not empty" plus a digits-only input filter.
  /// Guessing six would reject a five- or eight-digit code the server sends.
  static const int minimumAge = 15;

  /// Nobody alive is older than this; a birth date beyond it is a typo.
  static const int maximumAge = 130;

  static List<FieldError> validateContact(RegistrationDraft draft) {
    final errors = <FieldError>[];
    final mobile = draft.mobileNumber.trim();

    if (mobile.isEmpty) {
      errors.add(
        const FieldError(
          field: 'mobile_number',
          message: 'Enter your mobile number.',
        ),
      );
    } else if (!_mobile.hasMatch(mobile)) {
      errors.add(
        const FieldError(
          field: 'mobile_number',
          message: 'Enter an 11-digit mobile number starting with 09.',
        ),
      );
    }
    return errors;
  }

  static List<FieldError> validateCode(String code) {
    if (code.trim().isEmpty) {
      return const <FieldError>[
        FieldError(
          field: 'one_time_code',
          message: 'Enter the code we sent to your mobile number.',
        ),
      ];
    }
    return const <FieldError>[];
  }

  static List<FieldError> validatePersonalDetails(
    RegistrationDraft draft, {
    DateTime? now,
  }) {
    final errors = <FieldError>[];
    final today = now ?? DateTime.now();

    if (draft.givenName.trim().isEmpty) {
      errors.add(
        const FieldError(
          field: 'given_name',
          message: 'Enter your first name as it appears on your ID.',
        ),
      );
    }
    if (draft.familyName.trim().isEmpty) {
      errors.add(
        const FieldError(
          field: 'family_name',
          message: 'Enter your last name as it appears on your ID.',
        ),
      );
    }
    // Middle name and suffix are deliberately unvalidated and optional: plenty
    // of Filipino records carry neither.

    final birthDate = draft.birthDate;
    if (birthDate == null) {
      errors.add(
        const FieldError(
          field: 'birth_date',
          message: 'Enter your date of birth.',
        ),
      );
    } else {
      final age = _ageOn(birthDate, today);
      if (birthDate.isAfter(today)) {
        errors.add(
          const FieldError(
            field: 'birth_date',
            message: 'Date of birth cannot be in the future.',
          ),
        );
      } else if (age > maximumAge) {
        errors.add(
          const FieldError(
            field: 'birth_date',
            message: 'Check the year — that date looks too far back.',
          ),
        );
      } else if (age < minimumAge) {
        // A floor rather than 18: Taytay services include youth and student
        // programmes, and an app that refuses a 16-year-old applying for a
        // youth service has excluded exactly the people it is for. The LGU,
        // not this client, decides what a minor may then do.
        errors.add(
          const FieldError(
            field: 'birth_date',
            message:
                'You need to be at least $minimumAge to register on your own. '
                'A parent or guardian can register at the municipal hall.',
          ),
        );
      }
    }
    return errors;
  }

  static List<FieldError> validateAddress(RegistrationDraft draft) {
    final errors = <FieldError>[];

    if (draft.barangay == null) {
      errors.add(
        const FieldError(field: 'barangay', message: 'Choose your barangay.'),
      );
    }
    if (draft.streetAddress.trim().isEmpty) {
      errors.add(
        const FieldError(
          field: 'street_address',
          message: 'Enter your house number and street.',
        ),
      );
    }
    return errors;
  }

  static List<FieldError> validateConsent(RegistrationDraft draft) {
    return <FieldError>[
      for (final kind in ConsentKind.values)
        if (kind.required && !draft.hasConsent(kind))
          FieldError(
            field: 'consent_${kind.name}',
            message: 'You need to accept the ${kind.label} to continue.',
          ),
    ];
  }

  /// Whole-person age on [on].
  static int _ageOn(DateTime birthDate, DateTime on) {
    var age = on.year - birthDate.year;
    final hadBirthday =
        on.month > birthDate.month ||
        (on.month == birthDate.month && on.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age;
  }

  /// Validates whichever step is current.
  static List<FieldError> validateStep(
    RegistrationStep step,
    RegistrationDraft draft, {
    String code = '',
    DateTime? now,
  }) => switch (step) {
    RegistrationStep.contact => validateContact(draft),
    RegistrationStep.verifyCode => validateCode(code),
    RegistrationStep.personalDetails => validatePersonalDetails(
      draft,
      now: now,
    ),
    RegistrationStep.address => validateAddress(draft),
    RegistrationStep.consent => validateConsent(draft),
    // Upload steps validate on selection, not on continue: the picker either
    // produced a file or it did not.
    RegistrationStep.identityDocument =>
      draft.identityDocument == null
          ? const <FieldError>[
              FieldError(
                field: 'identity_document',
                message: 'Add a photo of your ID to continue.',
              ),
            ]
          : const <FieldError>[],
    RegistrationStep.faceCapture =>
      draft.faceCapture == null
          ? const <FieldError>[
              FieldError(
                field: 'face_capture',
                message: 'Take a photo of yourself to continue.',
              ),
            ]
          : const <FieldError>[],
    RegistrationStep.review ||
    RegistrationStep.submitting ||
    RegistrationStep.status => const <FieldError>[],
  };
}
