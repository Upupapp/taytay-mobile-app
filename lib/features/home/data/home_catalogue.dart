import 'dart:convert';

import '../../../core/mock/mock_fixtures.dart';
import '../domain/home_content.dart';

/// The designed Home catalogue. Slides are the published municipal features.
/// News rows and hotline numbers are dev-mock fixtures: a live build prefers
/// `GET /home` and the announcements feed, and only falls back here in a
/// dev mock build.
abstract final class HomeCatalogue {
  static Future<List<HomeSlide>> slides() async {
    final Map<String, Object?> json = await _json();
    return _slides(json['slides']);
  }

  static Future<({List<HomeNewsItem> news, List<HomeHotline> hotlines})>
  mockFeed() async {
    final Map<String, Object?> json = await _json();
    return (news: _news(json['news']), hotlines: _hotlines(json['hotlines']));
  }

  static Future<Map<String, Object?>> _json() async {
    final Object? decoded = jsonDecode(
      await MockFixtures.text('home_catalogue'),
    );
    if (decoded is! Map) return const <String, Object?>{};
    return decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }

  static List<HomeSlide> _slides(Object? raw) {
    if (raw is! List) return const <HomeSlide>[];
    return <HomeSlide>[
          for (final Object? row in raw)
            if (row is Map)
              HomeSlide(
                eyebrow: _s(row['eyebrow']),
                title: _s(row['title']),
                body: _s(row['body']),
                action: _s(row['action']),
                photoAsset: _s(row['photo']),
                credit: _s(row['credit']),
                routeName: _s(row['route']),
              ),
        ]
        .where((HomeSlide slide) => slide.title.isNotEmpty)
        .toList(growable: false);
  }

  static List<HomeNewsItem> _news(Object? raw) {
    if (raw is! List) return const <HomeNewsItem>[];
    return <HomeNewsItem>[
          for (final Object? row in raw)
            if (row is Map)
              HomeNewsItem(
                id: _s(row['id']),
                eyebrow: _s(row['eyebrow']),
                title: _s(row['title']),
                alert: row['alert'] == true,
              ),
        ]
        .where((HomeNewsItem item) => item.title.isNotEmpty)
        .toList(growable: false);
  }

  static List<HomeHotline> _hotlines(Object? raw) {
    if (raw is! List) return const <HomeHotline>[];
    return <HomeHotline>[
          for (final Object? row in raw)
            if (row is Map)
              HomeHotline(
                id: _s(row['id']),
                name: _s(row['name']),
                number: _s(row['number']),
                category: _s(row['category']),
              ),
        ]
        .where((HomeHotline line) => line.number.isNotEmpty)
        .toList(growable: false);
  }

  static String _s(Object? value) => value is String ? value : '';
}
