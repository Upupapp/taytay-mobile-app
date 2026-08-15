import '../../../core/api/paginated.dart';
import '../../../core/api/planned_backend.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_program.dart';
import '../domain/program_repository.dart';

/// The [ProgramRepository] this build ships with: it declines, honestly.
///
/// The citizen programme row is `planned`, so there is nothing to call. Mocking
/// it would be worse than most: a fabricated programme is an offer of public
/// money made in a local government's name, and a resident who read one would
/// arrive at a counter asking for a benefit that does not exist.
class PlannedProgramRepository implements ProgramRepository {
  const PlannedProgramRepository();

  static const PlannedModule _module = PlannedModule.serviceDelivery;

  @override
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page = 1,
    int perPage = 20,
  }) async => plannedBackendFailure<Paginated<AssistanceProgram>>(
    _module,
    'listActivePrograms',
  );

  @override
  Future<Result<AssistanceProgram>> loadProgram(String code) async =>
      plannedBackendFailure<AssistanceProgram>(_module, 'loadProgram');
}
