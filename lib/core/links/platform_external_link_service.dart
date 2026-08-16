import 'package:url_launcher/url_launcher.dart';

import 'external_link_service.dart';

/// Hands a validated `https` link to the operating system.
///
/// **Thin, and it validates before it launches.** `ExternalLink.isSafe` is the
/// gate; this class does not repair, normalise or retry a URL that fails it,
/// because repairing an untrusted URL is guessing at what somebody meant.
///
/// Launched in an external application rather than an in-app webview: a resident
/// opening directions should land in the maps app they already have signed in
/// and configured, and an in-app browser would put this app between them and a
/// municipal service for no benefit.
class PlatformExternalLinkService implements ExternalLinkService {
  const PlatformExternalLinkService();

  @override
  Future<LinkOutcome> open(String url) async {
    if (!ExternalLink.isSafe(url)) return LinkOutcome.refused;

    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      return launched ? LinkOutcome.opened : LinkOutcome.unavailable;
    } on Object {
      // Never throws into a screen. Opening a map is an enhancement; failing it
      // must not take down the event a resident is reading.
      return LinkOutcome.unavailable;
    }
  }
}
