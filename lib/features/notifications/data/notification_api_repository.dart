import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../../../core/session/push_registration.dart';
import '../domain/notification_repository.dart';

/// Talks to `me/notifications` and `me/notification-preferences`.
///
/// ---
///
/// **Only this repository was ever the stub.** Everything above it — optimistic
/// read with reconciliation, Manila-day grouping, critical categories that
/// cannot be switched off, a push prompt deferred to a meaningful moment, a
/// payload policy that refuses anything carrying personal data — is the
/// strongest feature in this codebase and is fully tested. None of its semantics
/// change here; the repository beneath simply stops declining.
///
/// **The deep link is a type and an identifier, and that is all it may ever be.**
/// The server sends `subject_type` and `subject_id`; the client opens that record
/// through its own module's endpoint, where authorization is rechecked. A
/// payload that named an action, or that carried a name, an amount or a case
/// narrative, would be personal data delivered to a lock screen that anybody
/// standing nearby can read — which is why the policy above this refuses it and
/// why nothing here widens what a target may contain.
class NotificationApiRepository
    implements NotificationRepository, PushRegistrationWithdrawal {
  const NotificationApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'me/notifications';
  static const String preferencesPath = 'me/notification-preferences';

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _apiClient.send<List<ResidentNotification>>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      query: <String, String>{
        'page': '${page < 1 ? 1 : page}',
        'per_page': '${perPage.clamp(1, 100)}',
      },
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decode)
                .whereType<ResidentNotification>()
                .toList(growable: false)
          : const <ResidentNotification>[],
    );
    return response.map(_toPage);
  }

  @override
  Future<Result<void>> markRead(String id) async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: '$path/$id/read',
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<void>> markAllRead() async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: '$path/read-all',
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<NotificationPreferences>> loadPreferences() async {
    final response = await _apiClient.send<NotificationPreferences>(
      method: HttpMethod.get,
      path: preferencesPath,
      authenticated: true,
      decode: _decodePreferences,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    // Sent per type and channel, the shape the server stores. Critical
    // categories are not included at all rather than being sent as `true`: the
    // rule that they cannot be switched off belongs to the server, and a client
    // that asserts it in a payload is a client that could assert the opposite.
    final List<Map<String, Object?>> rows = <Map<String, Object?>>[
      for (final MapEntry<NotificationCategory, bool> entry
          in preferences.categories.entries)
        if (!entry.key.isCritical)
          <String, Object?>{
            'notification_type': entry.key.wireValue,
            'channel': 'push',
            'enabled': entry.value,
          },
    ];

    final response = await _apiClient.send<void>(
      method: HttpMethod.put,
      path: preferencesPath,
      authenticated: true,
      body: <String, Object?>{'preferences': rows},
      decode: (_) {},
    );
    return response.map((_) {});
  }

  /// Registers this device so the office can reach it.
  ///
  /// `me/devices` is the device registry — the same one TAB 03 deliberately did
  /// not touch, because a registration whose purpose is a push token is not a
  /// session list and had nothing to carry. Here it has one.
  @override
  Future<Result<String>> registerPushToken(String token) async {
    final response = await _apiClient.send<String>(
      method: HttpMethod.post,
      path: 'me/devices',
      authenticated: true,
      body: <String, Object?>{
        // A stable per-install value, not a hardware identifier. The server
        // needs to recognise the same phone twice; it does not need to know
        // which phone it is.
        'fingerprint': token.hashCode.toRadixString(16),
        'display_name': 'Taytay LGU app',
        'platform': 'android',
        'push_token': token,
      },
      // The id is read, not discarded. `ApiResponse::item(['id' => ...], 201)`
      // is what the server returns and it is the only handle that can revoke
      // this registration later.
      decode: (Object? data) =>
          data is Map<String, dynamic> && data['id'] is String
          ? data['id'] as String
          : '',
    );

    return response.map((envelope) => envelope.data);
  }

  /// Withdraws a registration this install made (F27, closed in TAB 02).
  ///
  /// The old note here said "there is no route that removes a registration by
  /// push token" — true, and beside the point. `DELETE me/devices/{device}`
  /// removes it by **id**, and the id was being thrown away at registration
  /// rather than being unavailable.
  ///
  /// Returns false rather than throwing, and never blocks: the contract in
  /// [PushRegistrationWithdrawal] is that a resident signing out is signed out
  /// whatever the network does.
  @override
  Future<bool> withdraw(String deviceId) async {
    if (deviceId.isEmpty) return false;

    final response = await _apiClient.send<void>(
      method: HttpMethod.delete,
      path: 'me/devices/$deviceId',
      authenticated: true,
      decode: (_) {},
    );

    return response.isOk;
  }

  static ResidentNotification? _decode(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? id = entry['id'];
    final Object? title = entry['title'];
    if (id is! String || id.isEmpty || title is! String) return null;

    final Object? subjectType = entry['subject_type'];
    final Object? subjectId = entry['subject_id'];

    return ResidentNotification(
      id: id,
      title: title,
      body: entry['body'] is String ? entry['body'] as String : '',
      sentAt: DateTime.tryParse(
        entry['created_at'] is String ? entry['created_at'] as String : '',
      )?.toUtc(),
      readAt: DateTime.tryParse(
        entry['read_at'] is String ? entry['read_at'] as String : '',
      )?.toUtc(),
      category: ServerValue.parse<NotificationCategory>(
        entry['category'] is String ? entry['category'] as String : null,
        NotificationCategory.values,
        (NotificationCategory c) => c.wireValue,
      ),
      // Routing only, and only two keys. Anything else the server adds is
      // dropped here rather than carried into a target map that a screen might
      // one day read.
      target: <String, String>{
        if (subjectType is String && subjectType.isNotEmpty)
          'type': subjectType,
        if (subjectId is String && subjectId.isNotEmpty) 'id': subjectId,
      },
    );
  }

  static NotificationPreferences _decodePreferences(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final Object? rows = map['preferences'];

    final Map<NotificationCategory, bool> categories =
        <NotificationCategory, bool>{};
    if (rows is List<dynamic>) {
      for (final Object? row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final Object? type = row['notification_type'];
        if (type is! String) continue;
        for (final NotificationCategory category
            in NotificationCategory.values) {
          if (category.wireValue == type) {
            // A critical category's stored row is ignored, not trusted. The
            // server states in the same payload that service and security
            // notices cannot be switched off; honouring a stray `false` would
            // silence the one message a resident must not miss.
            categories[category] =
                category.isCritical || row['enabled'] == true;
          }
        }
      }
    }

    // The server stores a row per type *and channel*. A channel is on for this
    // resident when any category still uses it, which is what the three switches
    // above the category list actually mean — "does the LGU reach me this way at
    // all" — rather than a fourth thing to keep in sync.
    bool anyOn(String channel) =>
        rows is List<dynamic> &&
        rows.any(
          (Object? row) =>
              row is Map<String, dynamic> &&
              row['channel'] == channel &&
              row['enabled'] == true,
        );

    return NotificationPreferences(
      push: anyOn('push'),
      sms: anyOn('sms'),
      email: anyOn('email'),
      categories: categories,
    );
  }

  static Paginated<ResidentNotification> _toPage(
    ApiEnvelope<List<ResidentNotification>> envelope,
  ) {
    final pagination = envelope.pagination;
    if (pagination == null) {
      return Paginated<ResidentNotification>.single(envelope.data);
    }
    return Paginated<ResidentNotification>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
    );
  }
}
