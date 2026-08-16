/// The shape of an assistance intake, as the **server** describes it.
///
/// ---
///
/// ## The rule this whole file exists to keep
///
/// TAB 15 says the app must "answer only the resident-facing assessment/intake
/// questions supplied by backend", and the constitution says the server is the
/// only authority. So this app **does not know what any service asks for**.
/// There is no hard-coded question list here, no per-service branch, no
/// `if (serviceCode == 'CEDULA')`. An intake form is fetched, rendered and sent
/// back.
///
/// The alternative — writing the questions into the client — fails in a
/// specific, expensive way. The municipal office changes what it asks for; the
/// released app keeps asking the old questions; residents fill in a form that
/// produces an application the office has to reject. Nobody can patch a shipped
/// APK on the day the policy changed.
///
/// A consequence worth stating plainly: with the `ServiceDelivery` module still
/// `planned`, no form can be loaded today, and the wizard says so rather than
/// inventing one. See `PlannedServiceRequestRepository`.
///
/// ## Server text that *is* rendered
///
/// Question prompts, help text, choice labels, requirement names and consent
/// statements are **content**, and they are rendered as sent — the same standing
/// as a service name or description. This is not in tension with the rule that
/// the server's error `message` is never shown: that rule is about the
/// operator-facing `message` field on a *failure* envelope, which may name an
/// internal state. Content the LGU authored for residents is the opposite thing.
library;

import 'package:flutter/foundation.dart';

import '../../../core/forms/server_form.dart';

export '../../../core/forms/server_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The field shapes moved to `core/forms/server_form.dart` when event
// registration (TAB 22) needed the same thing: a set of fields an office
// defined, rendered by a client that does not know what they are. Duplicating
// them would have produced two enums and two `isRenderable` rules over one
// concept, which is the drift D-79 already records.
//
// Aliased rather than renamed, because "intake question" is the right word in
// this flow and every call site here reads better for it. The definitions are
// shared; the vocabulary is local.
// ─────────────────────────────────────────────────────────────────────────────

/// How one question is answered. See [ServerFieldKind].
typedef IntakeAnswerKind = ServerFieldKind;

/// One option on a choice question. See [ServerFieldChoice].
typedef IntakeChoice = ServerFieldChoice;

/// One question the office asks about this application. See [ServerField].
///
/// **An unrenderable question is never skipped**: skipping it would submit an
/// application the office considers incomplete, and the resident would never
/// learn why. The wizard blocks submission and sends them to the municipal hall
/// instead — see [AssistanceIntakeForm.hasUnrenderableQuestions].
typedef IntakeQuestion = ServerField;

/// A document the office needs for this application.
///
/// TAB 15 lists these so a resident knows what to bring before they start.
/// **Collecting the file is TAB 16's job** (`Requirements & Secure Document
/// Upload`) — that TAB owns the picker, the compression rules, the progress and
/// the retry, and it owns them once for both this flow and an existing request.
@immutable
class IntakeRequirement {
  const IntakeRequirement({
    required this.code,
    required this.label,
    this.description,
    this.isRequired = true,
  });

  final String code;
  final String label;
  final String? description;
  final bool isRequired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeRequirement && other.code == code);

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'IntakeRequirement($code)';
}

/// An acknowledgement the LGU requires before this application is accepted.
///
/// See [ServerConsent] — shared with event registration, because what a
/// resident is asked to agree to under RA 10173 is the same kind of record
/// whichever flow collects it.
typedef IntakeConsent = ServerConsent;

/// The server reporting that this resident already has an open application for
/// this service.
///
/// ---
///
/// **This is the server's statement, not the app's inference.** The app does not
/// scan a request list and decide something is a duplicate: it does not see
/// every channel a resident may have applied through, and a client that guesses
/// will eventually tell someone they have already applied when they have not.
/// When the server says nothing, the wizard says nothing.
@immutable
class ActiveRequestNotice {
  const ActiveRequestNotice({
    required this.rawState,
    this.referenceNumber,
    this.submittedAt,
  });

  /// The server's own lifecycle value, preserved. Mapped to resident copy for
  /// display; never printed raw.
  final String rawState;

  /// What a resident quotes at the counter.
  final String? referenceNumber;

  final DateTime? submittedAt;

  @override
  String toString() => 'ActiveRequestNotice($rawState)';
}

/// Everything needed to present one service's intake.
@immutable
class AssistanceIntakeForm {
  const AssistanceIntakeForm({
    required this.serviceCode,
    required this.serviceName,
    this.narrativePrompt,
    this.narrativeMaxLength,
    this.questions = const <IntakeQuestion>[],
    this.requirements = const <IntakeRequirement>[],
    this.consents = const <IntakeConsent>[],
    this.supportsDrafts = false,
    this.activeRequest,
  });

  final String serviceCode;
  final String serviceName;

  /// How the office words "tell us what you need". `null` falls back to the
  /// app's own neutral prompt — a label, not a rule.
  final String? narrativePrompt;

  /// Server-declared cap on the narrative. `null` means uncapped here; the
  /// server's answer on submission is the one that counts.
  final int? narrativeMaxLength;

  final List<IntakeQuestion> questions;
  final List<IntakeRequirement> requirements;
  final List<IntakeConsent> consents;

  /// Whether the backend can hold a partially completed application.
  ///
  /// **Autosave is off unless the server says it is supported.** A draft
  /// containing a resident's account of why they need assistance is sensitive
  /// personal data; keeping it on the device because the app felt helpful is
  /// storage nobody authorised and nobody clears. When this is false the wizard
  /// keeps the draft in memory for the life of the flow and nowhere else.
  final bool supportsDrafts;

  /// Set when the server reports an application already in progress.
  final ActiveRequestNotice? activeRequest;

  /// Questions this build cannot render an input for.
  List<IntakeQuestion> get unrenderableQuestions => questions
      .where((question) => !question.isRenderable)
      .toList(growable: false);

  bool get hasUnrenderableQuestions => unrenderableQuestions.isNotEmpty;

  /// Consents that must be given before submission is allowed.
  List<IntakeConsent> get requiredConsents =>
      consents.where((consent) => consent.isRequired).toList(growable: false);

  @override
  String toString() =>
      'AssistanceIntakeForm($serviceCode, ${questions.length} questions)';
}

/// What the resident has entered so far.
///
/// ---
///
/// **Immutable, and edited by replacement.** Moving between steps never touches
/// it, which is what makes "go back without losing anything" true by
/// construction rather than by remembering to copy fields around.
///
/// [answers] is a `Map<String, Object?>` keyed by the server's question keys.
/// The constitution bans wire-shaped maps above `data/`, and this is the
/// deliberate exception: the *shape* of an intake is defined per service by the
/// server, so there is no fixed set of fields for a typed model to name. The
/// values are constrained instead — a `String`, `num`, `bool`, `DateTime` or
/// `List<String>`, chosen by the question's kind — and the keys come from the
/// form, never from user input.
@immutable
class AssistanceIntakeDraft {
  const AssistanceIntakeDraft({
    this.contextConfirmed = false,
    this.narrative = '',
    this.answers = const <String, Object?>{},
    this.givenConsents = const <String>{},
    this.attachmentIds = const <String>[],
  });

  /// Whether the resident confirmed the identity and household context the
  /// application will be filed against.
  final bool contextConfirmed;

  final String narrative;
  final Map<String, Object?> answers;
  final Set<String> givenConsents;

  /// Server-issued references for documents already uploaded. Populated by the
  /// upload flow (TAB 16); never a local file path — a path is not a document,
  /// and putting one in a submission sends a reference that means nothing to
  /// the server.
  final List<String> attachmentIds;

  Object? answerFor(String key) => answers[key];

  bool hasConsent(String key) => givenConsents.contains(key);

  AssistanceIntakeDraft withAnswer(String key, Object? value) {
    final next = Map<String, Object?>.from(answers);
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return copyWith(answers: next);
  }

  AssistanceIntakeDraft withConsent(String key, {required bool given}) {
    final next = Set<String>.from(givenConsents);
    if (given) {
      next.add(key);
    } else {
      next.remove(key);
    }
    return copyWith(givenConsents: next);
  }

  AssistanceIntakeDraft copyWith({
    bool? contextConfirmed,
    String? narrative,
    Map<String, Object?>? answers,
    Set<String>? givenConsents,
    List<String>? attachmentIds,
  }) => AssistanceIntakeDraft(
    contextConfirmed: contextConfirmed ?? this.contextConfirmed,
    narrative: narrative ?? this.narrative,
    answers: answers ?? this.answers,
    givenConsents: givenConsents ?? this.givenConsents,
    attachmentIds: attachmentIds ?? this.attachmentIds,
  );

  /// Redacted. Every field here is the resident's own account of their
  /// circumstances, which is exactly what must never reach a log.
  @override
  String toString() => 'AssistanceIntakeDraft(${answers.length} answers)';
}

/// Where the resident is in the wizard.
enum IntakeStep {
  /// Who this application is being filed for, and against which service.
  context,

  /// The resident's own description of what they need.
  describe,

  /// The server's questions.
  questions,

  /// What the office will need to see.
  documents,

  /// Acknowledgements the LGU requires.
  consent,

  /// Everything, before it is sent.
  review,

  /// In flight.
  submitting,

  /// The result.
  outcome;

  /// Steps that count toward "step 3 of 5". The last three are not input.
  bool get isInputStep =>
      this != IntakeStep.submitting && this != IntakeStep.outcome;

  /// Resident-facing step title.
  String get title => switch (this) {
    IntakeStep.context => 'Who this is for',
    IntakeStep.describe => 'What you need',
    IntakeStep.questions => 'Questions from the office',
    IntakeStep.documents => 'What to bring',
    IntakeStep.consent => 'Before you send this',
    IntakeStep.review => 'Check your answers',
    IntakeStep.submitting => 'Sending',
    IntakeStep.outcome => 'Your application',
  };
}

/// How a submission ended.
enum IntakeOutcome {
  /// The server accepted it and issued a reference.
  submitted,

  /// The server refused because an application is already open. Not an error
  /// the resident caused, and not something to retry.
  alreadyOpen,

  /// It could not be sent. **Nothing was submitted**, so retrying is safe.
  couldNotSend,
}

/// The end of a submission attempt, in resident-facing terms.
@immutable
class AssistanceIntakeSubmission {
  const AssistanceIntakeSubmission({
    required this.outcome,
    required this.residentMessage,
    this.referenceNumber,
    this.requestId,
  });

  final IntakeOutcome outcome;

  /// Fixed app copy chosen by [outcome] — never the server's operator-facing
  /// `message`.
  final String residentMessage;

  /// Issued by the server on success. The only thing a resident needs to keep.
  final String? referenceNumber;

  /// Correlation id, when the server sent one, so a resident can quote an
  /// opaque reference to the support desk.
  final String? requestId;

  bool get isSuccess => outcome == IntakeOutcome.submitted;

  @override
  String toString() => 'AssistanceIntakeSubmission(${outcome.name})';
}
