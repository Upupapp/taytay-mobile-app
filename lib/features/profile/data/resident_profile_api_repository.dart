import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/profile_fields.dart';
import '../domain/resident_profile_detail.dart';
import '../domain/resident_profile_repository.dart';

/// Talks to `GET me/profile` and `POST me/profile/corrections`.
///
/// ---
///
/// **There is no `PATCH me/profile`, and that is the module's design rather
/// than a gap.** A resident does not edit their own master record: they request
/// a correction and staff adjudicate it — except for the fields the server's own
/// `CorrectableField::selfServiceValues()` marks as applying immediately. Which
/// is which is decided server-side and published on the profile response as
/// `editable_fields` and `requestable_fields`, told explicitly rather than left
/// for each client to infer from which fields happen to be writable.
///
/// So `updateContactDetails` and `submitOwnUpdate` are the same request here,
/// and the difference in what happens next belongs to the server. The screen
/// must make that visible: an edit form that looks like it saves but actually
/// queues a request for a caseworker is a trust failure, and it is the one a
/// resident discovers weeks later at a counter.
class ResidentProfileApiRepository implements ResidentProfileRepository {
  const ResidentProfileApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String path = 'me/profile';

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async {
    final response = await _apiClient.send<ResidentProfileSummary>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      decode: (Object? data) {
        final map = data is Map<String, dynamic>
            ? data
            : const <String, dynamic>{};
        final Object? tier = map['verification_tier'];
        return ResidentProfileSummary(
          // Unmapped, and read fresh on every call. The tier decides what a
          // resident may do, so it is authority-shaped: never computed here,
          // never cached past sign-out, and an unrecognised value fails closed
          // in `AccessLevel.fromVerificationTier` rather than here.
          verificationTier: tier is String ? tier : '',
        );
      },
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async {
    final response = await _apiClient.send<ResidentProfileDetail>(
      method: HttpMethod.get,
      path: path,
      authenticated: true,
      decode: _decodeDetail,
    );
    return response.map((envelope) => envelope.data);
  }

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) => _fileCorrection(
    changes: <ResidentProfileField, String>{
      if (update.mobileNumber != null && update.mobileNumber!.isNotEmpty)
        ResidentProfileField.mobileNumber: update.mobileNumber!,
      if (update.emailAddress != null && update.emailAddress!.isNotEmpty)
        ResidentProfileField.emailAddress: update.emailAddress!,
    },
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async {
    // Already keyed by the server's own field names — this is the path the
    // correction form uses, and it must not re-map anything on the way through.
    final Map<String, Object?> named = <String, Object?>{
      for (final MapEntry<String, Object?> entry in changes.entries)
        if (entry.value != null) entry.key: entry.value,
    };
    if (named.isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'Empty change set.'),
      );
    }

    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: '\$path/corrections',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{'changes': named},
      decode: (_) {},
    );
    return response.map((_) {});
  }

  /// One request for both, because the server draws the line, not this app.
  ///
  /// The idempotency key is required by the contract above and matters here:
  /// a correction that arrives twice is a second item in a caseworker's queue,
  /// and two open requests against one field is how a record ends up amended
  /// twice.
  Future<Result<void>> _fileCorrection({
    required Map<ResidentProfileField, String> changes,
    required String idempotencyKey,
    String? note,
  }) async {
    final Map<String, Object?> named = <String, Object?>{
      for (final MapEntry<ResidentProfileField, String> entry
          in changes.entries)
        if (entry.key.wireName != null) entry.key.wireName!: entry.value,
    };

    if (named.isEmpty) {
      return const Err<void>(
        ValidationFailure(
          debugMessage: 'No correctable field was named in the change set.',
        ),
      );
    }

    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: '$path/corrections',
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: <String, Object?>{
        'changes': named,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      decode: (_) {},
    );
    return response.map((_) {});
  }

  static ResidentProfileDetail _decodeDetail(Object? data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    final Map<ResidentProfileField, String> values =
        <ResidentProfileField, String>{};
    for (final ResidentProfileField field in ResidentProfileField.values) {
      final String? wire = field.wireName;
      if (wire == null) continue;
      final Object? value = map[wire];
      if (value is String && value.trim().isNotEmpty) {
        values[field] = value.trim();
      }
    }

    // The name is three fields on the wire and one on a screen. Joined here
    // rather than in the widget so that every surface showing a name shows the
    // same one.
    final String fullName = <String?>[
      map['first_name'] as String?,
      map['middle_name'] as String?,
      map['last_name'] as String?,
      map['suffix'] as String?,
    ].whereType<String>().where((String p) => p.trim().isNotEmpty).join(' ');
    if (fullName.isNotEmpty) values[ResidentProfileField.fullName] = fullName;

    final Object? tier = map['verification_tier'];
    return ResidentProfileDetail(
      values: Map<ResidentProfileField, String>.unmodifiable(values),
      verificationTier: tier is String ? tier : null,
    );
  }
}
