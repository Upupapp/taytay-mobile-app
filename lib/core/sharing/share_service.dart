import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What a resident is passing on.
///
/// ---
///
/// **Only public content is ever built into one of these.** Nothing personal —
/// no reference number, no case status, no name — has a field here, and no
/// screen holding personal data constructs one. A share sheet hands text to
/// whichever app the resident picks, and this app has no way to know what that
/// app then does with it.
///
/// **The link is the server's or absent.** This app does not compose a public
/// URL for a municipal announcement out of a base host and an id. It does not
/// know the LGU's public web address, and a fabricated link inside a shared
/// typhoon advisory sends people to a 404 — or to a domain somebody else owns.
/// When the backend publishes a canonical link, it is shared; when it does not,
/// the text goes alone and still says where it came from.
@immutable
class ShareableContent {
  const ShareableContent({required this.title, required this.body, this.url});

  /// The subject line, where the platform offers one.
  final String title;

  /// The text itself.
  final String body;

  /// A canonical public link, **exactly as the server supplied it**.
  final String? url;

  /// What is actually handed to the OS.
  String get text => url == null ? body : '$body\n\n$url';

  /// Redacted of the content. A share payload is public, but this type is
  /// reachable from a log line and there is no reason to put a whole
  /// announcement in one.
  @override
  String toString() => 'ShareableContent(hasUrl: ${url != null})';
}

/// How a share attempt ended.
enum ShareOutcome {
  /// The OS sheet opened and the resident chose something.
  shared,

  /// The sheet opened and they backed out. Not an error.
  dismissed,

  /// No share sheet was available, so the text was copied instead.
  copiedToClipboard,

  /// Nothing could be done, and the screen should say so.
  unavailable,
}

/// Passing public content to another app.
///
/// An interface so no screen calls a plugin directly, the whole flow is
/// testable without a platform channel, and a device with no share sheet has a
/// defined behaviour rather than an exception.
abstract interface class ShareService {
  Future<ShareOutcome> share(ShareableContent content);
}

/// The fallback: copy the text and tell the resident that is what happened.
///
/// Used on any platform where the OS sheet is unavailable, and by the platform
/// implementation when the sheet itself fails. Copying is a real, useful
/// outcome — it is how sharing worked before share sheets existed — so it is a
/// distinct [ShareOutcome] rather than a silent failure.
class ClipboardShareService implements ShareService {
  const ClipboardShareService();

  @override
  Future<ShareOutcome> share(ShareableContent content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content.text));
      return ShareOutcome.copiedToClipboard;
    } on Object {
      // Never throws into a screen. A share is an enhancement; failing it must
      // not take down the announcement a resident is reading.
      return ShareOutcome.unavailable;
    }
  }
}

/// Reports every share as unavailable. The default in tests.
class UnavailableShareService implements ShareService {
  const UnavailableShareService();

  @override
  Future<ShareOutcome> share(ShareableContent content) async =>
      ShareOutcome.unavailable;
}
