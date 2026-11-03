import 'dart:typed_data';

/// What a public media route is allowed to return.
///
/// The cover and hero routes answer `image/jpeg`, `image/png`, or
/// `image/webp`. Anything else — an HTML captive portal, a JSON error
/// that arrived with status 200, a truncated file — is not a picture.
abstract final class ImagePayload {
  /// Sent on a bytes read so a proxy that honours `Accept` still returns
  /// the image, and a 404 can still be the JSON error envelope.
  static const String acceptHeader =
      'image/jpeg, image/png, image/webp, application/json';

  /// Compressed size ceiling. A larger body is refused rather than decoded:
  /// the bitmap is downscaled at draw time, and the compressed bytes still
  /// have to fit in memory first.
  static const int maxBytes = 8 << 20;

  /// True when [contentType] names one of the three image types and [bytes]
  /// start with that type's signature.
  static bool isImage(String? contentType, Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) return false;
    return switch (_mediaType(contentType)) {
      'image/jpeg' => _jpeg(bytes),
      'image/png' => _png(bytes),
      'image/webp' => _webp(bytes),
      _ => false,
    };
  }

  static String _mediaType(String? header) {
    if (header == null || header.isEmpty) return '';
    final String first = header.split(',').first.trim().toLowerCase();
    final int semi = first.indexOf(';');
    return (semi < 0 ? first : first.substring(0, semi)).trim();
  }

  static bool _jpeg(Uint8List bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;

  static bool _png(Uint8List bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A;

  static bool _webp(Uint8List bytes) =>
      bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}
