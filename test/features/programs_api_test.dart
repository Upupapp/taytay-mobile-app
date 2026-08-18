import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/api/api_transport.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/storage/public_cache.dart';
import 'package:taytay_resident/features/programs/data/program_api_repository.dart';
import 'package:taytay_resident/features/programs/domain/assistance_program.dart';

/// Records what was asked for and answers with what it was given.
class _Recording implements ApiTransport {
  _Recording(this.responses);

  final List<ApiHttpResponse> responses;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async {
    requests.add(request);
    return Ok<ApiHttpResponse>(responses.removeAt(0));
  }
}

ApiHttpResponse ok(Object body) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(body),
  headers: const <String, String>{'x-request-id': 'req-1'},
);

Map<String, Object?> citizenProgram({
  String id = 'p-1',
  String code = 'AICS',
}) => <String, Object?>{
  'id': id,
  'code': code,
  'name': 'Assistance to Individuals in Crisis Situation',
  'description': 'Help for residents facing an unexpected crisis.',
  'owner_office': 'MSWDO',
  'target_population': 'Residents in crisis',
  'benefit_type': 'financial',
  'accepts_applications': true,
  'applications_close_at': '2026-12-31T10:00:00Z',
  'decided_by': 'lgu',
  'turnaround_target_days': 7,
};

void main() {
  late _Recording transport;
  late ProgramApiRepository repository;

  ApiClient clientFor(_Recording t) => ApiClient(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
    ),
    transport: t,
    cache: PublicCache(),
  );

  setUp(() {
    transport = _Recording(<ApiHttpResponse>[]);
    repository = ProgramApiRepository(apiClient: clientFor(transport));
  });

  group('listing programmes', () {
    test('calls the public path with paging and no token', () async {
      transport.responses.add(
        ok(<String, Object?>{
          'data': <Object?>[citizenProgram()],
          'meta': <String, Object?>{
            'request_id': 'req-1',
            'pagination': <String, Object?>{
              'page': 1,
              'per_page': 25,
              'total': 1,
              'total_pages': 1,
              'has_more': false,
            },
          },
        }),
      );

      final Result<Paginated<AssistanceProgram>> result = await repository
          .listActivePrograms();

      final ApiRequest request = transport.requests.single;
      expect(request.path, 'programs');
      expect(request.query['page'], '1');
      expect(request.query['per_page'], '25');

      // No Authorization header, deliberately. The server downgrades this
      // response's cache directive to `private` the moment there is a caller
      // behind the request, and a resident gains nothing by identifying
      // themselves here — they would only lose the shared, cacheable answer.
      expect(
        request.headers.keys.map((String k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );

      // And no invented filter. There is no `status` parameter in the contract;
      // drafts are excluded by `publicQuery()` server-side.
      expect(request.query.containsKey('status'), isFalse);

      final Paginated<AssistanceProgram> page =
          (result as Ok<Paginated<AssistanceProgram>>).value;
      expect(page.items.single.code, 'AICS');
      expect(page.total, 1);
      expect(page.hasMore, isFalse);
    });

    test('per_page is clamped to the contract ceiling', () async {
      transport.responses.add(
        ok(<String, Object?>{'data': <Object?>[], 'meta': <String, Object?>{}}),
      );
      await repository.listActivePrograms(page: 0, perPage: 5000);

      final ApiRequest request = transport.requests.single;
      expect(request.query['per_page'], '100');
      expect(request.query['page'], '1');
    });

    test(
      'a page with no pagination meta degrades instead of failing',
      () async {
        // The contract says collections are always paginated. A client that
        // crashes when meta is absent turns a server omission into an outage.
        transport.responses.add(
          ok(<String, Object?>{
            'data': <Object?>[citizenProgram()],
            'meta': <String, Object?>{'request_id': 'req-1'},
          }),
        );

        final Result<Paginated<AssistanceProgram>> result = await repository
            .listActivePrograms();
        expect(
          (result as Ok<Paginated<AssistanceProgram>>).value.items,
          hasLength(1),
        );
      },
    );
  });

  group('one programme', () {
    test('is addressed by id, and decodes its detail', () async {
      transport.responses.add(
        ok(<String, Object?>{
          'data': <String, Object?>{
            ...citizenProgram(id: 'p-42'),
            'requirements': <Object?>[
              <String, Object?>{
                'code': 'valid-id',
                'label': 'Valid government-issued ID',
                'obligation': 'required',
                'accepted_documents': <String>['philsys'],
              },
            ],
            'conditions': <Object?>['A resident of Taytay, Rizal'],
          },
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
      );

      final Result<AssistanceProgram> result = await repository.loadProgram(
        'p-42',
      );

      expect(transport.requests.single.path, 'programs/p-42');

      final AssistanceProgram program = (result as Ok<AssistanceProgram>).value;
      expect(program.id, 'p-42');
      expect(program.requirements.single.label, 'Valid government-issued ID');
      expect(program.conditions.single.explanation, contains('Taytay'));
      expect(program.isLocallyDecided, isTrue);
      // Manila, not UTC: 10:00Z on the 31st is 18:00 the same day in Taytay.
      expect(program.availabilityNote, contains('31 December 2026'));
    });

    test('a 404 is an ordinary outcome, not a fault', () async {
      // An unpublished programme is *not found* rather than forbidden,
      // deliberately: a 403 would confirm that a programme the LGU has not
      // announced exists.
      transport.responses.add(
        ApiHttpResponse(
          statusCode: 404,
          body: jsonEncode(<String, Object?>{
            'error': <String, Object?>{
              'code': 'NOT_FOUND',
              'message': 'That programme was not found.',
            },
          }),
          headers: const <String, String>{'x-request-id': 'req-1'},
        ),
      );

      final Result<AssistanceProgram> result = await repository.loadProgram(
        'gone',
      );
      expect(
        (result as Err<AssistanceProgram>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('a 200 with an unreadable body is a contract failure', () async {
      transport.responses.add(
        ok(<String, Object?>{
          'data': <String, Object?>{'code': 'X'},
          'meta': <String, Object?>{'request_id': 'req-1'},
        }),
      );

      final Result<AssistanceProgram> result = await repository.loadProgram(
        'p-1',
      );
      expect(
        (result as Err<AssistanceProgram>).failure,
        isA<ContractFailure>(),
      );
    });
  });
}
