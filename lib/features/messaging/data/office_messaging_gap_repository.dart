import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../domain/office_messaging_repository.dart';

/// Resident threads on the Taytay LGU IDS API.
///
/// `GET/POST /threads`, the message list and reply, mark-read, and close.
/// A thread carries `subject`, `last_message_preview`, `last_message_at`
/// and `unread_count`. Starting one and replying both return
/// `{thread, message}`. Pages use `limit` and `cursor`. An attachment is
/// `media_id` or multipart `file`, not both.
///
/// **A retried send posts once** (backend `a7a1884`). Starting a thread and
/// replying carry the caller's key as `idempotency_key` in the body — a
/// multipart field when a file goes with it — because that is where the Node
/// API reads it. A repeat with the same key and content answers `201` or `200`
/// with the first message and notifies nobody again. The key also goes to
/// [ApiClient] as the `Idempotency-Key` header, which the server ignores and
/// the transport reads to know an automatic retry is safe (`RetryPolicy`).
class OfficeMessagingApiRepository implements OfficeMessagingRepository {
  const OfficeMessagingApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<Paginated<OfficeThread>>> listThreads({
    int page = 1,
    int? perPage,
    String? cursor,
  }) async {
    assert(page >= 1);
    final response = await _apiClient.send<List<OfficeThread>>(
      method: HttpMethod.get,
      path: 'threads',
      authenticated: true,
      query: _pageQuery(perPage, cursor),
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodeThread)
                .whereType<OfficeThread>()
                .toList(growable: false)
          : const <OfficeThread>[],
    );
    if (response case Err<ApiEnvelope<List<OfficeThread>>>(:final failure)) {
      return Err<Paginated<OfficeThread>>(failure);
    }
    final ApiEnvelope<List<OfficeThread>> envelope =
        (response as Ok<ApiEnvelope<List<OfficeThread>>>).value;
    final Map<String, String> labels = await _officeLabels();
    return Ok<Paginated<OfficeThread>>(
      _page<OfficeThread>(envelope, _named(envelope.data, labels)),
    );
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
  Future<Result<Paginated<OfficeMessage>>> listMessages(
    String threadId, {
    int page = 1,
    int? perPage,
    String? cursor,
  }) async {
    assert(page >= 1);
    final response = await _apiClient.send<List<OfficeMessage>>(
      method: HttpMethod.get,
      path: 'threads/$threadId/messages',
      authenticated: true,
      query: _pageQuery(perPage, cursor),
      decode: (Object? data) => data is List<dynamic>
          ? data
                .map(_decodeMessage)
                .whereType<OfficeMessage>()
                .toList(growable: false)
          : const <OfficeMessage>[],
    );
    return response.map(
      (ApiEnvelope<List<OfficeMessage>> envelope) =>
          _page<OfficeMessage>(envelope, envelope.data),
    );
  }

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async {
    final Result<MultipartFile>? upload = _upload(file);
    if (upload is Err<MultipartFile>) {
      return Err<OfficeMessage>(upload.failure);
    }
    final MultipartFile? part = upload?.valueOrNull;
    final response = await _apiClient.send<OfficeMessage?>(
      method: HttpMethod.post,
      path: 'threads',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'office_id': officeId,
        'subject': topic,
        'body': body,
        'media_id': ?_mediaId(mediaId, file: part != null),
        'idempotency_key': idempotencyKey,
      },
      file: part,
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
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async {
    final Result<MultipartFile>? upload = _upload(file);
    if (upload is Err<MultipartFile>) {
      return Err<OfficeMessage>(upload.failure);
    }
    final MultipartFile? part = upload?.valueOrNull;
    final response = await _apiClient.send<OfficeMessage?>(
      method: HttpMethod.post,
      path: 'threads/$threadId/messages',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'body': body,
        'media_id': ?_mediaId(mediaId, file: part != null),
        'idempotency_key': idempotencyKey,
      },
      file: part,
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

  /// `limit` from the channel page size, capped at this route's maximum of 50.
  Map<String, String> _pageQuery(int? perPage, String? cursor) {
    final String? next = cursor != null && cursor.isNotEmpty ? cursor : null;
    final int asked = _apiClient.pages.clampRequest(
      perPage ?? _apiClient.pages.defaultPerPage,
    );
    final int limit = asked > 50 ? 50 : asked;
    return <String, String>{'limit': '$limit', 'cursor': ?next};
  }

  static Paginated<T> _page<T>(ApiEnvelope<List<T>> envelope, List<T> items) {
    final PageMeta? pagination = envelope.pagination;
    if (pagination == null) return Paginated<T>.single(items);
    return Paginated<T>(
      items: items,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
      nextCursor: pagination.nextCursor,
    );
  }

  /// A file takes the multipart path. `media_id` stays off that body.
  static String? _mediaId(String? mediaId, {required bool file}) {
    if (file) return null;
    final String trimmed = mediaId?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Refuses an attachment before any request. The ceiling and the types are
  /// [UploadPolicy.fallback]: 8 MB, JPEG, PNG, or PDF, and the bytes must match.
  static Result<MultipartFile>? _upload(OutgoingFile? file) {
    if (file == null) return null;
    const UploadPolicy policy = UploadPolicy.fallback;
    final DocumentRejection? rejection = DocumentCapturePolicy.inspect(
      CapturedDocument(
        bytes: file.bytes,
        fileName: file.fileName,
        mimeType: file.mimeType.trim(),
        source: DocumentSource.file,
      ),
      policy,
    );
    if (rejection != null) {
      return const Err<MultipartFile>(
        ValidationFailure(debugMessage: 'The attachment was not sent.'),
      );
    }
    final String name = file.fileName.trim();
    return Ok<MultipartFile>(
      MultipartFile(
        field: 'file',
        filename: name.isEmpty ? 'upload' : name,
        bytes: file.bytes,
        mimeType: file.mimeType.trim(),
      ),
    );
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
      ownerAccountId: raw['resident_id'] is String
          ? raw['resident_id'] as String
          : '',
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
      attachments: message?.attachments ?? const <MessageAttachment>[],
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
      attachments: _attachments(raw['attachments']),
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

  static List<MessageAttachment> _attachments(Object? raw) {
    if (raw is! List) return const <MessageAttachment>[];
    final List<MessageAttachment> attachments = <MessageAttachment>[];
    for (final Object? item in raw) {
      if (item is! Map) continue;
      final Object? mediaId = item['media_id'];
      if (mediaId is String && mediaId.isNotEmpty) {
        attachments.add(MessageAttachment(mediaId: mediaId));
      }
    }
    return List<MessageAttachment>.unmodifiable(attachments);
  }
}
