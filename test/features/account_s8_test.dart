import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/api/paginated.dart';
import 'package:taytay_resident/core/assets/asset_manifest.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/data/firebase_account_password_client.dart';
import 'package:taytay_resident/features/account/data/mock_account_password_client.dart';
import 'package:taytay_resident/features/account/domain/notice_markdown.dart';
import 'package:taytay_resident/features/account/domain/photo_credit.dart';
import 'package:taytay_resident/features/account/domain/profile_completion.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/account/presentation/account_home_screen.dart';
import 'package:taytay_resident/features/account/presentation/account_pages.dart';
import 'package:taytay_resident/features/account/presentation/change_password_form.dart';
import 'package:taytay_resident/features/messaging/domain/office_messaging_repository.dart';
import 'package:taytay_resident/features/platform/domain/app_bootstrap.dart';
import 'package:taytay_resident/features/platform/domain/platform_repository.dart';
import 'package:taytay_resident/features/platform/domain/privacy_notice.dart';
import 'package:taytay_resident/features/profile/domain/profile_fields.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_detail.dart';
import 'package:taytay_resident/features/profile/domain/resident_profile_repository.dart';
import 'package:taytay_resident/features/profile/domain/verification_decision.dart';
import 'package:taytay_resident/features/registration/domain/registration_domain.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/barangay_picker.dart';
import 'package:taytay_resident/shared/widgets/loading_skeleton.dart';
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

  test('the account settings own no switch and link to the one set', () {
    final String settings =
        File('lib/features/account/presentation/account_pages.dart')
            .readAsStringSync()
            .split('class AccountSettingsScreen')
            .last
            .split('class PrivacyNoticeScreen')
            .first;
    // D-224: the notification settings are the one place a switch lives.
    // Nothing sends a Balita or an emergency notice, and an emergency switch
    // contradicted "always sent".
    for (final String gone in <String>[
      'AccountToggle',
      'toggles:',
      "'balita'",
      "'emergency'",
      'Balita & advisories',
      'Emergency alerts',
      'updatePreferences',
      'loadPreferences',
    ]) {
      expect(settings, isNot(contains(gone)), reason: gone);
    }
    expect(settings, contains('onNotifications:'));
    expect(settings, contains('AppRoute.notificationSettings'));
  });

  testWidgets('the settings page opens the notification settings', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountCanvas(
            frame: AccountFrame.settings,
            title: 'Settings & privacy',
            showBack: true,
            showBell: false,
            onNotifications: () => opened++,
          ),
        ),
      ),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    await tester.tap(find.text('Notification settings'));
    await tester.pump();
    expect(opened, 1);
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
      expect(settings, isNot(contains('Push notifications')));
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

  test('people photographs use the design titles and the Replace mark', () {
    final Map<String, PhotoCredit> credits = <String, PhotoCredit>{
      for (final PhotoCredit credit in PhotoCredits.all)
        credit.assetKey: credit,
    };
    expect(credits['mswdo_relief']!.replace, isTrue);
    expect(credits['rescuers']!.replace, isTrue);
    expect(credits['rescuers']!.licence, 'Public domain (PH gov)');
    expect(credits['skills_training']!.title, 'TESDA skills training');
    expect(credits['skills_training']!.replace, isTrue);
    expect(credits['skills_training']!.licence, 'Public domain (PH gov)');
    expect(credits['sk_council']!.title, 'Sangguniang Kabataan council');
    expect(credits['sk_council']!.offices, <String>['TYDO']);
    expect(credits['sk_council']!.replace, isTrue);
    expect(credits['sk_court']!.title, 'SK basketball court');
    expect(credits['vaccination']!.title, 'Vaccination, Camarines Sur');
    expect(credits['vaccination']!.replace, isTrue);
    expect(credits['vaccination']!.licence, 'Public domain (PH gov)');
    expect(credits['rescue_vehicle']!.title, 'Rescue vehicle, Bula');
    expect(credits['health_centre']!.title, 'Barangay health center, Bula');
  });

  test('a credit row keeps the byline off the title', () {
    final String source = File(
      'lib/features/account/presentation/account_canvas.dart',
    ).readAsStringSync();
    final String row = source
        .split('class _CreditRow')
        .last
        .split('class _PrivacyBody')
        .first;
    expect(row, contains('credit.title'));
    expect(row, contains('credit.byline'));
    expect(row, isNot(contains('Positioned')));
    expect(row, isNot(contains('Stack')));
  });

  testWidgets('a production notice does not paint the bundled draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccountCanvas(
            frame: AccountFrame.privacy,
            title: 'Privacy Notice',
            showBack: true,
            showBundledDraft: false,
            showDataExport: false,
          ),
        ),
      ),
    );
    expect(find.textContaining('DRAFT'), findsNothing);
    expect(find.textContaining('SAMPLE'), findsNothing);
    expect(find.textContaining('when Taytay LGU publishes it'), findsOneWidget);
  });

  testWidgets('a failed inbox offers Retry and not an empty thread list', (
    tester,
  ) async {
    final _FailingThreads threads = _FailingThreads();
    final AppDependencies dependencies = await _accountDependencies(
      messaging: threads,
    );
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: const MaterialApp(home: MessagesInboxScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No messages yet'), findsNothing);
    expect(threads.calls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(threads.calls, 2);
    expect(find.text('No messages yet'), findsNothing);
  });

  testWidgets('Retry on the inbox shows the skeleton and reads once (D-221)', (
    tester,
  ) async {
    final _FailingThreads threads = _FailingThreads();
    final AppDependencies dependencies = await _accountDependencies(
      messaging: threads,
    );
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: const MaterialApp(home: MessagesInboxScreen()),
      ),
    );
    await tester.pump();
    expect(threads.calls, 1);

    threads.gate = Completer<void>();
    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Retry'), warnIfMissed: false);
    await tester.pump();
    expect(threads.calls, 2, reason: 'a second tap sends nothing');
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(LoadingSkeleton), findsOneWidget);

    threads.gate?.complete();
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a server failure on the inbox is not called unreachable '
      '(D-221)', (tester) async {
    final _FailingThreads threads = _FailingThreads(
      failure: const ServerFailure(),
    );
    final AppDependencies dependencies = await _accountDependencies(
      messaging: threads,
    );
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: const MaterialApp(home: MessagesInboxScreen()),
      ),
    );
    await tester.pump();
    expect(find.text(const ServerFailure().residentMessage), findsOneWidget);
    expect(find.textContaining('could not be reached'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(threads.calls, 2);
  });

  testWidgets('a privacy notice that failed to load says so with Try again, '
      'never "when published" (D-221)', (tester) async {
    final _ScriptedBootstrap platform =
        _ScriptedBootstrap(<Result<AppBootstrap>>[
          const Err<AppBootstrap>(ServerFailure()),
          const Err<AppBootstrap>(NetworkFailure()),
        ]);
    final AppDependencies dependencies = await _accountDependencies(
      config: AppConfig.from(
        rawEnvironment: 'prod',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
      ),
      platform: platform,
    );
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: const MaterialApp(home: PrivacyNoticeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text(const ServerFailure().residentMessage), findsOneWidget);
    expect(find.textContaining('when Taytay LGU publishes it'), findsNothing);
    expect(find.textContaining('DRAFT'), findsNothing);

    platform.gate = Completer<void>();
    await tester.tap(find.text('Try again'));
    await tester.tap(find.text('Try again'), warnIfMissed: false);
    await tester.pump();
    expect(platform.reads, 2, reason: 'a second tap sends nothing');
    expect(find.bySemanticsLabel('Loading the privacy notice'), findsOneWidget);
    platform.gate?.complete();
    await tester.pumpAndSettle();
    expect(find.text(const NetworkFailure().residentMessage), findsOneWidget);
    expect(find.textContaining('when Taytay LGU publishes it'), findsNothing);
  });

  // `GET /me` gives `barangay_id`; My Account printed the UUID (D-228).
  group('the barangay is named, never its id (D-228)', () {
    const String sanJuanId = '00000000-0000-4000-8000-0000000000a1';
    const List<Barangay> listed = <Barangay>[
      Barangay(id: sanJuanId, name: 'San Juan'),
      Barangay(id: '00000000-0000-4000-8000-0000000000d1', name: 'Dolores'),
    ];

    test('an id, a name, or nothing the list knows', () {
      expect(barangayFor(sanJuanId, listed)?.name, 'San Juan');
      expect(barangayFor('dolores', listed)?.name, 'Dolores');
      expect(barangayFor('00000000-0000-4000-8000-00000000ffff', listed), null);
      expect(barangayFor('', listed), null);
      expect(barangayFor(null, listed), null);
    });

    Future<void> pumpVerified(
      WidgetTester tester,
      Widget screen, {
      required List<Barangay> barangays,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final AppDependencies dependencies = await _accountDependencies(
        profile: _RecordingProfile(
          detail: const ResidentProfileDetail(
            verificationTier: 'verified',
            values: <ResidentProfileField, String>{
              ResidentProfileField.fullName: 'Juana Dela Cruz',
              ResidentProfileField.barangay: sanJuanId,
            },
          ),
        ),
        barangays: barangays,
      );
      addTearDown(dependencies.dispose);
      await dependencies.session.signIn(
        resident: const ResidentSession(
          accountId: 'acct-sample',
          accessLevel: AccessLevel.verified,
        ),
        accessToken: 'token',
      );
      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: dependencies,
          child: MaterialApp(
            localizationsDelegates: AppStrings.localizationsDelegates,
            supportedLocales: AppStrings.supportedLocales,
            home: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('My Account says the barangay by name', (tester) async {
      await pumpVerified(tester, const AccountHomeScreen(), barangays: listed);
      expect(find.text('Brgy. San Juan, Taytay, Rizal'), findsOneWidget);
      expect(find.textContaining(sanJuanId), findsNothing);
    });

    testWidgets('an id the list cannot name says the town alone', (
      tester,
    ) async {
      await pumpVerified(
        tester,
        const AccountHomeScreen(),
        barangays: const <Barangay>[],
      );
      expect(find.text('Taytay, Rizal'), findsOneWidget);
      expect(find.textContaining(sanJuanId), findsNothing);
    });

    testWidgets('Edit profile shows the barangay by name', (tester) async {
      await pumpVerified(tester, const EditProfileScreen(), barangays: listed);
      expect(find.text('San Juan'), findsOneWidget);
      expect(find.textContaining(sanJuanId), findsNothing);
    });
  });

  test('the design specimen still paints Display name', () {
    expect(
      AccountSpecimen.fields.map((AccountField field) => field.label),
      contains('Display name'),
    );
  });

  testWidgets(
    'Save sends only changed profile fields and never the legal name',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Future<_RecordingProfile> open(
        WidgetTester tester, {
        required String mobile,
        required String email,
      }) async {
        final _RecordingProfile profile = _RecordingProfile(
          detail: ResidentProfileDetail(
            values: <ResidentProfileField, String>{
              ResidentProfileField.fullName: 'Juana Dela Cruz',
              ResidentProfileField.mobileNumber: mobile,
              ResidentProfileField.emailAddress: email,
              ResidentProfileField.barangay: 'San Juan',
            },
            emailVerified: true,
          ),
        );
        final AppDependencies dependencies = await _accountDependencies(
          profile: profile,
          barangays: const <Barangay>[
            Barangay(id: 'brgy-san-juan', name: 'San Juan'),
            Barangay(id: 'brgy-dolores', name: 'Dolores'),
          ],
        );
        addTearDown(dependencies.dispose);
        final GoRouter router = GoRouter(
          initialLocation: '/edit',
          routes: <RouteBase>[
            GoRoute(
              path: '/edit',
              builder: (BuildContext context, GoRouterState state) {
                return const EditProfileScreen();
              },
            ),
            GoRoute(
              path: '/profile',
              name: AppRoute.profile.routeName,
              builder: (BuildContext context, GoRouterState state) {
                return const Scaffold(body: Text('saved'));
              },
            ),
            GoRoute(
              path: '/profile/record',
              name: AppRoute.profileRecord.routeName,
              builder: (BuildContext context, GoRouterState state) {
                return const SizedBox.shrink();
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          AppDependenciesScope(
            dependencies: dependencies,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump();
        expect(find.text('Display name'), findsNothing);
        return profile;
      }

      final Finder save = find.byWidgetPredicate(
        (Widget widget) => widget is Text && widget.data == 'Save changes',
      );

      final _RecordingProfile unchanged = await open(
        tester,
        mobile: '09170000000',
        email: 'juana@example.com',
      );
      await tester.tap(save);
      await tester.pump();
      await tester.pump();
      expect(unchanged.changes, isEmpty);
      expect(find.text('Nothing was changed'), findsOneWidget);

      final _RecordingProfile mobileOnly = await open(
        tester,
        mobile: '09170000000',
        email: 'juana@example.com',
      );
      await tester.enterText(find.byType(TextField).at(0), '09171111111');
      await tester.tap(save);
      await tester.pump();
      await tester.pump();
      expect(mobileOnly.changes, hasLength(1));
      expect(mobileOnly.changes.single.keys, <String>['mobile']);
      expect(mobileOnly.changes.single['mobile'], '09171111111');
      expect(mobileOnly.changes.single.containsKey('name'), isFalse);

      final _RecordingProfile emailOnly = await open(
        tester,
        mobile: '09170000000',
        email: 'juana@example.com',
      );
      await tester.enterText(find.byType(TextField).at(1), 'ana@example.com');
      await tester.tap(save);
      await tester.pump();
      await tester.pump();
      expect(emailOnly.changes, hasLength(1));
      expect(emailOnly.changes.single.keys, <String>['email']);
      expect(emailOnly.changes.single['email'], 'ana@example.com');
      expect(emailOnly.changes.single.containsKey('name'), isFalse);

      final _RecordingProfile barangayOnly = await open(
        tester,
        mobile: '09170000000',
        email: 'juana@example.com',
      );
      // The picker is the shared sheet now; it reads its list before drawing
      // the rows (F-review, finding 2).
      await tester.tap(find.text('San Juan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dolores'));
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump();
      await tester.pump();
      expect(barangayOnly.changes, hasLength(1));
      expect(barangayOnly.changes.single.keys, <String>['barangay_id']);
      expect(barangayOnly.changes.single['barangay_id'], 'brgy-dolores');
      expect(barangayOnly.changes.single.containsKey('name'), isFalse);
    },
  );

  testWidgets('the profile barangay picker is the sign-up picker sheet, '
      'with rows at least 48 dp (F-review, finding 2)', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _RecordingProfile profile = _RecordingProfile(
      detail: const ResidentProfileDetail(
        values: <ResidentProfileField, String>{
          ResidentProfileField.fullName: 'Juana Dela Cruz',
          ResidentProfileField.mobileNumber: '09170000000',
          ResidentProfileField.emailAddress: 'juana@example.com',
          ResidentProfileField.barangay: 'San Juan',
        },
        emailVerified: true,
      ),
    );
    const List<Barangay> barangays = <Barangay>[
      Barangay(id: 'brgy-san-juan', name: 'San Juan'),
      Barangay(id: 'brgy-dolores', name: 'Dolores'),
      Barangay(id: 'brgy-muzon', name: 'Muzon'),
    ];
    final AppDependencies dependencies = await _accountDependencies(
      profile: profile,
      barangays: barangays,
    );
    addTearDown(dependencies.dispose);
    final GoRouter router = GoRouter(
      initialLocation: '/edit',
      routes: <RouteBase>[
        GoRoute(
          path: '/edit',
          builder: (BuildContext context, GoRouterState state) =>
              const EditProfileScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: dependencies,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('San Juan'));
    await tester.pumpAndSettle();

    // A picker: the shared sheet, not a hand-built dialog.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(BarangayPicker), findsOneWidget);
    expect(find.byType(SimpleDialog), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(find.text(BarangayPicker.title), findsOneWidget);
    for (final Barangay barangay in barangays) {
      final Finder row = find.byKey(Key('barangay-${barangay.id}'));
      expect(row, findsOneWidget, reason: barangay.name);
      expect(
        tester.getSize(row).height,
        greaterThanOrEqualTo(A11y.minTapTarget),
        reason: barangay.name,
      );
      expect(
        tester.getSemantics(row),
        isSemantics(
          label: barangay.name,
          isButton: true,
          hasTapAction: true,
          isSelected: barangay.id == 'brgy-san-juan' ? true : null,
        ),
        reason: barangay.name,
      );
    }

    await tester.tap(find.byKey(const Key('barangay-brgy-muzon')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Muzon'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the inbox sample line is only on when mock data is', (
    tester,
  ) async {
    final AppDependencies live = await _accountDependencies(
      messaging: _OneThread(),
    );
    addTearDown(live.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: live,
        child: const MaterialApp(home: MessagesInboxScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('MSWDO'), findsOneWidget);
    expect(find.textContaining('messages for illustration'), findsNothing);
    expect(find.text('SAMPLE'), findsNothing);

    final AppDependencies mock = await _accountDependencies(
      messaging: _OneThread(),
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
        rawDataMode: 'mock',
      ),
    );
    addTearDown(mock.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: mock,
        child: const MaterialApp(home: MessagesInboxScreen()),
      ),
    );
    await tester.pump();
    expect(find.textContaining('messages for illustration'), findsOneWidget);
    expect(find.text('SAMPLE'), findsOneWidget);
  });

  testWidgets('the thread sample line is only on when mock data is', (
    tester,
  ) async {
    final AppDependencies live = await _accountDependencies(
      messaging: _OneThread(),
    );
    addTearDown(live.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: live,
        child: const MaterialApp(
          home: AccountThreadScreen(threadId: 'thread-1'),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('synthetic'), findsOneWidget);
    expect(find.textContaining('conversation for illustration'), findsNothing);
    expect(find.text('SAMPLE'), findsNothing);

    final AppDependencies mock = await _accountDependencies(
      messaging: _OneThread(),
      config: AppConfig.from(
        rawEnvironment: 'dev',
        rawApiBaseUrl: 'https://example.test/api/v1',
        isReleaseBuild: false,
        rawDataMode: 'mock',
      ),
    );
    addTearDown(mock.dispose);
    await tester.pumpWidget(
      AppDependenciesScope(
        dependencies: mock,
        child: const MaterialApp(
          home: AccountThreadScreen(threadId: 'thread-1'),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.textContaining('conversation for illustration'),
      findsOneWidget,
    );
    expect(find.text('SAMPLE'), findsOneWidget);
  });

  testWidgets('the privacy screen shows the draft only outside production', (
    tester,
  ) async {
    Future<void> pumpNotice({
      required String environment,
      required PrivacyNotice notice,
    }) async {
      final AppDependencies dependencies = await _accountDependencies(
        config: AppConfig.from(
          rawEnvironment: environment,
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
        ),
        platform: _FixedBootstrap(
          AppBootstrap(
            service: '',
            apiVersion: '',
            timezone: 'Asia/Manila',
            channel: 'citizen-mobile',
            defaultPageSize: 25,
            minimumVersion: '',
            features: FeatureFlags.none,
            support: SupportContact.none,
            privacyNotice: notice,
          ),
        ),
      );
      addTearDown(dependencies.dispose);
      await tester.pumpWidget(
        AppDependenciesScope(
          dependencies: dependencies,
          child: MaterialApp(
            home: PrivacyNoticeScreen(
              key: ValueKey<String>('$environment-${notice.version}'),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpNotice(
      environment: 'prod',
      notice: const PrivacyNotice(version: 'placeholder'),
    );
    expect(find.textContaining('DRAFT'), findsNothing);
    expect(find.textContaining('SAMPLE'), findsNothing);
    expect(find.textContaining('when Taytay LGU publishes it'), findsOneWidget);

    await pumpNotice(
      environment: 'dev',
      notice: const PrivacyNotice(version: 'placeholder'),
    );
    expect(find.textContaining('DRAFT'), findsOneWidget);
    expect(find.text('SAMPLE'), findsOneWidget);

    await pumpNotice(
      environment: 'prod',
      notice: const PrivacyNotice(
        version: '2026-10',
        bodyMarkdown: '## What we collect\n\nName and address.',
      ),
    );
    expect(find.textContaining('DRAFT'), findsNothing);
    expect(find.textContaining('SAMPLE'), findsNothing);
    expect(find.textContaining('What we collect'), findsOneWidget);
    expect(find.textContaining('Name and address.'), findsOneWidget);
  });
}

class _FailingThreads implements OfficeMessagingRepository {
  _FailingThreads({this.failure = const NetworkFailure()});

  final AppFailure failure;
  int calls = 0;

  /// Holds the read open while set, to see what the screen shows meanwhile.
  Completer<void>? gate;

  @override
  Future<Result<Paginated<OfficeThread>>> listThreads({
    int page = 1,
    int? perPage,
    String? cursor,
  }) async {
    calls++;
    final Completer<void>? waiting = gate;
    if (waiting != null) await waiting.future;
    return Err<Paginated<OfficeThread>>(failure);
  }

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) async =>
      const Err<OfficeThread>(NetworkFailure());

  @override
  Future<Result<Paginated<OfficeMessage>>> listMessages(
    String threadId, {
    int page = 1,
    int? perPage,
    String? cursor,
  }) async => const Err<Paginated<OfficeMessage>>(NetworkFailure());

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async => const Err<OfficeMessage>(NetworkFailure());

  @override
  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async => const Err<OfficeMessage>(NetworkFailure());

  @override
  Future<Result<void>> closeThread(String threadId) async =>
      const Err<void>(NetworkFailure());

  @override
  Future<Result<void>> markThreadRead(String threadId) async =>
      const Err<void>(NetworkFailure());
}

class _RecordingProfile implements ResidentProfileRepository {
  _RecordingProfile({required this.detail});

  final ResidentProfileDetail detail;
  final List<Map<String, Object?>> changes = <Map<String, Object?>>[];
  final List<String> idempotencyKeys = <String>[];

  @override
  Future<Result<ResidentProfileDetail>> loadOwnDetail() async =>
      Ok<ResidentProfileDetail>(detail);

  @override
  Future<Result<ResidentProfileSummary>> loadOwnSummary() async =>
      const Err<ResidentProfileSummary>(NetworkFailure());

  @override
  Future<Result<void>> updateContactDetails({
    required ContactDetailsUpdate update,
    required String idempotencyKey,
  }) async => const Err<void>(NetworkFailure());

  @override
  Future<Result<void>> submitOwnUpdate({
    required Map<String, Object?> changes,
    required String idempotencyKey,
  }) async {
    this.changes.add(changes);
    idempotencyKeys.add(idempotencyKey);
    return const Ok<void>(null);
  }
}

class _Barangays implements BarangayDirectory {
  const _Barangays(this.barangays);

  final List<Barangay> barangays;

  @override
  Future<Result<List<Barangay>>> listBarangays() async =>
      Ok<List<Barangay>>(barangays);
}

class _OneThread implements OfficeMessagingRepository {
  OfficeThread get _thread => OfficeThread(
    id: 'thread-1',
    officeId: 'office-1',
    officeName: 'MSWDO',
    topic: 'Relief',
    preview: 'A synthetic reply.',
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  @override
  Future<Result<Paginated<OfficeThread>>> listThreads({
    int page = 1,
    int? perPage,
    String? cursor,
  }) async => Ok<Paginated<OfficeThread>>(
    Paginated<OfficeThread>.single(<OfficeThread>[_thread]),
  );

  @override
  Future<Result<OfficeThread>> loadThread(String threadId) async =>
      Ok<OfficeThread>(_thread);

  @override
  Future<Result<Paginated<OfficeMessage>>> listMessages(
    String threadId, {
    int page = 1,
    int? perPage,
    String? cursor,
  }) async => Ok<Paginated<OfficeMessage>>(
    Paginated<OfficeMessage>.single(<OfficeMessage>[
      OfficeMessage(
        id: 'message-1',
        threadId: threadId,
        body: 'A synthetic message.',
        sentAt: DateTime.utc(2026, 10, 1),
        fromResident: false,
      ),
    ]),
  );

  @override
  Future<Result<OfficeMessage>> send({
    required String officeId,
    required String topic,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async => const Err<OfficeMessage>(NetworkFailure());

  @override
  Future<Result<OfficeMessage>> reply({
    required String threadId,
    required String body,
    required String idempotencyKey,
    String? mediaId,
    OutgoingFile? file,
  }) async => const Err<OfficeMessage>(NetworkFailure());

  @override
  Future<Result<void>> closeThread(String threadId) async =>
      const Err<void>(NetworkFailure());

  @override
  Future<Result<void>> markThreadRead(String threadId) async =>
      const Err<void>(NetworkFailure());
}

class _FixedBootstrap implements PlatformRepository {
  const _FixedBootstrap(this.bootstrap);

  final AppBootstrap bootstrap;

  @override
  Future<Result<ServiceHealth>> checkHealth() async => const Ok<ServiceHealth>(
    ServiceHealth(service: 'taytay', status: 'ok', apiVersion: '1'),
  );

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async =>
      Ok<AppBootstrap>(bootstrap);
}

/// Answers each `loadBootstrap` from a script, in order, held open while
/// [gate] is set.
class _ScriptedBootstrap implements PlatformRepository {
  _ScriptedBootstrap(this.answers);

  final List<Result<AppBootstrap>> answers;
  Completer<void>? gate;
  int reads = 0;

  @override
  Future<Result<ServiceHealth>> checkHealth() async => const Ok<ServiceHealth>(
    ServiceHealth(service: 'taytay', status: 'ok', apiVersion: '1'),
  );

  @override
  Future<Result<AppBootstrap>> loadBootstrap() async {
    reads++;
    final Completer<void>? waiting = gate;
    if (waiting != null) await waiting.future;
    return answers.removeAt(0);
  }
}

Future<AppDependencies> _accountDependencies({
  OfficeMessagingRepository? messaging,
  ResidentProfileRepository? profile,
  List<Barangay> barangays = const <Barangay>[],
  AppConfig? config,
  PlatformRepository? platform,
}) async {
  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final AppDependencies base = AppDependencies.build(
    config:
        config ??
        AppConfig.from(
          rawEnvironment: 'dev',
          rawApiBaseUrl: 'https://example.test/api/v1',
          isReleaseBuild: false,
        ),
    secrets: secrets,
    sessionStore: InMemorySessionStore(),
    localAuthenticator: const UnavailableLocalAuthenticator(),
  );
  return AppDependencies(
    config: base.config,
    session: base.session,
    launch: base.launch,
    intents: base.intents,
    appLock: base.appLock,
    apiClient: base.apiClient,
    cache: base.cache,
    network: base.network,
    telemetry: base.telemetry,
    authRepository: base.authRepository,
    deviceSessionRepository: base.deviceSessionRepository,
    platformRepository: platform ?? base.platformRepository,
    serviceCatalogRepository: base.serviceCatalogRepository,
    programRepository: base.programRepository,
    announcementRepository: base.announcementRepository,
    eventRepository: base.eventRepository,
    residentProfileRepository: profile ?? base.residentProfileRepository,
    householdRepository: base.householdRepository,
    credentialRepository: base.credentialRepository,
    verificationRepository: base.verificationRepository,
    documentPicker: base.documentPicker,
    shareService: base.shareService,
    externalLinks: base.externalLinks,
    accountControlsRepository: base.accountControlsRepository,
    notificationRepository: base.notificationRepository,
    registrationRepository: base.registrationRepository,
    barangayDirectory: _Barangays(barangays),
    platform: base.platform,
    officeMessaging: messaging,
    onDispose: base.onDispose,
  );
}
