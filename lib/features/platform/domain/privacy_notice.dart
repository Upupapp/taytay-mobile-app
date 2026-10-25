import 'package:flutter/foundation.dart';

/// `privacy_notice` on `GET /app/config`.
///
/// [version] `placeholder`, a missing object, or an empty body keeps the
/// bundled draft. A published version renders [bodyMarkdown].
@immutable
class PrivacyNotice {
  const PrivacyNotice({
    this.version = '',
    this.updatedAt,
    this.bodyMarkdown = '',
  });

  /// No object on the wire.
  static const PrivacyNotice missing = PrivacyNotice();

  final String version;
  final DateTime? updatedAt;
  final String bodyMarkdown;

  bool get usesBundledDraft {
    if (version.trim().isEmpty || version.trim() == 'placeholder') return true;
    return bodyMarkdown.trim().isEmpty;
  }

  @override
  String toString() => 'PrivacyNotice($version)';
}
