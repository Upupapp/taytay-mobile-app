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

  static const String path = 'me';

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
        final Object? tier =
            map['verification_status'] ?? map['verification_tier'];
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
      // The address parts the office lists as self-service (C-13). `barangay_id`
      // is not among them and must not be added here: which barangay serves
      // somebody is the LGU's decision, and this method is the one place a
      // resident's own edit becomes a request.
      if (update.streetAddress != null && update.streetAddress!.isNotEmpty)
        ResidentProfileField.streetAddress: update.streetAddress!,
      if (update.purokOrSitio != null && update.purokOrSitio!.isNotEmpty)
        ResidentProfileField.purokOrSitio: update.purokOrSitio!,
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
        if (entry.value != null && _patchWire(entry.key) != null)
          _patchWire(entry.key)!: entry.value,
    };
    if (named.isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'Empty change set.'),
      );
    }

    final response = await _apiClient.send<void>(
      method: HttpMethod.patch,
      path: path,
      // The Node profile edit is PATCH /me. There is no corrections route.
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: named,
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
        if (_patchKey(entry.key) != null) _patchKey(entry.key)!: entry.value,
    };

    if (named.isEmpty) {
      return const Err<void>(
        ValidationFailure(
          debugMessage: 'No correctable field was named in the change set.',
        ),
      );
    }

    final response = await _apiClient.send<void>(
      method: HttpMethod.patch,
      path: path,
      authenticated: true,
      idempotencyKey: idempotencyKey,
      body: named,
      decode: (_) {},
    );
    if (note != null && note.trim().isNotEmpty) {
      // ProfilePatch has no note field. The words stay off the wire.
      assert(note.isNotEmpty);
    }
    return response.map((_) {});
  }

  /// `POST me/avatar`.
  Future<Result<void>> uploadAvatar(MultipartFile file) async {
    final response = await _apiClient.send<void>(
      method: HttpMethod.post,
      path: 'me/avatar',
      authenticated: true,
      file: MultipartFile(
        field: 'file',
        filename: file.filename,
        bytes: file.bytes,
        mimeType: file.mimeType,
      ),
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
      final Object? value = _fieldValue(map, wire);
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
    final Object? singleName = map['name'];
    final String resolvedName = fullName.isNotEmpty
        ? fullName
        : (singleName is String ? singleName.trim() : '');
    if (resolvedName.isNotEmpty) {
      values[ResidentProfileField.fullName] = resolvedName;
    }

    final Object? tier = map['verification_status'] ?? map['verification_tier'];
    final Object? reason = map['rejection_reason'];
    final Object? closedAt = map['closed_at'];
    final Object? createdAt = map['created_at'];

    // WHO MAY CHANGE WHAT IS THE OFFICE'S ANSWER, AND IT IS ON THE WIRE (C-13).
    //
    // The server publishes `editable_fields` from
    // `CorrectableField::selfServiceValues()` and says in its own comment that
    // it is told explicitly rather than left for each client to infer. This app
    // inferred it anyway, from a `FieldOwnership` written into
    // `ResidentProfileField` — and the two disagreed: the office lets a resident
    // change `street_address` themselves, and the screen said only the LGU
    // could.
    //
    // A malformed or absent list stays null rather than becoming an empty set:
    // empty would mean "the resident may change nothing", which is the wrong
    // way to fail.
    final Object? editable = map['editable_fields'];
    final Set<String>? selfService = editable is List<dynamic>
        ? editable.whereType<String>().toSet()
        : null;

    return ResidentProfileDetail(
      values: Map<ResidentProfileField, String>.unmodifiable(values),
      verificationTier: tier is String ? tier : null,
      selfServiceFields: selfService != null && selfService.isNotEmpty
          ? Set<String>.unmodifiable(selfService)
          : null,
      emailVerified: map['email_verified'] == true,
      rejectionReason: reason is String && reason.trim().isNotEmpty
          ? reason.trim()
          : null,
      closed: map['closed'] == true,
      closedAt: DateTime.tryParse(closedAt is String ? closedAt : '')?.toUtc(),
      createdAt: DateTime.tryParse(createdAt is String ? createdAt : '')
          ?.toUtc(),
    );
  }

  /// ProfilePatch names. `street` and `purok` are the structured lines.
  /// `role` and `office_id` are never sent.
  static String? _patchKey(ResidentProfileField field) {
    final String? wire = field.wireName;
    if (wire == null) return null;
    return _patchWire(wire);
  }

  static String? _patchWire(String wire) => switch (wire) {
    'mobile_number' => 'mobile',
    'street_address' => 'street',
    'birth_date' => 'birthdate',
    'purok_or_sitio' => 'purok',
    'role' || 'office_id' || 'rejection_reason' || 'email_verified' => null,
    _ => wire,
  };

  /// Reads the historical wire name, then Clarence's names on `/me`.
  static Object? _fieldValue(Map<String, dynamic> map, String wire) {
    final List<String> keys = switch (wire) {
      'mobile_number' => <String>['mobile_number', 'mobile'],
      'street_address' => <String>['street', 'street_address', 'address'],
      'purok_or_sitio' => <String>['purok', 'purok_or_sitio'],
      'birth_date' => <String>['birth_date', 'birthdate'],
      _ => <String>[wire],
    };
    for (final String key in keys) {
      final Object? value = map[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }
}
