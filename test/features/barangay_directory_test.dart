import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/registration/data/barangay_api_repository.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';

/// The directory that closed F14 on the client side.
///
/// F14 was the largest single blocker in the platform: `POST me/kyc` required a
/// barangay, the only accepted identifier was an auto-increment key no route
/// published, and so no resident could open a KYC case, become Verified, or
/// reach the digital ID. The backend now publishes the list; this is the half
/// that reads it.
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

Result<ApiHttpResponse> ok(Object data) => Ok<ApiHttpResponse>(
  ApiHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{
      'data': data,
      'meta': <String, Object?>{
        'request_id': 'req-1',
        'pagination': <String, Object?>{
          'page': 1,
          'per_page': 100,
          'total': 2,
          'total_pages': 1,
          'has_more': false,
        },
      },
    }),
    headers: const <String, String>{'x-request-id': 'req-1'},
  ),
);

void main() {
  late _Scripted transport;
  late BarangayApiRepository repository;

  setUp(() {
    transport = _Scripted(<Result<ApiHttpResponse>>[]);
    repository = BarangayApiRepository(
      apiClient: ApiClient(
        config: AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
        ),
        transport: transport,
        accessTokenProvider: () async => 'tok',
      ),
    );
  });

  test('it asks for the whole list anonymously', () async {
    transport.responses.add(ok(<Object?>[]));
    await repository.listBarangays();

    final ApiRequest request = transport.requests.single;
    expect(request.path, 'barangays');

    // No token: the list is public and staying anonymous keeps the answer
    // publicly cacheable, which matters because every resident filling in an
    // address fetches it, on connections that pay per megabyte.
    expect(
      request.headers.keys.map((String k) => k.toLowerCase()),
      isNot(contains('authorization')),
    );

    // One page, explicitly. The server's default for this channel is 15, which
    // would silently truncate an address picker to the first fifteen barangays —
    // and a resident whose own barangay is missing has no way to tell that from
    // it not existing.
    expect(request.query['per_page'], '100');
  });

  test(
    'it carries the code, which is what a KYC claim is filed against',
    () async {
      transport.responses.add(
        ok(<Object?>[
          <String, Object?>{
            'id': '01a0140e-0eaf-71fa-bcb7-c354b5edee94',
            'code': 'brgy-dolores',
            'name': 'Dolores',
            'psgc_code': null,
          },
        ]),
      );

      final Result<List<Barangay>> result = await repository.listBarangays();
      final Barangay barangay = (result as Ok<List<Barangay>>).value.single;

      expect(barangay.id, startsWith('01a0140e'));
      expect(barangay.code, 'brgy-dolores');
      expect(barangay.name, 'Dolores');
      // Never invented. A wrong PSGC code is worse than an absent one, because
      // DSWD reporting keys off it.
      expect(barangay.psgcCode, isNull);
    },
  );

  test('a row with no name or no id is dropped, not shown blank', () async {
    transport.responses.add(
      ok(<Object?>[
        <String, Object?>{'id': 'b-1', 'code': 'a', 'name': 'Real'},
        <String, Object?>{'id': 'b-2', 'code': 'b'},
        <String, Object?>{'code': 'c', 'name': 'No id'},
        'garbage',
      ]),
    );

    final Result<List<Barangay>> result = await repository.listBarangays();
    final List<Barangay> rows = (result as Ok<List<Barangay>>).value;

    // A blank row in a picker is one somebody selects; one with no id cannot be
    // filed against and would fail at submission instead of at selection.
    expect(rows, hasLength(1));
    expect(rows.single.name, 'Real');
  });

  test('an auto-increment key never reaches the app', () async {
    // The shape of the defect the backend recorded as L-15, and the reason this
    // endpoint publishes a UUID and a slug. If the server ever regressed to
    // sending an integer here, it would not decode.
    transport.responses.add(
      ok(<Object?>[
        <String, Object?>{'id': 2, 'code': 'brgy-muzon', 'name': 'Muzon'},
      ]),
    );

    final Result<List<Barangay>> result = await repository.listBarangays();
    expect((result as Ok<List<Barangay>>).value, isEmpty);
  });

  test('a failure is a failure, not an empty municipality', () async {
    // An empty list and an unreachable server look identical in a dropdown, and
    // the first tells a resident their barangay does not exist.
    transport.responses.add(const Err<ApiHttpResponse>(NetworkFailure()));

    final Result<List<Barangay>> result = await repository.listBarangays();
    expect(result.isErr, isTrue);
    expect(result.valueOrNull, isNull);
  });
}
