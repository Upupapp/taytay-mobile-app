import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../../../core/session/session_controller.dart';
import '../domain/correctable_field.dart';
import '../domain/kyc_claim.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_status_detail.dart';

/// Drives the verification status screen and the correction flow.
///
/// ---
///
/// ## The one thing this class exists to get right
///
/// **When the server says verified, the session must reflect it immediately.**
///
/// A resident who has just been verified and is looking at a "Verified" screen,
/// but still cannot open their digital ID until they restart the app, has been
/// told two contradictory things by the same product. So [refresh] pushes the
/// server's tier straight into [SessionController.applyVerificationTier], which
/// is the single place access level changes. The router listens to that
/// controller, so every gated route re-evaluates in the same frame — no
/// restart, no manual navigation, and no second source of truth.
///
/// The app still decides nothing: the tier is the server's answer, and
/// `AccessLevel.fromVerificationTier` fails closed on anything it does not
/// recognise. This class only makes sure the answer arrives somewhere central.
class VerificationController extends ChangeNotifier {
  VerificationController({
    required VerificationRepository repository,
    required SessionController session,
    DocumentPicker? picker,
  }) : _repository = repository,
       _session = session,
       _picker = picker ?? const UnavailableDocumentPicker();

  final VerificationRepository _repository;
  final SessionController _session;

  /// The device seam for choosing a document (F28).
  ///
  /// Defaults to the unavailable one rather than being required, so a caller
  /// that has nothing to pick with still gets a working status screen — the
  /// screen's job is telling a resident where they stand, and it should not
  /// stop doing that because a platform channel is missing.
  final DocumentPicker _picker;

  List<KycDocument> _documents = const <KycDocument>[];
  KycDocumentType? _attaching;

  /// Whether this controller has been thrown away.
  ///
  /// [_loadDocuments] is fired and not awaited, so it can land after a resident
  /// has navigated off the screen — and `notifyListeners()` on a disposed
  /// `ChangeNotifier` throws. Found by a test that had nothing to do with
  /// documents, which is the usual way this class of bug is found.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Notifies unless this controller is gone.
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  VerificationStatusDetail? _status;
  AppFailure? _failure;
  bool _loading = false;
  bool _submitting = false;
  String? _correctionKey;
  String? _submissionKey;

  /// Corrections the resident has typed, keyed by the category the office
  /// flagged. Nothing can be entered for a category that was not flagged.
  final Map<CorrectableField, String> _corrections =
      <CorrectableField, String>{};

  /// Which field the resident chose for each category that spans several.
  ///
  /// Held apart from the values so that changing the choice does not silently
  /// re-file text typed for a different field — the old entry is removed, and
  /// the resident types again against the field they actually meant.
  final Map<VerificationItemCategory, CorrectableField> _chosenField =
      <VerificationItemCategory, CorrectableField>{};

  VerificationStatusDetail? get status => _status;
  AppFailure? get failure => _failure;
  bool get loading => _loading;
  bool get submitting => _submitting;

  /// What the office holds, one row per type. Empty until [refresh] has run.
  List<KycDocument> get documents => _documents;

  /// The type currently uploading, if any. Drives one spinner, not a global one.
  KycDocumentType? get attaching => _attaching;

  /// Whether this device can choose a file at all.
  ///
  /// A tablet with no picker should not show a Send button that cannot work —
  /// the screen says so instead, and points at the municipal hall.
  bool get canAttach =>
      _picker.supports(DocumentSource.gallery) ||
      _picker.supports(DocumentSource.camera);

  Map<CorrectableField, String> get corrections =>
      Map<CorrectableField, String>.unmodifiable(_corrections);

  /// The field chosen for [category], or the only one it has.
  CorrectableField? chosenFieldFor(VerificationItemCategory category) =>
      _chosenField[category] ??
      (category.fields.length == 1 ? category.fields.first : null);

  /// Records which detail a resident means, and drops anything typed against
  /// the field they no longer mean.
  void chooseField(VerificationItemCategory category, CorrectableField field) {
    final previous = chosenFieldFor(category);
    if (previous != null && previous != field) _corrections.remove(previous);
    _chosenField[category] = field;
    notifyListeners();
  }

  /// Whether every flagged item has something typed against it.
  bool get correctionsComplete {
    final issues = _status?.issues ?? const <VerificationItemIssue>[];
    if (issues.isEmpty) return false;

    // Only the categories this route can carry are required. A flagged document
    // has no field to correct and never gets an input, so demanding one would
    // make the button permanently dead for a resident whose only problem is a
    // blurry ID — which is the correction they can least afford to be blocked on.
    final correctable = issues.where((i) => i.category.isCorrectable);
    if (correctable.isEmpty) return false;

    return correctable.every((issue) {
      final field = chosenFieldFor(issue.category);
      if (field == null) return false;
      return (_corrections[field] ?? '').trim().isNotEmpty;
    });
  }

  /// Loads the status and, if it says verified, unlocks access centrally.
  Future<void> refresh() async {
    _loading = true;
    _failure = null;
    notifyListeners();

    final outcome = await _repository.loadOwnStatusDetail();
    _loading = false;

    outcome.fold(
      onOk: (detail) {
        _status = detail;
        _syncSessionTier(detail);
        // Read alongside the status rather than on demand: a resident opening
        // this screen wants to know what the office has, and a second tap to
        // find out is a second chance to conclude it has nothing.
        unawaited(_loadDocuments());
      },
      onErr: (failure) {
        _failure = failure;
        // Deliberately does **not** clear a previously loaded status: a resident
        // on a weak connection should keep seeing what the LGU last said rather
        // than watch their verification state vanish because a refresh failed.
      },
    );
    notifyListeners();
  }

  /// Pushes the server's verdict into the one place that owns access level.
  ///
  /// Only ever called with what the server sent. The app never promotes a
  /// session on its own — and `applyVerificationTier` ignores the call entirely
  /// when nobody is signed in, so this cannot manufacture a session either.
  void _syncSessionTier(VerificationStatusDetail detail) {
    if (detail.isVerified) {
      _session.applyVerificationTier('verified');
      return;
    }
    // Any non-verified stage means the session must not be holding a verified
    // level. Passing the raw state lets `AccessLevel.fromVerificationTier` fail
    // closed on anything that is not exactly 'verified' — including a state this
    // build has never seen.
    _session.applyVerificationTier(detail.rawState);
  }

  /// Records a correction against the field the office adjudicates.
  ///
  /// Ignores fields no flagged category covers: the correction flow is a reply
  /// to a specific request, not an opportunity to resubmit anything. Keyed by
  /// field rather than category since TAB 04 — see [CorrectableField].
  void updateCorrection(CorrectableField field, String value) {
    final flagged =
        _status?.issues.any((i) => i.category.fields.contains(field)) ?? false;
    if (!flagged) return;
    _corrections[field] = value;
    _failure = null;
    notifyListeners();
  }

  Future<void> _loadDocuments() async {
    final Result<List<KycDocument>> outcome = await _repository.loadDocuments();
    outcome.fold(
      onOk: (List<KycDocument> rows) {
        _documents = rows;
        _notify();
      },
      // Deliberately silent. A failure to list documents must not replace the
      // status a resident came here to read, and the attach controls stay
      // usable — the worst case is that they send something twice, which
      // supersedes rather than duplicates.
      onErr: (_) {},
    );
  }

  /// Attaches one document to the open case (F28).
  ///
  /// ---
  ///
  /// **The bytes leave the device here and nowhere else.** There is no local
  /// copy kept, no cache, and no retry queue holding a photograph of somebody's
  /// PhilID: if the send fails the resident is told and chooses again, which
  /// costs them a tap and costs nobody a stored identity document.
  ///
  /// Cancelling the picker is not a failure and is not reported as one — a
  /// person backing out of a camera is exercising a choice.
  Future<bool> attachDocument(
    KycDocumentType type,
    DocumentSource source,
  ) async {
    if (_attaching != null) return false;

    final CapturedDocument? picked = await _picker.pick(
      source,
      // The server publishes no `accepts` block for KYC, so the app's single
      // declared fallback applies. It is the only literal ceiling in `lib/`.
      UploadPolicy.fallback,
    );
    if (picked == null) return false;

    _attaching = type;
    _failure = null;
    notifyListeners();

    final Result<KycDocument> outcome = await _repository.attachDocument(
      type: type,
      fileName: picked.fileName,
      bytes: picked.bytes,
      mimeType: picked.mimeType,
      idempotencyKey: generateRequestId(),
    );

    _attaching = null;

    return outcome.fold(
      onOk: (KycDocument document) {
        _documents =
            <KycDocument>[
              for (final KycDocument existing in _documents)
                if (existing.type != document.type) existing,
              document,
            ]..sort(
              (KycDocument a, KycDocument b) =>
                  a.type.index.compareTo(b.type.index),
            );
        notifyListeners();
        return true;
      },
      onErr: (AppFailure failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  /// Sends a saved draft to Taytay LGU for review.
  ///
  /// ---
  ///
  /// **This is the moment a case enters a municipal queue**, and it is a
  /// separate press from saving the claim for exactly that reason: somebody who
  /// mistyped a birth date has not already spent their place in it.
  ///
  /// No documents are attached — a KYC case has nowhere to put one (F28), and
  /// the repository declines rather than dropping any it is given. Passing the
  /// empty list is not a stub: it is the true statement that this submission
  /// carries none, and it is the one shape the server actually serves.
  ///
  /// Re-reads the status afterwards rather than assuming the new state. The
  /// server decides whether a submission goes to screening or straight to a
  /// person, and the app has no basis for guessing which.
  Future<bool> sendForReview() async {
    if (_submitting) return false;

    // Reused on retry, so a dropped connection cannot put two cases in front of
    // a reviewer. Cleared once the server has answered.
    _submissionKey ??= generateRequestId();
    _submitting = true;
    _failure = null;
    notifyListeners();

    final outcome = await _repository.submitForReview(
      documentUploadIds: const <String>[],
      idempotencyKey: _submissionKey!,
    );
    _submitting = false;

    return outcome.fold(
      onOk: (_) {
        _submissionKey = null;
        notifyListeners();
        unawaited(refresh());
        return true;
      },
      onErr: (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  /// Sends the corrections the office asked for.
  ///
  /// One idempotency key per attempt, reused on retry, so a dropped connection
  /// cannot put two replies in a municipal review queue.
  Future<bool> submitCorrections() async {
    if (!correctionsComplete || _submitting) return false;

    _correctionKey ??= generateRequestId();
    _submitting = true;
    _failure = null;
    notifyListeners();

    final outcome = await _repository.submitCorrections(
      corrections: Map<CorrectableField, String>.from(_corrections),
      idempotencyKey: _correctionKey!,
    );
    _submitting = false;

    return outcome.fold(
      onOk: (_) {
        // Sent: forget the typed values and re-read the status rather than
        // assuming what the server now thinks.
        _corrections.clear();
        _correctionKey = null;
        notifyListeners();
        unawaited(refresh());
        return true;
      },
      onErr: (failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }
}
