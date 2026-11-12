import 'package:flutter/foundation.dart';

/// A published home banner. [imageUrl] points at the public image route.
@immutable
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.active,
    this.mediaId,
    this.imageUrl,
    this.href,
  });

  final String id;
  final String title;
  final int sortOrder;
  final bool active;
  final String? mediaId;

  /// Absolute URL of `GET /home/banners/{id}/image` when a picture is stored.
  /// The app does not open this host. It requests the path on the configured base.
  final String? imageUrl;

  final String? href;

  @override
  String toString() => 'HomeBanner($id)';
}

/// A home shortcut. [href] is a path the app already knows.
@immutable
class HomeQuickLink {
  const HomeQuickLink({
    required this.id,
    required this.label,
    required this.href,
    required this.sortOrder,
  });

  final String id;
  final String label;
  final String href;
  final int sortOrder;

  @override
  String toString() => 'HomeQuickLink($id)';
}

/// What a hotline is for (`kind`, backend `ebd7aeb`).
///
/// A closed set the office picks from, so a client chooses a line by what it
/// is for rather than by its name or its free-text category, which are staff
/// copy (D-196, D-214). At most one *active* line is the
/// [commandCenter]; the database refuses a second.
enum HotlineKind {
  /// The municipality's own command or operations center: the line an
  /// emergency note offers first.
  commandCenter('command-center'),

  /// A general emergency line, such as 911 (EO 56 s.2018).
  emergency('emergency'),
  police('police'),
  fire('fire'),
  medical('medical'),
  disaster('disaster'),

  /// Anything else, and what an unknown or missing kind reads as: a line is
  /// never promoted to an emergency line by a value this build does not know.
  other('other');

  const HotlineKind(this.wireValue);

  final String wireValue;

  /// Whether the line is for an emergency of some kind. [other] is not.
  bool get isEmergency => this != HotlineKind.other;

  static HotlineKind parse(Object? raw) {
    for (final HotlineKind kind in values) {
      if (kind.wireValue == raw) return kind;
    }
    return HotlineKind.other;
  }
}

/// A published municipal hotline. The number is a public office line.
@immutable
class MunicipalHotline {
  const MunicipalHotline({
    required this.id,
    required this.name,
    required this.number,
    required this.category,
    required this.sortOrder,
    required this.active,
    this.kind = HotlineKind.other,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String number;
  final String category;

  /// What the line is for. Chosen by the office; never guessed from [name].
  final HotlineKind kind;
  final int sortOrder;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  String toString() => 'MunicipalHotline($id, ${kind.wireValue})';
}

/// The active line the office marked as the command center, if any.
///
/// Picked by `kind` alone (D-214): never by a name, a category or the sort
/// order, which are staff copy. The database allows one active
/// `command-center`; should two ever arrive, the first in the server's order
/// is taken. A line with no number is not one a resident can call.
MunicipalHotline? activeCommandCenter(Iterable<MunicipalHotline> lines) {
  for (final MunicipalHotline line in lines) {
    if (!line.active || line.kind != HotlineKind.commandCenter) continue;
    if (line.number.trim().isEmpty || line.name.trim().isEmpty) continue;
    return line;
  }
  return null;
}

/// `GET /home`: banners, shortcuts, news, services, and hotlines.
/// The rows themselves are fetched again from their own routes when a screen
/// opens one. The hotline screen is still the later-sprint placeholder.
@immutable
class HomeFeed {
  const HomeFeed({
    required this.banners,
    required this.quickLinks,
    required this.newsIds,
    required this.serviceSlugs,
    this.hotlines = const <MunicipalHotline>[],
  });

  final List<HomeBanner> banners;
  final List<HomeQuickLink> quickLinks;
  final List<String> newsIds;
  final List<String> serviceSlugs;
  final List<MunicipalHotline> hotlines;

  @override
  String toString() =>
      'HomeFeed(${banners.length} banners, ${quickLinks.length} links, '
      '${hotlines.length} hotlines)';
}

/// A municipal office page. Public resident information.
@immutable
class MunicipalOffice {
  const MunicipalOffice({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.head = '',
    this.hours = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.category = '',
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String head;
  final String hours;
  final String phone;
  final String email;
  final String address;
  final String category;

  @override
  String toString() => 'MunicipalOffice($slug)';
}

/// Metadata for an uploaded file. The bytes are not kept on the model.
@immutable
class MediaRecord {
  const MediaRecord({
    required this.id,
    required this.contentType,
    required this.byteSize,
  });

  final String id;
  final String contentType;
  final int byteSize;

  @override
  String toString() => 'MediaRecord($id, $contentType, $byteSize bytes)';
}
