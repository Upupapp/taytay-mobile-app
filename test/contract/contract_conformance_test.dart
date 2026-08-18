import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_envelope.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/backend_baseline.dart';
import 'package:taytay_resident/core/result/result.dart';

/// Conformance against the **published contract**, not against this app's own
/// beliefs about it.
///
/// ---
///
/// Every assertion below is derived from `test/contract/openapi.json`, vendored
/// from the backend at `api-baseline-2026-08`. That direction matters. The app's
/// envelope handling is already correct and has been since it was written; these
/// tests do not exist to discover that. They exist because thirteen repositories
/// are about to be wired against this envelope by TABs 02–13, and the cheapest
/// moment to notice a divergence is before any of them is written rather than
/// after all of them are.
///
/// **The F05 exception is lifted.** The Master Command's TAB 01 §2 forbids using
/// the published error enum as the source for the app's codes, because both
/// backend generators emitted the PHP enum case name (`ValidationFailed`) where
/// the wire carries the backing value (`VALIDATION_FAILED`). That defect is
/// fixed at this baseline — `eec71e6`, "publish the contract the API actually
/// serves" — so the published enum is now the authority and this file uses it as
/// one. The prohibition is recorded as lifted in
/// `docs/integration/backend-baseline.md`, with the commit that lifted it, so
/// nobody reinstates it from the PDF.
void main() {
  final Map<String, dynamic> contract =
      jsonDecode(File('test/contract/openapi.json').readAsStringSync())
          as Map<String, dynamic>;

  final Map<String, dynamic> components =
      contract['components'] as Map<String, dynamic>;

  Map<String, dynamic> schema(String name) =>
      (components['schemas'] as Map<String, dynamic>)[name]
          as Map<String, dynamic>;

  List<String> required(Map<String, dynamic> node) =>
      ((node['required'] as List<dynamic>?) ?? <dynamic>[]).cast<String>();

  ApiHttpResponse json(
    int status,
    Object body, {
    Map<String, String>? headers,
  }) => ApiHttpResponse(
    statusCode: status,
    body: jsonEncode(body),
    headers: headers ?? const <String, String>{'x-request-id': 'req-1'},
  );

  group('the vendored contract is the one we baselined', () {
    test('it is OpenAPI 3.1 for the v1 API', () {
      expect(contract['openapi'], startsWith('3.1'));
      expect((contract['info'] as Map<String, dynamic>)['version'], 'v1');
    });

    test('the capture is recorded next to it', () {
      final String notes = File('test/contract/README.md').readAsStringSync();
      expect(notes, contains(backendBaselineTag));
      expect(notes, contains(backendBaselineCommit));
    });
  });

  group('error codes — the drift test that keeps F04 closed', () {
    List<String> publishedCodes() {
      final Map<String, dynamic> error = schema('Error');
      final Map<String, dynamic> inner =
          (error['properties'] as Map<String, dynamic>)['error']
              as Map<String, dynamic>;
      final Map<String, dynamic> code =
          (inner['properties'] as Map<String, dynamic>)['code']
              as Map<String, dynamic>;
      return (code['enum'] as List<dynamic>).cast<String>();
    }

    test('the app knows every code the backend publishes', () {
      final Set<String> known = ApiErrorCode.values
          .map((ApiErrorCode c) => c.wireValue)
          .toSet();

      for (final String published in publishedCodes()) {
        expect(
          known,
          contains(published),
          reason:
              'The backend publishes $published and this app does not know it, '
              'so it decodes to UNKNOWN and the resident is told "something '
              'went wrong". Add it to ApiErrorCode and give it copy.',
        );
      }
    });

    test('the app invents no code the backend does not publish', () {
      final Set<String> published = publishedCodes().toSet();

      for (final ApiErrorCode code in ApiErrorCode.values) {
        // UNKNOWN is this app's own forward-compatibility fallback and is
        // deliberately absent from the contract — a new server code must never
        // crash a released build (Article 8).
        if (code == ApiErrorCode.unknown) continue;
        expect(
          published,
          contains(code.wireValue),
          reason:
              '${code.wireValue} is not in the published contract. Either the '
              'backend removed it — in which case the branch behind it is dead '
              'code — or it was never real.',
        );
      }
    });

    test('the wire values are SCREAMING_SNAKE_CASE, not PHP case names', () {
      // The exact shape of F05. If a future backend regenerates with `->name`
      // this goes red here rather than silently in every client's error branch.
      for (final String code in publishedCodes()) {
        expect(
          code,
          matches(RegExp(r'^[A-Z][A-Z_]*$')),
          reason: '$code looks like a PHP enum case name, not a wire value',
        );
      }
    });

    test('every published code maps to a failure that is not "unexpected"', () {
      // A code the taxonomy has no opinion about is a code whose resident copy
      // is "something went wrong" — which is what F04 was.
      const Set<String> deliberatelyUnexpected = <String>{
        'BAD_REQUEST',
        'METHOD_NOT_ALLOWED',
      };

      for (final String wire in publishedCodes()) {
        if (deliberatelyUnexpected.contains(wire)) continue;
        final AppFailure failure = failureFromApiError(
          statusCode: 400,
          code: ApiErrorCode.parse(wire),
        );
        expect(
          failure,
          isNot(isA<UnexpectedFailure>()),
          reason: '$wire falls through to UnexpectedFailure',
        );
      }
    });
  });

  group('the success envelope matches what the contract publishes', () {
    test('Meta requires request_id and is additive', () {
      final Map<String, dynamic> meta = schema('Meta');
      expect(required(meta), contains('request_id'));
      expect(
        (meta['description'] as String).toLowerCase(),
        contains('additive'),
      );
    });

    test('Pagination publishes all five keys, all required', () {
      expect(
        required(schema('Pagination')),
        containsAll(<String>[
          'page',
          'per_page',
          'total',
          'total_pages',
          'has_more',
        ]),
      );
    });

    test('a collection response requires pagination in meta', () {
      final Map<String, dynamic> paginated = schema('PaginatedMeta');
      final List<dynamic> parts = paginated['allOf'] as List<dynamic>;
      final bool requiresPagination = parts
          .whereType<Map<String, dynamic>>()
          .any((Map<String, dynamic> p) => required(p).contains('pagination'));
      expect(requiresPagination, isTrue);
    });

    test('no response carries a `success` flag', () {
      // The status line carries success or failure. A body-level flag is a
      // second source of truth about the same fact, and the one clients read.
      expect(jsonEncode(contract).contains('"success"'), isFalse);
    });

    test('the decoder reads a success envelope shaped like the contract', () {
      final Result<ApiEnvelope<String>> result =
          ApiEnvelopeDecoder.decode<String>(
            json(200, <String, Object?>{
              'data': 'value',
              'meta': <String, Object?>{'request_id': 'req-42'},
            }),
            (Object? data) => data! as String,
          );

      expect(result, isA<Ok<ApiEnvelope<String>>>());
      final ApiEnvelope<String> envelope =
          (result as Ok<ApiEnvelope<String>>).value;
      expect(envelope.data, 'value');
      expect(envelope.requestId, 'req-42');
      expect(envelope.pagination, isNull);
    });

    test('the decoder reads pagination from meta', () {
      final Result<ApiEnvelope<List<dynamic>>> result =
          ApiEnvelopeDecoder.decode<List<dynamic>>(
            json(200, <String, Object?>{
              'data': <dynamic>[],
              'meta': <String, Object?>{
                'request_id': 'req-42',
                'pagination': <String, Object?>{
                  'page': 2,
                  'per_page': 25,
                  'total': 51,
                  'total_pages': 3,
                  'has_more': true,
                },
              },
            }),
            (Object? data) => data! as List<dynamic>,
          );

      final ApiEnvelope<List<dynamic>> envelope =
          (result as Ok<ApiEnvelope<List<dynamic>>>).value;
      expect(envelope.pagination!.page, 2);
      expect(envelope.pagination!.perPage, 25);
      expect(envelope.pagination!.total, 51);
      expect(envelope.pagination!.totalPages, 3);
      expect(envelope.pagination!.hasMore, isTrue);
    });

    test('unknown meta keys are ignored, never rejected', () {
      // `Meta` is declared additive and clients must tolerate new keys. A client
      // that rejects them turns every future backend release into an outage.
      final Result<ApiEnvelope<String>> result =
          ApiEnvelopeDecoder.decode<String>(
            json(200, <String, Object?>{
              'data': 'value',
              'meta': <String, Object?>{
                'request_id': 'req-42',
                'a_key_from_a_later_release': <String, Object?>{'nested': true},
                'another': 7,
              },
            }),
            (Object? data) => data! as String,
          );

      expect(result, isA<Ok<ApiEnvelope<String>>>());
      expect((result as Ok<ApiEnvelope<String>>).value.requestId, 'req-42');
    });
  });

  group('the error envelope matches what the contract publishes', () {
    test('Error requires code and message', () {
      final Map<String, dynamic> inner =
          (schema('Error')['properties'] as Map<String, dynamic>)['error']
              as Map<String, dynamic>;
      expect(required(inner), containsAll(<String>['code', 'message']));
    });

    test('every documented error response references the Error schema', () {
      final Map<String, dynamic> responses =
          components['responses'] as Map<String, dynamic>;
      expect(responses, isNotEmpty);

      responses.forEach((String name, dynamic node) {
        final String encoded = jsonEncode(node);
        expect(
          encoded,
          contains('#/components/schemas/Error'),
          reason: '$name does not use the error envelope',
        );
      });
    });

    test('the decoder branches on code, never on message', () {
      // Same status, same message, different code — different failure. If this
      // ever passes by reading the message, it will pass here and be wrong on
      // the first backend reword.
      AppFailure decode(String code) {
        final Result<ApiEnvelope<void>> result =
            ApiEnvelopeDecoder.decode<void>(
              json(409, <String, Object?>{
                'error': <String, Object?>{
                  'code': code,
                  'message': 'identical operator text',
                  'request_id': 'req-9',
                },
              }),
              (Object? _) {},
            );
        return (result as Err<ApiEnvelope<void>>).failure;
      }

      expect(decode('CONFLICT'), isA<ConflictFailure>());
      expect(
        (decode('INVALID_STATE_TRANSITION') as ConflictFailure)
            .isInvalidStateTransition,
        isTrue,
      );
    });

    test('request_id survives onto the failure for the support desk', () {
      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        json(
          500,
          <String, Object?>{
            'error': <String, Object?>{
              'code': 'SERVER_ERROR',
              'message': 'operator text',
              'request_id': 'req-from-body',
            },
          },
          headers: const <String, String>{'x-request-id': 'req-from-header'},
        ),
        (Object? _) {},
      );

      expect(
        (result as Err<ApiEnvelope<void>>).failure.requestId,
        'req-from-body',
      );
    });

    test('validation details decode as field -> messages', () {
      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        json(422, <String, Object?>{
          'error': <String, Object?>{
            'code': 'VALIDATION_FAILED',
            'message': 'The given data was invalid.',
            'details': <String, Object?>{
              'mobile_number': <String>['That number is not valid.'],
            },
          },
        }),
        (Object? _) {},
      );

      final ValidationFailure failure =
          (result as Err<ApiEnvelope<void>>).failure as ValidationFailure;
      expect(failure.firstErrorFor('mobile_number'), isNotNull);
    });

    test('a body that is not JSON is a contract failure, not a server fault', () {
      // The captive-portal and reverse-proxy case: a login page or an nginx 413
      // arrives where the envelope should be. Reporting it as a server error
      // sends somebody to a barangay hall over their own wifi.
      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        const ApiHttpResponse(
          statusCode: 200,
          body: '<html><body>Sign in to this network</body></html>',
        ),
        (Object? _) {},
      );

      expect(
        (result as Err<ApiEnvelope<void>>).failure,
        isA<ContractFailure>(),
      );
    });

    test('an unknown future code degrades and keeps the status meaningful', () {
      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        json(503, <String, Object?>{
          'error': <String, Object?>{
            'code': 'A_CODE_FROM_A_LATER_RELEASE',
            'message': 'operator text',
          },
        }),
        (Object? _) {},
      );

      expect(result, isA<Err<ApiEnvelope<void>>>());
      expect((result as Err<ApiEnvelope<void>>).failure, isA<ServerFailure>());
    });
  });

  group('the error seam covers the statuses thirteen repositories will meet', () {
    // The Master Command's TAB 01 trap: do not let the harness only test the
    // happy path. These are the responses the newly wired repositories are most
    // likely to get wrong, asserted as decoded failures rather than as fixtures
    // of a server nobody can reach from here.
    const Map<int, String> byStatus = <int, String>{
      401: 'UNAUTHENTICATED',
      403: 'FORBIDDEN',
      404: 'NOT_FOUND',
      409: 'CONFLICT',
      413: 'PAYLOAD_TOO_LARGE',
      415: 'UNSUPPORTED_MEDIA_TYPE',
      422: 'VALIDATION_FAILED',
      429: 'RATE_LIMITED',
      503: 'SERVICE_UNAVAILABLE',
    };

    for (final MapEntry<int, String> entry in byStatus.entries) {
      test('${entry.key} ${entry.value} decodes to a typed failure', () {
        final Result<ApiEnvelope<void>> result =
            ApiEnvelopeDecoder.decode<void>(
              json(entry.key, <String, Object?>{
                'error': <String, Object?>{
                  'code': entry.value,
                  'message': 'operator text',
                  'request_id': 'req-1',
                },
              }),
              (Object? _) {},
            );

        final AppFailure failure = (result as Err<ApiEnvelope<void>>).failure;
        expect(failure, isNot(isA<UnexpectedFailure>()));
        expect(failure.requestId, 'req-1');
        // Nothing operator-facing reaches a resident (Article 5.5).
        expect(failure.residentMessage, isNot(contains('operator text')));
      });
    }

    test('429 carries Retry-After through to the failure', () {
      final Result<ApiEnvelope<void>> result = ApiEnvelopeDecoder.decode<void>(
        json(
          429,
          <String, Object?>{
            'error': <String, Object?>{
              'code': 'RATE_LIMITED',
              'message': 'Too many attempts.',
            },
          },
          headers: const <String, String>{
            'x-request-id': 'req-1',
            'retry-after': '45',
          },
        ),
        (Object? _) {},
      );

      final RateLimitedFailure failure =
          (result as Err<ApiEnvelope<void>>).failure as RateLimitedFailure;
      expect(failure.retryAfter, const Duration(seconds: 45));
    });
  });
}
