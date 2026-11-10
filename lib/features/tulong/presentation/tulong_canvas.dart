import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/ringed_input_border.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/detail_page.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/pill_button_row.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/social_service.dart';

/// Which Tulong frame the canvas is painting.
enum TulongFrame { list, detail, offline, loading }

/// The Tulong tab, a service page, the featured page, and offline.
///
/// The tab is the glass main-tab pattern (`Home.dc.html` / `Balita.dc.html`):
/// the blue header with the search field, the list in a glass card. A service
/// page is the `Office.dc.html` detail pattern: the hero photo when the API
/// has one (otherwise the blue header), then the white sheet with pill
/// actions. The shell paints the tab bar and the offline banner.
///
/// A service uses the featured layout when it has a featured headline and at
/// least one claim step. The `featured` boolean alone does not.
class TulongCanvas extends StatelessWidget {
  const TulongCanvas({
    required this.frame,
    this.services = const <SocialService>[],
    this.service,
    this.saved = const <SocialService>[],
    this.offlineSubtitle = 'Social services · MSWDO',
    this.emptyMessage,
    this.onOpen,
    this.onBell,
    this.onBack,
    this.onRetry,
    this.onCall,
    this.onDirections,
    this.onMessage,
    this.onShare,
    this.onOffice,
    this.onSearch,
    this.searchController,
    this.loadHero,
    super.key,
  });

  final TulongFrame frame;
  final List<SocialService> services;
  final SocialService? service;
  final List<SocialService> saved;

  /// The offline header's second line. A live failure passes the list
  /// subtitle instead of inventing an office.
  final String offlineSubtitle;

  /// The empty state's title when a search matches nothing.
  final String? emptyMessage;

  final ValueChanged<SocialService>? onOpen;
  final VoidCallback? onBell;
  final VoidCallback? onBack;
  final VoidCallback? onRetry;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;
  final VoidCallback? onShare;
  final VoidCallback? onOffice;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;

  /// `GET /services/{slug}/hero` when the service has a hero URL.
  /// Null on a dev mock. The list does not paint it.
  final MediaBytesLoader? loadHero;

  /// The tab's second line.
  static const String listSubtitle = 'Social services & programmes';

  @override
  Widget build(BuildContext context) {
    final SocialService? current = service;
    return Material(
      type: MaterialType.transparency,
      child: frame == TulongFrame.detail && current != null
          ? _DetailPage(
              service: current,
              loadHero: loadHero,
              onBack: onBack,
              onCall: onCall,
              onDirections: onDirections,
              onMessage: onMessage,
              onOffice: onOffice,
              onShare: onShare,
            )
          : _ListPage(canvas: this),
    );
  }
}

/// The glass tab: blue header with the seal, the bell and the search field,
/// then the frame's body pulled up over the header.
class _ListPage extends StatelessWidget {
  const _ListPage({required this.canvas});

  final TulongCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final TulongCanvas c = canvas;
    final bool offline = c.frame == TulongFrame.offline;
    return GlassBackground(
      child: ListView(
        // No per-item repaint / semantics wrappers: they hit-test only their
        // own box, so the strip GlassOverlap raises over the header would not
        // take a tap.
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        children: <Widget>[
          BlueHeader(
            overlap: true,
            leading: const HeaderSeal(),
            title: 'Tulong',
            subtitle: offline ? c.offlineSubtitle : TulongCanvas.listSubtitle,
            actions: <Widget>[
              HeaderIconButton(
                key: const Key('tulong-bell'),
                icon: TaytayIcons.bell,
                semanticLabel: 'Notifications',
                onPressed: c.onBell,
              ),
            ],
            bottom: offline
                ? null
                : _SearchField(
                    controller: c.searchController,
                    onChanged: c.onSearch,
                  ),
          ),
          GlassOverlap(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: _body(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(TulongCanvas c) {
    return switch (c.frame) {
      TulongFrame.loading => const LoadingSkeleton(
        count: 6,
        semanticLabel: 'Loading programmes',
      ),
      TulongFrame.offline => _OfflineBody(
        saved: c.saved,
        onRetry: c.onRetry,
        onOpen: c.onOpen,
      ),
      _ => _ListBody(
        services: c.services,
        emptyMessage: c.emptyMessage,
        onOpen: c.onOpen,
      ),
    };
  }
}

/// CSS `.soft .search` on the blue header: white, 16 radius, the search
/// glyph, and a gold focus ring.
class _SearchField extends StatelessWidget {
  const _SearchField({this.controller, this.onChanged});

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    const BorderRadius corners = BorderRadius.all(Radius.circular(Radii.lg));
    return TextField(
      key: const Key('tulong-search'),
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onChanged,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      style: AppTypography.fieldValue.copyWith(
        fontWeight: AppTypography.body,
        color: BrandColors.ink,
      ),
      decoration: InputDecoration(
        hintText: 'Search programmes',
        filled: true,
        fillColor: BrandColors.white,
        constraints: const BoxConstraints(
          minHeight: ComponentSizes.fieldHeight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        prefixIcon: const TaytayIcon(
          icon: TaytayIcons.search,
          semanticLabel: '',
          excludeSemantics: true,
          size: IconSizes.sm,
          color: BrandColors.muted,
        ),
        border: const RingedInputBorder(
          borderSide: BorderSide.none,
          borderRadius: corners,
        ),
        enabledBorder: const RingedInputBorder(
          borderSide: BorderSide.none,
          borderRadius: corners,
        ),
        focusedBorder: RingedInputBorder(
          borderSide: BorderSide.none,
          borderRadius: corners,
          ring: BorderSide(
            color: BrandColors.gold.withValues(alpha: 0.7),
            width: FocusRing.ringWidth,
          ),
        ),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({required this.services, this.emptyMessage, this.onOpen});

  final List<SocialService> services;
  final String? emptyMessage;
  final ValueChanged<SocialService>? onOpen;

  @override
  Widget build(BuildContext context) {
    final String? noMatch = emptyMessage;
    final ValueChanged<SocialService>? open = onOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (services.isNotEmpty)
          SettingsList(
            glass: true,
            children: <Widget>[
              for (final SocialService service in services)
                _ServiceRow(
                  service: service,
                  onTap: open == null ? null : () => open(service),
                ),
            ],
          )
        else if (noMatch != null)
          EmptyState(
            title: noMatch,
            message:
                'Try another word, or clear the search to see every '
                'programme.',
            boxed: true,
          )
        else
          const EmptyState(
            title: 'No programmes listed yet',
            message: 'Programme information from Taytay LGU will appear here.',
            boxed: true,
          ),
        const _Note(),
      ],
    );
  }
}

/// Tulong is information, never an application. Said under the list.
class _Note extends StatelessWidget {
  const _Note();

  static const String copy =
      'Information on municipal programmes. These are information pages, not applications.';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xs, Spacing.md, Spacing.xs, 0),
      child: Text(
        copy,
        style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service, this.onTap, this.saved = false});

  final SocialService service;
  final VoidCallback? onTap;

  /// A saved row reads the saved line and may carry the sample tag.
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final bool sample = saved && (service.presentation?.heroSample ?? false);
    return SettingsRow(
      key: Key('tulong-open-${service.slug}'),
      title: saved ? service.name : service.listTitle,
      detail: saved ? service.savedLine : service.summary,
      leading: _ServiceTile(service: service),
      trailing: sample ? const SampleTag() : null,
      titleMaxLines: 2,
      detailMaxLines: 2,
      onTap: onTap,
    );
  }
}

/// The service's gradient tile (CSS `.gt`). The icon is the service's own
/// Lucide glyph (the API's icon key); the tone follows its tile colour.
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    this.tileSize = IconTileSize.medium,
  });

  final SocialService service;
  final IconTileSize tileSize;

  @override
  Widget build(BuildContext context) {
    final BrandGradient gradient = BrandGradients.tile(
      _toneOf(service.tileColor),
    );
    return ExcludeSemantics(
      child: Container(
        key: Key('tulong-tile-${service.slug}'),
        width: tileSize.dimension,
        height: tileSize.dimension,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient.toLinearGradient(),
          borderRadius: BorderRadius.circular(tileSize.radius),
        ),
        child: TaytayIcon(
          icon: _glyph(service.iconKey),
          semanticLabel: '',
          excludeSemantics: true,
          size: tileSize.glyphSize,
          color: gradient.onColor,
        ),
      ),
    );
  }
}

/// The list could not be read: the offline state with Try again, then the
/// pages this phone kept.
class _OfflineBody extends StatelessWidget {
  const _OfflineBody({required this.saved, this.onRetry, this.onOpen});

  final List<SocialService> saved;
  final VoidCallback? onRetry;
  final ValueChanged<SocialService>? onOpen;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<SocialService>? open = onOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ErrorState(
          title: 'Programme pages need a connection',
          message: saved.isEmpty
              ? "We couldn't load the latest programme information."
              : "We couldn't load the latest programme information. Pages "
                    'you opened before are saved below.',
          onRetry: onRetry,
          offline: true,
          boxed: true,
        ),
        if (saved.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.formGap),
          const SettingsSectionTitle('Saved pages'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xxs,
              0,
              Spacing.xxs,
              Spacing.sm,
            ),
            child: Text(
              'Showing what was saved on this phone',
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
          ),
          SettingsList(
            glass: true,
            children: <Widget>[
              for (final SocialService service in saved)
                _ServiceRow(
                  service: service,
                  saved: true,
                  onTap: open == null ? null : () => open(service),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A service page. The hero photo arrives through the API; until it does
/// (or when there is none) the page has the blue header instead.
class _DetailPage extends StatelessWidget {
  const _DetailPage({
    required this.service,
    this.loadHero,
    this.onBack,
    this.onCall,
    this.onDirections,
    this.onMessage,
    this.onOffice,
    this.onShare,
  });

  final SocialService service;
  final MediaBytesLoader? loadHero;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;
  final VoidCallback? onOffice;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final String? url = service.heroUrl;
    final MediaBytesLoader? load = loadHero;
    if (url == null || url.isEmpty || load == null) return _page(null);
    return MediaBytesHost(id: service.slug, load: load, builder: _page);
  }

  Widget _page(Uint8List? bytes) {
    final Widget sheet = DetailSheet(
      children: service.showsFeaturedLayout
          ? _featured(service, onShare)
          : _standard(
              service,
              onCall: onCall,
              onDirections: onDirections,
              onMessage: onMessage,
              onOffice: onOffice,
            ),
    );
    return ColoredBox(
      color: BrandColors.white,
      child: ListView(
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        children: <Widget>[
          if (bytes != null && bytes.isNotEmpty) ...<Widget>[
            DetailHero(
              onBack: onBack,
              photo: DecodedMemoryImage(
                bytes: bytes,
                height: DetailHero.photoHeight,
                semanticLabel: service.name,
                placeholder: const SizedBox.expand(),
              ),
            ),
            GlassOverlap(amount: Radii.sheetLarge, child: sheet),
          ] else ...<Widget>[
            BlueHeader(
              title: service.headerTitle,
              subtitle: service.headerSubtitle,
              showBack: true,
              onBack: onBack,
            ),
            sheet,
          ],
        ],
      ),
    );
  }
}

/// The service page: tile and name, Call / Directions / Message, what the
/// programme is, who can avail, the requirements (information only), the
/// office's facts and the legal source.
List<Widget> _standard(
  SocialService service, {
  VoidCallback? onCall,
  VoidCallback? onDirections,
  VoidCallback? onMessage,
  VoidCallback? onOffice,
}) {
  final String? eligibility = service.eligibility;
  final String? source = service.legalBasis;
  final List<_Fact> facts = _factsOf(service);
  return <Widget>[
    _SheetTitle(service: service, title: service.name),
    const SizedBox(height: Spacing.formGap),
    PillButtonRow(
      padding: EdgeInsets.zero,
      wrap: true,
      actions: <PillAction>[
        PillAction(
          buttonKey: const Key('tulong-call'),
          label: 'Call',
          glyph: TaytayGlyph.phone,
          primary: true,
          onPressed: onCall,
        ),
        PillAction(
          buttonKey: const Key('tulong-directions'),
          label: 'Directions',
          glyph: TaytayGlyph.pin,
          onPressed: onDirections,
        ),
        PillAction(
          buttonKey: const Key('tulong-message'),
          label: 'Message',
          glyph: TaytayGlyph.chat,
          onPressed: onMessage,
        ),
      ],
    ),
    if (service.details.isNotEmpty) ...<Widget>[
      const SizedBox(height: Spacing.formGap),
      _BodyText(service.details),
    ],
    if (eligibility != null && eligibility.isNotEmpty) ...<Widget>[
      const SizedBox(height: Spacing.formGap),
      const _SectionTitle('Who can avail'),
      const SizedBox(height: Spacing.xs + Spacing.xxs),
      _BodyText(eligibility),
    ],
    if (service.requirements.isNotEmpty) ...<Widget>[
      const SizedBox(height: Spacing.formGap),
      Semantics(
        header: true,
        child: Text.rich(
          TextSpan(
            text: 'Requirements ',
            style: AppTypography.sectionTitle.copyWith(color: BrandColors.ink),
            children: <InlineSpan>[
              TextSpan(
                text: '(information only)',
                style: AppTypography.listDetail.copyWith(
                  fontWeight: AppTypography.medium,
                  color: BrandColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
      for (final ServiceRequirement item in service.requirements)
        _RequirementLine(requirement: item),
    ],
    if (facts.isNotEmpty) ...<Widget>[
      const SizedBox(height: Spacing.formGap),
      const Divider(height: 1, thickness: 1, color: BrandColors.divider),
      for (final _Fact fact in facts)
        DetailFactRow(
          icon: fact.icon,
          label: fact.label,
          value: fact.value,
          onTap: fact.office ? onOffice : null,
          tapKey: fact.office ? const Key('tulong-office') : null,
        ),
    ],
    if (source != null && source.isNotEmpty) ...<Widget>[
      const SizedBox(height: Spacing.section),
      Text(
        source,
        style: AppTypography.small.copyWith(color: BrandColors.muted),
      ),
    ],
  ];
}

/// The featured page: the headline, what it is, how to claim, when and
/// whom to ask, and Share.
List<Widget> _featured(SocialService service, VoidCallback? onShare) {
  final TulongPresentation? presentation = service.presentation;
  final String headline = service.featuredHeadline ?? service.name;
  final List<String> steps = service.claimSteps;
  final String? schedule = service.schedule;
  final String? questions = presentation?.questionsValue;
  return <Widget>[
    _SheetTitle(service: service, title: headline),
    if (service.details.isNotEmpty) ...<Widget>[
      const SizedBox(height: Spacing.formGap),
      _BodyText(service.details),
    ],
    if (steps.isNotEmpty) ...<Widget>[
      const SizedBox(height: Spacing.formGap),
      const _SectionTitle('How to claim'),
      for (var i = 0; i < steps.length; i++)
        _StepLine(number: i + 1, text: steps[i]),
    ],
    if (schedule != null || questions != null) ...<Widget>[
      const SizedBox(height: Spacing.formGap),
      const Divider(height: 1, thickness: 1, color: BrandColors.divider),
      if (schedule != null)
        DetailFactRow(
          icon: TaytayIcons.calendar,
          label: 'Schedule',
          value: schedule,
        ),
      if (questions != null)
        DetailFactRow(
          icon: TaytayIcons.phone,
          label: presentation?.questionsLabel ?? 'Questions',
          value: questions,
        ),
    ],
    const SizedBox(height: Spacing.formGap),
    FilledButton.icon(
      key: const Key('tulong-share'),
      style: TaytayButtonStyles.soft(),
      onPressed: onShare,
      icon: const TaytayIcon(
        icon: TaytayIcons.share,
        semanticLabel: '',
        excludeSemantics: true,
        size: IconSizes.sm,
      ),
      label: Text(presentation?.shareLabel ?? 'Share with a family member'),
    ),
  ];
}

/// The sheet's first row: the large tile beside the badge and the title.
class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.service, required this.title});

  final SocialService service;
  final String title;

  @override
  Widget build(BuildContext context) {
    final String? badge = service.heroBadge;
    final bool sample = service.presentation?.heroSample ?? false;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ServiceTile(service: service, tileSize: IconTileSize.large),
        const SizedBox(width: Spacing.section),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (badge != null || sample) ...<Widget>[
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Spacing.xs + Spacing.xxs,
                  runSpacing: Spacing.xs,
                  children: <Widget>[
                    if (badge != null) _Badge(badge),
                    if (sample) const SampleTag(),
                  ],
                ),
                const SizedBox(height: Spacing.xs + Spacing.xxs),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppTypography.pageTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The office or programme badge: a category label in a soft blue pill.
class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.blue50,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm + Spacing.xxs,
          vertical: Spacing.xxs + 1,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.category.copyWith(color: BrandColors.blue),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: AppTypography.sectionTitle.copyWith(color: BrandColors.ink),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyStyle.copyWith(
        color: BrandColors.text,
        height: 1.55,
      ),
    );
  }
}

/// One requirement: a dot, the text, and the sample tag on bundled lines.
class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.requirement});

  final ServiceRequirement requirement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: Spacing.sm, right: Spacing.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrandColors.blue,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: Spacing.xs + Spacing.xxs),
            ),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Spacing.xs + Spacing.xxs,
              runSpacing: Spacing.xs,
              children: <Widget>[
                _BodyText(requirement.text),
                if (requirement.sample) const SampleTag(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One claim step: the number in a blue disc, then the step.
class _StepLine extends StatelessWidget {
  const _StepLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(
              minWidth: ComponentSizes.stepDisc,
              minHeight: ComponentSizes.stepDisc,
            ),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: BrandColors.blue,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTypography.small.copyWith(
                fontWeight: AppTypography.black,
                color: BrandColors.white,
              ),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.xxs),
              child: _BodyText(text),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact {
  const _Fact({
    required this.label,
    required this.value,
    required this.icon,
    this.office = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool office;
}

List<_Fact> _factsOf(SocialService service) {
  final List<_Fact> rows = <_Fact>[];
  final String? office = service.officeName;
  if (office != null && office.isNotEmpty) {
    rows.add(
      _Fact(
        label: 'Office',
        value: office,
        icon: TaytayIcons.handHeart,
        office: service.officeSlug != null,
      ),
    );
  }
  for (final ServiceLocation location in service.locations) {
    rows.add(
      _Fact(
        label: location.name,
        value: location.address,
        icon: TaytayIcons.mapPin,
      ),
    );
  }
  final bool hoursContact = service.contacts.any(
    (ServiceContact contact) =>
        (contact.label?.toLowerCase() ?? '').contains('hour'),
  );
  final String? hours = service.officeHours;
  if (!hoursContact && hours != null && hours.isNotEmpty) {
    rows.add(_Fact(label: 'Hours', value: hours, icon: TaytayIcons.clock));
  }
  for (final ServiceContact contact in service.contacts) {
    rows.add(
      _Fact(
        label: contact.displayLabel,
        value: contact.value,
        icon: _contactIcon(contact),
      ),
    );
  }
  return rows;
}

/// The tile tone for the API's tile colour. An unknown colour is blue.
TileTone _toneOf(int? tile) {
  return switch (tile) {
    0xFF0F7A4D => TileTone.green,
    0xFF7A5E0C => TileTone.gold,
    0xFFB3261E => TileTone.red,
    _ => TileTone.blue,
  };
}

IconData _glyph(String name) {
  return switch (name) {
    'accessibility' => TaytayIcons.accessibility,
    'users' => TaytayIcons.users,
    'baby' => TaytayIcons.baby,
    'handCoins' => TaytayIcons.handCoins,
    'graduationCap' => TaytayIcons.graduationCap,
    'heart' => TaytayIcons.heart,
    'heartPulse' => TaytayIcons.heartPulse,
    'briefcase' => TaytayIcons.briefcase,
    'briefcaseBusiness' => TaytayIcons.briefcaseBusiness,
    // Font name `users-2`, codepoint 58478. The design calls it users-round.
    'usersRound' => TaytayIcons.usersRound,
    'wifiOff' => TaytayIcons.wifiOff,
    _ => TaytayIcons.handHeart,
  };
}

IconData _contactIcon(ServiceContact contact) {
  final String lower = contact.label?.toLowerCase() ?? '';
  if (lower.contains('hour')) return TaytayIcons.clock;
  if (lower.contains('traffick') || lower.contains('siren')) {
    return TaytayIcons.siren;
  }
  if (lower.contains('facebook') || lower.contains('message')) {
    return TaytayIcons.messageSquare;
  }
  if (lower.contains('schedule') || lower.contains('calendar')) {
    return TaytayIcons.calendar;
  }
  return switch (contact.type) {
    ServiceContactType.email => TaytayIcons.mail,
    ServiceContactType.facebook => TaytayIcons.messageSquare,
    ServiceContactType.landline ||
    ServiceContactType.hotline ||
    ServiceContactType.mobile => TaytayIcons.phone,
    ServiceContactType.unknown =>
      lower.contains('phone') ||
              lower.contains('contact') ||
              lower.contains('landline') ||
              lower.contains('question')
          ? TaytayIcons.phone
          : TaytayIcons.mapPin,
  };
}
