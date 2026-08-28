import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/forms/field_error.dart';
import '../../../core/forms/validation_message.dart';
import '../../../core/result/result.dart';
import '../../../core/session/access_level.dart';
import '../domain/event_repository.dart';

/// Where the resident is in the registration flow.
enum RegistrationStep {
  /// Confirm the event and who is registering.
  confirm,

  /// Answer the office's questions.
  questions,

  /// Reminders and acknowledgements.
  consent,

  /// In flight.
  submitting,

  /// The result.
  outcome;

  bool get isInputStep =>
      this != RegistrationStep.submitting && this != RegistrationStep.outcome;

  String get title => switch (this) {
    RegistrationStep.confirm => 'Confirm your registration',
    RegistrationStep.questions => 'Questions from the office',
    RegistrationStep.consent => 'Before you register',
    RegistrationStep.submitting => 'Registering',
    RegistrationStep.outcome => 'Your registration',
  };
}

/// Why a resident cannot register right now.
///
/// Separate from a failure, because none of these is something going wrong:
/// each is a state with its own sentence and its own way forward.
enum RegistrationBlock {
  /// The event needs a verified resident and this one is not.
  needsVerification,

  /// The form contains a field this build cannot render.
  unsupportedForm,

  /// The office has closed registration, or the event is full.
  notOpen,

  /// They already hold a place.
  alreadyRegistered,
}

/// Drives registering for one event.
///
/// ---
///
/// ## What this class guarantees
///
/// * **The server owns capacity.** Nothing here decides a place is available.
///   A full event is discovered by asking, and a `full` answer to a submission
///   is an outcome the resident reads, not an error they report.
/// * **Nothing is registered twice.** One idempotency key per attempt, reused
///   across retries of that attempt, discarded once the server answers. A
///   resident who retried into a double registration would be holding a place
///   somebody else could have had.
/// * **Verification is the server's call, per event.** `allowsUnverifiedResidents`
///   comes from the form; the app does not assume that every event needs a
///   verified resident, nor that none does.
/// * **A failure keeps every answer.** The draft is untouched by failure
///   handling.
class EventRegistrationController extends ChangeNotifier {
  EventRegistrationController({
    required EventRepository repository,
    required this.eventId,
    required this.accessLevel,
  }) : _repository = repository;

  final EventRepository _repository;
  final String eventId;

  /// The signed-in resident's level, captured when the flow opened. The route
  /// already guarantees this is not a guest.
  final AccessLevel accessLevel;

  EventRegistrationForm? _form;
  AppFailure? _formFailure;
  bool _loadingForm = true;

  RegistrationStep _step = RegistrationStep.confirm;
  Map<String, Object?> _answers = const <String, Object?>{};
  Set<String> _consents = const <String>{};
  List<FieldError> _errors = const <FieldError>[];

  RegistrationAttempt? _attempt;
  AppFailure? _failure;
  bool _busy = false;
  String? _idempotencyKey;

  EventRegistrationForm? get form => _form;
  AppFailure? get formFailure => _formFailure;
  bool get isLoadingForm => _loadingForm;

  RegistrationStep get step => _step;
  Map<String, Object?> get answers =>
      Map<String, Object?>.unmodifiable(_answers);
  Set<String> get consents => Set<String>.unmodifiable(_consents);
  List<FieldError> get errors => _errors;

  RegistrationAttempt? get attempt => _attempt;
  AppFailure? get failure => _failure;
  bool get busy => _busy;

  /// Why registration is unavailable, or `null` when it may proceed.
  ///
  /// Ordered deliberately: an existing registration is reported before a
  /// verification requirement, because telling a resident who already holds a
  /// place to go and verify themselves is nonsense.
  RegistrationBlock? get block {
    final form = _form;
    if (form == null) return null;

    // Once this flow has produced an outcome, the outcome is what the resident
    // needs to read. Without this, a successful registration immediately
    // reports "you are already registered" and swallows the reference the
    // server just issued — which is the one thing they came for.
    if (_attempt != null) return null;

    if (_alreadyRegistered) return RegistrationBlock.alreadyRegistered;
    if (accessLevel != AccessLevel.verified &&
        !form.allowsUnverifiedResidents) {
      return RegistrationBlock.needsVerification;
    }
    if (form.hasUnrenderableFields) return RegistrationBlock.unsupportedForm;
    return null;
  }

  bool _alreadyRegistered = false;

  /// The steps this resident will see, derived from the form.
  List<RegistrationStep> get steps {
    final form = _form;
    return <RegistrationStep>[
      RegistrationStep.confirm,
      if (form != null && form.fields.isNotEmpty) RegistrationStep.questions,
      if (form != null && form.consents.isNotEmpty) RegistrationStep.consent,
      RegistrationStep.submitting,
      RegistrationStep.outcome,
    ];
  }

  List<RegistrationStep> get progressSteps =>
      steps.where((step) => step.isInputStep).toList(growable: false);

  int? get progressPosition {
    final index = progressSteps.indexOf(_step);
    return index < 0 ? null : index + 1;
  }

  bool get canGoBack =>
      _step != RegistrationStep.confirm &&
      _step != RegistrationStep.submitting &&
      _step != RegistrationStep.outcome;

  /// Whether the final step may send.
  bool get canSubmit {
    if (_form == null || _busy || block != null) return false;
    return _validateAll().isEmpty;
  }

  /// Loads the form, and notes whether the resident already holds a place.
  Future<void> initialise({EventRegistration? existing}) async {
    _alreadyRegistered = existing?.isActive ?? false;
    _loadingForm = true;
    notifyListeners();

    final outcome = await _repository.loadRegistrationForm(eventId);
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

  void answer(String key, Object? value) {
    final next = Map<String, Object?>.from(_answers);
    if (value == null) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    _answers = next;
    _failure = null;
    notifyListeners();
  }

  void toggleConsent(String key, {required bool given}) {
    final next = Set<String>.from(_consents);
    if (given) {
      next.add(key);
    } else {
      next.remove(key);
    }
    _consents = next;
    notifyListeners();
  }

  // ── Movement ─────────────────────────────────────────────────────────────

  bool next() {
    final form = _form;
    if (form == null || block != null) return false;

    final found = _validateStep(_step, form);
    if (found.isNotEmpty) {
      _errors = found;
      notifyListeners();
      return false;
    }

    _errors = const <FieldError>[];
    final order = steps;
    final index = order.indexOf(_step);
    if (index >= 0 && index + 1 < order.length) {
      _step = order[index + 1];
      notifyListeners();
    }
    return true;
  }

  void back() {
    if (!canGoBack) return;
    final order = steps;
    final index = order.indexOf(_step);
    if (index <= 0) return;
    _errors = const <FieldError>[];
    _failure = null;
    _step = order[index - 1];
    notifyListeners();
  }

  // ── Submission ───────────────────────────────────────────────────────────

  Future<void> submit() async {
    final form = _form;
    if (form == null || _busy || block != null) return;

    final found = _validateAll();
    if (found.isNotEmpty) {
      _errors = found;
      notifyListeners();
      return;
    }

    _errors = const <FieldError>[];
    _idempotencyKey ??= generateRequestId();
    _step = RegistrationStep.submitting;
    _busy = true;
    notifyListeners();

    final outcome = await _repository.register(
      eventId: eventId,
      answers: _answers,
      consentKeys: _consents.toList(growable: false),
      idempotencyKey: _idempotencyKey!,
    );
    _busy = false;

    outcome.fold(
      onOk: (attempt) {
        _attempt = attempt;
        _failure = null;
        // The server has answered. A later attempt is a new one.
        _idempotencyKey = null;
        if (attempt.isHeld) _alreadyRegistered = true;
      },
      onErr: (failure) {
        _failure = failure;
        _attempt = RegistrationAttempt(
          outcome: RegistrationOutcome.couldNotSend,
          requestId: failure.requestId,
          residentMessage:
              'We could not send your registration, so nothing was registered. '
              'Your answers are still here — you can try again without '
              'registering twice.',
        );
        // The key survives, so a retry replays this attempt.
      },
    );

    _step = RegistrationStep.outcome;
    notifyListeners();
  }

  /// Retries a failed attempt with the same key.
  ///
  /// Deliberately refuses when the event turned out to be full or closed: the
  /// server has stated the position, and asking again only makes it say so
  /// twice.
  Future<void> retry() async {
    if (_busy) return;
    final outcome = _attempt?.outcome;
    if (outcome == RegistrationOutcome.full ||
        outcome == RegistrationOutcome.closed ||
        outcome == RegistrationOutcome.refused) {
      return;
    }
    _step = RegistrationStep.confirm;
    await submit();
  }

  // ── Validation ───────────────────────────────────────────────────────────

  List<FieldError> _validateStep(
    RegistrationStep step,
    EventRegistrationForm form,
  ) => switch (step) {
    RegistrationStep.questions => _validateFields(form),
    RegistrationStep.consent => _validateConsents(form),
    _ => const <FieldError>[],
  };

  List<FieldError> _validateAll() {
    final form = _form;
    if (form == null) return const <FieldError>[];
    return <FieldError>[..._validateFields(form), ..._validateConsents(form)];
  }

  /// Checks the office's own fields. Never stricter than what it declared.
  List<FieldError> _validateFields(EventRegistrationForm form) {
    final errors = <FieldError>[];

    for (final field in form.fields) {
      // An unrenderable field blocks the whole flow elsewhere; reporting it
      // here would tell a resident to fix something never shown to them.
      if (!field.isRenderable) continue;

      final answer = _answers[field.key];
      if (_isBlank(answer)) {
        if (field.isRequired) {
          errors.add(
            FieldError(
              field: field.key,
              kind: ValidationMessage.answerMissingGeneric,
              subject: field.prompt,
              message: 'Answer "${field.prompt}".',
            ),
          );
        }
        continue;
      }

      if (field.kind.known == ServerFieldKind.number && answer is! num) {
        errors.add(
          FieldError(
            field: field.key,
            // Shares the intake form's wording deliberately. Two sentences for
            // one condition is two things to translate and two things to keep
            // consistent; the intake's is the fuller of the two and says what
            // to do about it.
            kind: ValidationMessage.answerNotANumber,
            subject: field.prompt,
            message: 'Enter "${field.prompt}" as a number.',
          ),
        );
        continue;
      }

      final maximum = field.maxLength;
      if (maximum != null &&
          answer is String &&
          answer.trim().length > maximum) {
        errors.add(
          FieldError(
            field: field.key,
            kind: ValidationMessage.answerTooLong,
            limit: maximum,
            message: 'Shorten this to $maximum characters or fewer.',
          ),
        );
      }
    }
    return errors;
  }

  List<FieldError> _validateConsents(EventRegistrationForm form) =>
      <FieldError>[
        for (final consent in form.requiredConsents)
          if (!_consents.contains(consent.key))
            FieldError(
              field: 'consent_${consent.key}',
              kind: ValidationMessage.consentRequiredToRegister,
              // The consent's own label comes from the server and is already in
              // the office's language — it is carried, not translated.
              subject: consent.label,
              message: 'You need to accept "${consent.label}" to register.',
            ),
      ];

  static bool _isBlank(Object? answer) => switch (answer) {
    null => true,
    final String value => value.trim().isEmpty,
    final List<Object?> value => value.isEmpty,
    // `false` on a yes/no field is an answer, not a blank.
    _ => false,
  };
}
