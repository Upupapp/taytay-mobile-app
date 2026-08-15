import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/forms/field_error.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_intake.dart';
import '../domain/assistance_intake_validation.dart';
import '../domain/service_request_repository.dart';

/// Drives the assistance intake wizard.
///
/// ---
///
/// ## What this class guarantees
///
/// * **The step list is derived from the server's form, never hard-coded.** A
///   service with no questions shows no question step; a service with no
///   consents shows no consent step. The app cannot present a step the office
///   did not ask for.
/// * **Going back never loses what was entered.** The draft is one immutable
///   value replaced in place, and movement never touches it.
/// * **Forward movement is validated; backward movement is not.** A resident may
///   always retreat, including out of a step they have not finished.
/// * **Nothing is submitted twice.** One idempotency key is minted per
///   submission attempt and reused across every retry of that attempt, so a
///   retry after a dropped connection replays rather than files a second
///   application. The key is discarded only once the server has answered.
/// * **A failure never clears the draft.** "Preserve entries on transient
///   network error" is not a feature here; it is what happens because failure
///   handling writes to a separate field.
class AssistanceIntakeController extends ChangeNotifier {
  AssistanceIntakeController({
    required ServiceRequestRepository repository,
    required this.serviceCode,
  }) : _repository = repository;

  final ServiceRequestRepository _repository;

  /// The catalogue entry being applied for. Validated by the screen before this
  /// controller is built.
  final String serviceCode;

  AssistanceIntakeForm? _form;
  AppFailure? _formFailure;
  bool _loadingForm = true;

  AssistanceIntakeDraft _draft = const AssistanceIntakeDraft();
  IntakeStep _step = IntakeStep.context;
  List<FieldError> _errors = const <FieldError>[];
  AppFailure? _failure;
  AssistanceIntakeSubmission? _submission;
  bool _busy = false;
  String? _idempotencyKey;

  AssistanceIntakeForm? get form => _form;

  /// Why the form could not be loaded. Distinct from [failure], which belongs
  /// to a submission attempt.
  AppFailure? get formFailure => _formFailure;

  bool get isLoadingForm => _loadingForm;

  AssistanceIntakeDraft get draft => _draft;
  IntakeStep get step => _step;

  /// Field errors for the current step. Empty until a resident tries to
  /// continue — errors that appear while someone is still typing are noise, and
  /// for a screen-reader user they are noise announced aloud.
  List<FieldError> get errors => _errors;

  /// A transport or server failure from a submission attempt.
  AppFailure? get failure => _failure;

  AssistanceIntakeSubmission? get submission => _submission;
  bool get busy => _busy;

  /// The server's statement that an application is already open, if it made one.
  ActiveRequestNotice? get activeRequest => _form?.activeRequest;

  /// Whether the form contains a question this build cannot render.
  ///
  /// When true the wizard refuses to submit and sends the resident to the
  /// municipal hall. Submitting anyway would file an application the office
  /// considers incomplete, and the resident would never learn which answer was
  /// missing. See [IntakeQuestion.isRenderable].
  bool get isBlockedByUnknownQuestions =>
      _form?.hasUnrenderableQuestions ?? false;

  /// The steps this resident will actually see, in order.
  List<IntakeStep> get steps {
    final form = _form;
    return <IntakeStep>[
      IntakeStep.context,
      IntakeStep.describe,
      if (form != null && form.questions.isNotEmpty) IntakeStep.questions,
      if (form != null && form.requirements.isNotEmpty) IntakeStep.documents,
      if (form != null && form.consents.isNotEmpty) IntakeStep.consent,
      IntakeStep.review,
      IntakeStep.submitting,
      IntakeStep.outcome,
    ];
  }

  /// Input steps only, for "step 3 of 5".
  List<IntakeStep> get progressSteps =>
      steps.where((step) => step.isInputStep).toList(growable: false);

  /// 1-based position, or `null` once past the input steps.
  int? get progressPosition {
    final index = progressSteps.indexOf(_step);
    return index < 0 ? null : index + 1;
  }

  bool get canGoBack =>
      _step != IntakeStep.context &&
      _step != IntakeStep.submitting &&
      _step != IntakeStep.outcome;

  /// Whether the review step may send.
  ///
  /// Guarded on three things, each of which has already caused a real defect
  /// class somewhere: an in-flight attempt, a form the app cannot fully render,
  /// and a form that is not actually complete.
  bool get canSubmit {
    final form = _form;
    if (form == null || _busy || isBlockedByUnknownQuestions) return false;
    return AssistanceIntakeValidation.validateAll(_draft, form).isEmpty;
  }

  /// Loads the server's description of this service's application.
  Future<void> initialise() async {
    _loadingForm = true;
    notifyListeners();

    final outcome = await _repository.loadIntakeForm(serviceCode);
    _loadingForm = false;
    outcome.fold(
      onOk: (form) {
        _form = form;
        _formFailure = null;
      },
      onErr: (failure) {
        _form = null;
        _formFailure = failure;
      },
    );
    notifyListeners();
  }

  // ── Draft edits ──────────────────────────────────────────────────────────
  //
  // Each clears the submission failure banner but not the field errors: a
  // resident fixing one field should not watch the other problems vanish from
  // the summary before they have addressed them.

  void confirmContext({required bool confirmed}) {
    _draft = _draft.copyWith(contextConfirmed: confirmed);
    _failure = null;
    notifyListeners();
  }

  void updateNarrative(String value) {
    _draft = _draft.copyWith(narrative: value);
    _failure = null;
    notifyListeners();
  }

  void answer(String questionKey, Object? value) {
    _draft = _draft.withAnswer(questionKey, value);
    _failure = null;
    notifyListeners();
  }

  void toggleConsent(String consentKey, {required bool given}) {
    _draft = _draft.withConsent(consentKey, given: given);
    notifyListeners();
  }

  // ── Movement ─────────────────────────────────────────────────────────────

  /// Validates the current step and advances if it passes.
  ///
  /// Returns whether it advanced, so a screen can move focus to the error
  /// summary when it did not.
  bool next() {
    final form = _form;
    if (form == null) return false;

    final found = AssistanceIntakeValidation.validateStep(_step, _draft, form);
    if (found.isNotEmpty) {
      _errors = found;
      notifyListeners();
      return false;
    }

    _errors = const <FieldError>[];
    _moveTo(_nextStepAfter(_step));
    return true;
  }

  /// Steps back, keeping everything already entered.
  void back() {
    if (!canGoBack) return;
    final order = steps;
    final index = order.indexOf(_step);
    if (index <= 0) return;
    _errors = const <FieldError>[];
    _failure = null;
    _moveTo(order[index - 1]);
  }

  /// Jumps to a step from the review screen.
  ///
  /// Backwards only, and only to a step already in the flow: "edit" on the
  /// review must not become a way to reach a step that was never part of this
  /// service's application.
  void editStep(IntakeStep target) {
    final order = steps;
    if (!order.contains(target) ||
        order.indexOf(target) >= order.indexOf(IntakeStep.review)) {
      return;
    }
    _errors = const <FieldError>[];
    _failure = null;
    _moveTo(target);
  }

  IntakeStep _nextStepAfter(IntakeStep current) {
    final order = steps;
    final index = order.indexOf(current);
    if (index < 0 || index + 1 >= order.length) return current;
    return order[index + 1];
  }

  void _moveTo(IntakeStep target) {
    _step = target;
    notifyListeners();
  }

  // ── Submission ───────────────────────────────────────────────────────────

  /// Sends the application.
  ///
  /// Re-validates everything first. A resident can reach review, step back,
  /// clear a required field and return, and the per-step check that let them
  /// past the first time is no longer true.
  Future<void> submit() async {
    final form = _form;
    if (form == null || _busy) return;

    if (isBlockedByUnknownQuestions) {
      // Refusing here rather than in the UI alone: this is the invariant, and
      // it should hold for any caller.
      return;
    }

    final found = AssistanceIntakeValidation.validateAll(_draft, form);
    if (found.isNotEmpty) {
      _errors = found;
      _moveTo(IntakeStep.review);
      return;
    }

    _errors = const <FieldError>[];
    _idempotencyKey ??= generateRequestId();
    _moveTo(IntakeStep.submitting);
    _setBusy(true);

    final outcome = await _repository.submitRequest(
      serviceCode: serviceCode,
      narrative: _draft.narrative.trim(),
      answers: _draft.answers,
      consentKeys: _draft.givenConsents.toList(growable: false),
      attachmentIds: _draft.attachmentIds,
      idempotencyKey: _idempotencyKey!,
    );
    _setBusy(false);

    outcome.fold(
      onOk: (request) {
        _failure = null;
        _submission = AssistanceIntakeSubmission(
          outcome: IntakeOutcome.submitted,
          referenceNumber: request.referenceNumber,
          residentMessage:
              'Taytay LGU has your application. Keep the reference below — the '
              'office will ask for it.',
        );
        // Answered. The key must not be reused: a later attempt is a genuinely
        // new application, not a replay of this one.
        _idempotencyKey = null;
      },
      onErr: (failure) {
        _failure = failure;
        _submission = _submissionFor(failure);
        // The key is deliberately kept for a retryable failure, so that
        // pressing "Try again" replays the same attempt rather than filing a
        // second application. A conflict means the server already has one, so
        // there is nothing left to replay.
        if (failure is ConflictFailure) _idempotencyKey = null;
      },
    );
    _moveTo(IntakeStep.outcome);
  }

  /// Retries a failed submission with the same idempotency key.
  Future<void> retrySubmission() async {
    if (_busy) return;
    // A conflict is not retryable: the server has stated an application exists,
    // and sending again would only ask it to say so twice.
    if (_submission?.outcome == IntakeOutcome.alreadyOpen) return;
    await submit();
  }

  /// Maps a failure onto resident-facing copy.
  ///
  /// The server's `message` never appears here — it is operator-facing by
  /// contract. The copy is chosen by failure kind, and the most important thing
  /// it says is whether anything was submitted.
  AssistanceIntakeSubmission _submissionFor(AppFailure failure) {
    if (failure is ConflictFailure) {
      return AssistanceIntakeSubmission(
        outcome: IntakeOutcome.alreadyOpen,
        requestId: failure.requestId,
        residentMessage:
            'Taytay LGU already has an application from you for this service. '
            'A second one would not be processed any faster. Check its status '
            'under your requests.',
      );
    }

    return AssistanceIntakeSubmission(
      outcome: IntakeOutcome.couldNotSend,
      requestId: failure.requestId,
      residentMessage:
          'We could not send your application, so nothing was submitted. Your '
          'answers are still here — you can try again without applying twice.',
    );
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
