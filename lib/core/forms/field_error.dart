import 'package:flutter/foundation.dart';

/// One field that needs fixing, named so an error summary can link to it.
///
/// ---
///
/// **Why this lives in `core/` rather than in the feature that first needed it.**
///
/// It was written for the registration wizard and kept in that feature's
/// `domain/`. Two things then reached across the boundary to use it:
/// `shared/widgets/form_support.dart` imported it — a shared widget depending on
/// one feature's domain — and the assistance intake wizard would have made it a
/// feature-to-feature import as well. Both are the dependency Article 2 rule 2
/// exists to stop.
///
/// A named field error is a form primitive, not a registration concept. It
/// belongs on the seam every form already depends on, so both wizards and the
/// shared error summary read one definition. `registration_validation.dart`
/// re-exports it, so nothing that already imported it had to change.
@immutable
class FieldError {
  const FieldError({required this.field, required this.message});

  /// Stable key matching the field's own identifier, e.g. `family_name`.
  ///
  /// For a server-defined intake question this is the question's `key`, so an
  /// error the server returns against that key lands on the right control
  /// without the app maintaining a translation table.
  final String field;

  /// Resident-facing. Says what to do, not what went wrong internally.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FieldError && other.field == field && other.message == message);

  @override
  int get hashCode => Object.hash(field, message);

  /// Redacted of the message: a validation message can quote what a resident
  /// typed, and this type is reachable from a log line.
  @override
  String toString() => 'FieldError($field)';
}
