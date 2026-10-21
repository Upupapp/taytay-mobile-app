import '../../../core/api/api_client.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/api/api_transport.dart';
import '../../../core/api/backend_gap.dart';
import '../../../core/result/result.dart';
import '../domain/household_record.dart';
import '../domain/household_repository.dart';
import '../domain/household_summary.dart';

/// The caller's household on the Taytay LGU IDS API.
///
/// Reads and writes `Household` and `HouseholdMember` as the contract
/// publishes them. Staff list `GET /households` is not called. A correction
/// report still has no route, so that one call declines.
class HouseholdApiRepository implements HouseholdRepository {
  const HouseholdApiRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const String currentPath = 'households/current';

  @override
  Future<Result<HouseholdSummary>> loadOwnHousehold() async {
    final Result<HouseholdRecord?> current = await loadCurrent();
    return switch (current) {
      Ok(:final value) when value == null => const Err<HouseholdSummary>(
        NotFoundFailure(debugMessage: 'No household on file.'),
      ),
      Ok(:final value) => Ok<HouseholdSummary>(value!.toSummary()),
      Err(:final failure) => Err<HouseholdSummary>(failure),
    };
  }

  @override
  Future<Result<void>> submitCorrectionRequest({
    required HouseholdCorrectionRequest request,
    required String idempotencyKey,
  }) async {
    // The contract accepts an address patch, not a category with no proposed
    // value. The screen still sends the resident to the office.
    if (idempotencyKey.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'An idempotency key is required.'),
      );
    }
    return backendGapFailure<void>(
      BackendGap.kycFieldCorrections,
      'submitCorrectionRequest (${request.kind.name})',
    );
  }

  @override
  Future<Result<HouseholdRecord>> createHousehold({
    required String address,
    required String barangayId,
  }) async {
    final String line = address.trim();
    final String barangay = barangayId.trim();
    if (line.isEmpty || barangay.isEmpty) {
      return const Err<HouseholdRecord>(
        ValidationFailure(
          debugMessage: 'An address and a barangay are required.',
        ),
      );
    }
    final Result<ApiEnvelope<HouseholdRecord>> response = await _apiClient
        .send<HouseholdRecord>(
          method: HttpMethod.post,
          path: 'households',
          authenticated: true,
          body: <String, Object?>{'address': line, 'barangay_id': barangay},
          decode: _decodeRecord,
        );
    return response.map(
      (ApiEnvelope<HouseholdRecord> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<HouseholdRecord?>> loadCurrent() async {
    final Result<ApiEnvelope<HouseholdRecord>> response = await _apiClient
        .send<HouseholdRecord>(
          method: HttpMethod.get,
          path: currentPath,
          authenticated: true,
          decode: _decodeRecord,
        );
    return switch (response) {
      Err(:final failure) when failure is NotFoundFailure =>
        const Ok<HouseholdRecord?>(null),
      Err(:final failure) => Err<HouseholdRecord?>(failure),
      Ok(:final value) => Ok<HouseholdRecord?>(value.data),
    };
  }

  @override
  Future<Result<HouseholdRecord>> updateCurrent({
    String? address,
    String? barangayId,
  }) async {
    final Map<String, Object?> body = <String, Object?>{
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (barangayId != null && barangayId.trim().isNotEmpty)
        'barangay_id': barangayId.trim(),
    };
    if (body.isEmpty) {
      return const Err<HouseholdRecord>(
        ValidationFailure(debugMessage: 'Nothing to update.'),
      );
    }
    final Result<ApiEnvelope<HouseholdRecord>> response = await _apiClient
        .send<HouseholdRecord>(
          method: HttpMethod.patch,
          path: currentPath,
          authenticated: true,
          body: body,
          decode: _decodeRecord,
        );
    return response.map(
      (ApiEnvelope<HouseholdRecord> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<void>> deleteCurrent() async {
    final Result<ApiEnvelope<bool>> response = await _apiClient.send<bool>(
      method: HttpMethod.delete,
      path: currentPath,
      authenticated: true,
      decode: _decodeDeleted,
    );
    return _completed(response);
  }

  @override
  Future<Result<HouseholdMember>> addMember(HouseholdMemberDraft draft) async {
    final String name = draft.name.trim();
    if (name.isEmpty) {
      return const Err<HouseholdMember>(
        ValidationFailure(debugMessage: 'A name is required.'),
      );
    }
    final Map<String, Object?> body = <String, Object?>{
      'name': name,
      'relationship': draft.relationship.wireValue,
      if (draft.birthdate != null && draft.birthdate!.trim().isNotEmpty)
        'birthdate': draft.birthdate!.trim(),
      if (draft.sex != null) 'sex': draft.sex!.wireValue,
      if (draft.userId != null && draft.userId!.trim().isNotEmpty)
        'user_id': draft.userId!.trim(),
    };
    final Result<ApiEnvelope<HouseholdMember>> response = await _apiClient
        .send<HouseholdMember>(
          method: HttpMethod.post,
          path: 'households/current/members',
          authenticated: true,
          body: body,
          decode: _decodeMember,
        );
    return response.map(
      (ApiEnvelope<HouseholdMember> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<HouseholdMember>> updateMember({
    required String memberId,
    required HouseholdMemberChange change,
  }) async {
    if (memberId.trim().isEmpty || change.isEmpty) {
      return const Err<HouseholdMember>(
        ValidationFailure(debugMessage: 'A member and a change are required.'),
      );
    }
    final Map<String, Object?> body = <String, Object?>{
      if (change.name != null && change.name!.trim().isNotEmpty)
        'name': change.name!.trim(),
      if (change.relationship != null)
        'relationship': change.relationship!.wireValue,
      if (change.birthdate != null && change.birthdate!.trim().isNotEmpty)
        'birthdate': change.birthdate!.trim(),
      if (change.sex != null) 'sex': change.sex!.wireValue,
    };
    final Result<ApiEnvelope<HouseholdMember>> response = await _apiClient
        .send<HouseholdMember>(
          method: HttpMethod.patch,
          path: 'households/current/members/$memberId',
          authenticated: true,
          body: body,
          decode: _decodeMember,
        );
    return response.map(
      (ApiEnvelope<HouseholdMember> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<void>> removeMember(String memberId) async {
    if (memberId.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'A member is required.'),
      );
    }
    final Result<ApiEnvelope<bool>> response = await _apiClient.send<bool>(
      method: HttpMethod.delete,
      path: 'households/current/members/$memberId',
      authenticated: true,
      decode: _decodeDeleted,
    );
    return _completed(response);
  }

  @override
  Future<Result<void>> leaveHousehold() async {
    final Result<ApiEnvelope<bool>> response = await _apiClient.send<bool>(
      method: HttpMethod.post,
      path: 'households/current/leave',
      authenticated: true,
      decode: (Object? data) {
        final Map<String, dynamic> map = _map(data);
        if (map['left'] != true) {
          throw const FormatException('Household leave.');
        }
        return true;
      },
    );
    return response.map((_) {});
  }

  @override
  Future<Result<HouseholdRecord>> transferHeadship({
    required String memberId,
  }) async {
    if (memberId.trim().isEmpty) {
      return const Err<HouseholdRecord>(
        ValidationFailure(debugMessage: 'A member is required.'),
      );
    }
    final Result<ApiEnvelope<HouseholdRecord>> response = await _apiClient
        .send<HouseholdRecord>(
          method: HttpMethod.post,
          path: 'households/current/transfer',
          authenticated: true,
          body: <String, Object?>{'member_id': memberId.trim()},
          decode: _decodeRecord,
        );
    return response.map(
      (ApiEnvelope<HouseholdRecord> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<HouseholdInvitation?>> loadCurrentInvitation() async {
    final Result<ApiEnvelope<HouseholdInvitation>> response = await _apiClient
        .send<HouseholdInvitation>(
          method: HttpMethod.get,
          path: 'households/invitations/current',
          authenticated: true,
          decode: _decodeInvitation,
        );
    return switch (response) {
      Err(:final failure) when failure is NotFoundFailure =>
        const Ok<HouseholdInvitation?>(null),
      Err(:final failure) => Err<HouseholdInvitation?>(failure),
      Ok(:final value) => Ok<HouseholdInvitation?>(value.data),
    };
  }

  @override
  Future<Result<HouseholdRecord>> acceptInvitation(String invitationId) async {
    if (invitationId.trim().isEmpty) {
      return const Err<HouseholdRecord>(
        ValidationFailure(debugMessage: 'An invitation is required.'),
      );
    }
    final Result<ApiEnvelope<HouseholdRecord>> response = await _apiClient
        .send<HouseholdRecord>(
          method: HttpMethod.post,
          path: 'households/invitations/$invitationId/accept',
          authenticated: true,
          decode: _decodeRecord,
        );
    return response.map(
      (ApiEnvelope<HouseholdRecord> envelope) => envelope.data,
    );
  }

  @override
  Future<Result<void>> declineInvitation(String invitationId) async {
    if (invitationId.trim().isEmpty) {
      return const Err<void>(
        ValidationFailure(debugMessage: 'An invitation is required.'),
      );
    }
    final Result<ApiEnvelope<bool>> response = await _apiClient.send<bool>(
      method: HttpMethod.post,
      path: 'households/invitations/$invitationId/decline',
      authenticated: true,
      decode: (Object? data) {
        final Map<String, dynamic> map = _map(data);
        if (map['declined'] != true) {
          throw const FormatException('Household decline.');
        }
        return true;
      },
    );
    return response.map((_) {});
  }

  static Result<void> _completed(Result<ApiEnvelope<bool>> response) {
    return switch (response) {
      Err(:final failure) => Err<void>(failure),
      Ok(:final value) when value.data => const Ok<void>(null),
      Ok() => const Err<void>(
        ConflictFailure(debugMessage: 'The server did not confirm deletion.'),
      ),
    };
  }

  static HouseholdRecord _decodeRecord(Object? data) {
    final Map<String, dynamic> map = _map(data);
    final String? id = _text(map['id']);
    final String? address = _text(map['address']);
    final String? barangayId = _text(map['barangay_id']);
    final String? barangayName = _text(map['barangay_name']);
    final String? headUserId = _text(map['head_user_id']);
    final String? role = _text(map['viewer_role']);
    final DateTime? created = _instant(map['created_at']);
    final Object? rawMembers = map['members'];
    if (id == null ||
        address == null ||
        barangayId == null ||
        barangayName == null ||
        headUserId == null ||
        role == null ||
        created == null ||
        rawMembers is! List<dynamic>) {
      throw const FormatException('Household envelope.');
    }
    return HouseholdRecord(
      id: id,
      address: address,
      barangayId: barangayId,
      barangayName: barangayName,
      headUserId: headUserId,
      viewerRole: HouseholdViewerRole.fromWire(role),
      createdAt: created,
      members: rawMembers.map(_decodeMember).toList(growable: false),
    );
  }

  static HouseholdMember _decodeMember(Object? data) {
    final Map<String, dynamic> map = _map(data);
    final String? id = _text(map['id']);
    final String? name = _text(map['name']);
    final String? relationship = _text(map['relationship']);
    final String? invite = _text(map['invite_status']);
    if (id == null || name == null || relationship == null || invite == null) {
      throw const FormatException('Household member.');
    }
    final Object? user = map['user_id'];
    return HouseholdMember(
      id: id,
      name: name,
      relationship: HouseholdRelationship.fromWire(relationship),
      birthdate: _text(map['birthdate']),
      sex: HouseholdSex.fromWire(
        map['sex'] is String ? map['sex'] as String : null,
      ),
      userId: user is String && user.trim().isNotEmpty ? user.trim() : null,
      inviteStatus: HouseholdInviteStatus.fromWire(invite),
    );
  }

  static HouseholdInvitation _decodeInvitation(Object? data) {
    final Map<String, dynamic> map = _map(data);
    final String? id = _text(map['id']);
    final String? household = _text(map['household_id']);
    final String? address = _text(map['address']);
    final String? barangayId = _text(map['barangay_id']);
    final String? barangayName = _text(map['barangay_name']);
    if (id == null ||
        household == null ||
        address == null ||
        barangayId == null ||
        barangayName == null) {
      throw const FormatException('Household invitation.');
    }
    return HouseholdInvitation(
      id: id,
      householdId: household,
      address: address,
      barangayId: barangayId,
      barangayName: barangayName,
    );
  }

  static bool _decodeDeleted(Object? data) {
    final Map<String, dynamic> map = _map(data);
    return map['deleted'] == true;
  }

  static Map<String, dynamic> _map(Object? data) {
    return data is Map<String, dynamic> ? data : const <String, dynamic>{};
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _instant(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim())?.toUtc();
  }
}
