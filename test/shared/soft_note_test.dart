import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_glyphs.dart';
import 'package:taytay_resident/core/design/typography.dart';
import 'package:taytay_resident/shared/widgets/pill_button_row.dart';
import 'package:taytay_resident/shared/widgets/soft_note.dart';
import 'package:taytay_resident/shared/widgets/taytay_icon.dart';

import '../support/layout_matrix.dart';

/// F-review, finding 7 (D-203): `SoftNote` carries a heading of its own and
/// one action inside the note, so the Message sent page's emergency note is a
/// `SoftNote` instead of a one-off box.
void main() {
  const Key actionKey = Key('soft-note-action');

  Widget note({VoidCallback? onAction, NoteTone tone = NoteTone.emergency}) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.formGutter),
      child: SoftNote(
        tone: tone,
        heading: "For emergencies don't wait for a reply",
        message: 'Call an emergency hotline.',
        live: false,
        action: onAction == null
            ? null
            : PillButtonRow(
                wrap: true,
                padding: EdgeInsets.zero,
                actions: <PillAction>[
                  PillAction(
                    label: 'See emergency hotlines',
                    glyph: TaytayGlyph.phone,
                    danger: true,
                    buttonKey: actionKey,
                    onPressed: onAction,
                  ),
                ],
              ),
      ),
    );
  }

  testWidgets('the heading is a bold line of its own above the message', (
    tester,
  ) async {
    await tester.pumpWidget(layoutHost(note()));

    final Finder heading = find.text("For emergencies don't wait for a reply");
    final Finder message = find.text('Call an emergency hotline.');
    expect(heading, findsOneWidget);
    expect(message, findsOneWidget);
    expect(
      tester.getRect(heading).bottom,
      lessThanOrEqualTo(tester.getRect(message).top),
    );
    expect(
      tester.widget<Text>(heading).style?.fontWeight,
      AppTypography.strong,
    );
    expect(find.byKey(actionKey), findsNothing);
  });

  testWidgets('the action sits inside the note, under the message, and is '
      'its own button', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    var pressed = 0;
    await tester.pumpWidget(layoutHost(note(onAction: () => pressed++)));

    final Finder action = find.byKey(actionKey);
    final Rect box = tester.getRect(
      find
          .descendant(
            of: find.byType(SoftNote),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final Rect drawn = tester.getRect(action);
    expect(box.contains(drawn.topLeft), isTrue);
    expect(box.contains(drawn.bottomRight - const Offset(1, 1)), isTrue);
    expect(
      drawn.top,
      greaterThanOrEqualTo(
        tester.getRect(find.text('Call an emergency hotline.')).bottom,
      ),
    );
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(action),
      isSemantics(
        label: 'See emergency hotlines',
        isButton: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(action);
    expect(pressed, 1);
    semantics.dispose();
  });

  testWidgets('the emergency tone says so with a siren, not with colour', (
    tester,
  ) async {
    await tester.pumpWidget(layoutHost(note()));
    final TaytayIcon icon = tester.widget<TaytayIcon>(
      find.descendant(
        of: find.byType(SoftNote),
        matching: find.byType(TaytayIcon),
      ),
    );
    expect(icon.semanticLabel, 'Emergency');
  });

  testWidgets('a note with a heading and an action fits every phone', (
    tester,
  ) async {
    await expectCleanLayouts(tester, () => note(onAction: () {}));
  });
}
