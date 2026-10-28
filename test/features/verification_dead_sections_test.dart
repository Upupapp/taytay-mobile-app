import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';

/// The citizen verification payload now carries `submitted_categories` and
/// `issues`. The decoder reads both. A payload that omits them still leaves
/// the lists empty, and staff `notes` are not a stand-in for either.
void main() {
  AppConfig config() => AppConfig.from(
    rawEnvironment: 'dev',
    rawApiBaseUrl: 'https://example.test/api/v1',
    isReleaseBuild: false,
  );

  Future<VerificationStatusDetail> decode(Map<String, dynamic> body) async {
    final repository = KycApiRepository(
      apiClient: ApiClient(
        config: config(),
        transport: _OneResponse(body),
        accessTokenProvider: () async => 'tok',
      ),
    );
    return (await repository.loadOwnStatusDetail()).valueOrNull!;
  }

  test('a payload without the lists still leaves them empty', () async {
    final detail = await decode(<String, dynamic>{
      'id': 'case-uuid',
      'status': 'pending',
      'can_edit': true,
      'submitted_at': '2026-08-18T04:00:00Z',
      'message': 'Please resend a clearer photo of your ID.',
      'notes': 'staff-only',
    });

    expect(detail.canEdit, isTrue);
    expect(detail.submittedAt, isNotNull);
    expect(detail.residentGuidance, isNotNull);
    expect(detail.residentGuidance, isNot(contains('staff-only')));
    expect(detail.submittedCategories, isEmpty);
    expect(detail.issues, isEmpty);
  });

  test('the decoder is what fills the citizen lists', () {
    final String decoder = File(
      'lib/features/verification/data/kyc_api_repository.dart',
    ).readAsStringSync();
    expect(decoder, contains('submittedCategories:'));
    expect(decoder, contains('issues:'));
    expect(decoder, isNot(contains("['notes']")));

    final String screen = File(
      'lib/features/verification/presentation/verification_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('_noteLabel'));
    expect(screen, contains('allowsEdit'));
    expect(screen, isNot(contains("['notes']")));
  });

  test('the scan would notice a producer', () {
    // A scan that matches nothing passes everything. Proves the matcher works
    // without needing the codebase to be dirty.
    const sample = 'VerificationStatusDetail(submittedCategories: <X>[]);';
    expect(sample.contains('submittedCategories:'), isTrue);
    expect(
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .length,
      greaterThan(100),
      reason: 'Too few files scanned; the walk is wrong.',
    );
  });
}

class _OneResponse implements ApiTransport {
  _OneResponse(this.body);

  final Map<String, dynamic> body;

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      Ok<ApiHttpResponse>(
        ApiHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, dynamic>{'data': body}),
          headers: const <String, String>{'content-type': 'application/json'},
        ),
      );
}
