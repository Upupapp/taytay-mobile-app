import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

/// My Account as a verified resident, on the dev mock so the record loads.
Future<void> _boot(
  WidgetTester tester, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
  await store.write(
    const StoredSession(
      resident: ResidentSession(
        accountId: 'acct-sample',
        accessLevel: AccessLevel.verified,
        displayName: 'Ana',
      ),
      accessToken: 'token-sample',
    ),
  );
  final AppDependencies dependencies = AppDependencies.build(
    config: AppConfig.from(
      rawEnvironment: 'dev',
      rawApiBaseUrl: '',
      isReleaseBuild: false,
      rawDataMode: 'mock',
      rawMockLatencyMs: '0',
    ),
    secrets: secrets,
    sessionStore: store,
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: textScaler),
      child: TaytayResidentApp(dependencies: dependencies),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profile');
  await tester.pumpAndSettle();
}

List<String> _overflows(WidgetTester tester) {
  final List<String> found = <String>[];
  Object? error = tester.takeException();
  while (error != null) {
    found.add('$error');
    error = tester.takeException();
  }
  return found;
}

final Finder _scroll = find.descendant(
  of: find.byKey(const Key('account-home-scroll')),
  matching: find.byType(Scrollable),
);

const String _row = 'Request documents';

/// The catalogue's own link to My document requests, near its top: the test
/// knows the catalogue is the page on top, not a screen sharing its title.
final Finder _catalogue = find.byKey(const Key('issuance-my-requests'));

void main() {
  testWidgets('Request documents opens the catalogue, and back returns here', (
    tester,
  ) async {
    await _boot(tester, size: const Size(400, 900));
    expect(_overflows(tester), isEmpty);
    expect(find.text('Verification status'), findsOneWidget);

    // First in the second card: after the three office rows, before Household.
    final double row = tester.getTopLeft(find.text(_row)).dy;
    expect(
      row,
      greaterThan(tester.getTopLeft(find.text('Verification status')).dy),
    );
    expect(row, lessThan(tester.getTopLeft(find.text('Household')).dy));
    expect(find.text('Certificates and copies from offices'), findsOneWidget);
    // Redesign P3c: a menu row now reads its title and its detail as one
    // label ("Request documents, Certificates and copies from offices").
    expect(
      tester
          .getSize(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is Semantics &&
                  (widget.properties.label ?? '').startsWith('$_row, '),
            ),
          )
          .height,
      greaterThanOrEqualTo(A11y.minTapTarget),
    );

    await tester.ensureVisible(find.text(_row));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_row));
    await tester.pumpAndSettle();
    expect(_catalogue, findsOneWidget);

    await tester.tap(find.byType(TaytayBackButton));
    await tester.pumpAndSettle();
    expect(_catalogue, findsNothing);
    expect(find.text(_row), findsOneWidget);
    expect(_overflows(tester), isEmpty);
  });

  // Redesign P3c: the old 08-01 frame stretched the sign-out card to the foot
  // of the page. Account.dc.html draws Sign out as its own one-row glass list
  // under the menu, so the row keeps its own height (a full target) instead.
  testWidgets('at 1× sign out is its own row under the menu', (tester) async {
    // A tall phone: the design's frame, with room left under the menu.
    await _boot(tester, size: const Size(430, 1400));
    expect(_overflows(tester), isEmpty);
    expect(tester.state<ScrollableState>(_scroll).position.maxScrollExtent, 0);
    final Finder signOut = find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics && widget.properties.label == 'Sign out',
    );
    final double height = tester.getSize(signOut).height;
    expect(height, greaterThanOrEqualTo(A11y.minTapTarget));
    expect(height, lessThan(200));
    expect(
      tester.getTopLeft(signOut).dy,
      greaterThan(tester.getBottomLeft(find.text('Photo credits & about')).dy),
    );
  });

  // Text scaling is honoured up to 200% (Article 6). The smallest phone is the
  // hardest case: the menu is taller than the screen, so the page must scroll,
  // and each row must be read whole rather than cut to a 1× line box.
  for (final double scale in <double>[1.3, 1.6, A11y.maxSupportedTextScale]) {
    testWidgets('at ${scale}x text on a small phone it scrolls to every row', (
      tester,
    ) async {
      await _boot(
        tester,
        size: const Size(320, 568),
        textScaler: TextScaler.linear(scale),
      );
      expect(_overflows(tester), isEmpty, reason: 'My Account at ${scale}x');
      expect(
        tester.state<ScrollableState>(_scroll).position.maxScrollExtent,
        greaterThan(0),
      );

      final Finder row = find.text(_row);
      await tester.scrollUntilVisible(row, 120, scrollable: _scroll);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(tester.getSize(row).height, greaterThanOrEqualTo(14 * scale));
      expect(
        tester
            .getSize(find.text('Certificates and copies from offices'))
            .height,
        greaterThanOrEqualTo(12 * scale),
      );

      // The last card is reachable and still a full target.
      final Finder signOut = find.text('Sign out');
      await tester.scrollUntilVisible(signOut, 120, scrollable: _scroll);
      await tester.ensureVisible(signOut);
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(
              find.byWidgetPredicate(
                (Widget widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'Sign out',
              ),
            )
            .height,
        greaterThanOrEqualTo(A11y.minTapTarget),
      );
      expect(_overflows(tester), isEmpty);

      await tester.scrollUntilVisible(row, -120, scrollable: _scroll);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(_catalogue, findsOneWidget);
      expect(_overflows(tester), isEmpty, reason: 'catalogue at ${scale}x');
    });
  }
}
