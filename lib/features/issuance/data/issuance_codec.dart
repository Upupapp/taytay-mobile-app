import '../../../core/documents/upload_policy.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_status.dart';
import '../domain/issuance_type.dart';

/// Reads the issuance wire shapes. Allow-list decoders: every key read is
/// named, everything else is walked past (API conventions §1), so an office
/// field added to the resident view later cannot land in a widget by accident.
abstract final class IssuanceCodec {
  static const Map<String, IssuanceStatus> _statuses = <String, IssuanceStatus>{
    'submitted': IssuanceStatus.submitted,
    'under-review': IssuanceStatus.underReview,
    'needs-info': IssuanceStatus.needsInfo,
    'approved': IssuanceStatus.approved,
    'ready-for-pickup': IssuanceStatus.readyForPickup,
    'released': IssuanceStatus.released,
    'rejected': IssuanceStatus.rejected,
    'cancelled': IssuanceStatus.cancelled,
  };

  /// `null` for a status this build does not know. It is shown as "Updated",
  /// never guessed at.
  static IssuanceStatus? status(Object? raw) =>
      raw is String ? _statuses[raw] : null;

  /// The wire value, for the mock store that speaks the same shapes.
  static String wireStatus(IssuanceStatus status) =>
      _statuses.entries.firstWhere((entry) => entry.value == status).key;

  static List<IssuanceType> typeList(Object? data) {
    if (data is! List<dynamic>) return const <IssuanceType>[];
    return <IssuanceType>[
      for (final Object? entry in data)
        if (type(entry) case final IssuanceType decoded) decoded,
    ];
  }

  /// A type, or `null` when the entry lacks an id or a name.
  static IssuanceType? type(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final String? id = _text(data['id']);
    final String? name = _text(data['name']);
    if (id == null || name == null) return null;
    final Object? office = data['office'];
    final Map<String, dynamic> officeMap = office is Map<String, dynamic>
        ? office
        : const <String, dynamic>{};
    return IssuanceType(
      id: id,
      name: name,
      description: _text(data['description']),
      officeId: _text(officeMap['id']) ?? '',
      officeName: _text(officeMap['name']) ?? 'Taytay municipal office',
      requirements: requirements(data['requirements']),
      feeCentavos: _int(data['fee_centavos']),
      processingDays: _int(data['processing_days']),
      claimInstructions: _text(data['claim_instructions']),
      uploadPolicy: UploadPolicy.decode(data['accepts']),
    );
  }

  static List<IssuanceRequirement> requirements(Object? data) {
    if (data is! List<dynamic>) return const <IssuanceRequirement>[];
    return <IssuanceRequirement>[
      for (final Object? entry in data)
        if (entry is Map<String, dynamic>)
          if ((_text(entry['code']), _text(entry['label'])) case (
            final String code,
            final String label,
          ))
            IssuanceRequirement(
              code: code,
              label: label,
              // Only a real `true` makes a file required. A missing flag must
              // not stop a resident sending a request the office would take.
              required: entry['required'] == true,
              hint: _text(entry['hint']),
            ),
    ];
  }

  static List<IssuanceRequestSummary> summaryList(Object? data) {
    if (data is! List<dynamic>) return const <IssuanceRequestSummary>[];
    return <IssuanceRequestSummary>[
      for (final Object? entry in data)
        if (summary(entry) case final IssuanceRequestSummary decoded) decoded,
    ];
  }

  static IssuanceRequestSummary? summary(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final String? id = _text(data['id']);
    if (id == null) return null;
    return IssuanceRequestSummary(
      id: id,
      referenceNumber: _text(data['reference_number']) ?? '',
      status: status(data['status']),
      typeName: _name(data['type']) ?? 'Document request',
      typeId: _id(data['type']),
      officeName: _name(data['office']) ?? 'Taytay municipal office',
      createdAt: _time(data['created_at']),
      updatedAt: _time(data['updated_at']),
    );
  }

  /// The resident view of one request. `null` when it has no id.
  static IssuanceRequestDetail? detail(Object? data) {
    final IssuanceRequestSummary? head = summary(data);
    if (head == null || data is! Map<String, dynamic>) return null;
    return IssuanceRequestDetail(
      summary: head,
      purpose: _text(data['purpose']) ?? '',
      requirements: requirements(data['requirements']),
      attachments: _attachments(data['attachments']),
      history: _history(data['history']),
      // Only a real `true` offers the act. A missing flag offers nothing; the
      // server would refuse a move it did not say was open.
      canCancel: data['can_cancel'] == true,
      canResubmit: data['can_resubmit'] == true,
      feeCentavos: _int(data['fee_centavos']),
      processingDays: _int(data['processing_days']),
      claimInstructions: _text(data['claim_instructions']),
      claimDetails: _text(data['claim_details']),
      needsInfoMessage: _text(data['needs_info_message']),
    );
  }

  static List<IssuanceAttachment> _attachments(Object? data) {
    if (data is! List<dynamic>) return const <IssuanceAttachment>[];
    return <IssuanceAttachment>[
      for (final Object? entry in data)
        if (entry is Map<String, dynamic>)
          if ((_text(entry['id']), _text(entry['requirement_code'])) case (
            final String id,
            final String code,
          ))
            IssuanceAttachment(
              id: id,
              requirementCode: code,
              version: _int(entry['version']) ?? 1,
              mimeType: _text(entry['mime_type']) ?? '',
              byteSize: _int(entry['byte_size']) ?? 0,
              current: entry['current'] == true,
              createdAt: _time(entry['created_at']),
            ),
    ];
  }

  static List<IssuanceHistoryEntry> _history(Object? data) {
    if (data is! List<dynamic>) return const <IssuanceHistoryEntry>[];
    return <IssuanceHistoryEntry>[
      for (final Object? entry in data)
        if (entry is Map<String, dynamic>)
          IssuanceHistoryEntry(
            from: status(entry['from_status']),
            to: status(entry['to_status']),
            by: switch (entry['by']) {
              'resident' => IssuanceActor.resident,
              'office' => IssuanceActor.office,
              _ => IssuanceActor.unknown,
            },
            // `description` is the server's sentence; this app writes its own
            // (`issuanceHistoryLine`). `message` is the office's or the
            // resident's own words and is kept as written.
            message: _text(entry['message']),
            claimDetails: _text(entry['claim_details']),
            at: _time(entry['at']),
          ),
    ];
  }

  static String? _id(Object? value) =>
      value is Map<String, dynamic> ? _text(value['id']) : null;

  static String? _name(Object? value) =>
      value is Map<String, dynamic> ? _text(value['name']) : null;

  static String? _text(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _int(Object? value) => value is int ? value : null;

  static DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;
}
