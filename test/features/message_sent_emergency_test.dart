import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/directory/data/office_catalogue.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/shared/widgets/soft_note.dart';

import '../support/layout_matrix.dart';

/// The emergency note on the Message sent page (F1, item 1).
///
/// It used to read "call the Sagip Taytay Command Center, `phone`" with the
/// messaged office's own number. `GET /hotlines` marks no line as the
/// Command Center or the primary emergency line, so the note names no number
/// and opens the Emergency hotlines page instead.
void main() {
  Future<Office> bplo() async {
    final ({List<String> chips, List<Office> offices}) catalogue =
        await OfficeCatalogue.load();
    return catalogue.offices.singleWhere(
      (Office office) => office.id == 'bplo',
    );
  }

  Widget sent(Office office, {VoidCallback? onHotlines}) => DirectoryCanvas(
    frame: DirectoryFrame.sent,
    offices: const <Office>[],
    office: office,
    onMessages: () {},
    onBack: () {},
    onHotlines: onHotlines,
  );

  testWidgets('the note names no number, not even the office that has one', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final Office office = await bplo();
    expect(office.phone, isNotEmpty, reason: 'the fixture office has a line');

    await tester.pumpWidget(
      layoutHost(sent(office, onHotlines: () {}), scrollable: false),
    );
    await tester.pump();

    final Finder note = find.byKey(messageSentEmergencyNoteKey);
    expect(note, findsOneWidget);
    // The design system's note (F-review, finding 7), with the mock-up's bold
    // title on a line of its own.
    expect(tester.widget<SoftNote>(note).tone, NoteTone.emergency);
    expect(
      find.descendant(
        of: note,
        matching: find.text(MessageSentCopy.emergencyHeading),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: note, matching: find.text(MessageSentCopy.emergency)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: note, matching: find.byKey(messageSentHotlinesKey)),
      findsOneWidget,
    );
    final String drawn = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text text) => text.data ?? text.textSpan?.toPlainText() ?? '')
        .join(' | ');
    expect(drawn, isNot(contains(office.phone)));
    expect(drawn, isNot(contains('Command Center')));
    expect(drawn, isNot(contains(RegExp(r'\d{3,}'))));
  });

  testWidgets('the button opens the hotlines and is a full tap target', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final Office office = await bplo();
    var opened = 0;

    await tester.pumpWidget(
      layoutHost(sent(office, onHotlines: () => opened++), scrollable: false),
    );
    await tester.pump();

    final Finder button = find.byKey(messageSentHotlinesKey);
    expect(button, findsOneWidget);
    expect(
      find.descendant(
        of: button,
        matching: find.text(MessageSentCopy.hotlinesButton),
      ),
      findsOneWidget,
    );
    final Size size = tester.getSize(button);
    expect(size.height, greaterThanOrEqualTo(A11y.minTapTarget));
    final SemanticsNode node = tester.getSemantics(button);
    expect(node.label, MessageSentCopy.hotlinesButton);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    await tester.ensureVisible(button);
    await tester.tap(button);
    expect(opened, 1);
  });

  testWidgets('without a way to the hotlines the note still says to call one', (
    tester,
  ) async {
    final Office office = await bplo();
    await tester.pumpWidget(layoutHost(sent(office), scrollable: false));
    await tester.pump();

    expect(find.text(MessageSentCopy.emergency), findsOneWidget);
    expect(find.byKey(messageSentHotlinesKey), findsNothing);
    expect(find.textContaining(office.phone), findsNothing);
  });

  testWidgets('the note and its button fit every phone at 200% text', (
    tester,
  ) async {
    final Office office = await bplo();
    await expectCleanLayouts(
      tester,
      () => sent(office, onHotlines: () {}),
      scrollable: false,
      height: 900,
    );
  });
}
