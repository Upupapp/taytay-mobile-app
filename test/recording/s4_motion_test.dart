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
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/router/app_router.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/home/data/home_catalogue.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Motion clips at 390×844 @3×. Animations stay on. No environment banner.
///
/// `flutter test --tags recording --run-skipped test/recording/s4_motion_test.dart`
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
        accountId: 'acct-s4',
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

Future<void> _mount(WidgetTester tester, Widget child) async {
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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: RepaintBoundary(
          key: const ValueKey<String>('s4-motion'),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await _precache(tester);
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
      tester.renderObject(find.byKey(const ValueKey<String>('s4-motion')))
          as RenderRepaintBoundary;
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

const Duration _step = Duration(milliseconds: 125);

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
    await _shot(tester, out, frame);
    frame++;
  }
  return frame;
}

class _Phone extends StatelessWidget {
  const _Phone({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 844,
      child: ColoredBox(
        color: BrandColors.surface,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: ShellTabBar.barHeight),
                child: child,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShellTabBar(selectedIndex: index, onSelected: _ignore),
            ),
          ],
        ),
      ),
    );
  }
}

void _ignore(int index) {}

/// The real shell, without the non-production environment banner.
///
/// Each tab keeps its own navigator. The recording goes into a Directory
/// service, leaves, and comes back to that same service.
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
    initialLocation: AppRoute.home.path,
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

  testWidgets('tab bar switches, motion on', (tester) async {
    final Directory out = Directory('/tmp/s4_motion_tabs');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final AppDependencies dependencies = await _dependencies();
    addTearDown(dependencies.dispose);

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
          key: const ValueKey<String>('s4-motion'),
          child: _ShellHost(dependencies: dependencies),
        ),
      ),
    );
    await tester.pump();

    final Finder service = find.text('Service').hitTestable();
    final Finder sample = find.text('SAMPLE PWD Cash Gift').hitTestable();

    var frame = await _until(tester, out, 0, find.text('BAYAN NG TAYTAY'));
    frame = await _hold(tester, out, frame, 6);

    await tester.tap(find.byKey(const Key('shell-tab-directory')));
    frame = await _until(tester, out, frame, sample);
    frame = await _hold(tester, out, frame, 6);
    expect(service, findsNothing);

    await tester.tap(sample);
    frame = await _until(tester, out, frame, service);
    frame = await _hold(tester, out, frame, 8);

    await tester.tap(find.byKey(const Key('shell-tab-home')));
    frame = await _until(tester, out, frame, find.text('BAYAN NG TAYTAY'));
    frame = await _hold(tester, out, frame, 6);
    expect(service, findsNothing);

    await tester.tap(find.byKey(const Key('shell-tab-directory')));
    frame = await _until(tester, out, frame, service);
    frame = await _hold(tester, out, frame, 8);
    expect(service, findsOneWidget);
    expect(frame, greaterThan(40));
  });

  testWidgets('hero carousel advances, motion on', (tester) async {
    final Directory out = Directory('/tmp/s4_motion_carousel');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);

    final List<HomeSlide> slides = await HomeCatalogue.slides();
    final ({List<HomeNewsItem> news, List<HomeHotline> hotlines}) feed =
        await HomeCatalogue.mockFeed();

    await _mount(
      tester,
      _Phone(
        index: 0,
        child: HomeCanvas(
          greeting: 'Magandang gabi, Juana!',
          initials: 'JD',
          bellCount: 2,
          status: HomeStatusKind.none,
          slides: slides,
          news: feed.news,
          hotline: feed.hotlines.first,
          autoplayInTests: true,
        ),
      ),
    );
    await _precache(tester);

    var frame = await _hold(tester, out, 0, 8);
    // The title sits on the left of the hero. The drag starts on the photo.
    await tester.dragFrom(const Offset(320, 220), const Offset(-220, 0));
    frame = await _hold(tester, out, frame, 10);
    for (var cycle = 0; cycle < 2; cycle++) {
      await tester.pump(const Duration(seconds: 5));
      frame = await _hold(tester, out, frame, 10);
    }
    expect(frame, greaterThan(30));
  });
}
