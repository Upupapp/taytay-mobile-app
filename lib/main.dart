import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/taytay_resident_app.dart';
import 'core/config/app_config.dart';
import 'shared/widgets/remote_image.dart';

/// Entry point for the Taytay, Rizal LGU IDS resident app.
///
/// Build with an explicit environment:
///
/// ```
/// flutter run --dart-define=TAYTAY_ENV=dev
/// flutter build apk --release --dart-define=TAYTAY_ENV=prod
/// ```
///
/// Configuration is resolved before the first frame so a misconfigured build
/// shows an explicit error instead of quietly pointing at the wrong backend.
void main() {
  // A guarded zone so an unhandled asynchronous error is caught rather than
  // taking the isolate down silently. Everything below runs inside it.
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // Once, before the first frame. Resizing the image cache during a scroll
      // evicts everything it currently holds, which is the opposite of intent.
      RemoteImage.configureImageCache();

      final config = AppConfig.resolve();
      final dependencies = AppDependencies.build(config: config);

      // ── Crash safety ────────────────────────────────────────────────────
      //
      // Three doors, wired to one redactor. Each keeps Flutter's own behaviour
      // — the red screen in debug, the console line — and adds a redacted
      // report on top, so nothing that used to be visible to a developer stops
      // being visible.
      //
      // Reporting is a no-op in the shipped build: `Telemetry.recordCrash`
      // returns without sending unless a resident consented and a sink exists.
      final previousFlutterError = FlutterError.onError;
      FlutterError.onError = (details) {
        previousFlutterError?.call(details);
        unawaited(
          dependencies.telemetry.recordCrash(
            details.exception,
            details.stack,
            library: details.library,
          ),
        );
      };

      // Errors from the platform side that never pass through FlutterError.
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          dependencies.telemetry.recordCrash(error, stack, fatal: true),
        );
        // False: this app does not claim to have handled it. The platform's
        // own reporting still runs.
        return false;
      };

      // The resident's stored answer, read before the first frame so a
      // consented device does not lose the first minute of its session.
      unawaited(dependencies.telemetry.restore());

      runApp(TaytayResidentApp(dependencies: dependencies));
    },
    (error, stack) {
      // The zone's own door: an asynchronous error nothing else caught.
      //
      // Through Flutter's reporter rather than a `print`. `debugPrint` writes
      // to the device log, which is readable by app-adjacent tooling, and a
      // Dart exception's text routinely quotes the value that caused it — the
      // exact leak `CrashReport` exists to prevent. `presentError` keeps the
      // developer-facing dump in debug and is a no-op the release build
      // discards.
      FlutterError.presentError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'taytay_resident',
          context: ErrorDescription('in a guarded zone'),
        ),
      );
    },
  );
}
