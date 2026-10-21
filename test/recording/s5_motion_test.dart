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

/// Motion clips at 390×844 @3×. Animations stay on. No environment banner.
///
/// `flutter test --tags recording --run-skipped test/recording/s5_motion_test.dart`
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

Future<AppDependencies> _dependencies({required bool verified}) async {
  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
  if (verified) {
    await store.write(
      const StoredSession(
        resident: ResidentSession(
          accountId: 'acct-s5',
          accessLevel: AccessLevel.verified,
          displayName: 'Juana',
        ),
        accessToken: 'token',
      ),
    );
  }
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

const Duration _step = Duration(milliseconds: 125);
const ValueKey<String> _boundaryKey = ValueKey<String>('s5-motion');

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
    initialLocation: AppRoute.services.path,
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

Finder get _bplo => find.byKey(const Key('directory-office-bplo'));
Finder get _message => find.byKey(const Key('directory-message'));
Finder get _send => find.byKey(const Key('directory-send'));

void main() {
  setUpAll(_loadFonts);

  testWidgets('open an office and come back, motion on', (tester) async {
    final Directory out = Directory('/tmp/s5_motion_office');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies(verified: true);
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, _bplo);
    frame = await _hold(tester, out, frame, 4);
    await tester.tap(_bplo);
    frame = await _until(tester, out, frame, _message);
    frame = await _hold(tester, out, frame, 6);
    await tester.tap(find.byType(TaytayBackButton));
    frame = await _until(tester, out, frame, _bplo);
    frame = await _hold(tester, out, frame, 4);
    expect(frame, greaterThan(12));
    expect(_message, findsNothing);
  });

  testWidgets('verified resident sends a message, motion on', (tester) async {
    final Directory out = Directory('/tmp/s5_motion_message');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies(verified: true);
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, _bplo);
    await tester.tap(_bplo);
    frame = await _until(tester, out, frame, _message);
    frame = await _hold(tester, out, frame, 4);
    await tester.tap(_message);
    frame = await _until(tester, out, frame, _send);
    frame = await _hold(tester, out, frame, 4);
    await tester.tap(_send);
    frame = await _until(tester, out, frame, find.text('Message sent'));
    frame = await _hold(tester, out, frame, 6);
    expect(frame, greaterThan(16));
  });

  testWidgets('guest message opens the verification gate, motion on', (
    tester,
  ) async {
    final Directory out = Directory('/tmp/s5_motion_gate');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies(verified: false);
    addTearDown(dependencies.dispose);
    await _mount(tester, dependencies);

    var frame = await _until(tester, out, 0, _bplo);
    await tester.tap(_bplo);
    frame = await _until(tester, out, frame, _message);
    frame = await _hold(tester, out, frame, 4);
    await tester.tap(_message);
    frame = await _until(
      tester,
      out,
      frame,
      find.text('Verify your account to message offices'),
    );
    frame = await _hold(tester, out, frame, 8);
    expect(_send, findsNothing);
    expect(frame, greaterThan(12));
  });
}
