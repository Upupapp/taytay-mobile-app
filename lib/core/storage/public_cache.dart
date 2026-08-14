import 'package:flutter/foundation.dart';

/// A cached value and when it stops being usable.
@immutable
class CacheEntry<T> {
  const CacheEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;

  bool isFresh(DateTime now) => now.isBefore(expiresAt);
}

/// Cache for **public, non-personal** API responses only.
///
/// ---
///
/// ## What may be cached, and why the rule is structural
///
/// Exactly one class of data: responses to requests that were **not
/// authenticated**, for keys on an explicit [allowedKeys] list. Today that is the
/// published service catalogue and the health probe — both unauthenticated by
/// design on the server (`docs/api/conventions.md` §8 and the ServiceCatalog
/// route file).
///
/// [store] takes `authenticated` as a **required** argument and refuses to write
/// when it is true. A caller cannot forget to consider it, and cannot pass a
/// personal response in by omission. That matters more than it looks: the usual
/// way personal data ends up in a cache is not a decision, it is a generic cache
/// wrapper applied to one more endpoint.
///
/// ## Why in memory
///
/// The cache lives for the process and nothing is written to disk. A disk cache
/// of public data would be legitimate, but it introduces a file whose contents
/// have to be reviewed on every future change to what passes through it — and
/// the first time someone caches an authenticated response by mistake, that file
/// is personal data at rest, in clear text, outside the keystore. The value a
/// disk cache would add here is one avoided catalogue fetch per launch.
///
/// ## Freshness
///
/// Entries carry a TTL and are evicted lazily on read. The catalogue changes
/// when LGU staff publish or retire a service, which is rare but must not take
/// an app restart to appear — hence a short default TTL rather than an
/// indefinite one.
class PublicCache {
  PublicCache({
    Set<String>? allowedKeys,
    this.defaultTtl = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : allowedKeys = allowedKeys ?? defaultAllowedKeys,
       _clock = clock ?? DateTime.now;

  /// Keys this cache will accept.
  ///
  /// An allow-list, not a deny-list: a new endpoint is uncacheable until someone
  /// states that its response is public.
  final Set<String> allowedKeys;

  final Duration defaultTtl;
  final DateTime Function() _clock;

  final Map<String, CacheEntry<Object?>> _entries =
      <String, CacheEntry<Object?>>{};

  /// The public endpoints of the committed backend contract.
  static const Set<String> defaultAllowedKeys = <String>{'services', 'health'};

  /// Number of live entries. For tests and diagnostics.
  @visibleForTesting
  int get size => _entries.length;

  /// Stores [value] under [key].
  ///
  /// Returns whether it was stored. Refuses — and says so — when the response
  /// came from an authenticated request, or when the key is not allow-listed.
  bool store<T>({
    required String key,
    required T value,
    required bool authenticated,
    Duration? ttl,
  }) {
    if (authenticated) return false;
    if (!allowedKeys.contains(key)) return false;

    _entries[key] = CacheEntry<Object?>(
      value: value,
      expiresAt: _clock().add(ttl ?? defaultTtl),
    );
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

  void invalidate(String key) => _entries.remove(key);

  /// Drops everything.
  ///
  /// Called on sign-out and on session invalidation. Nothing personal is in here
  /// by construction, but a resident handing the phone back should not find the
  /// previous session's screens repopulating from memory.
  void clear() => _entries.clear();
}
