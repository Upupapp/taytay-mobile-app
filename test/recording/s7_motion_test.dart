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
import 'package:taytay_resident/core/router/app_router.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

/// Motion clips at 390×844 @3×. Animations stay on. No environment banner.
///
/// `flutter test --tags recording --run-skipped test/recording/s7_motion_test.dart`
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
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
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

const Duration _step = Duration(milliseconds: 125);
const Duration _tick = Duration(milliseconds: 20);
const ValueKey<String> _boundaryKey = ValueKey<String>('s7-motion');

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
        child: _ShellHost(dependencies: dependencies),
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
  int maxFrames = 48,
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

Future<int> _ticks(
  WidgetTester tester,
  Directory out,
  int frame,
  int count,
) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(_tick);
    await _precache(tester);
    await _shot(tester, out, frame);
    frame++;
  }
  return frame;
}

class _ShellHost extends StatefulWidget {
  const _ShellHost({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<_ShellHost> {
  late final GoRouter router = buildAppRouter(
    session: widget.dependencies.session,
    launch: widget.dependencies.launch,
    platform: widget.dependencies.platform,
    initialLocation: AppRoute.programs.path,
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

Finder get _pwd => find.byKey(const Key('tulong-open-pwd-assistance'));
Finder get _office => find.byKey(const Key('tulong-office'));
Finder get _back => find.byType(TaytayBackButton);

void main() {
  setUpAll(_loadFonts);

  testWidgets('open a programme and come back, motion on', (tester) async {
    final Directory out = Directory('/tmp/s7_motion_detail');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies();
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, _pwd);
    frame = await _hold(tester, out, frame, 3);
    await tester.tap(_pwd);
    frame = await _ticks(tester, out, frame, 18);
    expect(_back, findsOneWidget);
    frame = await _hold(tester, out, frame, 3);
    await tester.tap(_back);
    frame = await _ticks(tester, out, frame, 18);
    expect(_pwd, findsOneWidget);
    frame = await _hold(tester, out, frame, 3);
    expect(frame, greaterThan(20));
  });

  testWidgets('open the social services centre and come back, motion on', (
    tester,
  ) async {
    final Directory out = Directory('/tmp/s7_motion_office');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies();
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, _pwd);
    frame = await _hold(tester, out, frame, 2);
    await tester.tap(_pwd);
    frame = await _ticks(tester, out, frame, 18);
    expect(_back, findsOneWidget);
    frame = await _hold(tester, out, frame, 2);
    await tester.ensureVisible(_office);
    await tester.tap(_office);
    frame = await _ticks(tester, out, frame, 18);
    expect(
      find.text('Municipal Social Welfare and Development Office'),
      findsWidgets,
    );
    frame = await _hold(tester, out, frame, 3);
    await tester.tap(_back);
    frame = await _ticks(tester, out, frame, 18);
    expect(_office, findsOneWidget);
    frame = await _hold(tester, out, frame, 2);
    expect(frame, greaterThan(20));
  });
}
