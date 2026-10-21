import '../../../core/mock/mock_fixtures.dart';
import '../domain/office.dart';

/// The designed office catalogue.
///
/// Facts live in `test/fixtures/mock/offices.json`. A fact the LGU has not
/// confirmed is marked `sample` and the screen paints the SAMPLE tag. There
/// is no office copy in this file.
abstract final class OfficeCatalogue {
  static Future<({List<String> chips, List<Office> offices})> load() async {
    final Map<String, Object?> json = await MockFixtures.object('offices');
    final List<String> chips = json['chips'] is List
        ? (json['chips']! as List).map((Object? item) => '$item').toList()
        : const <String>['All'];
    final List<Office> offices = json['offices'] is List
        ? (json['offices']! as List)
              .whereType<Map<dynamic, dynamic>>()
              .map(_office)
              .toList(growable: false)
        : const <Office>[];
    return (chips: chips, offices: offices);
  }

  static Future<Office?> byId(String id) async {
    final ({List<String> chips, List<Office> offices}) catalogue = await load();
    for (final Office office in catalogue.offices) {
      if (office.id == id) return office;
    }
    return null;
  }

  /// The sample thread. The day chip comes from the fixture, so this screen
  /// does not decide the label from the clock.
  static Future<({String dayLabel, List<DirectoryThreadBubble> messages})>
  thread() async {
    final Map<String, Object?> json = await MockFixtures.object('offices');
    final Object? thread = json['thread'];
    if (thread is! Map) {
      return (dayLabel: '', messages: const <DirectoryThreadBubble>[]);
    }
    final String dayLabel = thread['day'] is String
        ? thread['day'] as String
        : '';
    final Object? messages = thread['messages'];
    if (messages is! List) {
      return (dayLabel: dayLabel, messages: const <DirectoryThreadBubble>[]);
    }
    return (
      dayLabel: dayLabel,
      messages: messages
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> item) {
            return DirectoryThreadBubble(
              fromResident: item['fromResident'] == true,
              when: '${item['when'] ?? ''}',
              body: item['body'] as String?,
              attachment: item['attachment'] as String?,
              attachmentMeta: item['attachmentMeta'] as String?,
            );
          })
          .toList(growable: false),
    );
  }

  static Office _office(Map<dynamic, dynamic> json) {
    return Office(
      id: '${json['id']}',
      shortName: '${json['shortName']}',
      name: '${json['name']}',
      listName: '${json['listName']}',
      category: '${json['category']}',
      listLine: '${json['listLine']}',
      icon: _icon('${json['icon']}'),
      keywords: json['keywords'] is List
          ? (json['keywords'] as List).map((Object? item) => '$item').toList()
          : const <String>[],
      searchLine: json['searchLine'] as String?,
      eyebrow: '${json['eyebrow']}',
      summary: '${json['summary']}',
      heroAsset: '${json['hero']}',
      heroFocus: (json['heroFocus'] as num?)?.toDouble() ?? 0.5,
      insetAsset: '${json['inset']}',
      representative: json['representative'] == true,
      credit: '${json['credit']}',
      messageable: json['actions'] is List
          ? (json['actions'] as List).contains('message')
          : true,
      callLabel: '${json['callLabel'] ?? 'Call'}',
      callIsEmergency: json['callTone'] == 'danger',
      phone: '${json['phone'] ?? ''}',
      directionsQuery: '${json['directionsQuery'] ?? ''}',
      privacy: json['privacy'] as String?,
      composeTo: json['composeTo'] as String?,
      topic: json['topic'] as String?,
      draft: json['draft'] as String?,
      savedName: json['savedName'] as String?,
      facts: json['facts'] is List
          ? (json['facts'] as List).whereType<Map<dynamic, dynamic>>().map((
              Map<dynamic, dynamic> item,
            ) {
              return OfficeFact(
                label: '${item['label']}',
                value: '${item['value']}',
                icon: _factIcon('${item['icon']}'),
                sample: item['sample'] == true,
              );
            }).toList()
          : const <OfficeFact>[],
      services: json['services'] is List
          ? (json['services'] as List).whereType<Map<dynamic, dynamic>>().map((
              Map<dynamic, dynamic> item,
            ) {
              return OfficeServiceLine(
                label: '${item['label']}',
                sample: item['sample'] == true,
              );
            }).toList()
          : const <OfficeServiceLine>[],
    );
  }

  static OfficeIcon _icon(String name) => switch (name) {
    'landmark' => OfficeIcon.landmark,
    'fileText' => OfficeIcon.fileText,
    'building2' => OfficeIcon.building2,
    'siren' => OfficeIcon.siren,
    'graduationCap' => OfficeIcon.graduationCap,
    'newspaper' => OfficeIcon.newspaper,
    'users' => OfficeIcon.users,
    'stethoscope' => OfficeIcon.stethoscope,
    _ => OfficeIcon.handHeart,
  };

  static OfficeFactIcon _factIcon(String name) => switch (name) {
    'clock' => OfficeFactIcon.clock,
    'phone' => OfficeFactIcon.phone,
    'mail' => OfficeFactIcon.mail,
    'message' => OfficeFactIcon.message,
    'app' => OfficeFactIcon.phone,
    'siren' => OfficeFactIcon.siren,
    _ => OfficeFactIcon.pin,
  };
}
