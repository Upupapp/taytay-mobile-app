import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/assets/asset_manifest.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/account/data/firebase_account_password_client.dart';
import 'package:taytay_resident/features/account/data/mock_account_password_client.dart';
import 'package:taytay_resident/features/account/domain/notice_markdown.dart';
import 'package:taytay_resident/features/account/domain/photo_credit.dart';
import 'package:taytay_resident/features/account/domain/profile_completion.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/account/presentation/change_password_form.dart';
import 'package:taytay_resident/features/notifications/domain/notification_repository.dart';
import 'package:taytay_resident/features/platform/domain/privacy_notice.dart';
import 'package:taytay_resident/features/profile/domain/profile_fields.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/verification_decision.dart';
import 'package:taytay_resident/shared/widgets/taytay_back_button.dart';

class _RecordingUser implements SignedInPasswordUser {
  _RecordingUser({this.rejectCurrent = false});

  final bool rejectCurrent;
  final List<String> calls = <String>[];

  @override
  String? get email => 'juana@example.com';

  @override
  Future<void> reauthenticate(String password) async {
    calls.add('reauthenticate');
    if (rejectCurrent) {
      throw const PasswordChangeException(
        ValidationFailure(
          fieldErrors: <String, List<String>>{
            'current_password': <String>['That password does not match.'],
          },
        ),
      );
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    calls.add('update');
  }
}

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

  test('profile completion counts the ten resident columns', () {
    expect(profileCompletionPercent(const ResidentProfileDetail()), 0);
    expect(
      profileCompletionPercent(
        const ResidentProfileDetail(
          values: <ResidentProfileField, String>{
            ResidentProfileField.fullName: 'Juana Dela Cruz',
            ResidentProfileField.birthDate: '1992-03-14',
            ResidentProfileField.sex: 'female',
            ResidentProfileField.mobileNumber: '09170000000',
            ResidentProfileField.emailAddress: 'juana@example.com',
            ResidentProfileField.barangay: 'barangay-sample',
          },
        ),
      ),
      60,
    );
    expect(
      profileCompletionPercent(
        const ResidentProfileDetail(
          values: <ResidentProfileField, String>{
            ResidentProfileField.fullName: 'Juana Dela Cruz',
            ResidentProfileField.birthDate: '1992-03-14',
            ResidentProfileField.sex: 'female',
            ResidentProfileField.mobileNumber: '09170000000',
            ResidentProfileField.emailAddress: 'juana@example.com',
            ResidentProfileField.barangay: 'barangay-sample',
            ResidentProfileField.streetAddress: '1 Sample St',
            ResidentProfileField.purokOrSitio: '1',
          },
          hasStreetLine: true,
          hasFreeAddress: true,
          hasAvatar: true,
        ),
      ),
      100,
    );
    const ResidentProfileDetail withSystemOnly = ResidentProfileDetail(
      emailVerified: true,
      closed: true,
    );
    expect(profileCompletionPercent(withSystemOnly), 0);
  });

  test('a decision instant is the Manila calendar date', () {
    expect(manilaDecisionDate(null), isNull);
    expect(manilaDecisionDate(DateTime.utc(2026, 10, 21, 16)), 'Oct 22, 2026');
    expect(manilaDecisionDate(DateTime.utc(2026, 10, 22, 20)), 'Oct 23, 2026');
  });

  test('balita and emergency write both flags and default on', () {
    expect(preferenceEnabled(const <ChannelPreference>[], 'balita'), isTrue);
    final List<ChannelPreference> written = writePreference(
      const <ChannelPreference>[
        ChannelPreference(type: 'balita', inApp: true, push: true),
      ],
      type: 'emergency',
      on: false,
    );
    final ChannelPreference emergency = written.firstWhere(
      (ChannelPreference channel) => channel.type == 'emergency',
    );
    expect(emergency.inApp, isFalse);
    expect(emergency.push, isFalse);
    final List<ChannelPreference> office = writePreference(
      written,
      type: 'message_received',
      on: false,
      pushOnly: true,
    );
    final ChannelPreference replies = office.firstWhere(
      (ChannelPreference channel) => channel.type == 'message_received',
    );
    expect(replies.inApp, isTrue);
    expect(replies.push, isFalse);
  });

  test('placeholder and a missing notice keep the bundled draft', () {
    expect(PrivacyNotice.missing.usesBundledDraft, isTrue);
    expect(
      const PrivacyNotice(
        version: 'placeholder',
        bodyMarkdown: 'Do not show this.',
      ).usesBundledDraft,
      isTrue,
    );
    expect(
      const PrivacyNotice(
        version: '2026-10',
        bodyMarkdown: '## What we collect\n\nName.',
      ).usesBundledDraft,
      isFalse,
    );
  });

  test('notice markdown keeps headings, bold, and the link label', () {
    final List<NoticeLine> lines = parseNoticeMarkdown(
      '## What we collect\n\n**Name** and address.\n\n- A [selfie](https://example.test)\n',
    );
    expect(lines, hasLength(3));
    expect(lines[0].heading, isTrue);
    expect(lines[0].plain, 'What we collect');
    expect(lines[1].runs[0].strong, isTrue);
    expect(lines[1].plain, 'Name and address.');
    expect(lines[2].bullet, isTrue);
    expect(lines[2].plain, 'A selfie');
    expect(lines[2].plain, isNot(contains('example.test')));
  });

  test('a dev password change stays on the mock', () async {
    final MockAccountPasswordClient client = MockAccountPasswordClient();
    final Result<void> wrong = await client.changePassword(
      currentPassword: 'wrong-password',
      newPassword: 'Newpass1',
    );
    expect(wrong, isA<Err<void>>());
    expect(
      (wrong as Err<void>).failure,
      isA<ValidationFailure>().having(
        (ValidationFailure failure) =>
            failure.firstErrorFor('current_password'),
        'current',
        'That password does not match.',
      ),
    );

    final Result<void> updated = await client.changePassword(
      currentPassword: 'password-sample',
      newPassword: 'Newpass1',
    );
    expect(updated, isA<Ok<void>>());
    expect(client.currentPassword, 'Newpass1');

    final Result<void> again = await client.changePassword(
      currentPassword: 'password-sample',
      newPassword: 'Newpass2',
    );
    expect(again, isA<Err<void>>());
  });

  test('Firebase reauthenticates before it updates the password', () async {
    final _RecordingUser user = _RecordingUser();
    final FirebaseAccountPasswordClient client = FirebaseAccountPasswordClient(
      session: user,
    );
    final Result<void> result = await client.changePassword(
      currentPassword: 'password-sample',
      newPassword: 'Newpass1',
    );
    expect(result, isA<Ok<void>>());
    expect(user.calls, <String>['reauthenticate', 'update']);
  });

  test('a rejected current password does not call updatePassword', () async {
    final _RecordingUser user = _RecordingUser(rejectCurrent: true);
    final Result<void> result =
        await FirebaseAccountPasswordClient(session: user).changePassword(
          currentPassword: 'wrong-password',
          newPassword: 'Newpass1',
        );
    expect(result, isA<Err<void>>());
    expect(user.calls, <String>['reauthenticate']);
  });

  test(
    'the Firebase client is the only account file that talks to Firebase',
    () {
      final String source = File(
        'lib/features/account/data/firebase_account_password_client.dart',
      ).readAsStringSync();
      expect(source, contains('reauthenticateWithCredential'));
      expect(source, contains('updatePassword'));
      final List<String> others = <String>[];
      for (final File file in Directory(
        'lib/features/account',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        if (file.path.endsWith('firebase_account_password_client.dart')) {
          continue;
        }
        if (file.readAsStringSync().contains('package:firebase_auth')) {
          others.add(file.path);
        }
      }
      expect(others, isEmpty);
    },
  );

  test(
    'live account screens hide phone verification, email, and data export',
    () {
      final String source = File(
        'lib/features/account/presentation/account_pages.dart',
      ).readAsStringSync();
      final String edit = source
          .split('class EditProfileScreen')
          .last
          .split('class AccountSettingsScreen')
          .first;
      final String settings = source
          .split('class AccountSettingsScreen')
          .last
          .split('class PrivacyNoticeScreen')
          .first;
      final String notice = source
          .split('class PrivacyNoticeScreen')
          .last
          .split('class PhotoCreditsScreen')
          .first;
      expect(edit, isNot(contains('verified: true')));
      expect(edit, contains('verified: _emailVerified'));
      expect(settings, isNot(contains('Push and email')));
      expect(settings, contains('Push notifications'));
      expect(settings, contains('showDataExport: false'));
      expect(settings, isNot(contains('Request a copy of my data')));
      expect(notice, contains('showDataExport: false'));
      expect(notice, isNot(contains('Request a copy of my data')));
    },
  );

  test('the privacy notice reads the public config and nothing personal', () {
    final String source = File(
      'lib/features/account/presentation/account_pages.dart',
    ).readAsStringSync();
    final String notice = source.split('class PrivacyNoticeScreen').last;
    final String body = notice.split('class PhotoCreditsScreen').first;
    expect(body, contains('loadBootstrap'));
    expect(body, isNot(contains('session')));
    expect(body, isNot(contains('ResidentProfile')));
    expect(body, isNot(contains('loadOwn')));
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

  testWidgets('a published notice replaces the bundled draft', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccountCanvas(
            frame: AccountFrame.privacy,
            title: 'Privacy Notice',
            showBack: true,
            showDataExport: false,
            noticeMarkdown:
                '## What we collect\n\n**Name** and address.\n\n- A selfie',
          ),
        ),
      ),
    );
    expect(find.textContaining('DRAFT'), findsNothing);
    expect(find.textContaining('What we collect'), findsOneWidget);
    expect(find.textContaining('Name and address.'), findsOneWidget);
    expect(find.textContaining('A selfie'), findsOneWidget);
  });

  testWidgets('the password form reports a mismatch and a mock success', (
    tester,
  ) async {
    final MockAccountPasswordClient client = MockAccountPasswordClient();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChangePasswordForm(client: client)),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'password-sample');
    await tester.enterText(find.byType(TextField).at(1), 'Newpass1');
    await tester.enterText(find.byType(TextField).at(2), 'Otherpass1');
    await tester.tap(find.text('Save password'));
    await tester.pump();
    expect(find.text('Those passwords do not match.'), findsOneWidget);
    expect(client.currentPassword, 'password-sample');

    await tester.enterText(find.byType(TextField).at(2), 'Newpass1');
    await tester.tap(find.text('Save password'));
    await tester.pump();
    expect(client.currentPassword, 'Newpass1');
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
