import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../domain/photo_credit.dart';

/// Which My Account frame the canvas is painting.
enum AccountFrame {
  home,
  inbox,
  inboxEmpty,
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tile;
  final Color iconColor;
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
    this.onTap,
  });

  final String office;
  final String when;
  final String preview;
  final IconData icon;
  final Color tile;
  final Color iconColor;
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
    this.onTap,
  });

  final String label;
  final String value;
  final bool verified;
  final bool chevron;
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
    this.onMessageOffice,
    this.fields = AccountSpecimen.fields,
    this.onSave,
    this.onLegalName,
    this.toggles = AccountSpecimen.toggles,
    this.onLanguage,
    this.onChangePassword,
    this.changePasswordSubtitle = 'From the sign-in screen',
    this.onPrivacy,
    this.onBanners,
    this.onExport,
    this.showDataExport = true,
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
      AccountFrame.inbox => _InboxBody(rows: inbox),
      AccountFrame.inboxEmpty => _EmptyInbox(onMessageOffice: onMessageOffice),
      AccountFrame.editProfile => _EditBody(
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
        onSend: onSend,
      ),
      AccountFrame.privacy => _PrivacyBody(
        onExport: onExport,
        showDataExport: showDataExport,
      ),
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
      icon: TaytayIcons.circleUser,
      tile: Color(0xFFEAF0FB),
      iconColor: BrandColors.taytayBlue,
    ),
    AccountMenuRow(
      title: 'Messages',
      subtitle: '1 new reply from BPLO',
      icon: TaytayIcons.messageSquare,
      tile: Color(0xFFE7F6EE),
      iconColor: BrandColors.success,
    ),
    AccountMenuRow(
      title: 'Verification status',
      subtitle: 'Verified · Oct 22, 2026',
      icon: TaytayIcons.badgeCheck,
      tile: Color(0xFFFFF4D6),
      iconColor: BrandColors.warning,
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
      icon: TaytayIcons.shield,
      tile: Color(0xFFE7F6EE),
      iconColor: BrandColors.success,
    ),
    AccountMenuRow(
      title: 'Photo credits & about',
      subtitle: 'Licences, app version',
      icon: TaytayIcons.image,
      tile: Color(0xFFFFF4D6),
      iconColor: BrandColors.warning,
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
      icon: TaytayIcons.newspaper,
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
                      child: TaytayIcon(
                        icon: TaytayIcons.bell,
                        size: 20,
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
  const _InboxBody({required this.rows});

  final List<AccountInboxRow> rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
      children: <Widget>[
        const _UnreadMark(),
        const SizedBox(height: 12),
        SizedBox(
          height: 652 / 3,
          child: _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (var i = 0; i < rows.length; i++) ...<Widget>[
                  if (i > 0)
                    const ColoredBox(
                      color: Color(0xFFEEF1F6),
                      child: SizedBox(height: 1, width: double.infinity),
                    ),
                  SizedBox(
                    height: const <double>[230 / 3, 204 / 3, 212 / 3][i],
                    child: _InboxRow(
                      row: rows[i],
                      lift: const <double>[46 / 3, 10 / 3, 18 / 3][i],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 43 / 3),
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
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.row, this.lift = 0});

  final AccountInboxRow row;
  final double lift;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      label: row.office,
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
                  Row(
                    children: <Widget>[
                      Expanded(child: Text(row.office, style: _rowTitle)),
                      Text(row.when, style: _meta),
                    ],
                  ),
                  Text(
                    row.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _meta,
                  ),
                ],
              ),
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
        const _UnreadMark(),
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

class _EditBody extends StatelessWidget {
  const _EditBody({required this.fields, this.onSave, this.onLegalName});

  final List<AccountField> fields;
  final VoidCallback? onSave;
  final VoidCallback? onLegalName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: <Widget>[
        const _PhotoNote(),
        const SizedBox(height: 12),
        _Card(
          // 53/3 keeps the name label on the design line; the label-to-box
          // gap below puts that space back under the label only.
          padding: const EdgeInsets.fromLTRB(16 / 3, 53 / 3, 16 / 3, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < fields.length; i++) ...<Widget>[
                if (i == 1)
                  GestureDetector(
                    onTap: onLegalName,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 11.5),
                      child: Text(
                        'Legal name changes go through Resident Profile and '
                        're-verification.',
                        style: _legal,
                      ),
                    ),
                  ),
                _EditField(
                  field: fields[i],
                  gapLabel: i == 0
                      ? 20 / 3
                      : i == 1
                      ? 17 / 3
                      : 6,
                  gapAfter: i == 1
                      ? 46 / 3
                      : i == 2
                      ? 15
                      : 4,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 34 / 3),
        _PrimaryButton(
          label: 'Save changes',
          icon: TaytayIcons.check,
          onTap: onSave,
        ),
      ],
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({required this.field, this.gapLabel = 4, this.gapAfter = 4});

  final AccountField field;
  final double gapLabel;
  final double gapAfter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: gapAfter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(field.label, style: _label),
          SizedBox(height: gapLabel),
          _FieldBox(
            onTap: field.onTap,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    field.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _fieldInk,
                  ),
                ),
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
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.toggles,
    this.onLanguage,
    this.onChangePassword,
    this.changePasswordSubtitle = 'From the sign-in screen',
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
      padding: const EdgeInsets.fromLTRB(16, 52 / 3, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('NOTIFICATIONS'),
          const SizedBox(height: 35 / 3),
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
          const SizedBox(height: 18),
          const _SectionLabel('APP'),
          const SizedBox(height: 35 / 3),
          _Card(
            padding: EdgeInsets.zero,
            child: _FixedRows(
              heights: const <double>[71, 71],
              lifts: const <double>[0, 0],
              drops: const <double>[0, 8 / 3],
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
                  tile: const Color(0xFFFFF4D6),
                  color: BrandColors.warning,
                  onTap: onChangePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 52 / 3),
          const _SectionLabel('PRIVACY'),
          const SizedBox(height: 11),
          Expanded(
            child: _Card(
              padding: EdgeInsets.zero,
              child: _FixedRows(
                heights: const <double>[71, 71],
                lifts: const <double>[0, 0],
                drops: const <double>[22 / 3, 14 / 3],
                children: <Widget>[
                  _LinkRow(
                    title: 'Privacy Notice',
                    subtitle:
                        'Data Privacy Act of 2012 · LGU-approved text pending',
                    subtitleHeight: 53 / 36,
                    icon: TaytayIcons.fileText,
                    tile: const Color(0xFFE7F6EE),
                    color: BrandColors.success,
                    onTap: onPrivacy,
                  ),
                  if (showDataExport)
                    _LinkRow(
                      title: 'Request a copy of my data',
                      subtitle: 'Right to access',
                      icon: TaytayIcons.shield,
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
        const SizedBox(height: 51 / 3),
        const _SectionLabel('PHOTO CREDITS'),
        const SizedBox(height: 35 / 3),
        _Card(
          padding: const EdgeInsets.fromLTRB(16, 65 / 3, 16, 89 / 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < welcome.length; i++)
                _CreditRow(
                  title: welcome[i].title,
                  subtitle: welcome[i].byline,
                  gapAfter: i == welcome.length - 1 ? 0 : 142 / 3,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 74,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _LinkRow(
                title: 'Office banner photos',
                subtitle: PhotoCredits.officeBannerSummary,
                icon: TaytayIcons.image,
                tile: const Color(0xFFEAF0FB),
                color: BrandColors.taytayBlue,
                onTap: onBanners,
              ),
            ),
          ),
        ),
        const SizedBox(height: 53 / 3),
        const _SectionLabel('ABOUT'),
        const SizedBox(height: 34 / 3),
        const _Card(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 74,
            child: Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: _LinkRow(
                title: 'Municipal seal',
                subtitle: 'Described on taytayrizal.gov.ph/seal · Wikimedia',
                subtitleSize: 11,
                icon: TaytayIcons.landmark,
                tile: Color(0xFFFFF4D6),
                color: BrandColors.warning,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({
    required this.title,
    required this.subtitle,
    this.gapAfter = 0,
  });

  final String title;
  final String subtitle;
  final double gapAfter;

  @override
  Widget build(BuildContext context) {
    // The byline sits over the title's descenders so the two are one dark
    // run. The slot stays tall enough for the next credit's 208 px pitch.
    return Padding(
      padding: EdgeInsets.only(bottom: gapAfter),
      child: SizedBox(
        height: 22,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Text(
              title,
              style: _creditTitle,
              strutStyle: const StrutStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                height: 1,
                forceStrutHeight: true,
              ),
            ),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Text(
                subtitle,
                style: _creditByline,
                strutStyle: const StrutStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  height: 1,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 22 / 3, 16, 24),
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
                padding: EdgeInsets.fromLTRB(14, 16, 14, 9),
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
                          'the LGU Data Protection Officer. SAMPLE.',
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
            icon: TaytayIcons.shield,
            onTap: onExport,
          ),
        ],
      ],
    );
  }
}

class _NoticeBlock extends StatelessWidget {
  const _NoticeBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: _rowTitle),
          const SizedBox(height: 20 / 3),
          Text(body, style: _noticeBody),
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
      padding: const EdgeInsets.fromLTRB(16, 62 / 3, 16, 24),
      children: <Widget>[
        const _BannerIntro(),
        const SizedBox(height: 38 / 3),
        _Card(
          padding: const EdgeInsets.fromLTRB(16 / 3, 37 / 3, 16 / 3, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final PhotoCredit credit in rows)
                _BannerRow(
                  credit: credit,
                  // The relief row wraps its title and byline, so the next
                  // office starts further down than the 184 px pitch.
                  pitch: credit.assetKey == 'mswdo_relief'
                      ? 278 / 3
                      : credit.assetKey == 'rescuers'
                      ? 220 / 3
                      : 184 / 3,
                ),
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
  const _BannerRow({required this.credit, required this.pitch});

  final PhotoCredit credit;
  final double pitch;

  static const StrutStyle _kickerStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    height: 1,
    forceStrutHeight: true,
  );

  static const StrutStyle _titleStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 1,
    forceStrutHeight: true,
  );

  static const StrutStyle _bylineStrut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 1.25,
    forceStrutHeight: true,
    leadingDistribution: TextLeadingDistribution.proportional,
  );

  @override
  Widget build(BuildContext context) {
    final bool relief = credit.assetKey == 'mswdo_relief';
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: pitch),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            credit.offices.join(', '),
            style: _kicker,
            strutStyle: _kickerStrut,
          ),
          const SizedBox(height: 10 / 3),
          if (relief)
            const Text(
              'DSWD relief distribution (2026',
              style: _bannerTitle,
              strutStyle: _titleStrut,
            )
          else if (credit.assetKey == 'rescuers')
            SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          credit.title,
                          style: _bannerTitle,
                          strutStyle: _titleStrut,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _ReplaceMark(),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Text(
                      '${credit.author} ·\n${credit.licence}',
                      style: _creditByline,
                      strutStyle: const StrutStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        height: 1.6,
                        forceStrutHeight: true,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    credit.title,
                    style: _bannerTitle,
                    strutStyle: _titleStrut,
                  ),
                ),
                if (credit.replace) ...<Widget>[
                  const SizedBox(width: 8),
                  const _ReplaceMark(),
                ],
              ],
            ),
          if (relief) ...<Widget>[
            const SizedBox(height: 7 / 3),
            const Row(
              children: <Widget>[
                Text(
                  'earthquake)',
                  style: _bannerTitle,
                  strutStyle: _titleStrut,
                ),
                SizedBox(width: 8),
                _ReplaceMark(),
              ],
            ),
          ],
          if (credit.assetKey != 'rescuers') ...<Widget>[
            const SizedBox(height: 8 / 3),
            Text(credit.byline, style: _creditByline, strutStyle: _bylineStrut),
          ],
        ],
      ),
    );
  }
}

/// The Replace chip, kept to one title-line of layout so it does not push
/// the byline down.
class _ReplaceMark extends StatelessWidget {
  const _ReplaceMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 78,
      height: 14,
      child: OverflowBox(
        maxWidth: 78,
        maxHeight: 22,
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFEEF1F6),
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Replace',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
                color: BrandColors.fieldLabel,
                decoration: TextDecoration.none,
              ),
            ),
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
    this.onSend,
  });

  final List<AccountBubble> bubbles;
  final String dayLabel;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 57 / 3, 16, 8),
            children: <Widget>[
              Center(child: _Chip(dayLabel)),
              const SizedBox(height: 22 / 3),
              for (var i = 0; i < bubbles.length; i++)
                Padding(
                  // The last bubble's border sits one dp high of the specimen.
                  padding: EdgeInsets.only(
                    top: i == bubbles.length - 1 ? 1 : 0,
                  ),
                  child: _Bubble(bubble: bubbles[i]),
                ),
              const SizedBox(height: 2),
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
  const _Tile({required this.icon, required this.tile, required this.color});

  final IconData icon;
  final Color tile;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
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
      child: Text(
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
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: _label),
    );
  }
}

/// Blue ring and the word Unread. The ring is 36 dp, which is the dark run
/// under the messages header. The hit target overflows to 48 dp.
class _UnreadMark extends StatelessWidget {
  const _UnreadMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 36,
            height: 36,
            child: OverflowBox(
              maxWidth: 48,
              maxHeight: 48,
              child: Semantics(
                button: true,
                label: 'Unread',
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: _UnreadRing()),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Unread', style: _rowTitle),
        ],
      ),
    );
  }
}

class _UnreadRing extends StatelessWidget {
  const _UnreadRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: BrandColors.taytayBlue,
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 4),
      decoration: BoxDecoration(
        color: BrandColors.chipAmberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrandColors.sampleBorder),
      ),
      child: const Text(
        'DRAFT — LGU-approved text to be inserted',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: BrandColors.warning,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _PhotoNote extends StatelessWidget {
  const _PhotoNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 134 / 3),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 54,
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topCenter,
                  child: TaytayIcon(
                    icon: TaytayIcons.camera,
                    size: 24,
                    color: BrandColors.taytayBlue,
                    semanticLabel: '',
                    excludeSemantics: true,
                  ),
                ),
                Positioned(
                  top: 25,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment(0.55, 0),
                    child: TaytayIcon(
                      icon: TaytayIcons.circleUser,
                      size: 24,
                      color: BrandColors.taytayBlue,
                      semanticLabel: '',
                      excludeSemantics: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Profile photo — reviewed by LGU before it appears on your ID',
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
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
                  fontWeight: FontWeight.w700,
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
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, this.onTap});

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
          color: BrandColors.taytayBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TaytayIcon(
              icon: icon,
              size: 16,
              color: Colors.white,
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
    required this.subtitle,
    required this.icon,
    required this.tile,
    required this.color,
    this.subtitleHeight,
    this.subtitleSize,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tile;
  final Color color;
  final double? subtitleHeight;
  final double? subtitleSize;
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
                  Text(title, style: _rowTitle),
                  Text(
                    subtitle,
                    style: subtitleHeight == null && subtitleSize == null
                        ? _meta
                        : _meta.copyWith(
                            height: subtitleHeight,
                            fontSize: subtitleSize,
                          ),
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
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: BrandColors.listMeta,
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
  height: 1.28,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _kicker = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  height: 1,
  letterSpacing: 0.4,
  color: BrandColors.fieldLabel,
  decoration: TextDecoration.none,
);

const TextStyle _hint = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: BrandColors.fieldHint,
  decoration: TextDecoration.none,
);
