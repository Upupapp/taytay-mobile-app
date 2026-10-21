import 'package:flutter/foundation.dart';

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
    this.sample = true,
  });

  final String id;
  final String officeId;
  final String officeName;
  final String topic;
  final String preview;
  final DateTime updatedAt;
  final String officeSlug;
  final String status;
  final bool unread;

  /// True while the fact is a fixture, not an LGU record.
  final bool sample;

  @override
  String toString() => 'OfficeThread($id, $officeId)';
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
  });

  final String id;
  final String threadId;
  final String body;
  final DateTime sentAt;
  final bool fromResident;
  final String senderId;

  @override
  String toString() => 'OfficeMessage($id)';
}

/// Messages a verified resident sends to a municipal office.
///
/// Threads are `GET/POST /threads` on the Taytay LGU IDS API. F31 is closed.
/// A thread has no topic and no preview; those stay on the model for the
/// screens that already show them, filled from the office slug and the latest
/// message when the server sent neither.
abstract interface class OfficeMessagingRepository {
  Future<Result<List<OfficeThread>>> listThreads();

  Future<Result<OfficeThread>> loadThread(String threadId);

  Future<Result<List<OfficeMessage>>> listMessages(String threadId);

  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
  });

  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
  });

  Future<Result<void>> closeThread(String threadId);

  Future<Result<void>> markThreadRead(String threadId);
}
