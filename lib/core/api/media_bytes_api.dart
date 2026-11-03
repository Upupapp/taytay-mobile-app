import 'dart:typed_data';

import '../result/result.dart';
import '../storage/media_byte_cache.dart';
import 'api_client.dart';
import 'api_envelope.dart';
import 'api_transport.dart';

/// Public image bytes, read through [ApiClient].
///
/// `GET news/{id}/cover` and `GET services/{slug}/hero`. The path is always
/// relative to the configured base URL. A `cover_url` or `hero_url` string is
/// only a signal that a picture may exist; its host is never requested.
///
/// A 404 is [Ok] of null: there is no picture. Any other failure is [Err].
/// Neither path throws, and neither renders the server's error message.
class MediaBytesApi {
  MediaBytesApi({required ApiClient apiClient, MediaByteCache? cache})
    : _apiClient = apiClient,
      _cache = cache ?? MediaByteCache();

  final ApiClient _apiClient;
  final MediaByteCache _cache;
  final Map<String, Future<Result<Uint8List?>>> _inflight =
      <String, Future<Result<Uint8List?>>>{};
  int _epoch = 0;

  /// One path segment. The same shape as a deep-link identifier: no slash,
  /// no scheme, no `..`.
  static final RegExp _segment = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  /// `GET /news/{id}/cover`.
  Future<Result<Uint8List?>> newsCover(String id) {
    if (!_segment.hasMatch(id)) {
      return Future<Result<Uint8List?>>.value(const Ok<Uint8List?>(null));
    }
    return _cached(
      'news/$id/cover',
      () {
        return _apiClient.send<Uint8List?>(
          method: HttpMethod.get,
          path: 'news/$id/cover',
          authenticated: false,
          binary: true,
          endSessionOn401: false,
          decode: _ignoreJson,
        );
      },
      // A draft is 404 to an anonymous reader. Do not remember that as a
      // public picture, and do not keep the absence either.
      rememberMiss: false,
    );
  }

  /// `GET /services/{slug}/hero`.
  Future<Result<Uint8List?>> serviceHero(String slug) {
    if (!_segment.hasMatch(slug)) {
      return Future<Result<Uint8List?>>.value(const Ok<Uint8List?>(null));
    }
    return _cached('services/$slug/hero', () {
      return _apiClient.send<Uint8List?>(
        method: HttpMethod.get,
        path: 'services/$slug/hero',
        authenticated: false,
        binary: true,
        endSessionOn401: false,
        decode: _ignoreJson,
      );
    });
  }

  /// `GET /home/banners/{id}/image`. Public. The banner `image_url` host is
  /// not requested.
  Future<Result<Uint8List?>> homeBanner(String id) {
    if (!_segment.hasMatch(id)) {
      return Future<Result<Uint8List?>>.value(const Ok<Uint8List?>(null));
    }
    return _cached('home/banners/$id/image', () {
      return _apiClient.send<Uint8List?>(
        method: HttpMethod.get,
        path: 'home/banners/$id/image',
        authenticated: false,
        binary: true,
        endSessionOn401: false,
        decode: _ignoreJson,
      );
    });
  }

  /// `GET /media/{id}/content`. The caller's own image. Metadata stays on
  /// `GET /media/{id}`. These bytes are not written to the public cache.
  Future<Result<Uint8List?>> mediaContent(String id) {
    if (!_segment.hasMatch(id)) {
      return Future<Result<Uint8List?>>.value(const Ok<Uint8List?>(null));
    }
    return _cached('media/$id/content', () {
      return _apiClient.send<Uint8List?>(
        method: HttpMethod.get,
        path: 'media/$id/content',
        authenticated: true,
        binary: true,
        decode: _ignoreJson,
      );
    }, remember: false);
  }

  void clear() {
    _epoch += 1;
    _inflight.clear();
    _cache.clear();
  }

  @override
  String toString() => 'MediaBytesApi($_cache)';

  Future<Result<Uint8List?>> _cached(
    String key,
    Future<Result<ApiEnvelope<Uint8List?>>> Function() load, {
    bool remember = true,
    bool rememberMiss = true,
  }) {
    if (remember) {
      final Result<Uint8List?>? hit = _cache.read(key);
      if (hit != null) return Future<Result<Uint8List?>>.value(hit);
    }
    final Future<Result<Uint8List?>>? pending = _inflight[key];
    if (pending != null) return pending;
    final int epoch = _epoch;
    final Future<Result<Uint8List?>> future = _fetch(
      key,
      epoch,
      load,
      remember: remember,
      rememberMiss: rememberMiss,
    );
    _inflight[key] = future;
    return future;
  }

  Future<Result<Uint8List?>> _fetch(
    String key,
    int epoch,
    Future<Result<ApiEnvelope<Uint8List?>>> Function() load, {
    bool remember = true,
    bool rememberMiss = true,
  }) async {
    try {
      final Result<ApiEnvelope<Uint8List?>> response = await load();
      final Result<Uint8List?> result = switch (response) {
        Ok<ApiEnvelope<Uint8List?>>(:final value) => Ok<Uint8List?>(value.data),
        Err<ApiEnvelope<Uint8List?>>(:final failure) => Err<Uint8List?>(
          failure,
        ),
      };
      if (epoch == _epoch && remember && result.isOk) {
        final Uint8List? bytes = result.valueOrNull;
        if (bytes != null || rememberMiss) {
          _cache.store(key, bytes);
        }
      }
      return result;
    } finally {
      if (epoch == _epoch) {
        // The caller is already awaiting this future. ignore() only drops
        // the map entry's unused return value.
        _inflight.remove(key)?.ignore();
      }
    }
  }

  static Uint8List? _ignoreJson(Object? data) => null;
}
