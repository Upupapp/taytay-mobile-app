import '../../../core/api/api_client.dart';
import '../../../core/mock/mock_fixtures.dart';
import '../../../core/result/result.dart';
import '../domain/office.dart';
import 'office_api_repository.dart';

/// Raised when `GET /offices` does not answer. The screen turns that into
/// the offline frame.
final class OfficeDirectoryException implements Exception {
  OfficeDirectoryException(this.failure);

  final AppFailure failure;
}

/// The office catalogue.
///
/// A dev mock reads `test/fixtures/mock/offices.json`. Every other build
/// reads `GET /offices` and `GET /offices/{slug}`. The fixture is not a
/// silent fallback for a failed live call.
abstract final class OfficeCatalogue {
  static Future<({List<String> chips, List<Office> offices})> load({
    bool mock = true,
    ApiClient? api,
  }) async {
    if (mock) return _fixture();
    final Result<({List<String> chips, List<Office> offices})> result =
        await OfficeApiRepository(apiClient: api!).list();
    switch (result) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        throw OfficeDirectoryException(failure);
    }
  }

  static Future<Office?> byId(
    String id, {
    bool mock = true,
    ApiClient? api,
  }) async {
    if (mock) {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await _fixture();
      for (final Office office in catalogue.offices) {
        if (office.id == id) return office;
      }
      return null;
    }
    final Result<Office?> result = await OfficeApiRepository(
      apiClient: api!,
    ).bySlug(id);
    return switch (result) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  static Future<({List<String> chips, List<Office> offices})> _fixture() async {
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
      topics: _topics(json),
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

  static List<String> _topics(Map<dynamic, dynamic> json) {
    if (json['topics'] is List) {
      return (json['topics'] as List)
          .map((Object? item) => '$item')
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final Object? topic = json['topic'];
    if (topic is String && topic.isNotEmpty) return <String>[topic];
    return const <String>[];
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
