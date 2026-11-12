import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/profile/data/resident_profile_api_repository.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_repository.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';
import 'package:taytay_resident/features/verification/presentation/manila_stamp.dart';
import 'package:taytay_resident/features/verification/presentation/verification_screen.dart';
import 'package:taytay_resident/features/verification/presentation/verification_status_pages.dart';

import '../support/layout_matrix.dart';
import 'verification_screen_test.dart' show bootVerification;

/// In-person verification (backend `5209f75`, D-210): a request closed by it
/// reads as replaced, and the verified page says how the account was verified.
void main() {
  ApiClient answering(Object? data) => ApiClient(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    accessTokenProvider: () async => 'sample-token',
    transport: _OneAnswer(
      ApiHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'data': data,
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
      ),
    ),
  );

  group('a superseded request', () {
    test('is its own final state, never "under review" or approved', () {
      final VerificationAttemptState state = VerificationAttemptState.parse(
        'superseded',
      );
      expect(state, VerificationAttemptState.superseded);
      expect(state.isTerminal, isTrue);
      expect(state.needsResidentAction, isFalse);
      final ResidentVerificationStage stage =
          ResidentVerificationStage.fromAttemptState(state);
      expect(stage, isNot(ResidentVerificationStage.verified));
      expect(stage, isNot(ResidentVerificationStage.pendingReview));
    });

    test(
      'decodes, is not the verified request, and keeps the erasure',
      () async {
        final VerificationStatusDetail detail = (await KycApiRepository(
          apiClient: answering(<String, Object?>{
            'id': 'req-1',
            'status': 'superseded',
            'id_type': 'passport',
            'submitted_at': '2026-11-01T02:00:00.000Z',
            'can_edit': false,
            'selfie_erased_at': '2026-11-12T03:00:00.000Z',
          }),
        ).loadOwnStatusDetail()).valueOrNull!;
        expect(detail.supersededInPerson, isTrue);
        // The card timeline (D-207) reads dates only from the verified request.
        expect(detail.isVerified, isFalse);
        expect(detail.selfieErased, isTrue);
      },
    );
  });

  group('verification_method on GET /me', () {
    Future<ResidentProfileDetail> decode(Object? method) async =>
        (await ResidentProfileApiRepository(
          apiClient: answering(<String, Object?>{
            'verification_status': 'verified',
            'verification_method': method,
          }),
        ).loadOwnDetail()).valueOrNull!;

    test('selfie, in person, none, or an unknown value never named', () async {
      expect(
        (await decode('in-person')).verificationMethod,
        VerificationMethod.inPerson,
      );
      expect(
        (await decode('selfie')).verificationMethod,
        VerificationMethod.selfie,
      );
      expect((await decode(null)).verificationMethod, isNull);
      expect((await decode('face-scan')).verificationMethod, isNull);
    });

    test('the words for each', () {
      expect(
        VerificationMethodCopy.of(VerificationMethod.inPerson),
        'Verified in person at the Taytay LGU office.',
      );
      expect(
        VerificationMethodCopy.of(VerificationMethod.selfie),
        'Verified with your valid ID and selfie.',
      );
      expect(VerificationMethodCopy.of(null), isEmpty);
    });
  });

  group('the verified page', () {
    testWidgets('says how, and what became of the selfie request', (
      tester,
    ) async {
      await bootVerification(
        tester,
        viaRouter: true,
        detail: VerificationStatusDetail(
          stage: ResidentVerificationStage.notStarted,
          rawState: 'superseded',
          selfieErasedAt: DateTime.utc(2026, 11, 12, 3),
        ),
        profile: _Profile(
          ResidentProfileDetail(
            verificationTier: 'verified',
            verificationMethod: VerificationMethod.inPerson,
            verificationDecidedAt: DateTime.utc(2026, 11, 12, 3),
          ),
        ),
      );
      expect(find.text('Your account is verified'), findsOneWidget);
      expect(
        find.textContaining(VerificationMethodCopy.inPerson),
        findsOneWidget,
      );
      expect(
        find.textContaining('Replaced: you were verified in person'),
        findsOneWidget,
      );
      expect(find.textContaining('selfie you sent was erased'), findsOneWidget);
      // The date is the account's decision, not a request's review.
      expect(
        find.textContaining(formatManilaDate(DateTime.utc(2026, 11, 12, 3))),
        findsOneWidget,
      );
    });

    testWidgets('a selfie verification says so, and nothing was replaced', (
      tester,
    ) async {
      await bootVerification(
        tester,
        viaRouter: true,
        detail: VerificationStatusDetail(
          stage: ResidentVerificationStage.verified,
          rawState: 'approved',
          reviewedAt: DateTime.utc(2026, 11, 3, 3),
        ),
        profile: const _Profile(
          ResidentProfileDetail(
            verificationTier: 'verified',
            verificationMethod: VerificationMethod.selfie,
          ),
        ),
      );
      expect(
        find.textContaining(VerificationMethodCopy.selfie),
        findsOneWidget,
      );
      expect(find.textContaining('Replaced'), findsNothing);
    });

    testWidgets('with the profile unread, a superseded request is not "not '
        'verified"', (tester) async {
      await bootVerification(
        tester,
        viaRouter: true,
        detail: const VerificationStatusDetail(
          stage: ResidentVerificationStage.notStarted,
          rawState: 'superseded',
        ),
        profile: const _Profile(ResidentProfileDetail()),
      );
      expect(find.text('Your account is verified'), findsOneWidget);
      expect(find.text('Start verification'), findsNothing);
    });

    testWidgets('fits 360/375/430 dp at 200% text with both lines', (
      tester,
    ) async {
      await expectCleanLayouts(
        tester,
        () => VerifiedStatusPage(
          verifiedOn: '12 Nov 2026',
          method: VerificationMethodCopy.inPerson,
          replaced: VerificationMethodCopy.replaced(erased: true),
        ),
        scrollable: false,
        height: 900,
      );
    });
  });

  group('the contract (vendored Node export, backend 5209f75)', () {
    final Map<String, dynamic> node =
        jsonDecode(
              File(
                'docs/integration/taytay-node-openapi.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final Map<String, dynamic> schemas =
        (node['components'] as Map<String, dynamic>)['schemas']
            as Map<String, dynamic>;
    Map<String, dynamic> property(String schema, String name) =>
        ((schemas[schema] as Map<String, dynamic>)['properties']
                as Map<String, dynamic>)[name]
            as Map<String, dynamic>;

    test('every request status the server sends has a state of its own', () {
      final List<String> statuses =
          (property('VerificationRequest', 'status')['enum'] as List<dynamic>)
              .cast<String>();
      expect(statuses, contains('superseded'));
      expect(
        VerificationAttemptState.parse('pending'),
        VerificationAttemptState.underReview,
      );
      for (final String status in statuses.where((s) => s != 'pending')) {
        expect(
          VerificationAttemptState.parse(status),
          isNot(VerificationAttemptState.underReview),
          reason: '$status falls to the unknown-state fallback',
        );
      }
    });

    test('verification_method is the set the app names, or null', () {
      final List<Object?> methods =
          property('UserProfile', 'verification_method')['enum']
              as List<dynamic>;
      expect(
        methods.whereType<String>().toSet(),
        VerificationMethod.values
            .map((VerificationMethod m) => m.wireValue)
            .toSet(),
      );
      expect(methods, contains(null));
    });
  });
}

class _Profile implements ResidentProfileRepository {
  const _Profile(this.detail);

  final ResidentProfileDetail detail;

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async =>
      Ok<ResidentProfileDetail>(detail);

  /// Home asks for the summary; this test reads none.
  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      const Err<ResidentProfileSummary>(NetworkFailure());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers the one request a decode test makes.
class _OneAnswer implements ApiTransport {
  _OneAnswer(this._response);

  final ApiHttpResponse _response;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(_response);
}
