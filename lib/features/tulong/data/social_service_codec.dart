import '../domain/social_service.dart';
import 'office_stamp.dart';

/// Decodes one service.
///
/// [allowPresentation] is true only for the dev fixture. A live payload is
/// not allowed to set icons, SAMPLE, steps, or saved dates, even if a field
/// with that shape appears.
SocialService? decodeSocialService(
  Object? raw, {
  required bool allowPresentation,
  Map<String, OfficeStamp> offices = const <String, OfficeStamp>{},
}) {
  if (raw is! Map) return null;
  final Map<Object?, Object?> json = raw.cast<Object?, Object?>();
  final String? slug = _text(json['slug']);
  final String? name = _text(json['name']);
  if (slug == null || name == null) return null;
  final String? id = _text(json['id']);
  final String? officeSlug = _text(json['office_slug']);
  final OfficeStamp? office = officeSlug == null ? null : offices[officeSlug];
  return SocialService(
    id: id ?? slug,
    name: name,
    slug: slug,
    summary: _text(json['summary']) ?? '',
    details: _text(json['details']) ?? '',
    eligibility: _text(json['eligibility']),
    requirements: _requirements(
      json['requirements'],
      allowSample: allowPresentation,
    ),
    contacts: _contacts(json['contacts']),
    locations: _locations(json['locations']),
    category: _text(json['category']),
    officeId: _text(json['office_id']),
    officeSlug: officeSlug,
    featured: json['featured'] == true,
    officeName: office?.name,
    officeShortName: office?.shortName,
    officeHours: office?.hours,
    officePhone: office?.phone,
    presentation: allowPresentation
        ? _presentation(json['presentation'])
        : null,
  );
}

List<ServiceRequirement> _requirements(
  Object? raw, {
  required bool allowSample,
}) {
  if (raw is! List<Object?>) return const <ServiceRequirement>[];
  final List<ServiceRequirement> rows = <ServiceRequirement>[];
  for (final Object? item in raw) {
    if (item is String) {
      final String text = item.trim();
      if (text.isEmpty) continue;
      rows.add(ServiceRequirement(text: text));
      continue;
    }
    if (item is! Map) continue;
    final Map<Object?, Object?> json = item.cast<Object?, Object?>();
    final String? text = _text(json['text']);
    if (text == null) continue;
    rows.add(
      ServiceRequirement(
        text: text,
        sample: allowSample && json['sample'] == true,
      ),
    );
  }
  return rows;
}

List<ServiceContact> _contacts(Object? raw) {
  if (raw is! List<Object?>) return const <ServiceContact>[];
  final List<ServiceContact> rows = <ServiceContact>[];
  for (final Object? item in raw) {
    if (item is! Map) continue;
    final Map<Object?, Object?> json = item.cast<Object?, Object?>();
    final String? label = _text(json['label']);
    final String? value = _text(json['value']);
    if (label == null || value == null) continue;
    rows.add(ServiceContact(label: label, value: value));
  }
  return rows;
}

List<ServiceLocation> _locations(Object? raw) {
  if (raw is! List<Object?>) return const <ServiceLocation>[];
  final List<ServiceLocation> rows = <ServiceLocation>[];
  for (final Object? item in raw) {
    if (item is! Map) continue;
    final Map<Object?, Object?> json = item.cast<Object?, Object?>();
    final String? name = _text(json['name']);
    final String? address = _text(json['address']);
    if (name == null || address == null) continue;
    rows.add(ServiceLocation(name: name, address: address));
  }
  return rows;
}

TulongPresentation? _presentation(Object? raw) {
  if (raw is! Map) return null;
  final Map<Object?, Object?> json = raw.cast<Object?, Object?>();
  final Object? stepsRaw = json['steps'];
  final List<String> steps = stepsRaw is List<Object?>
      ? stepsRaw
            .whereType<String>()
            .map((String step) => step.trim())
            .where((String step) => step.isNotEmpty)
            .toList(growable: false)
      : const <String>[];
  return TulongPresentation(
    glyph: _text(json['glyph']) ?? 'handHeart',
    tile: _text(json['tile']) ?? 'blue',
    badge: _text(json['badge']),
    heroSample: json['hero_sample'] == true,
    source: _text(json['source']),
    layout: _text(json['layout']) == 'featured'
        ? TulongLayout.featured
        : TulongLayout.standard,
    headline: _text(json['headline']),
    steps: steps,
    listed: json['listed'] != false,
    savedLabel: _text(json['saved_label']),
    listName: _text(json['list_name']),
    headerTitle: _text(json['header_title']),
    headerSubtitle: _text(json['header_subtitle']),
    scheduleLabel: _text(json['schedule_label']),
    scheduleValue: _text(json['schedule_value']),
    questionsLabel: _text(json['questions_label']),
    questionsValue: _text(json['questions_value']),
    shareLabel: _text(json['share_label']),
  );
}

String? _text(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
