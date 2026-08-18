/// What each feature does without a connection, declared once.
///
/// ---
///
/// **The policy is written before the implementation and then held against it.**
/// An undocumented cache becomes an accidental one: somebody adds a path to make
/// a screen faster, nobody records why, and eighteen months later nobody can say
/// whether a resident's case history is sitting on a shared phone. The table
/// below is the answer, and `offline_policy_test.dart` fails when the code stops
/// matching it.
///
/// **Three postures, and the boundary between them is who the data is about.**
/// Public municipal content is the same for everybody, so a stale copy is a
/// service rather than a risk — a resident checking which documents a clearance
/// needs should get that answer on a dead connection. Anything about one
/// resident is not cached at all: on a shared handset, and shared handsets are
/// ordinary here, a cached case narrative is the most likely privacy incident
/// this app can have. Authority-shaped values are not cached even briefly,
/// because a cached "verified" is a permission the server did not grant today.
enum OfflinePosture {
  /// Readable offline, and readable stale, with its age shown.
  staleReadable,

  /// Not cached. Requires a connection, and says so.
  onlineOnly,

  /// Not cached, and re-read on every use even when a connection exists.
  neverCached,
}

/// One feature's offline behaviour.
class OfflineRule {
  const OfflineRule({
    required this.feature,
    required this.posture,
    required this.path,
    required this.because,
  });

  final String feature;
  final OfflinePosture posture;

  /// The `api/v1` path, or `''` where the rule is about a value rather than an
  /// endpoint.
  final String path;

  final String because;
}

/// The whole policy, per feature.
///
/// Ordered so the cacheable ones read together: everything above the divide is
/// public municipal content, everything below is about one resident.
const List<OfflineRule> offlinePolicy = <OfflineRule>[
  OfflineRule(
    feature: 'Service catalogue',
    posture: OfflinePosture.staleReadable,
    path: 'services',
    because:
        'The same for every resident, and the answer somebody most often opens '
        'the app for — which documents a clearance needs, and where to go. '
        'Useless only if it needs a signal.',
  ),
  OfflineRule(
    feature: 'Assistance programmes',
    posture: OfflinePosture.staleReadable,
    path: 'programs',
    because:
        'Public municipal content, and metered-data-expensive to re-fetch.',
  ),
  OfflineRule(
    feature: 'Newsfeed',
    posture: OfflinePosture.staleReadable,
    path: 'newsfeed',
    because:
        'Public. An advisory read late is better than an advisory not read, and '
        'the screen states when the office actually published it.',
  ),
  OfflineRule(
    feature: 'Events',
    posture: OfflinePosture.staleReadable,
    path: 'events',
    because:
        'The listing is public. Availability is NOT cached with it — that is '
        'derived server-side per read, and a stale "open" sends somebody to a '
        'covered court for a place that went hours ago.',
  ),
  OfflineRule(
    feature: 'Platform health',
    posture: OfflinePosture.staleReadable,
    path: 'health',
    because:
        'The liveness probe carries a service name, a status and an API version '
        'and nothing about anybody, so a stale copy discloses nothing.',
  ),

  // ── Below here: about one resident. None of it is cached. ────────────────
  OfflineRule(
    feature: 'Assistance cases and history',
    posture: OfflinePosture.onlineOnly,
    path: 'me/cases',
    because:
        'A case narrative describes a household in crisis. On a shared handset '
        'a cached copy is readable by whoever holds it next, and shared handsets '
        'are ordinary in this user base.',
  ),
  OfflineRule(
    feature: 'Assistance drafts',
    posture: OfflinePosture.onlineOnly,
    path: 'me/assistance/drafts',
    because:
        'The server is the draft store. A local copy would be a second record '
        'that disagrees with the office about what was submitted.',
  ),
  OfflineRule(
    feature: 'Requirements and documents',
    posture: OfflinePosture.onlineOnly,
    path: 'me/cases/{case}/requirements',
    because:
        'Identity documents. Nothing retrieved is kept, and a temporary file is '
        'cleared after upload rather than left in a cache directory.',
  ),
  OfflineRule(
    feature: 'Resident profile',
    posture: OfflinePosture.onlineOnly,
    path: 'me/profile',
    because:
        'Demographics and an address. Fetched by the screen that shows it.',
  ),
  OfflineRule(
    feature: 'Household',
    posture: OfflinePosture.onlineOnly,
    path: 'me/household',
    because: 'Other people\'s personal data as much as the resident\'s own.',
  ),
  OfflineRule(
    feature: 'Notifications',
    posture: OfflinePosture.onlineOnly,
    path: 'me/notifications',
    because:
        'Titles and bodies name cases and outcomes. An inbox cached to a shared '
        'phone is a case list on a lock screen.',
  ),
  OfflineRule(
    feature: 'Sessions and devices',
    posture: OfflinePosture.onlineOnly,
    path: 'me/sessions',
    because:
        'A stale list would reassure a resident checking for an intruder — the '
        'exact question the screen exists to answer.',
  ),

  // ── Authority-shaped. Re-read on every use, cached never. ────────────────
  OfflineRule(
    feature: 'Verification tier',
    posture: OfflinePosture.neverCached,
    path: 'me/profile#verification_tier',
    because:
        'It decides what a resident may do. A cached "verified" is a permission '
        'the server did not grant today, and Article 3.6 fails it closed.',
  ),
  OfflineRule(
    feature: 'Digital ID and its QR',
    posture: OfflinePosture.neverCached,
    path: 'me/credential',
    because:
        'A QR cached to disk can be lifted out of a device backup, and a stale '
        'one is refused at the counter with the resident standing there. Offline '
        'presentation needs the planned Verification module\'s key distribution '
        'and is out of scope (F12).',
  ),
  OfflineRule(
    feature: 'Event availability',
    posture: OfflinePosture.neverCached,
    path: 'events#registration.availability',
    because:
        'Derived server-side on every read, because a cached copy always wins '
        'the check that reads it (ADR 0030 §2).',
  ),
];

/// Paths the policy says may be cached. The cache's allow-list must equal this.
Set<String> get cacheablePaths => <String>{
  for (final OfflineRule rule in offlinePolicy)
    if (rule.posture == OfflinePosture.staleReadable) rule.path,
};
