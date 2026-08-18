import 'package:flutter/foundation.dart';

/// What the server says a client needs before it knows anything else.
///
/// ---
///
/// `GET app/bootstrap` is unauthenticated and has to be: an app that cannot
/// start cannot sign in to be told that it should update, and a minimum-version
/// gate behind authentication is a gate that opens only for the clients that did
/// not need it. It carries nothing worth protecting — the API version, a support
/// number an LGU prints on a poster, and rendering hints that grant nothing.
///
/// **This app never called it.** The backend published a canonical startup
/// contract and the app implemented its own gates beside it, which is how the
/// digital ID's feature flag came to be something TAB 06 would have had to
/// hardcode. Wiring it is F06.
@immutable
class AppBootstrap {
  const AppBootstrap({
    required this.service,
    required this.apiVersion,
    required this.timezone,
    required this.channel,
    required this.defaultPageSize,
    required this.minimumVersion,
    required this.features,
    required this.support,
    this.serverTime,
  });

  /// What the app assumes before the server has answered, and after a failure.
  ///
  /// **Permissive on versions, closed on features.** Those pull in opposite
  /// directions on purpose: a bootstrap that could not be fetched must never
  /// lock a resident out of a working app, and must never draw a tab for a
  /// feature the server would refuse.
  static const AppBootstrap unknown = AppBootstrap(
    service: '',
    apiVersion: '',
    timezone: 'Asia/Manila',
    channel: 'citizen-mobile',
    defaultPageSize: 25,
    minimumVersion: '',
    features: FeatureFlags.none,
    support: SupportContact.none,
  );

  final String service;
  final String apiVersion;

  /// The server's clock, ISO-8601 Zulu, when it answered.
  ///
  /// Published so a client with a wrong clock can notice rather than telling
  /// somebody an event that starts in an hour started yesterday. Nothing on the
  /// server reads a client-supplied time.
  final DateTime? serverTime;

  /// Always `Asia/Manila` in practice; read rather than assumed.
  final String timezone;

  /// How the server parsed `X-Client-Channel`. Echoed for diagnosis only — an
  /// unrecognised channel degrades to `unknown` and proceeds with identical
  /// authority (Article 3.4).
  final String channel;

  final int defaultPageSize;

  /// The oldest build the server will serve, or `''` for no minimum.
  final String minimumVersion;

  final FeatureFlags features;
  final SupportContact support;

  /// How far the device clock is from the server's, when both are known.
  ///
  /// Not used to correct anything. A device clock is not trustworthy for
  /// deciding whether a registration window is open — that is the server's
  /// answer — but a large skew is worth knowing when a relative time reads
  /// wrongly to a resident.
  Duration? get clockSkew {
    final DateTime? server = serverTime;
    if (server == null) return null;
    return DateTime.now().toUtc().difference(server.toUtc());
  }
}

/// Server-declared rendering hints. **Never authorization.**
///
/// The backend is explicit (ADR/Article 3.4): a value that reaches a client is
/// untrusted input on the way back. Every flag here is read server-side from the
/// config its owning module already reads, so a client that ignored all of them
/// would gain nothing — the module behind each feature refuses independently.
///
/// **An absent flag is false.** A flag decides whether to draw a door; drawing
/// one the server will not open sends a resident down a corridor that ends in
/// "temporarily unavailable". Missing means do not draw.
@immutable
class FeatureFlags {
  const FeatureFlags(this._values);

  static const FeatureFlags none = FeatureFlags(<String, bool>{});

  final Map<String, bool> _values;

  /// The digital ID. `Credential` is implemented and flagged off at the
  /// baseline, so TAB 06 must ship both states in one build and let this decide
  /// which one a resident sees — that is what lets the LGU switch the ID on for
  /// real residents without a new app version.
  bool get digitalId => isOn('digital_id');

  bool get newsfeedPublic => isOn('newsfeed_public');
  bool get newsfeedComments => isOn('newsfeed_comments');
  bool get pushNotifications => isOn('push_notifications');

  /// Unknown flags are readable without a code change, and default to off.
  bool isOn(String name) => _values[name] ?? false;

  /// Flag names the server sent, for diagnosis. Never for branching.
  Iterable<String> get names => _values.keys;
}

/// Where a resident is told to go when nothing else is reachable.
@immutable
class SupportContact {
  const SupportContact({required this.email, required this.phone});

  static const SupportContact none = SupportContact(email: '', phone: '');

  final String email;
  final String phone;

  bool get hasAny => email.isNotEmpty || phone.isNotEmpty;
}

/// Whether this build is old enough that the server will not serve it.
///
/// ---
///
/// **The server decides, and this is the one place the client computes.** That
/// is not a contradiction: the server publishes the threshold and the client
/// compares its own version to it, because only the client knows what it is. A
/// build with a broken update check cannot fix its own update check, so the
/// comparison is deliberately dull and its failure modes all resolve to "let
/// them in".
enum SupportedVersion {
  /// The build is current enough, or no minimum was published.
  supported,

  /// The server will not serve this build. Blocking.
  tooOld;

  /// Compares [appVersion] against a published [minimum].
  ///
  /// Returns [supported] when the minimum is empty, unparseable, or not greater
  /// than the app's version. **Every uncertain case lets the resident through**,
  /// matching the server's own reasoning that a missing configuration must never
  /// become an accidental hard block. The cost of a wrong `tooOld` is a resident
  /// with a working app being told to go to a store and update to a version that
  /// may not exist; the cost of a wrong `supported` is one failed request with a
  /// real error message. They are not close.
  static SupportedVersion compare({
    required String appVersion,
    required String minimum,
  }) {
    final List<int>? required = _parse(minimum);
    if (required == null) return SupportedVersion.supported;

    final List<int>? current = _parse(appVersion);
    if (current == null) return SupportedVersion.supported;

    for (int i = 0; i < 3; i++) {
      if (current[i] > required[i]) return SupportedVersion.supported;
      if (current[i] < required[i]) return SupportedVersion.tooOld;
    }
    return SupportedVersion.supported;
  }

  /// `major.minor.patch`, tolerating a `+build` suffix and missing components.
  /// Anything else is `null`, which reads as "no opinion".
  static List<int>? _parse(String raw) {
    final String trimmed = raw.trim().split('+').first;
    if (trimmed.isEmpty) return null;

    final List<String> parts = trimmed.split('.');
    if (parts.isEmpty || parts.length > 3) return null;

    final List<int> numbers = <int>[0, 0, 0];
    for (int i = 0; i < parts.length; i++) {
      final int? value = int.tryParse(parts[i]);
      if (value == null || value < 0) return null;
      numbers[i] = value;
    }
    return numbers;
  }
}
