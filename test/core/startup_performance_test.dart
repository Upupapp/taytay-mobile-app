import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The startup properties TAB 20 asks for, held as assertions rather than as a
/// measurement nobody re-runs.
///
/// A latency budget needs a low-end device and cannot be checked here. What
/// *can* be checked here is the structural half — that startup does not sit on
/// the network, and that list surfaces page rather than loading everything —
/// because those are the two decisions that make a budget achievable at all, and
/// both are one careless `await` away from being undone.
void main() {
  String sourceOf(String path) => File(path).readAsStringSync();

  group('startup does not wait for the network', () {
    test('bootstrap is fired, never awaited by anything that draws', () {
      // A resident on a weak connection must get the app, not a spinner. If this
      // ever becomes `await`, a server that never answers becomes an app that
      // never starts — and the people it happens to are the ones on the worst
      // connections, which is most of the user base.
      final String app = sourceOf('lib/app/taytay_resident_app.dart');
      expect(
        app,
        contains('unawaited(widget.dependencies.platform.refresh())'),
      );
      expect(
        app,
        isNot(contains('await widget.dependencies.platform.refresh()')),
      );
    });

    test('the app lock is loaded the same way', () {
      // Same reasoning: a lock that has not been confirmed to exist must not
      // hide the app while it is being confirmed.
      expect(
        sourceOf('lib/app/taytay_resident_app.dart'),
        contains('unawaited(widget.dependencies.appLock.load())'),
      );
    });

    test('permissive defaults hold until the server answers', () {
      // The other half of not blocking: if nothing waits for bootstrap, then
      // whatever the app assumes meanwhile has to be safe. Versions permissive,
      // features closed.
      final String controller = sourceOf(
        'lib/core/startup/platform_controller.dart',
      );
      expect(controller, contains('AppBootstrap.unknown'));

      // The defaults themselves live with the type. Empty minimum means no
      // minimum, and no feature flag is on until the server says so — permissive
      // about versions, closed about features, because a bootstrap that could
      // not be fetched must never lock somebody out of a working app and must
      // never draw a door the server would refuse to open.
      final String bootstrap = sourceOf(
        'lib/features/platform/domain/app_bootstrap.dart',
      );
      expect(bootstrap, contains("minimumVersion: ''"));
      expect(bootstrap, contains('features: FeatureFlags.none'));
    });
  });

  group('list surfaces page rather than loading everything', () {
    test('every paged repository sends page and per_page', () {
      // A feed page of twenty-five is twenty-five rows over a metered
      // connection. Loading everything is a cost the resident pays and never
      // asked for.
      const List<String> paged = <String>[
        'lib/features/news/data/newsfeed_api_repository.dart',
        'lib/features/events/data/event_api_repository.dart',
        'lib/features/programs/data/program_api_repository.dart',
        'lib/features/notifications/data/notification_api_repository.dart',
        'lib/features/services/data/assistance_api_repository.dart',
      ];

      for (final String path in paged) {
        final String source = sourceOf(path);
        expect(source, contains("'page'"), reason: path);
        expect(source, contains("'per_page'"), reason: path);
        // Clamped, because an over-large page is a slow response for a resident
        // on a weak connection even when the server tolerates it.
        expect(source, contains('clamp('), reason: path);
      }
    });
  });

  group('images are decoded to the size they are displayed at', () {
    test('remote images carry a decode target', () {
      // A 4000x3000 cover in a 360dp card is ~48MB of ARGB per card. Right-sized
      // it is ~2.6MB and visually identical, because the extra pixels were never
      // displayable. This was TAB 25 of the original build; it is asserted here
      // so that a later refactor cannot quietly drop it.
      final String source = sourceOf('lib/shared/widgets/remote_image.dart');
      expect(source, anyOf(contains('cacheWidth'), contains('cacheHeight')));
    });
  });
}
