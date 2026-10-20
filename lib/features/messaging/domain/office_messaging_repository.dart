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
    this.sample = true,
  });

  final String id;
  final String officeId;
  final String officeName;
  final String topic;
  final String preview;
  final DateTime updatedAt;

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
  });

  final String id;
  final String threadId;
  final String body;
  final DateTime sentAt;
  final bool fromResident;

  @override
  String toString() => 'OfficeMessage($id)';
}

/// Messages a verified resident sends to a municipal office.
///
/// Decision D7: the pinned backend has no messaging module. The live
/// implementation declines. The mock exists only in a dev build. This contract
/// does not grant permission to message; the server will, when it exists.
abstract interface class OfficeMessagingRepository {
  Future<Result<List<OfficeThread>>> listThreads();

  Future<Result<OfficeThread>> loadThread(String threadId);

  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
  });
}
