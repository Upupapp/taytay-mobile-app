import 'package:flutter/foundation.dart';

import 'lgu_service.dart' show ServerValue;
import 'service_request_repository.dart';

/// One thing that happened to a request, in the resident's view of it.
///
/// ---
///
/// **A timeline entry is the office's own record, filtered to what a citizen may
/// see.** The admin case file behind it carries assessment scores, caseworker
/// notes, risk flags, handoffs between desks and audit metadata. None of that
/// has a field on this class — not a nullable one, not a private one — because a
/// field that exists is a field something will eventually populate.
///
/// What a resident gets is the three things that answer "where is this?": when
/// it happened, what changed, and whether anything is now expected of them.
@immutable
class CaseTimelineEntry {
  const CaseTimelineEntry({
    required this.occurredAt,
    required this.state,
    required this.summary,
    this.detail,
  });

  final DateTime occurredAt;

  /// The lifecycle value the office recorded, with the raw string preserved.
  final ServerValue<ServiceRequestState> state;

  /// Resident-facing one-liner authored by the LGU, or derived from [state]
  /// when the server sent none.
  final String summary;

  /// Optional extra sentence, when the office chose to explain.
  final String? detail;

  @override
  String toString() => 'CaseTimelineEntry(${state.raw})';
}

/// Something the resident can do next.
///
/// The Master Command is explicit that these appear **only if the backend says
/// they are available**. That is not a UI preference: "view release
/// instructions" on a case with no release scheduled sends someone to a
/// municipal hall on a day nothing is waiting for them.
enum NextActionKind {
  uploadRequirement('upload_requirement'),
  provideInformation('provide_information'),
  awaitReview('await_review'),
  viewReleaseInstructions('view_release_instructions'),
  viewReferral('view_referral'),
  contactOffice('contact_office');

  const NextActionKind(this.wireValue);

  final String wireValue;
}

/// One offered next step.
@immutable
class CaseNextAction {
  const CaseNextAction({required this.kind, required this.label, this.detail});

  final ServerValue<NextActionKind> kind;

  /// Resident-facing, authored by the LGU.
  final String label;

  final String? detail;

  /// Whether this app can act on it, as opposed to only describing it.
  ///
  /// An unrecognised kind is **described and not actioned**: the label still
  /// tells the resident what the office wants, and the app does not guess at a
  /// destination for a step it has never heard of.
  bool get isActionable => kind.isRecognised;

  @override
  String toString() => 'CaseNextAction(${kind.raw})';
}

/// Everything a resident may see about one of their own requests.
@immutable
class AssistanceCaseDetail {
  const AssistanceCaseDetail({
    required this.request,
    this.timeline = const <CaseTimelineEntry>[],
    this.nextActions = const <CaseNextAction>[],
    this.outcomeReason,
    this.releaseInstructions,
    this.referral,
  });

  final ServiceRequest request;

  /// Oldest first. The screen reverses it; the order the server sent is kept so
  /// a support conversation and the app agree on what happened when.
  final List<CaseTimelineEntry> timeline;

  final List<CaseNextAction> nextActions;

  /// Why a request was rejected or cancelled.
  ///
  /// **Present only when the backend intentionally exposes it.** The Master
  /// Command says so, and the reason is the same one that governs every other
  /// staff field here: an internal rejection heuristic shown to a resident is
  /// both a privacy breach and an invitation to game it. When the server sends
  /// nothing, the screen says the office will be in touch — which is true — and
  /// does not speculate.
  final String? outcomeReason;

  /// Where and when to collect, when the office has scheduled it.
  final String? releaseInstructions;

  /// Where the case was referred, when that is intended for the resident.
  final String? referral;

  bool get hasTimeline => timeline.isNotEmpty;

  /// The most recent entry, which is what the status card reflects.
  CaseTimelineEntry? get latest => timeline.isEmpty ? null : timeline.last;

  @override
  String toString() =>
      'AssistanceCaseDetail(${request.rawState}, ${timeline.length} entries)';
}
