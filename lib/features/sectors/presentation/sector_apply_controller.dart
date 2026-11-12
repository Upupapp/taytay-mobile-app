import 'package:flutter/foundation.dart';

import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../domain/resident_sector.dart';
import '../domain/sector_repository.dart';

/// Where Apply for a sector is: the three steps of `SectorApply.dc.html`,
/// `SectorProof.dc.html` and `SectorSent.dc.html`, plus the send between the
/// last two.
enum SectorApplyStep { choose, proof, sending, sent }

/// Apply for a sector: one sector, one photo of its ID, a confirmation, and a
/// send (D-215).
///
/// **The photo lives here and nowhere else.** It is held in memory until it is
/// sent or replaced, then dropped; nothing is written to disk. The uploaded
/// photo's id is kept for a retry of the same photo, so a failed application
/// does not upload it twice.
///
/// The body is the sector and the proof, and nothing more: B4 takes no ID
/// number, no dates and no reasons, so the form collects none.
class SectorApplyController extends ChangeNotifier {
  SectorApplyController({
    required SectorRepository repository,
    required DocumentPicker picker,
    ResidentSector? initial,
  }) : _repository = repository,
       _picker = picker,
       _chosen = initial;

  final SectorRepository _repository;
  final DocumentPicker _picker;

  SectorApplyStep _step = SectorApplyStep.choose;
  SectorApplyStep get step => _step;

  ResidentSector? _chosen;
  ResidentSector? get chosen => _chosen;

  CapturedDocument? _proof;
  CapturedDocument? get proof => _proof;

  ({DocumentRejection reason, int bytes})? _refused;

  /// Why the last photo chosen was refused on the phone.
  ({DocumentRejection reason, int bytes})? get refused => _refused;

  bool _confirmed = false;
  bool get confirmed => _confirmed;

  AppFailure? _failure;

  /// Why the last send did not go through. Cleared by any change.
  AppFailure? get failure => _failure;

  String? _uploaded;
  SectorApplication? _filed;

  /// The application as the server filed it, once [step] is sent.
  SectorApplication? get filed => _filed;

  bool get readyToSend => _chosen != null && _proof != null && _confirmed;

  bool supports(DocumentSource source) => _picker.supports(source);

  void choose(ResidentSector sector) {
    if (_step != SectorApplyStep.choose) return;
    if (sector == _chosen) return;
    // A photo of one sector's ID is not proof of another.
    if (_chosen != null) {
      _proof = null;
      _refused = null;
      _uploaded = null;
      _confirmed = false;
    }
    _chosen = sector;
    _failure = null;
    notifyListeners();
  }

  /// Step 1 to step 2, once a sector is chosen.
  void next() {
    if (_step != SectorApplyStep.choose || _chosen == null) return;
    _step = SectorApplyStep.proof;
    notifyListeners();
  }

  /// Step 2 back to step 1. The photo stays: going back to read the choices
  /// again is not starting over.
  void back() {
    if (_step != SectorApplyStep.proof) return;
    _step = SectorApplyStep.choose;
    _failure = null;
    notifyListeners();
  }

  /// Opens the picker and keeps the photo only if it passes the upload rule.
  /// A refused photo is dropped at once.
  ///
  /// `POST /media` publishes no rule of its own, so this is the app's one
  /// fallback, as for the avatar and the verification photos. The server's
  /// narrower rule (JPEG, PNG or WebP, 5 MB) refuses the rest, and the send
  /// says so.
  Future<void> pick(DocumentSource source) async {
    if (_step != SectorApplyStep.proof) return;
    final CapturedDocument? picked = await _picker.pick(
      source,
      UploadPolicy.fallback,
    );
    // Backing out of a picker is a choice, not a failure.
    if (picked == null) return;
    final DocumentRejection? refusal = DocumentCapturePolicy.inspect(
      picked,
      UploadPolicy.fallback,
    );
    if (refusal != null) {
      _refused = (reason: refusal, bytes: picked.sizeBytes);
      _proof = null;
    } else {
      _refused = null;
      _proof = picked;
    }
    _uploaded = null;
    _failure = null;
    notifyListeners();
  }

  void confirm(bool value) {
    if (value == _confirmed) return;
    _confirmed = value;
    _failure = null;
    notifyListeners();
  }

  /// Uploads the photo (once), then files the application. A failure leaves
  /// the choice, the photo and the tick in place.
  Future<void> send() async {
    final ResidentSector? sector = _chosen;
    final CapturedDocument? proof = _proof;
    if (_step != SectorApplyStep.proof ||
        sector == null ||
        proof == null ||
        !_confirmed) {
      return;
    }
    _step = SectorApplyStep.sending;
    _failure = null;
    notifyListeners();

    String? mediaId = _uploaded;
    if (mediaId == null) {
      final Result<String> upload = await _repository.uploadProof(proof);
      switch (upload) {
        case Ok(:final value):
          mediaId = value;
          _uploaded = value;
        case Err(:final failure):
          _fail(failure);
          return;
      }
    }

    final Result<SectorApplication> filed = await _repository.apply(
      sector: sector,
      proofMediaIds: <String>[mediaId],
    );
    switch (filed) {
      case Ok(:final value):
        _filed = value;
        _proof = null;
        _uploaded = null;
        _step = SectorApplyStep.sent;
        notifyListeners();
      case Err(:final failure):
        _fail(failure);
    }
  }

  void _fail(AppFailure failure) {
    _failure = failure;
    _step = SectorApplyStep.proof;
    notifyListeners();
  }

  @override
  void dispose() {
    _proof = null;
    super.dispose();
  }
}
