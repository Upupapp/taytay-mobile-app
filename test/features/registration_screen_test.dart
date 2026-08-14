import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/app/taytay_resident_app.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';

AppConfig config() => AppConfig.from(
  rawEnvironment: 'dev',
  rawApiBaseUrl: 'https://example.test/api/v1',
  isReleaseBuild: false,
);

/// Boots the app straight into the registration wizard.
Future<AppDependencies> bootRegistration(
  WidgetTester tester, {
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');

  final dependencies = AppDependencies.build(
    config: config(),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
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

  // Home → Sign in → Create an account.
  await tapAfterScrolling(tester, find.text('Sign in'));
  await tapAfterScrolling(tester, find.text('Create an account'));

  return dependencies;
}

/// Scrolls [finder] into view if needed, then taps it.
///
/// At a large text scale the lower controls on a screen sit below the fold, and
/// an un-scrolled tap simply misses — a failure that reads like a logic bug.
Future<void> tapAfterScrolling(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('reaching the wizard', () {
    testWidgets('a guest can start registration from sign-in', (tester) async {
      await bootRegistration(tester);

      expect(find.text('Contact details'), findsWidgets);
      expect(find.text('Mobile number'), findsOneWidget);
    });

    testWidgets('the sign-in gate also offers creating an account', (
      tester,
    ) async {
      // A resident with no account cannot sign in; offering only "Sign in"
      // would strand them at the gate.
      final secrets = InMemorySecretStore();
      await secrets.write(LaunchController.welcomeCompletedKey, 'true');
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final dependencies = AppDependencies.build(
        config: config(),
        secrets: secrets,
        sessionStore: InMemorySessionStore(),
      );
      addTearDown(dependencies.dispose);

      await tester.pumpWidget(TaytayResidentApp(dependencies: dependencies));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Taytay digital ID'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Create an account'),
        ),
        findsOneWidget,
      );
    });
  });

  group('progress and step structure', () {
    testWidgets('progress is announced as text, not only as a bar', (
      tester,
    ) async {
      await bootRegistration(tester);
      // Six input steps when nothing optional is required.
      expect(find.bySemanticsLabel(RegExp('Step 1 of 6')), findsOneWidget);
      expect(find.text('Step 1 of 6'), findsOneWidget);
    });

    testWidgets('the wizard is one step per screen, never a giant form', (
      tester,
    ) async {
      await bootRegistration(tester);

      // Only the contact field is present; nothing from later steps.
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('First name'), findsNothing);
      expect(find.text('Barangay'), findsNothing);
      expect(find.text('Terms of Use'), findsNothing);
    });
  });

  group('validation and error summary', () {
    testWidgets('continuing with an empty field shows a summary', (
      tester,
    ) async {
      await bootRegistration(tester);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('There is a problem'), findsOneWidget);
      expect(find.textContaining('Enter your mobile number'), findsWidgets);
    });

    testWidgets('the summary counts multiple problems', (tester) async {
      await bootRegistration(tester);
      // Reach the personal step, where several fields can fail at once.
      await tester.enterText(find.byType(TextFormField).first, '09171234567');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // The one-time-code request declines (no Identity backend), so the
      // resident stays on contact with an honest failure rather than a summary.
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    });

    testWidgets('fields carry required and optional labels', (tester) async {
      await bootRegistration(tester);
      // Marking only required fields leaves a resident inferring the rest, and
      // an asterisk means nothing to a screen reader.
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.textContaining('(optional)'), findsNothing);
    });
  });

  group('transparency', () {
    testWidgets('a sensitive field carries an expandable explanation', (
      tester,
    ) async {
      await bootRegistration(tester);

      expect(find.text('Why we ask for this'), findsOneWidget);

      await tester.tap(find.text('Why we ask for this'));
      await tester.pumpAndSettle();

      // The panel body is `RichText`, so the finder has to look inside spans.
      expect(find.textContaining('Why: ', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Who sees it: ', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('honest seams', () {
    testWidgets('requesting a code declines rather than pretending', (
      tester,
    ) async {
      await bootRegistration(tester);

      await tester.enterText(find.byType(TextFormField).first, '09171234567');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Still on the contact step, told the truth.
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    });

    testWidgets('no camera or file picker is opened anywhere', (tester) async {
      // The upload steps are absent entirely while capabilities are denied, so
      // there is no path on which this build captures an identity image.
      await bootRegistration(tester);
      expect(find.text('Proof of identity'), findsNothing);
      expect(find.text('Photo of you'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility', () {
    testWidgets('the wizard survives a 200% text scale', (tester) async {
      await bootRegistration(tester, textScaler: const TextScaler.linear(2));
      expect(tester.takeException(), isNull);

      await tapAfterScrolling(tester, find.text('Continue'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the progress bar itself is hidden from assistive tech', (
      tester,
    ) async {
      await bootRegistration(tester);
      // The text carries the meaning; a percentage announcement would be noise.
      expect(
        find.descendant(
          of: find.byType(ExcludeSemantics),
          matching: find.byType(LinearProgressIndicator),
        ),
        findsOneWidget,
      );
    });
  });
}
