import '../../../core/api/api_client.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_program.dart';
import '../domain/program_repository.dart';

/// Talks to the historical programme routes.
///
/// The Node contract has no programme resource. Tulong is `GET services`.
class ProgramApiRepository implements ProgramRepository {
  const ProgramApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page = 1,
    int? perPage,
  }) async {
    final Object _ = _apiClient.runtimeType;
    assert(page >= 1);
    assert(perPage == null || perPage > 0);
    return backendGapFailure<Paginated<AssistanceProgram>>(
      BackendGap.absentOnNodeContract,
      'listActivePrograms',
    );
  }

  @override
  Future<Result<AssistanceProgram>> loadProgram(String id) async {
    final Object _ = _apiClient.runtimeType;
    assert(id.isNotEmpty);
    return backendGapFailure<AssistanceProgram>(
      BackendGap.absentOnNodeContract,
      'loadProgram',
    );
  }
}
