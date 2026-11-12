import 'package:flutter/foundation.dart';

/// A text `GET /app/config` publishes under a version: `privacy_notice`, and
/// since backend `77da0b2` the Terms of Use in `terms`. Both have the same
/// shape: `version`, `updated_at`, `body_markdown`.
///
/// [version] `placeholder`, a missing object, or an empty body is not
/// published, and [bodyMarkdown] is then never shown as the text. A published
/// version renders [bodyMarkdown].
@immutable
class PublishedText {
  const PublishedText({
    this.version = '',
    this.updatedAt,
    this.bodyMarkdown = '',
  });

  /// No object on the wire.
  static const PublishedText missing = PublishedText();

  /// The version the server ships until the LGU's approved text is written.
  static const String placeholderVersion = 'placeholder';

  final String version;
  final DateTime? updatedAt;
  final String bodyMarkdown;

  /// Whether the LGU has published this text.
  bool get isPublished {
    final String trimmed = version.trim();
    if (trimmed.isEmpty || trimmed == placeholderVersion) return false;
    return bodyMarkdown.trim().isNotEmpty;
  }

  /// The Privacy Notice's name for an unpublished text: the screens show the
  /// bundled draft instead.
  bool get usesBundledDraft => !isPublished;

  @override
  String toString() => 'PublishedText($version)';
}

/// `privacy_notice` on `GET /app/config`. Unpublished keeps the bundled draft.
typedef PrivacyNotice = PublishedText;

/// `terms` on `GET /app/config`: the Terms of Use a resident accepts.
/// Unpublished says the text is not out yet; there is no bundled draft, so
/// nothing stands in for it.
typedef TermsOfUse = PublishedText;

/// `biometric_consent` on `GET /app/config` (backend `44cae1b`): the consent a
/// resident gives before the app may send a selfie. Unpublished means no
/// selfie can be taken; there is no bundled draft (D-209).
typedef BiometricConsentText = PublishedText;
