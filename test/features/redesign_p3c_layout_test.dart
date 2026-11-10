import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/app/app_dependencies.dart';
import 'package:taytay_resident/core/config/app_config.dart';
import 'package:taytay_resident/core/design/app_theme.dart';
import 'package:taytay_resident/core/design/design_tokens.dart';
import 'package:taytay_resident/core/design/taytay_icons.dart';
import 'package:taytay_resident/core/l10n/app_locales.dart';
import 'package:taytay_resident/core/session/access_level.dart';
import 'package:taytay_resident/core/session/local_authenticator.dart';
import 'package:taytay_resident/core/session/session_state.dart';
import 'package:taytay_resident/core/session/session_store.dart';
import 'package:taytay_resident/core/startup/launch_controller.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/features/account/presentation/account_canvas.dart';
import 'package:taytay_resident/features/account/presentation/account_screen.dart';
import 'package:taytay_resident/features/account/presentation/security_screen.dart';
import 'package:taytay_resident/features/directory/data/office_catalogue.dart';
import 'package:taytay_resident/features/directory/domain/office.dart';
import 'package:taytay_resident/features/directory/presentation/directory_canvas.dart';
import 'package:taytay_resident/features/profile/presentation/contact_details_screen.dart';
import 'package:taytay_resident/features/profile/presentation/privacy_screen.dart';
import 'package:taytay_resident/features/profile/presentation/profile_screen.dart';
import 'package:taytay_resident/features/settings/presentation/privacy_controls_screen.dart';
import 'package:taytay_resident/features/settings/presentation/settings_screen.dart';
import 'package:taytay_resident/l10n/app_localizations.dart';
import 'package:taytay_resident/shared/widgets/blue_header.dart';
import 'package:taytay_resident/shared/widgets/conversation.dart';
import 'package:taytay_resident/shared/widgets/icon_tile.dart';
import 'package:taytay_resident/shared/widgets/notice_panel.dart';
import 'package:taytay_resident/shared/widgets/pill_button_row.dart';
import 'package:taytay_resident/shared/widgets/settings_list.dart';
import 'package:taytay_resident/shared/widgets/success_screen.dart';
import 'package:taytay_resident/shared/widgets/surface_cards.dart';
import 'package:taytay_resident/shared/widgets/wave_header.dart';

import '../support/layout_matrix.dart';

/// Redesign P3c: My Account, profile and settings at 360 / 375 / 430 dp and
/// 100% / 200% text, plus the content rules the restyle must keep. The
/// Account boxes here replace the retired "08 DOM boxes" test.
void main() {
  group('account canvas frames', () {
    final Map<String, AccountCanvas Function()> frames =
        <String, AccountCanvas Function()>{
          'home': () => AccountCanvas(
            frame: AccountFrame.home,
            name: 'Resident Sample With A Long Name',
            initials: 'RS',
            location: 'Brgy. Sample, Taytay, Rizal',
            menu: AccountSpecimen.homeMenu,
            onDigitalId: () {},
            onSignOut: () {},
          ),
          'home loading': () =>
              const AccountCanvas(frame: AccountFrame.home, loading: true),
          'inbox': () => const AccountCanvas(
            frame: AccountFrame.inbox,
            title: 'Messages',
            showBack: true,
            inbox: AccountSpecimen.inbox,
            inboxMoreMessage: 'More messages did not load.',
            onInboxMoreRetry: _noop,
          ),
          'inbox empty': () => const AccountCanvas(
            frame: AccountFrame.inboxEmpty,
            title: 'Messages',
            showBack: true,
          ),
          'inbox error': () => const AccountCanvas(
            frame: AccountFrame.inboxError,
            title: 'Messages',
            showBack: true,
          ),
          'inbox loading': () => const AccountCanvas(
            frame: AccountFrame.inbox,
            title: 'Messages',
            showBack: true,
            loading: true,
          ),
          'edit profile': () => const AccountCanvas(
            frame: AccountFrame.editProfile,
            title: 'Edit profile',
            showBack: true,
            showBell: false,
            initials: 'RS',
            showLegalNameNote: false,
            fields: <AccountField>[
              AccountField(
                label: 'Name',
                value: 'Resident Sample With A Long Name',
                locked: true,
                note: 'Your name was checked against your ID.',
              ),
              AccountField(label: 'Barangay', value: 'Sample', chevron: true),
            ],
          ),
          'settings': () => const AccountCanvas(
            frame: AccountFrame.settings,
            title: 'Settings & privacy',
            showBack: true,
            showBell: false,
            toggles: AccountSpecimen.toggles,
            onConsents: _noop,
          ),
          'about': () => const AccountCanvas(
            frame: AccountFrame.about,
            title: 'Photo credits & about',
            showBack: true,
            showBell: false,
          ),
          'banners': () => const AccountCanvas(
            frame: AccountFrame.banners,
            title: 'Office banner photos',
            showBack: true,
            showBell: false,
          ),
          'privacy draft': () => const AccountCanvas(
            frame: AccountFrame.privacy,
            title: 'Privacy Notice',
            showBack: true,
            showBundledDraft: true,
          ),
          'privacy published': () => const AccountCanvas(
            frame: AccountFrame.privacy,
            title: 'Privacy Notice',
            showBack: true,
            noticeMarkdown:
                '## What we collect\n\n**Name** and address.\n\n- One',
          ),
          'privacy pending': () => const AccountCanvas(
            frame: AccountFrame.privacy,
            title: 'Privacy Notice',
            showBack: true,
          ),
        };
    for (final MapEntry<String, AccountCanvas Function()> frame
        in frames.entries) {
      testWidgets('${frame.key} lays out cleanly', (tester) async {
        await expectCleanLayouts(tester, frame.value, scrollable: false);
      });
    }

    testWidgets('home is the glass tab under the blue header', (tester) async {
      await tester.pumpWidget(
        layoutHost(
          AccountCanvas(
            frame: AccountFrame.home,
            name: 'Resident Sample',
            initials: 'RS',
            location: 'Brgy. Sample, Taytay, Rizal',
            menu: AccountSpecimen.homeMenu,
            onDigitalId: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(GlassOverlap), findsOneWidget);
      expect(find.byType(BlueHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SettingsList),
          matching: find.byType(GlassCard),
        ),
        findsWidgets,
      );
      expect(find.text('My Taytay ID'), findsOneWidget);
      expect(find.text('Resident Sample'), findsOneWidget);
    });

    testWidgets('Account boxes follow Account.dc.html', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        layoutHost(
          AccountCanvas(
            frame: AccountFrame.home,
            name: 'Resident Sample',
            initials: 'RS',
            location: 'Brgy. Sample, Taytay, Rizal',
            menu: AccountSpecimen.homeMenu,
            onDigitalId: () {},
            onSignOut: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      // `.li`: at least 64 tall. `.ic`: 40 square.
      for (final Element row in find.byType(SettingsRow).evaluate()) {
        expect(row.size!.height, greaterThanOrEqualTo(ComponentSizes.listRow));
      }
      expect(
        tester.getSize(find.byType(SettingsIcon).first),
        const Size(ComponentSizes.listIcon, ComponentSizes.listIcon),
      );
      // `.idbtn`: at least 50 tall, the width of the header.
      final Finder id = find.byWidgetPredicate(
        (Widget widget) =>
            widget is Semantics && widget.properties.label == 'My Taytay ID',
      );
      expect(
        tester.getSize(id).height,
        greaterThanOrEqualTo(ComponentSizes.headerButton),
      );
      expect(tester.getSize(id).width, 390 - 2 * Spacing.lg);
      // `.prof .av`: a 60 px disc.
      expect(
        tester.getSize(find.text('RS')).height,
        lessThan(ComponentSizes.profileAvatar),
      );
    });

    testWidgets('the defaults carry no specimen name or sample tag', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountCanvas(frame: AccountFrame.home),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.textContaining('Juana'), findsNothing);
      expect(find.text('JD'), findsNothing);
      expect(find.text('SAMPLE'), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('edit profile is the RegDetails form', (tester) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountCanvas(
            frame: AccountFrame.editProfile,
            title: 'Edit profile',
            showBack: true,
            fields: <AccountField>[
              AccountField(label: 'Mobile number', value: ''),
            ],
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.byType(WaveHeader), findsOneWidget);
      expect(find.byType(BlueHeader), findsNothing);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('the privacy notice is the RegTerms notice', (tester) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountCanvas(
            frame: AccountFrame.privacy,
            title: 'Privacy Notice',
            showBack: true,
            showBundledDraft: true,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.byType(WaveHeader), findsOneWidget);
      expect(find.byType(NoticePanel), findsOneWidget);
      expect(find.textContaining('DRAFT'), findsOneWidget);
    });
  });

  group('screens', () {
    testWidgets('settings fits every phone, guest and signed in', (
      tester,
    ) async {
      for (final AccessLevel level in <AccessLevel>[
        AccessLevel.guest,
        AccessLevel.verified,
      ]) {
        final AppDependencies dependencies = await _dependencies(level);
        await _expectCleanScreen(
          tester,
          dependencies,
          () => const SettingsScreen(),
        );
      }
    });

    testWidgets('account, security and help fit every phone', (tester) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.verified,
      );
      for (final Widget Function() screen in <Widget Function()>[
        () => const AccountScreen(),
        () => const SecurityScreen(),
        () => const HelpScreen(),
        () => const PrivacyControlsScreen(),
      ]) {
        await _expectCleanScreen(tester, dependencies, screen);
      }
    });

    testWidgets('profile fits every phone, guest and unverified', (
      tester,
    ) async {
      for (final AccessLevel level in <AccessLevel>[
        AccessLevel.guest,
        AccessLevel.unverified,
      ]) {
        final AppDependencies dependencies = await _dependencies(level);
        await _expectCleanScreen(
          tester,
          dependencies,
          () => const ProfileScreen(),
        );
        await _expectCleanScreen(
          tester,
          dependencies,
          () => const ProfileScreen(showBack: true),
        );
      }
    });

    testWidgets('contact details and the privacy page fit every phone', (
      tester,
    ) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.unverified,
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const ContactDetailsScreen(),
      );
      await _expectCleanScreen(
        tester,
        dependencies,
        () => const PrivacyScreen(),
      );
    });

    testWidgets('the unverified account tab is glass under the blue header', (
      tester,
    ) async {
      final AppDependencies dependencies = await _dependencies(
        AccessLevel.unverified,
      );
      await tester.pumpWidget(_host(dependencies, const ProfileScreen()));
      await tester.pump();
      expect(find.byType(GlassBackground), findsOneWidget);
      expect(find.byType(BlueHeader), findsOneWidget);
      expect(find.byKey(profileScreenKey), findsOneWidget);
      expect(find.text('Not yet verified'), findsOneWidget);
      expect(find.byIcon(TaytayIcons.hourglass), findsOneWidget);
    });
  });

  group('shared list widgets', () {
    testWidgets('a row reads its count and keeps a 48 dp target', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          SettingsList(
            children: <Widget>[
              SettingsRow(
                icon: TaytayIcons.messageSquare,
                title: 'Messages',
                detail: 'From the API',
                badgeCount: 2,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      final Finder row = find.bySemanticsLabel('Messages, From the API, 2 new');
      expect(row, findsOneWidget);
      expect(
        tester.getSize(find.byType(SettingsRow)).height,
        greaterThanOrEqualTo(A11y.minTapTarget),
      );
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a switch row toggles through the whole row', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        layoutHost(
          StatefulBuilder(
            builder: (context, setState) => SettingsList(
              children: <Widget>[
                SettingsSwitchRow(
                  icon: TaytayIcons.bell,
                  title: 'Alerts',
                  value: value,
                  onChanged: (bool next) => setState(() => value = next),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Alerts'));
      await tester.pump();
      expect(value, isTrue);
    });

    testWidgets('list widgets fit every phone', (tester) async {
      await expectCleanLayouts(
        tester,
        () => Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: <Widget>[
              SettingsList(
                children: <Widget>[
                  SettingsRow(
                    icon: TaytayIcons.idCard,
                    title: 'A row title long enough to wrap at large text',
                    detail: 'A detail line that also wraps when text is large',
                    progress: 0.5,
                    badgeCount: 12,
                    onTap: () {},
                  ),
                  SettingsSwitchRow(
                    icon: TaytayIcons.bell,
                    title: 'A switch row with a long title',
                    detail: 'And a detail',
                    value: true,
                    onChanged: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              const NoticePanel(
                title: 'Notice title that runs long',
                subtitle: 'Source line',
                icon: TaytayIcons.shieldCheck,
                badge: DraftPill('DRAFT · text to be inserted'),
                intro: 'Intro paragraph.',
                points: <NoticePoint>[
                  NoticePoint(title: 'Point', body: 'Body text.'),
                ],
              ),
            ],
          ),
        ),
      );
    });
  });

  group('directory', () {
    testWidgets('every directory frame fits every phone', (tester) async {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      final Office bplo = catalogue.offices.singleWhere(
        (Office office) => office.id == 'bplo',
      );
      final Office mdrrmo = catalogue.offices.singleWhere(
        (Office office) => office.id == 'mdrrmo',
      );
      for (final DirectoryCanvas Function() frame
          in <DirectoryCanvas Function()>[
            () => DirectoryCanvas(
              frame: DirectoryFrame.list,
              offices: catalogue.offices,
              chips: catalogue.chips,
              onChip: (_) {},
            ),
            () => DirectoryCanvas(
              frame: DirectoryFrame.list,
              offices: catalogue.offices,
              chips: catalogue.chips,
              query: 'no office has this word',
              onBrowseAll: () {},
            ),
            () => DirectoryCanvas(
              frame: DirectoryFrame.loading,
              offices: const <Office>[],
              chips: catalogue.chips,
            ),
            () => DirectoryCanvas(
              frame: DirectoryFrame.offline,
              offices: catalogue.offices,
            ),
            () => DirectoryCanvas(
              frame: DirectoryFrame.searchSpecimen,
              offices: catalogue.offices,
            ),
            () => DirectoryCanvas(
              frame: DirectoryFrame.detail,
              offices: const <Office>[],
              office: bplo,
            ),
            () => DirectoryCanvas(
              frame: DirectoryFrame.detail,
              offices: const <Office>[],
              office: mdrrmo,
            ),
            () => const DirectoryCanvas(
              frame: DirectoryFrame.detail,
              offices: <Office>[],
            ),
            () => const DirectoryCanvas(
              frame: DirectoryFrame.detail,
              offices: <Office>[],
              officeMissing: true,
            ),
          ]) {
        await expectCleanLayouts(tester, frame, scrollable: false);
      }
    });

    testWidgets('the list is soft rows with gradient tiles and live chips', (
      tester,
    ) async {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      String chip = 'All';
      await tester.pumpWidget(
        layoutHost(
          StatefulBuilder(
            builder: (context, setState) => DirectoryCanvas(
              frame: DirectoryFrame.list,
              offices: catalogue.offices,
              chips: catalogue.chips,
              selectedChip: chip,
              onChip: (String next) => setState(() => chip = next),
            ),
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.byType(BlueHeader), findsOneWidget);
      expect(find.byType(IconTile), findsWidgets);
      expect(find.text('${catalogue.offices.length} offices'), findsOneWidget);
      final String category = catalogue.chips[1];
      await tester.tap(find.text(category).first);
      await tester.pump();
      expect(chip, category);
      final int inCategory = catalogue.offices
          .where((Office office) => office.category == category)
          .length;
      expect(
        find.text('$inCategory ${inCategory == 1 ? 'office' : 'offices'}'),
        findsOneWidget,
      );
    });

    testWidgets('no match says so and offers every office again', (
      tester,
    ) async {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      var browsed = 0;
      await tester.pumpWidget(
        layoutHost(
          DirectoryCanvas(
            frame: DirectoryFrame.list,
            offices: catalogue.offices,
            chips: catalogue.chips,
            query: 'zzz',
            onBrowseAll: () => browsed++,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.text('No offices found for “zzz”'), findsOneWidget);
      await tester.tap(find.text('Browse all offices'));
      expect(browsed, 1);
    });

    testWidgets('an office page is the photo, the sheet and the pills', (
      tester,
    ) async {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      final Office office = catalogue.offices.first;
      await tester.pumpWidget(
        layoutHost(
          DirectoryCanvas(
            frame: DirectoryFrame.detail,
            offices: const <Office>[],
            office: office,
            onCall: () {},
            onDirections: () {},
            onMessage: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.byType(GlassOverlap), findsOneWidget);
      expect(find.byType(PillButtonRow), findsOneWidget);
      // No structured hours from the API: no open / closed line is drawn.
      expect(find.textContaining('Closes'), findsNothing);
      expect(find.textContaining('Opens'), findsNothing);
      // No Facebook link from the API: the pills offer none.
      expect(
        find.descendant(
          of: find.byType(PillButtonRow),
          matching: find.text('Facebook'),
        ),
        findsNothing,
      );
    });

    testWidgets('offline shows the saved numbers and Try again', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      var retried = 0;
      await tester.pumpWidget(
        layoutHost(
          DirectoryCanvas(
            frame: DirectoryFrame.offline,
            offices: catalogue.offices,
            onRetry: () => retried++,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.text("You're offline"), findsOneWidget);
      expect(find.text('Saved on this phone'), findsOneWidget);
      await tester.tap(find.byKey(const Key('directory-retry')));
      expect(retried, 1);
      expect(
        tester.getSize(find.byKey(const Key('directory-saved-call-mswdo'))),
        const Size(A11y.minTapTarget, A11y.minTapTarget),
      );
    });
  });

  group('messaging', () {
    testWidgets('compose, sent and thread fit every phone', (tester) async {
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      final Office office = catalogue.offices.singleWhere(
        (Office office) => office.id == 'bplo',
      );
      for (final Widget Function() frame in <Widget Function()>[
        () => DirectoryCanvas(
          frame: DirectoryFrame.compose,
          offices: const <Office>[],
          office: office,
          selectedTopic: 'A topic long enough to wrap at large text',
          attachmentLabel: 'a-file-name-that-is-rather-long.pdf',
          composeError: 'Write a message before sending.',
          onAttach: () {},
          onTopic: () {},
          onSend: () {},
        ),
        () => const DirectoryCanvas(
          frame: DirectoryFrame.compose,
          offices: <Office>[],
        ),
        () => DirectoryCanvas(
          frame: DirectoryFrame.sent,
          offices: const <Office>[],
          office: office,
          emergencyPhone: office.phone,
          onMessages: () {},
          onBack: () {},
        ),
        () => DirectoryCanvas(
          frame: DirectoryFrame.thread,
          offices: const <Office>[],
          office: office,
          dayLabel: 'Oct 12',
          bubbles: const <DirectoryThreadBubble>[
            DirectoryThreadBubble(
              fromResident: true,
              when: '8:42 PM',
              body: 'A question long enough to wrap onto several lines.',
            ),
            DirectoryThreadBubble(
              fromResident: false,
              when: 'BPLO · 9:05 AM',
              body: 'An answer.',
              attachment: 'requirements.pdf',
              attachmentMeta: 'PDF',
            ),
          ],
        ),
        () => const AccountCanvas(
          frame: AccountFrame.thread,
          title: 'Office',
          subtitle: 'The office name in full',
          showBack: true,
          showBell: false,
          dayLabel: 'Oct 12',
          bubbles: AccountSpecimen.mswdoBubbles,
          attachmentLabel: 'a-chosen-file.pdf',
          onClearAttachment: _noop,
          onAttach: _noop,
          onSend: _noop,
          threadMoreMessage: 'Older messages did not load.',
          onThreadMoreRetry: _noop,
        ),
        () => const AccountCanvas(
          frame: AccountFrame.thread,
          title: 'Office',
          showBack: true,
          showBell: false,
          bubbles: AccountSpecimen.treasurerBubbles,
          threadClosed: true,
        ),
      ]) {
        await expectCleanLayouts(tester, frame, scrollable: false);
      }
    });

    testWidgets('compose states its problem above Send, never logged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ({List<String> chips, List<Office> offices}) catalogue =
          await OfficeCatalogue.load();
      await tester.pumpWidget(
        layoutHost(
          DirectoryCanvas(
            frame: DirectoryFrame.compose,
            offices: const <Office>[],
            office: catalogue.offices.first,
            composeError: 'Write a message before sending.',
            onSend: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.text('Write a message before sending.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Write a message before sending.')).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('directory-send'))).dy),
      );
      expect(find.textContaining('one-time codes'), findsOneWidget);
      expect(find.byType(BlueHeader), findsOneWidget);
    });

    testWidgets('the sent page is the success pattern without a made-up time', (
      tester,
    ) async {
      await tester.pumpWidget(
        layoutHost(
          DirectoryCanvas(
            frame: DirectoryFrame.sent,
            offices: const <Office>[],
            onMessages: () {},
            onBack: () {},
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(find.byType(SuccessScreen), findsOneWidget);
      expect(find.text('Message sent'), findsWidgets);
      expect(find.textContaining('working days'), findsNothing);
      expect(find.text('SAMPLE'), findsNothing);
    });

    testWidgets('a thread is bubbles over the composer', (tester) async {
      await tester.pumpWidget(
        layoutHost(
          const AccountCanvas(
            frame: AccountFrame.thread,
            title: 'Office',
            showBack: true,
            showBell: false,
            bubbles: AccountSpecimen.mswdoBubbles,
            onSend: _noop,
          ),
          scrollable: false,
        ),
      );
      await tester.pump();
      expect(
        find.byType(ConversationBubble),
        findsNWidgets(AccountSpecimen.mswdoBubbles.length),
      );
      expect(find.byType(ConversationComposer), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('account-thread-send'))),
        const Size(A11y.minTapTarget, A11y.minTapTarget),
      );
    });
  });

  test('restyled screens use tokens: no raw colours, sizes or shadows', () {
    final List<String> offenders = <String>[];
    for (final String path in _restyled) {
      final List<String> lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final String line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (RegExp(
          r'Color\(0x|BoxShadow|elevation:|fontSize:',
        ).hasMatch(line)) {
          offenders.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

void _noop() {}

const List<String> _restyled = <String>[
  'lib/features/account/presentation/account_home_screen.dart',
  'lib/features/account/presentation/account_screen.dart',
  'lib/features/account/presentation/security_screen.dart',
  'lib/features/account/presentation/change_password_form.dart',
  'lib/features/profile/presentation/profile_screen.dart',
  'lib/features/profile/presentation/profile_field_list.dart',
  'lib/features/profile/presentation/contact_details_screen.dart',
  'lib/features/profile/presentation/privacy_screen.dart',
  'lib/features/settings/presentation/settings_screen.dart',
  'lib/features/settings/presentation/privacy_controls_screen.dart',
  'lib/shared/widgets/settings_list.dart',
  'lib/shared/widgets/notice_panel.dart',
  'lib/shared/widgets/soft_page.dart',
  'lib/shared/widgets/conversation.dart',
  'lib/features/account/presentation/account_canvas.dart',
  'lib/features/account/presentation/account_pages.dart',
  'lib/features/directory/presentation/directory_canvas.dart',
  'lib/features/directory/presentation/directory_screen.dart',
];

/// The dev mock, with a session at [level] already restored.
Future<AppDependencies> _dependencies(AccessLevel level) async {
  final InMemorySecretStore secrets = InMemorySecretStore();
  await secrets.write(LaunchController.welcomeCompletedKey, 'true');
  final InMemorySessionStore store = InMemorySessionStore();
  if (level != AccessLevel.guest) {
    await store.write(
      StoredSession(
        resident: ResidentSession(
          accountId: 'acct-sample',
          accessLevel: level,
          displayName: 'Sample',
        ),
        accessToken: 'token-sample',
      ),
    );
  }
  final AppDependencies dependencies = AppDependencies.build(
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
  addTearDown(dependencies.dispose);
  await dependencies.session.restore();
  return dependencies;
}

Widget _host(
  AppDependencies dependencies,
  Widget child, {
  double textScale = 1,
}) {
  return AppDependenciesScope(
    dependencies: dependencies,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppLocales.supported,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    ),
  );
}

/// [expectCleanLayouts] for a screen that needs the app's dependencies and
/// strings: every width and text scale, failing on any error.
Future<void> _expectCleanScreen(
  WidgetTester tester,
  AppDependencies dependencies,
  Widget Function() build,
) async {
  addTearDown(tester.view.reset);
  for (final double width in layoutWidths) {
    for (final double scale in layoutTextScales) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        _host(
          dependencies,
          KeyedSubtree(key: UniqueKey(), child: build()),
          textScale: scale,
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final Object? error = tester.takeException();
      expect(error, isNull, reason: '$width dp at ${scale}x: $error');
    }
  }
}
