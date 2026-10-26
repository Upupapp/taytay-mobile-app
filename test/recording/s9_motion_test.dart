@Tags(<String>['recording'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/core/router/app_router.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// The gold thread across welcome, sign-in, and sign-up.
///
/// Every captured frame advances 33 ms. Encode at 30 fps so playback is real
/// time. No environment banner: this host is not the diagnostic app shell.
///
/// `flutter test --tags recording --run-skipped test/recording/s9_motion_test.dart`
Future<void> _loadFonts() async {
  final FontLoader jakarta = FontLoader('Plus Jakarta Sans');
  for (final String file in <String>[
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Medium.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    jakarta.addFont(rootBundle.load(file));
  }
  await jakarta.load();
  final FontLoader lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/lucide/lucide.ttf'));
  await lucide.load();
}

Future<AppDependencies> _dependencies() async {
  final InMemorySecretStore secrets = InMemorySecretStore();
  final AppDependencies dependencies = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
      rawDataMode: 'mock',
      rawMockLatencyMs: '0',
    ),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  await dependencies.session.restore();
  await dependencies.launch.restore();
  return dependencies;
}

const Duration _step = Duration(milliseconds: 33);
const ValueKey<String> _boundaryKey = ValueKey<String>('s9-motion');

Future<void> _mount(WidgetTester tester, AppDependencies dependencies) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: Size(390, 844),
        textScaler: TextScaler.noScaling,
        disableAnimations: false,
      ),
      child: RepaintBoundary(
        key: _boundaryKey,
        child: _Host(dependencies: dependencies),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _precache(WidgetTester tester) async {
  final Finder images = find.byType(Image);
  if (images.evaluate().isEmpty) return;
  final BuildContext context = tester.element(images.first);
  for (final Element element in images.evaluate()) {
    final Widget widget = element.widget;
    if (widget is Image) {
      await tester.runAsync(() => precacheImage(widget.image, context));
    }
  }
  await tester.pump();
}

Future<void> _shot(WidgetTester tester, Directory out, int frame) async {
  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(_boundaryKey)) as RenderRepaintBoundary;
  debugDisableShadows = false;
  try {
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final String name = frame.toString().padLeft(4, '0');
      File(
        '${out.path}/f_$name.png',
      ).writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = true;
  }
}

Future<int> _until(
  WidgetTester tester,
  Directory out,
  int frame,
  Finder finder, {
  int maxFrames = 40,
}) async {
  for (var i = 0; i < maxFrames; i++) {
    await tester.pump(_step);
    await _precache(tester);
    await _shot(tester, out, frame);
    frame++;
    if (finder.evaluate().isNotEmpty) return frame;
  }
  expect(finder, findsWidgets);
  return frame;
}

Future<int> _hold(
  WidgetTester tester,
  Directory out,
  int frame,
  int count,
) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(_step);
    await _precache(tester);
    await _shot(tester, out, frame);
    frame++;
  }
  return frame;
}

class _Host extends StatefulWidget {
  const _Host({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late final GoRouter router = buildAppRouter(
    session: widget.dependencies.session,
    launch: widget.dependencies.launch,
    platform: widget.dependencies.platform,
    initialLocation: AppRoute.onboarding.path,
  );

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDependenciesScope(
      dependencies: widget.dependencies,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the gold thread crosses welcome, sign-in and sign-up', (
    WidgetTester tester,
  ) async {
    WelcomeMotion.enabled = true;
    addTearDown(() => WelcomeMotion.enabled = false);

    final Directory out = Directory('/tmp/s9_motion_thread');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies();
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, find.text('Skip'));
    frame = await _hold(tester, out, frame, 24);
    await tester.tap(find.text('Next'));
    frame = await _until(tester, out, frame, find.text('Ang Taytay ID mo,'));
    frame = await _hold(tester, out, frame, 20);
    await tester.tap(find.text('Next'));
    frame = await _until(tester, out, frame, find.text('Get started'));
    frame = await _hold(tester, out, frame, 20);
    await tester.tap(find.text('Get started'));
    frame = await _until(
      tester,
      out,
      frame,
      find.text('Maligayang pagbabalik!'),
    );
    frame = await _hold(tester, out, frame, 24);
    await tester.tap(find.text('Create an account'));
    frame = await _until(tester, out, frame, find.text('Tungkol sa iyo'));
    frame = await _hold(tester, out, frame, 24);
    expect(frame, greaterThan(40));
  });
}
