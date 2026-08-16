import 'package:flutter/foundation.dart';

import 'lgu_service.dart' show ServerValue;
import 'service_request_repository.dart';

/// Which part of the resident's record is being asked for.
///
/// **Two views of one set of records, not two sets.** A resident looking for
/// "the assistance I got last year" and a resident checking "is my application
/// moving" are the same person asking about the same table, and splitting them
/// into two screens means two places to look for one thing. The scope is a
/// filter on one list.
enum HistoryScope {
  /// Anything still moving.
  open,

  /// Anything finished — completed, released, rejected or cancelled.
  past;

  bool get isPast => this == HistoryScope.past;
}

/// Where the LGU sent a case it does not handle itself.
///
/// ---
///
/// **Every field here is shown only when the backend intended it for the
/// resident.** A referral has an internal side — which desk moved it, why, what
/// the receiving office was told about the household — and none of that has a
/// field on this class. What a resident needs is where to go, what for, and how
/// to reach them.
@immutable
class ReferralDetail {
  const ReferralDetail({
    required this.destination,
    this.serviceRequested,
    this.instructions,
    this.status,
    this.contact,
  });

  /// The office or organisation the case went to.
  final String destination;

  final String? serviceRequested;

  /// What the resident should do about it.
  final String? instructions;

  /// The referral's own lifecycle, when the office publishes it.
  final ServerValue<ReferralStatus>? status;

  /// A phone number or address **only when it is meant to be given out**. A
  /// caseworker's direct line is not, and there is no field for one.
  final String? contact;

  @override
  String toString() => 'ReferralDetail(${status?.raw ?? 'no status'})';
}

/// How a referral is progressing at the receiving end.
enum ReferralStatus {
  sent('sent'),
  accepted('accepted'),
  declined('declined'),
  completed('completed');

  const ReferralStatus(this.wireValue);

  final String wireValue;
}

/// What a resident is receiving, and how to collect it.
///
/// ---
///
/// **`amount` is a string the server authored, never a number this app
/// formats.** Two reasons. A release may be in kind — "one sack of rice, 25 kg"
/// — which no currency formatter can express. And where it *is* money, the
/// figure a resident sees must be the figure the office approved, character for
/// character: an app that parses a value and re-renders it is one rounding rule
/// away from telling someone they are owed a different amount than the record
/// says.
///
/// **Nothing about funding appears here.** No budget line, no fund source, no
/// disbursement batch, no other beneficiary, no manifest. Those are the
/// accounting internals TAB 18 names explicitly, and this class has nowhere to
/// put them.
@immutable
class ReleaseDetail {
  const ReleaseDetail({
    this.scheduledAt,
    this.location,
    this.amountDescription,
    this.instructions,
    this.acknowledgement,
  });

  final DateTime? scheduledAt;

  /// Where to collect. A public counter, never a staff room.
  final String? location;

  /// The approved, resident-visible value or in-kind description, verbatim.
  final String? amountDescription;

  /// What to bring, and anything else the office wants understood.
  final String? instructions;

  /// Whether the resident has confirmed receipt, when the office tracks it.
  final ServerValue<ReleaseAcknowledgement>? acknowledgement;

  bool get isEmpty =>
      scheduledAt == null &&
      location == null &&
      amountDescription == null &&
      instructions == null;

  @override
  String toString() => 'ReleaseDetail(scheduled: ${scheduledAt != null})';
}

/// Whether the resident has confirmed they received something.
enum ReleaseAcknowledgement {
  notRequired('not_required'),
  awaitingResident('awaiting_resident'),
  acknowledged('acknowledged');

  const ReleaseAcknowledgement(this.wireValue);

  final String wireValue;
}

/// One line in the resident's own record of what they asked for and received.
@immutable
class AssistanceHistoryEntry {
  const AssistanceHistoryEntry({
    required this.requestId,
    required this.serviceCode,
    required this.status,
    this.serviceName,
    this.referenceNumber,
    this.submittedAt,
    this.completedAt,
    this.outcomeSummary,
    this.receiptReference,
  });

  /// Opens the case screen. Opaque, and `/me`-scoped by the endpoint.
  final String requestId;

  final String serviceCode;

  /// The catalogue name when the server sent one. The code is the fallback,
  /// because a code a resident can quote beats a blank.
  final String? serviceName;

  final ServerValue<ServiceRequestState> status;

  /// What a resident quotes at the counter.
  final String? referenceNumber;

  final DateTime? submittedAt;
  final DateTime? completedAt;

  /// The resident-visible summary of what was provided, when the office
  /// publishes one. Never composed by the app from a status.
  final String? outcomeSummary;

  /// A reference for the office's own receipt, **when the backend provides
  /// one**.
  ///
  /// Deliberately a reference rather than a file. The contract publishes no
  /// document endpoint, and a "download" that fetches nothing is worse than an
  /// absent button — it teaches a resident that the receipt is theirs to hold
  /// when the office's copy is still the authoritative one. When a document
  /// endpoint exists, this becomes the id it is fetched by.
  final String? receiptReference;

  bool get isFinished => status.known?.isTerminal ?? false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssistanceHistoryEntry && other.requestId == requestId);

  @override
  int get hashCode => requestId.hashCode;

  /// Redacted of the outcome: what a person received is a fact about their
  /// circumstances.
  @override
  String toString() => 'AssistanceHistoryEntry($serviceCode, ${status.raw})';
}
