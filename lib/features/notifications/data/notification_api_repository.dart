import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../../../core/router/deep_link.dart';
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

  static const String path = 'notifications';
  static const String readAllPath = 'notifications/read';
  static const String unreadCountPath = 'notifications/unread-count';

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int? perPage,
    String? cursor,
  }) async {
    assert(page >= 1);
    final String? next = cursor != null && cursor.isNotEmpty ? cursor : null;
    final response = await _apiClient.send<List<ResidentNotification>>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      query: <String, String>{
        'limit':
            '${_apiClient.pages.clampRequest(perPage ?? _apiClient.pages.defaultPerPage)}',
        'cursor': ?next,
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
      path: readAllPath,
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<NotificationPreferences>> loadPreferences() async {
    final response = await _apiClient.send<NotificationPreferences>(
      method: HttpMethod.get,
      path: 'me/notification-preferences',
      authenticated: true,
      decode: _decodePreferences,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.patch,
      path: 'me/notification-preferences',
      authenticated: true,
      body: <String, Object?>{'preferences': _preferenceBody(preferences)},
      decode: (_) {},
    );
    return response.map((_) {});
  }

  /// Registers this device so the office can reach it.
  ///
  /// `POST /me/devices` takes `{platform, token}` and returns a device row
  /// that does **not** include the token. The value returned here is the
  /// token that was sent, because `DELETE /me/devices` removes the row by
  /// that token in the body. It is not logged.
  @override
  Future<Result<String>> registerPushToken(String token) async {
    if (token.isEmpty) {
      return const Err<String>(
        ValidationFailure(debugMessage: 'A push token is required.'),
      );
    }
    final response = await _apiClient.send<String>(
      method: HttpMethod.post,
      path: 'me/devices',
      authenticated: true,
      body: <String, Object?>{'platform': _devicePlatform(), 'token': token},
      decode: (_) => token,
    );
    return response.map((envelope) => envelope.data);
  }

  /// Withdraws the push registration by the token [registerPushToken] returned.
  ///
  /// `DELETE /me/devices` carries `{token}` in the body. This is not session
  /// revocation. Returns false rather than throwing: a resident signing out
  /// is signed out whatever the network does.
  @override
  Future<bool> withdraw(String deviceId) async {
    if (deviceId.isEmpty) return false;
    final Result<ApiEnvelope<bool>> response = await _apiClient.send<bool>(
      method: HttpMethod.delete,
      path: 'me/devices',
      authenticated: true,
      body: <String, Object?>{'token': deviceId},
      decode: (Object? data) {
        if (data is Map<String, dynamic>) return data['deleted'] == true;
        return false;
      },
    );
    return switch (response) {
      Ok<ApiEnvelope<bool>>(:final value) => value.data,
      Err<ApiEnvelope<bool>>() => false,
    };
  }

  static String _devicePlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'web',
    };
  }

  static NotificationPreferences _decodePreferences(Object? data) {
    final Map<String, dynamic> map = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};
    final Object? raw = map['preferences'];
    final List<ChannelPreference> channels = raw is List<dynamic>
        ? raw
              .map(_channel)
              .whereType<ChannelPreference>()
              .toList(growable: false)
        : const <ChannelPreference>[];
    final bool push =
        channels.isEmpty || channels.any((ChannelPreference c) => c.push);
    ChannelPreference? verification;
    for (final ChannelPreference channel in channels) {
      if (channel.type == 'verification_decided') verification = channel;
    }
    return NotificationPreferences(
      push: push,
      sms: false,
      email: false,
      channels: channels,
      categories: <NotificationCategory, bool>{
        if (verification != null)
          NotificationCategory.verificationUpdate: verification.inApp,
      },
    );
  }

  static ChannelPreference? _channel(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final Object? type = raw['type'];
    if (type is! String || !preferenceTypes.contains(type)) return null;
    return ChannelPreference(
      type: type,
      inApp: _flag(raw['in_app']),
      push: _flag(raw['push']),
    );
  }

  /// An omitted flag is on. An explicit false stays off.
  static bool _flag(Object? value) => value is bool ? value : true;

  static List<Map<String, Object?>> _preferenceBody(
    NotificationPreferences preferences,
  ) {
    final bool verificationOn = preferences.isEnabled(
      NotificationCategory.verificationUpdate,
    );
    final Map<String, ChannelPreference> byType = <String, ChannelPreference>{
      for (final ChannelPreference channel in preferences.channels)
        channel.type: channel,
    };
    return <Map<String, Object?>>[
      for (final String type in preferenceTypes)
        <String, Object?>{
          'type': type,
          'in_app': _sent(type, byType[type], verificationOn).inApp,
          'push': _sent(type, byType[type], verificationOn).push,
        },
    ];
  }

  /// `verification_decided` still follows the older category switch.
  /// The other three types are the row itself, defaulting to on.
  static ChannelPreference _sent(
    String type,
    ChannelPreference? existing,
    bool verificationOn,
  ) {
    if (type == 'verification_decided') {
      final bool inApp = existing == null
          ? verificationOn
          : verificationOn && existing.inApp;
      final bool push = existing == null
          ? verificationOn
          : verificationOn && existing.push;
      return ChannelPreference(type: type, inApp: inApp, push: push);
    }
    return existing ?? ChannelPreference(type: type, inApp: true, push: true);
  }

  /// `GET notifications/unread-count`.
  Future<Result<int>> unreadCount() async {
    final response = await _apiClient.send<int>(
      method: HttpMethod.get,
      path: unreadCountPath,
      authenticated: true,
      decode: (Object? data) {
        if (data is int) return data;
        if (data is Map<String, dynamic>) {
          final Object? count = data['count'] ?? data['unread'];
          if (count is int) return count;
        }
        return 0;
      },
    );
    return response.map((envelope) => envelope.data);
  }

  static ResidentNotification? _decode(Object? entry) {
    if (entry is! Map<String, dynamic>) return null;
    final Object? id = entry['id'];
    final Object? title = entry['title'];
    if (id is! String || id.isEmpty || title is! String) return null;

    final Object? rawType = entry['type'] ?? entry['category'];
    // `verification_decided` is the resident category for a decision.
    // `message_received` stays itself. It is not relabelled to account security.
    final String? categoryWire = switch (rawType) {
      'verification_decided' => 'verification_update',
      final String value => value,
      _ => null,
    };
    final Object? subjectType = entry['subject_type'];
    final String? explicitType = subjectType is String && subjectType.isNotEmpty
        ? subjectType
        : null;
    // `subject_type` is not on the schema. When it is absent, the notification
    // type is the only routing hint the payload carries.
    final String? derivedType =
        explicitType ??
        (rawType is String && rawType.isNotEmpty ? rawType : null);
    final Object? subjectId = entry['subject_id'];
    final String? targetId = subjectId is String && subjectId.isNotEmpty
        ? subjectId
        : null;
    final String? place = _placeTarget(derivedType);

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
        categoryWire,
        NotificationCategory.values,
        (NotificationCategory c) => c.wireValue,
      ),
      // Routing only. Anything else the server adds is dropped here rather
      // than carried into a target map that a screen might one day read.
      // A place takes no id, and `DeepLink` refuses one on it, so the
      // record's id stays off a place's target.
      target: <String, String>{
        'type': ?derivedType,
        if (place == null) 'id': ?targetId,
        DeepLink.targetKey: ?(place ?? _deepLinkTarget(derivedType, targetId)),
      },
    );
  }

  /// The `DeepLink` target of a notification type that opens a *place*
  /// rather than one record.
  ///
  /// `sector_application_decided` names the application in `subject_id`, but
  /// the one page that shows applications, Sectors and benefits (`/sectors`),
  /// lists them all and takes no id. The notice opens it, and the page reads
  /// the decision and any reason from `GET /me/sector-applications`, never
  /// from the notice (D-216).
  static String? _placeTarget(String? type) => switch (type) {
    'sector_application_decided' => 'sector_applications',
    _ => null,
  };

  /// The `DeepLink` target a notification type opens, when this build knows
  /// one and the payload names the record.
  ///
  /// `issuance_request_updated` carries the request's id in `subject_id`, and
  /// tapping it opens that request; the screen fetches the detail itself under
  /// the live session. `event_registration_updated` carries the event's id —
  /// the office called it off or moved the resident's place — and opens the
  /// event, which shows where they stand now (D-191). Types not listed here
  /// keep their row and open nothing.
  static String? _deepLinkTarget(String? type, String? subjectId) {
    if (subjectId == null) return null;
    return switch (type) {
      'issuance_request_updated' => 'issuance_request',
      'event_registration_updated' => 'event',
      _ => null,
    };
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
      nextCursor: pagination.nextCursor,
    );
  }
}
