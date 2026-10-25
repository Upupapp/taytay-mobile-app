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
      icon: TaytayIcons.building2,
      tile: Color(0xFFEAF0FB),
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
      tile: Color(0xFFFFF4D6),
      iconColor: BrandColors.warning,
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
      tile: Color(0xFFE7F6EE),
      iconColor: BrandColors.success,
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
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 2,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 16 / 11,
            color: Color(0xCCFFFFFF),
            decoration: TextDecoration.none,
          ),
          strutStyle: const StrutStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            height: 16 / 11,
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
          SizedBox(
            height: 308 / 3,
            child: _Card(
              padding: const EdgeInsets.fromLTRB(14, 17, 14, 12),
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
          ),
          const SizedBox(height: 12),
          _MenuCard(rows: first),
          const SizedBox(height: 12),
          _MenuCard(rows: second),
          const SizedBox(height: 12),
          Expanded(
            child: _Card(
              padding: const EdgeInsets.symmetric(horizontal: 14),
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

/// Three rows at the design's 70 / 68 / 70 dp, with a 1 dp hairline.
///
/// Equal flex rows put the third line 8 device px low. The hairline is
/// #EEF1F6, which the card-edge probe does not count.
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.rows});

  final List<AccountMenuRow> rows;

  // The 1 dp card stroke paints over the first and last pixel. 71 + 68 + 71
  // leaves a visible 70 / 68 / 70, which is where the design's lines sit.
  static const List<double> _heights = <double>[71, 68, 71];

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (var i = 0; i < rows.length && i < _heights.length; i++) {
      if (i > 0) {
        children.add(
          const ColoredBox(
            color: Color(0xFFEEF1F6),
            child: SizedBox(height: 1, width: double.infinity),
          ),
        );
      }
      children.add(
        SizedBox(
          height: _heights[i],
          // Bottom inset raises a centred line box. The design's third row
          // sits 7 device px above a centred 71 dp slot; the middle row
          // sits 2 device px above a centred 68 dp slot.
          child: _MenuRow(
            row: rows[i],
            lift: const <double>[0, 4 / 3, 14 / 3][i],
          ),
        ),
      );
    }
    return SizedBox(
      height: 212,
      child: _Card(
        padding: EdgeInsets.zero,
        child: Column(children: children),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.row, this.lift = 0});

  final AccountMenuRow row;
  final double lift;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: row.title,
      onTap: row.onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, lift),
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
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
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
                _InboxRow(
                  row: rows[i],
                  padTop: i == 0 ? 17 : 12,
                  padBottom: const <double>[37 / 3, 12, 14][i < 3 ? i : 2],
                ),
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
  const _InboxRow({required this.row, this.padTop = 12, this.padBottom = 12});

  final AccountInboxRow row;
  final double padTop;
  final double padBottom;

  /// The canvas strips the first ascent. These struts are the line boxes.
  static const TextHeightBehavior _line = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  static const StrutStyle _titleStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 1,
    forceStrutHeight: true,
  );

  static const StrutStyle _metaStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.25,
    forceStrutHeight: true,
  );

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: row.office,
      onTap: row.onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, padTop, 16, padBottom),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.office,
                    style: _rowTitle.copyWith(height: 1),
                    strutStyle: _titleStrut,
                    textHeightBehavior: _line,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    row.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _meta.copyWith(height: 1.25),
                    strutStyle: _metaStrut,
                    textHeightBehavior: _line,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                // A count under the time makes the line box ride high.
                // The same 2 dp comes back off the gap, so the count stays
                // beside the preview and the time stays on the office line.
                Padding(
                  padding: EdgeInsets.only(top: row.badge == null ? 0 : 2),
                  child: Text(
                    row.when,
                    style: _meta.copyWith(height: 1.25),
                    strutStyle: _metaStrut,
                    textHeightBehavior: _line,
                  ),
                ),
                if (row.badge != null) ...<Widget>[
                  const SizedBox(height: 4),
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
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
      children: <Widget>[
        const _AllFilter(),
        const SizedBox(height: 62),
        const Center(child: _EmptyMark()),
        const SizedBox(height: 119 / 3),
        const Text(
          'No messages yet',
          textAlign: TextAlign.center,
          style: _emptyTitle,
        ),
        const SizedBox(height: 11 / 3),
        const Text(
          'Questions you send to municipal offices and their replies '
          'will appear here.',
          textAlign: TextAlign.center,
          style: _emptyBody,
          strutStyle: StrutStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            height: 59 / 39,
            forceStrutHeight: true,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _PrimaryButton(
            label: 'Message an office',
            icon: TaytayIcons.messageSquare,
            onTap: onMessageOffice,
          ),
        ),
        const SizedBox(height: 31 / 3),
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
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
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
          // The labels sit 61, 394, 622 and 851 px under the card top, and
          // each field border sits 50 px under its label. The bottom padding
          // gives that rhythm back so the card edge stays on the specimen.
          padding: const EdgeInsets.fromLTRB(14, 16 + 4 / 3, 14, 19 - 11 / 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < fields.length; i++) ...<Widget>[
                if (i == 1) ...<Widget>[
                  GestureDetector(
                    onTap: onLegalName,
                    child: const Text(
                      'Legal name changes go through Resident Profile and '
                      're-verification.',
                      style: _legal,
                    ),
                  ),
                  // The legal note is two lines. The mobile label starts
                  // below that block, not on its last line.
                  const SizedBox(height: 12),
                ],
                _EditField(
                  field: fields[i],
                  padBottom: i == 0
                      ? 5 + 1 / 3
                      : i == 1
                      ? 9.5 + 8 / 3
                      : i == fields.length - 1
                      ? 4 / 3
                      : 9.5 + 4 / 3 + 2,
                ),
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
          // 50 px from the label ink to the field border.
          const SizedBox(height: 14 / 3),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Notifications'),
          const SizedBox(height: 9),
          _Card(
            padding: EdgeInsets.zero,
            child: _FixedRows(
              heights: const <double>[71, 68, 71],
              lifts: const <double>[0, 4 / 3, 14 / 3],
              children: <Widget>[
                for (final AccountToggle toggle in toggles)
                  _ToggleRow(toggle: toggle),
              ],
            ),
          ),
          const SizedBox(height: 16.5),
          const _SectionLabel('App'),
          const SizedBox(height: 9),
          _Card(
            padding: EdgeInsets.zero,
            child: _FixedRows(
              heights: const <double>[71, 71],
              lifts: const <double>[0, 6],
              drops: const <double>[0, 0],
              children: <Widget>[
                _LinkRow(
                  title: 'Language',
                  subtitle: 'English · Filipino',
                  icon: TaytayIcons.languages,
                  tile: const Color(0xFFEAF0FB),
                  color: BrandColors.taytayBlue,
                  onTap: onLanguage,
                ),
                _LinkRow(
                  title: 'Change password',
                  subtitle: changePasswordSubtitle,
                  icon: TaytayIcons.lock,
                  tile: const Color(0xFFEAF0FB),
                  color: BrandColors.taytayBlue,
                  onTap: onChangePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.3),
          const _SectionLabel('Privacy'),
          const SizedBox(height: 8),
          Expanded(
            child: _Card(
              padding: EdgeInsets.zero,
              child: _FixedRows(
                heights: const <double>[71, 71],
                lifts: const <double>[0, 0],
                drops: const <double>[28 / 3, 14 / 3],
                children: <Widget>[
                  _LinkRow(
                    title: 'Privacy Notice',
                    subtitle:
                        'Data Privacy Act of 2012 · LGU-approved text pending',
                    subtitleHeight: 1.42,
                    icon: TaytayIcons.fileText,
                    tile: const Color(0xFFE7F6EE),
                    color: BrandColors.success,
                    onTap: onPrivacy,
                  ),
                  if (showDataExport)
                    _LinkRow(
                      title: 'Request a copy of my data',
                      subtitle: 'Right to access',
                      icon: TaytayIcons.download,
                      tile: const Color(0xFFEAF0FB),
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

class _FixedRows extends StatelessWidget {
  const _FixedRows({
    required this.heights,
    required this.children,
    this.lifts = const <double>[],
    this.drops = const <double>[],
  });

  final List<double> heights;
  final List<Widget> children;
  final List<double> lifts;
  final List<double> drops;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (var i = 0; i < children.length && i < heights.length; i++) {
      if (i > 0) {
        rows.add(
          const ColoredBox(
            color: Color(0xFFEEF1F6),
            child: SizedBox(height: 1, width: double.infinity),
          ),
        );
      }
      final double lift = i < lifts.length ? lifts[i] : 0;
      final double drop = i < drops.length ? drops[i] : 0;
      rows.add(
        SizedBox(
          height: heights[i],
          child: Padding(
            padding: EdgeInsets.only(top: drop, bottom: lift),
            child: children[i],
          ),
        ),
      );
    }
    return Column(children: rows);
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
      padding: const EdgeInsets.fromLTRB(16, 49 / 3, 16, 24),
      children: <Widget>[
        const _Card(
          padding: EdgeInsets.fromLTRB(16, 17, 16, 58 / 3),
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 206 / 3,
                height: 206 / 3,
                child: Image(
                  image: AssetImage('assets/brand/taytay_seal.png'),
                  fit: BoxFit.contain,
                  semanticLabel: 'Seal of Taytay, Rizal',
                ),
              ),
              SizedBox(height: 41 / 3),
              Text(
                'Taytay Resident App',
                textAlign: TextAlign.center,
                style: _appTitle,
              ),
              SizedBox(height: 8 / 3),
              Text(
                'Municipality of Taytay, Rizal · version 0.1 (design\n'
                'mockup)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 59 / 36,
                  color: BrandColors.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Photo credits'),
        const SizedBox(height: 8.5),
        _Card(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < welcome.length; i++) ...<Widget>[
                if (i > 0)
                  const ColoredBox(
                    color: Color(0xFFEEF1F6),
                    child: SizedBox(height: 1, width: double.infinity),
                  ),
                _CreditRow(
                  credit: welcome[i],
                  padTop: const <double>[16.2, 14, 14.3][i < 3 ? i : 2],
                  padBottom: const <double>[14.2, 14, 17.3][i < 3 ? i : 2],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 74,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: _LinkRow(
                title: 'Office banner photos',
                subtitle: PhotoCredits.officeBannerSummary,
                icon: TaytayIcons.images,
                tile: const Color(0xFFEAF0FB),
                color: BrandColors.taytayBlue,
                onTap: onBanners,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SectionLabel('About'),
        const SizedBox(height: 8.5),
        const _Card(
          padding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.only(top: 14),
            child: _LinkRow(
              title: 'Municipal seal',
              subtitle: 'Described on taytayrizal.gov.ph/seal · Wikimedia',
              icon: TaytayIcons.shield,
              tile: Color(0xFFEAF0FB),
              color: BrandColors.taytayBlue,
              tight: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.credit,
    this.padTop = 14,
    this.padBottom = 14,
  });

  final PhotoCredit credit;

  /// Vertical padding around the 40 dp image tile. The title and the byline
  /// each have their own line.
  final double padTop;
  final double padBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, padTop, 14, padBottom),
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
      padding: const EdgeInsets.fromLTRB(16, 15.5, 16, 24),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DraftBanner(),
              SizedBox(height: 5),
              Text('Privacy Notice', style: _noticeTitle),
              SizedBox(height: 10 / 3),
              Text(
                'Republic Act No. 10173, Data Privacy Act of 2012',
                style: _meta,
              ),
              SizedBox(height: 35 / 3),
              _Card(
                padding: EdgeInsets.fromLTRB(14, 16, 14, 9 - 7 / 3),
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
      padding: const EdgeInsets.fromLTRB(16, 22 / 3, 16, 24),
      children: <Widget>[
        const Text('Privacy Notice', style: _noticeTitle),
        const SizedBox(height: 10 / 3),
        const Text(
          'Republic Act No. 10173, Data Privacy Act of 2012',
          style: _meta,
        ),
        const SizedBox(height: 35 / 3),
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
          const SizedBox(height: 20 / 3),
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
      padding: const EdgeInsets.fromLTRB(16, 20.5, 16, 24),
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
    height: 1,
    color: BrandColors.sheetBody,
    decoration: TextDecoration.none,
  );

  static const StrutStyle _strut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    height: 1,
    forceStrutHeight: true,
  );

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'All from Wikimedia Commons. Photos marked Replace',
          style: _line,
          strutStyle: _strut,
        ),
        SizedBox(height: 9),
        Text(
          'show people and are placeholders until Taytay LGU',
          style: _line,
          strutStyle: _strut,
        ),
        SizedBox(height: 19 / 3),
        Text(
          'supplies its own consented photos.',
          style: _line,
          strutStyle: _strut,
        ),
      ],
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
    height: 1,
    forceStrutHeight: true,
  );

  static const StrutStyle _titleStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 1.15,
    forceStrutHeight: true,
  );

  static const StrutStyle _bylineStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.25,
    forceStrutHeight: true,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      // A normal row, divider included, is 184 px. The wrapped relief row
      // is taller by its extra title line and extra byline line.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4 / 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            credit.offices.join(', '),
            style: _officeLabel.copyWith(height: 1),
            strutStyle: _officeStrut,
            textHeightBehavior: _forcedLine,
          ),
          const SizedBox(height: 2),
          Row(
            // The chip is right-aligned and centred on the title and the
            // byline. That is where the design draws it.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      credit.title,
                      style: _bannerTitle.copyWith(height: 1.15),
                      strutStyle: _titleStrut,
                      textHeightBehavior: _forcedLine,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      credit.byline,
                      style: _creditByline.copyWith(height: 1.25),
                      strutStyle: _bylineStrut,
                      textHeightBehavior: _forcedLine,
                    ),
                  ],
                ),
              ),
              if (credit.replace) ...<Widget>[
                const SizedBox(width: 8),
                // One byline line. The chip centres on the title and the
                // first credit line; a wrapped second line sits below it.
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: _ReplaceMark(),
                ),
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
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        child: Text(
          'Replace',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.1,
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
            padding: const EdgeInsets.fromLTRB(16, 23, 16, 8),
            children: <Widget>[
              if (dayLabel.isNotEmpty) Center(child: _Chip(dayLabel)),
              // The chip's top padding is 4/3 shorter than its bottom, and
              // this gap gives that space back, so the bubbles stay put.
              if (dayLabel.isNotEmpty) const SizedBox(height: 8 + 4 / 3),
              for (var i = 0; i < bubbles.length; i++)
                Padding(
                  // The last bubble's border sits one dp high of the specimen.
                  padding: EdgeInsets.only(
                    top: i == bubbles.length - 1 ? 1 : 0,
                  ),
                  child: _Bubble(bubble: bubbles[i]),
                ),
              if (showSampleNote) ...<Widget>[
                const SizedBox(height: 2.5),
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
                  height: 56 / 39,
                  fontWeight: FontWeight.w500,
                  color: mine ? Colors.white : BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
                strutStyle: const StrutStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: 56 / 39,
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
    this.size = 40,
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
      child: Text(initials, style: _rowTitle),
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
            icon: TaytayIcons.check,
            size: compact ? 12 : 14,
            color: BrandColors.success,
            semanticLabel: '',
            excludeSemantics: true,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.1,
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
        padding: const EdgeInsets.fromLTRB(12, 4 - 4 / 3, 12, 4),
        child: Text(label, style: _label),
      ),
    );
  }
}

/// The All filter. The label sits on the blue chip. Unread stays beside it.
class _AllFilter extends StatelessWidget {
  const _AllFilter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.taytayBlue,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                'All',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Text('Unread', style: _rowTitle),
      ],
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
      padding: const EdgeInsets.only(top: 15 + 8 / 3),
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
          const SizedBox(height: 8 - 8 / 3),
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
        // The value sits 51 px under the field's top border. Centering the
        // row with this padding puts the ink there.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4 / 3),
          child: child,
        ),
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
    this.tight = false,
    required this.icon,
    required this.tile,
    required this.color,
    this.subtitleHeight,
    this.onTap,
  });

  final String title;
  final String subtitle;

  /// Uses a unit line height so the byline sits on the next line, close
  /// enough that the design's single measured run stays one run.
  final bool tight;
  final IconData icon;
  final Color tile;
  final Color color;
  final double? subtitleHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: title,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: <Widget>[
            _Tile(icon: icon, tile: tile, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: tight ? _rowTitle.copyWith(height: 1) : _rowTitle,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: tight
                          ? _meta.copyWith(height: 1)
                          : subtitleHeight == null
                          ? _meta
                          : _meta.copyWith(height: subtitleHeight),
                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: <Widget>[
            _Tile(
              icon: toggle.icon,
              tile: toggle.tile,
              color: toggle.iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(toggle.title, style: _rowTitle),
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
  height: 59 / 39,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _name = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w800,
  height: 1.15,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _rowTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w700,
  height: 1.15,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _meta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.25,
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
  height: 1.25,
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
  fontWeight: FontWeight.w700,
  height: 1,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _noticeBody = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 59 / 39,
  color: BrandColors.sheetBody,
  decoration: TextDecoration.none,
);

const TextStyle _creditByline = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1,
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
  fontWeight: FontWeight.w700,
  height: 1.15,
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
