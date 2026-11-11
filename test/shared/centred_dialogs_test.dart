import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/intent/resident_intent.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/access_policy.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/resident_capability.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/gallery/presentation/theme_gallery_section.dart';
import 'package:taytay_resident/features/profile/domain/profile_fields.dart';
import 'package:taytay_resident/features/profile/presentation/profile_field_list.dart';
import 'package:taytay_resident/features/requirements/presentation/requirements_screen.dart';
import 'package:taytay_resident/features/verification/presentation/verification_screen.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/access_gate_sheet.dart';
import 'package:taytay_resident/shared/widgets/app_button.dart';
import 'package:taytay_resident/shared/widgets/app_dialog.dart';
import 'package:taytay_resident/shared/widgets/confirm_sheet.dart';
import 'package:taytay_resident/shared/widgets/legal_text_sheet.dart';
import 'package:taytay_resident/shared/widgets/session_expired_sheet.dart';

import '../support/layout_matrix.dart';

/// F1, item 2: every gate, notice, confirmation and decision that used to
/// slide up from the bottom is a centred dialog. Each one is opened the way
/// its screen opens it, at 360 / 375 / 430 dp and 100% / 200% text, and must
/// lay out cleanly, centred, with no bottom sheet anywhere.
void main() {
  Future<AppDependencies> dependencies(AccessLevel level) async {
    final InMemorySecretStore secrets = InMemorySecretStore();
    await secrets.write(LaunchController.welcomeCompletedKey, 'true');
    final InMemorySessionStore store = InMemorySessionStore();
    if (level != AccessLevel.guest) {
      await store.write(
        StoredSession(
          resident: ResidentSession(accountId: 'acct-1', accessLevel: level),
          accessToken: 'token',
        ),
      );
    }
    final AppDependencies built = AppDependencies.build(
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
    addTearDown(built.dispose);
    await built.session.restore();
    return built;
  }

  /// The app's dependencies, strings and a router, with the text scale on
  /// the whole app so a dialog above the page is scaled too.
  Widget Function(Widget, double) routed(AppDependencies deps) {
    return (Widget page, double scale) => AppDependenciesScope(
      dependencies: deps,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppLocales.supported,
        routerConfig: GoRouter(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) =>
                  Scaffold(body: page),
            ),
          ],
        ),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('the check fails on a bottom sheet (planted)', (tester) async {
    TestFailure? caught;
    try {
      await expectCleanDialogLayouts(
        tester,
        () => dialogOpener(
          (BuildContext context) => showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext _) => const Text('A planted sheet'),
          ),
        ),
        widths: const <double>[360],
        textScales: const <double>[1],
      );
    } on TestFailure catch (failure) {
      caught = failure;
    }
    expect(caught, isNotNull, reason: 'a bottom sheet passed the check');
    expect(caught.toString(), contains('a sheet'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('AppDialog.show: a heading, scrolling content, a result', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      layoutHost(
        dialogOpener((BuildContext context) async {
          result = await AppDialog.show<String>(
            context: context,
            title: 'A panel',
            builder: (BuildContext dialog) => Column(
              children: <Widget>[
                for (var i = 0; i < 40; i++) Text('Line $i'),
                TextButton(
                  onPressed: () => Navigator.of(dialog).pop('chosen'),
                  child: const Text('Choose'),
                ),
              ],
            ),
          );
        }),
        scrollable: false,
      ),
    );
    await tester.tap(find.byKey(dialogOpenerKey));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.ancestor(
        of: find.text('A panel'),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics && (widget.properties.header ?? false),
        ),
      ),
      findsOneWidget,
    );
    // Forty lines do not fit: the content scrolls inside the dialog.
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Choose'), 200);
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(result, 'chosen');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('the gallery shows the panel dialog and the picker sheet', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(layoutHost(const ThemeGallerySection()));
    final Finder dialogButton = find.widgetWithText(FilledButton, 'Dialog');
    await tester.ensureVisible(dialogButton);
    await tester.pumpAndSettle();
    await tester.tap(dialogButton);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Centred dialog'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sheet'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('a confirmation is a centred dialog on every phone', (
    tester,
  ) async {
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(
        (BuildContext context) => ConfirmSheet.show(
          context: context,
          title: 'Give up your place at this event?',
          consequence:
              'Your place goes to the next person on the waitlist. If you '
              'change your mind you would register again, and the event may '
              'be full by then.',
          detail: 'Taytay LGU is told straight away.',
          confirmLabel: 'Give up my place',
        ),
      ),
    );
  });

  testWidgets('the Terms or Privacy Notice text is a centred dialog', (
    tester,
  ) async {
    final String markdown = <String>[
      '## Paano namin ginagamit ang iyong impormasyon',
      for (var i = 0; i < 12; i++)
        '- Isang mahabang pangungusap tungkol sa iyong datos na sapat ang '
            'haba para bumalot sa ilang linya sa malaking teksto.',
    ].join('\n\n');
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(
        (BuildContext context) => showLegalTextSheet(
          context,
          title: 'Privacy Notice',
          markdown: Future<String?>.value(markdown),
          pending: privacyNoticeNotPublishedYet,
        ),
      ),
    );
  });

  testWidgets('the legal text closes with its Close button', (tester) async {
    await tester.pumpWidget(
      layoutHost(
        dialogOpener(
          (BuildContext context) => showLegalTextSheet(
            context,
            title: 'Terms of Use',
            markdown: Future<String?>.value(''),
            pending: termsNotPublishedYet,
          ),
        ),
        scrollable: false,
      ),
    );
    await tester.tap(find.byKey(dialogOpenerKey));
    await tester.pumpAndSettle();
    expect(find.text(termsNotPublishedYet), findsOneWidget);

    await tester.tap(find.byKey(legalTextCloseKey));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('the resubmit note is a centred dialog', (tester) async {
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(showResubmitMessageDialog),
    );
  });

  testWidgets('the sign-in gate is a centred dialog', (tester) async {
    final AppDependencies deps = await dependencies(AccessLevel.guest);
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(
        (BuildContext context) => AccessGateSheet.show(
          context: context,
          decision: const AccessNeedsAuthentication(),
          intent: ResidentIntentKind.viewDigitalId,
        ),
      ),
      host: routed(deps),
    );
  });

  testWidgets('the verification gate is a centred dialog', (tester) async {
    final AppDependencies deps = await dependencies(AccessLevel.unverified);
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(
        (BuildContext context) => AccessGateSheet.show(
          context: context,
          decision: const AccessNeedsVerification(),
          intent: ResidentIntentKind.messageOffice,
        ),
      ),
      host: routed(deps),
    );
  });

  testWidgets('the not-yet-available gate is a centred dialog', (tester) async {
    final AppDependencies deps = await dependencies(AccessLevel.verified);
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(
        (BuildContext context) => AccessGateSheet.showForCapability(
          context: context,
          verdict: const CapabilityNotYetAvailable(),
          intent: ResidentIntentKind.viewDigitalId,
        ),
      ),
      host: routed(deps),
    );
  });

  testWidgets('the session-ended notice is a centred dialog', (tester) async {
    final AppDependencies deps = await dependencies(AccessLevel.guest);
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(SessionExpiredSheet.show),
      host: routed(deps),
    );
  });

  testWidgets('the correction notice for a checked field is a centred dialog', (
    tester,
  ) async {
    final AppDependencies deps = await dependencies(AccessLevel.verified);
    await expectCleanDialogLayouts(
      tester,
      () => dialogOpener(
        (BuildContext context) =>
            CanonicalFieldSheet.show(context, ResidentProfileField.fullName),
      ),
      host: routed(deps),
    );
  });

  testWidgets('sending a requested document is a centred dialog', (
    tester,
  ) async {
    final AppDependencies deps = await dependencies(AccessLevel.verified);
    await expectCleanDialogLayouts(
      tester,
      () => const RequirementsScreen(requestId: 'req-sample-1'),
      trigger: find.byWidgetPredicate(
        (Widget widget) =>
            widget is Text &&
            (widget.data == 'Send this document' ||
                widget.data == 'Replace this document'),
      ),
      host: routed(deps),
      height: 900,
    );
  });
}
