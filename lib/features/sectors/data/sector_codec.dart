import '../domain/resident_sector.dart';

/// The wire shapes of `GET /me/sectors`, `GET /me/sector-applications` and
/// `POST /me/sector-applications` (citizen pack B4; backend `OwnSector`,
/// `OwnSectorApplication`, `SectorApplicationBody`), read one way.
///
/// **An allow-list in both directions.** A sector the table below does not
/// name is dropped with its row, so `vawc-survivor`, `cicl` or `four-ps` sent
/// by mistake is never drawn and never held (D-13, D-215). An unknown
/// application status drops its row the same way (D-35). Unknown fields
/// (`decided_at`) are ignored.
abstract final class SectorCodec {
  static const Map<String, ResidentSector> _sectors = <String, ResidentSector>{
    'senior-citizen': ResidentSector.seniorCitizen,
    'pwd': ResidentSector.pwd,
    'solo-parent': ResidentSector.soloParent,
  };

  static const Map<String, SectorApplicationStatus> _statuses =
      <String, SectorApplicationStatus>{
        'pending': SectorApplicationStatus.pending,
        'approved': SectorApplicationStatus.approved,
        'returned': SectorApplicationStatus.returned,
      };

  /// The wire value of a sector, for the application body.
  static String wireSector(ResidentSector sector) => switch (sector) {
    ResidentSector.seniorCitizen => 'senior-citizen',
    ResidentSector.pwd => 'pwd',
    ResidentSector.soloParent => 'solo-parent',
  };

  static ResidentSector? sector(Object? raw) =>
      raw is String ? _sectors[raw] : null;

  static List<OwnSector> ownList(Object? data) => <OwnSector>[
    for (final Object? row in _rows(data))
      if (own(row) case final OwnSector value) value,
  ];

  static OwnSector? own(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final ResidentSector? kind = sector(raw['sector']);
    if (kind == null) return null;
    return OwnSector(
      sector: kind,
      since: _date(raw['since']),
      idLastFour: lastFour(raw['id_number']),
      validUntil: _date(raw['valid_until']),
    );
  }

  static List<SectorApplication> applicationList(Object? data) =>
      <SectorApplication>[
        for (final Object? row in _rows(data))
          if (application(row) case final SectorApplication value) value,
      ];

  static SectorApplication? application(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final Object? id = raw['id'];
    final ResidentSector? kind = sector(raw['sector']);
    final Object? status = raw['status'];
    final SectorApplicationStatus? decided = status is String
        ? _statuses[status]
        : null;
    if (id is! String || id.isEmpty || kind == null || decided == null) {
      return null;
    }
    final Object? reason = raw['reason'];
    return SectorApplication(
      id: id,
      sector: kind,
      status: decided,
      reason: reason is String && reason.trim().isNotEmpty
          ? reason.trim()
          : null,
      submittedAt: _date(raw['submitted_at']),
    );
  }

  /// The body of `POST /me/sector-applications`: the sector and the proof,
  /// nothing else.
  static Map<String, Object?> applicationBody({
    required ResidentSector sector,
    required List<String> proofMediaIds,
  }) => <String, Object?>{
    'sector': wireSector(sector),
    'proof_media_ids': List<String>.of(proofMediaIds),
  };

  /// The last four characters of an ID number, and never more.
  ///
  /// The server holds only four (DL-183, migration 0056) and sends them
  /// masked, `••••1234`. The mask goes, and if a longer value ever arrived the
  /// rest is cut here, before anything holds it.
  static String? lastFour(Object? raw) {
    if (raw is! String) return null;
    final String trimmed = raw.replaceAll('•', '').trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length <= 4
        ? trimmed
        : trimmed.substring(trimmed.length - 4);
  }

  /// `POST /media`'s id.
  static String? mediaId(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final Object? id = data['id'];
    return id is String && id.isNotEmpty ? id : null;
  }

  static Iterable<Object?> _rows(Object? data) =>
      data is List<dynamic> ? data : const <Object?>[];

  /// A date-only value (`2026-11-02`) is that calendar day, read as UTC so
  /// the Manila clock shows the same day. A timestamp is the instant it names.
  static DateTime? _date(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final RegExpMatch? day = _dayOnly.firstMatch(raw);
    if (day != null) {
      final int? year = int.tryParse(day.group(1) ?? '');
      final int? month = int.tryParse(day.group(2) ?? '');
      final int? date = int.tryParse(day.group(3) ?? '');
      if (year == null || month == null || date == null) return null;
      return DateTime.utc(year, month, date);
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  static final RegExp _dayOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
}
