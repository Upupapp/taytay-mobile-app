import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/config/app_version.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/notice_panel.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/notice_markdown.dart';
import '../domain/photo_credit.dart';
import 's8_space.dart';

/// Which My Account frame the canvas is painting.
enum AccountFrame {
  home,
  inbox,
  inboxEmpty,
  inboxError,
  editProfile,
  settings,
  about,
  thread,
  privacy,
  banners,
}

/// One home-menu row.
class AccountMenuRow {
  const AccountMenuRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tile,
    required this.iconColor,
    this.badge,
    this.progress,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tile;
  final Color iconColor;

  /// A count drawn on the row, such as the Messages `1`.
  final String? badge;

  /// A completion share (0–1) drawn as a thin bar under the subtitle.
  final double? progress;
  final VoidCallback? onTap;
}

/// One inbox row.
class AccountInboxRow {
  const AccountInboxRow({
    required this.office,
    required this.when,
    required this.preview,
    required this.icon,
    required this.tile,
    required this.iconColor,
    this.badge,
    this.onTap,
  });

  final String office;
  final String when;
  final String preview;
  final IconData icon;
  final Color tile;
  final Color iconColor;

  /// Unread count for this office, drawn when the thread has one.
  final String? badge;
  final VoidCallback? onTap;
}

/// One chat bubble.
class AccountBubble {
  const AccountBubble({
    required this.body,
    required this.when,
    required this.fromResident,
    this.mediaIds = const <String>[],
  });

  final String body;
  final String when;
  final bool fromResident;

  /// Media the resident can already read. Empty on the design specimen.
  final List<String> mediaIds;
}

/// One labelled value on Edit profile.
class AccountField {
  const AccountField({
    required this.label,
    required this.value,
    this.verified = false,
    this.chevron = false,
    this.controller,
    this.onChanged,
    this.onTap,
    this.locked = false,
    this.note,
  });

  final String label;
  final String value;
  final bool verified;
  final bool chevron;

  /// Draws a lock: the value is shown and cannot be changed on this screen.
  final bool locked;

  /// One sentence under the field, saying what the value is or why it is
  /// locked.
  final String? note;

  /// When set, the row is a text field and Save reads what was typed.
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
}

/// One settings switch. [locked] draws the on state and does not toggle.
class AccountToggle {
  const AccountToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tile,
    required this.iconColor,
    required this.on,
    this.locked = false,
    this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tile;
  final Color iconColor;
  final bool on;
  final bool locked;
  final ValueChanged<bool>? onChanged;
}

/// My Account in the redesign.
///
/// The home is the glass main tab of `Account.dc.html`: the tall blue header
/// with the resident's initials, barangay and the gold "My Taytay ID" button,
/// and the menu as one glass list. Lists (inbox, settings, credits) are soft
/// cards under a blue header with a back control; Edit profile is the
/// RegDetails form and the privacy notice the RegTerms notice, both under the
/// wave header.
///
/// Every name, line and count comes from the screen that builds the canvas.
/// The defaults are empty: [AccountSpecimen] holds the synthetic design
/// specimen for tests and captures, and nothing reaches a live screen from it.
///
/// The shell paints the tab bar, except a thread, which fills the phone.
class AccountCanvas extends StatelessWidget {
  const AccountCanvas({
    required this.frame,
    this.title = 'My Account',
    this.subtitle = 'Bayan ng Taytay · Rizal',
    this.subtitleLines = 1,
    this.showBack = false,
    this.showBell = true,
    this.onBack,
    this.onBell,
    this.name = '',
    this.initials = '',
    this.location = '',
    this.verifiedLabel = 'Verified',
    this.sample = false,
    this.menu = const <AccountMenuRow>[],
    this.onSignOut,
    this.onDigitalId,
    this.inbox = const <AccountInboxRow>[],
    this.showSampleNote = false,
    this.onInboxRetry,
    this.onMessageOffice,
    this.fields = const <AccountField>[],
    this.onSave,
    this.onLegalName,
    this.showLegalNameNote = true,
    this.toggles = const <AccountToggle>[],
    this.onLanguage,
    this.onChangePassword,
    this.changePasswordSubtitle = '',
    this.onPrivacy,
    this.onConsents,
    this.onBanners,
    this.onExport,
    this.showDataExport = false,
    this.noticeMarkdown,
    this.showBundledDraft = false,
    this.bubbles = const <AccountBubble>[],
    this.dayLabel = '',
    this.onSend,
    this.sendEnabled = true,
    this.onInboxNearEnd,
    this.composer,
    this.onAttach,
    this.onThreadMenu,
    this.threadClosed = false,
    this.hideComposer = false,
    this.attachmentLabel,
    this.onClearAttachment,
    this.onUseMedia,
    this.onThreadNearStart,
    this.inboxMoreMessage,
    this.onInboxMoreRetry,
    this.threadMoreMessage,
    this.onThreadMoreRetry,
    this.credits = PhotoCredits.all,
    this.loading = false,
    super.key,
  });

  final AccountFrame frame;
  final String title;
  final String subtitle;

  /// Kept for callers; the header wraps a long subtitle on its own.
  final int subtitleLines;
  final bool showBack;
  final bool showBell;
  final VoidCallback? onBack;
  final VoidCallback? onBell;
  final String name;
  final String initials;
  final String location;
  final String verifiedLabel;

  /// Marks the home name as a design specimen.
  final bool sample;
  final List<AccountMenuRow> menu;
  final VoidCallback? onSignOut;

  /// The gold "My Taytay ID" button on the home header. Null hides it.
  final VoidCallback? onDigitalId;
  final List<AccountInboxRow> inbox;

  /// The SAMPLE illustration line. Live screens pass `usesMockData`.
  final bool showSampleNote;
  final VoidCallback? onInboxRetry;
  final VoidCallback? onMessageOffice;
  final List<AccountField> fields;
  final VoidCallback? onSave;
  final VoidCallback? onLegalName;

  /// The design's legal-name line on Edit profile. The live screen draws the
  /// name as a field with its own note instead (D-195).
  final bool showLegalNameNote;
  final List<AccountToggle> toggles;
  final VoidCallback? onLanguage;
  final VoidCallback? onChangePassword;
  final String changePasswordSubtitle;

  /// The design draws a data-export row. The API has no such route, so the
  /// live screens pass false and the row is not shown.
  final bool showDataExport;

  /// Published `body_markdown`. Null keeps the bundled draft when
  /// [showBundledDraft] is set. Production leaves both off.
  final String? noticeMarkdown;

  /// The bundled DRAFT copy. Non-production only.
  final bool showBundledDraft;
  final VoidCallback? onPrivacy;
  final VoidCallback? onConsents;
  final VoidCallback? onBanners;
  final VoidCallback? onExport;
  final List<AccountBubble> bubbles;
  final String dayLabel;
  final VoidCallback? onSend;

  /// False while a reply is in flight. Specimens leave this on.
  final bool sendEnabled;
  final VoidCallback? onInboxNearEnd;
  final TextEditingController? composer;
  final VoidCallback? onAttach;
  final VoidCallback? onThreadMenu;
  final bool threadClosed;

  /// The first load failed. The live thread omits the composer.
  final bool hideComposer;
  final String? attachmentLabel;
  final VoidCallback? onClearAttachment;
  final ValueChanged<String>? onUseMedia;
  final VoidCallback? onThreadNearStart;

  /// Shown under the inbox list when the next page failed.
  final String? inboxMoreMessage;
  final VoidCallback? onInboxMoreRetry;

  /// Shown above the messages when an older page failed.
  final String? threadMoreMessage;
  final VoidCallback? onThreadMoreRetry;
  final List<PhotoCredit> credits;

  /// The first read has not answered: the header stays and the body is a
  /// skeleton.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final Widget page = switch (frame) {
      AccountFrame.home => _HomePage(canvas: this),
      AccountFrame.editProfile => _EditPage(canvas: this),
      AccountFrame.privacy => _PrivacyPage(canvas: this),
      _ => _BackPage(canvas: this),
    };
    return Material(
      color: frame == AccountFrame.home
          ? BrandColors.glassBackground
          : BrandColors.background,
      child: page,
    );
  }
}

/// Design specimen. Synthetic. The live screens pass server values instead.
abstract final class AccountSpecimen {
  static const List<AccountMenuRow> homeMenu = <AccountMenuRow>[
    AccountMenuRow(
      title: 'Resident Profile',
      subtitle: '60% complete',
      icon: TaytayIcons.idCard,
      tile: BrandColors.blue50,
      iconColor: BrandColors.taytayBlue,
    ),
    AccountMenuRow(
      title: 'Messages',
      subtitle: '1 new reply from BPLO',
      icon: TaytayIcons.messageSquare,
      tile: BrandColors.blue50,
      iconColor: BrandColors.taytayBlue,
      badge: '1',
    ),
    AccountMenuRow(
      title: 'Verification status',
      subtitle: 'Verified · Oct 22, 2026',
      icon: TaytayIcons.shield,
      tile: BrandColors.green50,
      iconColor: BrandColors.success,
    ),
    AccountMenuRow(
      title: 'Settings',
      subtitle: 'Notifications, language',
      icon: TaytayIcons.settings,
      tile: BrandColors.blue50,
      iconColor: BrandColors.taytayBlue,
    ),
    AccountMenuRow(
      title: 'Privacy & data',
      subtitle: 'Privacy Notice, your data rights',
      icon: TaytayIcons.lock,
      tile: BrandColors.blue50,
      iconColor: BrandColors.taytayBlue,
    ),
    AccountMenuRow(
      title: 'Photo credits & about',
      subtitle: 'Licences, app version',
      icon: TaytayIcons.image,
      tile: BrandColors.blue50,
      iconColor: BrandColors.taytayBlue,
    ),
  ];

  static const List<AccountInboxRow> inbox = <AccountInboxRow>[
    AccountInboxRow(
      office: 'BPLO',
      when: '9:06 AM',
      preview: 'Magandang araw po! Para sa renewal, dalhin…',
      icon: TaytayIcons.briefcase,
      tile: BrandColors.chipBlueBg,
      iconColor: BrandColors.taytayBlue,
      badge: '1',
    ),
    AccountInboxRow(
      office: 'MSWDO',
      when: 'Mon',
      preview: 'You: Salamat po sa impormasyon.',
      icon: TaytayIcons.handHeart,
      tile: BrandColors.green50,
      iconColor: BrandColors.success,
    ),
    AccountInboxRow(
      office: "Treasurer's Office",
      when: 'Oct 12',
      preview: 'Your RPT computation is ready for…',
      icon: TaytayIcons.landmark,
      tile: BrandColors.chipBlueBg,
      iconColor: BrandColors.taytayBlue,
    ),
  ];

  static const List<AccountField> fields = <AccountField>[
    AccountField(label: 'Display name', value: 'Juana Dela Cruz'),
    AccountField(
      label: 'Mobile number',
      value: '0917 123 4567',
      verified: true,
    ),
    AccountField(
      label: 'Email',
      value: 'juana.delacruz@example.com',
      verified: true,
    ),
    AccountField(label: 'Barangay', value: 'San Juan', chevron: true),
  ];

  static const List<AccountToggle> toggles = <AccountToggle>[
    AccountToggle(
      title: 'Balita & advisories',
      subtitle: 'Push notifications',
      icon: TaytayIcons.bell,
      tile: BrandColors.blue50,
      iconColor: BrandColors.taytayBlue,
      on: true,
    ),
    AccountToggle(
      title: 'Office replies',
      subtitle: 'Push and email',
      icon: TaytayIcons.messageSquare,
      tile: BrandColors.chipBlueBg,
      iconColor: BrandColors.taytayBlue,
      on: true,
    ),
    AccountToggle(
      title: 'Emergency alerts',
      subtitle: 'Always on for MDRRMO alerts',
      icon: TaytayIcons.siren,
      tile: BrandColors.red50,
      iconColor: BrandColors.danger,
      on: true,
      locked: true,
    ),
  ];

  static const List<AccountBubble> mswdoBubbles = <AccountBubble>[
    AccountBubble(
      body:
          'Magandang araw po. Paano po kung hindi nakuha ang 2026 PWD Cash '
          'Gift noong Jul 31?',
      when: '10:14 AM',
      fromResident: true,
    ),
    AccountBubble(
      body:
          'Magandang araw po! Pumunta po muna sa MSWD Office, Ground Floor, '
          'para ma-validate ang inyong ID, saka po sa Treasury Office, '
          '2nd Floor.',
      when: 'MSWDO · 11:02 AM',
      fromResident: false,
    ),
    AccountBubble(
      body: 'Dalhin po ang original at photocopy ng updated PWD ID.',
      when: 'MSWDO · 11:03 AM',
      fromResident: false,
    ),
    AccountBubble(
      body: 'Salamat po sa impormasyon.',
      when: '11:10 AM',
      fromResident: true,
    ),
  ];

  static const List<AccountBubble> treasurerBubbles = <AccountBubble>[
    AccountBubble(
      body:
          'Magandang araw po. Puwede po bang malaman ang halaga ng RPT ko '
          'para sa 2026?',
      when: 'Oct 10',
      fromResident: true,
    ),
    AccountBubble(
      body:
          'Magandang araw po. Paki-send po ang Tax Declaration number para '
          'ma-compute namin.',
      when: 'Treasury · Oct 11',
      fromResident: false,
    ),
    AccountBubble(
      body: 'TD No. 00-0000-00000 po (sample).',
      when: 'Oct 11',
      fromResident: true,
    ),
    AccountBubble(
      body:
          'Your RPT computation is ready for pickup or payment at the '
          'Treasury Office, 2nd Floor.',
      when: 'Treasury · Oct 12',
      fromResident: false,
    ),
  ];
}

/// `Account.dc.html`: the glass main tab. The header holds the resident and
/// the ID button; the menu rides up over it as one glass list, with Sign out
/// in a list of its own.
class _HomePage extends StatelessWidget {
  const _HomePage({required this.canvas});

  final AccountCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onBell = canvas.onBell;
    return GlassBackground(
      child: ListView(
        key: const Key('account-home-scroll'),
        padding: EdgeInsets.only(
          bottom: Spacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: <Widget>[
          BlueHeader(
            leading: const HeaderSeal(),
            title: canvas.title,
            subtitle: canvas.subtitle,
            overlap: true,
            actions: <Widget>[
              if (canvas.showBell)
                HeaderIconButton(
                  icon: TaytayIcons.bell,
                  semanticLabel: 'Notifications',
                  onPressed: onBell,
                ),
            ],
            bottom: canvas.loading ? null : _ProfileBlock(canvas: canvas),
          ),
          GlassOverlap(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: canvas.loading
                  ? const GlassCard(
                      child: LoadingSkeleton(
                        semanticLabel: 'Loading your account',
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (canvas.menu.isNotEmpty) ...<Widget>[
                          SettingsList(
                            glass: true,
                            children: <Widget>[
                              for (final AccountMenuRow row in canvas.menu)
                                _MenuRow(row: row),
                            ],
                          ),
                          const SizedBox(height: Spacing.section),
                        ],
                        SettingsList(
                          glass: true,
                          children: <Widget>[
                            SettingsRow(
                              title: 'Sign out',
                              icon: TaytayIcons.logOut,
                              destructive: true,
                              onTap: canvas.onSignOut,
                              semanticLabel: 'Sign out',
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.row});

  final AccountMenuRow row;

  @override
  Widget build(BuildContext context) {
    final int? count = int.tryParse(row.badge ?? '');
    return SettingsRow(
      title: row.title,
      detail: row.subtitle,
      icon: row.icon,
      iconFill: row.tile,
      iconInk: row.iconColor,
      badgeCount: count,
      progress: row.progress,
      onTap: row.onTap,
    );
  }
}

/// CSS `.prof` and `.idbtn`: the avatar with its gold ring and verified
/// tick, the name, the barangay and the verification line, then the gold ID
/// button when the screen offers one.
class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock({required this.canvas});

  final AccountCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onDigitalId = canvas.onDigitalId;
    final bool verified = canvas.verifiedLabel.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            _Avatar(initials: canvas.initials, verified: verified),
            const SizedBox(width: Spacing.section),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (canvas.name.isNotEmpty)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Spacing.sm,
                      children: <Widget>[
                        Text(
                          canvas.name,
                          style: AppTypography.storyTitle.copyWith(
                            fontWeight: AppTypography.black,
                            color: BrandColors.white,
                          ),
                        ),
                        if (canvas.sample) const SampleTag(),
                      ],
                    ),
                  if (canvas.location.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    _HeaderLine(
                      icon: TaytayIcons.mapPin,
                      text: canvas.location,
                      color: BrandColors.onHeaderLede,
                    ),
                  ],
                  if (verified) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    _HeaderLine(
                      icon: TaytayIcons.badgeCheck,
                      text: canvas.verifiedLabel,
                      color: BrandColors.onHeaderSuccess,
                      strong: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (onDigitalId != null) ...<Widget>[
          const SizedBox(height: Spacing.section),
          _IdButton(onTap: onDigitalId),
        ],
      ],
    );
  }
}

class _HeaderLine extends StatelessWidget {
  const _HeaderLine({
    required this.icon,
    required this.text,
    required this.color,
    this.strong = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: Spacing.xxs),
          child: TaytayIcon(
            icon: icon,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm - Spacing.xs,
            color: color,
          ),
        ),
        const SizedBox(width: Spacing.xs + 1),
        Flexible(
          child: Text(
            text,
            style: AppTypography.listDetail.copyWith(
              color: color,
              fontWeight: strong ? AppTypography.medium : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// CSS `.prof .av` and `.vb`: 60 px white disc, 3 px gold ring, blue
/// initials, and the green tick at the bottom right when verified.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.verified});

  final String initials;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: ComponentSizes.profileAvatar,
        height: ComponentSizes.profileAvatar,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: ComponentSizes.profileAvatar,
              height: ComponentSizes.profileAvatar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: BrandColors.gold, width: 3),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xs),
                  child: Text(
                    initials,
                    style: AppTypography.storyTitle.copyWith(
                      fontWeight: AppTypography.black,
                      color: BrandColors.blue,
                    ),
                  ),
                ),
              ),
            ),
            if (verified)
              Positioned(
                right: -3,
                bottom: -1,
                child: Container(
                  width: ComponentSizes.profileBadge,
                  height: ComponentSizes.profileBadge,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BrandColors.successBright,
                    shape: BoxShape.circle,
                    border: Border.all(color: BrandColors.blue, width: 2.5),
                  ),
                  child: const TaytayIcon(
                    icon: TaytayIcons.check,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: Spacing.md,
                    color: BrandColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// CSS `.idbtn`: gold, 50 tall, navy 13.5 / 800, the card icon and a chevron.
class _IdButton extends StatelessWidget {
  const _IdButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'My Taytay ID',
      child: ExcludeSemantics(
        child: Material(
          color: BrandColors.gold,
          borderRadius: BorderRadius.circular(Radii.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ComponentSizes.headerButton,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Row(
                  children: <Widget>[
                    const TaytayIcon(
                      icon: TaytayIcons.idCard,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: IconSizes.sm,
                      color: BrandColors.navy,
                    ),
                    const SizedBox(width: Spacing.sm + Spacing.xxs),
                    Expanded(
                      child: Text(
                        'My Taytay ID',
                        style: AppTypography.listTitle.copyWith(
                          fontWeight: AppTypography.black,
                          color: BrandColors.navy,
                        ),
                      ),
                    ),
                    const TaytayIcon(
                      icon: TaytayIcons.chevronRight,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: IconSizes.sm - Spacing.xxs,
                      color: BrandColors.navy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every list frame: the blue header with a back control over the soft
/// page, the frame's body below.
class _BackPage extends StatelessWidget {
  const _BackPage({required this.canvas});

  final AccountCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onBell = canvas.onBell;
    final VoidCallback? onMenu = canvas.onThreadMenu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BlueHeader(
          title: canvas.title,
          subtitle: canvas.subtitle.isEmpty ? null : canvas.subtitle,
          showBack: canvas.showBack,
          onBack: canvas.onBack,
          leading: canvas.showBack ? null : const HeaderSeal(),
          actions: <Widget>[
            if (canvas.showBell)
              HeaderIconButton(
                icon: TaytayIcons.bell,
                semanticLabel: 'Notifications',
                onPressed: onBell,
              ),
            if (onMenu != null)
              HeaderIconButton(
                key: const Key('account-thread-menu'),
                icon: TaytayIcons.moreVertical,
                semanticLabel: 'More',
                onPressed: onMenu,
              ),
          ],
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (canvas.loading) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: const <Widget>[LoadingSkeleton(semanticLabel: 'Loading')],
      );
    }
    final AccountCanvas c = canvas;
    return switch (c.frame) {
      AccountFrame.inbox => _InboxBody(
        rows: c.inbox,
        showSampleNote: c.showSampleNote,
        onNearEnd: c.onInboxNearEnd,
        moreMessage: c.inboxMoreMessage,
        onMoreRetry: c.onInboxMoreRetry,
      ),
      AccountFrame.inboxEmpty => _EmptyInbox(
        onMessageOffice: c.onMessageOffice,
      ),
      AccountFrame.inboxError => _InboxError(onRetry: c.onInboxRetry),
      AccountFrame.settings => _SettingsBody(
        toggles: c.toggles,
        onLanguage: c.onLanguage,
        onChangePassword: c.onChangePassword,
        changePasswordSubtitle: c.changePasswordSubtitle,
        onPrivacy: c.onPrivacy,
        onConsents: c.onConsents,
        onExport: c.onExport,
        showDataExport: c.showDataExport,
      ),
      AccountFrame.about => _AboutBody(
        credits: c.credits,
        onBanners: c.onBanners,
      ),
      AccountFrame.banners => _BannersBody(credits: c.credits),
      AccountFrame.thread => _ThreadBody(
        bubbles: c.bubbles,
        dayLabel: c.dayLabel,
        showSampleNote: c.showSampleNote,
        onSend: c.onSend,
        sendEnabled: c.sendEnabled,
        composer: c.composer,
        onAttach: c.onAttach,
        closed: c.threadClosed,
        hideComposer: c.hideComposer,
        attachmentLabel: c.attachmentLabel,
        onClearAttachment: c.onClearAttachment,
        onUseMedia: c.onUseMedia,
        onNearStart: c.onThreadNearStart,
        moreMessage: c.threadMoreMessage,
        onMoreRetry: c.onThreadMoreRetry,
      ),
      // Drawn by their own pages.
      AccountFrame.home ||
      AccountFrame.editProfile ||
      AccountFrame.privacy => const SizedBox.shrink(),
    };
  }
}

class _InboxBody extends StatelessWidget {
  const _InboxBody({
    required this.rows,
    required this.showSampleNote,
    this.onNearEnd,
    this.moreMessage,
    this.onMoreRetry,
  });

  final List<AccountInboxRow> rows;
  final bool showSampleNote;
  final VoidCallback? onNearEnd;
  final String? moreMessage;
  final VoidCallback? onMoreRetry;

  @override
  Widget build(BuildContext context) {
    final String? moreMessage = this.moreMessage;
    final VoidCallback? onMoreRetry = this.onMoreRetry;
    final Widget list = ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        SettingsList(
          children: <Widget>[
            for (final AccountInboxRow row in rows) _InboxRow(row: row),
          ],
        ),
        if (moreMessage != null && onMoreRetry != null) ...<Widget>[
          const SizedBox(height: Spacing.md),
          _MoreRetry(
            message: moreMessage,
            onRetry: onMoreRetry,
            retryKey: const Key('inbox-load-more-retry'),
          ),
        ],
        if (showSampleNote) ...<Widget>[
          const SizedBox(height: Spacing.section),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.xs + Spacing.xxs,
              children: <Widget>[
                const SampleTag(),
                Text(
                  'messages for illustration',
                  style: AppTypography.small.copyWith(color: BrandColors.muted),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    final VoidCallback? onNearEnd = this.onNearEnd;
    if (onNearEnd == null) return list;
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notice) {
        final ScrollMetrics metrics = notice.metrics;
        if (metrics.maxScrollExtent <= 0) return false;
        if (metrics.maxScrollExtent - metrics.pixels < 600) onNearEnd();
        return false;
      },
      child: list,
    );
  }
}

/// One conversation: the office, the last line, the time and the unread
/// count, read out as one row.
class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.row});

  final AccountInboxRow row;

  @override
  Widget build(BuildContext context) {
    final int? count = int.tryParse(row.badge ?? '');
    final bool unread = count != null && count > 0;
    return SettingsRow(
      title: row.office,
      detail: row.preview,
      detailMaxLines: 2,
      icon: row.icon,
      iconFill: row.tile,
      iconInk: row.iconColor,
      onTap: row.onTap,
      semanticLabel: <String>[
        row.office,
        row.preview,
        row.when,
        if (unread) '$count new',
      ].join(', '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            row.when,
            style: AppTypography.small.copyWith(
              color: unread ? BrandColors.blue : BrandColors.muted,
              fontWeight: unread ? AppTypography.strong : null,
            ),
          ),
          if (unread) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            CountBadge(count: count),
          ],
        ],
      ),
    );
  }
}

/// A page that failed to load more: the sentence and Retry, in a soft note.
class _MoreRetry extends StatelessWidget {
  const _MoreRetry({
    required this.message,
    required this.onRetry,
    required this.retryKey,
  });

  final String message;
  final VoidCallback onRetry;
  final Key retryKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SoftNote(message: message, tone: NoteTone.error),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: retryKey,
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({this.onMessageOffice});

  final VoidCallback? onMessageOffice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        EmptyState(
          title: 'No messages yet',
          message:
              'Questions you send to municipal offices and their replies '
              'will appear here.',
          actionLabel: 'Message an office',
          onAction: onMessageOffice,
          boxed: true,
          primaryAction: true,
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Messaging is available to verified residents.',
          textAlign: TextAlign.center,
          style: AppTypography.small.copyWith(color: BrandColors.muted),
        ),
      ],
    );
  }
}

class _InboxError extends StatelessWidget {
  const _InboxError({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: <Widget>[
        ErrorState(
          title: 'Messages did not load',
          message: 'Taytay LGU could not be reached. You can try again.',
          onRetry: onRetry,
          retryLabel: 'Retry',
          offline: true,
          boxed: true,
        ),
      ],
    );
  }
}

/// RegDetails: the wave header over the white page, the filled fields, and
/// Save in the footer.
class _EditPage extends StatelessWidget {
  const _EditPage({required this.canvas});

  final AccountCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final List<AccountField> fields = canvas.fields;
    final bool legalLine =
        canvas.showLegalNameNote &&
        !fields.any((AccountField field) => field.label == 'Display name');
    return AuthFormPage(
      title: canvas.title,
      onBack: canvas.onBack,
      footer: canvas.loading
          ? null
          : FilledButton(
              onPressed: canvas.onSave,
              child: const Text('Save changes'),
            ),
      child: canvas.loading
          ? const LoadingSkeleton(
              layout: SkeletonLayout.detail,
              semanticLabel: 'Loading your profile',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PhotoNote(initials: canvas.initials),
                const SizedBox(height: Spacing.formGap),
                if (legalLine) ...<Widget>[
                  _LegalNameNote(onTap: canvas.onLegalName),
                  const SizedBox(height: Spacing.formGap),
                ],
                for (var i = 0; i < fields.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: Spacing.formGap),
                  _EditField(field: fields[i]),
                  if (fields[i].label == 'Display name' &&
                      canvas.showLegalNameNote) ...<Widget>[
                    const SizedBox(height: Spacing.sm),
                    _LegalNameNote(onTap: canvas.onLegalName),
                  ],
                ],
              ],
            ),
    );
  }
}

/// The initials disc and the photo sentence above the form.
class _PhotoNote extends StatelessWidget {
  const _PhotoNote({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      filled: true,
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: <Widget>[
          Semantics(
            image: true,
            label: 'Profile photo',
            child: Container(
              width: ComponentSizes.avatar,
              height: ComponentSizes.avatar,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: BrandColors.blue,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Text(
                  initials,
                  style: AppTypography.listTitle.copyWith(
                    fontWeight: AppTypography.black,
                    color: BrandColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              'Profile photo · reviewed by LGU before it appears on your ID',
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CSS `.fld` + `.inp`: the label above a filled field. A field with a
/// controller is typed into; one without is a value the resident reads, or
/// opens a picker when it has [AccountField.onTap].
class _EditField extends StatelessWidget {
  const _EditField({required this.field});

  final AccountField field;

  @override
  Widget build(BuildContext context) {
    final TextEditingController? controller = field.controller;
    final String? note = field.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthFieldLabel(field.label),
        const SizedBox(height: Spacing.sm),
        if (controller != null)
          TextField(
            controller: controller,
            onChanged: field.onChanged,
            maxLines: 1,
            style: AppTypography.fieldValue.copyWith(color: BrandColors.ink),
            decoration: InputDecoration(
              suffixIcon: field.verified
                  ? const Padding(
                      padding: EdgeInsets.only(right: Spacing.md),
                      child: _VerifiedPill(),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(),
            ),
          )
        else
          _ValueBox(field: field),
        if (note != null) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          Text(
            note,
            style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
          ),
        ],
      ],
    );
  }
}

/// A filled field that is not typed into: a locked value or a picker.
class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.field});

  final AccountField field;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = field.onTap;
    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ComponentSizes.fieldHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                field.value,
                style: AppTypography.fieldValue.copyWith(
                  color: field.locked ? BrandColors.text : BrandColors.ink,
                ),
              ),
            ),
            if (field.verified) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              const _VerifiedPill(),
            ],
            if (field.locked) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              const TaytayIcon(
                icon: TaytayIcons.lock,
                size: IconSizes.sm,
                color: BrandColors.chevron,
                semanticLabel: 'Cannot be changed here',
              ),
            ],
            if (field.chevron) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              const TaytayIcon(
                icon: TaytayIcons.chevronDown,
                size: IconSizes.sm,
                color: BrandColors.chevron,
                semanticLabel: '',
                excludeSemantics: true,
              ),
            ],
          ],
        ),
      ),
    );
    final BorderRadius corners = BorderRadius.circular(Radii.field);
    return Material(
      color: BrandColors.softFill,
      borderRadius: corners,
      child: onTap == null
          ? row
          : InkWell(
              borderRadius: corners,
              onTap: onTap,
              child: Semantics(button: true, child: row),
            ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: BrandColors.green50,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
        child: Text(
          'Verified',
          style: AppTypography.pill.copyWith(color: BrandColors.green),
        ),
      ),
    );
  }
}

class _LegalNameNote extends StatelessWidget {
  const _LegalNameNote({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget text = Text(
      'Legal name changes go through Resident Profile and re-verification.',
      style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
    );
    final VoidCallback? onTap = this.onTap;
    if (onTap == null) return text;
    return InkWell(onTap: onTap, child: text);
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.toggles,
    this.onLanguage,
    this.onChangePassword,
    this.changePasswordSubtitle = '',
    this.onPrivacy,
    this.onConsents,
    this.onExport,
    this.showDataExport = true,
  });

  final List<AccountToggle> toggles;
  final VoidCallback? onLanguage;
  final VoidCallback? onChangePassword;
  final String changePasswordSubtitle;
  final VoidCallback? onPrivacy;
  final VoidCallback? onConsents;
  final VoidCallback? onExport;
  final bool showDataExport;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        if (toggles.isNotEmpty) ...<Widget>[
          const SettingsSectionTitle('Notifications'),
          SettingsList(
            children: <Widget>[
              for (final AccountToggle toggle in toggles)
                SettingsSwitchRow(
                  title: toggle.title,
                  detail: toggle.subtitle,
                  icon: toggle.icon,
                  iconFill: toggle.tile,
                  iconInk: toggle.iconColor,
                  value: toggle.on || toggle.locked,
                  onChanged: toggle.locked ? null : toggle.onChanged,
                ),
            ],
          ),
          const SizedBox(height: Spacing.xl),
        ],
        const SettingsSectionTitle('App'),
        SettingsList(
          children: <Widget>[
            SettingsRow(
              title: 'Language',
              detail: 'English · Filipino',
              icon: TaytayIcons.languages,
              onTap: onLanguage,
            ),
            SettingsRow(
              title: 'Change password',
              detail: changePasswordSubtitle,
              icon: TaytayIcons.lock,
              onTap: onChangePassword,
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const SettingsSectionTitle('Privacy'),
        SettingsList(
          children: <Widget>[
            SettingsRow(
              title: 'Privacy Notice',
              detail: 'Data Privacy Act of 2012 · LGU-approved text pending',
              icon: TaytayIcons.fileText,
              onTap: onPrivacy,
            ),
            if (onConsents != null)
              SettingsRow(
                title: 'Your consents',
                detail: 'Review or withdraw what you agreed to',
                icon: TaytayIcons.shieldCheck,
                onTap: onConsents,
              ),
            if (showDataExport)
              SettingsRow(
                title: 'Request a copy of my data',
                detail: 'Right to access',
                icon: TaytayIcons.download,
                onTap: onExport,
              ),
          ],
        ),
      ],
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody({required this.credits, this.onBanners});

  final List<PhotoCredit> credits;
  final VoidCallback? onBanners;

  @override
  Widget build(BuildContext context) {
    final List<PhotoCredit> welcome = credits
        .where((PhotoCredit credit) => credit.welcome)
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        SoftCard(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            children: <Widget>[
              const SizedBox(
                width: ComponentSizes.tileLarge,
                height: ComponentSizes.tileLarge,
                child: Image(
                  image: AssetImage('assets/brand/taytay_seal.png'),
                  fit: BoxFit.contain,
                  semanticLabel: 'Seal of Taytay, Rizal',
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'Taytay Resident App',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  fontWeight: AppTypography.strong,
                  color: BrandColors.ink,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Municipality of Taytay, Rizal · version $appVersion',
                textAlign: TextAlign.center,
                style: AppTypography.listDetail.copyWith(
                  color: BrandColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (welcome.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.xl),
          const SettingsSectionTitle('Photo credits'),
          SettingsList(
            children: <Widget>[
              for (final PhotoCredit credit in welcome)
                _CreditRow(credit: credit),
            ],
          ),
        ],
        const SizedBox(height: Spacing.section),
        SettingsList(
          children: <Widget>[
            SettingsRow(
              title: 'Office banner photos',
              detail: PhotoCredits.officeBannerSummary,
              icon: TaytayIcons.images,
              onTap: onBanners,
            ),
          ],
        ),
        const SizedBox(height: Spacing.xl),
        const SettingsSectionTitle('About'),
        const SettingsList(
          children: <Widget>[
            SettingsRow(
              title: 'Municipal seal',
              detail: 'Described on taytayrizal.gov.ph/seal · Wikimedia',
              icon: TaytayIcons.shield,
            ),
          ],
        ),
      ],
    );
  }
}

/// One credited photograph: its title, then the byline on its own line.
class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.credit});

  final PhotoCredit credit;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      title: credit.title,
      detail: credit.byline,
      icon: TaytayIcons.image,
      trailing: const TaytayIcon(
        icon: TaytayIcons.externalLink,
        size: IconSizes.sm - Spacing.xxs,
        color: BrandColors.blue,
        semanticLabel: '',
        excludeSemantics: true,
      ),
    );
  }
}

/// RegTerms: the wave header over the white page and the notice summary.
/// A published notice replaces the bundled draft, which only a
/// non-production build shows; production without one says it is coming.
class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage({required this.canvas});

  final AccountCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final String? markdown = canvas.noticeMarkdown;
    final Widget body;
    if (canvas.loading) {
      body = const LoadingSkeleton(
        layout: SkeletonLayout.detail,
        semanticLabel: 'Loading the privacy notice',
      );
    } else if (markdown != null) {
      body = _PublishedNotice(markdown: markdown);
    } else if (canvas.showBundledDraft) {
      body = _PrivacyBody(
        onExport: canvas.onExport,
        showDataExport: canvas.showDataExport,
      );
    } else {
      body = const _NoticePending();
    }
    return AuthFormPage(
      title: canvas.title,
      onBack: canvas.onBack,
      child: body,
    );
  }
}

const String _noticeSource = 'Republic Act No. 10173, Data Privacy Act of 2012';

/// The bundled draft, marked as one, with the data-export button when the
/// API offers it.
class _PrivacyBody extends StatelessWidget {
  const _PrivacyBody({this.onExport, this.showDataExport = true});

  final VoidCallback? onExport;
  final bool showDataExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const NoticePanel(
          title: 'Privacy Notice',
          subtitle: _noticeSource,
          icon: TaytayIcons.shieldCheck,
          badge: DraftPill('DRAFT · LGU-approved text to be inserted'),
          points: <NoticePoint>[
            NoticePoint(
              title: 'What we collect',
              body:
                  'Name, contact details, address, valid ID and selfie, and '
                  'messages you send to offices.',
            ),
            NoticePoint(
              title: 'Why',
              body:
                  'To verify that you are a Taytay resident and to deliver '
                  'the services you request.',
            ),
            NoticePoint(
              title: 'Who can see it',
              body:
                  'Authorised LGU staff of the office you deal with. Not sold '
                  'or shared for marketing.',
            ),
            NoticePoint(
              title: 'Your rights',
              body:
                  'Access, correction, objection and erasure. Contact the LGU '
                  'Data Protection Officer',
              trailing: SampleTag(),
              suffix: '.',
            ),
          ],
        ),
        if (showDataExport) ...<Widget>[
          const SizedBox(height: Spacing.lg),
          FilledButton.tonalIcon(
            onPressed: onExport,
            icon: const TaytayIcon(
              icon: TaytayIcons.download,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
            ),
            label: const Text('Request a copy of my data'),
          ),
        ],
      ],
    );
  }
}

/// The notice the LGU published (`body_markdown`), drawn line by line.
class _PublishedNotice extends StatelessWidget {
  const _PublishedNotice({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final List<NoticeLine> lines = parseNoticeMarkdown(markdown);
    final TextStyle body = AppTypography.bodyStyle.copyWith(
      color: BrandColors.text,
      height: 1.55,
    );
    final TextStyle heading = AppTypography.listTitle.copyWith(
      fontWeight: AppTypography.strong,
      color: BrandColors.ink,
    );
    return NoticePanel(
      title: 'Privacy Notice',
      subtitle: _noticeSource,
      icon: TaytayIcons.shieldCheck,
      footer: SoftCard(
        radius: Radii.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var i = 0; i < lines.length; i++) ...<Widget>[
              if (i > 0)
                SizedBox(height: lines[i].heading ? Spacing.md : Spacing.sm),
              Semantics(
                header: lines[i].heading,
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      if (lines[i].bullet) TextSpan(text: '• ', style: body),
                      for (final NoticeRun run in lines[i].runs)
                        TextSpan(
                          text: run.text,
                          style: lines[i].heading
                              ? heading
                              : body.copyWith(
                                  fontWeight: run.strong
                                      ? AppTypography.strong
                                      : null,
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoticePending extends StatelessWidget {
  const _NoticePending();

  @override
  Widget build(BuildContext context) {
    return const NoticePanel(
      title: 'Privacy Notice',
      subtitle: _noticeSource,
      icon: TaytayIcons.shieldCheck,
      intro:
          'The privacy notice will appear here when Taytay LGU publishes it.',
    );
  }
}

class _BannersBody extends StatelessWidget {
  const _BannersBody({required this.credits});

  final List<PhotoCredit> credits;

  @override
  Widget build(BuildContext context) {
    final List<PhotoCredit> rows = credits
        .where((PhotoCredit credit) => credit.officeBanner)
        .toList(growable: false);
    final TextStyle intro = AppTypography.bodyStyle.copyWith(
      color: BrandColors.text,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        Text.rich(
          TextSpan(
            style: intro,
            children: const <InlineSpan>[
              TextSpan(text: 'All from Wikimedia Commons. Photos marked '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _ReplaceMark(),
              ),
              TextSpan(
                text:
                    ' show people and are placeholders until Taytay LGU '
                    'supplies its own consented photos.',
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.section),
        if (rows.isNotEmpty)
          SettingsList(
            children: <Widget>[
              for (final PhotoCredit credit in rows) _BannerRow(credit: credit),
            ],
          ),
      ],
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({required this.credit});

  final PhotoCredit credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.section,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  credit.offices.join(', ').toUpperCase(),
                  style: AppTypography.category.copyWith(
                    color: BrandColors.blue,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  credit.title,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  credit.byline,
                  style: AppTypography.listDetail.copyWith(
                    color: BrandColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (credit.replace) ...<Widget>[
            const SizedBox(width: Spacing.md),
            const _ReplaceMark(),
          ],
        ],
      ),
    );
  }
}

/// The gold "Replace" pill on a placeholder photo of people.
class _ReplaceMark extends StatelessWidget {
  const _ReplaceMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: BrandColors.gold50,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xxs,
        ),
        child: Text(
          'Replace',
          style: AppTypography.pill.copyWith(color: BrandColors.goldInk),
        ),
      ),
    );
  }
}

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({
    required this.bubbles,
    required this.dayLabel,
    required this.showSampleNote,
    this.onSend,
    this.sendEnabled = true,
    this.composer,
    this.onAttach,
    this.closed = false,
    this.hideComposer = false,
    this.attachmentLabel,
    this.onClearAttachment,
    this.onUseMedia,
    this.onNearStart,
    this.moreMessage,
    this.onMoreRetry,
  });

  final List<AccountBubble> bubbles;
  final String dayLabel;
  final bool showSampleNote;
  final VoidCallback? onSend;
  final bool sendEnabled;
  final TextEditingController? composer;
  final VoidCallback? onAttach;
  final bool closed;
  final bool hideComposer;
  final String? attachmentLabel;
  final VoidCallback? onClearAttachment;
  final ValueChanged<String>? onUseMedia;
  final VoidCallback? onNearStart;
  final String? moreMessage;
  final VoidCallback? onMoreRetry;

  bool get _live =>
      hideComposer ||
      composer != null ||
      onAttach != null ||
      onNearStart != null ||
      onUseMedia != null ||
      closed ||
      attachmentLabel != null ||
      moreMessage != null;

  @override
  Widget build(BuildContext context) {
    if (_live) return _liveColumn();
    return _specimenColumn();
  }

  Widget _specimenColumn() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              S8Space.gutter,
              S8Space.threadInset,
              S8Space.gutter,
              S8Space.labelGap,
            ),
            children: <Widget>[
              if (dayLabel.isNotEmpty) Center(child: _Chip(dayLabel)),
              if (dayLabel.isNotEmpty) const SizedBox(height: S8Space.dayGap),
              for (final AccountBubble bubble in bubbles)
                _Bubble(bubble: bubble),
              if (showSampleNote) const _SampleConversation(),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: BrandColors.cardLine)),
          ),
          child: Row(
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.paperclip,
                size: 20,
                color: BrandColors.listMeta,
                semanticLabel: 'Attach',
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: SizedBox(
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F8FC),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Write a message…', style: _hint),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ComposerSend(onTap: onSend),
            ],
          ),
        ),
      ],
    );
  }

  Widget _liveColumn() {
    final Widget transcript = ListView(
      padding: const EdgeInsets.fromLTRB(
        S8Space.gutter,
        S8Space.threadInset,
        S8Space.gutter,
        S8Space.labelGap,
      ),
      children: <Widget>[
        if (moreMessage != null && onMoreRetry != null)
          _LoadMoreRetry(
            message: moreMessage!,
            onRetry: onMoreRetry!,
            retryKey: const Key('thread-load-more-retry'),
          ),
        if (dayLabel.isNotEmpty) Center(child: _Chip(dayLabel)),
        if (dayLabel.isNotEmpty) const SizedBox(height: S8Space.dayGap),
        for (final AccountBubble bubble in bubbles)
          _Bubble(bubble: bubble, onUseMedia: onUseMedia),
        if (showSampleNote) const _SampleConversation(),
      ],
    );
    final VoidCallback? onNearStart = this.onNearStart;
    return Column(
      children: <Widget>[
        Expanded(
          child: onNearStart == null
              ? transcript
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notice) {
                    final ScrollMetrics metrics = notice.metrics;
                    if (metrics.maxScrollExtent <= 0) return false;
                    if (metrics.pixels < 480) onNearStart();
                    return false;
                  },
                  child: transcript,
                ),
        ),
        if (!hideComposer)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: BrandColors.cardLine)),
            ),
            child: closed ? const _ClosedLine() : _liveComposer(),
          ),
      ],
    );
  }

  Widget _liveComposer() {
    final String? label = attachmentLabel;
    final Widget row = Row(
      children: <Widget>[
        _AttachControl(onTap: onAttach),
        const SizedBox(width: 10),
        Expanded(child: _ComposerField(controller: composer)),
        const SizedBox(width: 10),
        _ComposerSend(onTap: onSend, enabled: sendEnabled),
      ],
    );
    if (label == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _hint,
              ),
            ),
            if (onClearAttachment != null)
              _ClearAttachment(onTap: onClearAttachment!),
          ],
        ),
        const SizedBox(height: 8),
        row,
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.bubble, this.onUseMedia});

  final AccountBubble bubble;
  final ValueChanged<String>? onUseMedia;

  @override
  Widget build(BuildContext context) {
    final bool mine = bubble.fromResident;
    final TextStyle style = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 13,
      height: S8Space.threadLineHeight,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      leadingDistribution: TextLeadingDistribution.even,
      color: mine ? Colors.white : BrandColors.textPrimary,
      decoration: TextDecoration.none,
    );
    final Widget words = _CssLines(
      text: bubble.body,
      style: style,
      step: 13 * S8Space.threadLineHeight,
    );
    final Widget content = bubble.mediaIds.isEmpty
        ? words
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (bubble.body.isNotEmpty) words,
              for (final String mediaId in bubble.mediaIds)
                _MediaChip(mediaId: mediaId, mine: mine, onTap: onUseMedia),
            ],
          );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: S8Space.bubbleMaxWidth,
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: S8Space.bubbleMaxWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: S8Space.bubblePadX,
                vertical: S8Space.bubblePadY,
              ),
              decoration: BoxDecoration(
                color: mine ? BrandColors.taytayBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                border: mine
                    ? null
                    : Border.all(
                        color: BrandColors.cardLine,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
              ),
              child: content,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
              child: SizedBox(
                height: S8Space.line(11),
                child: Text(
                  bubble.when,
                  style: _time,
                  textHeightBehavior: S8Space.lineBox,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFEEF1F6),
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: S8Space.dayPadX,
          vertical: S8Space.dayPadY,
        ),
        child: SizedBox(
          height: S8Space.line(11),
          child: Text(label, style: _day, textHeightBehavior: S8Space.lineBox),
        ),
      ),
    );
  }
}

class _ClosedLine extends StatelessWidget {
  const _ClosedLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('This conversation is closed.', style: _hint),
      ),
    );
  }
}

class _LoadMoreRetry extends StatelessWidget {
  const _LoadMoreRetry({
    required this.message,
    required this.onRetry,
    required this.retryKey,
  });

  final String message;
  final VoidCallback onRetry;
  final Key retryKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrandColors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          Semantics(
            button: true,
            label: 'Retry',
            child: GestureDetector(
              key: retryKey,
              behavior: HitTestBehavior.opaque,
              onTap: onRetry,
              child: const SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.taytayBlue,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachControl extends StatelessWidget {
  const _AttachControl({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const Widget icon = TaytayIcon(
      icon: TaytayIcons.paperclip,
      size: 20,
      color: BrandColors.listMeta,
      semanticLabel: 'Attach',
    );
    final VoidCallback? onTap = this.onTap;
    if (onTap == null) return icon;
    return SizedBox(
      width: 20,
      height: 20,
      child: OverflowBox(
        maxWidth: 48,
        maxHeight: 48,
        child: Semantics(
          button: true,
          label: 'Attach photo or PDF',
          child: GestureDetector(
            key: const Key('account-thread-attach'),
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: TaytayIcon(
                  icon: TaytayIcons.paperclip,
                  size: 20,
                  color: BrandColors.listMeta,
                  semanticLabel: '',
                  excludeSemantics: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerField extends StatelessWidget {
  const _ComposerField({required this.controller});

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final TextEditingController? controller = this.controller;
    const BoxDecoration decoration = BoxDecoration(
      color: Color(0xFFF6F8FC),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    if (controller == null) {
      return const SizedBox(
        height: 44,
        child: DecoratedBox(
          decoration: decoration,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Write a message…', style: _hint),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              key: const Key('account-thread-field'),
              controller: controller,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: S8Space.normal,
                color: BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
              cursorColor: BrandColors.taytayBlue,
              decoration: const InputDecoration(
                isCollapsed: true,
                isDense: true,
                filled: false,
                hintText: 'Write a message…',
                hintStyle: _hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearAttachment extends StatelessWidget {
  const _ClearAttachment({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove attachment',
      child: GestureDetector(
        key: const Key('account-thread-clear-attachment'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: TaytayIcon(
              icon: TaytayIcons.close,
              size: 16,
              color: BrandColors.listMeta,
              semanticLabel: '',
              excludeSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaChip extends StatelessWidget {
  const _MediaChip({required this.mediaId, required this.mine, this.onTap});

  final String mediaId;
  final bool mine;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = mine ? Colors.white : BrandColors.textPrimary;
    final ValueChanged<String>? onTap = this.onTap;
    return Semantics(
      button: onTap != null,
      label: 'Attachment',
      child: GestureDetector(
        key: Key('thread-media-$mediaId'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap(mediaId),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: <Widget>[
              TaytayIcon(
                icon: TaytayIcons.fileText,
                size: 16,
                color: ink,
                semanticLabel: '',
                excludeSemantics: true,
              ),
              const SizedBox(width: 8),
              Text(
                'Attachment',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerSend extends StatelessWidget {
  const _ComposerSend({this.onTap, this.enabled = true});

  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // The painted disc is 44 dp, which is the composer dark run. The hit
    // overflows to 48 without growing the row. A send in flight keeps that
    // disc and drops the ink so the control reads as disabled.
    final Widget button = SizedBox(
      width: 44,
      height: 44,
      child: OverflowBox(
        maxWidth: 48,
        maxHeight: 48,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: 'Send',
          child: GestureDetector(
            key: const Key('account-thread-send'),
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.taytayBlue,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: TaytayIcon(
                      icon: TaytayIcons.send,
                      size: 18,
                      color: Colors.white,
                      semanticLabel: '',
                      excludeSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (enabled) return button;
    return Opacity(opacity: Opacities.disabled, child: button);
  }
}

const TextStyle _meta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

/// Thread timestamp. CSS `.tm` is 11 / 400 `#5F6880`.
const Color _timeInk = Color(0xFF5F6880);

const TextStyle _day = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  letterSpacing: 0,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _time = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: _timeInk,
  decoration: TextDecoration.none,
);

const TextStyle _hint = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.fieldHint,
  decoration: TextDecoration.none,
);

double _spanWidth(String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
    textHeightBehavior: S8Space.lineBox,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}

/// `.sample` border box. Padding 7 and a 1 px border, each side.
double _sampleChipWidth() {
  return _spanWidth(
        'SAMPLE',
        AppTypography.labelStrong.copyWith(letterSpacing: 0.6),
      ) +
      16;
}

/// 11 px `normal` SAMPLE chip, for a `vertical-align: middle` line.
class _NormalSample extends StatelessWidget {
  const _NormalSample();

  @override
  Widget build(BuildContext context) {
    return SampleTag(lineHeight: S8Space.normal, lineSlot: S8Space.line(11));
  }
}

/// One inline line. A chip uses CSS `vertical-align: middle`.
///
/// Chrome centres the chip on the parent's baseline plus half the x-height.
/// The parent's strut stays at the top of the line. The line grows downward
/// when the chip hangs below that strut.
class _MiddleLine extends StatelessWidget {
  const _MiddleLine({
    required this.text,
    required this.style,
    this.chip,
    this.trailing = '',
    this.trailingStyle,
    this.centered = false,
  });

  final String text;
  final TextStyle style;
  final Widget? chip;
  final String trailing;
  final TextStyle? trailingStyle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final double fontSize = style.fontSize ?? 16;
    final FontWeight weight = style.fontWeight ?? FontWeight.w400;
    final double strut = S8Space.line(fontSize);
    final Widget? chip = this.chip;
    final double chipHeight = chip == null ? 0 : S8Space.sampleChipHeight;
    final double chipTop = chip == null
        ? 0
        : S8Space.middleTop(
            fontSize: fontSize,
            weight: weight,
            boxHeight: chipHeight,
          );
    final double shift = math.max(0.0, -chipTop);
    final double height = math.max(strut, chipTop + chipHeight) + shift;
    final TextStyle trailStyle = trailingStyle ?? style;
    final double trailSize = trailStyle.fontSize ?? fontSize;
    final double trailHeight = S8Space.line(trailSize);
    final double trailTop =
        shift + S8Space.ascender(fontSize) - S8Space.ascender(trailSize);
    final bool gap = chip != null && trailing.isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double leadWidth = text.isEmpty ? 0 : _spanWidth(text, style);
        final double chipWidth = chip == null ? 0 : _sampleChipWidth();
        final double spaceWidth = gap ? _spanWidth(' ', style) : 0;
        final double trailWidth = trailing.isEmpty
            ? 0
            : _spanWidth(
                trailing,
                trailStyle.copyWith(height: trailHeight / trailSize),
              );
        final double used = leadWidth + chipWidth + spaceWidth + trailWidth;
        final double dx = centered
            ? math.max(0.0, (constraints.maxWidth - used) / 2)
            : 0;
        var x = dx;
        final List<Widget> children = <Widget>[];
        void place(double width, double top, double box, Widget child) {
          children.add(
            Positioned(
              left: x,
              top: top,
              width: width,
              height: box,
              child: child,
            ),
          );
          x += width;
        }

        if (text.isNotEmpty) {
          place(
            leadWidth,
            shift,
            strut,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: style,
                textHeightBehavior: S8Space.lineBox,
              ),
            ),
          );
        }
        if (chip != null) {
          place(chipWidth, shift + chipTop, chipHeight, chip);
        }
        if (gap) {
          place(spaceWidth, shift, strut, const SizedBox.shrink());
        }
        if (trailing.isNotEmpty) {
          place(
            trailWidth,
            trailTop,
            trailHeight,
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                trailing,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: trailStyle.copyWith(
                  height: trailHeight / trailSize,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                textHeightBehavior: S8Space.lineBox,
              ),
            ),
          );
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
  }
}

/// "SAMPLE conversation for illustration" under a thread.
///
/// The timestamp's margin-bottom is 12 and this line's margin-top is 6.
/// Those collapse, and the 12 already sits in the timestamp padding. The
/// parent face is the body 16 px. The caption sits on that baseline, and
/// the gap is one space in that face.
class _SampleConversation extends StatelessWidget {
  const _SampleConversation();

  @override
  Widget build(BuildContext context) {
    return const _MiddleLine(
      text: '',
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: S8Space.normal,
        leadingDistribution: TextLeadingDistribution.even,
        decoration: TextDecoration.none,
      ),
      chip: _NormalSample(),
      trailing: 'conversation for illustration',
      trailingStyle: _meta,
      centered: true,
    );
  }
}

/// Paints [text] on Chrome's line step.
///
/// Flutter rounds a fractional strut to a whole logical pixel. The slot keeps
/// the CSS advance, and each line is placed at that step.
class _CssLines extends StatelessWidget {
  const _CssLines({
    required this.text,
    required this.style,
    required this.step,
  });

  final String text;
  final TextStyle style;
  final double step;
  TextAlign get align => TextAlign.start;
  int? get maxLines => null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final TextPainter painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textAlign: align,
          textScaler: TextScaler.noScaling,
          textHeightBehavior: S8Space.lineBox,
          strutStyle: S8Space.strut(
            style.fontSize ?? 14,
            height: style.height,
            weight: style.fontWeight,
          ),
          maxLines: maxLines,
          ellipsis: maxLines == null ? null : '…',
        )..layout(maxWidth: width);
        final List<String> lines = <String>[];
        var start = 0;
        final String laid = text;
        while (start < laid.length &&
            (maxLines == null || lines.length < maxLines!)) {
          final TextRange range = painter.getLineBoundary(
            TextPosition(offset: start),
          );
          if (range.end <= start) {
            break;
          }
          lines.add(laid.substring(range.start, range.end).trimRight());
          start = range.end;
          // getLineBoundary stays on the line that owns a hard break, so
          // step past the newline before asking for the next line.
          while (start < laid.length &&
              (laid.codeUnitAt(start) == 10 || laid.codeUnitAt(start) == 13)) {
            start += 1;
          }
        }
        painter.dispose();
        if (lines.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: width,
          height: step * lines.length,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (var i = 0; i < lines.length; i++)
                Positioned(
                  top: step * i,
                  left: 0,
                  right: 0,
                  height: step,
                  child: Align(
                    alignment: align == TextAlign.center
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: Text(
                      lines[i],
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      textAlign: align,
                      style: style,
                      textHeightBehavior: S8Space.lineBox,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
