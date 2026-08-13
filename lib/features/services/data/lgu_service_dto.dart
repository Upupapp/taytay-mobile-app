import '../domain/lgu_service.dart';

/// Wire ↔ domain mapping for `LguServiceResource`.
///
/// ---
///
/// **The wire format stops here** (CLAUDE.md Article 2.4). Nothing above the
/// data layer sees a `Map<String, dynamic>`.
///
/// Three rules shape this mapping, all from the committed contract:
///
/// 1. **Unknown fields are ignored, never rejected** (conventions §1). The
///    decoder reads the keys it knows and walks past anything else, so a server
///    that adds a field cannot break a released app.
/// 2. **Unknown enum *values* are preserved, not dropped.** They arrive as a
///    [ServerValue] carrying the raw string, because a new category is an
///    additive change the server may make at any time and the app must be able
///    to report what it actually received.
/// 3. **Nothing is inferred.** No eligibility, no "can apply", no derived
///    availability beyond restating what the server sent. Those are server-side
///    decisions (ADR 0002).
///
/// Fields mapped, from `Http/Resources/LguServiceResource.php` at commit
/// `7844859`: `id`, `code`, `name`, `description`, `category`, `status`,
/// `available_channels`. There are no others, and none are invented here.
abstract final class LguServiceDto {
  /// Decodes one catalogue entry.
  ///
  /// Returns `null` when the payload is not a JSON object or is missing the
  /// identity fields that make an entry addressable. A malformed row is skipped
  /// rather than allowed to fail a whole page — one bad record must not hide the
  /// rest of the catalogue from a resident.
  static LguService? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    final id = _string(raw['id']);
    final code = _string(raw['code']);
    if (id == null || code == null) return null;

    return LguService(
      id: id,
      code: code,
      name: _string(raw['name']) ?? code,
      description: _string(raw['description']) ?? '',
      category: ServerValue.parse<ServiceCategory>(
        _string(raw['category']),
        ServiceCategory.values,
        (value) => value.wireValue,
      ),
      status: ServerValue.parse<ServicePublicationStatus>(
        _string(raw['status']),
        ServicePublicationStatus.values,
        (value) => value.wireValue,
      ),
      availableChannels: _channels(raw['available_channels']),
    );
  }

  /// Decodes the `data` array of a paginated catalogue response.
  static List<LguService> listFromJson(Object? raw) {
    if (raw is! List) return const <LguService>[];
    return raw
        .map(fromJson)
        .whereType<LguService>()
        .toList(growable: false);
  }

  static List<ServerValue<ServiceChannel>> _channels(Object? raw) {
    if (raw is! List) return const <ServerValue<ServiceChannel>>[];
    return raw
        .whereType<String>()
        .map(
          (value) => ServerValue.parse<ServiceChannel>(
            value,
            ServiceChannel.values,
            (channel) => channel.wireValue,
          ),
        )
        .toList(growable: false);
  }

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
