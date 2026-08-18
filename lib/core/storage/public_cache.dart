import 'package:flutter/foundation.dart';

/// A cached value, when it was stored, and when it stops being fresh.
@immutable
class CacheEntry<T> {
  const CacheEntry({
    required this.value,
    required this.storedAt,
    required this.expiresAt,
  });

  final T value;

  /// When the office actually answered.
  ///
  /// This is what a "last updated" line shows, and it is deliberately the
  /// **fetch** time rather than the TTL: a resident reading a stale feed wants
  /// to know how old the news is, not when the app plans to try again.
  final DateTime storedAt;

  final DateTime expiresAt;

  bool isFresh(DateTime now) => now.isBefore(expiresAt);
}

/// A value read from the cache, with the honesty attached.
@immutable
class CachedRead<T> {
  const CachedRead({
    required this.value,
    required this.storedAt,
    required this.isFresh,
  });

  final T value;
  final DateTime storedAt;

  /// False when the entry is past its TTL and was served anyway.
  ///
  /// A caller that receives `false` **must** label the screen. That is the whole
  /// contract of [PublicCache.readAllowingStale]: it will hand back old public
  /// content so a resident on a dead connection has something to read, on the
  /// condition that they are told how old it is.
  final bool isFresh;
}

/// Cache for **public, non-personal** API responses only.
///
/// ---
///
/// ## What may be cached, and why the rule is structural
///
/// Exactly one class of data: responses to requests that were **not
/// authenticated**, for paths on an explicit [allowedPaths] list. Today that is
/// the published service catalogue and the health probe — both unauthenticated
/// by design on the server (`docs/api/conventions.md` §8 and the ServiceCatalog
/// route file) — plus the public announcement, event and programme collections
/// the contract will publish.
///
/// [store] takes `authenticated` as a **required** argument and refuses to write
/// when it is true. A caller cannot forget to consider it, and cannot pass a
/// personal response in by omission. That matters more than it looks: the usual
/// way personal data ends up in a cache is not a decision, it is a generic cache
/// wrapper applied to one more endpoint.
///
/// ## Why the query is part of the key
///
/// A key of `services` alone would store page 3 and serve it to a request for
/// page 1. Worse, it would serve the "health" category's results to a request
/// that asked for "social welfare". So the key is the path **and** its query,
/// with parameters sorted so that two equivalent requests produce one entry.
/// The allow-list is still checked against the path, because what is public is
/// a property of the endpoint, not of its arguments.
///
/// ## Why in memory
///
/// The cache lives for the process and nothing is written to disk. A disk cache
/// of public data would be legitimate, but it introduces a file whose contents
/// have to be reviewed on every future change to what passes through it — and
/// the first time someone caches an authenticated response by mistake, that file
/// is personal data at rest, in clear text, outside the keystore.
///
/// The cost is real and worth stating: a resident who opens the app on a dead
/// connection after force-quitting it sees nothing, where a disk cache would
/// have shown them yesterday's announcements. That is the trade this app makes,
/// and it is the same one [PublicCache] made before offline support existed.
///
/// ## Freshness, and serving stale on purpose
///
/// Entries carry a TTL. [read] evicts a stale entry rather than returning it —
/// a caller that receives data has no obligation to check whether it should
/// have. [readAllowingStale] is the deliberate opposite, for the offline path,
/// and it hands back the age so the screen can say so.
class PublicCache {
  PublicCache({
    Set<String>? allowedPaths,
    this.defaultTtl = const Duration(minutes: 5),
    this.maxEntries = 60,
    DateTime Function()? clock,
  }) : allowedPaths = allowedPaths ?? defaultAllowedPaths,
       _clock = clock ?? DateTime.now;

  /// Paths this cache will accept.
  ///
  /// An allow-list, not a deny-list: a new endpoint is uncacheable until someone
  /// states that its response is public.
  final Set<String> allowedPaths;

  final Duration defaultTtl;

  /// Ceiling on live entries, so a resident scrolling a long feed on a phone
  /// with little memory cannot make the cache the reason the app is killed.
  /// The oldest entry goes first.
  final int maxEntries;

  final DateTime Function() _clock;

  final Map<String, CacheEntry<Object?>> _entries =
      <String, CacheEntry<Object?>>{};

  /// The public endpoints of the committed backend contract, plus the public
  /// collections the resident app browses without an account.
  static const Set<String> defaultAllowedPaths = <String>{
    'services',
    'health',
    // `newsfeed`, not `announcements`. The app cached a path no module has ever
    // served, so the entry could never have been hit.
    'newsfeed',
    'events',
    'programs',
  };

  /// Number of live entries. For tests and diagnostics.
  @visibleForTesting
  int get size => _entries.length;

  /// The cache key for a request.
  ///
  /// Query parameters are sorted, so `?page=1&per_page=25` and
  /// `?per_page=25&page=1` are one entry rather than two.
  static String keyFor(String path, [Map<String, String> query = const {}]) {
    if (query.isEmpty) return path;
    final parts = query.entries.map((e) => '${e.key}=${e.value}').toList()
      ..sort();
    return '$path?${parts.join('&')}';
  }

  /// The endpoint part of a key, which is what the allow-list is about.
  static String pathOf(String key) {
    final marker = key.indexOf('?');
    return marker < 0 ? key : key.substring(0, marker);
  }

  /// Stores [value] under [key].
  ///
  /// Returns whether it was stored. Refuses — and says so — when the response
  /// came from an authenticated request, or when the key's path is not
  /// allow-listed.
  bool store<T>({
    required String key,
    required T value,
    required bool authenticated,
    Duration? ttl,
  }) {
    if (authenticated) return false;
    if (!allowedPaths.contains(pathOf(key))) return false;

    final now = _clock();
    _entries[key] = CacheEntry<Object?>(
      value: value,
      storedAt: now,
      expiresAt: now.add(ttl ?? defaultTtl),
    );
    _evictOverflow();
    return true;
  }

  /// Returns the cached value when it is present, fresh and of type [T].
  ///
  /// A stale entry is evicted on the way out rather than returned with a flag:
  /// a caller that receives data has no obligation to check whether it should
  /// have.
  T? read<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (!entry.isFresh(_clock())) {
      _entries.remove(key);
      return null;
    }
    final value = entry.value;
    return value is T ? value : null;
  }

  /// Returns the cached value even when it is stale, with its age.
  ///
  /// **The offline path, and it does not evict.** A resident whose connection
  /// died deserves yesterday's announcements over an empty screen — provided the
  /// screen says they are yesterday's, which is why [CachedRead.isFresh] and
  /// [CachedRead.storedAt] come back with the value rather than being optional
  /// extras a caller can ignore.
  CachedRead<T>? readAllowingStale<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    final value = entry.value;
    if (value is! T) return null;
    return CachedRead<T>(
      value: value,
      storedAt: entry.storedAt,
      isFresh: entry.isFresh(_clock()),
    );
  }

  void invalidate(String key) => _entries.remove(key);

  /// Drops everything.
  ///
  /// Called on sign-out and on session invalidation. Nothing personal is in here
  /// by construction, but a resident handing the phone back should not find the
  /// previous session's screens repopulating from memory.
  void clear() => _entries.clear();

  /// Drops the oldest entries until the cache is within [maxEntries].
  void _evictOverflow() {
    if (_entries.length <= maxEntries) return;
    final byAge = _entries.entries.toList()
      ..sort((a, b) => a.value.storedAt.compareTo(b.value.storedAt));
    for (final entry in byAge.take(_entries.length - maxEntries)) {
      _entries.remove(entry.key);
    }
  }
}
