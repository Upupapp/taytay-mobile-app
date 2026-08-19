import '../config/app_config.dart';
import '../network/network_monitor.dart';
import '../result/result.dart';
import '../storage/public_cache.dart';
import 'api_envelope.dart';
import 'api_transport.dart';
import 'auth_coordinator.dart';
import 'page_policy.dart';
import 'request_context.dart';

/// Supplies the current access token to the API layer.
///
/// A function seam rather than a session dependency: the API layer must not know
/// what a session *is*, and the token must be read at send time (it can be
/// refreshed or cleared between building a request and sending it).
typedef AccessTokenProvider = Future<String?> Function();

/// Called with the verdict of every decoded response, success or failure.
typedef OutcomeObserver = void Function(AppFailure? failure);

/// Called when the server answers `401 UNAUTHENTICATED`.
///
/// Session expiry is a server verdict, so this is the single place the app
/// learns its credentials are dead. The handler drops the session to guest;
/// the router reacts to that, not to the individual call site.
typedef UnauthenticatedHandler = Future<void> Function();

/// The one place an outbound API call is assembled.
///
/// Responsibilities: resolve the URL from configuration, attach contract
/// headers, delegate to the [ApiTransport], decode the envelope, and translate
/// `401` into a session event. It holds no business rules — those live in
/// feature domain layers.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required ApiTransport transport,
    AccessTokenProvider? accessTokenProvider,
    UnauthenticatedHandler? onUnauthenticated,
    OutcomeObserver? onOutcome,
    AuthCoordinator? authCoordinator,
    PublicCache? cache,
    NetworkMonitor? networkMonitor,
  }) : _config = config,
       _transport = transport,
       _accessTokenProvider = accessTokenProvider,
       _onUnauthenticated = onUnauthenticated,
       _onOutcome = onOutcome,
       _authCoordinator = authCoordinator,
       _cache = cache,
       _networkMonitor = networkMonitor;

  final AppConfig _config;
  final ApiTransport _transport;

  /// The page size this channel was told to use, once the bootstrap says so.
  ///
  /// Held here because every paged call already has the client, and because it
  /// is channel-level contract state of the same kind as the base URL and the
  /// headers — not because the transport decides it. `PlatformController` sets
  /// it when `app/bootstrap` answers; until then it is the labelled fallback.
  ///
  /// See [PagePolicy] for why this is read rather than copied.
  PagePolicy pages = PagePolicy.fallback;
  final AccessTokenProvider? _accessTokenProvider;
  final UnauthenticatedHandler? _onUnauthenticated;

  /// Told the verdict of every request, alongside the network monitor.
  ///
  /// Same discipline as `recordOutcome`: the verdict, never the request. It
  /// exists so `503 SERVICE_UNAVAILABLE` reaches the startup layer from the one
  /// place every response already passes through, rather than each of thirteen
  /// repositories learning to recognise maintenance for itself.
  final OutcomeObserver? _onOutcome;

  /// Serialises recovery from `401`. When absent, a `401` ends the session
  /// directly through [_onUnauthenticated] — the same fail-closed outcome.
  final AuthCoordinator? _authCoordinator;

  /// Public, non-personal responses only. See [PublicCache].
  final PublicCache? _cache;

  /// Told the outcome of every request that reached the transport.
  ///
  /// Here rather than at call sites because reachability is one app-wide fact
  /// and this is the one place every request passes through. A feature that
  /// reported it separately would be a feature that could forget to.
  final NetworkMonitor? _networkMonitor;

  /// Sends [method] [path] and decodes `data` with [decode].
  ///
  /// [authenticated] must be an explicit choice at every call site. Defaulting
  /// it would let a protected endpoint be called anonymously by omission —
  /// the client-side mirror of the backend's "deny by default" rule.
  Future<Result<ApiEnvelope<T>>> send<T>({
    required HttpMethod method,
    required String path,
    required bool authenticated,
    required T Function(Object? data) decode,
    Map<String, String> query = const <String, String>{},
    Object? body,
    String? idempotencyKey,
    Duration? timeout,
    String? bearerOverride,
    MultipartFile? file,
    bool attachTokenIfAvailable = false,
  }) async {
    // A token that exists but is not yet the session's.
    //
    // Sign-in has to make two more calls with the credential it has just been
    // handed — `GET me`, and the profile read that carries the verification
    // tier — *before* it can build a session, because the access level is what
    // the session is made of. Storing the token first to make the provider find
    // it would mean a session existed for a moment at a level nobody had
    // checked, and fail-closed means never guessing that level even briefly.
    // OPTIONALLY AUTHENTICATED, for content whose public-ness is a server flag.
    //
    // `GET newsfeed` is an unauthenticated route whose controller still refuses
    // an anonymous reader unless `newsfeed.public_access` is on — and it defaults
    // off. Reading the route file says "public"; calling it says 401. A request
    // that is anonymous by construction therefore fails for a signed-in resident
    // too, which is the worst of both: the token exists and is deliberately
    // withheld.
    //
    // So: attach the token when there is one, stay anonymous when there is not,
    // and never fail for the lack of it. A guest still gets the server's own
    // answer about whether the feed is public, rather than the app guessing.
    final token = authenticated
        ? (bearerOverride ?? await _accessTokenProvider?.call())
        : (attachTokenIfAvailable ? await _accessTokenProvider?.call() : null);
    if (authenticated && (token == null || token.isEmpty)) {
      // Never send a protected request as a guest and let the server decide:
      // it produces a misleading 401 and, worse, a request that looks
      // deliberately anonymous in the audit log.
      return const Err(
        UnauthenticatedFailure(
          debugMessage: 'Authenticated request attempted with no access token.',
        ),
      );
    }

    var decoded = await _sendOnce<T>(
      method: method,
      path: path,
      query: query,
      body: body,
      idempotencyKey: idempotencyKey,
      timeout: timeout,
      token: token,
      decode: decode,
      file: file,
    );

    // `401` is the single signal that ends a session, handled once here rather
    // than at each call site. Recovery is serialised by the coordinator so that
    // several requests failing together cause at most one refresh.
    final failure = decoded.failureOrNull;
    if (failure != null && failure.requiresReauthentication) {
      final coordinator = _authCoordinator;
      if (coordinator == null) {
        await _onUnauthenticated?.call();
        return decoded;
      }

      final recovery = await coordinator.handleUnauthenticated();
      if (recovery == AuthRecovery.failed) return decoded;

      // Refreshed: replay exactly once, with the new token. Never twice — a
      // second `401` after a successful refresh means something is wrong that
      // retrying cannot fix.
      final refreshedToken = await _accessTokenProvider?.call();
      if (refreshedToken == null || refreshedToken.isEmpty) return decoded;

      decoded = await _sendOnce<T>(
        method: method,
        path: path,
        query: query,
        body: body,
        idempotencyKey: idempotencyKey,
        timeout: timeout,
        token: refreshedToken,
        decode: decode,
      );
      if (decoded.failureOrNull?.requiresReauthentication ?? false) {
        await _onUnauthenticated?.call();
      }
    }

    if (decoded.isOk && !authenticated) {
      _cache?.store<ApiEnvelope<T>>(
        // Path **and** query: a key of `services` alone would store page 3 and
        // serve it to a request for page 1.
        key: PublicCache.keyFor(path, query),
        value: decoded.valueOrNull!,
        authenticated: false,
      );
    }

    // The verdict, not the request: no path, no payload, no identifier.
    _networkMonitor?.recordOutcome(decoded.failureOrNull);
    _onOutcome?.call(decoded.failureOrNull);

    return decoded;
  }

  /// One attempt: build the request context, send, decode. No auth recovery.
  Future<Result<ApiEnvelope<T>>> _sendOnce<T>({
    required HttpMethod method,
    required String path,
    required Map<String, String> query,
    required Object? body,
    required String? idempotencyKey,
    required Duration? timeout,
    required String? token,
    MultipartFile? file,
    required T Function(Object? data) decode,
  }) async {
    // A fresh correlation id per attempt: a replay is a different request and
    // must be traceable as one in the server's logs.
    final context = RequestContext(
      requestId: generateRequestId(),
      bearerToken: token,
    );

    final response = await _transport.send(
      ApiRequest(
        method: method,
        path: path,
        query: query,
        body: body,
        headers: context.headers(
          // A multipart request's Content-Type is generated with its boundary by
          // the transport; declaring JSON here would produce a body the server
          // cannot parse and a 400 that reads like a validation failure.
          hasJsonBody: body != null && file == null,
          idempotencyKey: idempotencyKey,
        ),
        timeout: timeout ?? _config.requestTimeout,
        file: file,
      ),
    );

    return switch (response) {
      Err<ApiHttpResponse>(:final failure) => Err<ApiEnvelope<T>>(failure),
      Ok<ApiHttpResponse>(value: final httpResponse) =>
        ApiEnvelopeDecoder.decode<T>(httpResponse, decode),
    };
  }

  /// A cached public envelope for [path], when one is fresh.
  ///
  /// Callers opt in explicitly; nothing is served from cache behind their back.
  ApiEnvelope<T>? cached<T>(
    String path, [
    Map<String, String> query = const <String, String>{},
  ]) => _cache?.read<ApiEnvelope<T>>(PublicCache.keyFor(path, query));

  /// A cached public envelope for [path] **even when it is stale**, with its
  /// age attached.
  ///
  /// For the offline path only. A caller that takes this owes the resident a
  /// visible statement of how old it is — see [CachedRead].
  CachedRead<ApiEnvelope<T>>? cachedAllowingStale<T>(
    String path, [
    Map<String, String> query = const <String, String>{},
  ]) => _cache?.readAllowingStale<ApiEnvelope<T>>(
    PublicCache.keyFor(path, query),
  );

  /// Absolute URI for [path], honouring the configured base path.
  ///
  /// Exposed so a transport implementation resolves URLs the same way the client
  /// does instead of concatenating strings of its own.
  Uri resolve(String path, [Map<String, String> query = const {}]) {
    final basePath = _config.apiBaseUri.path.endsWith('/')
        ? _config.apiBaseUri.path
        : '${_config.apiBaseUri.path}/';
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return _config.apiBaseUri.replace(
      path: '$basePath$relative',
      queryParameters: query.isEmpty ? null : query,
    );
  }
}

/// A transport that fails every call, used until a real HTTP client lands.
///
/// It exists so the composition root is complete and testable today without
/// pretending the app can talk to a backend it has no endpoints for yet. It
/// reports [NetworkFailure] — the honest description of "this build cannot
/// reach the API".
class UnconfiguredApiTransport implements ApiTransport {
  const UnconfiguredApiTransport();

  @override
  Future<Result<ApiHttpResponse>> send(ApiRequest request) async =>
      const Err<ApiHttpResponse>(
        NetworkFailure(
          debugMessage:
              'No HTTP transport is wired up in this build (TAB 01 seam).',
        ),
      );
}
