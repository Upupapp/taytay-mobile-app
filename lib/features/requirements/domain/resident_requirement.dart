import 'package:flutter/foundation.dart';

import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart' show ServerValue;

/// Whether an office insists on this document.
///
/// Carried as a [ServerValue] like every other server enum: adding a value is
/// not a breaking change on the backend, so a released build must meet an
/// unknown one without dropping the requirement or guessing what it means.
enum RequirementObligation {
  required('required'),
  optional('optional'),

  /// Needed only in circumstances the office describes in the instruction text.
  conditional('conditional');

  const RequirementObligation(this.wireValue);

  final String wireValue;
}

/// Where one document stands.
///
/// ---
///
/// **`submitted` and `verified` are different states and are never collapsed.**
/// A resident who reads "done" after uploading, and then finds out at the
/// counter that nobody had checked it, has been misled by the app. Acceptance 3
/// of this TAB is precisely that the difference is legible, so the two states
/// have different words, different colours and different next actions.
enum RequirementStatus {
  /// Nothing sent yet.
  missing('missing'),

  /// Received by the LGU. **Not yet checked by anyone.**
  submitted('submitted'),

  /// A person is looking at it now.
  underVerification('under_verification'),

  /// Looked at, and something is wrong with it.
  needsReplacement('needs_replacement'),

  /// Checked and accepted.
  verified('verified'),

  /// Was accepted, and has since aged out.
  expired('expired');

  const RequirementStatus(this.wireValue);

  final String wireValue;
}

/// One document the office is waiting for, or has already seen.
@immutable
class ResidentRequirement {
  const ResidentRequirement({
    required this.code,
    required this.label,
    required this.obligation,
    required this.status,
    this.instruction,
    this.lastSubmittedAt,
    this.reviewerMessage,
  });

  /// Stable server code. The upload is filed against it.
  final String code;

  final String label;

  final ServerValue<RequirementObligation> obligation;
  final ServerValue<RequirementStatus> status;

  /// Plain-language guidance authored by the LGU: what this document is, and
  /// what makes one acceptable.
  final String? instruction;

  final DateTime? lastSubmittedAt;

  /// A message the office chose to show the resident about *this* document.
  ///
  /// **Only ever a field the backend marks resident-visible.** A caseworker's
  /// internal note about a document is staff data, and the app has no field to
  /// put one in even if it arrived.
  final String? reviewerMessage;

  /// Whether the resident can act on this now.
  ///
  /// True while nothing has been sent, and true again when the office asked for
  /// a replacement or the document aged out. Deliberately **false while it is
  /// being checked**: replacing a document mid-review sends a caseworker back to
  /// the start, and the resident cannot see that happening.
  bool get acceptsUpload => switch (status.known) {
    RequirementStatus.missing ||
    RequirementStatus.needsReplacement ||
    RequirementStatus.expired => true,
    RequirementStatus.submitted ||
    RequirementStatus.underVerification ||
    RequirementStatus.verified => false,
    // An unrecognised status is not an invitation to upload. Failing closed
    // here costs a resident a trip to the counter; failing open replaces a
    // document in a state this build knows nothing about.
    null => false,
  };

  /// Whether the office is waiting on the resident for this one.
  bool get isOutstanding => switch (status.known) {
    RequirementStatus.missing ||
    RequirementStatus.needsReplacement ||
    RequirementStatus.expired => true,
    _ => false,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResidentRequirement && other.code == code);

  @override
  int get hashCode => code.hashCode;

  /// Redacted of the reviewer message and the dates: both are facts about this
  /// resident's case.
  @override
  String toString() => 'ResidentRequirement($code, ${status.raw})';
}

/// Every document one request is waiting on.
@immutable
class RequirementChecklist {
  const RequirementChecklist({required this.requestId, required this.items});

  final String requestId;
  final List<ResidentRequirement> items;

  bool get isEmpty => items.isEmpty;

  List<ResidentRequirement> get outstanding =>
      items.where((item) => item.isOutstanding).toList(growable: false);

  /// How many the office is still waiting for.
  ///
  /// ---
  ///
  /// **There is no completion percentage here, and there must not be.** TAB 16
  /// is explicit: a local "100% complete" meter implies approval, and approval
  /// is a decision only Taytay LGU staff make after reading the documents. A
  /// resident who sees a full bar and is then rejected was told something the
  /// app had no standing to say.
  ///
  /// A count of what is still outstanding is a different statement — it is
  /// about the resident's own to-do list, not about the outcome — so that is
  /// what this exposes.
  int get outstandingCount => outstanding.length;

  @override
  String toString() =>
      'RequirementChecklist($requestId, ${items.length} items)';
}

/// The server's receipt for one uploaded file.
///
/// **A reference, never the bytes.** The same rule the verification flow already
/// follows: a document is uploaded once and afterwards referred to by id, so a
/// retry elsewhere in the app never re-sends an identity document over a
/// resident's mobile data.
@immutable
class UploadedDocumentReference {
  const UploadedDocumentReference({
    required this.id,
    required this.requirementCode,
    this.status,
    this.rawStatus,
  });

  /// Server-issued opaque id.
  final String id;

  final String requirementCode;

  final ServerValue<RequirementStatus>? status;

  /// Preserved verbatim when the server reported one this build did not know.
  final String? rawStatus;

  @override
  String toString() => 'UploadedDocumentReference($requirementCode)';
}

/// A cancellation the resident can pull mid-upload.
///
/// ---
///
/// **Cooperative, and deliberately one-way.** An upload that has already reached
/// the server cannot be un-sent, so this signals intent rather than guaranteeing
/// an outcome: the transport stops sending where it still can, and the
/// controller treats the attempt as stopped whatever the transport returned.
///
/// What it must never do is report success for something the resident stopped —
/// see `RequirementsController.send`, which re-reads [isCancelled] *after* the
/// repository resolves for exactly that reason.
class UploadCancellation {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// The documents belonging to one of the signed-in resident's own requests.
///
/// **`/me/`-scoped by construction.** Every method takes a request id and no
/// resident identifier, because there is no code path in this app that should be
/// able to name another person's request.
abstract interface class RequirementRepository {
  /// What this request is waiting on.
  Future<Result<RequirementChecklist>> listRequirements(String requestId);

  /// Sends one document against one requirement.
  ///
  /// [onProgress] receives a fraction in `0.0..1.0`. It is a progress report,
  /// not a promise: a resident watching a bar reach the end still waits for the
  /// server's answer, and the screen must not treat 1.0 as success.
  ///
  /// [idempotencyKey] is required for the same reason it is on a submission —
  /// a dropped connection after the server stored the file is indistinguishable
  /// from one before, and a duplicate document creates work for the office.
  Future<Result<UploadedDocumentReference>> uploadRequirementDocument({
    required String requestId,
    required String requirementCode,
    required CapturedDocument document,
    required String idempotencyKey,
    void Function(double fraction)? onProgress,
    UploadCancellation? cancellation,
  });
}
