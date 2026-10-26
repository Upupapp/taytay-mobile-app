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
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

/// Motion clips at 390×844 @3×. Every captured frame advances 33 ms.
///
/// `flutter test --tags recording --run-skipped test/recording/s8_motion_test.dart`
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
  final InMemorySessionStore store = InMemorySessionStore();
  await store.write(
    const StoredSession(
      resident: ResidentSession(
        accountId: 'acct-s8',
        accessLevel: AccessLevel.verified,
        displayName: 'Juana',
      ),
      accessToken: 'token',
    ),
  );
  final AppDependencies dependencies = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
      rawDataMode: 'mock',
      rawMockLatencyMs: '0',
    ),
    secrets: secrets,
    sessionStore: store,
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  await dependencies.session.restore();
  await dependencies.launch.restore();
  return dependencies;
}

const Duration _step = Duration(milliseconds: 33);
const ValueKey<String> _boundaryKey = ValueKey<String>('s8-motion');

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
    initialLocation: AppRoute.profile.path,
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

Finder get _messages => find.text('Messages');
Finder get _mswdo => find.text('MSWDO');
Finder get _settings => find.text('Settings');
Finder get _notice => find.text('Privacy Notice');
Finder get _draft => find.textContaining('DRAFT');
Finder get _back => find.byType(TaytayBackButton).last;

void main() {
  setUpAll(_loadFonts);

  testWidgets('open messages, open the MSWDO thread, and come back', (
    tester,
  ) async {
    final Directory out = Directory('/tmp/s8_motion_messages');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies();
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, _messages);
    frame = await _hold(tester, out, frame, 30);
    await tester.tap(_messages);
    frame = await _until(tester, out, frame, _mswdo);
    frame = await _hold(tester, out, frame, 30);
    await tester.tap(_mswdo);
    frame = await _until(
      tester,
      out,
      frame,
      find.text('Write a message…'),
    );
    frame = await _hold(tester, out, frame, 30);
    await tester.tap(_back);
    frame = await _until(tester, out, frame, _mswdo);
    frame = await _hold(tester, out, frame, 30);
    expect(frame, greaterThan(20));
  });

  testWidgets('open settings, open the privacy notice, and come back', (
    tester,
  ) async {
    final Directory out = Directory('/tmp/s8_motion_settings');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies();
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, _settings);
    frame = await _hold(tester, out, frame, 30);
    await tester.tap(_settings);
    frame = await _until(tester, out, frame, _notice);
    frame = await _hold(tester, out, frame, 30);
    await tester.tap(_notice);
    frame = await _until(tester, out, frame, _draft);
    frame = await _hold(tester, out, frame, 30);
    await tester.tap(_back);
    frame = await _until(tester, out, frame, _notice);
    frame = await _hold(tester, out, frame, 30);
    expect(frame, greaterThan(20));
  });
}
