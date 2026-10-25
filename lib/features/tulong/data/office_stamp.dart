import '../../../core/mock/mock_fixtures.dart';

/// The office fields Tulong is allowed to join onto a service.
///
/// Name, short name, hours, and phone. Read from `GET /offices` on a live
/// build and from the directory fixture in a dev mock. This file does not
/// import the directory feature.
class OfficeStamp {
  const OfficeStamp({
    required this.slug,
    this.name,
    this.shortName,
    this.hours,
    this.phone,
  });

  final String slug;
  final String? name;
  final String? shortName;
  final String? hours;
  final String? phone;
}

/// Hours from `hours`, or from a fact whose label contains "hour".
///
/// The directory fixture stores hours as a fact. The Node office stores them
/// as `hours`. Neither is copied into the service widget.
String? hoursOf(Map<Object?, Object?> office) {
  final String? direct = _text(office['hours']);
  if (direct != null) return direct;
  final Object? facts = office['facts'];
  if (facts is! List) return null;
  for (final Object? fact in facts) {
    if (fact is! Map) continue;
    final Map<Object?, Object?> row = fact.cast<Object?, Object?>();
    final Object? label = row['label'];
    if (label is! String || !label.toLowerCase().contains('hour')) continue;
    final String? value = _text(row['value']);
    if (value != null) return value;
  }
  return null;
}

OfficeStamp? officeStampFrom(Map<Object?, Object?> office) {
  final String? slug = _text(office['slug']) ?? _text(office['id']);
  if (slug == null) return null;
  return OfficeStamp(
    slug: slug,
    name: _text(office['name']),
    shortName: _text(office['short_name']) ?? _text(office['shortName']),
    hours: hoursOf(office),
    phone: _text(office['phone']),
  );
}

/// Directory fixture offices, keyed by slug (the fixture's `id`).
Future<Map<String, OfficeStamp>> fixtureOffices() async {
  final Map<String, Object?> json = await MockFixtures.object('offices');
  final Object? raw = json['offices'];
  if (raw is! List<Object?>) return const <String, OfficeStamp>{};
  final Map<String, OfficeStamp> stamps = <String, OfficeStamp>{};
  for (final Object? item in raw) {
    if (item is! Map) continue;
    final OfficeStamp? stamp = officeStampFrom(item.cast<Object?, Object?>());
    if (stamp != null) stamps[stamp.slug] = stamp;
  }
  return stamps;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
