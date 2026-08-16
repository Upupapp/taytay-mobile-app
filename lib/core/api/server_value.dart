import 'package:flutter/foundation.dart';

/// A value the server sent that this build may or may not recognise.
///
/// ---
///
/// **Why enums alone are not enough here.** The backend contract is explicit
/// that adding a new enum value is *not* a breaking change
/// (`docs/api/conventions.md` §1: "Adding an optional field or a new error
/// `code` for a new condition is **not** breaking", and "Clients must ignore
/// unknown fields"). A released app therefore has to meet values it has never
/// heard of, and it must not crash, must not silently drop them, and must not
/// guess what they mean.
///
/// So a server value is carried as a pair: the [raw] string exactly as sent, and
/// [known], the enum case when this build recognises it. Screens branch on
/// [known] and fall back gracefully; logs and support quote [raw].
///
/// ---
///
/// **Why it lives in `core/api/`.** It began in the service catalogue's domain,
/// because that was the first feature to decode a server enum. Every feature
/// decodes one now — statuses, publication states, reactions, registration
/// states — and `core/forms/` needs it too. A shape this universal is a property
/// of the API contract rather than of any one feature, which is the same reason
/// `Paginated` lives beside it. `lgu_service.dart` re-exports it, so nothing
/// that already imported it from there had to change.
@immutable
class ServerValue<T extends Enum> {
  const ServerValue({required this.raw, required this.known});

  /// Exactly what the server sent. Never normalised, never discarded.
  final String raw;

  /// The matching case, or `null` when this build does not recognise [raw].
  final T? known;

  bool get isRecognised => known != null;

  static ServerValue<T> parse<T extends Enum>(
    String? raw,
    List<T> values,
    String Function(T) wireValueOf,
  ) {
    final value = raw ?? '';
    for (final candidate in values) {
      if (wireValueOf(candidate) == value) {
        return ServerValue<T>(raw: value, known: candidate);
      }
    }
    return ServerValue<T>(raw: value, known: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ServerValue<T> && other.raw == raw && other.known == known);

  @override
  int get hashCode => Object.hash(raw, known);

  @override
  String toString() => 'ServerValue($raw${isRecognised ? '' : ', unknown'})';
}
