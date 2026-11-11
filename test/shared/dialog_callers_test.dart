import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/features/account/presentation/account_copy.dart';
import 'package:taytay_resident/features/issuance/presentation/issuance_request_detail_screen.dart';
import 'package:taytay_resident/features/profile/domain/name_lock.dart';
import 'package:taytay_resident/shared/widgets/app_dialog.dart';

import '../support/layout_matrix.dart';

/// F-review, finding 1 (D-202): `AppDialog.confirm` and `.acknowledge` used to
/// build an `AlertDialog` that did not scroll, so a long message at 200% text
/// on a 360 dp phone was clipped without a word. Every place the app calls
/// either one is opened here with its own words, at 360 / 375 / 430 dp and
/// 100% / 200% text, and must lay out cleanly, centred, with nothing cut off.
void main() {
  /// A device name as long as a phone reports one.
  const String longDevice =
      'Samsung Galaxy A14 5G · Chrome on Android 14 · Taytay, Rizal';

  /// Each caller of [AppDialog.confirm]: where it is, title, message, the
  /// confirm label, the cancel label and whether it is destructive.
  final List<
    ({
      String where,
      String title,
      String message,
      String confirm,
      String cancel,
      bool destructive,
    })
  >
  confirms =
      <
        ({
          String where,
          String title,
          String message,
          String confirm,
          String cancel,
          bool destructive,
        })
      >[
        (
          where: 'Security: sign out another device',
          title: AccountCopy.revokeOneTitle(longDevice),
          message: AccountCopy.revokeOne,
          confirm: AccountCopy.revokeOneAction,
          cancel: 'Cancel',
          destructive: false,
        ),
        (
          where: 'Security: sign out all other devices',
          title: AccountCopy.revokeOthersTitle,
          message: AccountCopy.revokeOthers,
          confirm: AccountCopy.revokeOthersAction,
          cancel: 'Cancel',
          destructive: false,
        ),
        (
          where: 'Security: sign out of this device',
          title: AccountCopy.signOutTitle,
          message: AccountCopy.signOut,
          confirm: AccountCopy.signOutAction,
          cancel: 'Cancel',
          destructive: false,
        ),
        (
          where: 'My Account: sign out of this device',
          title: AccountCopy.signOutTitle,
          message: AccountCopy.signOut,
          confirm: AccountCopy.signOutAction,
          cancel: 'Cancel',
          destructive: false,
        ),
        (
          where: 'Account home: sign out of this device',
          title: AccountCopy.signOutTitle,
          message: AccountCopy.signOut,
          confirm: AccountCopy.signOutAction,
          cancel: 'Cancel',
          destructive: true,
        ),
        (
          where: 'Conversation: close it',
          title: AccountCopy.closeConversationTitle,
          message: AccountCopy.closeConversation,
          confirm: AccountCopy.closeConversationAction,
          cancel: 'Cancel',
          destructive: true,
        ),
        (
          where: 'Issuance request: cancel it',
          title: IssuanceCancelCopy.title,
          message: IssuanceCancelCopy.message('BRGY-CLR-2026-000123'),
          confirm: IssuanceCancelCopy.confirm,
          cancel: IssuanceCancelCopy.keep,
          destructive: true,
        ),
      ];

  /// Each caller of [AppDialog.acknowledge]: where it is, title, message.
  final List<({String where, String title, String message})> acknowledges =
      <({String where, String title, String message})>[
        (
          where: 'Edit profile: the name is empty',
          title: AccountCopy.nothingChangedTitle,
          message: NameCheckCopy.emptyName,
        ),
        (
          where: 'Edit profile: the name is too long',
          title: AccountCopy.nothingChangedTitle,
          message: NameCheckCopy.tooLong,
        ),
        (
          where: 'Edit profile: nothing was changed',
          title: AccountCopy.nothingChangedTitle,
          message: AccountCopy.nothingChanged,
        ),
        (
          where: 'Edit profile: the save timed out',
          title: AccountCopy.notConfirmedTitle,
          message: AccountCopy.notConfirmed,
        ),
        (
          where: 'Edit profile: the name locked since the screen loaded',
          title: AccountCopy.nameNotChangedTitle,
          message: AccountCopy.nameNotChanged(
            NameLock.underReview.explanation,
            otherChanges: true,
          ),
        ),
        (
          where: 'Edit profile: the save failed',
          title: AccountCopy.nothingChangedTitle,
          message: AccountCopy.nothingChanged,
        ),
        (
          where: 'Settings: language',
          title: AccountCopy.languageTitle,
          message: AccountCopy.language,
        ),
        (
          where: 'Settings: password updated',
          title: AccountCopy.passwordUpdatedTitle,
          message: AccountCopy.passwordUpdated,
        ),
      ];

  test('fourteen places open these dialogs, and each is listed here', () {
    // Seven confirmations; seven acknowledgements, one of which (an invalid
    // name) has two messages.
    expect(confirms.length + acknowledges.length - 1, 14);
  });

  for (final c in confirms) {
    testWidgets('${c.where}: fits every phone at 200% text', (tester) async {
      await expectCleanDialogLayouts(
        tester,
        () => dialogOpener(
          (BuildContext context) => AppDialog.confirm(
            context: context,
            title: c.title,
            message: c.message,
            confirmLabel: c.confirm,
            cancelLabel: c.cancel,
            destructive: c.destructive,
          ),
        ),
      );
    });
  }

  for (final a in acknowledges) {
    testWidgets('${a.where}: fits every phone at 200% text', (tester) async {
      await expectCleanDialogLayouts(
        tester,
        () => dialogOpener(
          (BuildContext context) => AppDialog.acknowledge(
            context: context,
            title: a.title,
            message: a.message,
          ),
        ),
      );
    });
  }

  testWidgets('the longest confirmation scrolls to its buttons at 360 dp and '
      '200% text, and nothing is cut off', (tester) async {
    addTearDown(tester.view.reset);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 640);
    bool? confirmed;
    await tester.pumpWidget(
      layoutHost(
        dialogOpener((BuildContext context) async {
          confirmed = await AppDialog.confirm(
            context: context,
            title: AccountCopy.revokeOneTitle(longDevice),
            message: AccountCopy.revokeOne,
            confirmLabel: AccountCopy.revokeOneAction,
          );
        }),
        textScale: 2,
        scrollable: false,
      ),
    );
    await tester.tap(find.byKey(dialogOpenerKey));
    await tester.pumpAndSettle();

    final Finder scroll = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scroll, findsOneWidget);
    // Every word of the message is laid out in full: the scroll view gives
    // it the height it needs instead of cutting it at the dialog's edge.
    final Finder message = find.text(AccountCopy.revokeOne);
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      message,
    );
    expect(
      paragraph.size.height,
      greaterThanOrEqualTo(
        paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 0.5,
      ),
    );

    final Finder confirm = find.text(AccountCopy.revokeOneAction);
    await tester.scrollUntilVisible(
      confirm,
      120,
      scrollable: find.descendant(
        of: scroll,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
