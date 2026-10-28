import 'package:flutter/foundation.dart';

import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';

/// A thread between a verified resident and one municipal office.
///
/// Public office names only. The body is the resident's own words, fetched by
/// the screen that shows them and not stored on the session.
@immutable
class OfficeThread {
  const OfficeThread({
    required this.id,
    required this.officeId,
    required this.officeName,
    required this.topic,
    required this.preview,
    required this.updatedAt,
    this.officeSlug = '',
    this.status = 'open',
    this.unread = false,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.createdAt,
    this.sample = true,
  });

  final String id;
  final String officeId;
  final String officeName;

  /// The thread `subject`. The screens already call this the topic.
  final String topic;

  /// `last_message_preview`.
  final String preview;
  final DateTime updatedAt;
  final String officeSlug;
  final String status;
  final bool unread;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  /// True while the fact is a fixture, not an LGU record.
  final bool sample;

  /// Same thread, with the office label from `GET /offices`.
  OfficeThread withOfficeName(String officeName) => OfficeThread(
    id: id,
    officeId: officeId,
    officeName: officeName,
    topic: topic,
    preview: preview,
    updatedAt: updatedAt,
    officeSlug: officeSlug,
    status: status,
    unread: unread,
    unreadCount: unreadCount,
    lastMessageAt: lastMessageAt,
    createdAt: createdAt,
    sample: sample,
  );

  @override
  String toString() => 'OfficeThread($id, $officeId)';
}

/// One file already stored, named only by the id the resident can read.
@immutable
class MessageAttachment {
  const MessageAttachment({required this.mediaId});

  /// `attachments[].media_id`. Not a URL and not the bytes.
  final String mediaId;

  @override
  String toString() => 'MessageAttachment';
}

/// A new upload for `multipart` field `file`.
///
/// The bytes live only for the request. [toString] keeps the name out: a
/// chosen filename often contains a person's name.
@immutable
class OutgoingFile {
  const OutgoingFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  @override
  String toString() => 'OutgoingFile($mimeType, ${bytes.length} bytes)';
}

/// One message in a thread. [fromResident] distinguishes the two sides without
/// naming a staff account.
@immutable
class OfficeMessage {
  const OfficeMessage({
    required this.id,
    required this.threadId,
    required this.body,
    required this.sentAt,
    required this.fromResident,
    this.senderId = '',
    this.attachments = const <MessageAttachment>[],
  });

  final String id;
  final String threadId;
  final String body;
  final DateTime sentAt;
  final bool fromResident;
  final String senderId;
  final List<MessageAttachment> attachments;

  /// The same message, marked as the resident's own after they sent it.
  ///
  /// The wire does not say which side sent a row. A reply this app just
  /// posted is the resident's.
  OfficeMessage asFromResident() => OfficeMessage(
    id: id,
    threadId: threadId,
    body: body,
    sentAt: sentAt,
    fromResident: true,
    senderId: senderId,
    attachments: attachments,
  );

  @override
  String toString() => 'OfficeMessage($id)';
}

/// Messages a verified resident sends to a municipal office.
///
/// Threads are `GET/POST /threads` on the Taytay LGU IDS API. A thread carries
/// `subject`, `last_message_preview`, `last_message_at` and `unread_count`.
/// `resident_id` comes back and is not stored. [OfficeThread.topic] is that
/// subject. Starting a thread and replying both return `{thread, message}`.
///
/// An attachment is either `media_id` for media the resident can already read,
/// or multipart field `file`. The two are not sent together.
/// Lists page with `limit` and `cursor`.
abstract interface class OfficeMessagingRepository {
  Future<Result<Paginated<OfficeThread>>> listThreads({
    int page = 1,
    int? perPage,
    String? cursor,
  });

  Future<Result<OfficeThread>> loadThread(String threadId);

  Future<Result<Paginated<OfficeMessage>>> listMessages(
    String threadId, {
    int page = 1,
    int? perPage,
    String? cursor,
  });

  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
    String? mediaId,
    OutgoingFile? file,
  });

  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
    String? mediaId,
    OutgoingFile? file,
  });

  Future<Result<void>> closeThread(String threadId);

  Future<Result<void>> markThreadRead(String threadId);
}
