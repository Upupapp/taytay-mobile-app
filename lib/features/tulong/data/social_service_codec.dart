import '../domain/social_service.dart';
import 'office_stamp.dart';

/// Decodes one service.
///
/// [allowPresentation] is true only for the dev fixture. A live payload
/// cannot set SAMPLE, a saved date, or a renamed list row. Icon, tile,
/// badge, legal basis, claim steps, the featured headline, schedule,
/// hero URL, and hidden-from-list are real `Service` fields and are read
/// either way.
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
    iconKey: canonicalServiceIconKey(_text(json['icon_key'])),
    tileColor: _tileColor(json['tile_color']),
    badge: _text(json['badge']),
    legalBasis: _text(json['legal_basis']),
    claimSteps: _steps(json['claim_steps']),
    featuredHeadline: _text(json['featured_headline']),
    schedule: _text(json['schedule']),
    heroUrl: _text(json['hero_url']),
    hiddenFromList: json['hidden_from_list'] == true,
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
    final String? value = _text(json['value']);
    if (value == null) continue;
    rows.add(
      ServiceContact(
        type: _contactType(json['type']),
        label: _text(json['label']),
        value: value,
      ),
    );
  }
  return rows;
}

ServiceContactType _contactType(Object? raw) {
  return switch (_text(raw)?.toLowerCase()) {
    'facebook' => ServiceContactType.facebook,
    'landline' => ServiceContactType.landline,
    'hotline' => ServiceContactType.hotline,
    'email' => ServiceContactType.email,
    'mobile' => ServiceContactType.mobile,
    _ => ServiceContactType.unknown,
  };
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

/// `#RGB` or `#RRGGBB`, opaque. Anything else is null.
int? _tileColor(Object? raw) {
  final String? text = _text(raw);
  if (text == null) return null;
  final RegExpMatch? six = RegExp(r'^#([0-9A-Fa-f]{6})$').firstMatch(text);
  if (six != null) {
    return 0xFF000000 | int.parse(six.group(1)!, radix: 16);
  }
  final RegExpMatch? three = RegExp(r'^#([0-9A-Fa-f]{3})$').firstMatch(text);
  if (three != null) {
    final String hex = three.group(1)!;
    final String expanded =
        '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    return 0xFF000000 | int.parse(expanded, radix: 16);
  }
  return null;
}

List<String> _steps(Object? raw) {
  if (raw is! List<Object?>) return const <String>[];
  return raw
      .whereType<String>()
      .map((String step) => step.trim())
      .where((String step) => step.isNotEmpty)
      .toList(growable: false);
}

TulongPresentation? _presentation(Object? raw) {
  if (raw is! Map) return null;
  final Map<Object?, Object?> json = raw.cast<Object?, Object?>();
  final bool heroSample = json['hero_sample'] == true;
  final String? savedLabel = _text(json['saved_label']);
  final String? listName = _text(json['list_name']);
  final String? headerTitle = _text(json['header_title']);
  final String? headerSubtitle = _text(json['header_subtitle']);
  final String? questionsLabel = _text(json['questions_label']);
  final String? questionsValue = _text(json['questions_value']);
  final String? shareLabel = _text(json['share_label']);
  if (!heroSample &&
      savedLabel == null &&
      listName == null &&
      headerTitle == null &&
      headerSubtitle == null &&
      questionsLabel == null &&
      questionsValue == null &&
      shareLabel == null) {
    return null;
  }
  return TulongPresentation(
    heroSample: heroSample,
    savedLabel: savedLabel,
    listName: listName,
    headerTitle: headerTitle,
    headerSubtitle: headerSubtitle,
    questionsLabel: questionsLabel,
    questionsValue: questionsValue,
    shareLabel: shareLabel,
  );
}

String? _text(Object? value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
