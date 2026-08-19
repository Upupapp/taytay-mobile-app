/// How many records a page of this channel holds, as the server chose.
///
/// ## Why this is not a constant
///
/// `app/bootstrap` publishes `default_page_size` **per channel** —
/// `citizen-mobile` is told 15 — and before TAB 05 this app sent 25 and never
/// read it. Nothing was broken, and that is exactly why it was worth closing: a
/// number chosen for this channel by the system of record was being overridden
/// by a number chosen in a client, and the next person to change either would
/// not have known the other existed.
///
/// It was also not one number. It was **three** — `PageMeta.defaultPerPage`,
/// `ProgramApiRepository.defaultPerPage` and
/// `ServiceCatalogApiRepository.defaultPerPage` — plus five separate `clamp(1,
/// 100)` literals written out at the call sites. Three copies of a default agree
/// until one of them is edited.
///
/// Same rule as `UploadPolicy`, and for the same reason: **a published value is
/// read, never copied.**
library;

/// Where the page size came from. Never inferred at the point of use.
enum PagePolicySource {
  /// From `app/bootstrap`'s `client.default_page_size` for this channel.
  served,

  /// The bootstrap has not answered, or published nothing usable.
  fallback,
}

/// The page size in force, and where it came from.
final class PagePolicy {
  const PagePolicy({required this.defaultPerPage, required this.source});

  /// The contract's own ceiling (conventions §5). A request above it is refused
  /// by the server, so asking is only ever a wasted round trip.
  ///
  /// **The only page-size literal in `lib/`** besides [fallback], and
  /// `test/core/page_policy_test.dart` fails if a second appears.
  static const int maxPerPage = 100;

  /// Used until the bootstrap answers, and if it never does.
  ///
  /// 25 — what this app sent before TAB 05. Kept rather than lowered to the
  /// server's 15: an app that quietly halved its page size on every screen the
  /// moment a fallback engaged would look like a performance regression with no
  /// cause anybody could find.
  static const PagePolicy fallback = PagePolicy(
    defaultPerPage: 25,
    source: PagePolicySource.fallback,
  );

  final int defaultPerPage;
  final PagePolicySource source;

  /// Adopts a served value, clamped.
  ///
  /// **Clamped, not trusted.** A client that renders whatever it is told is one
  /// bad config away from loading four thousand rows over a municipal
  /// connection, and a zero would page forever. A value outside the range is
  /// clamped rather than rejected, because a usable page is better than none —
  /// and [wasClamped] says it happened so nobody reads the result as the
  /// server's choice.
  static PagePolicy adopt(int? served) {
    if (served == null || served <= 0) return fallback;
    return PagePolicy(
      defaultPerPage: served.clamp(1, maxPerPage),
      source: PagePolicySource.served,
    );
  }

  /// Whether the served value had to be brought into range.
  bool wasClamped(int? served) =>
      served != null && served > 0 && served != defaultPerPage;

  /// Brings a caller's own request into range.
  ///
  /// Callers that page deliberately — a directory small enough to arrive whole —
  /// still pass through here, so there is one place a request can be out of
  /// range and one place it is fixed.
  int clampRequest(int requested) => requested.clamp(1, maxPerPage);

  @override
  String toString() => 'PagePolicy($defaultPerPage, ${source.name})';
}
