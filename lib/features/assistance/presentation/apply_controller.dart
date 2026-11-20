import 'package:flutter/foundation.dart';

import '../../../core/api/send_key.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../../tulong/domain/social_service.dart';
import '../domain/assistance_application.dart';
import '../domain/own_assistance_repository.dart';
import '../domain/own_assistance_request.dart';

/// Where the Apply wizard stands (D-226).
///
/// The four steps a resident moves through — [about], [details],
/// [documents], [review] — then [sending] and [done]. [notVerified],
/// [unlinked] and [notLinked] are what the server or the session said
/// instead: each tells her what to do first, and none is a dead end.
///
/// [unlinked] is said up front, before anything is typed, when `GET /me`
/// said the account is not linked to her office record; [notLinked] is the
/// send's `409`, after she has answered, from an API that did not say.
enum ApplyStage {
  about,
  details,
  documents,
  review,
  sending,
  done,
  notVerified,
  unlinked,
  notLinked,
}

/// The Apply wizard's state: the answers, the files, the step, and what the
/// server said (D-226).
///
/// One controller per Tulong page and visit. The answers and the files live
/// only here, in memory, and go when the page is left: nothing is written to
/// the phone, and a file is held no longer than the screen that chose it.
class ApplyController extends ChangeNotifier {
  ApplyController({
    required OwnAssistanceRepository repository,
    required DocumentPicker picker,
    required this.service,
    required bool verified,
    bool? linkedToOfficeRecord,
    SendKey? sendKey,
  }) : _repository = repository,
       _picker = picker,
       _key = sendKey ?? SendKey(),
       _stage = !verified
           ? ApplyStage.notVerified
           // Only a server that said "not linked" stops her here. Unknown
           // (an older API, a failed read) keeps the four steps, and the
           // send's `409` says it then.
           : linkedToOfficeRecord == false
           ? ApplyStage.unlinked
           : ApplyStage.about;

  final OwnAssistanceRepository _repository;
  final DocumentPicker _picker;
  final SendKey _key;

  /// The Tulong page applied from, as `GET /services/{slug}` read it.
  final SocialService service;

  /// The route sends no `accepts` block for applications, so files are held
  /// to the app's labelled fallback (8 MB, PDF, JPEG, PNG), which is under the
  /// server's 10 MB: a file refused here is never one the server would take
  /// and the app refused for nothing, only one it might have.
  UploadPolicy get uploadPolicy => UploadPolicy.fallback;

  List<ApplicationRequirement> get requirements =>
      service.applicationRequirements;

  ApplyStage _stage;
  ApplyStage get stage => _stage;

  String _purpose = '';
  String get purpose => _purpose;

  String _amountText = '';
  String get amountText => _amountText;
  ApplicationAmount get amount => ApplicationAmount.parse(_amountText);

  final Map<String, CapturedDocument> _files = <String, CapturedDocument>{};
  Map<String, CapturedDocument> get files =>
      Map<String, CapturedDocument>.unmodifiable(_files);

  final Map<String, ({DocumentRejection reason, int bytes})> _refused =
      <String, ({DocumentRejection reason, int bytes})>{};

  /// The file the phone refused for [code], and why.
  ({DocumentRejection reason, int bytes})? refusedFor(String code) =>
      _refused[code];

  bool _detailsChecked = false;
  bool _documentsChecked = false;

  /// The details step's problems are shown once she has tried to go on.
  bool get showDetailProblems => _detailsChecked;

  /// The documents step's missing files are shown once she has tried to go on.
  bool get showDocumentProblems => _documentsChecked;

  AppFailure? _failure;

  /// Why the last send did not file, in the app's own words on screen.
  AppFailure? get failure => _failure;

  Set<String> _serverFlagged = const <String>{};

  /// The server named [field] in a refusal (`purpose`, a document's code…).
  bool serverFlagged(String field) => _serverFlagged.contains(field);

  /// The page or programme stopped taking applications between the read and
  /// the send (a `422` keyed by `service_slug`).
  bool get closed => _serverFlagged.contains('service_slug');

  OwnAssistanceRequest? _filed;

  /// Her own row, with the control number, once the office has it.
  OwnAssistanceRequest? get filed => _filed;

  ApplicationPurposeProblem? get purposeProblem =>
      checkApplicationPurpose(_purpose);

  ApplicationAmountProblem? get amountProblem => switch (amount) {
    AmountRefused(:final problem) => problem,
    AmountNotGiven() || AmountGiven() => null,
  };

  int? get amountCentavos => switch (amount) {
    AmountGiven(:final centavos) => centavos,
    AmountNotGiven() || AmountRefused() => null,
  };

  List<ApplicationRequirement> get missing =>
      missingRequiredDocuments(requirements, _files);

  bool get detailsComplete => purposeProblem == null && amountProblem == null;

  bool supports(DocumentSource source) => _picker.supports(source);

  /// The step number she reads ("Step 2 of 4"), or null off the four steps.
  int? get stepNumber => switch (_stage) {
    ApplyStage.about => 1,
    ApplyStage.details => 2,
    ApplyStage.documents => 3,
    ApplyStage.review || ApplyStage.sending => 4,
    ApplyStage.done ||
    ApplyStage.notVerified ||
    ApplyStage.unlinked ||
    ApplyStage.notLinked => null,
  };

  static const int stepCount = 4;

  void start() => _move(ApplyStage.about, ApplyStage.details);

  void setPurpose(String value) {
    if (value == _purpose) return;
    _purpose = value;
    _edited();
  }

  void setAmount(String value) {
    if (value == _amountText) return;
    _amountText = value;
    _edited();
  }

  /// From the details to the documents, once the purpose and the amount can
  /// be sent. Returns whether it moved.
  bool toDocuments() {
    if (_stage != ApplyStage.details) return false;
    _detailsChecked = true;
    if (!detailsComplete) {
      notifyListeners();
      return false;
    }
    _stage = ApplyStage.documents;
    notifyListeners();
    return true;
  }

  /// From the documents to the review, once every required one has a file.
  bool toReview() {
    if (_stage != ApplyStage.documents) return false;
    _documentsChecked = true;
    if (missing.isNotEmpty) {
      notifyListeners();
      return false;
    }
    _stage = ApplyStage.review;
    notifyListeners();
    return true;
  }

  /// One step back. Returns false where there is no step to go back to, so
  /// the screen may leave.
  bool back() {
    final ApplyStage? previous = switch (_stage) {
      ApplyStage.details => ApplyStage.about,
      ApplyStage.documents => ApplyStage.details,
      ApplyStage.review => ApplyStage.documents,
      ApplyStage.notLinked => ApplyStage.review,
      ApplyStage.about ||
      ApplyStage.sending ||
      ApplyStage.done ||
      ApplyStage.notVerified ||
      ApplyStage.unlinked => null,
    };
    if (previous == null) return false;
    _stage = previous;
    notifyListeners();
    return true;
  }

  /// From the review, straight to a step to change something.
  void edit(ApplyStage step) {
    if (_stage != ApplyStage.review) return;
    if (step != ApplyStage.details && step != ApplyStage.documents) return;
    _stage = step;
    notifyListeners();
  }

  Future<void> choose(String code, DocumentSource source) async {
    final CapturedDocument? picked = await _picker.pick(source, uploadPolicy);
    // Backing out of a picker is a choice, not a failure.
    if (picked == null) return;
    final DocumentRejection? refusal = DocumentCapturePolicy.inspect(
      picked,
      uploadPolicy,
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

  /// Sends the application. Only from the review, and only once.
  ///
  /// A send that fails says plainly that nothing was sent, or that it is not
  /// confirmed when the answer never came; the answers and files stay, and
  /// sending again under the same key cannot file twice.
  Future<void> submit() async {
    if (_stage != ApplyStage.review && _stage != ApplyStage.notLinked) return;
    if (!detailsComplete || missing.isNotEmpty) return;
    final String key = _key.take();
    _stage = ApplyStage.sending;
    _failure = null;
    notifyListeners();

    final Result<OwnAssistanceRequest> result = await _repository.apply(
      serviceSlug: service.slug,
      purpose: _purpose,
      requestedAmountCentavos: amountCentavos,
      files: Map<String, CapturedDocument>.of(_files),
      idempotencyKey: key,
    );
    _key.settle(result);
    switch (result) {
      case Ok(:final value):
        _filed = value;
        _files.clear();
        _refused.clear();
        _stage = ApplyStage.done;
      case Err(:final failure):
        _serverFlagged = failure is ValidationFailure
            ? failure.fieldErrors.keys.toSet()
            : const <String>{};
        _failure = failure;
        _stage = _stageAfter(failure);
    }
    notifyListeners();
  }

  /// Where a refusal is best answered: the step that holds what the server
  /// named, or a state that says what to do first.
  ApplyStage _stageAfter(AppFailure failure) {
    return switch (failure) {
      ForbiddenFailure(requiresVerification: true) => ApplyStage.notVerified,
      // The route's 409s: the account is not linked to a registry record, or
      // the record was retired. Both are the office's to put right, and both
      // are said the same way. A key reused for another body cannot happen
      // here: every edit drops the key.
      ConflictFailure() => ApplyStage.notLinked,
      ValidationFailure()
          when _serverFlagged.contains('purpose') ||
              _serverFlagged.contains('requested_amount_centavos') =>
        ApplyStage.details,
      ValidationFailure()
          when requirements.any(
            (ApplicationRequirement r) => _serverFlagged.contains(r.code),
          ) =>
        ApplyStage.documents,
      _ => ApplyStage.review,
    };
  }

  void _move(ApplyStage from, ApplyStage to) {
    if (_stage != from) return;
    _stage = to;
    notifyListeners();
  }

  void _edited() {
    _failure = null;
    _serverFlagged = const <String>{};
    _key.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _files.clear();
    _refused.clear();
    super.dispose();
  }
}
