import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/assets/asset_manifest.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/features/account/domain/photo_credit.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

void main() {
  test('photo credits name every bundled photograph', () {
    final Set<String> photographs = AppAssets.all
        .where((AssetEntry entry) => entry.kind == AssetKind.photograph)
        .map((AssetEntry entry) => entry.key)
        .toSet();
    final Set<String> credited = PhotoCredits.all
        .map((PhotoCredit credit) => credit.assetKey)
        .toSet();

    expect(credited, photographs);
    expect(
      PhotoCredits.all.length,
      credited.length,
      reason: 'a photograph is credited twice',
    );
  });

  test('the privacy notice reads nothing about a person', () {
    final String source = File(
      'lib/features/account/presentation/account_pages.dart',
    ).readAsStringSync();
    final String notice = source.split('class PrivacyNoticeScreen').last;
    final String body = notice.split('class PhotoCreditsScreen').first;
    expect(body, isNot(contains('Repository')));
    expect(body, isNot(contains('session')));
    expect(body, isNot(contains('AppDependencies')));
  });

  test('account sources do not send an authority field', () {
    final Directory root = Directory('lib/features/account');
    final List<String> offenders = <String>[];
    for (final File file in root.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final String source = file.readAsStringSync();
      for (final String needle in <String>[
        'is_admin',
        'role:',
        "'role'",
        'verification_status',
      ]) {
        if (source.contains(needle)) offenders.add('${file.path} $needle');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  testWidgets('the back control is 48 dp and a home row is at least that', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 754,
            child: AccountCanvas(
              frame: AccountFrame.inbox,
              title: 'Messages',
              showBack: true,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(TaytayBackButton)).shortestSide,
      A11y.minTapTarget,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 754,
            child: AccountCanvas(frame: AccountFrame.home),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(
            find.byWidgetPredicate(
              (Widget widget) =>
                  widget is Semantics && widget.properties.label == 'Sign out',
            ),
          )
          .height,
      greaterThanOrEqualTo(A11y.minTapTarget),
    );
  });
}
