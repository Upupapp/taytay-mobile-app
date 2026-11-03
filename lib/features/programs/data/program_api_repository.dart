import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import '../domain/assistance_program.dart';
import '../domain/program_repository.dart';

/// The programmes entry reads the Tulong catalogue.
///
/// `GET /programs` is not in the Node contract. List is `GET /services`.
/// One programme is `GET /services/{slug}`. An office page asks for
/// `GET /services?office={slug}` through the Tulong repository, not here.
/// Both reads are public. There is no apply call.
class ProgramApiRepository implements ProgramRepository {
  const ProgramApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'services';

  @override
  Future<Result<Paginated<AssistanceProgram>>> listActivePrograms({
    int page = 1,
    int perPage = 20,
    String? office,
  }) async {
    assert(page >= 1);
    final int size = perPage.clamp(1, 50);
    final String? officeSlug = office?.trim();
    final Result<ApiEnvelope<List<AssistanceProgram>>> response =
        await _apiClient.send<List<AssistanceProgram>>(
          method: HttpMethod.get,
          path: path,
          authenticated: false,
          query: <String, String>{
            'limit': '$size',
            'office': ?((officeSlug == null || officeSlug.isEmpty)
                ? null
                : officeSlug),
          },
          decode: _decodeList,
        );
    return response.map(_toPage);
  }

  @override
  Future<Result<AssistanceProgram>> loadProgram(String id) async {
    assert(id.isNotEmpty);
    final Result<ApiEnvelope<AssistanceProgram?>> response = await _apiClient
        .send<AssistanceProgram?>(
          method: HttpMethod.get,
          path: '$path/$id',
          authenticated: false,
          decode: _decodeOne,
        );
    return switch (response) {
      Err<ApiEnvelope<AssistanceProgram?>>(:final failure) =>
        Err<AssistanceProgram>(failure),
      Ok<ApiEnvelope<AssistanceProgram?>>(:final value) =>
        value.data == null
            ? const Err<AssistanceProgram>(
                NotFoundFailure(
                  debugMessage: 'No readable service in the body.',
                ),
              )
            : Ok<AssistanceProgram>(value.data!),
    };
  }

  static Paginated<AssistanceProgram> _toPage(
    ApiEnvelope<List<AssistanceProgram>> envelope,
  ) {
    final PageMeta? page = envelope.pagination;
    if (page == null) return Paginated<AssistanceProgram>.single(envelope.data);
    return Paginated<AssistanceProgram>(
      items: envelope.data,
      page: page.page,
      perPage: page.perPage,
      total: page.total,
      totalPages: page.totalPages,
      hasMore: page.hasMore,
      nextCursor: page.nextCursor,
    );
  }

  static List<AssistanceProgram> _decodeList(Object? data) {
    if (data is! List) return const <AssistanceProgram>[];
    return data
        .map(_decodeOne)
        .whereType<AssistanceProgram>()
        .toList(growable: false);
  }

  /// Node `Service`. `slug` is the address. Applications are not offered.
  static AssistanceProgram? _decodeOne(Object? raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> json = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    final String? id = _text(json['id']);
    final String? slug = _text(json['slug']) ?? _text(json['code']);
    final String? name = _text(json['name']);
    if (id == null || slug == null || name == null) return null;
    if (json['hidden_from_list'] == true) return null;
    final String summary = _text(json['summary']) ?? '';
    final String details = _text(json['details']) ?? '';
    return AssistanceProgram(
      id: id,
      code: slug,
      name: name,
      description: summary.isNotEmpty ? summary : details,
      acceptsApplications: false,
      ownerOffice: _text(json['office_slug']),
      requirements: _requirements(json['requirements']),
    );
  }

  static List<ProgramRequirement> _requirements(Object? raw) {
    if (raw is! List) return const <ProgramRequirement>[];
    return <ProgramRequirement>[
      for (final Object? item in raw)
        if (item is String && item.trim().isNotEmpty)
          ProgramRequirement(
            code: item.trim(),
            label: item.trim(),
            obligation: RequirementObligation.required,
          ),
    ];
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
