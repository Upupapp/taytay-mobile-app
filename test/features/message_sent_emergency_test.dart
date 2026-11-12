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

  Widget sent(
    Office office, {
    VoidCallback? onHotlines,
    EmergencyLine? commandCenter,
    bool loading = false,
    VoidCallback? onCall,
  }) => DirectoryCanvas(
    frame: DirectoryFrame.sent,
    offices: const <Office>[],
    office: office,
    onMessages: () {},
    onBack: () {},
    onHotlines: onHotlines,
    commandCenter: commandCenter,
    commandCenterLoading: loading,
    onCallCommandCenter: onCall,
  );

  const EmergencyLine line = (
    name: 'Synthetic Command Center',
    number: '0900-000-0000',
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

  group('a hotline marked command-center (D-214)', () {
    testWidgets('its name and number are in the note, with a call button', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 1100)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final Office office = await bplo();
      int called = 0;
      int opened = 0;
      await tester.pumpWidget(
        layoutHost(
          sent(
            office,
            onHotlines: () => opened++,
            commandCenter: line,
            onCall: () => called++,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();

      final Finder note = find.byKey(messageSentEmergencyNoteKey);
      expect(
        find.descendant(
          of: note,
          matching: find.text(MessageSentCopy.callLine(line)),
        ),
        findsOneWidget,
      );
      expect(find.text(MessageSentCopy.emergency), findsNothing);
      // Never the messaged office's own line.
      expect(find.textContaining(office.phone), findsNothing);
      expect(tester.widget<SoftNote>(note).tone, NoteTone.emergency);
      // The hotlines button stays beside the call.
      expect(find.byKey(messageSentHotlinesKey), findsOneWidget);

      final Finder call = find.byKey(messageSentCallKey);
      expect(call, findsOneWidget);
      // Its own button, read by its words; the number is in the sentence
      // just above it.
      final SemanticsNode node = tester.getSemantics(call);
      expect(node.label, MessageSentCopy.callButton(line));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(tester.getSize(call).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(call);
      await tester.tap(call);
      expect(called, 1);
      expect(opened, 0);
    });

    testWidgets('while the hotlines load, the note waits and names none', (
      tester,
    ) async {
      final Office office = await bplo();
      await tester.pumpWidget(
        layoutHost(
          sent(office, onHotlines: () {}, loading: true),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.text(MessageSentCopy.emergency), findsOneWidget);
      expect(find.byKey(messageSentCallKey), findsNothing);
      expect(find.bySemanticsLabel(MessageSentCopy.loading), findsOneWidget);
      expect(find.byKey(messageSentHotlinesKey), findsOneWidget);
    });

    testWidgets('none marked, or a failed read: the note names no number', (
      tester,
    ) async {
      final Office office = await bplo();
      await tester.pumpWidget(
        layoutHost(sent(office, onHotlines: () {}), scrollable: false),
      );
      await tester.pump();
      expect(find.text(MessageSentCopy.emergency), findsOneWidget);
      expect(find.byKey(messageSentCallKey), findsNothing);
      expect(find.byKey(messageSentHotlinesKey), findsOneWidget);
    });

    testWidgets('every frame fits every phone at 200% text', (tester) async {
      final Office office = await bplo();
      for (final Widget Function() build in <Widget Function()>[
        () => sent(office, onHotlines: () {}, loading: true),
        () =>
            sent(office, onHotlines: () {}, commandCenter: line, onCall: () {}),
        () => sent(
          office,
          onHotlines: () {},
          commandCenter: (
            name: 'A synthetic command and operations center with a long name',
            number: '0900-000-0000 · 0900-000-0001',
          ),
          onCall: () {},
        ),
      ]) {
        await expectCleanLayouts(tester, build, scrollable: false, height: 900);
      }
    });
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
