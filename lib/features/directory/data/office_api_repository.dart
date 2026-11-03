import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/office.dart';

/// Public office pages on `GET /offices` and `GET /offices/{slug}`.
///
/// The list is unauthenticated. A row carries the contract fields, including
/// `service_lines` (an empty list when the office publishes none) and
/// `hero_url`. The bytes are loaded by `MediaBytesApi.officeHero`, not here.
/// A missing URL or a failed read keeps the bundled hall.
class OfficeApiRepository {
  const OfficeApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String _hall = 'assets/photos/municipal_hall.jpg';

  Future<Result<({List<String> chips, List<Office> offices})>> list() async {
    final List<Office> offices = <Office>[];
    String? cursor;
    for (var page = 0; page < 5; page++) {
      final Result<ApiEnvelope<List<Office>>> response = await _apiClient
          .send<List<Office>>(
            method: HttpMethod.get,
            path: 'offices',
            authenticated: false,
            query: <String, String>{'limit': '50', 'cursor': ?cursor},
            decode: _decodeList,
          );
      switch (response) {
        case Err<ApiEnvelope<List<Office>>>(:final failure):
          return Err<({List<String> chips, List<Office> offices})>(failure);
        case Ok<ApiEnvelope<List<Office>>>(:final value):
          offices.addAll(value.data);
          final String? next = value.pagination?.nextCursor;
          final bool more = value.pagination?.hasMore == true && next != null;
          if (!more) {
            return Ok((chips: _chips(offices), offices: offices));
          }
          cursor = next;
      }
    }
    return Ok((chips: _chips(offices), offices: offices));
  }

  Future<Result<Office?>> bySlug(String slug) async {
    final Result<ApiEnvelope<Office?>> response = await _apiClient
        .send<Office?>(
          method: HttpMethod.get,
          path: 'offices/$slug',
          authenticated: false,
          decode: _decodeOffice,
        );
    return response.map((ApiEnvelope<Office?> envelope) => envelope.data);
  }

  static List<String> _chips(List<Office> offices) {
    final List<String> categories = <String>[];
    for (final Office office in offices) {
      if (office.category.isEmpty || categories.contains(office.category)) {
        continue;
      }
      categories.add(office.category);
    }
    return <String>['All', ...categories];
  }

  static List<Office> _decodeList(Object? data) {
    if (data is! List) return const <Office>[];
    return data.map(_decodeOffice).whereType<Office>().toList(growable: false);
  }

  static Office? _decodeOffice(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> json = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    final Object? id = json['id'];
    final Object? name = json['name'];
    final Object? slug = json['slug'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        slug is! String ||
        slug.isEmpty) {
      return null;
    }
    final String description = _text(json['description']);
    final String phone = _text(json['phone']);
    final String email = _text(json['email']);
    final String hours = _text(json['hours']);
    final String address = _text(json['address']);
    final String head = _text(json['head']);
    final String category = _text(json['category']);
    final String? shortName = _optional(json['short_name']);
    return Office(
      id: slug,
      serverId: id,
      shortName: shortName ?? name,
      name: name,
      listName: name,
      category: category,
      listLine: description.isNotEmpty ? description : address,
      icon: OfficeIcon.building2,
      keywords: const <String>[],
      eyebrow: category.toUpperCase(),
      summary: description,
      heroAsset: _hall,
      heroFocus: 0.5,
      insetAsset: _hall,
      representative: false,
      credit: '',
      messageable: true,
      callLabel: 'Call',
      callIsEmergency: false,
      phone: phone,
      directionsQuery: address.isNotEmpty ? address : name,
      facts: <OfficeFact>[
        if (address.isNotEmpty)
          OfficeFact(
            label: 'Location',
            value: address,
            icon: OfficeFactIcon.pin,
          ),
        if (hours.isNotEmpty)
          OfficeFact(
            label: 'Office hours',
            value: hours,
            icon: OfficeFactIcon.clock,
          ),
        if (phone.isNotEmpty)
          OfficeFact(label: 'Phone', value: phone, icon: OfficeFactIcon.phone),
        if (email.isNotEmpty)
          OfficeFact(label: 'Email', value: email, icon: OfficeFactIcon.mail),
        if (head.isNotEmpty)
          OfficeFact(label: 'Head', value: head, icon: OfficeFactIcon.pin),
      ],
      services: _serviceLines(json['service_lines']),
      bannerMediaId: _optional(json['banner_media_id']),
      heroUrl: _optional(json['hero_url']),
      latitude: _coord(json['latitude']),
      longitude: _coord(json['longitude']),
    );
  }

  /// Missing, null, or a non-list is an empty directory. Strings only.
  static List<OfficeServiceLine> _serviceLines(Object? raw) {
    if (raw is! List) return const <OfficeServiceLine>[];
    return <OfficeServiceLine>[
      for (final Object? item in raw)
        if (item is String && item.trim().isNotEmpty)
          OfficeServiceLine(label: item.trim()),
    ];
  }

  static double? _coord(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  static String _text(Object? value) => value is String ? value : '';

  /// `short_name` is present and null when the office has no short label.
  static String? _optional(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
