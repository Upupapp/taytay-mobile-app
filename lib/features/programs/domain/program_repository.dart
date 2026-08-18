import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import 'assistance_program.dart';

/// Reads the social-welfare programmes a resident may see.
///
/// ---
///
/// **Public, like the service catalogue — and this file used to say the
/// opposite.** It claimed programmes were `GET /api/v1/programs?status=active`
/// behind a bearer token, and drew that line in the client so a guest was asked
/// to sign in before the request. Measured at
/// `backend@api-baseline-2026-08`, neither half is true:
///
/// | | route | auth | status |
/// | --- | --- | --- | --- |
/// | Service catalogue | `GET services` | public | implemented |
/// | Programmes | `GET programs` · `GET programs/{program}` | **public** | **implemented** |
///
/// There is no `auth:sanctum` on either programme route and no `status` query
/// parameter anywhere in the contract. The consequence was not a failed
/// request — it was a locked door: `/programs` required an account, so a guest
/// could not read what the municipality had published for everyone. The app was
/// withholding public information the LGU had deliberately made public.
///
/// **One controller, two audiences, and the server chooses.** What a caller sees
/// is decided by their server-resolved permissions, never by which URL they
/// used (ADR 0002). A resident — signed in or not — gets the citizen
/// projection; the status filter that keeps drafts out of it is applied in
/// `publicQuery()` server-side, so there is no method here that could ask for a
/// draft, a suspended or a retired programme, and no caller can be talked into
/// surfacing one.
abstract interface class ProgramRepository {
  /// Published programmes, in the citizen projection.
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page,
    int perPage,
  });

  /// One programme.
  ///
  /// **Addressed by [AssistanceProgram.id], not by `code`.** The server resolves
  /// the path segment with `findByUuid`; the code is the human-facing string an
  /// office quotes at a counter and is not a route key.
  ///
  /// A `404` is an ordinary outcome: an unpublished programme is *not found*
  /// rather than forbidden, deliberately, because a `403` would confirm that a
  /// programme the LGU has not announced exists. The screen says so plainly
  /// rather than reporting a fault.
  Future<Result<AssistanceProgram>> loadProgram(String id);
}
