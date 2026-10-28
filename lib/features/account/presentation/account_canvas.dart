import 'dart:math' as math;

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
    this.onConsents,
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
  final VoidCallback? onConsents;
  final VoidCallback? onBanners;
  final VoidCallback? onExport;
  final List<AccountBubble> bubbles;
  final String dayLabel;
  final VoidCallback? onSend;
  final List<PhotoCredit> credits;

  static const Color _pageTop = Color(0xFFEAF0FB);

  /// Header titles opt into a tight box. Everything else keeps [S8Space.lineBox].
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
      textHeightBehavior: S8Space.lineBox,
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
        onConsents: onConsents,
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
        // CSS padding is 46×16×14 on every header. A wrapped subtitle does
        // not add padding; it grows the row. See [_TwoLineTitles].
        padding: EdgeInsets.fromLTRB(16, top == 0 ? 46 : top, 16, 14),
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
    // `b` is its own 16 px block (normal → [S8Space.line] of 16). `small` is
    // inline in that same block, so each wrapped line uses the 16 px strut,
    // not the 11 px glyph's own 13.67. Two lines plus the title are 61, and
    // with the 46 + 14 padding the header is 121.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: S8Space.line(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
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
              textHeightBehavior: AccountCanvas._block,
            ),
          ),
        ),
        _CssLines(
          text: subtitle,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: S8Space.normal,
            color: Color(0xCCFFFFFF),
            decoration: TextDecoration.none,
          ),
          step: S8Space.line(16),
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
      padding: const EdgeInsets.fromLTRB(
        S8Space.gutter,
        S8Space.pagePad,
        S8Space.gutter,
        0,
      ),
      child: Column(
        children: <Widget>[
          _Card(
            padding: const EdgeInsets.fromLTRB(
              S8Space.cardPad,
              S8Space.profilePadY,
              S8Space.cardPad,
              S8Space.profilePadY,
            ),
            child: Row(
              children: <Widget>[
                _Initials(initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _MiddleLine(
                        text: sample ? '$name ' : name,
                        style: _name,
                        chip: sample ? const _NormalSample() : null,
                      ),
                      SizedBox(
                        height: 13 * S8Space.bodyLineHeight,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _location,
                            textHeightBehavior: S8Space.lineBox,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _Pill(verifiedLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: S8Space.cardGap),
          _MenuCard(rows: first),
          const SizedBox(height: S8Space.cardGap),
          _MenuCard(rows: second),
          const SizedBox(height: S8Space.cardGap),
          Expanded(
            child: _Card(
              padding: const EdgeInsets.symmetric(horizontal: S8Space.cardPad),
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
                    SizedBox(width: S8Space.iconGap),
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
      padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const _RowDivider(),
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
          horizontal: S8Space.cardPad,
          vertical: S8Space.rowPadY,
        ),
        child: Row(
          children: <Widget>[
            _Tile(icon: row.icon, tile: row.tile, color: row.iconColor),
            const SizedBox(width: S8Space.iconGap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Line(row.title, _rowTitle),
                  const SizedBox(height: S8Space.titleGap),
                  _Line(row.subtitle, _meta),
                ],
              ),
            ),
            const SizedBox(width: S8Space.iconGap),
            if (row.badge != null)
              _CountBadge(row.badge!)
            else
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
        S8Space.gutter,
        S8Space.listInset,
        S8Space.gutter,
        S8Space.pageBottom,
      ),
      children: <Widget>[
        const _AllFilter(),
        const SizedBox(height: S8Space.filterGap),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
          child: Column(
            children: <Widget>[
              for (var i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0) const _RowDivider(),
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

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: row.office,
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          S8Space.cardPad,
          S8Space.rowPadY,
          S8Space.cardPad,
          S8Space.rowPadY,
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
              size: S8Space.tile,
            ),
            const SizedBox(width: S8Space.iconGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: S8Space.line(14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        row.office,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _rowTitle,
                      ),
                    ),
                  ),
                  const SizedBox(height: S8Space.titleGap),
                  _CssLines(
                    text: row.preview,
                    style: S8Space.preview,
                    step: S8Space.line(12),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: S8Space.iconGap),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                // `.ls` carries margin-top 2, and a flex item does not
                // collapse it, so the time starts 2 px into the column.
                const SizedBox(height: S8Space.titleGap),
                _Line(row.when, _meta, align: Alignment.centerRight),
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
      padding: const EdgeInsets.fromLTRB(
        S8Space.gutter,
        S8Space.listInset,
        S8Space.gutter,
        S8Space.pageBottom,
      ),
      children: <Widget>[
        const _AllFilter(),
        const SizedBox(height: S8Space.filterGap),
        _EmptyCopy(
          title: 'No messages yet',
          body:
              'Questions you send to municipal offices and their replies '
              'will appear here.',
          button: 'Message an office',
          buttonIcon: TaytayIcons.messageSquare,
          note: 'Messaging is available to verified residents.',
          onButton: onMessageOffice,
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
        S8Space.gutter,
        S8Space.listInset,
        S8Space.gutter,
        S8Space.pageBottom,
      ),
      children: <Widget>[
        const _AllFilter(),
        const SizedBox(height: S8Space.filterGap),
        _EmptyCopy(
          title: 'Messages did not load',
          body: 'Taytay LGU could not be reached. You can try again.',
          button: 'Retry',
          onButton: onRetry,
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
        const SizedBox(height: S8Space.cardGap),
        _Card(
          padding: const EdgeInsets.all(S8Space.cardPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!fields.any(
                (AccountField field) => field.label == 'Display name',
              )) ...<Widget>[
                _LegalNameNote(onTap: onLegalName),
                const SizedBox(height: S8Space.fieldStack),
              ],
              for (var i = 0; i < fields.length; i++) ...<Widget>[
                _EditField(
                  field: fields[i],
                  padBottom: i == fields.length - 1
                      ? 0
                      : fields[i].label == 'Display name'
                      ? S8Space.legalGap
                      : S8Space.fieldStack,
                ),
                if (fields[i].label == 'Display name') ...<Widget>[
                  _LegalNameNote(onTap: onLegalName),
                  const SizedBox(height: S8Space.fieldStack),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: S8Space.cardGap),
        _PrimaryButton(label: 'Save changes', onTap: onSave),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.field, this.padBottom = S8Space.fieldStack});

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
          const SizedBox(height: S8Space.labelGap),
          _FieldBox(
            onTap: field.controller == null ? field.onTap : null,
            child: Row(
              children: <Widget>[
                Expanded(child: _fieldValue()),
                if (field.verified) const _Pill('Verified'),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        S8Space.gutter,
        S8Space.pagePad,
        S8Space.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Notifications'),
          const SizedBox(height: S8Space.sectionGap),
          _Card(
            padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
            child: _InsetRows(
              children: <Widget>[
                for (final AccountToggle toggle in toggles)
                  _ToggleRow(toggle: toggle),
              ],
            ),
          ),
          const SizedBox(height: S8Space.sectionBreak),
          const _SectionLabel('App'),
          const SizedBox(height: S8Space.sectionGap),
          _Card(
            padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
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
          const SizedBox(height: S8Space.sectionBreak),
          const _SectionLabel('Privacy'),
          const SizedBox(height: S8Space.sectionGap),
          Expanded(
            child: _Card(
              padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
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
                  if (onConsents != null)
                    _LinkRow(
                      title: 'Your consents',
                      subtitle: 'Review or withdraw what you agreed to',
                      icon: TaytayIcons.shieldCheck,
                      tile: BrandColors.chipBlueBg,
                      color: BrandColors.taytayBlue,
                      onTap: onConsents,
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

/// Hairline inset to the row content. 08-01 / 08-04 / 08-10, x = 99–1070.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: S8Space.cardPad),
      child: ColoredBox(
        color: BrandColors.chipGreyBg,
        child: SizedBox(height: S8Space.divider, width: double.infinity),
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
          if (i > 0) const _RowDivider(),
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
        S8Space.gutter,
        S8Space.pagePad,
        S8Space.gutter,
        S8Space.pageBottom,
      ),
      children: <Widget>[
        _Card(
          padding: const EdgeInsets.fromLTRB(
            S8Space.cardPad,
            S8Space.cardPad,
            S8Space.cardPad,
            S8Space.aboutPadBottom,
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(
                width: S8Space.seal,
                height: S8Space.seal,
                child: Image(
                  image: AssetImage('assets/brand/taytay_seal.png'),
                  fit: BoxFit.contain,
                  semanticLabel: 'Seal of Taytay, Rizal',
                ),
              ),
              const SizedBox(height: S8Space.sealGap),
              _CssLines(
                text: 'Taytay Resident App',
                style: _aboutTitle,
                step: S8Space.line(14),
                align: TextAlign.center,
              ),
              const SizedBox(height: S8Space.titleGap),
              const _CssLines(
                text:
                    'Municipality of Taytay, Rizal · version 0.1 (design mockup)',
                style: _version,
                step: 13 * S8Space.versionLineHeight,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: S8Space.sectionBreak),
        const _SectionLabel('Photo credits'),
        const SizedBox(height: S8Space.sectionGap),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < welcome.length; i++) ...<Widget>[
                if (i > 0) const _RowDivider(),
                _CreditRow(credit: welcome[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: S8Space.cardGap),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
          child: _LinkRow(
            title: 'Office banner photos',
            subtitle: PhotoCredits.officeBannerSummary,
            icon: TaytayIcons.images,
            tile: BrandColors.chipBlueBg,
            color: BrandColors.taytayBlue,
            onTap: onBanners,
          ),
        ),
        const SizedBox(height: S8Space.sectionBreak),
        const _SectionLabel('About'),
        const SizedBox(height: S8Space.sectionGap),
        const _Card(
          padding: EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
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
        horizontal: S8Space.cardPad,
        vertical: S8Space.rowPadY,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const _Tile(
            icon: TaytayIcons.image,
            tile: Color(0xFFEAF0FB),
            color: BrandColors.taytayBlue,
          ),
          const SizedBox(width: S8Space.iconGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(credit.title, style: _creditTitle),
                const SizedBox(height: S8Space.titleGap),
                Text(credit.byline, style: _creditByline),
              ],
            ),
          ),
          const SizedBox(width: S8Space.iconGap),
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
        S8Space.gutter,
        S8Space.noticeInset,
        S8Space.gutter,
        S8Space.pageBottom,
      ),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DraftBanner(),
              SizedBox(height: S8Space.draftGap),
              Text('Privacy Notice', style: _noticeTitle),
              SizedBox(height: S8Space.titleGap),
              Text(
                'Republic Act No. 10173, Data Privacy Act of 2012',
                style: _meta,
              ),
              SizedBox(height: S8Space.cardGap),
              _Card(
                padding: EdgeInsets.all(S8Space.cardPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _NoticeBlock(
                      title: 'What we collect',
                      body:
                          'Name, contact details, address, valid ID and selfie, '
                          'and messages you send to offices.',
                    ),
                    SizedBox(height: S8Space.blockGap),
                    _NoticeBlock(
                      title: 'Why',
                      body:
                          'To verify that you are a Taytay resident and to '
                          'deliver the services you request.',
                    ),
                    SizedBox(height: S8Space.blockGap),
                    _NoticeBlock(
                      title: 'Who can see it',
                      body:
                          'Authorised LGU staff of the office you deal with. '
                          'Not sold or shared for marketing.',
                    ),
                    SizedBox(height: S8Space.blockGap),
                    _NoticeBlock(
                      title: 'Your rights',
                      body:
                          'Access, correction, objection and erasure. Contact '
                          'the LGU Data Protection Officer ',
                      trailing: SampleTag(lineHeight: S8Space.bodyLineHeight),
                      suffix: '.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDataExport) ...<Widget>[
          const SizedBox(height: S8Space.cardGap),
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
        S8Space.gutter,
        S8Space.pagePad,
        S8Space.gutter,
        S8Space.pageBottom,
      ),
      children: <Widget>[
        const Text('Privacy Notice', style: _noticeTitle),
        const SizedBox(height: S8Space.titleGap),
        const Text(
          'Republic Act No. 10173, Data Privacy Act of 2012',
          style: _meta,
        ),
        const SizedBox(height: S8Space.cardGap),
        _Card(
          padding: const EdgeInsets.fromLTRB(
            S8Space.cardPad,
            S8Space.cardPad,
            S8Space.cardPad,
            S8Space.cardPad,
          ),
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
  const _NoticeBlock({
    required this.title,
    required this.body,
    this.trailing,
    this.suffix = '',
  });

  final String title;
  final String body;

  /// The design draws this at the end of the last line of [body].
  final Widget? trailing;

  /// Text after [trailing]. The SAMPLE chip is followed by a period.
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = this.trailing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: S8Space.line(14),
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: _rowTitle),
          ),
        ),
        const SizedBox(height: S8Space.noticeGap),
        if (trailing == null)
          _CssLines(
            text: body,
            style: _noticeBody,
            step: 13 * S8Space.bodyLineHeight,
          )
        else
          _FlowLines(
            style: _noticeBody,
            step: 13 * S8Space.bodyLineHeight,
            // SAMPLE inherits the 13 / 1.5 line, so that line is 22.5.
            objectStep: 22.5,
            pieces: <_FlowPiece>[
              _FlowPiece.text(body),
              _FlowPiece.box(width: _sampleChipWidth(), child: trailing),
              if (suffix.isNotEmpty) _FlowPiece.text(suffix),
            ],
          ),
      ],
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
        S8Space.gutter,
        S8Space.pagePad,
        S8Space.gutter,
        S8Space.pageBottom,
      ),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: _BannerIntro(),
        ),
        const SizedBox(height: 10),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: S8Space.cardInsetY),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < rows.length; i++) ...<Widget>[
                if (i > 0) const _RowDivider(),
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
    height: S8Space.bodyLineHeight,
    leadingDistribution: TextLeadingDistribution.even,
    color: BrandColors.textSecondary,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    // The Replace chip inherits the 13 / 1.5 line, so its line is 22.5 and
    // the other lines stay 19.5. A forced strut rounded every line to 20
    // and the paragraph came out 60 instead of 61.5.
    return _FlowLines(
      style: _line,
      step: 13 * S8Space.bodyLineHeight,
      objectStep: 11 * S8Space.introLineHeight + 2 * S8Space.replacePadY,
      pieces: <_FlowPiece>[
        const _FlowPiece.text('All from Wikimedia Commons. Photos marked '),
        _FlowPiece.box(
          width: _replaceChipWidth(_introChip),
          child: const _ReplaceMark(intro: true),
        ),
        const _FlowPiece.text(
          ' show people and are placeholders until Taytay LGU '
          'supplies its own consented photos.',
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
    // The chip centres on the whole row, office label included.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        S8Space.cardPad,
        S8Space.bannerPadY,
        S8Space.cardPad,
        S8Space.bannerPadY,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Line(credit.offices.join(', '), _officeLabel),
                _CssLines(
                  text: credit.title,
                  style: _bannerTitle,
                  step: S8Space.line(13),
                ),
                const SizedBox(height: S8Space.titleGap),
                _CssLines(
                  text: credit.byline,
                  style: _creditByline,
                  step: S8Space.line(12),
                ),
              ],
            ),
          ),
          if (credit.replace) ...<Widget>[
            const SizedBox(width: S8Space.iconGap),
            const _ReplaceMark(),
          ],
        ],
      ),
    );
  }
}

/// Amber Replace chip, sitting on the right of the title row.
class _ReplaceMark extends StatelessWidget {
  const _ReplaceMark({this.intro = false});

  /// The sentence chip is taller than the chip on a credit row.
  final bool intro;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.chipAmberBg,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: S8Space.replacePadX,
          vertical: S8Space.replacePadY,
        ),
        child: SizedBox(
          height: intro ? 11 * S8Space.introLineHeight : S8Space.line(11),
          child: Text(
            'Replace',
            style: intro ? _introChip : _day,
            textHeightBehavior: S8Space.lineBox,
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
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.bubble});

  final AccountBubble bubble;

  @override
  Widget build(BuildContext context) {
    final bool mine = bubble.fromResident;
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
              child: _CssLines(
                text: bubble.body,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  height: S8Space.threadLineHeight,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  leadingDistribution: TextLeadingDistribution.even,
                  color: mine ? Colors.white : BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
                step: 13 * S8Space.threadLineHeight,
              ),
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
        border: Border.fromBorderSide(
          BorderSide(
            color: BrandColors.cardLine,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
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
      child: Padding(padding: padding + const EdgeInsets.all(1), child: child),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.tile,
    required this.color,
    this.size = S8Space.tile,
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
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF0FB),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: _initials,
        strutStyle: S8Space.strut(18, weight: FontWeight.w800),
        textHeightBehavior: S8Space.lineBox,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: BrandColors.chipGreenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const TaytayIcon(
            icon: TaytayIcons.badgeCheck,
            size: 12,
            color: BrandColors.success,
            semanticLabel: '',
            excludeSemantics: true,
          ),
          const SizedBox(width: Spacing.xs),
          SizedBox(
            height: 11 * 1.2,
            child: Text(
              label,
              style: _badge,
              textHeightBehavior: S8Space.lineBox,
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

/// Inbox filters. All is a filled pill. Unread is a white pill with a border.
class _AllFilter extends StatelessWidget {
  const _AllFilter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        _FilterPill(label: 'All', selected: true),
        SizedBox(width: S8Space.filterGapX),
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
    // Border-box: the 1 px stroke sits inside the 36 px height, and the 14 px
    // padding is inside that stroke. All is then 44.59 and Unread 72.56.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? BrandColors.taytayBlue : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.pill)),
        border: Border.all(
          color: selected ? BrandColors.taytayBlue : _chipBorder,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: SizedBox(
        height: S8Space.filterHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: S8Space.normal,
                letterSpacing: 0,
                leadingDistribution: TextLeadingDistribution.even,
                color: selected ? Colors.white : _chipInk,
                decoration: TextDecoration.none,
              ),
              strutStyle: S8Space.strut(12, weight: FontWeight.w700),
              textHeightBehavior: S8Space.lineBox,
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
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: S8Space.dayPadX,
          vertical: S8Space.dayPadY,
        ),
        child: SizedBox(
          height: S8Space.line(11),
          child: Text(
            label,
            style: _day.copyWith(color: Colors.white),
            textHeightBehavior: S8Space.lineBox,
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.chipAmberBg,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: S8Space.dayPadX,
          vertical: S8Space.dayPadY,
        ),
        child: SizedBox(
          height: S8Space.line(11),
          child: const Text(
            'DRAFT · LGU-approved text to be inserted',
            style: _draft,
            textHeightBehavior: S8Space.lineBox,
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
                    style: _photoInitials,
                    strutStyle: S8Space.strut(24, weight: FontWeight.w800),
                    textHeightBehavior: S8Space.lineBox,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BrandColors.taytayBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
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
          const SizedBox(height: 6),
          const Text(
            'Profile photo · reviewed by LGU before it appears on your ID',
            textAlign: TextAlign.center,
            style: _photoNote,
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
        height: S8Space.buttonHeight,
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

/// 08-06 empty state. The circle is 72, the title is 16 / normal, and the
/// body is 13 / 1.5. Padding is 28 × 18 inside the page gutter.
class _EmptyCopy extends StatelessWidget {
  const _EmptyCopy({
    required this.title,
    required this.body,
    required this.button,
    this.buttonIcon,
    this.note,
    this.onButton,
  });

  final String title;
  final String body;
  final String button;
  final IconData? buttonIcon;
  final String? note;
  final VoidCallback? onButton;

  @override
  Widget build(BuildContext context) {
    final String? note = this.note;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        S8Space.emptyPadX,
        S8Space.emptyPadY,
        S8Space.emptyPadX,
        S8Space.emptyPadY,
      ),
      child: Column(
        children: <Widget>[
          const _EmptyMark(),
          const SizedBox(height: S8Space.emptyTitleGap),
          _Line(title, _emptyTitle, align: Alignment.center),
          const SizedBox(height: S8Space.emptyBodyGap),
          _CssLines(
            text: body,
            style: _emptyBody,
            step: 13 * S8Space.bodyLineHeight,
            align: TextAlign.center,
          ),
          const SizedBox(height: S8Space.emptyButtonGap),
          _PrimaryButton(label: button, icon: buttonIcon, onTap: onButton),
          if (note != null) ...<Widget>[
            const SizedBox(height: S8Space.emptyNoteGap),
            _Line(note, _meta, align: Alignment.center),
          ],
        ],
      ),
    );
  }
}

class _EmptyMark extends StatelessWidget {
  const _EmptyMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: S8Space.emptyCircle,
      height: S8Space.emptyCircle,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF0FB),
        shape: BoxShape.circle,
      ),
      child: const TaytayIcon(
        icon: TaytayIcons.inbox,
        size: S8Space.emptyIcon,
        color: BrandColors.taytayBlue,
        semanticLabel: '',
        excludeSemantics: true,
      ),
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
        height: S8Space.fieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: S8Space.fieldPadX),
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
        height: S8Space.buttonHeight,
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
          horizontal: S8Space.cardPad,
          vertical: S8Space.rowPadY,
        ),
        child: Row(
          children: <Widget>[
            _Tile(icon: icon, tile: tile, color: color),
            const SizedBox(width: S8Space.iconGap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: _rowTitle),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: S8Space.titleGap),
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
          horizontal: S8Space.cardPad,
          vertical: S8Space.rowPadY,
        ),
        child: Row(
          children: <Widget>[
            _Tile(
              icon: toggle.icon,
              tile: toggle.tile,
              color: toggle.iconColor,
            ),
            const SizedBox(width: S8Space.iconGap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(toggle.title, style: _rowTitle),
                  const SizedBox(height: S8Space.titleGap),
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
      style: _section,
      strutStyle: S8Space.strut(15, weight: FontWeight.w800),
      textHeightBehavior: S8Space.lineBox,
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
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _emptyBody = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: S8Space.bodyLineHeight,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _name = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _initials = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 18,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

const TextStyle _location = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: S8Space.bodyLineHeight,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _badge = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  height: 1.2,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.success,
  decoration: TextDecoration.none,
);

const TextStyle _rowTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _meta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _label = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.fieldLabel,
  decoration: TextDecoration.none,
);

/// Unselected filter ink. CSS `.chip` is `#33405C`.
const Color _chipInk = Color(0xFF33405C);

/// Unselected filter stroke. CSS `.chip` border is `#E1E6F0`.
const Color _chipBorder = Color(0xFFE1E6F0);

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

const TextStyle _draft = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  letterSpacing: 0,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.warning,
  decoration: TextDecoration.none,
);

const TextStyle _introChip = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  height: S8Space.introLineHeight,
  letterSpacing: 0,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.warning,
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

const TextStyle _section = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _aboutTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _version = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: S8Space.versionLineHeight,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _photoInitials = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 24,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

const TextStyle _photoNote = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _fieldInk = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.fieldInk,
  decoration: TextDecoration.none,
);

const TextStyle _legal = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _creditTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _noticeBody = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: S8Space.bodyLineHeight,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.sheetBody,
  decoration: TextDecoration.none,
);

const TextStyle _creditByline = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _noticeTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 20,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  letterSpacing: -0.4,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _bannerTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _officeLabel = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w800,
  height: S8Space.normal,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.taytayBlue,
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

/// Replace chip border box. Padding [S8Space.replacePadX], no border.
double _replaceChipWidth(TextStyle style) {
  return _spanWidth('Replace', style) + S8Space.replacePadX * 2;
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

/// One CSS line, in Chrome's device-pixel line box rather than Flutter's
/// rounded strut.
class _Line extends StatelessWidget {
  const _Line(this.text, this.style, {this.align = Alignment.centerLeft});

  final String text;
  final TextStyle style;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: S8Space.line(style.fontSize ?? 14),
      child: Align(
        alignment: align,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align == Alignment.center ? TextAlign.center : null,
          style: style,
          textHeightBehavior: S8Space.lineBox,
        ),
      ),
    );
  }
}

/// A text run or a fixed-width chip inside [_FlowLines].
class _FlowPiece {
  const _FlowPiece.text(this.text) : child = null, width = 0;

  const _FlowPiece.box({required this.width, required this.child}) : text = '';

  final String text;
  final Widget? child;
  final double width;
}

class _Run {
  _Run.text(this.text) : child = null, width = 0;

  _Run.box(this.child, this.width) : text = '';

  final String text;
  final Widget? child;
  final double width;
}

/// Wraps [pieces] onto Chrome's line step.
///
/// A line that contains a chip uses [objectStep] (the chip's border box).
/// Other lines use [step]. Flutter's strut would round both to a whole pixel.
class _FlowLines extends StatelessWidget {
  const _FlowLines({
    required this.pieces,
    required this.style,
    required this.step,
    this.objectStep,
  });

  final List<_FlowPiece> pieces;
  final TextStyle style;
  final double step;
  final double? objectStep;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final List<List<_Run>> lines = _wrap(maxWidth);
        var top = 0.0;
        final List<Widget> children = <Widget>[];
        for (final List<_Run> line in lines) {
          final bool object = line.any((_Run run) => run.child != null);
          final double height = object ? (objectStep ?? step) : step;
          final StringBuffer words = StringBuffer();
          final List<Widget> row = <Widget>[];
          void flush() {
            if (words.isEmpty) return;
            row.add(
              Text(
                words.toString(),
                style: style,
                textHeightBehavior: S8Space.lineBox,
              ),
            );
            words.clear();
          }

          for (final _Run run in line) {
            final Widget? child = run.child;
            if (child != null) {
              flush();
              // The reserved width is the Chrome border box. A test font is
              // wider than Plus Jakarta, and an unconstrained chip then
              // overflows the line.
              row.add(SizedBox(width: run.width, child: child));
            } else {
              words.write(run.text);
            }
          }
          flush();
          children.add(
            Positioned(
              top: top,
              left: 0,
              right: 0,
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: row,
              ),
            ),
          );
          top += height;
        }
        return SizedBox(
          width: maxWidth,
          height: top,
          child: Stack(clipBehavior: Clip.none, children: children),
        );
      },
    );
  }

  List<List<_Run>> _wrap(double maxWidth) {
    final List<_Run> tokens = <_Run>[];
    for (final _FlowPiece piece in pieces) {
      final Widget? child = piece.child;
      if (child != null) {
        tokens.add(_Run.box(child, piece.width));
        continue;
      }
      for (final String part in piece.text.split(RegExp(r'(?<= )'))) {
        if (part.isEmpty) continue;
        tokens.add(_Run.text(part));
      }
    }
    final List<List<_Run>> lines = <List<_Run>>[];
    var line = <_Run>[];
    var used = 0.0;
    for (final _Run token in tokens) {
      final bool box = token.child != null;
      final String raw = box ? '' : token.text;
      final double width = box ? token.width : _measure(raw);
      if (line.isNotEmpty && used + width > maxWidth + 0.05) {
        lines.add(line);
        if (box) {
          line = <_Run>[token];
          used = width;
        } else {
          final String word = raw.trimLeft();
          if (word.isEmpty) {
            line = <_Run>[];
            used = 0;
            continue;
          }
          line = <_Run>[_Run.text(word)];
          used = _measure(word);
        }
      } else {
        if (!box && raw.trim().isEmpty && line.isEmpty) continue;
        line.add(token);
        used += width;
      }
    }
    if (line.isNotEmpty) lines.add(line);
    return lines;
  }

  double _measure(String text) {
    if (text.isEmpty) return 0;
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
    this.align = TextAlign.start,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final double step;
  final TextAlign align;
  final int? maxLines;

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
