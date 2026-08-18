import 'package:flutter/foundation.dart';

import '../../../core/api/request_context.dart';
import '../../../core/result/result.dart';
import '../../registration/domain/registration_domain.dart';
import '../domain/kyc_claim.dart';
import '../domain/verification_repository.dart';

/// Drives the KYC claim form: the screen that opens a resident's case.
///
/// ---
///
/// **This is the screen F14 kept shut.** `POST me/kyc` needed a barangay, no
/// route published one, and so the whole Verified tier was unreachable. The
/// directory ships now, and this controller is what connects it to a form: the
/// barangay list is loaded from the server, the resident picks one, and the
/// claim is filed against the `code` that came back — never an identifier this
/// app invented.
///
/// **The list is loaded before the form is usable, and a failure to load is not
/// hidden.** A picker that silently comes up empty tells a resident their
/// barangay does not exist in Taytay, which is a worse lie than an error.
class KycClaimController extends ChangeNotifier {
  KycClaimController({
    required BarangayDirectory directory,
    required VerificationRepository repository,
  }) : _directory = directory,
       _repository = repository;

  final BarangayDirectory _directory;
  final VerificationRepository _repository;

  /// Held across retries of the same claim: a resend after a dropped connection
  /// must not become a second case in a municipal review queue. Cleared once the
  /// server has answered, because a later attempt is a different claim.
  String? _idempotencyKey;

  List<Barangay> _barangays = const <Barangay>[];
  AppFailure? _directoryFailure;
  bool _loadingDirectory = false;

  String _givenName = '';
  String _middleName = '';
  String _familyName = '';
  String _suffix = '';
  DateTime? _birthDate;
  ClaimedSex? _sex;
  Barangay? _barangay;
  String _streetAddress = '';

  bool _submitting = false;
  AppFailure? _failure;
  bool _opened = false;

  List<Barangay> get barangays => _barangays;
  AppFailure? get directoryFailure => _directoryFailure;
  bool get loadingDirectory => _loadingDirectory;
  bool get submitting => _submitting;
  AppFailure? get failure => _failure;

  /// True once the server has accepted the claim. The screen leaves on this,
  /// not on the absence of a failure — "no error yet" is also what an
  /// in-flight request looks like.
  bool get opened => _opened;

  DateTime? get birthDate => _birthDate;
  ClaimedSex? get sex => _sex;
  Barangay? get barangay => _barangay;

  /// Whether the form has everything the server requires.
  ///
  /// Drives the submit button's enabled state, so the resident is never sent to
  /// a 422 whose field errors are keyed by wire names they have never seen.
  bool get canSubmit =>
      !_submitting &&
      _givenName.trim().isNotEmpty &&
      _familyName.trim().isNotEmpty &&
      _birthDate != null &&
      _sex != null &&
      (_barangay?.code ?? '').isNotEmpty &&
      _streetAddress.trim().isNotEmpty;

  Future<void> loadDirectory() async {
    _loadingDirectory = true;
    _directoryFailure = null;
    notifyListeners();

    final Result<List<Barangay>> outcome = await _directory.listBarangays();
    _loadingDirectory = false;
    outcome.fold(
      onOk: (List<Barangay> rows) {
        // A barangay with no code cannot be filed against, so it is not offered.
        // Selecting one that fails at submission is worse than not seeing it.
        _barangays = rows
            .where((Barangay b) => (b.code ?? '').isNotEmpty)
            .toList(growable: false);
        // If the chosen one is no longer in the list, forget it rather than
        // submitting a code the server has since retired.
        if (_barangay != null && !_barangays.contains(_barangay)) {
          _barangay = null;
        }
      },
      onErr: (AppFailure f) => _directoryFailure = f,
    );
    notifyListeners();
  }

  void setGivenName(String value) => _update(() => _givenName = value);
  void setMiddleName(String value) => _update(() => _middleName = value);
  void setFamilyName(String value) => _update(() => _familyName = value);
  void setSuffix(String value) => _update(() => _suffix = value);
  void setBirthDate(DateTime value) => _update(() => _birthDate = value);
  void setSex(ClaimedSex value) => _update(() => _sex = value);
  void setStreetAddress(String value) => _update(() => _streetAddress = value);

  /// Ignores a barangay that is not in the loaded list.
  ///
  /// The only barangays that exist are the ones the server published. Accepting
  /// anything else would let a stale draft or a deep link file a claim against
  /// a code this build never saw.
  void setBarangay(Barangay value) {
    if (!_barangays.contains(value)) return;
    _update(() => _barangay = value);
  }

  void _update(void Function() change) {
    change();
    _failure = null;
    notifyListeners();
  }

  /// Files the claim. Opens the case; does not submit it for review.
  ///
  /// Two steps because they are two decisions. Opening a case is reversible from
  /// the resident's side — the draft is theirs until they send it — and sending
  /// it puts a case in front of a municipal reviewer. Collapsing them would mean
  /// a resident who mistyped a birth date has already used their queue slot.
  Future<void> submit() async {
    if (!canSubmit) return;

    _submitting = true;
    _failure = null;
    _idempotencyKey ??= generateRequestId();
    notifyListeners();

    final Result<VerificationStatus> outcome = await _repository.openCase(
      claim: KycClaim(
        givenName: _givenName,
        middleName: _middleName,
        familyName: _familyName,
        suffix: _suffix,
        birthDate: _birthDate!,
        sex: _sex!,
        barangayCode: _barangay!.code!,
        streetAddress: _streetAddress,
      ),
      idempotencyKey: _idempotencyKey!,
    );

    _submitting = false;
    outcome.fold(
      onOk: (VerificationStatus _) {
        _opened = true;
        _idempotencyKey = null;
      },
      onErr: (AppFailure f) => _failure = f,
    );
    notifyListeners();
  }
}
