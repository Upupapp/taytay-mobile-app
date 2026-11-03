import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/shared/widgets/message_field.dart';

void main() {
  testWidgets('both message fields show the label and the 170 dp box', (
    tester,
  ) async {
    const List<Key> keys = <Key>[
      Key('directory-message-field'),
      Key('verification-message-field'),
    ];
    for (final Key key in keys) {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageField(controller: controller, fieldKey: key),
          ),
        ),
      );

      final Text label = tester.widget<Text>(find.text('Message'));
      expect(label.style?.inherit, isFalse);

      final Finder box = find.ancestor(
        of: find.byKey(key),
        matching: find.byWidgetPredicate((Widget widget) {
          if (widget is! Container) return false;
          final Decoration? decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.border ==
                  Border.all(color: MessageField.border, width: 1.3);
        }),
      );
      expect(box, findsOneWidget);
      expect(tester.getSize(box).height, 170);
    }
  });
}
