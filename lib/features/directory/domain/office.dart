import 'package:flutter/foundation.dart';

/// Which glyph a directory row uses. Presentation maps this to Lucide.
enum OfficeIcon {
  handHeart,
  landmark,
  fileText,
  building2,
  siren,
  graduationCap,
  newspaper,
  users,
  stethoscope,
}

/// Which glyph a fact row uses. The names are icon keys, not resident copy.
enum OfficeFactIcon {
  pin,
  clock,
  phone,
  mail,
  message,
  siren, // stays split so the copy scan does not read the next class
}

/// One public fact on an office page. [sample] keeps the SAMPLE tag.
@immutable
class OfficeFact {
  const OfficeFact({
    required this.label,
    required this.value,
    required this.icon,
    this.sample = false,
  });

  final String label;
  final String value;
  final OfficeFactIcon icon;
  final bool sample;
}

/// A service the office offers. Information only.
@immutable
class OfficeServiceLine {
  const OfficeServiceLine({
    required this.label,
    this.sample = false,
    this.serviceSlug,
  });

  final String label;
  final bool sample;

  /// Tulong slug, when this line came from `GET /services?office=`.
  /// Directory lines from `service_lines` leave this null.
  final String? serviceSlug;
}

/// One municipal office, as public information for residents.
///
/// This is not a staff selector and not an office a resident signs in as
/// (decision D11).
@immutable
class Office {
  const Office({
    required this.id,
    required this.shortName,
    required this.name,
    required this.listName,
    required this.category,
    required this.listLine,
    required this.icon,
    required this.keywords,
    required this.eyebrow,
    required this.summary,
    required this.heroAsset,
    required this.heroFocus,
    required this.insetAsset,
    required this.representative,
    required this.credit,
    required this.messageable,
    required this.callLabel,
    required this.callIsEmergency,
    required this.phone,
    required this.directionsQuery,
    required this.facts,
    required this.services,
    this.serverId = '',
    this.searchLine,
    this.privacy,
    this.composeTo,
    this.topic,
    this.topics = const <String>[],
    this.draft,
    this.savedName,
    this.bannerMediaId,
    this.heroUrl,
    this.latitude,
    this.longitude,
  });

  /// Route slug. Live rows use the office `slug`, which is what
  /// `GET /offices/{slug}` takes.
  final String id;

  /// UUID for `POST /threads` `office_id`. Empty on a fixture row, which has
  /// no server id.
  final String serverId;
  final String shortName;
  final String name;
  final String listName;
  final String category;
  final String listLine;
  final OfficeIcon icon;
  final List<String> keywords;
  final String? searchLine;
  final String eyebrow;
  final String summary;
  final String heroAsset;
  final double heroFocus;
  final String insetAsset;
  final bool representative;
  final String credit;

  /// False for MDRRMO, whose third action is the app, not a message.
  final bool messageable;
  final String callLabel;
  final bool callIsEmergency;
  final String phone;
  final String directionsQuery;
  final List<OfficeFact> facts;
  final List<OfficeServiceLine> services;
  final String? privacy;
  final String? composeTo;
  final String? topic;

  /// Choices for the compose topic picker. The first is the one the field
  /// shows until the resident picks another.
  final List<String> topics;
  final String? draft;

  /// Shorter label on the offline saved-numbers row, when the list name
  /// would wrap. Null keeps [listName].
  final String? savedName;

  /// `banner_media_id` from `GET /offices`. Not a file the app can paint.
  final String? bannerMediaId;

  /// `hero_url` from `GET /offices`. Present when a banner is stored.
  /// The bytes are `GET /offices/{slug}/hero` on the configured API host.
  /// Null keeps [heroAsset], which for a live office is the bundled hall.
  final String? heroUrl;

  /// Office pin from the contract. Null when the office has not published one.
  final double? latitude;
  final double? longitude;

  /// The id sent as `office_id`. A live office sends its UUID.
  String get wireId => serverId.isNotEmpty ? serverId : id;

  /// The thread `subject` when the office publishes no topics.
  ///
  /// `POST /threads` requires a subject, and the office inbox lists it, so it
  /// is fixed wording. It is never taken from what the resident wrote.
  static const String generalTopic = 'General enquiry';

  /// True when the compose screen has topics to offer in a picker.
  /// `GET /offices` publishes none.
  bool get offersTopics => topics.isNotEmpty;

  /// The subject the compose screen starts on.
  String get composeTopic {
    if (topics.isNotEmpty) return topics.first;
    final String named = topic?.trim() ?? '';
    return named.isNotEmpty ? named : generalTopic;
  }

  /// Published directory lines, then Tulong names that are not already listed.
  List<OfficeServiceLine> linesWithCatalogue(
    List<({String label, String slug})> catalogue,
  ) {
    if (catalogue.isEmpty) return services;
    final Set<String> seen = <String>{
      for (final OfficeServiceLine line in services)
        line.label.trim().toLowerCase(),
    };
    final List<OfficeServiceLine> extra = <OfficeServiceLine>[];
    for (final ({String label, String slug}) item in catalogue) {
      final String label = item.label.trim();
      if (label.isEmpty) continue;
      if (!seen.add(label.toLowerCase())) continue;
      extra.add(OfficeServiceLine(label: label, serviceSlug: item.slug));
    }
    if (extra.isEmpty) return services;
    return <OfficeServiceLine>[...services, ...extra];
  }

  Office withServices(List<OfficeServiceLine> services) {
    return Office(
      id: id,
      serverId: serverId,
      shortName: shortName,
      name: name,
      listName: listName,
      category: category,
      listLine: listLine,
      icon: icon,
      keywords: keywords,
      searchLine: searchLine,
      eyebrow: eyebrow,
      summary: summary,
      heroAsset: heroAsset,
      heroFocus: heroFocus,
      insetAsset: insetAsset,
      representative: representative,
      credit: credit,
      messageable: messageable,
      callLabel: callLabel,
      callIsEmergency: callIsEmergency,
      phone: phone,
      directionsQuery: directionsQuery,
      facts: facts,
      services: services,
      privacy: privacy,
      composeTo: composeTo,
      topic: topic,
      topics: topics,
      draft: draft,
      savedName: savedName,
      bannerMediaId: bannerMediaId,
      heroUrl: heroUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }

  bool matches(String query, String chip) {
    if (chip != 'All' && category != chip) return false;
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final String haystack = <String>[
      listName,
      name,
      shortName,
      listLine,
      category,
      ...keywords,
      ...services.map((OfficeServiceLine line) => line.label),
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }

  @override
  String toString() => 'Office($id)';
}

/// One bubble in the sample BPLO thread.
@immutable
class DirectoryThreadBubble {
  const DirectoryThreadBubble({
    required this.fromResident,
    required this.when,
    this.body,
    this.attachment,
    this.attachmentMeta,
  });

  final bool fromResident;
  final String when;
  final String? body;
  final String? attachment;
  final String? attachmentMeta;
}
