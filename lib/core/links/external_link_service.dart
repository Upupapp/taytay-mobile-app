/// How an attempt to open an external link ended.
enum LinkOutcome {
  /// Handed to the OS successfully.
  opened,

  /// The URL was not something this app is willing to open. **Not** a device
  /// problem — see [ExternalLink.isSafe].
  refused,

  /// Nothing on the device could open it.
  unavailable,
}

/// A link this app is willing to hand to the operating system.
///
/// ---
///
/// ## Why there is a type here at all
///
/// The URLs this app opens come from **the server**, and a URL from a payload is
/// attacker-influenced in exactly the way a path parameter is. Handing one
/// straight to the platform launcher is how an app ends up opening a
/// `javascript:` URI in a webview, a `file:` URI pointing at its own sandbox, or
/// an `intent:` URI that starts another app's private activity.
///
/// So a link is validated once, here, and every caller goes through it.
abstract final class ExternalLink {
  /// The only scheme this app will open.
  ///
  /// **`https` only — not `http`.** The constitution already refuses cleartext
  /// for the API outside development, and there is no reason a municipal venue's
  /// directions link should be weaker: an `http` link is one an intermediary can
  /// rewrite, and it would send a resident somewhere the LGU did not choose.
  static const String scheme = 'https';

  /// Whether [url] is something this app will open.
  ///
  /// Requires a well-formed absolute `https` URL with a host. Everything else —
  /// other schemes, relative URLs, scheme-relative URLs, an empty host — is
  /// refused rather than repaired. Repairing an untrusted URL is guessing at
  /// what somebody meant, and the safe guess does not exist.
  static bool isSafe(String? url) {
    if (url == null || url.isEmpty) return false;

    final parsed = Uri.tryParse(url);
    if (parsed == null) return false;
    if (!parsed.isAbsolute) return false;
    if (parsed.scheme != scheme) return false;
    if (parsed.host.isEmpty) return false;
    return true;
  }

  /// A `tel:` URI for a published office number, or null when [number] has no
  /// dialable digits. `https` stays the only scheme [isSafe] accepts.
  static Uri? dialUri(String number) {
    final String first = number.split('·').first.trim();
    final String digits = first.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.replaceAll('+', '').length < 3) return null;
    return Uri(scheme: 'tel', path: digits);
  }
}

/// Opening a link outside the app.
///
/// An interface so no screen calls a plugin directly, the flow is testable
/// without a platform channel, and a device that cannot open a link has a
/// defined behaviour rather than an exception.
abstract interface class ExternalLinkService {
  Future<LinkOutcome> open(String url);

  /// Hands a published hotline to the phone dialer. [LinkOutcome.unavailable]
  /// when the device has no dialer, so the screen can say so.
  Future<LinkOutcome> dial(String number);
}

/// Refuses everything. The default in tests, and on any platform without a
/// launcher.
class UnavailableExternalLinkService implements ExternalLinkService {
  const UnavailableExternalLinkService();

  @override
  Future<LinkOutcome> open(String url) async =>
      ExternalLink.isSafe(url) ? LinkOutcome.unavailable : LinkOutcome.refused;

  @override
  Future<LinkOutcome> dial(String number) async => ExternalLink.dialUri(number) ==
          null
      ? LinkOutcome.refused
      : LinkOutcome.unavailable;
}
