import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/motion/motion_tokens.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/shared/widgets/gold_thread_shell.dart';
import 'package:taytay_resident/shared/widgets/taytay_thread.dart';

/// Sprint S9: the shared thread, the layout rule, and the softened copy.
void main() {
  test('onboarding and auth do not nudge with Transform.translate', () {
    final List<String> offenders = <String>[];
    for (final String folder in <String>[
      'lib/features/onboarding',
      'lib/features/auth',
    ]) {
      for (final FileSystemEntity entity in Directory(
        folder,
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains('Transform.translate')) {
          offenders.add(entity.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('the woven wordmark is laid out without a translate', () {
    final String source = File(
      'lib/shared/widgets/taytay_headers.dart',
    ).readAsStringSync();
    expect(source.contains('Transform.translate'), isFalse);
  });

  test('the about version is one sentence with no hard break', () {
    final String source = File(
      'lib/features/account/presentation/account_canvas.dart',
    ).readAsStringSync();
    expect(
      source.contains(
        'Municipality of Taytay, Rizal · version 0.1 (design mockup)',
      ),
      isTrue,
    );
    expect(source.contains('design\n'), isFalse);
    expect(source.contains(r"design '"), isFalse);
  });

  test(
    'profile, registration, verification, household and requests do not invite an application',
    () {
      const List<String> files = <String>[
        'lib/features/profile/presentation/profile_screen.dart',
        'lib/features/registration/presentation/registration_screen.dart',
        'lib/features/verification/presentation/kyc_claim_screen.dart',
        'lib/features/household/presentation/household_screen.dart',
        'lib/features/services/presentation/assistance_requests_screen.dart',
      ];
      for (final String path in files) {
        final String source = File(path).readAsStringSync();
        expect(source.contains('anything you apply'), isFalse, reason: path);
        expect(source.contains('apply for'), isFalse, reason: path);
        expect(source.contains('service applications'), isFalse, reason: path);
      }
    },
  );

  test('welcome curves meet and a fractional page stays between them', () {
    expect(ThreadCurve.pages[0].exitY, ThreadCurve.pages[1].entryY);
    expect(ThreadCurve.pages[1].exitY, ThreadCurve.pages[2].entryY);
    final ThreadCurve mid = ThreadCurve.welcomeAt(0.5);
    expect(mid.entryY, 250);
    expect(mid.exitY, 235);
    expect(ThreadCurve.welcomeAt(0), ThreadCurve.pages[0]);
    expect(ThreadCurve.welcomeAt(2), ThreadCurve.pages[2]);
  });

  testWidgets('the gold thread clock survives welcome, sign-in and sign-up', (
    WidgetTester tester,
  ) async {
    WelcomeMotion.enabled = true;
    addTearDown(() => WelcomeMotion.enabled = false);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
    );
    addTearDown(dependencies.dispose);
    await dependencies.session.restore();
    await dependencies.launch.restore();
    expect(dependencies.launch.state, LaunchState.firstLaunch);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          disableAnimations: false,
        ),
        child: TaytayResidentApp(dependencies: dependencies),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
    final GoldThreadModel model = GoldThreadScope.maybeOf(
      tester.element(find.text('Skip')),
    )!;
    final int shell = identityHashCode(model);
    expect(model.clock.isAnimating, isTrue);
    final double marked = model.cycle;
    await tester.pump(const Duration(seconds: 2));
    expect(model.cycle, isNot(marked));
    expect(find.byType(GoldThreadShell), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(identityHashCode(model), shell);
    expect(model.clock.isAnimating, isTrue);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final double atPage3 = model.cycle;
    await tester.tap(find.text('Get started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Maligayang pagbabalik!'), findsOneWidget);
    expect(identityHashCode(model), shell);
    expect(model.clock.isAnimating, isTrue);
    expect(model.cycle, isNot(atPage3));
    expect(find.byType(GoldThreadShell), findsOneWidget);
    expect(find.byKey(TravellingLight.mark), findsOneWidget);

    final double atSignIn = model.cycle;
    await tester.tap(find.text('Create an account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Tungkol sa iyo'), findsOneWidget);
    expect(identityHashCode(model), shell);
    expect(model.clock.isAnimating, isTrue);
    expect(model.cycle, isNot(atSignIn));
    expect(find.byType(GoldThreadShell), findsOneWidget);
    expect(find.byKey(TravellingLight.mark), findsOneWidget);
    // Redesign P3a: the gold thread and its travelling light are gone from
    // welcome and sign-in (design/mobile/screens/Main.dc.html, SignIn.dc.html).
    // Phase 4 deletes this test with gold_thread_shell.dart.
  }, skip: true);

  testWidgets('reduced motion keeps the thread and hides the tip', (
    WidgetTester tester,
  ) async {
    MotionPreference.set(MotionPreference.reduced);
    addTearDown(MotionPreference.reset);
    WelcomeMotion.enabled = true;
    addTearDown(() => WelcomeMotion.enabled = false);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final AppDependencies dependencies = AppDependencies.build(
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
    addTearDown(dependencies.dispose);
    await dependencies.session.restore();
    await dependencies.launch.restore();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: TaytayResidentApp(dependencies: dependencies),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.byType(SignInThreadOverlay), findsOneWidget);
    expect(find.byKey(TravellingLight.mark), findsNothing);
    final GoldThreadModel model = GoldThreadScope.maybeOf(
      tester.element(find.text('Skip')),
    )!;
    expect(model.clock.isAnimating, isFalse);
    // Redesign P3a: the gold thread and its travelling light are gone from
    // welcome and sign-in (design/mobile/screens/Main.dc.html, SignIn.dc.html).
    // Phase 4 deletes this test with gold_thread_shell.dart.
  }, skip: true);
}
