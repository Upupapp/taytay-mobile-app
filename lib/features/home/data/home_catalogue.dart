import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/mock/mock_fixtures.dart';
import '../../citizen_api/domain/citizen_contract.dart';
import '../domain/home_content.dart';

/// The designed Home catalogue.
///
/// Hero slides ship in `assets/home/slides.json`. A live build reads that
/// asset, and replaces a slide's title and route when `GET /home` returns an
/// active banner. News rows and hotline numbers stay dev-mock fixtures: a
/// live build prefers the announcements feed and `GET /home`, and only falls
/// back here in a dev mock build.
abstract final class HomeCatalogue {
  static const String slidesAsset = 'assets/home/slides.json';

  /// Parsed once. A later call returns a [SynchronousFuture] created in the
  /// caller's zone: the asset bundle caches the first load's [Future], and
  /// awaiting that same future from a later test never resumes.
  static List<HomeSlide>? _parsedSlides;

  static Future<List<HomeSlide>> slides() {
    final List<HomeSlide>? parsed = _parsedSlides;
    if (parsed != null) return SynchronousFuture<List<HomeSlide>>(parsed);
    return _readSlides();
  }

  static Future<List<HomeSlide>> _readSlides() async {
    final Object? decoded = jsonDecode(
      await rootBundle.loadString(slidesAsset),
    );
    if (decoded is! Map) return const <HomeSlide>[];
    final List<HomeSlide> parsed = _slides(decoded['slides']);
    _parsedSlides = parsed;
    return parsed;
  }

  /// Banner titles and links from `/home`, with the bundled photograph kept
  /// until `image_url` is set. The bytes are `GET /home/banners/{id}/image`.
  static List<HomeSlide> withBanners(
    List<HomeSlide> bundled,
    List<HomeBanner> banners,
  ) {
    if (bundled.isEmpty) return bundled;
    final List<HomeBanner> active =
        banners.where((HomeBanner banner) => banner.active).toList()..sort(
          (HomeBanner a, HomeBanner b) => a.sortOrder.compareTo(b.sortOrder),
        );
    if (active.isEmpty) return bundled;
    return <HomeSlide>[
      for (var i = 0; i < active.length; i++)
        _fromBanner(
          active[i],
          bundled[i < bundled.length ? i : bundled.length - 1],
        ),
    ];
  }

  /// A banner carries a title, a link and an image, and nothing else. The
  /// bundled slide's eyebrow, sentence and button were written for another
  /// message, so they are not shown under the office's title: the eyebrow and
  /// the button name where the banner goes, and there is no sentence.
  static HomeSlide _fromBanner(HomeBanner banner, HomeSlide fallback) {
    final String route = _route(banner.href, fallback.routeName);
    return HomeSlide(
      eyebrow: _eyebrowFor(route),
      title: banner.title,
      body: '',
      action: _actionFor(route),
      photoAsset: fallback.photoAsset,
      credit: fallback.credit,
      routeName: route,
      focus: fallback.focus,
      bannerId: _bannerId(banner),
    );
  }

  static String _eyebrowFor(String route) => switch (route) {
    'news' => 'BALITA',
    'programs' => 'TULONG',
    'services' => 'DIRECTORY',
    'hotlines' => 'HOTLINES',
    'events' => 'EVENTS',
    _ => 'TAYTAY LGU',
  };

  static String _actionFor(String route) => switch (route) {
    'news' => 'Read Balita',
    'programs' => 'Explore Tulong',
    'services' => 'Open Directory',
    'hotlines' => 'See hotlines',
    'events' => 'See events',
    _ => 'Open',
  };

  static String? _bannerId(HomeBanner banner) {
    final String? url = banner.imageUrl;
    if (url == null || url.isEmpty) return null;
    return banner.id;
  }

  /// The route a banner's link names. Every value is an `AppRoute` name, so
  /// the slide's button resolves when Home calls `goNamed`.
  ///
  /// Events is not on the tab bar (D-178). A banner whose link names events is
  /// the way into it, and the office sets banners from the staff console's
  /// home screen page, so promoting an event stays in its hands (D-192).
  static String _route(String? href, String fallback) {
    if (href == null || href.isEmpty) return fallback;
    final String path = Uri.tryParse(href)?.path ?? href;
    if (path.contains('program')) return 'programs';
    if (path.contains('service')) return 'services';
    if (path.contains('hotline')) return 'hotlines';
    if (path.contains('news')) return 'news';
    if (path.contains('event')) return 'events';
    return fallback;
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
                focus: row['focus'] is num
                    ? (row['focus'] as num).toDouble()
                    : 0.35,
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
