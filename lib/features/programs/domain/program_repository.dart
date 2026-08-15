import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import 'assistance_program.dart';

/// Reads the social-welfare programmes a citizen may see.
///
/// ---
///
/// **Authenticated, unlike the service catalogue.** The committed matrix has two
/// different rows and this app keeps them apart:
///
/// | | endpoint | auth | status |
/// | --- | --- | --- | --- |
/// | Service catalogue | `GET /api/v1/services` | **public** | implemented |
/// | Citizen programmes | `GET /api/v1/programs?status=active` | **bearer** | planned |
///
/// So a guest browses services freely and is asked to sign in for programmes.
/// That is the server's line, not this app's preference, and drawing it in the
/// client means a guest is told *before* the request rather than by a `401`.
///
/// **`status=active` is not a filter this app chooses to apply — it is the
/// citizen row.** There is no method here that could ask for a draft, a
/// suspended or a retired programme, so no caller can be talked into surfacing
/// one.
abstract interface class ProgramRepository {
  /// Active programmes, in the citizen projection.
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page,
    int perPage,
  });

  /// One programme by its stable code.
  ///
  /// A `404` is an ordinary outcome: a programme can be retired between a link
  /// being sent and a resident tapping it, and the screen says so plainly rather
  /// than reporting a fault.
  Future<Result<AssistanceProgram>> loadProgram(String code);
}
