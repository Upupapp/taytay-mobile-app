import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/api/api_client.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';

/// 390×844 at 3×, the same frame as the design PNGs (1170×2532).
const Size _pixels = Size(1170, 2532);

Future<void> _loadFonts() async {
  final jakarta = FontLoader('Plus Jakarta Sans');
  for (final file in <String>[
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Regular.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Medium.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Bold.ttf',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-ExtraBold.ttf',
  ]) {
    jakarta.addFont(rootBundle.load(file));
  }
  await jakarta.load();
  final lucide = FontLoader('Lucide')
    ..addFont(rootBundle.load('assets/fonts/lucide/lucide.ttf'));
  await lucide.load();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('the configuration stop screen at 390x844 at 3x', (tester) async {
    debugDisableShadows = false;
    const dpr = 3.0;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = _pixels * dpr;
    tester.view.padding = FakeViewPadding.zero;
    tester.view.viewPadding = FakeViewPadding.zero;
    addTearDown(tester.view.reset);

    final config = AppConfig.from(
      rawEnvironment: 'prod',
      rawApiBaseUrl: '',
      isReleaseBuild: true,
    );
    final dependencies = AppDependencies.build(
      config: config,
      sessionStore: InMemorySessionStore(),
      secrets: InMemorySecretStore(),
      transport: const UnconfiguredApiTransport(),
    );
    addTearDown(dependencies.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
              disableAnimations: true,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: ColoredBox(
          key: const ValueKey<String>('misconfigured-root'),
          color: BrandColors.surface,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: _pixels.width / dpr,
              height: _pixels.height / dpr,
              child: TaytayResidentApp(dependencies: dependencies),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.settings_suggest_outlined), findsNothing);
    final icon = tester.widget<TaytayIcon>(find.byType(TaytayIcon));
    expect(icon.icon, TaytayIcons.settings);
    expect(icon.icon.fontFamily, 'Lucide');
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('misconfigured-root'))),
      _pixels,
    );

    try {
      await expectLater(
        find.byKey(const ValueKey<String>('misconfigured-root')),
        matchesGoldenFile('misconfigured_app.png'),
      );
    } finally {
      debugDisableShadows = true;
    }
  });
}
