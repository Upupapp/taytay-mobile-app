import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_envelope.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/programs/data/program_dto.dart';
import 'package:taytay_resident/features/programs/domain/assistance_program.dart';

/// Decodes responses **a real server produced** through the app's real decoders.
///
/// ---
///
/// **This is the test TAB 01 defined and could not run.** It reported that no
/// staging API existed and no PHP toolchain was on the machine, shipped the
/// recorder and the drift check unfed, and made CI skip them loudly rather than
/// pass. Every TAB from 01 to 24 then repeated the caveat that nothing had been
/// exercised against a running backend.
///
/// The toolchain claim was taken from a document and never checked. PHP 8.4 and
/// Composer are on this machine via Herd; the backend boots against sqlite and
/// serves in about six seconds. The fixtures under `fixtures/` were recorded from
/// it — every one carries the endpoint, the baseline tag and the capture date.
///
/// **What this proves that the schema tests do not.** Conformance against
/// `openapi.json` proves the app matches what the server *publishes*. This
/// proves it matches what the server *sends*, and those differ: the first thing
/// this found was `GET newsfeed` answering 401 to a guest on a route with no
/// `auth:sanctum`, because the controller gates anonymous readers on a feature
/// flag that defaults off.
void main() {
  Map<String, dynamic> fixture(String name) {
    final File file = File('test/contract/fixtures/$name.json');
    expect(
      file.existsSync(),
      isTrue,
      reason:
          '$name.json is missing. Record fixtures with tool/record_fixtures.sh '
          'against a running API.',
    );
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  ApiHttpResponse responseFrom(Map<String, dynamic> f) => ApiHttpResponse(
    statusCode: f['status'] as int,
    body: jsonEncode(f['body']),
    headers: const <String, String>{'x-request-id': 'req-fixture'},
  );

  group('every fixture records what it is and when', () {
    test('endpoint, baseline tag and capture date are stamped', () {
      final List<File> files = Directory('test/contract/fixtures')
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.json'))
          .toList();

      expect(files, isNotEmpty, reason: 'no fixtures recorded');

      for (final File file in files) {
        final Map<String, dynamic> f =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(f['endpoint'], isNotNull, reason: file.path);
        expect(f['baseline_tag'], 'api-baseline-2026-08', reason: file.path);
        expect(f['captured'], isNotNull, reason: file.path);
      }
    });

    test('no fixture carries anything shaped like a government identifier', () {
      // The recorder refuses to write one and deletes the file if it slips
      // through. This is the same check, held at rest, because a fixture is a
      // permanent copy in a public repository.
      final RegExp identifier = RegExp(
        r'(\+?63|0)9[0-9]{9}|[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}',
      );
      for (final FileSystemEntity entity in Directory(
        'test/contract/fixtures',
      ).listSync()) {
        if (entity is! File) continue;
        expect(
          identifier.hasMatch(entity.readAsStringSync()),
          isFalse,
          reason: entity.path,
        );
      }
    });
  });

  group('the app decodes what the server actually sent', () {
    test('app/bootstrap decodes to a usable startup contract', () {
      final Map<String, dynamic> f = fixture('app_bootstrap');
      expect(f['status'], 200);

      final Map<String, dynamic> data =
          (f['body'] as Map<String, dynamic>)['data'] as Map<String, dynamic>;

      // Every field the app reads, present in a real response.
      for (final String key in <String>[
        'service',
        'api_version',
        'server_time',
        'timezone',
        'client',
        'features',
        'support',
      ]) {
        expect(data.containsKey(key), isTrue, reason: key);
      }

      final Map<String, dynamic> client =
          data['client'] as Map<String, dynamic>;
      expect(client['channel'], 'citizen-mobile');
      // Empty means no minimum, which the app must read as "let them in".
      expect(client['minimum_version'], '');
      expect(
        SupportedVersion.compare(
          appVersion: '1.0.0',
          minimum: client['minimum_version'] as String,
        ),
        SupportedVersion.supported,
      );

      // The flag TAB 06 depends on, off in a fresh environment as expected.
      expect((data['features'] as Map<String, dynamic>)['digital_id'], false);
    });

    test('the real default page size is 15, not the 25 the app assumes', () {
      // Recorded rather than corrected here. The app clamps and sends its own
      // per_page, so nothing is broken — but the server publishes a per-channel
      // default and this app ignores it, which means a page size chosen for
      // citizen-mobile by the backend is overridden by a number chosen in a
      // client. Worth a decision rather than a silent divergence.
      final Map<String, dynamic> data =
          ((fixture('app_bootstrap')['body'] as Map<String, dynamic>)['data']
              as Map<String, dynamic>);
      expect((data['client'] as Map<String, dynamic>)['default_page_size'], 15);
    });

    test('the envelope decoder reads a real services page', () {
      final Result<ApiEnvelope<List<dynamic>>> result =
          ApiEnvelopeDecoder.decode<List<dynamic>>(
            responseFrom(fixture('services')),
            (Object? data) => data! as List<dynamic>,
          );

      expect(result, isA<Ok<ApiEnvelope<List<dynamic>>>>());
      final ApiEnvelope<List<dynamic>> envelope =
          (result as Ok<ApiEnvelope<List<dynamic>>>).value;
      expect(envelope.data, isNotEmpty);
      expect(envelope.requestId, isNotNull);
      // Collections are always paginated, and this is the first time that has
      // been checked against a real one rather than a hand-built map.
      expect(envelope.pagination, isNotNull);
      expect(envelope.pagination!.perPage, greaterThan(0));
    });

    test('a real programmes page decodes through ProgramDto', () {
      final Result<ApiEnvelope<List<dynamic>>> result =
          ApiEnvelopeDecoder.decode<List<dynamic>>(
            responseFrom(fixture('programs')),
            (Object? data) => data! as List<dynamic>,
          );

      final List<dynamic> rows =
          (result as Ok<ApiEnvelope<List<dynamic>>>).value.data;
      final List<AssistanceProgram> decoded = ProgramDto.decodeAll(rows);

      // TAB 07 re-modelled this against the controller's citizenProjection.
      // Nothing had ever confirmed the re-modelling against a response.
      expect(
        decoded.length,
        rows.length,
        reason: 'a real programme row failed to decode',
      );
      for (final AssistanceProgram program in decoded) {
        expect(program.id, isNotEmpty);
        expect(program.code, isNotEmpty);
        expect(program.name, isNotEmpty);
      }
    });

    test('a real 401 decodes to an unauthenticated failure', () {
      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        responseFrom(fixture('me')),
        (Object? _) {},
      );
      expect(
        (result as Err<ApiEnvelope<void>>).failure,
        isA<UnauthenticatedFailure>(),
      );
    });

    test('a real 404 decodes to not-found, with nothing operator-facing', () {
      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        responseFrom(fixture('no-such-endpoint')),
        (Object? _) {},
      );
      final AppFailure failure = (result as Err<ApiEnvelope<void>>).failure;
      expect(failure, isA<NotFoundFailure>());
      expect(failure.residentMessage, isNot(contains('endpoint')));
    });
  });

  group('F30 — the newsfeed is not unconditionally public', () {
    test('a guest is refused, on a route with no auth middleware', () {
      // The finding that only a live call could produce. `Route::get('newsfeed')`
      // sits outside the auth group, and `NewsfeedController::assertReadable`
      // refuses an anonymous reader unless `newsfeed.public_access` is on — which
      // defaults off. Reading the route file says public; calling it says 401.
      final Map<String, dynamic> f = fixture('newsfeed');
      expect(
        f['status'],
        401,
        reason:
            'If this is now 200, the deployment has NEWSFEED_PUBLIC on. The app '
            'handles both, but the launch scope should say which is intended.',
      );

      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        responseFrom(f),
        (Object? _) {},
      );
      expect(
        (result as Err<ApiEnvelope<void>>).failure,
        isA<UnauthenticatedFailure>(),
      );
    });
  });
}
