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
  WidgetsFlutterBinding.ensureInitialized();

  // Once, before the first frame. Resizing the image cache during a scroll
  // evicts everything it currently holds, which is the opposite of the intent.
  RemoteImage.configureImageCache();

  final config = AppConfig.resolve();
  final dependencies = AppDependencies.build(config: config);

  runApp(TaytayResidentApp(dependencies: dependencies));
}
