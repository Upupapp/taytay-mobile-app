import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../../services/domain/lgu_service.dart' show ServerValue;
import '../domain/resident_requirement.dart';

/// What the upload sheet is doing right now.
enum UploadStage {
  /// Nothing chosen yet.
  choosing,

  /// A document is chosen and shown for review before it is sent.
  previewing,

  /// Bytes are moving.
  uploading,

  /// The server accepted it.
  accepted,

  /// The resident stopped it, or it failed.
  stopped,
}

/// Drives the requirement checklist and one upload at a time.
///
/// ---
///
/// ## What this class guarantees
///
/// * **Nothing reads as sent until the server says so.** [UploadStage.accepted]
///   is set from an `Ok` and from nowhere else. Progress reaching 1.0 does not
///   advance it — the bytes have left the phone, which is not the same as the
///   LGU having stored them.
/// * **A cancellation never reports success.** It resolves to
///   [UploadStage.stopped] with no failure attached — neither an error the
///   resident caused nor a completed upload.
/// * **A retry replays one attempt.** The idempotency key is minted per
///   document and reused until the server answers, so a dropped connection does
///   not leave two copies of an ID card in an office queue.
/// * **The chosen document is dropped as soon as it is no longer needed.** It is
///   the most sensitive thing this app holds in memory, and it is released on
///   success, on cancellation and on dispose.
class RequirementsController extends ChangeNotifier {
  RequirementsController({
    required RequirementRepository repository,
    required DocumentPicker picker,
    required this.requestId,
  }) : _repository = repository,
       _picker = picker;

  final RequirementRepository _repository;
  final DocumentPicker _picker;
  final String requestId;

  RequirementChecklist? _checklist;
  AppFailure? _loadFailure;
  bool _loading = true;

  // ── One upload at a time ─────────────────────────────────────────────────
  //
  // Deliberately singular. Parallel uploads on a weak connection make every one
  // of them slower and the progress unreadable, and the resident cannot tell
  // which one failed.

  String? _activeCode;
  UploadStage _stage = UploadStage.choosing;
  CapturedDocument? _document;
  DocumentRejection? _rejection;

  /// How big the refused file was, in bytes.
  ///
  /// **A number, not the document.** The refusal needs to say "that file is
  /// 12 MB", and that is the only thing about it worth keeping — holding the
  /// bytes of a resident's identity document that the app has already refused
  /// would be retaining personal data for no purpose (Article 5.1).
  int? _refusedSizeBytes;
  AppFailure? _uploadFailure;
  double _progress = 0;
  UploadCancellation? _cancellation;
  String? _idempotencyKey;

  RequirementChecklist? get checklist => _checklist;
  AppFailure? get loadFailure => _loadFailure;
  bool get isLoading => _loading;

  /// The requirement an upload is open for, if any.
  String? get activeCode => _activeCode;

  UploadStage get stage => _stage;
  CapturedDocument? get document => _document;

  /// Why the chosen file was refused before anything was sent.
  DocumentRejection? get rejection => _rejection;

  /// Size of the refused file, for the message. Null unless [rejection] is set.
  int? get refusedSizeBytes => _refusedSizeBytes;

  AppFailure? get uploadFailure => _uploadFailure;

  /// `0.0..1.0`. Only meaningful while [stage] is [UploadStage.uploading].
  double get progress => _progress;

  bool get isUploading => _stage == UploadStage.uploading;

  bool get canSend =>
      _document != null &&
      _rejection == null &&
      _stage == UploadStage.previewing;

  /// Server-side validation messages for the file, when the server returned
  /// them against a field.
  ///
  /// The one place server text is shown, because it is the only place it is
  /// actionable — the same rule the rest of the app follows.
  List<String> get serverFieldMessages {
    final failure = _uploadFailure;
    if (failure is! ValidationFailure) return const <String>[];
    return failure.fieldErrors.values.expand((messages) => messages).toList();
  }

  bool supportsSource(DocumentSource source) => _picker.supports(source);

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final outcome = await _repository.listRequirements(requestId);
    _loading = false;
    outcome.fold(
      onOk: (checklist) {
        _checklist = checklist;
        _loadFailure = null;
      },
      onErr: (failure) {
        _checklist = null;
        _loadFailure = failure;
      },
    );
    notifyListeners();
  }

  /// Opens the upload flow for one requirement.
  void beginUpload(String requirementCode) {
    _activeCode = requirementCode;
    _stage = UploadStage.choosing;
    _clearDocument();
    _rejection = null;
    _refusedSizeBytes = null;
    _uploadFailure = null;
    _progress = 0;
    _idempotencyKey = null;
    notifyListeners();
  }

  /// Closes it, releasing the bytes.
  void endUpload() {
    _cancellation?.cancel();
    _cancellation = null;
    _activeCode = null;
    _stage = UploadStage.choosing;
    _clearDocument();
    _rejection = null;
    _refusedSizeBytes = null;
    _uploadFailure = null;
    _progress = 0;
    _idempotencyKey = null;
    notifyListeners();
  }

  /// Asks the platform for a document and checks it before showing a preview.
  Future<void> choose(DocumentSource source) async {
    _rejection = null;
    _refusedSizeBytes = null;
    _uploadFailure = null;

    // The policy the checklist arrived with. Until it has, the labelled
    // fallback applies — a resident who opens the picker before the list has
    // loaded is still told about a file that is plainly too big, and told with
    // the conservative number rather than with nothing.
    final policy = _checklist?.uploadPolicy ?? UploadPolicy.fallback;

    final picked = await _picker.pick(source, policy);
    // Backing out of a picker is a choice, not a failure. The sheet stays where
    // it was, with nothing reported.
    if (picked == null) {
      notifyListeners();
      return;
    }

    final refusal = DocumentCapturePolicy.inspect(picked, policy);
    if (refusal != null) {
      // Refused locally, so the bytes are dropped immediately rather than kept
      // around for a send that will not happen.
      _rejection = refusal;
      _refusedSizeBytes = picked.sizeBytes;
      _clearDocument();
      _stage = UploadStage.choosing;
      notifyListeners();
      return;
    }

    _document = picked;
    _stage = UploadStage.previewing;
    // A new document is a new attempt, so it gets its own key.
    _idempotencyKey = null;
    notifyListeners();
  }

  /// Discards the previewed document without sending it.
  void discard() {
    _clearDocument();
    _rejection = null;
    _refusedSizeBytes = null;
    _stage = UploadStage.choosing;
    notifyListeners();
  }

  /// Sends the previewed document.
  Future<void> send() async {
    final document = _document;
    final code = _activeCode;
    if (document == null || code == null || _stage == UploadStage.uploading) {
      return;
    }

    _idempotencyKey ??= generateRequestId();
    _cancellation = UploadCancellation();
    _uploadFailure = null;
    _progress = 0;
    _stage = UploadStage.uploading;
    notifyListeners();

    final outcome = await _repository.uploadRequirementDocument(
      requestId: requestId,
      requirementCode: code,
      document: document,
      idempotencyKey: _idempotencyKey!,
      policy: _checklist?.uploadPolicy ?? UploadPolicy.fallback,
      onProgress: _onProgress,
      cancellation: _cancellation,
    );

    final wasCancelled = _cancellation?.isCancelled ?? false;
    _cancellation = null;

    if (wasCancelled) {
      // Whatever the transport returned, the resident said stop. Reporting
      // success here would be the worst possible outcome of a cancel button.
      _stage = UploadStage.stopped;
      _uploadFailure = null;
      _progress = 0;
      notifyListeners();
      return;
    }

    outcome.fold(
      onOk: (reference) {
        _stage = UploadStage.accepted;
        _uploadFailure = null;
        // Held no longer than it must be.
        _clearDocument();
        _idempotencyKey = null;
        _applyAccepted(reference);
      },
      onErr: (failure) {
        _stage = UploadStage.stopped;
        _uploadFailure = failure;
        // The key survives, so "Try again" replays this attempt. The document
        // survives too, so the resident does not re-photograph it.
      },
    );
    notifyListeners();
  }

  /// Stops an upload in flight.
  void cancel() {
    if (_stage != UploadStage.uploading) return;
    _cancellation?.cancel();
    notifyListeners();
  }

  /// Retries a failed upload with the same key and the same document.
  Future<void> retry() async {
    if (_stage == UploadStage.uploading || _document == null) return;
    _stage = UploadStage.previewing;
    await send();
  }

  /// Moves the checklist forward locally after the server accepted a document.
  ///
  /// Uses **the status the server returned**, and falls back to `submitted` —
  /// never `verified`. The app has no standing to decide a document has been
  /// checked, and a resident who saw "verified" appear the instant they uploaded
  /// would reasonably stop worrying about something nobody had read.
  void _applyAccepted(UploadedDocumentReference reference) {
    final current = _checklist;
    if (current == null) return;

    _checklist = RequirementChecklist(
      // Carried forward unchanged: what the office accepts is a property of the
      // response, not of this local status move.
      uploadPolicy: current.uploadPolicy,
      requestId: current.requestId,
      items: <ResidentRequirement>[
        for (final item in current.items)
          if (item.code != reference.requirementCode)
            item
          else
            ResidentRequirement(
              code: item.code,
              label: item.label,
              obligation: item.obligation,
              status:
                  reference.status ??
                  const ServerValue<RequirementStatus>(
                    raw: 'submitted',
                    known: RequirementStatus.submitted,
                  ),
              instruction: item.instruction,
              lastSubmittedAt: item.lastSubmittedAt,
              // Any previous "please replace this" message is about the file
              // that has just been replaced, so it must not survive.
              reviewerMessage: null,
            ),
      ],
    );
  }

  void _onProgress(double fraction) {
    if (_stage != UploadStage.uploading) return;
    _progress = fraction.clamp(0, 1);
    notifyListeners();
  }

  void _clearDocument() => _document = null;

  @override
  void dispose() {
    _cancellation?.cancel();
    _clearDocument();
    super.dispose();
  }
}
