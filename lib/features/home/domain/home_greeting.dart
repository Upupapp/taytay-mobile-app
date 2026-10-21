import '../../../core/time/manila_time.dart';

/// Filipino time-of-day greeting for Home.
///
/// The name is the session greeting only. A guest is "Bisita". A signed-in
/// resident with no greeting name gets the time of day and no invented name.
abstract final class HomeGreeting {
  static String line(DateTime now, {String? name, required bool guest}) {
    final int hour = ManilaTime.of(now).hour;
    final String part = hour < 12
        ? 'umaga'
        : hour < 18
        ? 'hapon'
        : 'gabi';
    final String? who = guest ? 'Bisita' : _trimmed(name);
    if (who == null) return 'Magandang $part!';
    return 'Magandang $part, $who!';
  }

  /// Initials from a greeting name. One word yields one letter.
  static String initials(String? name) {
    final String? trimmed = _trimmed(name);
    if (trimmed == null) return '';
    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return _letter(parts.first);
    return '${_letter(parts.first)}${_letter(parts.last)}';
  }

  static String? _trimmed(String? name) {
    final String value = name?.trim() ?? '';
    if (value.isEmpty) return null;
    return value;
  }

  static String _letter(String word) {
    final iterator = word.runes.iterator;
    if (!iterator.moveNext()) return '';
    return String.fromCharCode(iterator.current).toUpperCase();
  }
}
