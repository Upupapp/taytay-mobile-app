import 'package:flutter/foundation.dart';

import '../../features/citizen_api/domain/citizen_contract.dart';
import '../../features/platform/domain/app_bootstrap.dart';
import '../../features/platform/domain/platform_repository.dart';
import '../../features/platform/domain/privacy_notice.dart';
import '../../features/settings/domain/account_controls.dart';
import '../api/request_context.dart';
import '../result/result.dart';

/// Where the resident stands on the selfie's biometric consent (D-209).
sealed class BiometricConsentStatus {
  const BiometricConsentStatus();
}

/// The first read has not answered.
final class BiometricConsentChecking extends BiometricConsentStatus {
  const BiometricConsentChecking();
}

/// Taytay LGU has not published the consent text, so the server takes no
/// selfie from anybody (`biometric_consent_version` is null). Nothing can be
/// agreed to; verifying in person is the way on (D-210).
final class BiometricConsentUnavailable extends BiometricConsentStatus {
  const BiometricConsentUnavailable();
}

/// A text is published and the resident has not agreed to it (or agreed to an
/// older version, or withdrew).
final class BiometricConsentOwed extends BiometricConsentStatus {
  const BiometricConsentOwed({required this.version, required this.text});

  /// `biometric_consent_version` from `GET /app/config`: what is recorded.
  final String version;

  /// `biometric_consent` from `GET /app/config`: what the resident reads.
  final PublishedText text;
}

/// The resident's consent stands for the version published now: the one
/// condition under which the server takes a selfie.
final class BiometricConsentGiven extends BiometricConsentStatus {
  const BiometricConsentGiven({
    required this.version,
    required this.text,
    this.acceptedAt,
  });

  final String version;
  final PublishedText text;
  final DateTime? acceptedAt;
}

/// A read failed. Nothing is assumed: no selfie is offered and the screen
/// offers to try again.
final class BiometricConsentFailed extends BiometricConsentStatus {
  const BiometricConsentFailed(this.failure);

  final AppFailure failure;
}

/// Reads, records and withdraws the biometric consent a selfie needs.
///
/// ---
///
/// **The server decides.** Whether a consent stands is
/// `GET /me/consents/current` `biometric.up_to_date`, exactly the condition
/// under which `POST /me/verification-requests` and a selfie on
/// `/current/documents` are accepted (backend `44cae1b`). The app reads the
/// text from `GET /app/config` and never takes a selfie it knows would be
/// refused.
///
/// **Deny by default** (D-32). Until both reads answer, and whenever either
/// fails, no selfie is offered.
///
/// One per screen, never in long-lived state: it holds no personal data, and
/// a resident who withdraws on one screen is read afresh by the next.
class BiometricConsentController extends ChangeNotifier {
  BiometricConsentController({
    required PlatformRepository platform,
    required AccountControlsRepository consents,
    Future<Result<MunicipalOffice?>> Function()? inPersonOffice,
  }) : _platform = platform,
       _consents = consents,
       _inPersonOffice = inPersonOffice;

  final PlatformRepository _platform;
  final AccountControlsRepository _consents;
  final Future<Result<MunicipalOffice?>> Function()? _inPersonOffice;

  BiometricConsentStatus _status = const BiometricConsentChecking();
  bool _recording = false;
  AppFailure? _recordFailure;
  MunicipalOffice? _office;
  bool _officeAsked = false;
  bool _disposed = false;
  int _generation = 0;

  BiometricConsentStatus get status => _status;

  /// Whether the server would take a selfie now.
  bool get allowsSelfie => _status is BiometricConsentGiven;

  /// Whether [agree] or [withdraw] is waiting for the server.
  bool get isRecording => _recording;

  /// Why the last [agree] or [withdraw] did not finish.
  AppFailure? get recordFailure => _recordFailure;

  /// The office that verifies in person, from the directory, once read. Null
  /// until then, or when the directory has no such office: the note then
  /// names it without an address (D-210).
  MunicipalOffice? get inPersonOffice => _office;

  /// Reads the published text and where the resident stands on it.
  Future<void> load() async {
    final int generation = ++_generation;
    if (_status is! BiometricConsentChecking) {
      _status = const BiometricConsentChecking();
      _notify();
    }
    final Result<AppBootstrap> config = await _platform.loadBootstrap();
    if (generation != _generation || _disposed) return;
    final AppBootstrap? current = config.valueOrNull;
    if (current == null) {
      _settle(
        BiometricConsentFailed(
          config.failureOrNull ?? const UnexpectedFailure(),
        ),
      );
      return;
    }
    final String published = current.biometricConsentVersion.trim();
    if (published.isEmpty || !current.biometricConsent.isPublished) {
      _settle(const BiometricConsentUnavailable());
      return;
    }
    final Result<ConsentState> state = await _consents.loadConsentState();
    if (generation != _generation || _disposed) return;
    switch (state) {
      case Err<ConsentState>(:final AppFailure failure):
        _settle(BiometricConsentFailed(failure));
      case Ok<ConsentState>(:final ConsentState value):
        final ConsentStanding standing = value.biometric;
        // The server's own published version wins over the config's when
        // they disagree: it is the one a selfie is checked against.
        final String version = standing.publishedVersion ?? '';
        if (version.isEmpty) {
          _settle(const BiometricConsentUnavailable());
        } else if (standing.upToDate) {
          _settle(
            BiometricConsentGiven(
              version: version,
              text: current.biometricConsent,
              acceptedAt: standing.consent?.grantedAt,
            ),
          );
        } else {
          _settle(
            BiometricConsentOwed(
              version: version,
              text: current.biometricConsent,
            ),
          );
        }
    }
  }

  /// Reads the in-person office once, for the note that offers that way.
  Future<void> loadInPersonOffice() async {
    final Future<Result<MunicipalOffice?>> Function()? read = _inPersonOffice;
    if (read == null || _officeAsked) return;
    _officeAsked = true;
    final Result<MunicipalOffice?> office = await read();
    if (_disposed) return;
    _office = office.valueOrNull;
    _notify();
  }

  /// Records the resident's agreement to the version they were shown. True
  /// only when the server confirmed it.
  Future<bool> agree() async {
    final BiometricConsentStatus owed = _status;
    if (owed is! BiometricConsentOwed || _recording) return false;
    _recording = true;
    _recordFailure = null;
    _notify();
    final Result<ConsentRecord> result = await _consents.acceptConsent(
      version: owed.version,
      kind: ConsentKind.biometric,
    );
    if (_disposed) return false;
    _recording = false;
    switch (result) {
      case Ok<ConsentRecord>(:final ConsentRecord value)
          when value.kind == ConsentKind.biometric &&
              value.key.trim() == owed.version &&
              value.isActive:
        _status = BiometricConsentGiven(
          version: owed.version,
          text: owed.text,
          acceptedAt: value.grantedAt,
        );
        _notify();
        return true;
      case Ok<ConsentRecord>():
        _recordFailure = const ContractFailure(
          debugMessage: 'Consent answer did not confirm the version.',
        );
        _notify();
        return false;
      case Err<ConsentRecord>(:final AppFailure failure):
        _recordFailure = failure;
        _notify();
        // 409: the text was taken down; 422: another version is published
        // now. Either way the resident must read again what stands.
        if (failure is ConflictFailure || failure is ValidationFailure) {
          await load();
        }
        return false;
    }
  }

  /// Withdraws the consent. The server erases the account's selfies in the
  /// same act. True only when the server confirmed the withdrawal.
  Future<bool> withdraw() async {
    final BiometricConsentStatus given = _status;
    if (given is! BiometricConsentGiven || _recording) return false;
    _recording = true;
    _recordFailure = null;
    _notify();
    final Result<ConsentRecord> result = await _consents.withdrawConsent(
      key: given.version,
      idempotencyKey: generateIdempotencyKey(),
      kind: ConsentKind.biometric,
    );
    if (_disposed) return false;
    _recording = false;
    switch (result) {
      case Ok<ConsentRecord>():
        _notify();
        await load();
        return true;
      case Err<ConsentRecord>(:final AppFailure failure):
        _recordFailure = failure;
        _notify();
        return false;
    }
  }

  /// The server refused a selfie for want of consent: what this screen knew
  /// is stale, so it is read again.
  Future<void> refusedForConsent() => load();

  void _settle(BiometricConsentStatus status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
