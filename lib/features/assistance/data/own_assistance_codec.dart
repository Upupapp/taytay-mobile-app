import '../../../core/api/server_value.dart';
import '../domain/own_assistance_request.dart';

/// Reads `OwnAssistanceRequest` rows (`GET /me/assistance-requests`, D-223).
///
/// Explicit, field by field. Unknown fields are ignored (Article 8); a row
/// with no id is dropped, because a row nobody can name cannot be opened from
/// its notice or quoted at the counter. Every other missing or malformed field
/// reads as absent, never as a guessed value.
abstract final class OwnAssistanceCodec {
  static List<OwnAssistanceRequest> list(Object? data) {
    if (data is! List<dynamic>) return const <OwnAssistanceRequest>[];
    return <OwnAssistanceRequest>[
      for (final Object? entry in data)
        if (row(entry) case final OwnAssistanceRequest decoded) decoded,
    ];
  }

  static OwnAssistanceRequest? row(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final String? id = _text(data['id']);
    if (id == null) return null;
    return OwnAssistanceRequest(
      id: id,
      referenceNumber: _text(data['reference_number']) ?? '',
      programName: _text(data['program_name']),
      filedAt: _instant(data['filed_at']),
      status: status(data['status']),
      statusChangedAt: _instant(data['status_changed_at']),
      approvedAmountCentavos: _centavos(data['approved_amount_centavos']),
      payoutScheduledFor: _day(data['payout_scheduled_for']),
      payoutVenue: _text(data['payout_venue']),
      releasedAt: _instant(data['released_at']),
      channel: switch (data['channel']) {
        'online' => AssistanceChannel.online,
        'office' => AssistanceChannel.office,
        'imported' => AssistanceChannel.imported,
        _ => null,
      },
      sourceReference: _text(data['source_reference']),
      missingDocuments: _missing(data['missing_documents']),
    );
  }

  /// `missing_documents` (D-226). A row with no code or no name is dropped:
  /// nothing could be sent for it, or said about it.
  static List<MissingDocument> _missing(Object? raw) {
    if (raw is! List<dynamic>) return const <MissingDocument>[];
    final List<MissingDocument> rows = <MissingDocument>[];
    for (final Object? entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final String? code = _text(entry['code']);
      final String? name = _text(entry['name']);
      if (code == null || name == null) continue;
      rows.add(
        MissingDocument(
          code: code,
          name: name,
          state: switch (entry['state']) {
            'not-sent' => MissingDocumentState.notSent,
            'send-again' => MissingDocumentState.sendAgain,
            _ => MissingDocumentState.other,
          },
          instruction: _text(entry['instruction']),
        ),
      );
    }
    return List<MissingDocument>.unmodifiable(rows);
  }

  static ServerValue<AssistanceRequestStatus> status(Object? raw) =>
      ServerValue.parse<AssistanceRequestStatus>(
        raw is String ? raw : null,
        AssistanceRequestStatus.values,
        (AssistanceRequestStatus s) => s.wireValue,
      );

  static String? _text(Object? raw) {
    if (raw is! String) return null;
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _instant(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  /// Integer centavos only. A fractional or negative number is not an amount
  /// the office approved, so it is not shown as one.
  static int? _centavos(Object? raw) => raw is int && raw >= 0 ? raw : null;

  /// A date-only value (`2026-11-20`) is that calendar day, read as UTC
  /// midnight so the Manila clock shows the same day. A timestamp is the
  /// instant it names.
  static DateTime? _day(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final RegExpMatch? day = _dayOnly.firstMatch(raw);
    if (day == null) return DateTime.tryParse(raw)?.toUtc();
    final int? year = int.tryParse(day.group(1) ?? '');
    final int? month = int.tryParse(day.group(2) ?? '');
    final int? date = int.tryParse(day.group(3) ?? '');
    if (year == null || month == null || date == null) return null;
    return DateTime.utc(year, month, date);
  }

  static final RegExp _dayOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
}
