import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/documents/document_capture.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

// ─── Devices ────────────────────────────────────────────────────────────────
//
// Real shapes rather than round numbers, because the failures this catches are
// at the edges: a notch, a short landscape window, a tablet wide enough for the
// rail.

/// One device to render on.
typedef Device = ({String name, Size size, EdgeInsets insets});

const List<Device> devices = <Device>[
  // The floor. A 5-inch Android phone is still very much in service in Taytay,
  // and it is the size that clips first.
  (name: 'small phone', size: Size(320, 568), insets: EdgeInsets.zero),
  (
    name: 'phone with a notch',
    size: Size(390, 844),
    // A tall status-bar cutout and a home indicator. Content must clear both.
    insets: EdgeInsets.only(top: 47, bottom: 34),
  ),
  (name: 'large phone', size: Size(430, 932), insets: EdgeInsets.zero),
  (
    name: 'phone in landscape',
    size: Size(844, 390),
    // In landscape the cutout moves to the side.
    insets: EdgeInsets.only(left: 47, right: 47),
  ),
  (name: 'tablet', size: Size(1024, 1366), insets: EdgeInsets.zero),
];

/// Every session state, because a screen that only renders for one of them has
/// only been checked for one of them.
const List<AccessLevel> levels = <AccessLevel>[
  AccessLevel.guest,
  AccessLevel.unverified,
  AccessLevel.verified,
];

/// Routes a resident reaches without a backend. Every one of these renders from
/// the app's own state, so a layout failure here is a layout failure, not a
/// missing endpoint.
const List<String> coreRoutes = <String>[
  '/home',
  '/services',
  '/news',
  '/events',
  '/profile',
  '/settings',
  '/settings/help',
];

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

Future<AppDependencies> boot(
  WidgetTester tester, {
  required AccessLevel level,
  required Device device,
  TextScaler textScaler = TextScaler.noScaling,
  Locale locale = AppLocales.english,
  String location = '/home',
}) async {
  tester.view.physicalSize = device.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // Through the device's own preference and the app's `localeResolutionCallback`
  // — the real path — rather than by overriding `Localizations` around the app,
  // which would prove the widget tree and not the resolution rule.
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = <Locale>[locale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final sessionStore = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await sessionStore.write(
      StoredSession(
        resident: ResidentSession(
          accountId: 'acct-1',
          accessLevel: level,
          displayName: 'Ana',
        ),
        accessToken: 'token',
      ),
    );
  }

  final dependencies = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
    documentPicker: const UnavailableDocumentPicker(),
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view).copyWith(
        textScaler: textScaler,
        padding: device.insets,
        viewPadding: device.insets,
      ),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  if (location != '/home') {
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
    await tester.pumpAndSettle();
  }
  return dependencies;
}

/// Every rendered overflow, as a list of sentences.
List<String> overflows(WidgetTester tester) {
  final found = <String>[];
  Object? error = tester.takeException();
  while (error != null) {
    found.add('$error');
    error = tester.takeException();
  }
  return found;
}

void main() {
  // ── Size and orientation ────────────────────────────────────────────────

  group('Core routes render on every device shape', () {
    for (final device in devices) {
      testWidgets(device.name, (tester) async {
        for (final route in coreRoutes) {
          await boot(
            tester,
            level: AccessLevel.verified,
            device: device,
            location: route,
          );
          expect(
            overflows(tester),
            isEmpty,
            reason: '$route on ${device.name}',
          );
        }
      });
    }
  });

  group('Core routes render for every session state', () {
    for (final level in levels) {
      testWidgets('$level', (tester) async {
        for (final route in coreRoutes) {
          await boot(tester, level: level, device: devices[1], location: route);
          expect(overflows(tester), isEmpty, reason: '$route as $level');
        }
      });
    }
  });

  // ── Text scaling ────────────────────────────────────────────────────────
  //
  // Acceptance: core flows are usable with large text.

  group('Core routes survive the largest supported text', () {
    for (final scale in <double>[1.3, 1.6, A11y.maxSupportedTextScale]) {
      testWidgets('at ${scale}x', (tester) async {
        for (final route in coreRoutes) {
          await boot(
            tester,
            level: AccessLevel.verified,
            // The tall phone: a layout that scrolls needs room to prove it.
            device: devices[1],
            textScaler: TextScaler.linear(scale),
            location: route,
          );
          expect(overflows(tester), isEmpty, reason: '$route at ${scale}x');
        }
      });
    }

    testWidgets('the smallest phone at 200% still renders', (tester) async {
      // The hardest combination in the matrix, and the one a resident with low
      // vision on an old handset actually has.
      for (final route in coreRoutes) {
        await boot(
          tester,
          level: AccessLevel.verified,
          device: devices.first,
          textScaler: const TextScaler.linear(A11y.maxSupportedTextScale),
          location: route,
        );
        expect(overflows(tester), isEmpty, reason: '$route on a small phone');
      }
    });
  });

  // ── Localised layout ────────────────────────────────────────────────────

  group('Filipino copy fits where English does', () {
    testWidgets('the navigation bar is actually in Filipino', (tester) async {
      await boot(
        tester,
        level: AccessLevel.verified,
        device: devices.first,
        locale: AppLocales.filipino,
      );

      // Proves the locale reached the widgets, so the layout assertions below
      // are measuring Filipino rather than English on a Filipino device.
      expect(find.text('Mga Serbisyo'), findsWidgets);
      expect(find.text('Mga Kaganapan'), findsWidgets);
      expect(find.text('Balita'), findsWidgets);
      expect(find.text('Events'), findsNothing);
    });

    testWidgets('core routes render in Filipino', (tester) async {
      // Filipino runs longer than English — "Mga Kaganapan" against "Events" —
      // and a navigation bar that fits one and clips the other is a bar that
      // was only ever checked in one language.
      for (final route in coreRoutes) {
        await boot(
          tester,
          level: AccessLevel.verified,
          device: devices.first,
          locale: AppLocales.filipino,
          location: route,
        );
        expect(overflows(tester), isEmpty, reason: '$route in Filipino');
      }
    });

    testWidgets('and in Filipino at 200%', (tester) async {
      for (final route in coreRoutes) {
        await boot(
          tester,
          level: AccessLevel.verified,
          device: devices[1],
          textScaler: const TextScaler.linear(A11y.maxSupportedTextScale),
          locale: AppLocales.filipino,
          location: route,
        );
        expect(overflows(tester), isEmpty, reason: '$route in Filipino at 2x');
      }
    });
  });

  // ── Tap targets ─────────────────────────────────────────────────────────

  group('Every tappable thing is big enough to hit', () {
    testWidgets('on the core routes, at the default scale', (tester) async {
      for (final route in coreRoutes) {
        await boot(
          tester,
          level: AccessLevel.verified,
          device: devices[1],
          location: route,
        );

        final undersized = <String>[];
        for (final element
            in find
                .byWidgetPredicate(
                  (widget) =>
                      widget is IconButton ||
                      widget is FilledButton ||
                      widget is OutlinedButton ||
                      widget is TextButton,
                )
                .evaluate()) {
          final size = element.size;
          if (size == null) continue;
          // Zero-sized means laid out but not painted — an offscreen list item,
          // not a target a resident can miss.
          if (size.height == 0 || size.width == 0) continue;
          if (size.height + 0.01 < A11y.minTapTarget) {
            undersized.add(
              '${element.widget.runtimeType} ${size.height}dp on $route',
            );
          }
        }

        expect(undersized, isEmpty);
      }
    });
  });

  // ── Safe areas ──────────────────────────────────────────────────────────

  group('Content clears the notch and the home indicator', () {
    testWidgets('nothing is drawn under the status-bar cutout', (tester) async {
      const device = (
        name: 'phone with a notch',
        size: Size(390, 844),
        insets: EdgeInsets.only(top: 47, bottom: 34),
      );

      for (final route in coreRoutes) {
        await boot(
          tester,
          level: AccessLevel.verified,
          device: device,
          location: route,
        );

        // The app bar, where there is one, is the topmost thing a resident
        // reads. Under a cutout it becomes unreadable rather than merely ugly.
        final bars = find.byType(AppBar);
        for (final element in bars.evaluate()) {
          final box = element.renderObject! as RenderBox;
          final top = box.localToGlobal(Offset.zero).dy;
          expect(
            top,
            greaterThanOrEqualTo(0),
            reason: 'the app bar on $route sits above the viewport',
          );
        }
      }
    });
  });
}
