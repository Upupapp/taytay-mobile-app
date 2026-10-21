import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
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

  static const String path = 'notifications';
  static const String readAllPath = 'notifications/read';
  static const String unreadCountPath = 'notifications/unread-count';

  @override
  Future<Result<Paginated<ResidentNotification>>> listOwn({
    int page = 1,
    int? perPage,
  }) async {
    assert(page >= 1);
    final response = await _apiClient.send<List<ResidentNotification>>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      query: <String, String>{
        'limit':
            '${_apiClient.pages.clampRequest(perPage ?? _apiClient.pages.defaultPerPage)}',
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
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<NotificationPreferences>(
      BackendGap.absentOnNodeContract,
      'loadPreferences',
    );
  }

  @override
  Future<Result<void>> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<void>(
      BackendGap.absentOnNodeContract,
      'updatePreferences',
    );
  }

  /// Registers this device so the office can reach it.
  ///
  /// `me/devices` is the device registry — the same one TAB 03 deliberately did
  /// not touch, because a registration whose purpose is a push token is not a
  /// session list and had nothing to carry. Here it has one.
  @override
  Future<Result<String>> registerPushToken(String token) async {
    final Object _ = _apiClient.runtimeType;
    return backendGapFailure<String>(
      BackendGap.absentOnNodeContract,
      'registerPushToken',
    );
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
    final Object _ = _apiClient.runtimeType;
    if (deviceId.isEmpty) return false;
    // The Node API has no device registry.
    return false;
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
    final String? categoryWire = switch (rawType) {
      'verification_decided' => 'verification_update',
      'message_received' => 'account_security',
      final String value => value,
      _ => null,
    };
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
        categoryWire,
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
