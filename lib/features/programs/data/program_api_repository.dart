import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_program.dart';
import '../domain/program_repository.dart';
import 'program_dto.dart';

/// Talks to `GET /api/v1/programs` and `GET /api/v1/programs/{program}`.
///
/// Follows `ServiceCatalogApiRepository` deliberately rather than inventing a
/// second shape: same pagination handling, same explicit unauthenticated
/// request, same one-place query builder. Two repositories against one backend
/// module that disagreed about how to call it is how this app ended up with one
/// vertical wired and its neighbour declining.
class ProgramApiRepository implements ProgramRepository {
  const ProgramApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// The contract's own path.
  static const String path = 'programs';

  /// Conventions §5. Clamped here as well as server-side, because an over-large
  /// page is a slow response for a resident on a weak connection even when the
  /// server tolerates it.
  static const int defaultPerPage = 25;
  static const int maxPerPage = 100;

  @override
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page = 1,
    int perPage = defaultPerPage,
  }) async {
    final response = await _apiClient.send<List<AssistanceProgram>>(
      method: HttpMethod.get,
      path: path,
      // PUBLIC BY DESIGN, and sent with no token on purpose.
      //
      // The server downgrades this response's cache directive to `private` the
      // moment there is a caller behind the request, because the same URL
      // returns drafts to staff. A resident has no `program.view` permission, so
      // sending their token would change nothing they see and would cost them
      // the shared, cacheable answer — which matters most to exactly the people
      // on metered prepaid data.
      authenticated: false,
      query: _query(page: page, perPage: perPage),
      decode: ProgramDto.decodeAll,
    );

    return response.map(_toPage);
  }

  @override
  Future<Result<AssistanceProgram>> loadProgram(String id) async {
    final response = await _apiClient.send<AssistanceProgram?>(
      method: HttpMethod.get,
      path: '$path/$id',
      authenticated: false,
      decode: ProgramDto.decode,
    );

    return response.flatMap((envelope) {
      final AssistanceProgram? program = envelope.data;
      if (program == null) {
        // A 200 whose body cannot be read as a programme is a contract breach,
        // not a missing programme — and the two need different copy, because one
        // is worth reporting and the other is an ordinary afternoon.
        return Err<AssistanceProgram>(
          ContractFailure(
            requestId: envelope.requestId,
            debugMessage:
                'programs/$id returned 200 with no readable programme; the '
                'citizen projection must carry id, code and name.',
          ),
        );
      }
      return Ok<AssistanceProgram>(program);
    });
  }

  static Map<String, String> _query({
    required int page,
    required int perPage,
  }) => <String, String>{
    'page': '${page < 1 ? 1 : page}',
    'per_page': '${perPage.clamp(1, maxPerPage)}',
  };

  static Paginated<AssistanceProgram> _toPage(
    ApiEnvelope<List<AssistanceProgram>> envelope,
  ) {
    final pagination = envelope.pagination;
    if (pagination == null) {
      // The contract says collections are always paginated, but a client that
      // crashes when `meta.pagination` is absent turns a server omission into an
      // outage. Degrade to a single page.
      return Paginated<AssistanceProgram>.single(envelope.data);
    }
    return Paginated<AssistanceProgram>(
      items: envelope.data,
      page: pagination.page,
      perPage: pagination.perPage,
      total: pagination.total,
      totalPages: pagination.totalPages,
      hasMore: pagination.hasMore,
    );
  }
}
