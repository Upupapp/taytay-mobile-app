import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/session/access_level.dart';

import 'device_adaptation_test.dart' show Device, boot, coreRoutes, devices;

/// What a screen reader needs, checked by machine.
///
/// ## What this is, and what it is not
///
/// TAB 07 asks for a VoiceOver and TalkBack walk. **Neither can be driven from
/// here**: VoiceOver does not run on the iOS Simulator, no Android emulator is
/// installed on this machine, and no physical device has ever been attached to
/// this programme. `docs/frontend/accessibility-session.md` records that in
/// full, per criterion, rather than letting a green suite imply it.
///
/// What *can* be checked is the semantics tree the screen reader would read, and
/// that is what this does — through Flutter's own accessibility guidelines,
/// which are the same rules a reviewer applies by hand:
///
///  * **`labeledTapTargetGuideline`** — the one that matters most. A control
///    with no label is announced as "button" and nothing else, which is a
///    screen-reader user meeting an unlabelled door.
///  * **`androidTapTargetGuideline` / `iOSTapTargetGuideline`** — 48dp and 44pt.
///    Already asserted for the default scale in `device_adaptation_test.dart`;
///    here they run at every access level, because a control that only appears
///    for a verified resident was never in that sweep.
/// **`textContrastGuideline` is deliberately NOT run, and this is the reason.**
/// It samples the pixels inside a semantics node and compares the lightest
/// against the darkest. On this app's primary buttons — a brand gradient with
/// white text — the sample is overwhelmingly fill, so it reports the two ends of
/// the *gradient* against each other and calls a 4.5:1 button 1.06:1. Measured:
/// it named `#0B3D91`, which is `BrandColors.taytayBlue` exactly, and never
/// weighed a white glyph.
///
/// Contrast is enforced instead where it can be computed rather than sampled:
/// `BrandGradient.worstCaseContrastRatio()` proves the declared foreground
/// across the whole ramp **including interpolated midpoints**, and the palette
/// tests prove every status colour. That is a stronger guarantee than pixel
/// sampling, not a weaker one, and `test/core/brand_test.dart` holds it.
///
/// A pass here is evidence about the tree. It is **not** evidence about focus
/// order, announcement wording, or what happens when a rotor moves through a
/// list — those need a person and a device.
/// The notched 390x844 phone — the shape most residents actually hold, and the
/// one where a control can end up under the cutout or the home indicator.
final Device _phone = devices.firstWhere(
  (Device d) => d.name == 'phone with a notch',
);

void main() {
  group('every core route is legible to a screen reader', () {
    for (final AccessLevel level in AccessLevel.values) {
      testWidgets('$level: every tappable thing carries a label', (
        tester,
      ) async {
        for (final String route in coreRoutes) {
          await boot(tester, level: level, device: _phone, location: route);
          await expectLater(
            tester,
            meetsGuideline(labeledTapTargetGuideline),
            reason: '$route at $level',
          );
        }
      });
    }

    // EVERY LEVEL, not just `verified`, and the reason is a hole this audit
    // had on its first draft. `/sign-in` and `/sign-in-help` are in
    // `coreRoutes`, and `resolveRedirect` moves a signed-in resident off them —
    // so a sweep run only at `verified` boots those two, gets redirected to
    // `/home`, and passes without ever rendering the screen it named. A planted
    // undersized button on the sign-in screen went undetected exactly that way.
    //
    // Running every level means each route is genuinely rendered at the level
    // where it is reachable, and the sweep cannot pass by redirection.
    for (final AccessLevel level in AccessLevel.values) {
      testWidgets('$level: targets are big enough to hit on both platforms', (
        tester,
      ) async {
        for (final String route in coreRoutes) {
          await boot(tester, level: level, device: _phone, location: route);
          await expectLater(
            tester,
            meetsGuideline(androidTapTargetGuideline),
            reason: '$route at $level',
          );
          await expectLater(
            tester,
            meetsGuideline(iOSTapTargetGuideline),
            reason: '$route at $level',
          );
        }
      });
    }

    testWidgets('the verification journey is legible too', (tester) async {
      // Not in `coreRoutes`, and it is the journey that decides whether a
      // resident ever becomes Verified — so it is the last one that should go
      // unchecked. Only reachable while signed in.
      for (final AccessLevel level in <AccessLevel>[
        AccessLevel.unverified,
        AccessLevel.verified,
      ]) {
        await boot(
          tester,
          level: level,
          device: _phone,
          location: '/verification',
        );
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: '/verification at $level',
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      }
    });

    for (final AccessLevel level in AccessLevel.values) {
      testWidgets('$level: and in Filipino, where the copy is longer', (
        tester,
      ) async {
        for (final String route in coreRoutes) {
          await boot(
            tester,
            level: level,
            device: _phone,
            location: route,
            locale: AppLocales.filipino,
          );
          await expectLater(
            tester,
            meetsGuideline(labeledTapTargetGuideline),
            reason: '$route at $level in Filipino',
          );
        }
      });
    }
  });
}
