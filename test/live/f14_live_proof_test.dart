@Tags(<String>['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/http_api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/registration/data/barangay_api_repository.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/kyc_claim.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';

/// F14, proven end to end by **this app's own repositories** against a running
/// API — not by curl, and not against a hand-built fixture.
///
/// ---
///
/// **Why this exists and the golden fixtures do not suffice.** A fixture proves
/// the app can decode a response somebody else obtained. It cannot prove the app
/// can *compose a request the server accepts*, and that is the entire content of
/// F14: `POST me/kyc` required a `barangay_id` — the `barangays` auto-increment
/// primary key — and no route published one, so every client was asked for an
/// identifier it had no way to obtain. The Verified tier, the digital ID and
/// every service resting on them were unreachable by construction.
///
/// This test reads the directory with [BarangayApiRepository], takes a `code`
/// from what came back, and opens a real KYC case with [KycApiRepository] using
/// nothing the server did not publish. If the integer key were still required,
/// or the app still sent one, it fails.
///
/// **Excluded from the ordinary suite**, and deliberately not silently skipped:
/// it needs a running API and a citizen bearer token, so it is tagged `live` and
/// `dart_test.yaml` excludes that tag by default. Run it with:
///
/// ```
/// TAYTAY_LIVE_API=http://127.0.0.1:8000/api/v1 \
/// TAYTAY_LIVE_TOKEN=<citizen token> \
///   flutter test --tags live test/live/f14_live_proof_test.dart
/// ```
///
/// A token is not committed and never should be. `qa-and-evidence.md` records
/// how the one used for the recorded run was obtained.
void main() {
  final String baseUrl = Platform.environment['TAYTAY_LIVE_API'] ?? '';
  final String token = Platform.environment['TAYTAY_LIVE_TOKEN'] ?? '';

  test('a resident opens a KYC case with only what the server published', () async {
    // Fails rather than skips. A live proof that quietly passes with no server
    // is worse than no live proof, because the launch dossier cites it.
    expect(
      baseUrl.isNotEmpty && token.isNotEmpty,
      isTrue,
      reason:
          'Set TAYTAY_LIVE_API and TAYTAY_LIVE_TOKEN. See the library doc above.',
    );

    final AppConfig config = AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: baseUrl,
      isReleaseBuild: false,
    );
    final ApiClient apiClient = ApiClient(
      config: config,
      transport: HttpApiTransport(config: config),
      accessTokenProvider: () async => token,
    );

    // ── the directory half ──────────────────────────────────────────────────
    final Result<List<Barangay>> directory = await BarangayApiRepository(
      apiClient: apiClient,
    ).listBarangays();
    final List<Barangay> barangays = (directory as Ok<List<Barangay>>).value;
    expect(barangays, isNotEmpty, reason: 'GET barangays served nothing');

    final Barangay chosen = barangays.first;
    // The two things F14 turned on: an identifier that is not the primary key,
    // and a code the KYC endpoint will accept.
    expect(chosen.id, isNot(matches(RegExp(r'^\d+$'))));
    expect(chosen.code, isNotNull);

    // ── the claim half ──────────────────────────────────────────────────────
    // Obviously synthetic (Article 5.6). This runs against a local integration
    // database seeded for exactly this.
    final Result<VerificationStatus> opened =
        await KycApiRepository(apiClient: apiClient).openCase(
          claim: KycClaim(
            givenName: 'Integration',
            familyName: 'Proof',
            birthDate: DateTime(1990, 3, 7),
            sex: ClaimedSex.female,
            barangayCode: chosen.code!,
            streetAddress: '1 Test Street',
          ),
          idempotencyKey: 'f14-live-proof',
        );

    expect(
      opened,
      isA<Ok<VerificationStatus>>(),
      reason: opened is Err<VerificationStatus>
          ? 'POST me/kyc refused the claim: ${opened.failure.debugMessage}'
          : null,
    );

    final VerificationStatus status = (opened as Ok<VerificationStatus>).value;
    // A case exists and the server named its state. Anything the app does not
    // recognise resolves to underReview, never to a state with an action in it.
    expect(status.rawState, isNotEmpty);
    expect(status.state, isNotNull);
  });
}
