import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../domain/social_service.dart';

/// Which Tulong frame the canvas is painting.
enum TulongFrame { list, detail, offline, loading }

/// The Tulong list, a service page, the featured specimen, and offline.
///
/// The shell paints the tab bar. This canvas is the page above that bar.
/// One detail layout covers every service. Featured steps are fixture
/// presentation; a live service does not grow them.
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
    super.key,
  });

  final TulongFrame frame;
  final List<SocialService> services;
  final SocialService? service;
  final List<SocialService> saved;

  /// The offline header's second line. The specimen names MSWDO. A live
  /// failure passes the list subtitle instead of inventing an office.
  final String offlineSubtitle;

  /// Shown under the note when a search matches nothing.
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

  static const Color _pageTop = Color(0xFFEAF0FB);
  static const Color _searchBorder = Color(0xFFE1E6F0);
  static const Color _searchInk = Color(0xFF5F6880);
  static const Color _bodyInk = Color(0xFF33405C);
  static const Color _hairline = Color(0xFFEEF1F6);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: BrandColors.textPrimary,
        decoration: TextDecoration.none,
      ),
      textHeightBehavior: _cssHalfLeading,
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
    final SocialService? current = service;
    return switch (frame) {
      TulongFrame.detail when current != null => MunicipalHeader(
        title: current.headerTitle,
        subtitle: current.headerSubtitle,
        onBack: onBack,
        plainSeal: true,
      ),
      TulongFrame.offline => _ListHeader(
        subtitle: offlineSubtitle,
        onBell: onBell,
      ),
      _ => _ListHeader(onBell: onBell),
    };
  }

  Widget _body() {
    return switch (frame) {
      TulongFrame.offline => _OfflineBody(
        saved: saved,
        onRetry: onRetry,
        onOpen: onOpen,
      ),
      TulongFrame.detail when service != null && service!.showsFeaturedLayout =>
        _FeaturedBody(service: service!, onShare: onShare),
      TulongFrame.detail when service != null => _DetailBody(
        service: service!,
        onCall: onCall,
        onDirections: onDirections,
        onMessage: onMessage,
        onOffice: onOffice,
      ),
      _ => _ListBody(
        services: services,
        showNote: true,
        emptyMessage: frame == TulongFrame.loading ? null : emptyMessage,
        onOpen: onOpen,
        onSearch: onSearch,
        searchController: searchController,
      ),
    };
  }

  Widget _fade(Widget child) {
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

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    this.subtitle = 'Social services & programmes',
    this.onBell,
  });

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
            const _HeaderSeal(),
            const SizedBox(width: 11),
            Expanded(
              child: MunicipalHeaderTitles(title: 'Tulong', subtitle: subtitle),
            ),
            const SizedBox(width: 11),
            _Bell(onTap: onBell),
          ],
        ),
      ),
    );
  }
}

class _HeaderSeal extends StatelessWidget {
  const _HeaderSeal();

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
    // The circle stays 44 dp. The hit and its semantics are 48, centred on
    // that circle, so the header row does not grow.
    return SizedBox(
      width: 44,
      height: 44,
      child: OverflowBox(
        maxWidth: 48,
        maxHeight: 48,
        child: Semantics(
          button: onTap != null,
          label: 'Notifications',
          child: GestureDetector(
            key: const Key('tulong-bell'),
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Center(child: _BellFace()),
            ),
          ),
        ),
      ),
    );
  }
}

class _BellFace extends StatelessWidget {
  const _BellFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: const Stack(
        children: <Widget>[
          Center(
            child: TaytayIcon(
              icon: TaytayIcons.bell,
              size: 19,
              color: Colors.white,
              semanticLabel: '',
              excludeSemantics: true,
            ),
          ),
          Positioned(
            top: 6,
            right: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrandColors.sealGold,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: BrandColors.taytayBlue, width: 1.5),
                ),
              ),
              child: SizedBox(width: 8, height: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.services,
    required this.showNote,
    this.emptyMessage,
    this.onOpen,
    this.onSearch,
    this.searchController,
  });

  final List<SocialService> services;
  final bool showNote;
  final String? emptyMessage;
  final ValueChanged<SocialService>? onOpen;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        _SearchBox(controller: searchController, onChanged: onSearch),
        if (showNote) const _Note(),
        if (emptyMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
            child: Text(emptyMessage!, style: _noteStyle),
          ),
        if (services.isNotEmpty)
          _Card(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < services.length; i++)
                  _CompactRow(
                    service: services[i],
                    last: i == services.length - 1,
                    onTap: onOpen == null ? null : () => onOpen!(services[i]),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note();

  static const String copy =
      'Information on municipal programmes. These are information pages, not applications.';

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(2, 10, 2, 11),
      child: _CssLines(copy, style: _noteStyle),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({this.controller, this.onChanged});

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    const TextStyle ink = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 14,
      height: 1,
      fontWeight: FontWeight.w500,
      color: TulongCanvas._searchInk,
      decoration: TextDecoration.none,
    );
    // The field is 44 dp. The hit grows to 48 without moving the ink.
    return Semantics(
      textField: true,
      label: 'Search programmes',
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TulongCanvas._searchBorder),
            ),
            child: Row(
              children: <Widget>[
                const TaytayIcon(
                  icon: TaytayIcons.search,
                  size: 18,
                  color: TulongCanvas._searchInk,
                  semanticLabel: '',
                  excludeSemantics: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    type: MaterialType.transparency,
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      onSubmitted: onChanged,
                      maxLines: 1,
                      style: ink,
                      cursorColor: BrandColors.taytayBlue,
                      cursorWidth: 1.2,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Search programmes',
                        hintStyle: ink,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: -2,
            bottom: -2,
            child: IgnorePointer(child: SizedBox(key: Key('tulong-search'))),
          ),
        ],
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.service, required this.last, this.onTap});

  final SocialService service;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = _tileColors(
      service.presentation?.tile ?? 'blue',
    );
    return _Hit(
      hitKey: Key('tulong-open-${service.slug}'),
      label: service.listTitle,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: TulongCanvas._hairline)),
        ),
        child: Row(
          children: <Widget>[
            _Tile(
              size: 40,
              radius: 12,
              background: background,
              icon: _glyph(service.presentation?.glyph ?? 'handHeart'),
              color: foreground,
              iconSize: 20,
              lucideStroke:
                  service.presentation?.glyph == 'users' &&
                  service.presentation?.tile == 'gold',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    service.listTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _compactTitle,
                    strutStyle: _strutFor(_compactTitle),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _compactMeta,
                    strutStyle: _strutFor(_compactMeta),
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.service,
    this.onCall,
    this.onDirections,
    this.onMessage,
    this.onOffice,
  });

  final SocialService service;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;
  final VoidCallback? onOffice;

  @override
  Widget build(BuildContext context) {
    final String? source = service.presentation?.source;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        _Hero(service: service),
        const SizedBox(height: 12),
        _Actions(
          onCall: onCall,
          onDirections: onDirections,
          onMessage: onMessage,
        ),
        const SizedBox(height: 12),
        _AboutCard(service: service),
        const SizedBox(height: 12),
        _FactsCard(service: service, onOffice: onOffice),
        if (source != null) ...<Widget>[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _CssLines(source, style: _sourceStyle),
          ),
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.service});

  final SocialService service;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = _tileColors(
      service.presentation?.tile ?? 'blue',
    );
    final String? badge = service.heroBadge;
    final bool sample = service.presentation?.heroSample ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _Tile(
                        size: 52,
                        radius: 16,
                        background: background,
                        icon: _glyph(
                          service.presentation?.glyph ?? 'handHeart',
                        ),
                        color: foreground,
                        iconSize: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (badge != null)
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: <Widget>[
                                  _GoldTag(badge),
                                  if (sample)
                                    const SampleTag(lineHeight: _cssNormal),
                                ],
                              ),
                            const SizedBox(height: 6),
                            Text(
                              service.name,
                              style: _heroTitle,
                              strutStyle: _strutFor(_heroTitle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _CssLines(service.details, style: _heroBlurb),
                ],
              ),
            ),
            Positioned(
              right: -14,
              bottom: -18,
              child: Opacity(
                opacity: 0.12,
                child: TaytayIcon(
                  icon: _glyph(service.presentation?.glyph ?? 'handHeart'),
                  size: 110,
                  color: BrandColors.sealGold,
                  semanticLabel: '',
                  excludeSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldTag extends StatelessWidget {
  const _GoldTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: BrandColors.chipGoldBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: _tag, strutStyle: _strutFor(_tag)),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({this.onCall, this.onDirections, this.onMessage});

  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _PrimaryButton(
            hitKey: const Key('tulong-call'),
            label: 'Call',
            icon: TaytayIcons.phone,
            onTap: onCall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SecondaryButton(
            hitKey: const Key('tulong-directions'),
            label: 'Directions',
            icon: TaytayIcons.send,
            onTap: onDirections,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SecondaryButton(
            hitKey: const Key('tulong-message'),
            label: 'Message',
            icon: TaytayIcons.messageSquare,
            onTap: onMessage,
          ),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.service});

  final SocialService service;

  @override
  Widget build(BuildContext context) {
    final String? eligibility = service.eligibility;
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 16 / 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (eligibility != null && eligibility.isNotEmpty) ...<Widget>[
            Text(
              'Who can avail',
              style: _cardTitle,
              strutStyle: _strutFor(_cardTitle),
            ),
            // .bl margin-top is 6. One image px of the browser line box
            // sits below that, which is what keeps the body run on the
            // specimen's start row.
            const SizedBox(height: 6 + 1 / 3),
            _CssLines(eligibility, style: _body),
          ],
          if (service.requirements.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            const _RequirementsHeading(),
            // ul.bl margin-top 6 collapses with the first li margin-top 3.
            // Adjacent li margins then collapse to 3, not 6.
            const SizedBox(height: 6),
            for (var i = 0; i < service.requirements.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 3),
                child: _RequirementLine(requirement: service.requirements[i]),
              ),
            if (service.requirements.any(
              (ServiceRequirement item) => item.sample,
            ))
              // One image px of the chip line box is left after the
              // per-line overflow, and it shows up on the fact rows.
              const SizedBox(height: 1 / 3),
          ],
        ],
      ),
    );
  }
}

class _RequirementsHeading extends StatelessWidget {
  const _RequirementsHeading();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'Requirements ',
        style: _cardTitle,
        children: <InlineSpan>[
          TextSpan(text: '(information only)', style: _requirementAside),
        ],
      ),
      strutStyle: _cardTitleStrut,
    );
  }
}

class _RequirementLine extends StatelessWidget {
  const _RequirementLine({required this.requirement});

  final ServiceRequirement requirement;

  @override
  Widget build(BuildContext context) {
    // Chrome's default ul padding-inline-start is 40. The li margin-left is
    // 18, and the disc sits in that margin (list-style-position: outside).
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(
            width: 18,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TulongCanvas._bodyInk,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 4, height: 4),
                ),
              ),
            ),
          ),
          Expanded(
            child: requirement.sample
                ? _SampleLines(requirement.text)
                : _CssLines(requirement.text, style: _body),
          ),
        ],
      ),
    );
  }
}

/// Requirement copy with the SAMPLE chip in the inline position the
/// specimen uses: after the last word when the line has room, otherwise
/// on the following line. A full-width text block would always drop it.
class _SampleLines extends StatelessWidget {
  const _SampleLines(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final TextDirection direction = Directionality.of(context);
        final StrutStyle strut = _strutFor(_body);
        final List<String> lines = _cssLineBreaks(
          text,
          style: _body,
          strut: strut,
          maxWidth: maxWidth,
          textScaler: scaler,
          direction: direction,
        );
        final double step = (_body.fontSize ?? 13) * (_body.height ?? 1);
        final String lastLine = lines.isEmpty ? '' : lines.last;
        final TextPainter lastPainter = TextPainter(
          text: TextSpan(text: lastLine, style: _body),
          textDirection: direction,
          textScaler: scaler,
          strutStyle: strut,
          textHeightBehavior: _cssHalfLeading,
        )..layout();
        final double lastWidth = lastPainter.width;
        lastPainter.dispose();
        final TextPainter spacePainter = TextPainter(
          text: const TextSpan(text: ' ', style: _body),
          textDirection: direction,
          textScaler: scaler,
        )..layout();
        final double gap = spacePainter.width;
        spacePainter.dispose();
        final TextPainter chipPainter = TextPainter(
          text: TextSpan(
            text: 'SAMPLE',
            style: AppTypography.labelStrong.copyWith(
              letterSpacing: 0.6,
              height: _cssNormal,
            ),
          ),
          textDirection: direction,
          textScaler: scaler,
        )..layout();
        // Border 1 + padding 7 on each side, matching `.sample`.
        final double chipWidth = chipPainter.width + 16;
        chipPainter.dispose();
        final bool fits =
            lines.isNotEmpty && lastWidth + gap + chipWidth <= maxWidth;
        final int chipLine = fits ? lines.length - 1 : lines.length;
        final int slots = lines.length + (fits ? 0 : 1);
        // `.sample` is an inline-block taller than the 13/1.55 line, so
        // the line box grows by the overflow. 8 image px on the specimen.
        const double chipOverflow = 8 / 3;
        final double height = step * slots + chipOverflow;
        return SizedBox(
          width: maxWidth,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (var i = 0; i < lines.length; i++)
                Positioned(
                  top: step * i + (i > chipLine ? chipOverflow : 0),
                  left: 0,
                  right: 0,
                  height: step,
                  child: Text(
                    lines[i],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: _body,
                    strutStyle: strut,
                    textHeightBehavior: _cssHalfLeading,
                  ),
                ),
              Positioned(
                top: step * chipLine,
                left: fits ? lastWidth + gap : 0,
                height: step,
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: SampleTag(lineHeight: _cssNormal),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FactsCard extends StatelessWidget {
  const _FactsCard({required this.service, this.onOffice});

  final SocialService service;
  final VoidCallback? onOffice;

  @override
  Widget build(BuildContext context) {
    final List<_Fact> facts = _factsOf(service);
    return _Card(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < facts.length; i++)
            _FactRow(
              fact: facts[i],
              last: i == facts.length - 1,
              onTap: facts[i].office ? onOffice : null,
              hitKey: facts[i].office ? const Key('tulong-office') : null,
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
    (ServiceContact contact) => contact.label.toLowerCase().contains('hour'),
  );
  final String? hours = service.officeHours;
  if (!hoursContact && hours != null && hours.isNotEmpty) {
    rows.add(_Fact(label: 'Hours', value: hours, icon: TaytayIcons.clock));
  }
  for (final ServiceContact contact in service.contacts) {
    rows.add(
      _Fact(
        label: contact.label,
        value: contact.value,
        icon: _contactIcon(contact.label),
      ),
    );
  }
  return rows;
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.fact,
    required this.last,
    this.onTap,
    this.hitKey,
  });

  final _Fact fact;
  final bool last;
  final VoidCallback? onTap;
  final Key? hitKey;

  @override
  Widget build(BuildContext context) {
    final Widget row = Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: TulongCanvas._hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Tile(
            size: 44,
            radius: 12,
            background: BrandColors.chipBlueBg,
            icon: fact.icon,
            color: BrandColors.taytayBlue,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fact.label,
                  style: _factLabel,
                  strutStyle: _strutFor(_factLabel),
                ),
                const SizedBox(height: 2),
                _CssLines(fact.value, style: _factValue),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return _Hit(hitKey: hitKey, label: fact.label, onTap: onTap, child: row);
  }
}

class _FeaturedBody extends StatelessWidget {
  const _FeaturedBody({required this.service, this.onShare});

  final SocialService service;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final TulongPresentation? presentation = service.presentation;
    final String headline = presentation?.headline ?? service.name;
    final List<String> steps = presentation?.steps ?? const <String>[];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        _FeaturedHero(service: service, headline: headline),
        if (steps.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _Card(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16 + 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'How to claim',
                  style: _cardTitle,
                  strutStyle: _strutFor(_cardTitle),
                ),
                for (var i = 0; i < steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: BrandColors.taytayBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}', style: _stepNumber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: _CssLines(steps[i], style: _noteStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (presentation?.scheduleValue != null) ...<Widget>[
          const SizedBox(height: 12),
          _Card(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
            child: Column(
              children: <Widget>[
                _FactRow(
                  fact: _Fact(
                    label: presentation?.scheduleLabel ?? 'Schedule',
                    value: presentation!.scheduleValue!,
                    icon: TaytayIcons.calendar,
                  ),
                  last: presentation.questionsValue == null,
                ),
                if (presentation.questionsValue != null)
                  _FactRow(
                    fact: _Fact(
                      label: presentation.questionsLabel ?? 'Questions',
                      value: presentation.questionsValue!,
                      icon: TaytayIcons.phone,
                    ),
                    last: true,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _SecondaryButton(
          hitKey: const Key('tulong-share'),
          label: presentation?.shareLabel ?? 'Share with a family member',
          icon: TaytayIcons.share,
          onTap: onShare,
        ),
      ],
    );
  }
}

class _FeaturedHero extends StatelessWidget {
  const _FeaturedHero({required this.service, required this.headline});

  final SocialService service;
  final String headline;

  @override
  Widget build(BuildContext context) {
    final String? badge = service.heroBadge;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              // The painted hero is 7 image px short of the specimen at
              // line-height 1.2. The extra bottom padding is that remainder.
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18 + 7 / 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (badge != null) _GoldTag(badge),
                  const SizedBox(height: 10),
                  _CssLines(headline, style: _featuredTitle),
                  const SizedBox(height: 6),
                  _CssLines(service.details, style: _featuredBlurb),
                ],
              ),
            ),
            Positioned(
              right: -10,
              bottom: -14,
              child: Opacity(
                opacity: 0.18,
                child: TaytayIcon(
                  icon: _glyph(service.presentation?.glyph ?? 'accessibility'),
                  size: 120,
                  color: BrandColors.sealGold,
                  semanticLabel: '',
                  excludeSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBody extends StatelessWidget {
  const _OfflineBody({required this.saved, this.onRetry, this.onOpen});

  final List<SocialService> saved;
  final VoidCallback? onRetry;
  final ValueChanged<SocialService>? onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: BrandColors.textPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: <Widget>[
              TaytayIcon(
                icon: TaytayIcons.wifiOff,
                size: 18,
                color: Colors.white,
                semanticLabel: '',
                excludeSemantics: true,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text("You're offline", style: _offlineTitle),
                    Text(
                      'Showing what was saved on this phone',
                      style: _offlineMeta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
          child: Column(
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: BrandColors.chipGreyBg,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: TaytayIcon(
                      icon: TaytayIcons.wifiOff,
                      size: 32,
                      color: BrandColors.listMeta,
                      semanticLabel: '',
                      excludeSemantics: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Programme pages need a connection',
                textAlign: TextAlign.center,
                style: _offlineHeading,
              ),
              const SizedBox(height: 4),
              const _CssLines(
                "We couldn't load the latest programme information. Pages you opened before are saved below.",
                style: _noteStyle,
                align: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _PrimaryButton(
                hitKey: const Key('tulong-retry'),
                label: 'Try again',
                icon: TaytayIcons.refreshCw,
                onTap: onRetry,
              ),
            ],
          ),
        ),
        if (saved.isNotEmpty) ...<Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 4, 0, 8),
            child: Text('Saved pages', style: _sectionTitle),
          ),
          _Card(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < saved.length; i++)
                  _SavedRow(
                    service: saved[i],
                    last: i == saved.length - 1,
                    onTap: onOpen == null ? null : () => onOpen!(saved[i]),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.service, required this.last, this.onTap});

  final SocialService service;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = _tileColors(
      service.presentation?.tile ?? 'blue',
    );
    final bool sample = service.presentation?.heroSample ?? false;
    return _Hit(
      hitKey: Key('tulong-open-${service.slug}'),
      label: service.listTitle,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: TulongCanvas._hairline)),
        ),
        child: Row(
          children: <Widget>[
            _Tile(
              size: 44,
              radius: 12,
              background: background,
              icon: _glyph(service.presentation?.glyph ?? 'handHeart'),
              color: foreground,
              iconSize: 20,
              dropIcon: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: <Widget>[
                      Text(service.name, style: _savedTitle),
                      if (sample) const SampleTag(lineHeight: _cssNormal),
                    ],
                  ),
                  // The chip is taller than `.lt` and the row is centred on
                  // the icon, so the line box has to carry the overflow or
                  // the subtitle rides up into the title.
                  if (sample) const SizedBox(height: 2),
                  const SizedBox(height: 2),
                  Text(service.savedLine, style: _compactMeta),
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
      // CSS `border-box` takes the 1 px stroke out of the content width.
      // A vertical inset would move every line by 3 image px.
      child: Padding(
        padding: padding + const EdgeInsets.symmetric(horizontal: 1),
        child: child,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.size,
    required this.radius,
    required this.background,
    required this.icon,
    required this.color,
    required this.iconSize,
    this.lucideStroke = false,
    this.dropIcon = false,
  });

  final double size;
  final double radius;
  final Color background;
  final IconData icon;
  final Color color;
  final double iconSize;
  final bool lucideStroke;

  /// The Lucide users glyph has a neck the SVG stroke does not. One pixel
  /// down puts that gap on the specimen's subtitle row.
  final bool dropIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        // Centering a child that is 2 px taller on top drops the glyph 1 px.
        padding: dropIcon ? const EdgeInsets.only(top: 2) : EdgeInsets.zero,
        child: lucideStroke
            ? _UsersMark(size: iconSize, color: color)
            : TaytayIcon(
                icon: icon,
                size: iconSize,
                color: color,
                semanticLabel: '',
                excludeSemantics: true,
              ),
      ),
    );
  }
}

/// The list specimen's users glyph is the Lucide stroke, whose head and
/// shoulders meet. The icon font leaves a light gap there on every row.
class _UsersMark extends StatelessWidget {
  const _UsersMark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _UsersPainter(color));
  }
}

class _UsersPainter extends CustomPainter {
  const _UsersPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path shoulders = Path()
      ..moveTo(18 * s, 21 * s)
      ..arcToPoint(
        Offset(2 * s, 21 * s),
        radius: Radius.circular(8 * s),
        clockwise: false,
      );
    canvas.drawPath(shoulders, paint);
    canvas.drawCircle(Offset(10 * s, 8 * s), 5 * s, paint);
    final Path second = Path()
      ..moveTo(22 * s, 20 * s)
      ..cubicTo(22 * s, 16.63 * s, 20 * s, 13.5 * s, 18 * s, 12 * s)
      ..arcToPoint(
        Offset(17.55 * s, 3.7 * s),
        radius: Radius.circular(5 * s),
        clockwise: false,
      );
    canvas.drawPath(second, paint);
  }

  @override
  bool shouldRepaint(covariant _UsersPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.hitKey,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final Key hitKey;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      hitKey: hitKey,
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
                style: _primaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.hitKey,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final Key hitKey;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      hitKey: hitKey,
      label: label,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.taytayBlue, width: 1.5),
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
                style: _secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({
    required this.child,
    required this.label,
    this.hitKey,
    this.onTap,
  });

  final Widget child;
  final String label;
  final Key? hitKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: GestureDetector(
        key: hitKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _CssLines extends StatelessWidget {
  const _CssLines(
    this.text, {
    required this.style,
    this.align = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final double? fontSize = style.fontSize;
    final double? height = style.height;
    final StrutStyle strut = _strutFor(style);
    if (fontSize == null || height == null) {
      return Text(text, style: style, strutStyle: strut, textAlign: align);
    }
    final double step = fontSize * height;
    if ((step - step.roundToDouble()).abs() < 0.001) {
      return Text(
        text,
        style: style,
        strutStyle: strut,
        textAlign: align,
        textHeightBehavior: _cssHalfLeading,
      );
    }
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final List<String> lines = _cssLineBreaks(
              text,
              style: style,
              strut: strut,
              maxWidth: constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
              direction: Directionality.of(context),
            );
            if (lines.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              width: constraints.maxWidth,
              height: step * lines.length,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var i = 0; i < lines.length; i++)
                    Positioned(
                      top: step * i,
                      left: 0,
                      right: 0,
                      child: Text(
                        lines[i],
                        maxLines: 1,
                        softWrap: false,
                        textAlign: align,
                        textHeightBehavior: _cssHalfLeading,
                        strutStyle: strut,
                        style: style,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Hard breaks are their own lines. A painter given the whole string keeps
/// the characters after a newline on the first line's boundary.
List<String> _cssLineBreaks(
  String text, {
  required TextStyle style,
  required StrutStyle strut,
  required double maxWidth,
  required TextScaler textScaler,
  required TextDirection direction,
}) {
  final List<String> lines = <String>[];
  for (final String paragraph in text.split('\n')) {
    if (paragraph.isEmpty) {
      lines.add('');
      continue;
    }
    final TextPainter painter = TextPainter(
      text: TextSpan(text: paragraph, style: style),
      textDirection: direction,
      textScaler: textScaler,
      textHeightBehavior: _cssHalfLeading,
      strutStyle: strut,
    )..layout(maxWidth: maxWidth);
    var start = 0;
    while (start < paragraph.length) {
      final TextRange range = painter.getLineBoundary(
        TextPosition(offset: start),
      );
      if (range.end <= start) break;
      lines.add(paragraph.substring(range.start, range.end).trimRight());
      start = range.end;
    }
    painter.dispose();
  }
  return lines;
}

StrutStyle _strutFor(TextStyle style) {
  return StrutStyle(
    fontFamily: style.fontFamily,
    fontSize: style.fontSize,
    fontWeight: style.fontWeight,
    height: style.height,
    leadingDistribution: TextLeadingDistribution.even,
    forceStrutHeight: true,
  );
}

const double _cssNormal = 1.26;

const TextHeightBehavior _cssHalfLeading = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

const StrutStyle _cardTitleStrut = StrutStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  height: _cssNormal,
  leadingDistribution: TextLeadingDistribution.even,
  forceStrutHeight: true,
);

const TextStyle _noteStyle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.5,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _compactTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: _cssNormal,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _compactMeta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: _cssNormal,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _heroTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 18,
  fontWeight: FontWeight.w800,
  height: 1.2,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _heroBlurb = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.5,
  color: Color(0xF2FFFFFF),
  decoration: TextDecoration.none,
);

const TextStyle _featuredTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 22,
  fontWeight: FontWeight.w800,
  height: 1.2,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _featuredBlurb = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.5,
  color: Color(0xE6FFFFFF),
  decoration: TextDecoration.none,
);

const TextStyle _tag = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w800,
  height: _cssNormal,
  color: BrandColors.inkGold,
  decoration: TextDecoration.none,
);

const TextStyle _cardTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: _cssNormal,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _requirementAside = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: _cssNormal,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _body = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w500,
  height: 1.55,
  color: TulongCanvas._bodyInk,
  decoration: TextDecoration.none,
);

const TextStyle _factLabel = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: _cssNormal,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _factValue = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: _cssNormal,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _sourceStyle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.5,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _primaryLabel = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 1,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _secondaryLabel = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 1,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

const TextStyle _offlineTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.26,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const TextStyle _offlineMeta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w500,
  height: 1.26,
  color: Color(0xD9FFFFFF),
  decoration: TextDecoration.none,
);

const TextStyle _offlineHeading = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w800,
  height: _cssNormal,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _sectionTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w800,
  height: _cssNormal,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _savedTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: _cssNormal,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _stepNumber = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w800,
  height: 1,
  color: Colors.white,
  decoration: TextDecoration.none,
);

(Color, Color) _tileColors(String tile) {
  return switch (tile) {
    'green' => (BrandColors.chipGreenBg, BrandColors.success),
    'gold' => (BrandColors.chipGoldBg, BrandColors.inkGold),
    'red' => (BrandColors.chipRedBg, BrandColors.danger),
    _ => (BrandColors.chipBlueBg, BrandColors.taytayBlue),
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
    'briefcase' => TaytayIcons.briefcase,
    'wifiOff' => TaytayIcons.wifiOff,
    _ => TaytayIcons.handHeart,
  };
}

IconData _contactIcon(String label) {
  final String lower = label.toLowerCase();
  if (lower.contains('hour')) return TaytayIcons.clock;
  if (lower.contains('schedule') || lower.contains('calendar')) {
    return TaytayIcons.calendar;
  }
  if (lower.contains('facebook') || lower.contains('message')) {
    return TaytayIcons.messageSquare;
  }
  if (lower.contains('traffick') || lower.contains('siren')) {
    return TaytayIcons.siren;
  }
  if (lower.contains('phone') ||
      lower.contains('contact') ||
      lower.contains('landline') ||
      lower.contains('question')) {
    return TaytayIcons.phone;
  }
  return TaytayIcons.mapPin;
}
