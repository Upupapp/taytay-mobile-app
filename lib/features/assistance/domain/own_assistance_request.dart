import 'package:flutter/foundation.dart' show immutable;

import '../../../core/api/server_value.dart';

/// The status of one of the resident's own assistance requests, as the API
/// sends it (`GET /me/assistance-requests`, backend `d1e997c`, D-223).
///
/// The raw office vocabulary. The resident never reads these words: the app
/// says each one through [AssistanceStage]. `draft` is never sent to a
/// resident, so it is not here, and a value this build does not know is held
/// as an unrecognised [ServerValue] rather than refused.
enum AssistanceRequestStatus {
  submitted('submitted'),
  intakeReview('intake-review'),
  returned('returned'),
  assessment('assessment'),
  endorsed('endorsed'),
  approved('approved'),
  rejected('rejected'),
  scheduled('scheduled'),
  released('released'),
  completed('completed'),
  cancelled('cancelled'),
  expired('expired');

  const AssistanceRequestStatus(this.wireValue);

  final String wireValue;
}

/// Where a request stands, in the resident's terms (D-223).
///
/// Fewer than the office's statuses on purpose. Which desk holds a file
/// (intake review, assessment, endorsement) is the office's working detail;
/// what a family needs is whether it was received, is being looked at, was
/// decided, and when to come. [updated] is a status this build does not know:
/// a released app meets values added after it shipped, and the honest reading
/// is that something changed, never a guess at what.
enum AssistanceStage {
  received,
  beingAssessed,
  approved,
  payoutScheduled,
  released,
  needsMore,
  notApproved,
  cancelled,
  expired,
  updated;

  /// The stage a raw status is said as. `null` (unknown) is [updated].
  static AssistanceStage of(AssistanceRequestStatus? status) =>
      switch (status) {
        AssistanceRequestStatus.submitted ||
        AssistanceRequestStatus.intakeReview => received,
        AssistanceRequestStatus.assessment ||
        AssistanceRequestStatus.endorsed => beingAssessed,
        AssistanceRequestStatus.approved => approved,
        AssistanceRequestStatus.scheduled => payoutScheduled,
        AssistanceRequestStatus.released ||
        AssistanceRequestStatus.completed => released,
        AssistanceRequestStatus.returned => needsMore,
        AssistanceRequestStatus.rejected => notApproved,
        AssistanceRequestStatus.cancelled => cancelled,
        AssistanceRequestStatus.expired => expired,
        null => updated,
      };
}

/// One of the resident's own filed assistance requests (D-223, ADR 0003 C).
///
/// **The minimum that says where it stands, and nothing of the office's
/// record.** The API sends no staff name, note, assessment, reason, requested
/// amount or case, and this type has nowhere to put one. Each optional field
/// is null outside the status that gives it meaning, and the server decides
/// that: the app shows what it is sent.
@immutable
class OwnAssistanceRequest {
  const OwnAssistanceRequest({
    required this.id,
    required this.referenceNumber,
    required this.programName,
    required this.filedAt,
    required this.status,
    required this.statusChangedAt,
    this.approvedAmountCentavos,
    this.payoutScheduledFor,
    this.payoutVenue,
    this.releasedAt,
  });

  /// Opaque. Matches the `subject_id` of an `assistance_request_updated`
  /// notice.
  final String id;

  /// The control number issued at filing. What a resident quotes at the
  /// counter.
  final String referenceNumber;

  /// The programme it was filed under; null when the API names none.
  final String? programName;

  final DateTime? filedAt;
  final ServerValue<AssistanceRequestStatus> status;
  final DateTime? statusChangedAt;

  /// Integer centavos, once approved; null before, and for goods. Never a
  /// double: formatted with integer division only.
  final int? approvedAmountCentavos;

  /// The payout's calendar day, while the payout is scheduled (UTC midnight
  /// of that day, so Manila time shows the same date).
  final DateTime? payoutScheduledFor;

  /// Where to collect, while the payout is scheduled.
  final String? payoutVenue;

  /// When it was handed over, once released.
  final DateTime? releasedAt;

  AssistanceStage get stage => AssistanceStage.of(status.known);

  /// Redacted: a control number and a venue are about a person.
  @override
  String toString() => 'OwnAssistanceRequest(${stage.name})';
}
