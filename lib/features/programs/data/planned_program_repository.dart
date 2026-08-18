import '../../../core/api/paginated.dart';
import '../../../core/api/unwired_repository.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_program.dart';
import '../domain/program_repository.dart';

/// The [ProgramRepository] this build ships with: it declines, honestly.
///
/// **The app's own premise contradicted itself here.** `ServiceCatalogApiRepository`
/// has been calling `GET services` against this very module for the whole of the
/// app's life, while this file declined `GET programs` and `GET programs/{program}`
/// as `planned` — two repositories, one implemented module, opposite beliefs.
/// That is the cheapest real win available and TAB 07 takes it, partly as a
/// low-risk first exercise of the TAB 01 conformance harness.
///
/// It still declines meanwhile rather than mocking, which would be worse than
/// most: a fabricated programme is an offer of public money made in a local
/// government's name, and a resident who read one would arrive at a counter
/// asking for a benefit that does not exist.
class PlannedProgramRepository implements ProgramRepository {
  const PlannedProgramRepository();

  static const UnwiredRepository _repository = UnwiredRepository.programs;

  @override
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page = 1,
    int perPage = 20,
  }) async => unwiredRepositoryFailure<Paginated<AssistanceProgram>>(
    _repository,
    'listActivePrograms',
  );

  @override
  Future<Result<AssistanceProgram>> loadProgram(String code) async =>
      unwiredRepositoryFailure<AssistanceProgram>(_repository, 'loadProgram');
}
