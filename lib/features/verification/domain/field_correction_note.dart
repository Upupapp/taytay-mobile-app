import 'package:flutter/foundation.dart';

/// One thing the office asked the resident to fix, named by the field.
///
/// The note is resident-facing guidance. It is not the operator error
/// `message`, and it is not logged: [toString] names the fact of a note and
/// nothing that was written in it.
@immutable
class FieldCorrectionNote {
  const FieldCorrectionNote({required this.label, required this.note});

  /// What the resident calls the field. Fixed copy, not a wire key.
  final String label;

  /// What to change. Shown next to [label] and nowhere else.
  final String note;

  @override
  bool operator ==(Object other) =>
      other is FieldCorrectionNote &&
      other.label == label &&
      other.note == note;

  @override
  int get hashCode => Object.hash(label, note);

  @override
  String toString() => 'FieldCorrectionNote';
}
