import 'package:flutter/foundation.dart';

import '../result/result.dart';

/// In-memory cache for public cover and hero bytes.
///
/// The same rules as the public response cache: nothing is written to disk, and a miss
/// that means "no picture" is remembered so a feed does not ask again on
/// every rebuild. A network failure is not stored — the next paint may retry.
///
/// Bytes are not copied. Callers must not mutate the list they receive.
class MediaByteCache {
  MediaByteCache({
    this.hitTtl = const Duration(minutes: 10),
    this.missTtl = const Duration(minutes: 1),
    this.maxEntries = 24,
    this.maxBytes = 12 << 20,
    this.maxEntryBytes = 3 << 20,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration hitTtl;
  final Duration missTtl;
  final int maxEntries;
  final int maxBytes;

  /// A single picture larger than this is shown and not kept.
  final int maxEntryBytes;

  final DateTime Function() _clock;
  final Map<String, _Slot> _slots = <String, _Slot>{};
  int _used = 0;

  @visibleForTesting
  int get size => _slots.length;

  /// A cached result, or null when nothing fresh is stored.
  ///
  /// [Ok] of null is a remembered 404. It is not the same as a cache miss.
  Result<Uint8List?>? read(String key) {
    final _Slot? slot = _slots.remove(key);
    if (slot == null) return null;
    if (!_clock().isBefore(slot.expiresAt)) {
      _used -= slot.bytes?.length ?? 0;
      return null;
    }
    _slots[key] = slot;
    return Ok<Uint8List?>(slot.bytes);
  }

  /// Stores a picture, or a remembered absence when [bytes] is null.
  void store(String key, Uint8List? bytes) {
    if (bytes != null &&
        (bytes.isEmpty ||
            bytes.length > maxEntryBytes ||
            bytes.length > maxBytes)) {
      return;
    }
    final _Slot? previous = _slots.remove(key);
    if (previous != null) _used -= previous.bytes?.length ?? 0;
    final int size = bytes?.length ?? 0;
    _slots[key] = _Slot(
      bytes: bytes,
      expiresAt: _clock().add(bytes == null ? missTtl : hitTtl),
    );
    _used += size;
    _evict();
  }

  void clear() {
    _slots.clear();
    _used = 0;
  }

  void _evict() {
    while (_slots.length > maxEntries || _used > maxBytes) {
      final String oldest = _slots.keys.first;
      final _Slot removed = _slots.remove(oldest)!;
      _used -= removed.bytes?.length ?? 0;
    }
  }

  @override
  String toString() => 'MediaByteCache(${_slots.length} entries)';
}

class _Slot {
  const _Slot({required this.bytes, required this.expiresAt});

  final Uint8List? bytes;
  final DateTime expiresAt;
}
