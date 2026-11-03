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

ApiHttpResponse _ok(Object? data) => ApiHttpResponse(
  statusCode: 200,
  body: jsonEncode(<String, Object?>{
    'data': data,
    'meta': <String, Object?>{},
  }),
  headers: const <String, String>{'x-request-id': 'req-services'},
);

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

  test('programmes are the Tulong catalogue', () async {
    transport.responses.add(
      _ok(<Object?>[
        <String, Object?>{
          'id': 'svc-1',
          'name': 'Sample assistance',
          'slug': 'sample-assistance',
          'summary': 'A synthetic programme.',
          'details': 'Longer text.',
          'requirements': <String>['Barangay certificate'],
          'office_slug': 'mswdo',
          'hidden_from_list': false,
        },
        <String, Object?>{
          'id': 'svc-hidden',
          'name': 'Hidden gift',
          'slug': 'hidden-gift',
          'summary': 'Not on the list.',
          'hidden_from_list': true,
        },
      ]),
    );
    transport.responses.add(
      _ok(<String, Object?>{
        'id': 'svc-1',
        'name': 'Sample assistance',
        'slug': 'sample-assistance',
        'summary': 'A synthetic programme.',
        'details': '',
        'requirements': <String>[],
        'office_slug': 'mswdo',
      }),
    );

    final Result<Paginated<AssistanceProgram>> listed = await repository
        .listActivePrograms(office: 'mswdo');
    final AssistanceProgram program = listed.valueOrNull!.items.single;
    expect(program.code, 'sample-assistance');
    expect(program.acceptsApplications, isFalse);
    expect(program.ownerOffice, 'mswdo');
    expect(program.requirements.single.label, 'Barangay certificate');
    expect(transport.requests.single.path, 'services');
    expect(transport.requests.single.query['office'], 'mswdo');
    expect(
      transport.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );

    final Result<AssistanceProgram> loaded = await repository.loadProgram(
      'sample-assistance',
    );
    expect(loaded.valueOrNull!.name, 'Sample assistance');
    expect(transport.requests.last.path, 'services/sample-assistance');
    expect(
      transport.requests.every(
        (ApiRequest request) => request.path.contains('programs'),
      ),
      isFalse,
    );
  });
}
