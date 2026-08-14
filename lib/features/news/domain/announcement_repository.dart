import 'package:flutter/foundation.dart';

import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';

/// One municipal announcement — `balita`.
///
/// Public content by contract: `GET /api/v1/announcements` carries no `auth`
/// column entry and is marked `public`. Nothing here is personal data, which is
/// why the whole feature is readable by a guest and why an announcement id is
/// safe to put in a push notification.
@immutable
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.publishedAt,
    this.category,
  });

  /// Opaque server identifier. The deep-link target for `news_post`.
  final String id;

  final String title;
  final String body;
  final DateTime? publishedAt;

  /// The server's own label, preserved and shown as sent. Not mapped to an enum
  /// because the app takes no decision from it — an unrecognised category should
  /// display, not disappear.
  final String? category;

  @override
  String toString() => 'Announcement($id)';
}

/// Municipal announcements, as the committed contract describes them.
///
/// Two calls, both public, both paginated per `docs/api/conventions.md` §5.
/// Nothing is invented: the list row exists in the endpoint matrix (§12), and
/// the detail read is the same collection addressed by id — which is what the
/// notification deep link needs and what the conventions' resource shape
/// implies. Should the backend ship the list without a detail route, this is
/// the one method that changes.
abstract interface class AnnouncementRepository {
  Future<Result<Paginated<Announcement>>> listAnnouncements({
    int page,
    int perPage,
  });

  /// One announcement by opaque id.
  ///
  /// A `404` is an ordinary outcome here, not an error to hide: an announcement
  /// can be withdrawn between the notification being sent and the resident
  /// tapping it, and the screen says so plainly.
  Future<Result<Announcement>> loadAnnouncement(String id);
}
