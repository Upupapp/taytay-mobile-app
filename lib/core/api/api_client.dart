import '../config/app_config.dart';
import '../result/result.dart';
import 'api_envelope.dart';
import 'api_transport.dart';
import 'request_context.dart';

/// Supplies the current access token to the API layer.
///
/// A function seam rather than a session dependency: the API layer must not know
/// what a session *is*, and the token must be read at send time (it can be
/// refreshed or cleared between building a request and sending it).
typedef AccessTokenProvider = Future<String?> Function();

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
  }) : _config = config,
       _transport = transport,
       _accessTokenProvider = accessTokenProvider,
       _onUnauthenticated = onUnauthenticated;

  final AppConfig _config;
  final ApiTransport _transport;
  final AccessTokenProvider? _accessTokenProvider;
  final UnauthenticatedHandler? _onUnauthenticated;

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
  }) async {
    final token = authenticated ? await _accessTokenProvider?.call() : null;
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
          hasJsonBody: body != null,
          idempotencyKey: idempotencyKey,
        ),
        timeout: timeout ?? _config.requestTimeout,
      ),
    );

    switch (response) {
      case Err<ApiHttpResponse>(:final failure):
        return Err<ApiEnvelope<T>>(failure);
      case Ok<ApiHttpResponse>(value: final httpResponse):
        final decoded = ApiEnvelopeDecoder.decode<T>(httpResponse, decode);
        final failure = decoded.failureOrNull;
        if (failure != null && failure.requiresReauthentication) {
          await _onUnauthenticated?.call();
        }
        return decoded;
    }
  }

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
