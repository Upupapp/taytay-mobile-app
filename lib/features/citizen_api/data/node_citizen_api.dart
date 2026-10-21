import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/citizen_contract.dart';

/// Citizen routes that no older repository already calls.
///
/// Home, offices, and media. Messaging, profile, news, services, and
/// notifications keep their own repositories. Nothing here calls an `/admin`
/// path.
class NodeCitizenApi {
  const NodeCitizenApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<HomeFeed>> loadHome() async {
    final response = await _apiClient.send<HomeFeed>(
      method: HttpMethod.get,
      path: 'home',
      authenticated: false,
      decode: _decodeHome,
    );
    return response.map((envelope) => envelope.data);
  }

  Future<Result<List<MunicipalOffice>>> listOffices() async {
    final response = await _apiClient.send<List<MunicipalOffice>>(
      method: HttpMethod.get,
      path: 'offices',
      authenticated: false,
      decode: _decodeOffices,
    );
    return response.map((envelope) => envelope.data);
  }

  Future<Result<MunicipalOffice?>> loadOffice(String slug) async {
    final response = await _apiClient.send<MunicipalOffice?>(
      method: HttpMethod.get,
      path: 'offices/$slug',
      authenticated: false,
      decode: _decodeOffice,
    );
    return response.map((envelope) => envelope.data);
  }

  Future<Result<MediaRecord?>> uploadMedia(MultipartFile file) async {
    final response = await _apiClient.send<MediaRecord?>(
      method: HttpMethod.post,
      path: 'media',
      authenticated: true,
      file: MultipartFile(
        field: 'file',
        filename: file.filename,
        bytes: file.bytes,
        mimeType: file.mimeType,
      ),
      decode: _decodeMedia,
    );
    return response.map((envelope) => envelope.data);
  }

  Future<Result<MediaRecord?>> loadMedia(String id) async {
    final response = await _apiClient.send<MediaRecord?>(
      method: HttpMethod.get,
      path: 'media/$id',
      authenticated: true,
      decode: _decodeMedia,
    );
    return response.map((envelope) => envelope.data);
  }

  static HomeFeed _decodeHome(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    return HomeFeed(
      banners: _list(
        map['banners'],
      ).map(_banner).whereType<HomeBanner>().toList(growable: false),
      quickLinks: _list(
        map['quick_links'],
      ).map(_link).whereType<HomeQuickLink>().toList(growable: false),
      newsIds: _list(map['news'])
          .map((Object? row) => _string(_map(row)['id']))
          .whereType<String>()
          .toList(growable: false),
      serviceSlugs: _list(map['services'])
          .map(
            (Object? row) =>
                _string(_map(row)['slug']) ?? _string(_map(row)['id']),
          )
          .whereType<String>()
          .toList(growable: false),
      hotlines: _list(
        map['hotlines'],
      ).map(_hotline).whereType<MunicipalHotline>().toList(growable: false),
    );
  }

  /// `GET /hotlines`. The screen that lists them is still a later sprint.
  Future<Result<List<MunicipalHotline>>> listHotlines() async {
    final response = await _apiClient.send<List<MunicipalHotline>>(
      method: HttpMethod.get,
      path: 'hotlines',
      authenticated: false,
      decode: (Object? data) => _list(
        data,
      ).map(_hotline).whereType<MunicipalHotline>().toList(growable: false),
    );
    return response.map((envelope) => envelope.data);
  }

  static MunicipalHotline? _hotline(Object? raw) {
    final map = _map(raw);
    final id = _string(map['id']);
    final name = _string(map['name']);
    final number = _string(map['number']);
    if (id == null || name == null || number == null) return null;
    return MunicipalHotline(
      id: id,
      name: name,
      number: number,
      category: _string(map['category']) ?? '',
      sortOrder: map['sort_order'] is int ? map['sort_order'] as int : 0,
      active: map['active'] != false,
      createdAt: DateTime.tryParse(
        map['created_at'] is String ? map['created_at'] as String : '',
      )?.toUtc(),
      updatedAt: DateTime.tryParse(
        map['updated_at'] is String ? map['updated_at'] as String : '',
      )?.toUtc(),
    );
  }

  static HomeBanner? _banner(Object? raw) {
    final map = _map(raw);
    final id = _string(map['id']);
    final title = _string(map['title']);
    if (id == null || title == null) return null;
    return HomeBanner(
      id: id,
      title: title,
      sortOrder: map['sort_order'] is int ? map['sort_order'] as int : 0,
      active: map['active'] != false,
      mediaId: _string(map['media_id']),
      href: _string(map['href']),
    );
  }

  static HomeQuickLink? _link(Object? raw) {
    final map = _map(raw);
    final id = _string(map['id']);
    final label = _string(map['label']);
    final href = _string(map['href']);
    if (id == null || label == null || href == null) return null;
    return HomeQuickLink(
      id: id,
      label: label,
      href: href,
      sortOrder: map['sort_order'] is int ? map['sort_order'] as int : 0,
    );
  }

  static List<MunicipalOffice> _decodeOffices(Object? data) {
    return _list(
      data,
    ).map(_decodeOffice).whereType<MunicipalOffice>().toList(growable: false);
  }

  static MunicipalOffice? _decodeOffice(Object? raw) {
    final map = _map(raw);
    final id = _string(map['id']);
    final name = _string(map['name']);
    final slug = _string(map['slug']);
    if (id == null || name == null || slug == null) return null;
    return MunicipalOffice(
      id: id,
      name: name,
      slug: slug,
      description: _string(map['description']) ?? '',
      head: _string(map['head']) ?? '',
      hours: _string(map['hours']) ?? '',
      phone: _string(map['phone']) ?? '',
      email: _string(map['email']) ?? '',
      address: _string(map['address']) ?? '',
      category: _string(map['category']) ?? '',
    );
  }

  static MediaRecord? _decodeMedia(Object? raw) {
    final map = _map(raw);
    final id = _string(map['id']);
    final type = _string(map['content_type']);
    if (id == null || type == null) return null;
    final Object? size = map['byte_size'];
    return MediaRecord(
      id: id,
      contentType: type,
      byteSize: size is int ? size : 0,
    );
  }

  static List<Object?> _list(Object? raw) =>
      raw is List<dynamic> ? raw : const <Object?>[];

  static Map<String, dynamic> _map(Object? raw) =>
      raw is Map<String, dynamic> ? raw : const <String, dynamic>{};

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
