// The screen audit of D-220: a failed read is said as a failure with Try
// again, a skeleton never stays up for ever, a default is never drawn as the
// resident's own setting, and a control is read once.
//
// The screen-level halves live beside their features (notifications_test,
// events_test, household_test, profile_test); these hold the canvases.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/home/domain/home_content.dart';
import 'package:taytay_resident/features/home/presentation/hotlines_screen.dart';
import 'package:taytay_resident/features/shell/presentation/shell_destinations.dart';
import 'package:taytay_resident/features/shell/presentation/shell_tab_bar.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';

import '../support/layout_matrix.dart';

void _ignore(int _) {}

void main() {
  group('hotlines', () {
    testWidgets('a failed read offers Try again, never "none published"', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        layoutHost(
          HotlinesCanvas(
            lines: const <HomeHotline>[],
            failure: const NetworkFailure(),
            onRetry: () => retries++,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();

      expect(find.text('No hotlines to show'), findsNothing);
      expect(find.textContaining('has not published'), findsNothing);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('the failed read fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => HotlinesCanvas(
          lines: const <HomeHotline>[],
          failure: const NetworkFailure(),
          onRetry: () {},
        ),
        scrollable: false,
      );
    });
  });

  group('the message page of an office', () {
    Widget unavailable(VoidCallback onRetry) => DirectoryCanvas(
      frame: DirectoryFrame.compose,
      offices: const <Office>[],
      officeUnavailable: true,
      onRetry: onRetry,
    );

    testWidgets('an office that did not load says so, with Try again', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        layoutHost(unavailable(() => retries++), scrollable: false),
      );
      await tester.pump();

      expect(find.text('This office did not load'), findsOneWidget);
      expect(find.bySemanticsLabel('Loading the office'), findsNothing);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
    });

    testWidgets('it fits every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => unavailable(() {}),
        scrollable: false,
      );
    });
  });

  group('settings', () {
    testWidgets('the switches wait for the read; a default is never shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountCanvas(
            frame: AccountFrame.settings,
            title: 'Settings & privacy',
            showBack: true,
            showBell: false,
            toggles: AccountSpecimen.toggles,
            togglesPlaceholder: SizedBox(key: Key('toggles-placeholder')),
          ),
          scrollable: false,
        ),
      );
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byKey(const Key('toggles-placeholder')), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });
  });

  group('the tab bar', () {
    testWidgets('each tab is one button, read once', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ShellTabBar(selectedIndex: 0, onSelected: _ignore),
            ),
          ),
        ),
      );
      await tester.pump();

      final AppStrings strings = AppStrings.of(
        tester.element(find.byType(ShellTabBar)),
      );
      for (final ShellDestination destination in ShellDestination.values) {
        final String label = destination.labelIn(strings);
        // One node, labelled once: not "Balita\nBalita", and no second
        // "Balita" button for the disc.
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      semantics.dispose();
    });
  });
}
