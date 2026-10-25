import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tile;
  final Color iconColor;

  /// A count drawn on the row, such as the Messages `1`.
  final String? badge;
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
  });

  final String body;
  final String when;
  final bool fromResident;
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
  });

  final String label;
  final String value;
  final bool verified;
  final bool chevron;

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

/// My Account, painted to the 08-01 … 08-10 frames.
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
    this.name = 'Juana Dela Cruz',
    this.initials = 'JD',
    this.location = 'Brgy. San Juan, Taytay, Rizal',
    this.verifiedLabel = 'Verified',
    this.sample = true,
    this.menu = AccountSpecimen.homeMenu,
    this.onSignOut,
    this.inbox = AccountSpecimen.inbox,
    this.showSampleNote = true,
    this.onInboxRetry,
    this.onMessageOffice,
    this.fields = AccountSpecimen.fields,
    this.onSave,
    this.onLegalName,
    this.toggles = AccountSpecimen.toggles,
    this.onLanguage,
    this.onChangePassword,
    this.changePasswordSubtitle = '',
    this.onPrivacy,
    this.onBanners,
    this.onExport,
    this.showDataExport = true,
    this.noticeMarkdown,
    this.showBundledDraft = true,
    this.bubbles = AccountSpecimen.mswdoBubbles,
    this.dayLabel = 'Mon',
    this.onSend,
    this.credits = PhotoCredits.all,
    super.key,
  });

  final AccountFrame frame;
  final String title;
  final String subtitle;
  final int subtitleLines;
  final bool showBack;
  final bool showBell;
  final VoidCallback? onBack;
  final VoidCallback? onBell;
  final String name;
  final String initials;
  final String location;
  final String verifiedLabel;
  final bool sample;
  final List<AccountMenuRow> menu;
  final VoidCallback? onSignOut;
  final List<AccountInboxRow> inbox;

  /// The SAMPLE illustration line. Live screens pass `usesMockData`.
  final bool showSampleNote;
  final VoidCallback? onInboxRetry;
  final VoidCallback? onMessageOffice;
  final List<AccountField> fields;
  final VoidCallback? onSave;
  final VoidCallback? onLegalName;
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
  final VoidCallback? onBanners;
  final VoidCallback? onExport;
  final List<AccountBubble> bubbles;
  final String dayLabel;
  final VoidCallback? onSend;
  final List<PhotoCredit> credits;

  static const Color _pageTop = Color(0xFFEAF0FB);

  static const TextHeightBehavior _block = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: BrandColors.textPrimary,
        decoration: TextDecoration.none,
      ),
      textHeightBehavior: _block,
      child: ColoredBox(
        color: BrandColors.surface,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[_pageTop, BrandColors.surface],
              stops: <double>[0, 260 / 844],
            ),
          ),
          child: Column(
            children: <Widget>[
              _header(),
              Expanded(child: _fade(_body())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    if (showBack) {
      return _BackHeader(
        title: title,
        subtitle: subtitle,
        lines: subtitleLines,
        showBell: showBell,
        onBack: onBack,
        onBell: onBell,
      );
    }
    return _RootHeader(title: title, subtitle: subtitle, onBell: onBell);
  }

  Widget _body() {
    return switch (frame) {
      AccountFrame.home => _HomeBody(
        name: name,
        initials: initials,
        location: location,
        verifiedLabel: verifiedLabel,
        sample: sample,
        menu: menu,
        onSignOut: onSignOut,
      ),
      AccountFrame.inbox => _InboxBody(
        rows: inbox,
        showSampleNote: showSampleNote,
      ),
      AccountFrame.inboxEmpty => _EmptyInbox(onMessageOffice: onMessageOffice),
      AccountFrame.inboxError => _InboxError(onRetry: onInboxRetry),
      AccountFrame.editProfile => _EditBody(
        initials: initials,
        fields: fields,
        onSave: onSave,
        onLegalName: onLegalName,
      ),
      AccountFrame.settings => _SettingsBody(
        toggles: toggles,
        onLanguage: onLanguage,
        onChangePassword: onChangePassword,
        changePasswordSubtitle: changePasswordSubtitle,
        onPrivacy: onPrivacy,
        onExport: onExport,
        showDataExport: showDataExport,
      ),
      AccountFrame.about => _AboutBody(credits: credits, onBanners: onBanners),
      AccountFrame.thread => _ThreadBody(
        bubbles: bubbles,
        dayLabel: dayLabel,
        showSampleNote: showSampleNote,
        onSend: onSend,
      ),
      AccountFrame.privacy =>
        noticeMarkdown != null
            ? _PublishedNotice(markdown: noticeMarkdown!)
            : showBundledDraft
            ? _PrivacyBody(onExport: onExport, showDataExport: showDataExport)
            : const _NoticePending(),
      AccountFrame.banners => _BannersBody(credits: credits),
    };
  }

  Widget _fade(Widget child) {
    if (frame == AccountFrame.thread) return child;
    return Stack(
      children: <Widget>[
        child,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 28,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x00F3F5FA), BrandColors.surface],
                ),
              ),
            ),
          ),
        ),
      ],
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
      tile: Color(0xFFEAF0FB),
      iconColor: BrandColors.taytayBlue,
    ),
    AccountMenuRow(
      title: 'Messages',
      subtitle: '1 new reply from BPLO',
      icon: TaytayIcons.messageSquare,
      tile: Color(0xFFEAF0FB),
      iconColor: BrandColors.taytayBlue,
      badge: '1',
    ),
    AccountMenuRow(
      title: 'Verification status',
      subtitle: 'Verified · Oct 22, 2026',
      icon: TaytayIcons.shield,
      tile: Color(0xFFE7F6EE),
      iconColor: BrandColors.success,
    ),
    AccountMenuRow(
      title: 'Settings',
      subtitle: 'Notifications, language',
      icon: TaytayIcons.settings,
      tile: Color(0xFFEAF0FB),
      iconColor: BrandColors.taytayBlue,
    ),
    AccountMenuRow(
      title: 'Privacy & data',
      subtitle: 'Privacy Notice, your data rights',
      icon: TaytayIcons.lock,
      tile: Color(0xFFEAF0FB),
      iconColor: BrandColors.taytayBlue,
    ),
    AccountMenuRow(
      title: 'Photo credits & about',
      subtitle: 'Licences, app version',
      icon: TaytayIcons.image,
      tile: Color(0xFFEAF0FB),
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
      tile: Color(0xFFE7F6EE),
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
      tile: Color(0xFFEAF0FB),
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
      tile: Color(0xFFFDECEC),
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
      when: 'Treasury · Oct 10',
      fromResident: false,
    ),
    AccountBubble(
      body: 'TD No. 000-0000-00000 po (sample).',
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

class _RootHeader extends StatelessWidget {
  const _RootHeader({required this.title, required this.subtitle, this.onBell});

  final String title;
  final String subtitle;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top == 0 ? 46 : top, 16, 14),
        child: Row(
          children: <Widget>[
            const _Seal(),
            const SizedBox(width: 11),
            Expanded(
              child: MunicipalHeaderTitles(title: title, subtitle: subtitle),
            ),
            const SizedBox(width: 11),
            _Bell(onTap: onBell),
          ],
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({
    required this.title,
    required this.subtitle,
    required this.lines,
    required this.showBell,
    this.onBack,
    this.onBell,
  });

  final String title;
  final String subtitle;
  final int lines;
  final bool showBell;
  final VoidCallback? onBack;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
        ),
      ),
      child: Padding(
        // A wrapped office name makes the navy 8 dp taller than the one-line
        // header. The one-line header stays 46 + 44 + 14.
        padding: EdgeInsets.fromLTRB(
          16,
          top == 0 ? 46 : top,
          16,
          lines > 1 ? 22 : 14,
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 44,
              height: 44,
              child: OverflowBox(
                minWidth: 48,
                maxWidth: 48,
                minHeight: 48,
                maxHeight: 48,
                child: TaytayBackButton(onPressed: onBack, translucent: true),
              ),
            ),
            const SizedBox(width: 11),
            const _Seal(),
            const SizedBox(width: 11),
            Expanded(
              child: lines > 1
                  ? _TwoLineTitles(title: title, subtitle: subtitle)
                  : MunicipalHeaderTitles(title: title, subtitle: subtitle),
            ),
            if (showBell) ...<Widget>[
              const SizedBox(width: 11),
              _Bell(onTap: onBell),
            ],
          ],
        ),
      ),
    );
  }
}

class _TwoLineTitles extends StatelessWidget {
  const _TwoLineTitles({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1,
            color: Colors.white,
            decoration: TextDecoration.none,
          ),
          strutStyle: const StrutStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            height: 1,
            forceStrutHeight: true,
          ),
          textHeightBehavior: AccountCanvas._block,
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          subtitle,
          maxLines: 2,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: Color(0xCCFFFFFF),
            decoration: TextDecoration.none,
          ),
          strutStyle: const StrutStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            height: 1.5,
            leadingDistribution: TextLeadingDistribution.even,
            forceStrutHeight: true,
          ),
        ),
      ],
    );
  }
}

class _Seal extends StatelessWidget {
  const _Seal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/brand/taytay_seal.png',
          fit: BoxFit.contain,
          semanticLabel: 'Seal of Taytay, Rizal',
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OverflowBox(
        maxWidth: 48,
        maxHeight: 48,
        child: Semantics(
          button: true,
          label: 'Notifications',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x24FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Center(
                            child: TaytayIcon(
                              icon: TaytayIcons.bell,
                              size: 20,
                              color: Colors.white,
                              semanticLabel: '',
                              excludeSemantics: true,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: BrandColors.threadGold,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(width: 8, height: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.name,
    required this.initials,
    required this.location,
    required this.verifiedLabel,
    required this.sample,
    required this.menu,
    this.onSignOut,
  });

  final String name;
  final String initials;
  final String location;
  final String verifiedLabel;
  final bool sample;
  final List<AccountMenuRow> menu;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final List<AccountMenuRow> first = menu.take(3).toList(growable: false);
    final List<AccountMenuRow> second = menu.skip(3).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: <Widget>[
          _Card(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.lg,
              Spacing.lg,
              Spacing.md,
            ),
            child: Row(
              children: <Widget>[
                _Initials(initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(name, style: _name, maxLines: 1),
                          ),
                          if (sample) ...<Widget>[
                            const SizedBox(width: 8),
                            const SampleTag(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _meta,
                      ),
                      const SizedBox(height: 8),
                      _Pill(verifiedLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          _MenuCard(rows: first),
          const SizedBox(height: 12),
          _MenuCard(rows: second),
          const SizedBox(height: 12),
          Expanded(
            child: _Card(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: _Hit(
                label: 'Sign out',
                onTap: onSignOut,
                child: const Row(
                  children: <Widget>[
                    _Tile(
                      icon: TaytayIcons.logOut,
                      tile: BrandColors.chipRedBg,
                      color: BrandColors.danger,
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Sign out', style: _name)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu rows sized by their content. The hairline is #EEF1F6.
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.rows});

  final List<AccountMenuRow> rows;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0)
              const ColoredBox(
                color: BrandColors.chipGreyBg,
                child: SizedBox(height: 1, width: double.infinity),
              ),
            _MenuRow(row: rows[i]),
          ],
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
    return _Hit(
      label: row.title,
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          children: <Widget>[
            _Tile(icon: row.icon, tile: row.tile, color: row.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(row.title, maxLines: 1, style: _rowTitle),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _meta,
                  ),
                ],
              ),
            ),
            if (row.badge != null) ...<Widget>[
              const SizedBox(width: 8),
              _CountBadge(row.badge!),
            ],
            const TaytayIcon(
              icon: TaytayIcons.chevronRight,
              size: 18,
              color: BrandColors.chevron,
              semanticLabel: '',
              excludeSemantics: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxBody extends StatelessWidget {
  const _InboxBody({required this.rows, required this.showSampleNote});

  final List<AccountInboxRow> rows;
  final bool showSampleNote;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xxl,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        const _AllFilter(),
        const SizedBox(height: 12),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (var i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0)
                  const ColoredBox(
                    color: Color(0xFFEEF1F6),
                    child: SizedBox(height: 1, width: double.infinity),
                  ),
                _InboxRow(row: rows[i]),
              ],
            ],
          ),
        ),
        if (showSampleNote) ...<Widget>[
          const SizedBox(height: 14),
          const Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: <Widget>[
                SampleTag(),
                Text('messages for illustration', style: _meta),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.row});

  final AccountInboxRow row;

  /// The canvas strips the first ascent. These struts are the line boxes.
  static const TextHeightBehavior _line = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  static const StrutStyle _titleStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 1.2,
    forceStrutHeight: true,
  );

  static const StrutStyle _metaStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.2,
    forceStrutHeight: true,
  );

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: row.office,
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // The design's office tile is 44 dp. The time sits in the
            // trailing column, right-aligned, centred on this row.
            _Tile(
              icon: row.icon,
              tile: row.tile,
              color: row.iconColor,
              size: 44,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.office,
                    style: _rowTitle,
                    strutStyle: _titleStrut,
                    textHeightBehavior: _line,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    row.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _meta,
                    strutStyle: _metaStrut,
                    textHeightBehavior: _line,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  row.when,
                  style: _meta,
                  strutStyle: _metaStrut,
                  textHeightBehavior: _line,
                ),
                if (row.badge != null) ...<Widget>[
                  const SizedBox(height: Spacing.xs),
                  _CountBadge(row.badge!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({this.onMessageOffice});

  final VoidCallback? onMessageOffice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xxl,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        const _AllFilter(),
        const SizedBox(height: 62),
        const Center(child: _EmptyMark()),
        const SizedBox(height: Spacing.xxl),
        const Text(
          'No messages yet',
          textAlign: TextAlign.center,
          style: _emptyTitle,
        ),
        const SizedBox(height: Spacing.xs),
        const Text(
          'Questions you send to municipal offices and their replies '
          'will appear here.',
          textAlign: TextAlign.center,
          style: _emptyBody,
          strutStyle: StrutStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            height: 1.5,
            forceStrutHeight: true,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _PrimaryButton(
            label: 'Message an office',
            icon: TaytayIcons.messageSquare,
            onTap: onMessageOffice,
          ),
        ),
        const SizedBox(height: Spacing.md),
        const Text(
          'Messaging is available to verified residents.',
          textAlign: TextAlign.center,
          style: _meta,
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
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.xxl,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        const _AllFilter(),
        const SizedBox(height: 62),
        const Center(child: _EmptyMark()),
        const SizedBox(height: 16),
        const Text(
          'Messages did not load',
          textAlign: TextAlign.center,
          style: _emptyTitle,
        ),
        const SizedBox(height: 8),
        const Text(
          'Taytay LGU could not be reached. You can try again.',
          textAlign: TextAlign.center,
          style: _emptyBody,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _PrimaryButton(label: 'Retry', onTap: onRetry),
        ),
      ],
    );
  }
}

class _EditBody extends StatelessWidget {
  const _EditBody({
    required this.initials,
    required this.fields,
    this.onSave,
    this.onLegalName,
  });

  final String initials;
  final List<AccountField> fields;
  final VoidCallback? onSave;
  final VoidCallback? onLegalName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        _PhotoNote(initials: initials),
        const SizedBox(height: 12),
        _Card(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!fields.any(
                (AccountField field) => field.label == 'Display name',
              )) ...<Widget>[
                _LegalNameNote(onTap: onLegalName),
                const SizedBox(height: Spacing.md),
              ],
              for (var i = 0; i < fields.length; i++) ...<Widget>[
                _EditField(
                  field: fields[i],
                  padBottom: i == fields.length - 1 ? 0 : Spacing.md,
                ),
                if (fields[i].label == 'Display name') ...<Widget>[
                  _LegalNameNote(onTap: onLegalName),
                  const SizedBox(height: Spacing.md),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(label: 'Save changes', onTap: onSave),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.field, this.padBottom = 12});

  final AccountField field;
  final double padBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: padBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(field.label, style: _label),
          const SizedBox(height: Spacing.sm),
          _FieldBox(
            onTap: field.controller == null ? field.onTap : null,
            child: Row(
              children: <Widget>[
                Expanded(child: _fieldValue()),
                if (field.verified) const _Pill('Verified', compact: true),
                if (field.chevron)
                  const TaytayIcon(
                    icon: TaytayIcons.chevronDown,
                    size: 18,
                    color: BrandColors.chevron,
                    semanticLabel: '',
                    excludeSemantics: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldValue() {
    final TextEditingController? controller = field.controller;
    if (controller == null) {
      return Text(
        field.value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _fieldInk,
      );
    }
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        onChanged: field.onChanged,
        maxLines: 1,
        style: _fieldInk,
        cursorColor: BrandColors.taytayBlue,
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
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
    return GestureDetector(
      onTap: onTap,
      child: const Text(
        'Legal name changes go through Resident Profile and re-verification.',
        style: _legal,
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.toggles,
    this.onLanguage,
    this.onChangePassword,
    this.changePasswordSubtitle = '',
    this.onPrivacy,
    this.onExport,
    this.showDataExport = true,
  });

  final List<AccountToggle> toggles;
  final VoidCallback? onLanguage;
  final VoidCallback? onChangePassword;
  final String changePasswordSubtitle;
  final VoidCallback? onPrivacy;
  final VoidCallback? onExport;
  final bool showDataExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Notifications'),
          const SizedBox(height: Spacing.sm),
          _Card(
            padding: EdgeInsets.zero,
            child: _InsetRows(
              children: <Widget>[
                for (final AccountToggle toggle in toggles)
                  _ToggleRow(toggle: toggle),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          const _SectionLabel('App'),
          const SizedBox(height: Spacing.sm),
          _Card(
            padding: EdgeInsets.zero,
            child: _InsetRows(
              children: <Widget>[
                _LinkRow(
                  title: 'Language',
                  subtitle: 'English · Filipino',
                  icon: TaytayIcons.languages,
                  tile: BrandColors.chipBlueBg,
                  color: BrandColors.taytayBlue,
                  onTap: onLanguage,
                ),
                _LinkRow(
                  title: 'Change password',
                  subtitle: changePasswordSubtitle,
                  icon: TaytayIcons.lock,
                  tile: BrandColors.chipBlueBg,
                  color: BrandColors.taytayBlue,
                  onTap: onChangePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          const _SectionLabel('Privacy'),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: _Card(
              padding: EdgeInsets.zero,
              child: _InsetRows(
                children: <Widget>[
                  _LinkRow(
                    title: 'Privacy Notice',
                    subtitle:
                        'Data Privacy Act of 2012 · LGU-approved text pending',
                    icon: TaytayIcons.fileText,
                    tile: BrandColors.chipBlueBg,
                    color: BrandColors.taytayBlue,
                    onTap: onPrivacy,
                  ),
                  if (showDataExport)
                    _LinkRow(
                      title: 'Request a copy of my data',
                      subtitle: 'Right to access',
                      icon: TaytayIcons.download,
                      tile: BrandColors.chipBlueBg,
                      color: BrandColors.taytayBlue,
                      onTap: onExport,
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

/// Settings rows with the hairline inset by the page gutter.
class _InsetRows extends StatelessWidget {
  const _InsetRows({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: ColoredBox(
                color: BrandColors.chipGreyBg,
                child: SizedBox(height: 1, width: double.infinity),
              ),
            ),
          children[i],
        ],
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
        const _Card(
          padding: EdgeInsets.all(Spacing.lg),
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 72,
                height: 72,
                child: Image(
                  image: AssetImage('assets/brand/taytay_seal.png'),
                  fit: BoxFit.contain,
                  semanticLabel: 'Seal of Taytay, Rizal',
                ),
              ),
              SizedBox(height: Spacing.md),
              Text(
                'Taytay Resident App',
                textAlign: TextAlign.center,
                style: _appTitle,
              ),
              SizedBox(height: Spacing.xs),
              Text(
                'Municipality of Taytay, Rizal · version 0.1 (design\n'
                'mockup)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: BrandColors.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        const _SectionLabel('Photo credits'),
        const SizedBox(height: Spacing.sm),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < welcome.length; i++) ...<Widget>[
                if (i > 0)
                  const ColoredBox(
                    color: BrandColors.chipGreyBg,
                    child: SizedBox(height: 1, width: double.infinity),
                  ),
                _CreditRow(credit: welcome[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),
        _Card(
          padding: EdgeInsets.zero,
          child: _LinkRow(
            title: 'Office banner photos',
            subtitle: PhotoCredits.officeBannerSummary,
            icon: TaytayIcons.images,
            tile: BrandColors.chipBlueBg,
            color: BrandColors.taytayBlue,
            onTap: onBanners,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        const _SectionLabel('About'),
        const SizedBox(height: Spacing.sm),
        const _Card(
          padding: EdgeInsets.zero,
          child: _LinkRow(
            title: 'Municipal seal',
            subtitle: 'Described on taytayrizal.gov.ph/seal · Wikimedia',
            icon: TaytayIcons.shield,
            tile: BrandColors.chipBlueBg,
            color: BrandColors.taytayBlue,
          ),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.credit});

  final PhotoCredit credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const _Tile(
            icon: TaytayIcons.image,
            tile: Color(0xFFEAF0FB),
            color: BrandColors.taytayBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(credit.title, style: _creditTitle),
                const SizedBox(height: 2),
                Text(credit.byline, style: _creditByline),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const TaytayIcon(
            icon: TaytayIcons.externalLink,
            size: 16,
            color: BrandColors.taytayBlue,
            semanticLabel: '',
            excludeSemantics: true,
          ),
        ],
      ),
    );
  }
}

class _PrivacyBody extends StatelessWidget {
  const _PrivacyBody({this.onExport, this.showDataExport = true});

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
        const Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DraftBanner(),
              SizedBox(height: Spacing.xs),
              Text('Privacy Notice', style: _noticeTitle),
              SizedBox(height: Spacing.xs),
              Text(
                'Republic Act No. 10173, Data Privacy Act of 2012',
                style: _meta,
              ),
              SizedBox(height: Spacing.md),
              _Card(
                padding: EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _NoticeBlock(
                      title: 'What we collect',
                      body:
                          'Name, contact details, address, valid ID and selfie, '
                          'and messages you send to offices.',
                    ),
                    _NoticeBlock(
                      title: 'Why',
                      body:
                          'To verify that you are a Taytay resident and to '
                          'deliver the services you request.',
                    ),
                    _NoticeBlock(
                      title: 'Who can see it',
                      body:
                          'Authorised LGU staff of the office you deal with. '
                          'Not sold or shared for marketing.',
                    ),
                    _NoticeBlock(
                      title: 'Your rights',
                      body:
                          'Access, correction, objection and erasure. Contact '
                          'the LGU Data Protection Officer.',
                      trailing: SampleTag(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDataExport) ...<Widget>[
          const SizedBox(height: 12),
          _OutlineButton(
            label: 'Request a copy of my data',
            icon: TaytayIcons.download,
            onTap: onExport,
          ),
        ],
      ],
    );
  }
}

class _PublishedNotice extends StatelessWidget {
  const _PublishedNotice({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final List<NoticeLine> lines = parseNoticeMarkdown(markdown);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        const Text('Privacy Notice', style: _noticeTitle),
        const SizedBox(height: Spacing.xs),
        const Text(
          'Republic Act No. 10173, Data Privacy Act of 2012',
          style: _meta,
        ),
        const SizedBox(height: Spacing.md),
        _Card(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final NoticeLine line in lines) ...<Widget>[
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      if (line.bullet)
                        const TextSpan(text: '• ', style: _noticeBody),
                      for (final NoticeRun run in line.runs)
                        TextSpan(
                          text: run.text,
                          style: line.heading
                              ? _rowTitle
                              : _noticeBody.copyWith(
                                  fontWeight: run.strong
                                      ? FontWeight.w700
                                      : _noticeBody.fontWeight,
                                ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NoticeBlock extends StatelessWidget {
  const _NoticeBlock({required this.title, required this.body, this.trailing});

  final String title;
  final String body;

  /// The design draws this at the end of the last line of [body].
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: _rowTitle),
          const SizedBox(height: Spacing.sm),
          if (trailing == null)
            Text(body, style: _noticeBody)
          else
            Text.rich(
              TextSpan(
                style: _noticeBody,
                children: <InlineSpan>[
                  TextSpan(text: '$body '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: trailing,
                  ),
                ],
              ),
            ),
        ],
      ),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        const _BannerIntro(),
        const SizedBox(height: 12),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0)
                  const ColoredBox(
                    color: Color(0xFFEEF1F6),
                    child: SizedBox(height: 1, width: double.infinity),
                  ),
                _BannerRow(credit: rows[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerIntro extends StatelessWidget {
  const _BannerIntro();

  static const TextStyle _line = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: BrandColors.sheetBody,
    decoration: TextDecoration.none,
  );

  static const StrutStyle _strut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    height: 1.5,
    forceStrutHeight: true,
  );

  static const TextHeightBehavior _behavior = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: _line,
        children: <InlineSpan>[
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
      strutStyle: _strut,
      textHeightBehavior: _behavior,
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({required this.credit});

  final PhotoCredit credit;

  /// The canvas strips the first ascent, which lets a font's own leading
  /// open a gap the design does not have. These struts are the line boxes.
  static const TextHeightBehavior _forcedLine = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  static const StrutStyle _officeStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.2,
    forceStrutHeight: true,
  );

  static const StrutStyle _titleStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 1.2,
    forceStrutHeight: true,
  );

  static const StrutStyle _bylineStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.2,
    forceStrutHeight: true,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            credit.offices.join(', '),
            style: _officeLabel,
            strutStyle: _officeStrut,
            textHeightBehavior: _forcedLine,
          ),
          const SizedBox(height: Spacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      credit.title,
                      style: _bannerTitle,
                      strutStyle: _titleStrut,
                      textHeightBehavior: _forcedLine,
                    ),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      credit.byline,
                      style: _creditByline,
                      strutStyle: _bylineStrut,
                      textHeightBehavior: _forcedLine,
                    ),
                  ],
                ),
              ),
              if (credit.replace) ...<Widget>[
                const SizedBox(width: Spacing.sm),
                const _ReplaceMark(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Amber Replace chip, sitting on the right of the title row.
class _ReplaceMark extends StatelessWidget {
  const _ReplaceMark();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.chipAmberBg,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Text(
          'Replace',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: 0,
            color: BrandColors.warning,
            decoration: TextDecoration.none,
          ),
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
  });

  final List<AccountBubble> bubbles;
  final String dayLabel;
  final bool showSampleNote;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.xl,
              Spacing.lg,
              Spacing.sm,
            ),
            children: <Widget>[
              if (dayLabel.isNotEmpty) Center(child: _Chip(dayLabel)),
              if (dayLabel.isNotEmpty) const SizedBox(height: Spacing.sm),
              for (final AccountBubble bubble in bubbles)
                _Bubble(bubble: bubble),
              if (showSampleNote) ...<Widget>[
                const SizedBox(height: Spacing.xs),
                const Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: <Widget>[
                      SampleTag(),
                      Text('conversation for illustration', style: _meta),
                    ],
                  ),
                ),
              ],
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
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.bubble});

  final AccountBubble bubble;

  @override
  Widget build(BuildContext context) {
    final bool mine = bubble.fromResident;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 276),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: mine ? BrandColors.taytayBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
                border: mine ? null : Border.all(color: BrandColors.cardLine),
              ),
              child: Text(
                bubble.body,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: mine ? Colors.white : BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
                strutStyle: const StrutStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: 1.5,
                  forceStrutHeight: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
              child: Text(bubble.when, style: _meta),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.fromBorderSide(BorderSide(color: BrandColors.cardLine)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding + const EdgeInsets.symmetric(horizontal: 1),
        child: child,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.tile,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color tile;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TaytayIcon(
        icon: icon,
        size: 18,
        color: color,
        semanticLabel: '',
        excludeSemantics: true,
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.initials);

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF0FB),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppTypography.cardTitle.copyWith(
          color: BrandColors.taytayBlue,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: BrandColors.chipGreenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TaytayIcon(
            icon: TaytayIcons.badgeCheck,
            size: compact ? 12 : 14,
            color: BrandColors.success,
            semanticLabel: '',
            excludeSemantics: true,
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: AppTypography.labelStrong.copyWith(
              color: BrandColors.success,
              decoration: TextDecoration.none,
            ),
          ),
        ],
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
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        child: Text(label, style: _label),
      ),
    );
  }
}

/// Inbox filters. All is a filled pill. Unread is a white pill with a border.
class _AllFilter extends StatelessWidget {
  const _AllFilter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _FilterPill(label: 'All', selected: true),
        SizedBox(width: Spacing.sm),
        _FilterPill(label: 'Unread'),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? BrandColors.taytayBlue : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
        border: selected ? null : Border.all(color: BrandColors.cardLine),
      ),
      child: SizedBox(
        height: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Center(
            child: Text(
              label,
              style: AppTypography.sbtn.copyWith(
                color: selected ? Colors.white : BrandColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.taytayBlue,
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.chipAmberBg,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'DRAFT · LGU-approved text to be inserted',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: BrandColors.warning,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticePending extends StatelessWidget {
  const _NoticePending();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const <Widget>[
        Text('Privacy Notice', style: _noticeTitle),
        SizedBox(height: 8),
        Text(
          'The privacy notice will appear here when Taytay LGU publishes it.',
          style: _noticeBody,
        ),
      ],
    );
  }
}

class _PhotoNote extends StatelessWidget {
  const _PhotoNote({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.lg),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF0FB),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.taytayBlue,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BrandColors.taytayBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const TaytayIcon(
                      icon: TaytayIcons.camera,
                      size: 14,
                      color: Colors.white,
                      semanticLabel: 'Profile photo',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            'Profile photo — reviewed by LGU before it appears on your ID',
            textAlign: TextAlign.center,
            style: _caption,
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: label,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.taytayBlue),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TaytayIcon(
              icon: icon,
              size: 16,
              color: BrandColors.taytayBlue,
              semanticLabel: '',
              excludeSemantics: true,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: BrandColors.taytayBlue,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMark extends StatelessWidget {
  const _EmptyMark();

  @override
  Widget build(BuildContext context) {
    return const TaytayIcon(
      icon: TaytayIcons.messageSquare,
      size: 24,
      color: BrandColors.taytayBlue,
      semanticLabel: '',
      excludeSemantics: true,
    );
  }
}

class _ComposerSend extends StatelessWidget {
  const _ComposerSend({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // The painted disc is 44 dp, which is the composer dark run. The hit
    // overflows to 48 without growing the row.
    return SizedBox(
      width: 44,
      height: 44,
      child: OverflowBox(
        maxWidth: 48,
        maxHeight: 48,
        child: Semantics(
          button: true,
          label: 'Send',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
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
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6DCE8)),
        ),
        child: child,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final IconData? icon = this.icon;
    return _Hit(
      label: label,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.taytayBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              TaytayIcon(
                icon: icon,
                size: 16,
                color: Colors.white,
                semanticLabel: '',
                excludeSemantics: true,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.title,
    this.subtitle = '',
    required this.icon,
    required this.tile,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tile;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: title,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          children: <Widget>[
            _Tile(icon: icon, tile: tile, color: color),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: _rowTitle),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.xxs),
                    Text(subtitle, style: _meta),
                  ],
                ],
              ),
            ),
            const TaytayIcon(
              icon: TaytayIcons.chevronRight,
              size: 18,
              color: BrandColors.chevron,
              semanticLabel: '',
              excludeSemantics: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.toggle});

  final AccountToggle toggle;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: toggle.title,
      onTap: toggle.locked ? null : () => toggle.onChanged?.call(!toggle.on),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        child: Row(
          children: <Widget>[
            _Tile(
              icon: toggle.icon,
              tile: toggle.tile,
              color: toggle.iconColor,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(toggle.title, style: _rowTitle),
                  const SizedBox(height: Spacing.xxs),
                  Text(toggle.subtitle, style: _meta),
                ],
              ),
            ),
            _Switch(on: toggle.on, locked: toggle.locked),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.on, required this.locked});

  final bool on;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      enabled: !locked,
      child: Container(
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? BrandColors.taytayBlue : const Color(0xFFD5DBE8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: BrandColors.textPrimary,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({required this.child, required this.label, this.onTap});

  final Widget child;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: child,
        ),
      ),
    );
  }
}

const TextStyle _emptyTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w800,
  height: 1,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _emptyBody = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.5,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _name = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w800,
  height: 1.2,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _rowTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 1.2,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _meta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _label = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
  color: BrandColors.fieldLabel,
  decoration: TextDecoration.none,
);

const TextStyle _fieldInk = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  height: 1.2,
  color: BrandColors.fieldInk,
  decoration: TextDecoration.none,
);

const TextStyle _caption = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w500,
  height: 1,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _legal = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _appTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w800,
  height: 1,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _creditTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 1.2,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _noticeBody = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.5,
  color: BrandColors.sheetBody,
  decoration: TextDecoration.none,
);

const TextStyle _creditByline = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _noticeTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 20,
  fontWeight: FontWeight.w800,
  height: 1,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _bannerTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 1.2,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _officeLabel = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w800,
  height: 1.2,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

const TextStyle _hint = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: BrandColors.fieldHint,
  decoration: TextDecoration.none,
);
