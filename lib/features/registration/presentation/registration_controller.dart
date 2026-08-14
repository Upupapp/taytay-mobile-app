import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/result/result.dart';
import '../domain/registration_domain.dart';
import '../domain/registration_validation.dart';

/// Drives the registration wizard.
///
/// ---
///
/// ## What this class guarantees
///
/// * **The step list is derived, never hard-coded.** Optional steps appear only
///   when [RegistrationCapabilities] says the server asked for them, so a build
///   that cannot reach the server shows the short flow rather than collecting
///   documents nobody requested.
/// * **Going back never loses what was entered.** The draft is a single
///   immutable value updated in place; moving between steps does not touch it.
///   Re-collecting a birth date because someone corrected a typo two steps
///   earlier is how a resident abandons a government form.
/// * **Forward movement is validated; backward movement is not.** A resident may
///   always retreat, including out of an invalid step.
/// * **Nothing is submitted twice.** One idempotency key is minted per
///   submission attempt and reused across retries of that attempt.
class RegistrationController extends ChangeNotifier {
  RegistrationController({
    required RegistrationRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final RegistrationRepository _repository;
  final DateTime Function() _clock;

  RegistrationDraft _draft = const RegistrationDraft();
  RegistrationCapabilities _capabilities = RegistrationCapabilities.denied;
  RegistrationStep _step = RegistrationStep.contact;
  List<FieldError> _errors = const <FieldError>[];
  AppFailure? _failure;
  RegistrationResult? _result;
  bool _busy = false;
  String _code = '';
  String? _idempotencyKey;

  RegistrationDraft get draft => _draft;
  RegistrationCapabilities get capabilities => _capabilities;
  RegistrationStep get step => _step;

  /// Field errors for the current step. Empty until a resident tries to
  /// continue — inline errors that appear while someone is still typing are
  /// noise, and for a screen-reader user they are noise announced aloud.
  List<FieldError> get errors => _errors;

  /// A transport or server failure, distinct from field errors.
  AppFailure? get failure => _failure;

  RegistrationResult? get result => _result;
  bool get busy => _busy;
  String get code => _code;

  /// The steps this resident will actually see, in order.
  ///
  /// Recomputed from [capabilities], so a step cannot be reached by navigation
  /// if it is not in this list.
  List<RegistrationStep> get steps => <RegistrationStep>[
    RegistrationStep.contact,
    RegistrationStep.verifyCode,
    RegistrationStep.personalDetails,
    RegistrationStep.address,
    RegistrationStep.consent,
    if (_capabilities.requiresIdentityDocument)
      RegistrationStep.identityDocument,
    // Biometric capture needs *both* a server requirement and explicit consent.
    // Either alone is not enough: the server asking does not make it consented,
    // and consent given in advance does not make it required.
    if (_capabilities.requiresFaceCapture &&
        _draft.hasConsent(ConsentKind.biometricProcessing))
      RegistrationStep.faceCapture,
    RegistrationStep.review,
    RegistrationStep.submitting,
    RegistrationStep.status,
  ];

  /// Input steps only, for "step 3 of 6".
  List<RegistrationStep> get progressSteps =>
      steps.where((step) => step.isInputStep).toList(growable: false);

  /// 1-based position, or `null` once past the input steps.
  int? get progressPosition {
    final index = progressSteps.indexOf(_step);
    return index < 0 ? null : index + 1;
  }

  bool get canGoBack =>
      _step != RegistrationStep.contact &&
      _step != RegistrationStep.submitting &&
      _step != RegistrationStep.status;

  /// Asks the server what this resident still needs to provide.
  ///
  /// Called once when the wizard opens. Any failure leaves capabilities denied.
  Future<void> initialise() async {
    _capabilities = await _repository.loadCapabilities();
    notifyListeners();
  }

  // ── Draft edits ──────────────────────────────────────────────────────────
  //
  // Each clears the failure banner but not the field errors: a resident fixing
  // one field should not have the other errors disappear from the summary
  // before they have addressed them.

  void updateDraft(RegistrationDraft Function(RegistrationDraft) edit) {
    _draft = edit(_draft);
    _failure = null;
    notifyListeners();
  }

  void updateCode(String value) {
    _code = value;
    _failure = null;
    notifyListeners();
  }

  void toggleConsent(ConsentKind kind, {required bool given}) {
    final next = Set<ConsentKind>.from(_draft.consents);
    if (given) {
      next.add(kind);
    } else {
      next.remove(kind);
    }
    _draft = _draft.copyWith(consents: next);
    notifyListeners();
  }

  // ── Movement ─────────────────────────────────────────────────────────────

  /// Validates the current step and advances if it passes.
  ///
  /// Returns whether it advanced, so a screen can move focus to the error
  /// summary when it did not.
  Future<bool> next() async {
    final found = RegistrationValidation.validateStep(
      _step,
      _draft,
      code: _code,
      now: _clock(),
    );
    if (found.isNotEmpty) {
      _errors = found;
      notifyListeners();
      return false;
    }
    _errors = const <FieldError>[];

    // Two steps do work before they may be left.
    if (_step == RegistrationStep.contact) return _requestCode();
    if (_step == RegistrationStep.verifyCode) return _verifyCode();

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
  /// Only backwards, and only to a step already in the flow: "edit" on the
  /// review must not become a way to skip a step that was never completed.
  void editStep(RegistrationStep target) {
    final order = steps;
    if (!order.contains(target) ||
        order.indexOf(target) >= order.indexOf(RegistrationStep.review)) {
      return;
    }
    _errors = const <FieldError>[];
    _failure = null;
    _moveTo(target);
  }

  RegistrationStep _nextStepAfter(RegistrationStep current) {
    final order = steps;
    final index = order.indexOf(current);
    if (index < 0 || index + 1 >= order.length) return current;
    return order[index + 1];
  }

  void _moveTo(RegistrationStep target) {
    _step = target;
    notifyListeners();
  }

  // ── Server-backed steps ──────────────────────────────────────────────────

  Future<bool> _requestCode() async {
    _setBusy(true);
    final outcome = await _repository.requestOneTimeCode(
      mobileNumber: _draft.mobileNumber.trim(),
    );
    _setBusy(false);

    return outcome.fold(
      onOk: (_) {
        _moveTo(RegistrationStep.verifyCode);
        return true;
      },
      onErr: (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> _verifyCode() async {
    _setBusy(true);
    final outcome = await _repository.verifyOneTimeCode(
      mobileNumber: _draft.mobileNumber.trim(),
      code: _code.trim(),
    );
    _setBusy(false);

    return outcome.fold(
      onOk: (_) {
        _draft = _draft.copyWith(codeVerified: true);
        // The server may now know more about what this resident needs.
        unawaited(initialise());
        _moveTo(RegistrationStep.personalDetails);
        return true;
      },
      onErr: (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  /// Sends the completed registration.
  ///
  /// The idempotency key is minted once and kept for the life of this attempt,
  /// so a retry after a dropped connection replays rather than duplicates.
  Future<void> submit() async {
    _idempotencyKey ??= generateRequestId();
    _moveTo(RegistrationStep.submitting);
    _setBusy(true);

    final outcome = await _repository.submitRegistration(
      draft: _draft,
      idempotencyKey: _idempotencyKey!,
    );
    _setBusy(false);

    outcome.fold(
      onOk: (result) {
        _result = result;
        _failure = null;
        // A completed submission cannot be replayed against a new key.
        _idempotencyKey = null;
      },
      onErr: (failure) {
        _failure = failure;
        _result = const RegistrationResult(
          outcome: RegistrationOutcome.unavailable,
          residentMessage:
              'We could not send your registration. Nothing was submitted, so '
              'you can try again without registering twice.',
        );
      },
    );
    _moveTo(RegistrationStep.status);
  }

  /// Retries a failed submission with the same key.
  Future<void> retrySubmission() async {
    if (_busy) return;
    await submit();
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
