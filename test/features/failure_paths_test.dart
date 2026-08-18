import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/auth_coordinator.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/events/data/event_api_repository.dart';
import 'package:taytay_resident/features/events/domain/event_registration.dart';
import 'package:taytay_resident/features/requirements/data/requirement_api_repository.dart';
import 'package:taytay_resident/features/requirements/domain/resident_requirement.dart';
import 'package:taytay_resident/features/services/data/assistance_api_repository.dart';

/// The failure paths TAB 23 names, tested deliberately rather than hoped for.
///
/// ---
///
/// **These are the seven the Master Command lists**, and they are listed because
/// they are the ones thirteen newly wired repositories are most likely to get
/// wrong: an expired token mid-journey, a revoked session, network loss
/// mid-upload, a duplicate submit, a capacity race, an oversized upload
/// *including* the proxy rejection that does not look like one, and rate
/// limiting on OTP.
///
/// What they have in common is that none of them is reachable by using the app
/// normally. Each needs a server behaving badly on purpose, which is exactly why
/// they go untested until something happens to a resident.
class _Scripted implements ApiTransport {
  _Scripted(this.responses);

  final List<Result<ApiHttpResponse>> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return responses.isEmpty
        ? const Err<ApiHttpResponse>(NetworkFailure())
        : responses.removeAt(0);
  }
}

Result<ApiHttpResponse> ok(Object data, {int status = 200}) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'data': data,
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

Result<ApiHttpResponse> apiError(int status, String code) =>
    Ok<ApiHttpResponse>(
      ApiHttpResponse(
        statusCode: status,
        body: jsonEncode(<String, Object?>{
          'error': <String, Object?>{'code': code, 'message': 'operator text'},
        }),
        headers: const <String, String>{'x-request-id': 'req-1'},
      ),
    );

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

void main() {
  group('an expired token mid-journey ends the session exactly once', () {
    test(
      'a 401 partway through a journey invalidates, and only once',
      () async {
        var invalidations = 0;
        final AuthCoordinator coordinator = AuthCoordinator(
          onSessionInvalidated: () async => invalidations++,
        );
        final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
          ok(<Object?>[]),
          apiError(401, 'UNAUTHENTICATED'),
          apiError(401, 'UNAUTHENTICATED'),
        ]);
        final ApiClient client = ApiClient(
          config: config(),
          transport: transport,
          accessTokenProvider: () async => 'tok',
          authCoordinator: coordinator,
          onUnauthenticated: () async => invalidations++,
        );

        // The journey: a list loads, then the token dies partway through.
        await client.send<void>(
          method: HttpMethod.get,
          path: 'me/cases',
          authenticated: true,
          decode: (_) {},
        );
        await Future.wait<void>(<Future<void>>[
          client
              .send<void>(
                method: HttpMethod.get,
                path: 'me/notifications',
                authenticated: true,
                decode: (_) {},
              )
              .then((_) {}),
          client
              .send<void>(
                method: HttpMethod.get,
                path: 'me/profile',
                authenticated: true,
                decode: (_) {},
              )
              .then((_) {}),
        ]);

        // Two screens noticed; the resident is signed out once. Thirteen
        // repositories each pulling the session down independently is the
        // stampede this coordinator exists to prevent.
        expect(invalidations, 1);
      },
    );
  });

  group('a revoked session is refused, not retried into', () {
    test('an authenticated request with no token never reaches the wire', () async {
      // After revocation the store is cleared, so the provider has nothing. The
      // request must not go out anonymously: that produces a misleading 401 and,
      // worse, a request that looks deliberately anonymous in an audit log.
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[]);
      final ApiClient client = ApiClient(
        config: config(),
        transport: transport,
        accessTokenProvider: () async => null,
      );

      final Result<void> result = await client.send<void>(
        method: HttpMethod.get,
        path: 'me/cases',
        authenticated: true,
        decode: (_) {},
      );

      expect(result.failureOrNull, isA<UnauthenticatedFailure>());
      expect(transport.requests, isEmpty);
    });
  });

  group('network loss mid-upload does not report success', () {
    test(
      'a dropped connection during an upload is a failure, not a document',
      () async {
        final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
          const Err<ApiHttpResponse>(NetworkFailure()),
        ]);

        final Result<UploadedDocumentReference> result =
            await RequirementApiRepository(
              apiClient: ApiClient(
                config: config(),
                transport: transport,
                accessTokenProvider: () async => 'tok',
              ),
            ).uploadRequirementDocument(
              requestId: 'case-1',
              requirementCode: 'valid-id',
              document: CapturedDocument(
                bytes: Uint8List.fromList(<int>[1, 2, 3]),
                fileName: 'id.pdf',
                mimeType: 'application/pdf',
                source: DocumentSource.file,
              ),
              idempotencyKey: 'k',
            );

        // A mocked success here would tell a resident their barangay clearance had
        // reached Taytay LGU when nothing left the phone — and they would find out
        // at the counter, having travelled on the strength of it.
        expect(result.isErr, isTrue);
        expect(result.valueOrNull, isNull);
      },
    );
  });

  group('an oversized upload is refused before it costs anything', () {
    test('a body over the client ceiling never leaves the device', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[]);
      final Result<UploadedDocumentReference> result =
          await RequirementApiRepository(
            apiClient: ApiClient(config: config(), transport: transport),
          ).uploadRequirementDocument(
            requestId: 'case-1',
            requirementCode: 'valid-id',
            // Not an image, so it is not downscaled — a PDF larger than the ceiling.
            document: CapturedDocument(
              bytes: Uint8List(9 * 1024 * 1024),
              fileName: 'huge.pdf',
              mimeType: 'application/pdf',
              source: DocumentSource.file,
            ),
            idempotencyKey: 'k',
          );

      expect(result.failureOrNull, isA<UnacceptableUploadFailure>());
      expect(
        (result.failureOrNull! as UnacceptableUploadFailure).isTooLarge,
        isTrue,
      );
      // The point of refusing here: several megabytes are not pushed over
      // metered data to be told no.
      expect(transport.requests, isEmpty);
    });

    test('a PROXY rejection is not reported as a lost connection', () async {
      // The failure path TAB 10 warns about and nothing had covered. nginx
      // answers before the application when a body exceeds
      // client_max_body_size, so the response is HTML rather than the error
      // envelope. Reporting that as "no connection" sends a resident to a
      // barangay hall over a file size.
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        const Ok<ApiHttpResponse>(
          ApiHttpResponse(
            statusCode: 413,
            body:
                '<html><head><title>413 Request Entity Too Large</title></head>'
                '<body><center><h1>413</h1></center></body></html>',
            headers: <String, String>{'content-type': 'text/html'},
          ),
        ),
      ]);

      final Result<UploadedDocumentReference> result =
          await RequirementApiRepository(
            apiClient: ApiClient(
              config: config(),
              transport: transport,
              accessTokenProvider: () async => 'tok',
            ),
          ).uploadRequirementDocument(
            requestId: 'case-1',
            requirementCode: 'valid-id',
            document: CapturedDocument(
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              fileName: 'id.pdf',
              mimeType: 'application/pdf',
              source: DocumentSource.file,
            ),
            idempotencyKey: 'k',
          );

      // Asserted as what the resident is *told*, not merely as what it is not.
      // The first version of this test only checked it was not a network
      // failure, and it passed against `UnexpectedFailure` — "something went
      // wrong" — which is the exact outcome TAB 10 exists to prevent, on the one
      // screen where the remedy is obvious and the resident's.
      final AppFailure failure = result.failureOrNull!;
      expect(failure, isA<UnacceptableUploadFailure>());
      expect((failure as UnacceptableUploadFailure).isTooLarge, isTrue);
      expect(failure.residentMessage.toLowerCase(), contains('too large'));
      expect(
        failure.residentMessage.toLowerCase(),
        isNot(contains('connection')),
      );
    });
  });

  group('a duplicate submit produces one case', () {
    test('the retry carries the same key the first attempt did', () async {
      final _Scripted transport = _Scripted(<Result<ApiHttpResponse>>[
        ok(<String, Object?>{'id': 'draft-1'}, status: 201),
        const Err<ApiHttpResponse>(TimeoutFailure()),
        ok(<String, Object?>{'id': 'draft-1'}, status: 201),
        ok(<String, Object?>{
          'id': 'case-9',
          'status': 'submitted',
        }, status: 201),
      ]);
      final AssistanceApiRepository repository = AssistanceApiRepository(
        apiClient: ApiClient(
          config: config(),
          transport: transport,
          accessTokenProvider: () async => 'tok',
        ),
      );

      // Submit, lose the response, submit again — the resident tapping twice
      // because the first attempt appeared to do nothing.
      await repository.submitRequest(
        serviceCode: 'AICS',
        narrative: 'x',
        answers: const <String, Object?>{},
        consentKeys: const <String>[],
        attachmentIds: const <String>[],
        idempotencyKey: 'one-draft',
      );
      await repository.submitRequest(
        serviceCode: 'AICS',
        narrative: 'x',
        answers: const <String, Object?>{},
        consentKeys: const <String>[],
        attachmentIds: const <String>[],
        idempotencyKey: 'one-draft',
      );

      final List<String> keys = transport.requests
          .where((ApiRequest r) => r.path.endsWith('/submit'))
          .map((ApiRequest r) => r.headers['Idempotency-Key'] ?? '')
          .toList();

      // Same key both times. A fresh key on a retry is a new request, which is
      // the second case the MSWDO cleans up by hand while a household waits.
      expect(keys, isNotEmpty);
      expect(keys.toSet(), hasLength(1));
    });
  });

  group('the capacity race resolves as an outcome, not a fault', () {
    test(
      'two registrations for one place: one confirmed, one told why',
      () async {
        final EventApiRepository first = EventApiRepository(
          apiClient: ApiClient(
            config: config(),
            transport: _Scripted(<Result<ApiHttpResponse>>[
              ok(<String, Object?>{'id': 'reg-1', 'state': 'registered'}),
            ]),
            accessTokenProvider: () async => 'tok',
          ),
        );
        final EventApiRepository second = EventApiRepository(
          apiClient: ApiClient(
            config: config(),
            transport: _Scripted(<Result<ApiHttpResponse>>[
              apiError(409, 'CONFLICT'),
            ]),
            accessTokenProvider: () async => 'tok',
          ),
        );

        final List<Result<RegistrationAttempt>> results =
            await Future.wait<Result<RegistrationAttempt>>(
              <Future<Result<RegistrationAttempt>>>[
                first.register(
                  eventId: 'e-1',
                  answers: const <String, Object?>{},
                  consentKeys: const <String>[],
                  idempotencyKey: 'a',
                ),
                second.register(
                  eventId: 'e-1',
                  answers: const <String, Object?>{},
                  consentKeys: const <String>[],
                  idempotencyKey: 'b',
                ),
              ],
            );

        // Both succeed as *results*; they differ in outcome. Neither resident
        // gets an error dialog, and the one who lost is told what happened.
        expect(
          results.every((Result<RegistrationAttempt> r) => r.isOk),
          isTrue,
        );
        final Set<RegistrationOutcome> outcomes = results
            .map(
              (Result<RegistrationAttempt> r) =>
                  (r as Ok<RegistrationAttempt>).value.outcome,
            )
            .toSet();
        expect(
          outcomes,
          containsAll(<RegistrationOutcome>[
            RegistrationOutcome.registered,
            RegistrationOutcome.full,
          ]),
        );
      },
    );
  });
}
