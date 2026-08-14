import 'package:flutter/foundation.dart';

import '../../../core/session/access_level.dart';

/// A block Home can show, and the order it appears in.
///
/// ---
///
/// **Declared as data, not as `if` statements in a build method.** Home is the
/// one screen whose contents differ by access level, which makes it the screen
/// most likely to leak something to the wrong person. Expressing the layout as a
/// list means a test can assert what a guest's Home contains — and, more to the
/// point, what it does not — without pumping a widget and reading pixels.
enum HomeSection {
  /// Gradient banner: who this is, and one action.
  hero,

  /// The "what can I do now?" card. At most one, chosen by state.
  nextAction,

  /// Latest municipal announcements, public.
  news,

  /// Upcoming LGU events, public.
  events,

  /// The service catalogue, public.
  services,

  /// The resident's own assistance requests. Verified only.
  requests,

  /// Where to go when the app cannot help. Always last, always present.
  municipalHall;

  /// Whether this section reads data scoped to the signed-in resident.
  ///
  /// The privacy invariant of this TAB: **no section marked personal may appear
  /// for a guest**, so no `/me/` request is issued and no personal field can
  /// reach a guest's screen. Asserted directly, rather than trusted to whichever
  /// widget happens to guard it.
  ///
  /// [nextAction] is deliberately **not** personal. For a guest it is an
  /// invitation written from fixed copy and the access level alone; only once
  /// there is a session does it read verification status, and the screen gates
  /// that read on `CapabilityService`, not on this flag.
  bool get isPersonal => this == HomeSection.requests;
}

/// What Home emphasises for a given access level.
///
/// The emphasis changes; the identity does not. Every level sees the same
/// Taytay hero, the same public content and the same catalogue, in the same
/// order — what differs is which single next action sits near the top.
@immutable
class HomeEmphasis {
  const HomeEmphasis._({required this.level, required this.sections});

  final AccessLevel level;

  /// In render order.
  final List<HomeSection> sections;

  bool contains(HomeSection section) => sections.contains(section);

  static HomeEmphasis forLevel(AccessLevel level) => switch (level) {
    // A guest sees everything public and nothing personal. `nextAction` is
    // present but its content is an invitation, not a status — see
    // `HomeScreen`, which never reads a `/me/` repository without a session.
    AccessLevel.guest => const HomeEmphasis._(
      level: AccessLevel.guest,
      sections: <HomeSection>[
        HomeSection.hero,
        HomeSection.nextAction,
        HomeSection.services,
        HomeSection.news,
        HomeSection.events,
        HomeSection.municipalHall,
      ],
    ),

    // Adds nothing personal beyond the verification step they are already in
    // the middle of. Deliberately **no saved-draft or onboarding-progress
    // card**: the registration draft is held in memory only and dies with the
    // process (TAB 07), so there is no authoritative source to summarise, and
    // inventing "you are 60% done" from a widget's local state would be a
    // fabricated claim about the resident's application.
    AccessLevel.unverified => const HomeEmphasis._(
      level: AccessLevel.unverified,
      sections: <HomeSection>[
        HomeSection.hero,
        HomeSection.nextAction,
        HomeSection.services,
        HomeSection.news,
        HomeSection.events,
        HomeSection.municipalHall,
      ],
    ),

    // Adds the resident's own requests. Order is deliberate: what the LGU needs
    // from them comes before what the LGU is telling everyone.
    AccessLevel.verified => const HomeEmphasis._(
      level: AccessLevel.verified,
      sections: <HomeSection>[
        HomeSection.hero,
        HomeSection.nextAction,
        HomeSection.requests,
        HomeSection.services,
        HomeSection.news,
        HomeSection.events,
        HomeSection.municipalHall,
      ],
    ),
  };

  /// Sections that read `/me/` data. Empty for a guest, by construction.
  List<HomeSection> get personalSections =>
      sections.where((section) => section.isPersonal).toList(growable: false);
}
