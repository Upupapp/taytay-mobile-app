import '../../../core/api/api_client.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/result/result.dart';
import '../domain/field_correction_note.dart';
import '../domain/resident_record.dart';
import '../domain/resident_record_repository.dart';

/// `GET /me`, `PATCH /me`, and `GET|PATCH|POST /households/current`.
///
/// Household member names are other people's personal data. This decoder
/// counts the array and does not read a name, a birth date, or a user id
/// out of it. The household id is not kept either: every call is the
/// caller's own current household and takes no argument.
class ResidentRecordApiRepository implements ResidentRecordRepository {
  const ResidentRecordApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String profilePath = 'me';
  static const String householdPath = 'households/current';
  static const String createHouseholdPath = 'households';

  @override
  Future<Result<ResidentRecord>> load() async {
    final profile = await _apiClient.send<Map<String, dynamic>>(
      method: HttpMethod.get,
      path: profilePath,
      authenticated: true,
      decode: _asMap,
    );
    if (profile case Err(:final failure)) {
      return Err<ResidentRecord>(failure);
    }
    final map = profile.valueOrNull!.data;
    final household = await _loadHousehold();
    if (household case Err(:final failure)) {
      return Err<ResidentRecord>(failure);
    }
    return Ok<ResidentRecord>(
      _record(profile: map, household: household.valueOrNull),
    );
  }

  @override
  Future<Result<ResidentRecord>> savePersonal(PersonalDraft draft) async {
    final saved = await _patchProfile(draft);
    if (saved case Err(:final failure)) {
      return Err<ResidentRecord>(failure);
    }
    return load();
  }

  @override
  Future<Result<ResidentRecord>> saveHousehold(HouseholdDraft draft) async {
    final profile = await _apiClient.send<void>(
      method: HttpMethod.patch,
      path: profilePath,
      authenticated: true,
      idempotencyKey: _key('street'),
      body: <String, Object?>{
        'street': draft.street,
        'purok': draft.purok,
        if (draft.barangayId.isNotEmpty) 'barangay_id': draft.barangayId,
        'address': _addressLine(draft),
      },
      decode: (_) {},
    );
    if (profile case Err(:final failure)) {
      return Err<ResidentRecord>(failure);
    }
    final household = await _writeHousehold(draft);
    if (household case Err(:final failure)) {
      return Err<ResidentRecord>(failure);
    }
    return load();
  }

  @override
  Future<Result<ResidentRecord>> submit({
    required PersonalDraft personal,
    required HouseholdDraft household,
  }) async {
    final person = await savePersonal(personal);
    if (person case Err(:final failure)) {
      return Err<ResidentRecord>(failure);
    }
    return saveHousehold(household);
  }

  Future<Result<void>> _patchProfile(PersonalDraft draft) {
    final name = <String>[
      draft.givenName,
      draft.middleName,
      draft.familyName,
      draft.suffix,
    ].where((String part) => part.trim().isNotEmpty).join(' ');
    return _apiClient.send<void>(
      method: HttpMethod.patch,
      path: profilePath,
      authenticated: true,
      idempotencyKey: _key('profile'),
      body: <String, Object?>{
        if (name.isNotEmpty) 'name': name,
        if (draft.birthdate.isNotEmpty) 'birthdate': draft.birthdate,
        if (_sexWire(draft.sex) != null) 'sex': _sexWire(draft.sex),
        if (draft.mobile.isNotEmpty) 'mobile': draft.mobile,
        if (draft.email.isNotEmpty) 'email': draft.email,
      },
      decode: (_) {},
    );
  }

  Future<Result<void>> _writeHousehold(HouseholdDraft draft) async {
    final body = <String, Object?>{
      'address': _addressLine(draft),
      if (draft.barangayId.isNotEmpty) 'barangay_id': draft.barangayId,
    };
    final patched = await _apiClient.send<void>(
      method: HttpMethod.patch,
      path: householdPath,
      authenticated: true,
      idempotencyKey: _key('household'),
      body: body,
      decode: (_) {},
    );
    if (patched case Ok()) return const Ok<void>(null);
    final failure = patched.failureOrNull!;
    if (failure is! NotFoundFailure) return Err<void>(failure);
    if (draft.barangayId.isEmpty || _addressLine(draft).isEmpty) {
      return const Ok<void>(null);
    }
    return _apiClient.send<void>(
      method: HttpMethod.post,
      path: createHouseholdPath,
      authenticated: true,
      idempotencyKey: _key('household-create'),
      body: <String, Object?>{
        'address': _addressLine(draft),
        'barangay_id': draft.barangayId,
      },
      decode: (_) {},
    );
  }

  Future<Result<Map<String, dynamic>?>> _loadHousehold() async {
    final response = await _apiClient.send<Map<String, dynamic>?>(
      method: HttpMethod.get,
      path: householdPath,
      authenticated: true,
      decode: (Object? data) => data is Map<String, dynamic> ? data : null,
    );
    if (response case Ok(:final value)) {
      return Ok<Map<String, dynamic>?>(value.data);
    }
    final failure = response.failureOrNull!;
    if (failure is NotFoundFailure) return const Ok<Map<String, dynamic>?>(null);
    return Err<Map<String, dynamic>?>(failure);
  }

  static Map<String, dynamic> _asMap(Object? data) =>
      data is Map<String, dynamic> ? data : const <String, dynamic>{};

  static ResidentRecord _record({
    required Map<String, dynamic> profile,
    required Map<String, dynamic>? household,
  }) {
    final name = _string(profile['name']);
    final parts = name.split(RegExp(r'\s+')).where((String p) => p.isNotEmpty);
    final list = parts.toList(growable: false);
    final given = list.isNotEmpty ? list.first : '';
    final family = list.length > 1 ? list.last : '';
    final middle = list.length > 2 ? list.sublist(1, list.length - 1).join(' ') : '';
    final street = _string(profile['street']);
    final purok = _string(profile['purok']);
    final barangayName = _string(household?['barangay_name']);
    final personal = given.isNotEmpty && family.isNotEmpty;
    final householdStarted = street.isNotEmpty || barangayName.isNotEmpty;
    final filled = <bool>[personal, householdStarted, _string(profile['mobile']).isNotEmpty]
        .where((bool bit) => bit)
        .length;
    return ResidentRecord(
      givenName: given,
      middleName: middle,
      familyName: family,
      sex: _sexLabel(_string(profile['sex'])),
      birthdate: _string(profile['birthdate']),
      mobile: _string(profile['mobile']),
      email: _string(profile['email']),
      mobileVerified: false,
      barangayId: _string(profile['barangay_id']).isNotEmpty
          ? _string(profile['barangay_id'])
          : _string(household?['barangay_id']),
      barangayName: barangayName,
      street: street.isNotEmpty ? street : _string(household?['address']),
      purok: purok,
      yearsAtAddress: '',
      memberCount: _memberCount(household?['members']),
      residenceType: '',
      verificationTier: _string(profile['verification_status']),
      rejectionReason: _string(profile['rejection_reason']),
      fieldNotes: const <FieldCorrectionNote>[],
      completeness: ((filled / 3) * 100).round(),
      personalComplete: personal,
      householdStarted: householdStarted,
    );
  }

  /// Count only. A member object is never opened, so a name cannot be copied.
  static String _memberCount(Object? members) {
    if (members is! List<Object?>) return '';
    return '${members.length}';
  }

  static String _string(Object? value) =>
      value is String ? value.trim() : '';

  static String _addressLine(HouseholdDraft draft) {
    final street = <String>[
      draft.street,
      if (draft.purok.isNotEmpty) 'Purok ${draft.purok}',
    ].where((String part) => part.isNotEmpty).join(', ');
    final place = <String>[
      if (draft.barangayName.isNotEmpty) 'Brgy. ${draft.barangayName}',
      'Taytay',
      'Rizal',
    ].join(', ');
    if (street.isEmpty) return place == 'Taytay, Rizal' ? '' : place;
    return '$street, $place';
  }

  static String? _sexWire(String label) => switch (label.trim().toLowerCase()) {
    'female' => 'female',
    'male' => 'male',
    'unspecified' => 'unspecified',
    _ => null,
  };

  static String _sexLabel(String wire) => switch (wire) {
    'female' => 'Female',
    'male' => 'Male',
    'unspecified' => 'Unspecified',
    _ => '',
  };

  static String _key(String name) =>
      'record-$name-${DateTime.now().toUtc().microsecondsSinceEpoch}';
}
