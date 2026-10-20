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
    test('declines: the Node API has no programmes route', () async {
      final Result<Paginated<AssistanceProgram>> listed = await repository
          .listActivePrograms();
      final Result<AssistanceProgram> loaded = await repository.loadProgram(
        'p-42',
      );

      for (final Result<Object?> result in <Result<Object?>>[listed, loaded]) {
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull!.debugMessage, contains('F32'));
      }
      expect(transport.requests, isEmpty);
    });
  });
}
