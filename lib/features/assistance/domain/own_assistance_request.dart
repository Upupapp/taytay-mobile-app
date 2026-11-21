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

  /// Returned, and she has sent from this app every document the office
  /// named: the office now has them to review (A10). Said only while the
  /// request has not moved since she sent them.
  documentsSent,
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

/// How a request reached the office (`channel`, backend `6794f8d`, D-226):
/// sent from this app, filed at the office by any of its own channels, or
/// imported from the office's old paper records (D-227). Null on a row that
/// does not say, which is not shown as any of them.
enum AssistanceChannel {
  /// Sent from this app.
  online,

  /// Filed at the office, by any of its channels.
  office,

  /// Imported from the office's old paper records (D-227).
  imported,
}

/// Whether a document a returned request still needs was never sent, or was
/// sent and must be sent again (`missing_documents[].state`, D-226). A state
/// this build does not know is [other], and is said without a reason.
enum MissingDocumentState {
  /// Never sent.
  notSent,

  /// Sent, and the office needs it again.
  sendAgain,

  /// A state this build does not know.
  other,
}

/// One document the office still needs for a returned request, in the
/// office's words for the resident (`missing_documents`, D-226). Never the
/// office's remarks on it: the API sends none.
@immutable
class MissingDocument {
  const MissingDocument({
    required this.code,
    required this.name,
    required this.state,
    this.instruction,
  });

  /// The multipart field its file is sent under.
  final String code;
  final String name;
  final MissingDocumentState state;

  /// What to send, as the office wrote it for residents. Null when empty.
  final String? instruction;

  @override
  String toString() => 'MissingDocument($code, ${state.name})';
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
    this.channel,
    this.sourceReference,
    this.missingDocuments = const <MissingDocument>[],
    this.documentsSent = false,
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

  /// Sent from this app, filed at the office (D-226), or imported from the
  /// office's old paper records (D-227).
  final AssistanceChannel? channel;

  /// For a request imported from the office's old paper records, the control
  /// or voucher number printed on them (`source_reference`, D-227): the number
  /// she holds in her hand. [referenceNumber] stays this system's own. Null
  /// for a request filed in this system.
  final String? sourceReference;

  /// For a returned request only: what she has not sent, or must send again.
  /// Empty otherwise, and empty when the office named nothing.
  final List<MissingDocument> missingDocuments;

  /// She sent, from this app, every document the office named while the
  /// request stood returned, and it has not moved since (A10). The API says
  /// only what is still missing, so an empty list alone cannot tell "sent"
  /// from "the office named nothing"; the data layer sets this from its own
  /// send, for as long as the app runs, and never stores it.
  final bool documentsSent;

  /// This request, marked as one whose documents she has sent.
  OwnAssistanceRequest withDocumentsSent() => OwnAssistanceRequest(
    id: id,
    referenceNumber: referenceNumber,
    programName: programName,
    filedAt: filedAt,
    status: status,
    statusChangedAt: statusChangedAt,
    approvedAmountCentavos: approvedAmountCentavos,
    payoutScheduledFor: payoutScheduledFor,
    payoutVenue: payoutVenue,
    releasedAt: releasedAt,
    channel: channel,
    sourceReference: sourceReference,
    missingDocuments: missingDocuments,
    documentsSent: true,
  );

  /// She can send documents from the app: the office has returned it and
  /// named what is missing. The server decides; this only offers the button.
  bool get takesDocuments =>
      status.known == AssistanceRequestStatus.returned &&
      missingDocuments.isNotEmpty;

  /// Where it stands in her terms. A returned request whose documents she
  /// has all sent is waiting for the office, not for her (A10).
  AssistanceStage get stage =>
      status.known == AssistanceRequestStatus.returned &&
          missingDocuments.isEmpty &&
          documentsSent
      ? AssistanceStage.documentsSent
      : AssistanceStage.of(status.known);

  /// Redacted: a control number and a venue are about a person.
  @override
  String toString() => 'OwnAssistanceRequest(${stage.name})';
}
