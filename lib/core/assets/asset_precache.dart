import 'package:flutter/widgets.dart';

import 'asset_manifest.dart';

/// Startup image warming.
///
/// **Precaching is opt-in and budgeted.** Decoding an image costs CPU and
/// memory, and the moment it costs most is during the first frames, when a
/// low-end device is already building the widget tree and restoring the session.
/// So nothing is precached because a screen felt like it: an asset is warmed
/// only if it appears in [AppAssets.precacheKeys], and that list is bounded by
/// [AssetPolicy.maxPrecacheCount] and [AssetPolicy.maxPrecacheBytes], both
/// asserted in `asset_manifest_test.dart`.
///
/// **Everything else loads lazily**, at the moment the widget that needs it is
/// built. For painted illustrations there is nothing to load at all — the
/// current state of this app — which is why the allowlist is empty.
abstract final class AssetPrecache {
  /// Warms the allowlisted assets.
  ///
  /// Failures are swallowed deliberately: a missing or corrupt decorative image
  /// must never prevent the app from starting. The manifest tests are what catch
  /// that case, at build time, where it can actually be fixed.
  static Future<void> warmUp(BuildContext context) async {
    for (final key in AppAssets.precacheKeys) {
      final entry = AppAssets.byKey(key);
      if (entry == null) continue;
      if (entry.format == AssetFormat.svg) continue;
      try {
        await precacheImage(AssetImage(entry.path), context);
      } on Object {
        // Intentionally ignored — see the doc comment.
      }
    }
  }
}
