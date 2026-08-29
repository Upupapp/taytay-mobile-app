import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/verification/data/kyc_api_repository.dart';
import 'package:taytay_resident/features/verification/domain/verification_status_detail.dart';

/// Two sections of the verification screen cannot render, and their tests pass.
///
/// ## What this is about
///
/// `verification_screen.dart` draws a "What Taytay LGU has from you" card from
/// `status.submittedCategories` and a corrections list from `status.issues`.
/// **Neither list is populated by any production code.** `applicantProjection`
/// in `KycController` serves exactly seven things at
/// `backend@api-baseline-2026-08` — `id`, `status`, `can_edit`, `submitted_at`,
/// `message`, `claimed`, `resident_id` — and none of them is a category list or
/// an issue list. So both sections sit behind an `isNotEmpty` check that is
/// always false, on every device.
///
/// `verification_screen_test.dart` builds those lists directly and passes. That
/// is the trap worth naming: **the widgets are proven to work and nothing was
/// proving they are ever reached.** A green suite meant "this renders correctly
/// when given data", and was read as "this renders".
///
/// ## Why the client cannot simply fix it
///
/// It is tempting to build the category list from `claimed`, which the server
/// does send. That would be the wrong fix twice over. `claimed` carries the
/// resident's actual submitted *values* — names, birth date — whereas
/// `submittedCategories` is a privacy-safe summary of the *kinds* of
/// information held. Re-displaying the values is a different, more exposing
/// feature than the one the card was designed for, and the categories cannot be
/// derived from anything on the wire. The server has to publish them.
///
/// So this file does not fix anything. It stops the deadness being invisible,
/// and it turns red the day **the client starts decoding** one of these lists —
/// at which point `VerificationItemCategory` needs localising, since it is only
/// excused from translation because nobody can read it.
///
/// It does **not** notice the server growing the field: the decoder allow-lists
/// its keys, so an unknown one is walked past in silence. Closing that would
/// mean diffing the live projection against the pin, which is
/// `check_fixture_drift.sh`'s job and is unproven while `TAYTAY_STAGING` is
/// unset. Named here so the green tick is not read as more than it is.
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

  test('the whole applicant projection still leaves both lists empty', () async {
    // Every field `applicantProjection` sends at the pinned baseline, copied
    // from the controller rather than imagined.
    //
    // WHAT THIS TEST DOES NOT DO, corrected before it was committed. The first
    // draft claimed "if the server ever grows a category list, this fixture is
    // where it lands first". That is false, and red-proofing it showed why:
    // adding `submitted_categories` to this payload changes nothing, because
    // the decoder allow-lists the keys it reads and walks past the rest by
    // design. A server-side addition is invisible here.
    //
    // So this test documents the decode, and only the ratchet below has teeth.
    // Writing it down because a file about checks that promise more than they
    // deliver is a poor place to add a fifth.
    final detail = await decode(<String, dynamic>{
      'id': 'case-uuid',
      'status': 'needs_more_information',
      'can_edit': true,
      'submitted_at': '2026-08-18T04:00:00Z',
      'message': 'Please resend a clearer photo of your ID.',
      'claimed': <String, dynamic>{
        'first_name': 'Ana',
        'middle_name': 'Reyes',
        'last_name': 'Santos',
        'suffix': null,
        'birth_date': '1990-04-02',
      },
      'resident_id': 'res-1',
    });

    // The fields that DO arrive are read — this is not a broken decoder.
    expect(detail.canEdit, isTrue);
    expect(detail.submittedAt, isNotNull);
    expect(detail.residentGuidance, isNotNull);

    // And these two are not, because nothing sends them.
    expect(
      detail.submittedCategories,
      isEmpty,
      reason:
          'A category list arrived. That is good news, not a failure: wire it '
          'up, and localise VerificationItemCategory, which is excused from '
          'translation only because this list is always empty.',
    );
    expect(
      detail.issues,
      isEmpty,
      reason:
          'An issue list arrived. Wire up the corrections section and re-read '
          'the note in resident_copy_localisation_test.dart.',
    );
  });

  test('no production code populates either list', () {
    // The ratchet. The test above proves one payload does not populate them;
    // this proves nothing anywhere does, which is the claim that matters.
    final List<String> producers = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The declaration itself names both fields; it is not a producer.
      if (entity.path.endsWith('verification_status_detail.dart')) continue;

      final source = entity
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');

      // `issues:` alone is not specific enough — `app_config.dart` has a
      // `ConfigIssue` list under the same name and was the first thing this
      // caught. A producer has to be naming the type it is constructing.
      if (!source.contains('VerificationStatusDetail')) continue;

      for (final field in <String>['submittedCategories:', 'issues:']) {
        if (source.contains(field)) {
          producers.add('${entity.path}  $field');
        }
      }
    }

    expect(
      producers,
      isEmpty,
      reason:
          'Something now populates one of these lists, so the verification '
          'screen has come alive. Localise VerificationItemCategory and remove '
          'its entry from knownUntranslated:\n${producers.join('\n')}',
    );
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
