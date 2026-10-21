import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/directory/data/office_catalogue.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/verification/presentation/unverified_gate_sheet.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

AppConfig _config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

Future<void> _boot(
  WidgetTester tester, {
  required AccessLevel level,
  String location = '/services',
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final sessionStore = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await sessionStore.write(
      StoredSession(
        resident: ResidentSession(accountId: 'acct-1', accessLevel: level),
        accessToken: 'token',
      ),
    );
  }
  final dependencies = AppDependencies.build(
    config: _config(),
    secrets: secrets,
    sessionStore: sessionStore,
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  addTearDown(dependencies.dispose);

  await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

Future<void> _pumpCanvas(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: child,
    ),
  );
  await tester.pump();
}

void _expectAtLeast48(WidgetTester tester, Key key) {
  final Finder marked = find.byKey(key);
  expect(marked, findsOneWidget, reason: '$key is missing');
  final Size size = tester.getSize(marked);
  expect(size.width, greaterThanOrEqualTo(A11y.minTapTarget), reason: '$key');
  expect(size.height, greaterThanOrEqualTo(A11y.minTapTarget), reason: '$key');
}

void main() {
  test('the catalogue is nine offices from the fixture', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load();
    expect(catalogue.chips, hasLength(6));
    expect(catalogue.offices, hasLength(9));
    expect(catalogue.offices.map((Office office) => office.id), <String>[
      'mswdo',
      'treasury',
      'assessor',
      'bplo',
      'mdrrmo',
      'peso',
      'pio',
      'tydo',
      'health',
    ]);
    expect(
      catalogue.offices
          .singleWhere((Office office) => office.id == 'mdrrmo')
          .messageable,
      isFalse,
    );

    final String source = File(
      'lib/features/directory/presentation/directory_canvas.dart',
    ).readAsStringSync();
    expect(source.contains('Transform.translate'), isFalse);
    expect(source.contains('0985-488-3352'), isFalse);
    expect(source.contains('Tax Declaration'), isFalse);
  });

  testWidgets('one canvas paints every office, and sample facts stay tagged', (
    tester,
  ) async {
    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load();
    for (final Office office in catalogue.offices) {
      await _pumpCanvas(
        tester,
        DirectoryCanvas(
          frame: DirectoryFrame.detail,
          offices: catalogue.offices,
          office: office,
        ),
      );
      expect(find.text(office.shortName), findsWidgets);
      expect(find.text(office.name), findsOneWidget);
      final int samples =
          office.facts.where((OfficeFact fact) => fact.sample).length +
          office.services.where((OfficeServiceLine line) => line.sample).length;
      expect(
        find.text('SAMPLE'),
        samples == 0 ? findsNothing : findsNWidgets(samples),
        reason: office.id,
      );
    }
  });

  testWidgets('directory hits are at least 48 dp and the back mark is 44', (
    tester,
  ) async {
    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load();
    await _pumpCanvas(
      tester,
      DirectoryCanvas(
        frame: DirectoryFrame.list,
        offices: catalogue.offices,
        chips: catalogue.chips,
      ),
    );
    _expectAtLeast48(tester, const Key('directory-bell'));
    for (final Office office in catalogue.offices) {
      _expectAtLeast48(tester, Key('directory-office-${office.id}'));
    }

    final Office bplo = catalogue.offices.singleWhere(
      (Office office) => office.id == 'bplo',
    );
    await _pumpCanvas(
      tester,
      DirectoryCanvas(
        frame: DirectoryFrame.detail,
        offices: const <Office>[],
        office: bplo,
        onBack: () {},
        onCall: () {},
        onDirections: () {},
        onMessage: () {},
      ),
    );
    for (final String name in <String>[
      'directory-call',
      'directory-directions',
      'directory-message',
    ]) {
      _expectAtLeast48(tester, Key(name));
    }
    expect(tester.getSize(find.byType(TaytayBackButton)), const Size(48, 48));
    final Finder mark = find.descendant(
      of: find.byType(TaytayBackButton),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == A11y.backButtonVisual &&
            widget.height == A11y.backButtonVisual,
      ),
    );
    expect(tester.getSize(mark.first), const Size(44, 44));
  });

  for (final AccessLevel level in <AccessLevel>[
    AccessLevel.guest,
    AccessLevel.unverified,
  ]) {
    testWidgets('a $level Message opens the verification gate', (tester) async {
      await _boot(tester, level: level, location: '/offices/bplo');
      await tester.tap(find.byKey(const Key('directory-message')));
      await tester.pumpAndSettle();
      expect(find.byType(UnverifiedGateSheet), findsOneWidget);
      expect(
        find.text('Verify your account to message offices'),
        findsOneWidget,
      );
      expect(find.text('New message'), findsNothing);
    });
  }

  testWidgets('a verified resident reaches compose', (tester) async {
    await _boot(tester, level: AccessLevel.verified, location: '/offices/bplo');
    await tester.tap(find.byKey(const Key('directory-message')));
    await tester.pumpAndSettle();
    expect(find.byType(UnverifiedGateSheet), findsNothing);
    expect(find.text('New message'), findsOneWidget);
    expect(find.textContaining('business permit'), findsWidgets);
  });
}
