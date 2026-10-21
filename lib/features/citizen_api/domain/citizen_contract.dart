import 'package:flutter/foundation.dart';

/// A published home banner. The bytes live behind [mediaId].
@immutable
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.active,
    this.mediaId,
    this.href,
  });

  final String id;
  final String title;
  final int sortOrder;
  final bool active;
  final String? mediaId;
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
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String number;
  final String category;
  final int sortOrder;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  String toString() => 'MunicipalHotline($id, $category)';
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
