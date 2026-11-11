import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/mock/mock_behavior.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/auth/presentation/sign_in_screen.dart';
import 'package:taytay_resident/features/credential/domain/credential_repository.dart';
import 'package:taytay_resident/features/credential/presentation/digital_id_canvas.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/gallery/presentation/component_gallery_screen.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/home_canvas.dart';
import 'package:taytay_resident/features/platform/presentation/blocking_notice_screen.dart';
import 'package:taytay_resident/features/splash/presentation/splash_screen.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

/// Redesign Phase 5: the design system pinned as pictures.
///
/// The component gallery, page by page, and one real screen for each pattern
/// in `docs/design/README.md` ("Screen patterns"), so an accidental visual
/// change — a token, a shared widget, a pattern's layout — fails here before a
/// resident sees it. Every golden is in `test/goldens/design_system/`.
///
/// The frame is the one the other goldens use: 390 × 844 logical pixels at 3×,
/// the bundled Plus Jakarta Sans and Lucide fonts loaded, no text scaling,
/// animations off. The data is synthetic and neutral; nothing here is a real
/// person or a real record.
///
/// A deliberate visual change regenerates them:
///
/// ```sh
/// flutter test --update-goldens test/goldens/design_system_golden_test.dart
/// ```
///
/// then delete any `test/goldens/failures/` files a failing run left behind.
/// The welcome pages (Splash / onboarding) and the digital ID faces have
/// their own goldens in `welcome_golden_test.dart` and
/// `digital_id_golden_test.dart`.
void main() {
  setUpAll(_loadFonts);

  group('component gallery', () {
    testWidgets('every page of the gallery matches its golden', (tester) async {
      final MockBehaviorController behavior = MockBehaviorController(
        latency: Duration.zero,
        failure: MockFailureMode.none,
      );
      addTearDown(behavior.dispose);
      await _pumpFrame(tester, ComponentGalleryScreen(behavior: behavior));

      final ScrollPosition position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.axis, Axis.vertical);
      // A ListView estimates its extent until it has laid every child out:
      // walk to the end until the extent stops moving.
      double extent = -1;
      while (extent != position.maxScrollExtent) {
        extent = position.maxScrollExtent;
        position.jumpTo(extent);
        await tester.pump();
      }
      final int pages = (extent / _frame.height).ceil() + 1;
      for (var page = 0; page < pages; page++) {
        position.jumpTo(math.min(page * _frame.height, extent));
        await _settle(tester);
        await _match(
          tester,
          'design_system/gallery_${'${page + 1}'.padLeft(2, '0')}.png',
        );
      }
    });
  });

  group('one screen per pattern', () {
    testWidgets('main tab: Home', (tester) async {
      await _pumpFrame(
        tester,
        const HomeCanvas(
          greeting: 'Magandang umaga, Resident!',
          initials: 'RS',
          bellCount: 2,
          slides: _slides,
          news: _news,
          hotline: _hotline,
        ),
      );
      await _match(tester, 'design_system/pattern_main_tab.png');
    });

    testWidgets('list + search: Directory', (tester) async {
      await _pumpFrame(
        tester,
        DirectoryCanvas(
          frame: DirectoryFrame.list,
          offices: _offices,
          chips: const <String>['All', 'Social services', 'Permits'],
          onChip: (_) {},
        ),
      );
      await _match(tester, 'design_system/pattern_list_search.png');
    });

    testWidgets('detail: the office page', (tester) async {
      await _pumpFrame(
        tester,
        DirectoryCanvas(
          frame: DirectoryFrame.detail,
          offices: const <Office>[],
          office: _offices.first,
          onBack: _noop,
          onCall: _noop,
          onDirections: _noop,
          onMessage: _noop,
        ),
      );
      await _match(tester, 'design_system/pattern_detail.png');
    });

    testWidgets('form / step flow: sign-in', (tester) async {
      await _pumpFrame(
        tester,
        const SignInScreen(),
        dependencies: _dependencies(),
      );
      await _match(tester, 'design_system/pattern_form.png');
    });

    testWidgets('settings / profile list: Settings & privacy', (tester) async {
      await _pumpFrame(
        tester,
        const AccountCanvas(
          frame: AccountFrame.settings,
          title: 'Settings & privacy',
          showBack: true,
          showBell: false,
          toggles: _toggles,
          onConsents: _noop,
        ),
      );
      await _match(tester, 'design_system/pattern_settings_list.png');
    });

    testWidgets('success: message sent', (tester) async {
      await _pumpFrame(
        tester,
        DirectoryCanvas(
          frame: DirectoryFrame.sent,
          offices: const <Office>[],
          office: _offices.first,
          onHotlines: _noop,
          onBack: _noop,
          onMessages: _noop,
        ),
      );
      await _match(tester, 'design_system/pattern_success.png');
    });

    testWidgets('notice / blocked: maintenance', (tester) async {
      await _pumpFrame(
        tester,
        const BlockingNoticeScreen(kind: BlockingNoticeKind.maintenance),
        dependencies: _dependencies(),
      );
      await _match(tester, 'design_system/pattern_notice.png');
    });

    testWidgets('card: the digital ID', (tester) async {
      await _pumpFrame(
        tester,
        DigitalIdView(
          now: DateTime(2026, 10, 22, 12),
          name: 'Resident Sample',
          sample: true,
          card: ResidentCredential(
            id: 'credential-sample-1',
            idNumber: 'TYT-0000-0000',
            state: CredentialLifecycleState.active,
            rawState: 'active',
            issuedAt: DateTime(2026, 10, 22),
            expiresAt: DateTime(2029, 10, 22),
            qr: PresentationArtifact(
              payload: 'sample-qr-not-a-credential',
              expiresAt: DateTime(2026, 10, 22, 21, 42),
            ),
          ),
        ),
      );
      await _match(tester, 'design_system/pattern_card.png');
    });

    testWidgets('splash', (tester) async {
      await _pumpFrame(
        tester,
        const SplashScreen(),
        dependencies: _dependencies(),
      );
      await _match(tester, 'design_system/pattern_splash.png');
      // The splash holds on a timer; let it run out.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    });

    testWidgets('messaging: a conversation', (tester) async {
      // The routed thread (AccountThreadScreen) draws this frame.
      await _pumpFrame(
        tester,
        const AccountCanvas(
          frame: AccountFrame.thread,
          title: 'Sample Office',
          subtitle: 'Sample Social Services Office',
          showBack: true,
          showBell: false,
          dayLabel: 'Tue, 20 Oct',
          bubbles: <AccountBubble>[
            AccountBubble(
              body: 'A synthetic question for the golden frame.',
              when: '9:05 AM',
              fromResident: true,
            ),
            AccountBubble(
              body: 'A synthetic answer from the office, long enough to wrap.',
              when: '9:40 AM',
              fromResident: false,
            ),
          ],
          onAttach: _noop,
          onSend: _noop,
        ),
      );
      await _match(tester, 'design_system/pattern_messaging.png');
    });
  });
}

/// The phone frame of every golden in the repository: 390 × 844 at 3×.
const Size _frame = Size(390, 844);
const double _dpr = 3;

const ValueKey<String> _frameKey = ValueKey<String>('design-system-frame');

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

/// Dev mock dependencies with no latency, for screens that read
/// [AppDependencies] (sign-in, the blocking notice, the splash).
AppDependencies _dependencies() {
  return AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: 'https://example.test/api/v1',
      isReleaseBuild: false,
      rawDataMode: 'mock',
      rawMockLatencyMs: '0',
    ),
    secrets: InMemorySecretStore(),
    sessionStore: InMemorySessionStore(),
  );
}

/// Pumps [screen] alone in the 390 × 844 frame at 3×, on the light theme,
/// with no text scaling and animations off, and waits for bundled images
/// and SVGs.
Future<void> _pumpFrame(
  WidgetTester tester,
  Widget screen, {
  AppDependencies? dependencies,
}) async {
  tester.view
    ..devicePixelRatio = _dpr
    ..physicalSize = _frame * _dpr
    ..padding = FakeViewPadding.zero
    ..viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
  if (dependencies != null) addTearDown(dependencies.dispose);

  final Widget app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    localizationsDelegates: AppStrings.localizationsDelegates,
    supportedLocales: AppStrings.supportedLocales,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
      child: child ?? const SizedBox.shrink(),
    ),
    home: RepaintBoundary(key: _frameKey, child: screen),
  );
  await tester.pumpWidget(
    dependencies == null
        ? app
        : AppDependenciesScope(dependencies: dependencies, child: app),
  );
  await _settle(tester);
}

/// Lets bundled SVGs and photos arrive, decodes every [Image] on screen,
/// then paints. Bounded rather than `pumpAndSettle`: a progress bar or a
/// skeleton never settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  final Finder images = find.byType(Image);
  for (final Element element in images.evaluate().toList()) {
    final Widget widget = element.widget;
    if (widget is Image && element.mounted) {
      await tester.runAsync(() => precacheImage(widget.image, element));
    }
  }
  await tester.pump(const Duration(milliseconds: 50));
}

/// Compares the whole view with [golden]. The capture is taken at the root,
/// as `component_golden_test.dart` takes `gallery_frame.png`, so the PNG is
/// the device frame: 1170 × 2532 pixels.
Future<void> _match(WidgetTester tester, String golden) async {
  expect(tester.getSize(find.byKey(_frameKey)), _frame);
  debugDisableShadows = false;
  try {
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(golden));
  } finally {
    debugDisableShadows = true;
  }
}

void _noop() {}

const List<HomeSlide> _slides = <HomeSlide>[
  HomeSlide(
    eyebrow: 'BALITA',
    title: 'A synthetic slide title for the golden frame',
    body: 'A synthetic sentence under the slide title.',
    action: 'Read Balita',
    photoAsset: 'assets/photos/municipal_hall.jpg',
    credit: 'Photo credit',
    routeName: 'news',
  ),
];

const List<HomeNewsItem> _news = <HomeNewsItem>[
  HomeNewsItem(
    id: 'n1',
    eyebrow: 'ADVISORY · SAMPLE OFFICE',
    title: 'A synthetic advisory title for the golden frame',
    alert: false,
  ),
  HomeNewsItem(
    id: 'n2',
    eyebrow: 'SAFETY',
    title: 'A synthetic safety notice',
    alert: true,
  ),
];

const HomeHotline _hotline = HomeHotline(
  id: 'line-1',
  name: 'Sample Command Center',
  number: '0900-000-0000',
  category: 'municipal',
);

const List<AccountToggle> _toggles = <AccountToggle>[
  AccountToggle(
    title: 'Balita & advisories',
    subtitle: 'Push notifications',
    icon: TaytayIcons.bell,
    tile: BrandColors.blue50,
    iconColor: BrandColors.blue,
    on: true,
  ),
  AccountToggle(
    title: 'Emergency alerts',
    subtitle: 'Always on',
    icon: TaytayIcons.siren,
    tile: BrandColors.red50,
    iconColor: BrandColors.redInk,
    on: true,
    locked: true,
  ),
];

const List<Office> _offices = <Office>[
  Office(
    id: 'sample-office',
    shortName: 'SAMPLE',
    name: 'Sample Social Services Office',
    listName: 'Sample Social Services Office',
    category: 'Social services',
    listLine: 'Ground floor, Sample Hall',
    icon: OfficeIcon.handHeart,
    keywords: <String>[],
    eyebrow: 'SOCIAL SERVICES',
    summary: 'A synthetic office description for the golden frame.',
    heroAsset: 'assets/photos/municipal_hall.jpg',
    heroFocus: 0.5,
    insetAsset: 'assets/photos/municipal_hall.jpg',
    representative: false,
    credit: '',
    messageable: true,
    callLabel: 'Call',
    callIsEmergency: false,
    phone: '0900-000-0000',
    directionsQuery: 'Sample Hall',
    facts: <OfficeFact>[
      OfficeFact(
        label: 'Location',
        value: 'Ground floor, Sample Hall',
        icon: OfficeFactIcon.pin,
      ),
      OfficeFact(
        label: 'Office hours',
        value: 'Monday to Friday, 8:00 AM to 5:00 PM',
        icon: OfficeFactIcon.clock,
      ),
    ],
    services: <OfficeServiceLine>[OfficeServiceLine(label: 'Certificates')],
  ),
  Office(
    id: 'sample-permits',
    shortName: 'PERMITS',
    name: 'Sample Permits Office',
    listName: 'Sample Permits Office',
    category: 'Permits',
    listLine: 'Second floor, Sample Hall',
    icon: OfficeIcon.fileText,
    keywords: <String>[],
    eyebrow: 'PERMITS',
    summary: 'A second synthetic office.',
    heroAsset: 'assets/photos/municipal_hall.jpg',
    heroFocus: 0.5,
    insetAsset: 'assets/photos/municipal_hall.jpg',
    representative: false,
    credit: '',
    messageable: true,
    callLabel: 'Call',
    callIsEmergency: false,
    phone: '',
    directionsQuery: 'Sample Hall',
    facts: <OfficeFact>[],
    services: <OfficeServiceLine>[],
  ),
  Office(
    id: 'sample-emergency',
    shortName: 'RESCUE',
    name: 'Sample Rescue Office',
    listName: 'Sample Rescue Office',
    category: 'Emergency',
    listLine: 'Sample Street',
    icon: OfficeIcon.siren,
    keywords: <String>[],
    eyebrow: 'EMERGENCY',
    summary: 'A third synthetic office.',
    heroAsset: 'assets/photos/rescue_vehicle.jpg',
    heroFocus: 0.5,
    insetAsset: 'assets/photos/rescue_vehicle.jpg',
    representative: false,
    credit: '',
    messageable: false,
    callLabel: 'Call',
    callIsEmergency: true,
    phone: '0900-000-0001',
    directionsQuery: 'Sample Street',
    facts: <OfficeFact>[],
    services: <OfficeServiceLine>[],
  ),
];
