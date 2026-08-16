/// A form field whose shape the **server** decides.
///
/// ---
///
/// ## Why this lives in `core/`
///
/// It was written for the assistance intake in TAB 15, where the rule is that
/// the app holds no per-service question list. Event registration in TAB 22
/// needs exactly the same thing: a set of fields an office defined, rendered by
/// a client that does not know what they are.
///
/// Duplicating it would have produced two enums, two `isRenderable` rules and
/// two switches over the same concept — and two switches over one concept drift,
/// which is the lesson already written down as D-79. So the shape moved here,
/// where a feature is allowed to depend on it, and `assistance_intake.dart`
/// aliases the old names so nothing that already used them had to change.
///
/// The rule the type exists to protect is unchanged: **the app renders what the
/// office asked for and invents nothing.** A form a client authors drifts the
/// moment the office changes it, and a shipped build cannot be patched that day.
library;

import 'package:flutter/foundation.dart';

import '../api/server_value.dart';

export '../api/server_value.dart';

/// How one field is answered.
enum ServerFieldKind {
  shortText('short_text'),
  longText('long_text'),
  number('number'),
  date('date'),
  yesNo('yes_no'),
  singleChoice('single_choice'),
  multipleChoice('multiple_choice');

  const ServerFieldKind(this.wireValue);

  final String wireValue;
}

/// One option on a choice field.
@immutable
class ServerFieldChoice {
  const ServerFieldChoice({required this.value, required this.label});

  /// Sent back verbatim. Opaque to the app.
  final String value;

  /// Resident-facing, authored by the LGU.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerFieldChoice &&
          other.value == value &&
          other.label == label);

  @override
  int get hashCode => Object.hash(value, label);

  @override
  String toString() => 'ServerFieldChoice($value)';
}

/// One question an office asks.
@immutable
class ServerField {
  const ServerField({
    required this.key,
    required this.prompt,
    required this.kind,
    this.helpText,
    this.isRequired = true,
    this.maxLength,
    this.choices = const <ServerFieldChoice>[],
  });

  /// Stable server key. The answer is sent under it, and a server-side
  /// validation error against it lands on this control without translation.
  final String key;

  final String prompt;
  final ServerValue<ServerFieldKind> kind;

  /// Optional guidance shown under the prompt.
  final String? helpText;

  final bool isRequired;

  /// Server-declared cap. `null` means the server stated none, and the app does
  /// not invent a limit — a guessed cap silently truncates an answer the office
  /// would have accepted.
  final int? maxLength;

  final List<ServerFieldChoice> choices;

  bool get _needsChoices =>
      kind.known == ServerFieldKind.singleChoice ||
      kind.known == ServerFieldKind.multipleChoice;

  /// Whether this build can present an input for this field.
  ///
  /// False for a kind this version has never heard of, and for a choice field
  /// that arrived with no options. **An unrenderable field is never skipped** —
  /// skipping it would submit something the office considers incomplete, and
  /// the resident would never learn which answer was missing.
  bool get isRenderable =>
      kind.isRecognised && (!_needsChoices || choices.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ServerField && other.key == key);

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ServerField($key, ${kind.raw})';
}

/// An acknowledgement the LGU requires before something is accepted.
///
/// **Declared by the server, never by the app.** What a resident is asked to
/// consent to under RA 10173 is a decision with legal weight; a client that
/// invents a consent statement is asserting a purpose of processing nobody with
/// authority wrote.
@immutable
class ServerConsent {
  const ServerConsent({
    required this.key,
    required this.label,
    required this.statement,
    this.isRequired = true,
  });

  final String key;

  /// Short name, for a review row.
  final String label;

  /// The full sentence a resident is agreeing to.
  final String statement;

  final bool isRequired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ServerConsent && other.key == key);

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ServerConsent($key)';
}
