import 'package:share_plus/share_plus.dart';

import 'share_service.dart';

/// The OS share sheet, with a copy-to-clipboard fallback.
///
/// ---
///
/// **Thin by design**, like the document picker: everything decidable without a
/// platform channel lives in `ShareService` and its content type, and this class
/// only translates.
///
/// **Every failure degrades rather than throws.** A device with no share sheet,
/// a platform channel that is not registered, a sheet the OS refuses to open —
/// all of them fall back to copying the text, which is a real way to pass an
/// advisory to a neighbour. A resident trying to forward a typhoon notice should
/// never meet an exception.
class PlatformShareService implements ShareService {
  const PlatformShareService({
    ShareService fallback = const ClipboardShareService(),
  }) : _fallback = fallback;

  final ShareService _fallback;

  @override
  Future<ShareOutcome> share(ShareableContent content) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: content.text, subject: content.title),
      );

      return switch (result.status) {
        ShareResultStatus.success => ShareOutcome.shared,
        // Backing out of the sheet is a choice, not a failure, and must never be
        // reported as one.
        ShareResultStatus.dismissed => ShareOutcome.dismissed,
        // The platform could not tell us what happened. Treated as done rather
        // than retried: the sheet did open, and copying on top of it would put
        // the text on the clipboard behind the resident's back.
        ShareResultStatus.unavailable => ShareOutcome.shared,
      };
    } on Object {
      return _fallback.share(content);
    }
  }
}
