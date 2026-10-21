import 'package:flutter/foundation.dart';

import '../../../core/session/access_level.dart';

/// What Home shows, in order.
///
/// A guest and an unverified resident get a status card. A verified resident
/// does not. Nothing here is a personal record: news and hotlines are public,
/// and the status card is a sentence about the session the app already holds.
enum HomeSection {
  greeting,
  statusCard,
  carousel,
  quickActions,
  news,
  hotline;

  bool get isPersonal => false;
}

@immutable
class HomeEmphasis {
  const HomeEmphasis._({required this.level, required this.sections});

  final AccessLevel level;
  final List<HomeSection> sections;

  bool contains(HomeSection section) => sections.contains(section);

  static HomeEmphasis forLevel(AccessLevel level) {
    return HomeEmphasis._(
      level: level,
      sections: <HomeSection>[
        HomeSection.greeting,
        if (level != AccessLevel.verified) HomeSection.statusCard,
        HomeSection.carousel,
        HomeSection.quickActions,
        HomeSection.news,
        HomeSection.hotline,
      ],
    );
  }

  List<HomeSection> get personalSections =>
      sections.where((HomeSection section) => section.isPersonal).toList();
}
