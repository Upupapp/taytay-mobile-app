import 'package:flutter/material.dart';

import '../../../core/config/app_version.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/conversation.dart';
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
        // No per-item repaint / semantics wrappers: they hit-test only their
        // own box, so the strip GlassOverlap raises over the header would not
        // take a tap.
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
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
        // A gesture detector, not a TextButton: tests (and screen readers)
        // read the one control under [retryKey].
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            button: true,
            label: 'Retry',
            excludeSemantics: true,
            child: GestureDetector(
              key: retryKey,
              behavior: HitTestBehavior.opaque,
              onTap: onRetry,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: A11y.minTapTarget,
                  minHeight: A11y.minTapTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Retry',
                      style: AppTypography.link.copyWith(
                        color: BrandColors.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: BrandColors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
    // Every credit here is a bundled photograph's, from the asset manifest:
    // the API sends no image credit (design/PROGRESS "API fields needed"), so
    // a photo it serves is not listed. A list with nothing in it is not drawn.
    final List<PhotoCredit> welcome = credits
        .where((PhotoCredit credit) => credit.welcome)
        .toList(growable: false);
    final List<PhotoCredit> banners = credits
        .where((PhotoCredit credit) => credit.officeBanner)
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
        if (banners.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.section),
          SettingsList(
            children: <Widget>[
              SettingsRow(
                title: 'Office banner photos',
                detail: PhotoCredits.bannerSummaryOf(banners),
                icon: TaytayIcons.images,
                onTap: onBanners,
              ),
            ],
          ),
        ],
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

/// `Conversation.dc.html`: the messages as a log of bubbles over the soft
/// page, and the composer under them. A closed thread says so where the
/// composer was; a thread whose first read failed shows neither.
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

  @override
  Widget build(BuildContext context) {
    final String? moreMessage = this.moreMessage;
    final VoidCallback? onMoreRetry = this.onMoreRetry;
    final Widget transcript = Semantics(
      container: true,
      label: 'Conversation',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.section,
          Spacing.lg,
          Spacing.sm,
        ),
        children: <Widget>[
          if (moreMessage != null && onMoreRetry != null) ...<Widget>[
            _MoreRetry(
              message: moreMessage,
              onRetry: onMoreRetry,
              retryKey: const Key('thread-load-more-retry'),
            ),
            const SizedBox(height: Spacing.md),
          ],
          if (dayLabel.isNotEmpty) ...<Widget>[
            ConversationDayChip(dayLabel),
            const SizedBox(height: Spacing.md),
          ],
          for (final AccountBubble bubble in bubbles)
            ConversationBubble(
              body: bubble.body,
              meta: bubble.when,
              mine: bubble.fromResident,
              attachments: <Widget>[
                for (final String mediaId in bubble.mediaIds)
                  _MediaChip(
                    mediaId: mediaId,
                    mine: bubble.fromResident,
                    onTap: onUseMedia,
                  ),
              ],
            ),
          if (showSampleNote) ...<Widget>[
            const SizedBox(height: Spacing.xs),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Spacing.xs + Spacing.xxs,
                children: <Widget>[
                  const SampleTag(),
                  Text(
                    'conversation for illustration',
                    style: AppTypography.small.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    final VoidCallback? onNearStart = this.onNearStart;
    final Widget log = onNearStart == null
        ? transcript
        : NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notice) {
              final ScrollMetrics metrics = notice.metrics;
              if (metrics.maxScrollExtent <= 0) return false;
              if (metrics.pixels < 480) onNearStart();
              return false;
            },
            child: transcript,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: log),
        if (closed)
          const _ClosedLine()
        else if (!hideComposer)
          ConversationComposer(
            controller: composer,
            onAttach: onAttach,
            onSend: onSend,
            sendEnabled: sendEnabled,
            attachmentLabel: attachmentLabel,
            onClearAttachment: onClearAttachment,
            attachKey: const Key('account-thread-attach'),
            sendKey: const Key('account-thread-send'),
            fieldKey: const Key('account-thread-field'),
            clearKey: const Key('account-thread-clear-attachment'),
          ),
      ],
    );
  }
}

/// Where the composer was, on a thread the office closed.
class _ClosedLine extends StatelessWidget {
  const _ClosedLine();

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: BrandColors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.lg + Spacing.xs + safeBottom,
        ),
        child: Row(
          children: <Widget>[
            const TaytayIcon(
              icon: TaytayIcons.lock,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.muted,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'This conversation is closed.',
                style: AppTypography.bodyStyle.copyWith(
                  color: BrandColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A file in a message: opened through [onTap] with its media id.
class _MediaChip extends StatelessWidget {
  const _MediaChip({required this.mediaId, required this.mine, this.onTap});

  final String mediaId;
  final bool mine;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<String>? onTap = this.onTap;
    final Color ink = mine ? BrandColors.white : BrandColors.blue;
    return Semantics(
      button: onTap != null,
      label: 'Attachment',
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('thread-media-$mediaId'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap(mediaId),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TaytayIcon(
                icon: TaytayIcons.paperclip,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: ink,
              ),
              const SizedBox(width: Spacing.sm),
              Flexible(
                child: Text(
                  'Attachment',
                  style: AppTypography.listTitle.copyWith(
                    color: ink,
                    decoration: TextDecoration.underline,
                    decorationColor: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
