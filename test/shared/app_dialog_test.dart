import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/shared/widgets/app_button.dart';
import 'package:taytay_resident/shared/widgets/app_dialog.dart';
import 'package:taytay_resident/shared/widgets/legal_text_sheet.dart';

import '../support/layout_matrix.dart';

/// F-review (D-202): every dialog opens through `AppDialog.show`, is announced
/// by its title, scrolls, draws its actions one way, keeps the theme's radius
/// and hands focus back to whatever opened it.
void main() {
  Future<void> open(WidgetTester tester, void Function(BuildContext) show) {
    return tester.pumpWidget(layoutHost(dialogOpener(show), scrollable: false));
  }

  Future<void> tapOpen(WidgetTester tester) async {
    await tester.tap(find.byKey(dialogOpenerKey));
    await tester.pumpAndSettle();
  }

  group('the title', () {
    testWidgets('is a heading that names the route', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await open(
        tester,
        (BuildContext context) => AppDialog.show<void>(
          context: context,
          title: 'A panel',
          builder: (BuildContext _) => const Text('Content'),
        ),
      );
      await tapOpen(tester);

      expect(
        tester.getSemantics(find.text('A panel')),
        isSemantics(label: 'A panel', isHeader: true, namesRoute: true),
      );
      semantics.dispose();
    });

    testWidgets('of a confirmation and a notice names the route too', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await open(
        tester,
        (BuildContext context) => AppDialog.confirm(
          context: context,
          title: 'Sign out?',
          message: 'You will need a new code.',
        ),
      );
      await tapOpen(tester);
      expect(
        tester.getSemantics(find.text('Sign out?')),
        isSemantics(isHeader: true, namesRoute: true),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await open(
        tester,
        (BuildContext context) => AppDialog.acknowledge(
          context: context,
          title: 'Nothing was changed',
          message: 'Try again.',
        ),
      );
      await tapOpen(tester);
      expect(
        tester.getSemantics(find.text('Nothing was changed')),
        isSemantics(isHeader: true, namesRoute: true),
      );
      semantics.dispose();
    });

    testWidgets('of the Terms or Privacy Notice names the route', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await open(
        tester,
        (BuildContext context) => showLegalTextSheet(
          context,
          title: 'Privacy Notice',
          markdown: Future<String?>.value(''),
          pending: privacyNoticeNotPublishedYet,
        ),
      );
      await tapOpen(tester);
      expect(
        tester.getSemantics(find.text('Privacy Notice')),
        isSemantics(isHeader: true, namesRoute: true),
      );
      semantics.dispose();
    });

    testWidgets('centres under a hero icon', (tester) async {
      await open(
        tester,
        (BuildContext context) => AppDialog.show<void>(
          context: context,
          title: 'With an icon',
          icon: const SizedBox(key: Key('hero'), width: 40, height: 40),
          builder: (BuildContext _) => const Text('Content'),
        ),
      );
      await tapOpen(tester);

      final Rect hero = tester.getRect(find.byKey(const Key('hero')));
      final Rect title = tester.getRect(find.text('With an icon'));
      expect(hero.bottom, lessThanOrEqualTo(title.top));
      expect(
        tester.widget<Text>(find.text('With an icon')).textAlign,
        TextAlign.center,
      );
    });
  });

  group('the actions', () {
    testWidgets('a confirmation: the confirm button over Cancel, full width', (
      tester,
    ) async {
      await open(
        tester,
        (BuildContext context) => AppDialog.confirm(
          context: context,
          title: 'Close this conversation?',
          message: 'The office will see it as closed.',
          confirmLabel: 'Close conversation',
          destructive: true,
        ),
      );
      await tapOpen(tester);

      final Finder actions = find.byType(AppDialogActions);
      expect(actions, findsOneWidget);
      final Finder confirm = find.widgetWithText(
        AppButton,
        'Close conversation',
      );
      final Finder cancel = find.widgetWithText(AppButton, 'Cancel');
      expect(
        tester.widget<AppButton>(confirm).variant,
        AppButtonVariant.danger,
      );
      expect(tester.widget<AppButton>(cancel).variant, AppButtonVariant.text);
      expect(
        tester.getRect(confirm).bottom,
        lessThanOrEqualTo(tester.getRect(cancel).top),
      );
      expect(
        tester.getSize(confirm).width,
        tester.getSize(actions).width,
        reason: 'stacked, full width',
      );
      for (final Finder button in <Finder>[confirm, cancel]) {
        expect(
          tester.getSize(button).height,
          greaterThanOrEqualTo(A11y.minTapTarget),
        );
      }
    });

    testWidgets('a notice: one text action that closes it', (tester) async {
      await open(
        tester,
        (BuildContext context) => AppDialog.acknowledge(
          context: context,
          title: 'Language',
          message: 'The app follows the language of this phone.',
        ),
      );
      await tapOpen(tester);

      final AppButton ok = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'OK'),
      );
      expect(ok.variant, AppButtonVariant.text);
      expect(find.byType(AppButton), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('the slot, the secondary button and Close', (tester) async {
      String? result;
      await open(tester, (BuildContext context) async {
        result = await AppDialog.show<String>(
          context: context,
          title: 'Three ways',
          builder: (BuildContext _) => const Text('Content'),
          actions: (BuildContext dialog) => AppDialogActions(
            primary: DialogButton(
              label: 'Forward',
              onPressed: () => Navigator.of(dialog).pop('forward'),
            ),
            secondary: DialogButton(
              label: 'Another way',
              onPressed: () => Navigator.of(dialog).pop('another'),
            ),
            text: DialogButton(
              label: 'Not now',
              onPressed: () => Navigator.of(dialog).pop('dismissed'),
            ),
          ),
        );
      });
      await tapOpen(tester);
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Another way'))
            .variant,
        AppButtonVariant.secondary,
      );
      await tester.tap(find.text('Another way'));
      await tester.pumpAndSettle();
      expect(result, 'another');

      await open(
        tester,
        (BuildContext context) => AppDialog.show<void>(
          context: context,
          title: 'A notice',
          builder: (BuildContext _) => const Text('Content'),
          actions: AppDialogActions.close,
        ),
      );
      await tapOpen(tester);
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Close'))
            .variant,
        AppButtonVariant.text,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  testWidgets('a confirmation and a notice keep the theme radius, 22', (
    tester,
  ) async {
    ShapeBorder? shapeOfOpenDialog() => tester
        .widget<Material>(
          find
              .descendant(
                of: find.byType(Dialog),
                matching: find.byType(Material),
              )
              .first,
        )
        .shape;

    await open(
      tester,
      (BuildContext context) => AppDialog.confirm(
        context: context,
        title: 'Sign out?',
        message: 'Message',
      ),
    );
    await tapOpen(tester);
    final ShapeBorder? confirm = shapeOfOpenDialog();
    expect(confirm, isA<RoundedRectangleBorder>());
    expect(
      (confirm as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(Radii.dialog),
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await open(
      tester,
      (BuildContext context) => AppDialog.acknowledge(
        context: context,
        title: 'Saved',
        message: 'Message',
      ),
    );
    await tapOpen(tester);
    expect(shapeOfOpenDialog(), confirm);
  });

  testWidgets('without scrolling, a long notice scrolls itself and Close stays '
      'in view at 360 dp and 200% text', (tester) async {
    addTearDown(tester.view.reset);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 800);
    final String markdown = <String>[
      for (var i = 0; i < 30; i++)
        '- A long sentence about your data, long enough to wrap over several '
            'lines at large text.',
    ].join('\n\n');
    await tester.pumpWidget(
      layoutHost(
        dialogOpener(
          (BuildContext context) => showLegalTextSheet(
            context,
            title: 'Privacy Notice',
            markdown: Future<String?>.value(markdown),
            pending: privacyNoticeNotPublishedYet,
          ),
        ),
        textScale: 2,
        scrollable: false,
      ),
    );
    await tapOpen(tester);

    final Rect dialog = tester.getRect(
      find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first,
    );
    final Rect close = tester.getRect(find.byKey(legalTextCloseKey));
    expect(close.bottom, lessThanOrEqualTo(dialog.bottom));
    expect(close.top, greaterThanOrEqualTo(dialog.top));
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
      reason: 'the frame does not scroll; the notice does',
    );
    await tester.tap(find.byKey(legalTextCloseKey));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('focus goes into the dialog and returns to the opener', (
    tester,
  ) async {
    final FocusNode opener = FocusNode(debugLabel: 'opener');
    addTearDown(opener.dispose);
    await tester.pumpWidget(
      layoutHost(
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              focusNode: opener,
              onPressed: () => AppDialog.confirm(
                context: context,
                title: 'Sign out?',
                message: 'You will need a new code.',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        scrollable: false,
      ),
    );
    opener.requestFocus();
    await tester.pump();
    expect(opener.hasPrimaryFocus, isTrue);

    // A keyboard user opens it from the button.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(opener.hasFocus, isFalse, reason: 'focus left the page');

    // Tab moves through the dialog's own controls and stays inside it.
    bool focusInDialog() {
      final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
      if (focused == null) return false;
      return find
          .ancestor(
            of: find.byElementPredicate(
              (Element element) => identical(element, focused),
            ),
            matching: find.byType(Dialog),
          )
          .evaluate()
          .isNotEmpty;
    }

    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusInDialog(), isTrue, reason: 'Tab $i left the dialog');
    }

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(opener.hasPrimaryFocus, isTrue, reason: 'focus came back');
  });
}
