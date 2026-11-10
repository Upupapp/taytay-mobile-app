import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/features/onboarding/presentation/welcome_scene.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

import 'device_adaptation_test.dart' as phone;
import 'welcome_and_gates_test.dart';

/// Headless stand-in for the S9 accessibility and frame-timing evidence.
///
/// These pumps run on the test host. They are not a device frame time and
/// not a TalkBack session. Set `TAYTAY_S9_REPORT=1` to write the two reports.
void main() {
  testWidgets('welcome semantics, 48dp targets, and 200% text', (tester) async {
    await boot(tester);
    await settle(tester);

    expect(find.byKey(welcomeSkipTargetKey), findsOneWidget);
    final SemanticsNode skip = tester.getSemantics(
      find.bySemanticsLabel('Skip'),
    );
    expect(skip.label, 'Skip');
    expect(skip.flagsCollection.isButton, isTrue);
    expect(skip.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    final SemanticsNode headline = tester.getSemantics(
      find.bySemanticsLabel('Serbisyong bayan, nasa isang app.'),
    );
    expect(headline.flagsCollection.isHeader, isTrue);
    _expectTargets(tester);
    final Finder next = find.byKey(welcomeNextKey);
    final Size nextSize = tester.getSize(next);
    expect(nextSize.height, greaterThanOrEqualTo(A11y.minTapTarget));
    expect(nextSize.width, greaterThanOrEqualTo(A11y.minTapTarget));

    await tester.tap(find.byKey(welcomeNextKey));
    await tester.pumpAndSettle();
    expect(find.byType(TaytayBackButton), findsWidgets);
    for (final element in find.byType(TaytayBackButton).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, greaterThanOrEqualTo(A11y.minTapTarget));
      expect(size.height, greaterThanOrEqualTo(A11y.minTapTarget));
    }
  });

  testWidgets('welcome at 200% text still shows the title and a 48dp Skip', (
    tester,
  ) async {
    await boot(tester, textScaler: const TextScaler.linear(2));
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Serbisyong bayan, nasa isang app.'),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(welcomeSkipTargetKey)).height,
      greaterThanOrEqualTo(A11y.minTapTarget),
    );
    final RenderObject headlineBox = tester.renderObject(
      find.textContaining('Serbisyong bayan,'),
    );
    expect((headlineBox as RenderBox).size.height, greaterThan(0));
  });

  testWidgets(
    'sign-in, create-account, and services meet the tap and contrast guidelines',
    (tester) async {
      final phone.Device handset = phone.devices.firstWhere(
        (phone.Device device) => device.name == 'phone with a notch',
      );
      const screens = <String>['/sign-in', '/register', '/services'];
      for (final String location in screens) {
        await phone.boot(
          tester,
          level: AccessLevel.guest,
          device: handset,
          location: location,
        );
        expect(tester.takeException(), isNull, reason: location);
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
          reason: location,
        );
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: location,
        );
        await expectLater(
          tester,
          meetsGuideline(textContrastGuideline),
          reason: location,
        );
      }
    },
  );
}

void _expectTargets(WidgetTester tester) {
  expect(
    tester.getSize(find.byKey(welcomeSkipTargetKey)).height,
    A11y.minTapTarget,
  );
  expect(
    tester.getSize(find.byKey(welcomeSkipTargetKey)).width,
    greaterThanOrEqualTo(A11y.minTapTarget),
  );
}
