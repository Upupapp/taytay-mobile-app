import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/office_messaging_repository.dart';

/// Resident threads on the Taytay LGU IDS API.
///
/// F31 is closed: `GET/POST /threads` and the message routes are in the
/// contract. A thread carries `subject`, `last_message_preview`,
/// `last_message_at` and `unread_count`. Starting one and replying both
/// return `{thread, message}`.
class OfficeMessagingApiRepository implements OfficeMessagingRepository {
  const OfficeMessagingApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<List<OfficeThread>>> listThreads() async {
    final response = await _apiClient.send<List<OfficeThread>>(
      method: HttpMethod.get,
      path: 'threads',
      authenticated: true,
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodeThread)
                .whereType<OfficeThread>()
                .toList(growable: false)
          : const <OfficeThread>[],
    );
    if (response case Err<ApiEnvelope<List<OfficeThread>>>(:final failure)) {
      return Err<List<OfficeThread>>(failure);
    }
    final List<OfficeThread> threads =
        (response as Ok<ApiEnvelope<List<OfficeThread>>>).value.data;
    final Map<String, String> labels = await _officeLabels();
    return Ok<List<OfficeThread>>(_named(threads, labels));
  }

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) async {
    final response = await _apiClient.send<OfficeThread?>(
      method: HttpMethod.get,
      path: 'threads/$threadId',
      authenticated: true,
      decode: _decodeThread,
    );
    if (response case Err<ApiEnvelope<OfficeThread?>>(:final failure)) {
      return Err<OfficeThread>(failure);
    }
    final OfficeThread? thread =
        (response as Ok<ApiEnvelope<OfficeThread?>>).value.data;
    if (thread == null) {
      return const Err<OfficeThread>(
        NotFoundFailure(debugMessage: 'No thread in the body.'),
      );
    }
    final Map<String, String> labels = await _officeLabels();
    return Ok<OfficeThread>(_named(<OfficeThread>[thread], labels).single);
  }

  @override
  Future<Result<List<OfficeMessage>>> listMessages(String threadId) async {
    final response = await _apiClient.send<List<OfficeMessage>>(
      method: HttpMethod.get,
      path: 'threads/$threadId/messages',
      authenticated: true,
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodeMessage)
                .whereType<OfficeMessage>()
                .toList(growable: false)
          : const <OfficeMessage>[],
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
  }) async {
    final response = await _apiClient.send<OfficeMessage?>(
      method: HttpMethod.post,
      path: 'threads',
      authenticated: true,
      body: <String, Object?>{
        'office_id': officeId,
        'subject': topic,
        'body': body,
      },
      decode: (Object? data) => _decodeEnvelope(data, fallbackBody: body),
    );
    return response.flatMap(
      (envelope) => envelope.data == null
          ? const Err<OfficeMessage>(
              ContractFailure(
                debugMessage: 'Starting a thread returned no row.',
              ),
            )
          : Ok<OfficeMessage>(envelope.data!),
    );
  }

  @override
  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
  }) async {
    final response = await _apiClient.send<OfficeMessage?>(
      method: HttpMethod.post,
      path: 'threads/$threadId/messages',
      authenticated: true,
      body: <String, Object?>{'body': body},
      decode: (Object? data) => _decodeEnvelope(data, fallbackBody: body),
    );
    return response.flatMap(
      (envelope) => envelope.data == null
          ? const Err<OfficeMessage>(
              ContractFailure(debugMessage: 'Reply returned no message.'),
            )
          : Ok<OfficeMessage>(envelope.data!),
    );
  }

  @override
  Future<Result<void>> closeThread(String threadId) async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'threads/$threadId/close',
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  @override
  Future<Result<void>> markThreadRead(String threadId) async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'threads/$threadId/read',
      authenticated: true,
      decode: (_) {},
    );
    return response.map((_) {});
  }

  /// `short_name`, then `name`. A failed read leaves the slug in place.
  Future<Map<String, String>> _officeLabels() async {
    final Map<String, String> labels = <String, String>{};
    String? cursor;
    for (var page = 0; page < 5; page++) {
      final Result<ApiEnvelope<Map<String, String>>> response = await _apiClient
          .send<Map<String, String>>(
            method: HttpMethod.get,
            path: 'offices',
            authenticated: false,
            query: <String, String>{'limit': '50', 'cursor': ?cursor},
            decode: _decodeOfficeLabels,
          );
      switch (response) {
        case Err<ApiEnvelope<Map<String, String>>>():
          return labels;
        case Ok<ApiEnvelope<Map<String, String>>>(:final value):
          labels.addAll(value.data);
          final String? next = value.pagination?.nextCursor;
          if (value.pagination?.hasMore != true ||
              next == null ||
              next.isEmpty) {
            return labels;
          }
          cursor = next;
      }
    }
    return labels;
  }

  static Map<String, String> _decodeOfficeLabels(Object? data) {
    if (data is! List) return const <String, String>{};
    final Map<String, String> labels = <String, String>{};
    for (final Object? item in data) {
      if (item is! Map) continue;
      final Object? slug = item['slug'];
      final Object? id = item['id'];
      final String? label = _officeLabel(item['short_name'], item['name']);
      if (label == null) continue;
      if (slug is String && slug.isNotEmpty) labels[slug] = label;
      if (id is String && id.isNotEmpty) labels[id] = label;
    }
    return labels;
  }

  /// `short_name` when it is a non-empty string, otherwise `name`.
  static String? _officeLabel(Object? shortName, Object? name) {
    if (shortName is String && shortName.trim().isNotEmpty) {
      return shortName.trim();
    }
    if (name is String && name.trim().isNotEmpty) return name.trim();
    return null;
  }

  static List<OfficeThread> _named(
    List<OfficeThread> threads,
    Map<String, String> labels,
  ) {
    return <OfficeThread>[
      for (final OfficeThread thread in threads)
        if (labels[thread.officeSlug] != null)
          thread.withOfficeName(labels[thread.officeSlug]!)
        else if (labels[thread.officeId] != null)
          thread.withOfficeName(labels[thread.officeId]!)
        else
          thread,
    ];
  }

  static OfficeThread? _decodeThread(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final Object? id = raw['id'];
    final Object? officeId = raw['office_id'];
    if (id is! String || id.isEmpty || officeId is! String) return null;
    final Object? slug = raw['office_slug'];
    final Object? subject = raw['subject'];
    final Object? preview = raw['last_message_preview'];
    final Object? updated = raw['updated_at'] ?? raw['created_at'];
    final Object? unreadCount = raw['unread_count'];
    return OfficeThread(
      id: id,
      officeId: officeId,
      officeName: slug is String ? slug : '',
      officeSlug: slug is String ? slug : '',
      topic: subject is String ? subject : '',
      preview: preview is String ? preview : '',
      status: raw['status'] is String ? raw['status'] as String : 'open',
      unread: raw['unread'] == true,
      unreadCount: unreadCount is int ? unreadCount : 0,
      lastMessageAt: DateTime.tryParse(
        raw['last_message_at'] is String
            ? raw['last_message_at'] as String
            : '',
      )?.toUtc(),
      createdAt: DateTime.tryParse(
        raw['created_at'] is String ? raw['created_at'] as String : '',
      )?.toUtc(),
      updatedAt:
          DateTime.tryParse(updated is String ? updated : '')?.toUtc() ??
          DateTime.utc(2026, 10, 20, 1, 5),
      sample: false,
    );
  }

  /// `POST /threads` and a reply both return `{thread, message}`.
  static OfficeMessage? _decodeEnvelope(
    Object? raw, {
    required String fallbackBody,
  }) {
    if (raw is! Map<String, dynamic>) return null;
    final OfficeMessage? message = _decodeMessage(raw['message'] ?? raw);
    if (message != null && raw['message'] is Map<String, dynamic>) {
      return message;
    }
    final OfficeThread? thread = _decodeThread(raw['thread']);
    if (message != null && raw['thread_id'] is String) return message;
    if (thread == null) return message;
    return OfficeMessage(
      id: message?.id ?? thread.id,
      threadId: thread.id,
      body: message?.body ?? fallbackBody,
      sentAt: message?.sentAt ?? thread.updatedAt,
      fromResident: true,
    );
  }

  static OfficeMessage? _decodeMessage(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final Object? id = raw['id'];
    final Object? threadId = raw['thread_id'];
    final Object? body = raw['body'];
    if (id is! String || threadId is! String || body is! String) return null;
    final Object? sender = raw['sender_id'];
    return OfficeMessage(
      id: id,
      threadId: threadId,
      body: body,
      senderId: sender is String ? sender : '',
      sentAt:
          DateTime.tryParse(
            raw['created_at'] is String ? raw['created_at'] as String : '',
          )?.toUtc() ??
          DateTime.utc(2026, 10, 20, 1, 5),
      // The server does not say which side sent it. The screen compares
      // sender id with the signed-in account when it has one.
      fromResident: false,
    );
  }
}
