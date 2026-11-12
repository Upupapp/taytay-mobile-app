import 'package:flutter/foundation.dart';

import '../../citizen_api/domain/citizen_contract.dart';

/// One slide of the Home hero. Municipal copy, not a resident record.
@immutable
class HomeSlide {
  const HomeSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.action,
    required this.photoAsset,
    required this.credit,
    required this.routeName,
    this.focus = 0.35,
    this.bannerId,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String action;
  final String photoAsset;
  final String credit;

  /// `goNamed` target: news, programs, or services.
  final String routeName;

  /// CSS `background-position` vertical fraction. 0 is the top of the photo.
  final double focus;

  /// Set when the banner's `image_url` says a picture is stored.
  /// The bytes are `GET /home/banners/{id}/image`. Null keeps the bundled photo.
  final String? bannerId;

  @override
  String toString() => 'HomeSlide($routeName)';
}

/// A row in the Home news teaser.
@immutable
class HomeNewsItem {
  const HomeNewsItem({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.alert,
  });

  final String id;
  final String eyebrow;
  final String title;

  /// Safety rows use the red tile. Advisories use the blue tile.
  final bool alert;

  @override
  String toString() => 'HomeNewsItem($id)';
}

/// A published hotline. The number is a public office line.
@immutable
class HomeHotline {
  const HomeHotline({
    required this.id,
    required this.name,
    required this.number,
    required this.category,
    this.kind = HotlineKind.other,
  });

  final String id;
  final String name;
  final String number;
  final String category;

  /// What the line is for (`kind`). The Hotlines page draws an emergency
  /// tile from it, never from the name (D-214).
  final HotlineKind kind;

  bool get isBarangay => category.toLowerCase().contains('barangay');

  @override
  String toString() => 'HomeHotline($id, $category)';
}
