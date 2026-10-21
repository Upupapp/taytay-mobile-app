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
  const OfficeServiceLine({required this.label, this.sample = false});

  final String label;
  final bool sample;
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

  /// The id sent as `office_id`. A live office sends its UUID.
  String get wireId => serverId.isNotEmpty ? serverId : id;

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
