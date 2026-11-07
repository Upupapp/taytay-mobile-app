import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../domain/issuance_form.dart';
import '../domain/issuance_repository.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_type.dart';

/// Where the request form is.
enum IssuanceFormStage { editing, reviewing, sending, done }

/// The document request form: one purpose, one file per requirement, a review,
/// and a send.
///
/// **Bytes live here and nowhere else.** A chosen file is held in memory until
/// it is sent or removed, then dropped. Nothing is written to disk, and a
/// request that was not sent leaves nothing behind when the screen closes.
class IssuanceRequestController extends ChangeNotifier {
  IssuanceRequestController({
    required IssuanceRepository repository,
    required DocumentPicker picker,
    required this.type,
  }) : _repository = repository,
       _picker = picker;

  final IssuanceRepository _repository;
  final DocumentPicker _picker;
  final IssuanceType type;

  IssuanceFormStage _stage = IssuanceFormStage.editing;
  IssuanceFormStage get stage => _stage;

  String _purpose = '';
  String get purpose => _purpose;

  final Map<String, CapturedDocument> _files = <String, CapturedDocument>{};
  Map<String, CapturedDocument> get files =>
      Map<String, CapturedDocument>.unmodifiable(_files);

  final Map<String, ({DocumentRejection reason, int bytes})> _refused =
      <String, ({DocumentRejection reason, int bytes})>{};

  /// Why the last file chosen for [code] was refused on the phone.
  ({DocumentRejection reason, int bytes})? refusedFor(String code) =>
      _refused[code];

  /// Set once the resident asks to review, so a field is not marked wrong
  /// before they have had a chance to fill it.
  bool _checked = false;
  bool get showProblems => _checked;

  AppFailure? _failure;

  /// Why the last send did not go through. Cleared by any edit.
  AppFailure? get failure => _failure;

  /// Requirement codes and `purpose`, when the server's 422 named them.
  Set<String> _serverFlagged = const <String>{};
  bool serverFlagged(String field) => _serverFlagged.contains(field);

  IssuanceRequestDetail? _filed;

  /// The request as the server filed it, once [stage] is done.
  IssuanceRequestDetail? get filed => _filed;

  String? _idempotencyKey;

  PurposeProblem? get purposeProblem => checkPurpose(_purpose);

  List<IssuanceRequirement> get missing => missingRequiredFiles(type, _files);

  bool get isComplete => purposeProblem == null && missing.isEmpty;

  bool supports(DocumentSource source) => _picker.supports(source);

  void setPurpose(String value) {
    if (value == _purpose) return;
    _purpose = value;
    _edited();
  }

  /// Opens the picker and keeps the file only if it passes the office's own
  /// `accepts` block. A refused file is dropped at once.
  Future<void> choose(String code, DocumentSource source) async {
    final CapturedDocument? picked = await _picker.pick(
      source,
      type.uploadPolicy,
    );
    // Backing out of a picker is a choice, not a failure.
    if (picked == null) return;
    final DocumentRejection? refusal = DocumentCapturePolicy.inspect(
      picked,
      type.uploadPolicy,
    );
    if (refusal != null) {
      _refused[code] = (reason: refusal, bytes: picked.sizeBytes);
      _files.remove(code);
    } else {
      _refused.remove(code);
      _files[code] = picked;
    }
    _edited();
  }

  void remove(String code) {
    _files.remove(code);
    _refused.remove(code);
    _edited();
  }

  /// Moves to the review step when nothing is missing. Otherwise marks what
  /// is, and stays.
  bool review() {
    _checked = true;
    if (!isComplete) {
      notifyListeners();
      return false;
    }
    _stage = IssuanceFormStage.reviewing;
    notifyListeners();
    return true;
  }

  void backToEditing() {
    if (_stage != IssuanceFormStage.reviewing) return;
    _stage = IssuanceFormStage.editing;
    notifyListeners();
  }

  /// Sends the request. A failure leaves every answer and file in place, and
  /// the screen says plainly that nothing was submitted.
  Future<void> submit() async {
    if (_stage != IssuanceFormStage.reviewing || !isComplete) return;
    // One key per set of answers: a retry of the same request carries the
    // same key, an edited request a new one.
    _idempotencyKey ??= generateRequestId();
    _stage = IssuanceFormStage.sending;
    _failure = null;
    notifyListeners();

    final Result<IssuanceRequestDetail> result = await _repository.submit(
      typeId: type.id,
      purpose: _purpose,
      files: Map<String, CapturedDocument>.of(_files),
      idempotencyKey: _idempotencyKey!,
    );
    switch (result) {
      case Ok(:final value):
        _filed = value;
        _files.clear();
        _stage = IssuanceFormStage.done;
      case Err(:final failure):
        _failure = failure;
        _serverFlagged = failure is ValidationFailure
            ? failure.fieldErrors.keys.toSet()
            : const <String>{};
        // A refusal about the content goes back to the form, where the
        // flagged items are; anything else stays on review to send again.
        _stage = failure is ValidationFailure
            ? IssuanceFormStage.editing
            : IssuanceFormStage.reviewing;
    }
    notifyListeners();
  }

  void _edited() {
    _failure = null;
    _serverFlagged = const <String>{};
    _idempotencyKey = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _files.clear();
    super.dispose();
  }
}
