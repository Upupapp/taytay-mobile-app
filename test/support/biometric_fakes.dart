import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';
import 'package:taytay_resident/features/platform/domain/privacy_notice.dart';
import 'package:taytay_resident/features/settings/domain/account_controls.dart';

/// The synthetic selfie consent the tests publish.
const String sampleBiometricVersion = 'bio-sample-1';

/// The synthetic consent text. Obviously not the office's.
const String sampleBiometricBody =
    '# Sample selfie consent\nSAMPLE consent text written for a test.';

/// `GET /app/config` with the selfie consent published, or not.
AppBootstrap biometricBootstrap({bool published = true}) => AppBootstrap(
  service: '',
  apiVersion: '',
  timezone: 'Asia/Manila',
  channel: 'citizen-mobile',
  defaultPageSize: 25,
  minimumVersion: '',
  features: FeatureFlags.none,
  support: SupportContact.none,
  biometricConsentVersion: published ? sampleBiometricVersion : '',
  biometricConsent: published
      ? const BiometricConsentText(
          version: sampleBiometricVersion,
          bodyMarkdown: sampleBiometricBody,
        )
      : const BiometricConsentText(
          version: PublishedText.placeholderVersion,
          bodyMarkdown: 'Placeholder, never shown.',
        ),
);

/// `GET /app/config` answering [answer] every time.
class BiometricPlatform implements PlatformRepository {
  BiometricPlatform({bool published = true, Result<AppBootstrap>? answer})
    : answer =
          answer ?? Ok<AppBootstrap>(biometricBootstrap(published: published));

  Result<AppBootstrap> answer;
  int reads = 0;

  @override
  Future<Result<ServiceHealth>> checkHealth() async => const Ok<ServiceHealth>(
    ServiceHealth(service: 'taytay', status: 'ok', apiVersion: '1'),
  );

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async {
    reads++;
    return answer;
  }
}

/// Where the selfie consent starts.
enum BiometricStart { given, owed, unpublished }

/// `/me/consents` for the selfie consent, in memory.
class BiometricConsents implements AccountControlsRepository {
  BiometricConsents({BiometricStart start = BiometricStart.given})
    : _published = start != BiometricStart.unpublished,
      _held = start == BiometricStart.given
          ? record(sampleBiometricVersion)
          : null;

  static ConsentRecord record(String version, {DateTime? withdrawnAt}) =>
      ConsentRecord(
        key: version,
        kind: ConsentKind.biometric,
        label: 'Selfie consent',
        statement: 'Agreed that Taytay LGU may use your selfie',
        grantedAt: DateTime.utc(2026, 11, 2),
        withdrawnAt: withdrawnAt,
        isWithdrawable: true,
      );

  final bool _published;
  ConsentRecord? _held;

  /// A failure for the next state read, then cleared.
  AppFailure? stateFailure;

  /// A failure for the next acceptance, then cleared.
  AppFailure? acceptFailure;

  /// A failure for the next withdrawal, then cleared.
  AppFailure? withdrawFailure;

  final List<({String version, ConsentKind kind})> accepted =
      <({String version, ConsentKind kind})>[];
  final List<({String version, ConsentKind kind})> withdrawn =
      <({String version, ConsentKind kind})>[];
  int stateReads = 0;

  bool get holds => _held != null;

  @override
  Future<Result<AccountControls>> loadControls() async =>
      const Ok<AccountControls>(AccountControls(canWithdrawConsent: true));

  @override
  Future<Result<List<ConsentRecord>>> listConsents() async =>
      Ok<List<ConsentRecord>>(<ConsentRecord>[?_held]);

  @override
  Future<Result<ConsentState>> loadConsentState() async {
    stateReads++;
    final AppFailure? failure = stateFailure;
    if (failure != null) {
      stateFailure = null;
      return Err<ConsentState>(failure);
    }
    final ConsentRecord? held = _held;
    return Ok<ConsentState>(
      ConsentState(
        biometric: ConsentStanding(
          publishedVersion: _published ? sampleBiometricVersion : null,
          consent: held,
          upToDate:
              _published && held != null && held.key == sampleBiometricVersion,
        ),
      ),
    );
  }

  @override
  Future<Result<ConsentRecord>> acceptConsent({
    required String version,
    required ConsentKind kind,
  }) async {
    accepted.add((version: version, kind: kind));
    final AppFailure? failure = acceptFailure;
    if (failure != null) {
      acceptFailure = null;
      return Err<ConsentRecord>(failure);
    }
    final ConsentRecord row = record(version);
    _held = row;
    return Ok<ConsentRecord>(row);
  }

  @override
  Future<Result<ConsentRecord>> withdrawConsent({
    required String key,
    required String idempotencyKey,
    required ConsentKind kind,
  }) async {
    withdrawn.add((version: key, kind: kind));
    final AppFailure? failure = withdrawFailure;
    if (failure != null) {
      withdrawFailure = null;
      return Err<ConsentRecord>(failure);
    }
    _held = null;
    return Ok<ConsentRecord>(
      record(key, withdrawnAt: DateTime.utc(2026, 11, 12)),
    );
  }

  @override
  Future<Result<void>> requestDataCorrection({
    required String detail,
    required String idempotencyKey,
  }) async => const Ok<void>(null);

  @override
  Future<Result<void>> requestAccountClosure({
    required bool permanent,
    required String reason,
    required String idempotencyKey,
  }) async => const Ok<void>(null);
}
