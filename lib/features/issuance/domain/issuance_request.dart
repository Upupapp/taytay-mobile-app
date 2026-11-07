import 'package:flutter/foundation.dart';

import '../../../core/documents/upload_policy.dart';
import 'issuance_status.dart';
import 'issuance_type.dart';

/// One row of "My document requests".
///
/// The server sends no purpose and no history on a list row, and neither is
/// modelled here: what a resident wrote is read only on the detail screen.
@immutable
class IssuanceRequestSummary {
  const IssuanceRequestSummary({
    required this.id,
    required this.referenceNumber,
    required this.status,
    required this.typeName,
    required this.officeName,
    this.typeId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// `DR-<year>-<six digits>`, issued by the server when the request is filed.
  final String referenceNumber;

  /// `null` when the server sent a status this build does not know.
  final IssuanceStatus? status;
  final String typeName;
  final String officeName;

  /// The document type it was filed for. A resubmission reads the type's
  /// `accepts` block only when the request carries none of its own (a server
  /// older than backend `0d1cb14`). `null` when the server did not say.
  final String? typeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  String toString() => 'IssuanceRequestSummary($id, ${status?.name})';
}

/// One file the resident sent. A resubmission adds a version beside the one
/// before; nothing the resident sent is ever replaced.
@immutable
class IssuanceAttachment {
  const IssuanceAttachment({
    required this.id,
    required this.requirementCode,
    required this.version,
    required this.mimeType,
    required this.byteSize,
    required this.current,
    this.createdAt,
  });

  final String id;
  final String requirementCode;
  final int version;
  final String mimeType;
  final int byteSize;

  /// The newest version for its requirement.
  final bool current;
  final DateTime? createdAt;

  bool get isImage => mimeType == 'image/jpeg' || mimeType == 'image/png';
}

/// One move in the request's history.
@immutable
class IssuanceHistoryEntry {
  const IssuanceHistoryEntry({
    required this.from,
    required this.to,
    required this.by,
    this.message,
    this.claimDetails,
    this.at,
  });

  final IssuanceStatus? from;
  final IssuanceStatus? to;
  final IssuanceActor by;

  /// The words that came with the move: the office's reason, or the
  /// resident's own note. Shown as written.
  final String? message;
  final String? claimDetails;
  final DateTime? at;
}

/// The resident's own request, as `GET me/issuance-requests/{id}` sends it.
@immutable
class IssuanceRequestDetail {
  const IssuanceRequestDetail({
    required this.summary,
    required this.purpose,
    required this.requirements,
    required this.attachments,
    required this.history,
    required this.canCancel,
    required this.canResubmit,
    this.feeCentavos,
    this.processingDays,
    this.claimInstructions,
    this.claimDetails,
    this.needsInfoMessage,
    this.uploadPolicy = UploadPolicy.fallback,
  });

  final IssuanceRequestSummary summary;

  /// The resident's own words. Personal: never logged, never in [toString].
  final String purpose;
  final List<IssuanceRequirement> requirements;
  final List<IssuanceAttachment> attachments;
  final List<IssuanceHistoryEntry> history;

  /// The server's answer to "may I cancel this now". Never derived here.
  final bool canCancel;

  /// The server's answer to "may I send more now". Never derived here.
  final bool canResubmit;
  final int? feeCentavos;
  final int? processingDays;
  final String? claimInstructions;

  /// When and where to claim, set by the office when the document is ready.
  final String? claimDetails;

  /// What the office asked for, while the request needs more information.
  final String? needsInfoMessage;

  /// The request's own `accepts` block: what a file sent with it, on a
  /// resubmission too, is checked against. The server's limits, so it is
  /// there after the type is retired. [UploadPolicy.fallback] when a server
  /// older than backend `0d1cb14` sent none.
  final UploadPolicy uploadPolicy;

  String get id => summary.id;
  IssuanceStatus? get status => summary.status;

  /// The office's reason for not issuing, from the move that refused it.
  String? get refusalReason {
    for (final IssuanceHistoryEntry entry in history.reversed) {
      if (entry.to == IssuanceStatus.rejected &&
          entry.by != IssuanceActor.resident) {
        return entry.message;
      }
    }
    return null;
  }

  /// The label of the requirement a file was sent for, or `null` when the
  /// type no longer lists it.
  String? requirementLabel(String code) {
    for (final IssuanceRequirement requirement in requirements) {
      if (requirement.code == code) return requirement.label;
    }
    return null;
  }

  @override
  String toString() => 'IssuanceRequestDetail(${summary.id}, ${status?.name})';
}
