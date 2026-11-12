import 'package:flutter/foundation.dart';

/// A sector the signed-in resident may see on their own record (D-215).
///
/// **A closed allow-list of three**, the ones `GET /me/sectors` sends and
/// `POST /me/sector-applications` takes. Every other sector stays with the
/// office: `vawc-survivor` (RA 9262) and `cicl` (RA 9344) above all, and also
/// 4Ps and the rest, which the MSWDO records in person. A sector the decoder
/// does not know is dropped with its row, never shown as "Other". Indigency,
/// income and other household members' sectors are not sectors here at all
/// (D-13).
enum ResidentSector { seniorCitizen, pwd, soloParent }

/// One sector on the resident's record, as `GET /me/sectors` sends it.
@immutable
class OwnSector {
  const OwnSector({
    required this.sector,
    this.since,
    this.idLastFour,
    this.validUntil,
  });

  final ResidentSector sector;

  /// The day the office last recorded it.
  final DateTime? since;

  /// The last four characters of the sector ID, never more (the console's
  /// DL-183). The server sends them masked; the decoder keeps the four.
  final String? idLastFour;

  /// When the sector ID stops being valid, if the office recorded it.
  final DateTime? validUntil;

  /// Whether the recorded ID has passed its validity date on the Manila
  /// calendar. A record with no date never lapses here. Said on the row; it
  /// decides nothing.
  bool lapsedOn(DateTime today) {
    final DateTime? until = validUntil;
    if (until == null) return false;
    return _day(until).isBefore(_day(today));
  }

  /// Redacted: the ID digits are the resident's.
  @override
  String toString() => 'OwnSector(${sector.name})';
}

/// Where an application for a sector stands. The wire sends three; anything
/// else is not drawn.
enum SectorApplicationStatus { pending, approved, returned }

/// One of the resident's own applications, as `GET /me/sector-applications`
/// sends it.
@immutable
class SectorApplication {
  const SectorApplication({
    required this.id,
    required this.sector,
    required this.status,
    this.reason,
    this.submittedAt,
  });

  /// Opaque server id. Never shown and never put in a route.
  final String id;
  final ResidentSector sector;
  final SectorApplicationStatus status;

  /// Why the office returned it, in the office's words to the resident. The
  /// server sends one only for a returned application.
  final String? reason;
  final DateTime? submittedAt;

  @override
  String toString() => 'SectorApplication(${sector.name}, ${status.name})';
}

/// What the Sectors and benefits page draws, from the two reads.
///
/// Pure: it decides what to *show*, never what the office will allow. The
/// server answers every application, whatever this page offers.
@immutable
class SectorOverview {
  SectorOverview({
    required List<OwnSector> recorded,
    required List<SectorApplication> applications,
  }) : recorded = List<OwnSector>.unmodifiable(recorded),
       latest = List<SectorApplication>.unmodifiable(
         _latestPerSector(applications),
       );

  final List<OwnSector> recorded;

  /// The newest application for each sector, newest first.
  final List<SectorApplication> latest;

  /// Applications still worth a row: being checked, or returned. An approved
  /// one is the recorded sector's row; a second row would say it twice.
  List<SectorApplication> get open => <SectorApplication>[
    for (final SectorApplication application in latest)
      if (application.status != SectorApplicationStatus.approved) application,
  ];

  bool get isEmpty => recorded.isEmpty && open.isEmpty;

  /// The sectors the page offers to apply for: neither on the record nor
  /// being checked, the two the server refuses with a conflict. A returned
  /// application is offered again.
  List<ResidentSector> get offered => <ResidentSector>[
    for (final ResidentSector sector in ResidentSector.values)
      if (!_pending(sector) && !_held(sector)) sector,
  ];

  bool _pending(ResidentSector sector) => latest.any(
    (SectorApplication application) =>
        application.sector == sector &&
        application.status == SectorApplicationStatus.pending,
  );

  bool _held(ResidentSector sector) =>
      recorded.any((OwnSector own) => own.sector == sector);

  static List<SectorApplication> _latestPerSector(
    List<SectorApplication> applications,
  ) {
    final List<SectorApplication> sorted = List<SectorApplication>.of(
      applications,
    )..sort(_newestFirst);
    final Set<ResidentSector> seen = <ResidentSector>{};
    return <SectorApplication>[
      for (final SectorApplication application in sorted)
        if (seen.add(application.sector)) application,
    ];
  }

  /// Newest first; an undated application sorts last.
  static int _newestFirst(SectorApplication a, SectorApplication b) {
    final DateTime? left = a.submittedAt;
    final DateTime? right = b.submittedAt;
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }
}

/// The Manila calendar day of an instant, as a UTC midnight.
DateTime _day(DateTime instant) {
  final DateTime manila = instant.toUtc().add(const Duration(hours: 8));
  return DateTime.utc(manila.year, manila.month, manila.day);
}
