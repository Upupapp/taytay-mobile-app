import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/design/brand_assets.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../domain/office.dart';

/// Which 05 frame the canvas is painting.
enum DirectoryFrame {
  list,
  searchSpecimen,
  loading,
  offline,
  detail,
  compose,
  sent,
  thread,
}

/// The Directory pages, painted from the office catalogue.
///
/// One widget covers the list, the nine office pages, compose, the sent
/// confirmation and the thread. Office pages are public information (D11).
class DirectoryCanvas extends StatelessWidget {
  const DirectoryCanvas({
    required this.frame,
    required this.offices,
    this.office,
    this.bubbles = const <DirectoryThreadBubble>[],
    this.onOffice,
    this.onBack,
    this.onCall,
    this.onDirections,
    this.onMessage,
    this.onApp,
    this.onSend,
    this.onMessages,
    this.onRetry,
    this.onBrowseAll,
    this.chips = const <String>[],
    this.emergencyPhone = '',
    this.dayLabel = '',
    this.query = '',
    this.searchController,
    this.onSearch,
    this.messageController,
    this.selectedTopic,
    this.onTopic,
    this.heroBytes,
    this.onServiceLine,
    super.key,
  });

  final DirectoryFrame frame;
  final List<Office> offices;
  final List<String> chips;
  final String emergencyPhone;

  /// The day chip on the thread. The fixture supplies it.
  final String dayLabel;
  final Office? office;
  final List<DirectoryThreadBubble> bubbles;
  final ValueChanged<Office>? onOffice;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;
  final VoidCallback? onApp;
  final VoidCallback? onSend;
  final VoidCallback? onMessages;
  final VoidCallback? onRetry;
  final VoidCallback? onBrowseAll;

  /// The list filter. Empty shows every office.
  final String query;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearch;
  final TextEditingController? messageController;
  final String? selectedTopic;
  final VoidCallback? onTopic;

  /// Banner bytes from `GET /offices/{slug}/hero`. Null paints [Office.heroAsset].
  final Uint8List? heroBytes;

  /// Opens a Tulong page for a catalogue line. Directory lines have no slug.
  final ValueChanged<String>? onServiceLine;

  static const Color _pageTop = Color(0xFFEAF0FB);
  static const Color _searchBorder = Color(0xFFE1E6F0);
  static const Color _searchInk = Color(0xFF5F6880);
  static const Color _chipBorder = Color(0xFFE1E6F0);
  static const Color _chipInk = Color(0xFF33405C);
  static const Color _bodyInk = Color(0xFF33405C);
  static const Color _rowLine = Color(0xFFEEF1F6);
  static const Color _fieldBorder = Color(0xFFD6DCE8);

  @override
  Widget build(BuildContext context) {
    final Office? current = office;
    return ColoredBox(
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
            _header(current),
            Expanded(child: _body(current)),
          ],
        ),
      ),
    );
  }

  Widget _header(Office? current) {
    return switch (frame) {
      DirectoryFrame.list ||
      DirectoryFrame.loading ||
      DirectoryFrame.offline => const _ListHeader(),
      DirectoryFrame.searchSpecimen => MunicipalHeader(
        title: 'Search',
        subtitle: 'Directory',
        onBack: onBack,
        plainSeal: true,
      ),
      DirectoryFrame.detail => MunicipalHeader(
        title: current?.shortName ?? 'Office',
        subtitle: 'Office details',
        onBack: onBack,
        plainSeal: true,
      ),
      DirectoryFrame.compose => MunicipalHeader(
        title: 'New message',
        subtitle: 'Bayan ng Taytay · Rizal',
        onBack: onBack,
        plainSeal: true,
      ),
      DirectoryFrame.sent => MunicipalHeader(
        title: 'Message sent',
        subtitle: 'Bayan ng Taytay · Rizal',
        onBack: onBack,
        plainSeal: true,
      ),
      DirectoryFrame.thread => MunicipalHeader(
        title: current?.shortName ?? 'BPLO',
        subtitle: current?.name ?? 'Business Permits and Licensing Office',
        onBack: onBack,
        plainSeal: true,
      ),
    };
  }

  Widget _body(Office? current) {
    final Widget child = switch (frame) {
      DirectoryFrame.list => _ListBody(
        offices: offices,
        chips: chips,
        query: query,
        searchController: searchController,
        onSearch: onSearch,
        onOffice: onOffice,
      ),
      DirectoryFrame.searchSpecimen => _SearchSpecimen(
        offices: offices,
        onOffice: onOffice,
        onBrowseAll: onBrowseAll,
      ),
      DirectoryFrame.loading => _LoadingBody(chips: chips),
      DirectoryFrame.offline => _OfflineBody(
        offices: offices,
        onRetry: onRetry,
        onCall: onCall,
      ),
      DirectoryFrame.detail when current != null => _DetailBody(
        office: current,
        heroBytes: heroBytes,
        onCall: onCall,
        onDirections: onDirections,
        onMessage: onMessage,
        onApp: onApp,
        onServiceLine: onServiceLine,
      ),
      DirectoryFrame.compose when current != null => _ComposeBody(
        office: current,
        onSend: onSend,
        messageController: messageController,
        selectedTopic: selectedTopic,
        onTopic: onTopic,
      ),
      DirectoryFrame.sent => _SentBody(
        emergencyPhone: emergencyPhone,
        onMessages: onMessages,
        onBack: onBack,
      ),
      DirectoryFrame.thread => _ThreadBody(
        bubbles: bubbles,
        dayLabel: dayLabel,
      ),
      _ => const SizedBox.shrink(),
    };
    if (frame == DirectoryFrame.thread) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect rect) {
        // CSS `.bd.fade` stays opaque until 28px from the bottom.
        final double start = rect.height <= 28 ? 0 : 1 - (28 / rect.height);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const <Color>[Colors.white, Colors.white, Colors.transparent],
          stops: <double>[0, start, 1],
        ).createShader(rect);
      },
      child: child,
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BrandColors.taytayBlueDark, BrandColors.taytayBlue],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 46, 16, 14),
        child: Row(
          children: <Widget>[
            _HeaderSeal(),
            SizedBox(width: 11),
            Expanded(
              child: MunicipalHeaderTitles(
                title: 'Directory',
                subtitle: 'Municipal offices',
              ),
            ),
            SizedBox(width: 11),
            _Bell(),
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
          BrandAssets.municipalSeal.assetPath,
          fit: BoxFit.contain,
          semanticLabel: BrandAssets.municipalSeal.semanticLabel,
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell();

  @override
  Widget build(BuildContext context) {
    return _Hit(
      hitKey: const Key('directory-bell'),
      label: 'Notifications',
      width: 44,
      height: 44,
      child: Container(
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
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody({
    required this.offices,
    required this.chips,
    required this.query,
    this.searchController,
    this.onSearch,
    this.onOffice,
  });

  final List<Office> offices;
  final List<String> chips;
  final String query;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearch;
  final ValueChanged<Office>? onOffice;

  @override
  Widget build(BuildContext context) {
    final List<Office> visible = offices
        .where((Office office) => office.matches(query, 'All'))
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        _SearchBox(
          hint: 'Search offices or services',
          controller: searchController,
          onChanged: onSearch,
        ),
        const SizedBox(height: 12),
        _Chips(labels: chips, selected: 'All'),
        const SizedBox(height: 12),
        _OfficeCard(offices: visible, compact: true, onOffice: onOffice),
      ],
    );
  }
}

class _SearchSpecimen extends StatefulWidget {
  const _SearchSpecimen({
    required this.offices,
    this.onOffice,
    this.onBrowseAll,
  });

  final List<Office> offices;
  final ValueChanged<Office>? onOffice;
  final VoidCallback? onBrowseAll;

  @override
  State<_SearchSpecimen> createState() => _SearchSpecimenState();
}

class _SearchSpecimenState extends State<_SearchSpecimen> {
  late final TextEditingController _cedula = TextEditingController(
    text: 'cedula',
  );
  late final TextEditingController _passport = TextEditingController(
    text: 'passport',
  );

  @override
  void initState() {
    super.initState();
    _cedula.addListener(_changed);
    _passport.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cedula.dispose();
    _passport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Office> found = widget.offices
        .where((Office office) => office.matches(_cedula.text, 'All'))
        .toList(growable: false);
    final List<Office> missed = widget.offices
        .where((Office office) => office.matches(_passport.text, 'All'))
        .toList(growable: false);
    final String countWord = found.length == 1 ? 'result' : 'results';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        _SearchBox(
          key: const Key('directory-search-cedula'),
          controller: _cedula,
          active: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 12),
          child: Text(
            '${found.length} $countWord for “${_cedula.text}”',
            style: _meta,
          ),
        ),
        if (found.isNotEmpty)
          _OfficeCard(
            offices: found,
            compact: false,
            looseSubtitle: true,
            lineFor: (Office office) => office.searchLine ?? office.listLine,
            onOffice: widget.onOffice,
          ),
        const SizedBox(height: 19.5),
        _SearchBox(
          key: const Key('directory-search-passport'),
          controller: _passport,
          active: true,
          showClear: false,
        ),
        if (missed.isEmpty)
          _EmptySearch(query: _passport.text, onBrowseAll: widget.onBrowseAll)
        else
          _OfficeCard(
            offices: missed,
            compact: false,
            onOffice: widget.onOffice,
          ),
      ],
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({this.query = 'passport', this.onBrowseAll});

  final String query;
  final VoidCallback? onBrowseAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 27, 20, 28),
      child: Column(
        children: <Widget>[
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF1F6),
              shape: BoxShape.circle,
            ),
            child: const TaytayIcon(
              icon: TaytayIcons.search,
              size: 24,
              color: BrandColors.listMeta,
              semanticLabel: '',
              excludeSemantics: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No offices found for “$query”',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: BrandColors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Passports are handled by the DFA, not the municipality. '
            'Try another word, or browse by category.',
            textAlign: TextAlign.center,
            style: _summary,
          ),
          const SizedBox(height: 14),
          _StrokeButton(
            hitKey: const Key('directory-browse'),
            label: 'Browse all offices',
            onTap: onBrowseAll,
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        const _SearchBox(hint: 'Search offices or services'),
        const SizedBox(height: 12),
        _Chips(labels: chips, selected: 'All', wrap: true),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: _cardDecoration,
          child: const Column(
            children: <Widget>[
              _SkeletonRow(),
              _SkeletonRow(),
              _SkeletonRow(),
              _SkeletonRow(),
              _SkeletonRow(),
              _SkeletonRow(),
              _SkeletonRow(last: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({this.last = false});

  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: DirectoryCanvas._rowLine)),
      ),
      child: const Row(
        children: <Widget>[
          _Bone(width: 44, height: 44, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Bone(widthFactor: 0.7, height: 13),
                SizedBox(height: 8),
                _Bone(widthFactor: 0.45, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    this.width,
    this.widthFactor,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double? widthFactor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE6EAF2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (widthFactor == null) return box;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: box,
    );
  }
}

class _OfflineBody extends StatelessWidget {
  const _OfflineBody({required this.offices, this.onRetry, this.onCall});

  final List<Office> offices;
  final VoidCallback? onRetry;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    // Fixed emergency default. MDRRMO and MSWDO are the numbers that
    // stay on this screen when the directory cannot load. They are not
    // read from storage and they are not the last list the phone fetched.
    final List<Office> saved =
        offices
            .where(
              (Office office) => office.id == 'mdrrmo' || office.id == 'mswdo',
            )
            .toList()
          ..sort((Office a, Office b) {
            if (a.id == 'mdrrmo') return -1;
            if (b.id == 'mdrrmo') return 1;
            return 0;
          });
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A33),
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
                    Text(
                      "You're offline",
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      'Showing what was saved on this phone',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xD9FFFFFF),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 26, 18, 0),
          child: Column(
            children: <Widget>[
              _EmptyMark(icon: TaytayIcons.wifiOff),
              SizedBox(height: 15.7),
              Text(
                "Can't load the directory",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Check your mobile data or Wi-Fi, then try again. '
                'Saved office numbers are listed below.',
                textAlign: TextAlign.center,
                style: _summary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FilledButton(
          hitKey: const Key('directory-retry'),
          label: 'Try again',
          icon: TaytayIcons.refreshCw,
          onTap: onRetry,
        ),
        const SizedBox(height: 26.3),
        const Padding(
          padding: EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            'Saved on this phone',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BrandColors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        _OfficeCard(
          offices: saved,
          compact: false,
          lineFor: (Office office) => office.phone,
          trailingCall: true,
          onOffice: (_) => onCall?.call(),
        ),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.office,
    this.heroBytes,
    this.onCall,
    this.onDirections,
    this.onMessage,
    this.onApp,
    this.onServiceLine,
  });

  final Office office;
  final Uint8List? heroBytes;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;
  final VoidCallback? onApp;
  final ValueChanged<String>? onServiceLine;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        _Hero(office: office, heroBytes: heroBytes),
        const SizedBox(height: 4.33),
        Text(office.credit, style: _credit),
        const SizedBox(height: 12.67),
        Row(
          children: <Widget>[
            Expanded(
              child: _FilledButton(
                hitKey: const Key('directory-call'),
                label: office.callLabel,
                icon: TaytayIcons.phone,
                danger: office.callIsEmergency,
                onTap: onCall,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StrokeButton(
                hitKey: const Key('directory-directions'),
                label: 'Directions',
                icon: TaytayIcons.send,
                onTap: onDirections,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StrokeButton(
                hitKey: const Key('directory-message'),
                label: office.messageable ? 'Message' : 'App',
                icon: office.messageable
                    ? TaytayIcons.messageSquare
                    : TaytayIcons.smartphone,
                onTap: office.messageable ? onMessage : onApp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11.33),
        Text(
          office.summary,
          textHeightBehavior: _cssHalfLeading,
          style: _summary.copyWith(color: DirectoryCanvas._bodyInk),
        ),
        const SizedBox(height: 10),
        _FactCard(office: office),
        const SizedBox(height: 11.67),
        _ServiceCard(office: office, onServiceLine: onServiceLine),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.office, this.heroBytes});

  final Office office;
  final Uint8List? heroBytes;

  Widget _hall() {
    return Image.asset(
      office.heroAsset,
      fit: BoxFit.cover,
      alignment: Alignment(0, office.heroFocus * 2 - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x29062358),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 196,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              heroBytes == null
                  ? _hall()
                  : Image.memory(
                      heroBytes!,
                      fit: BoxFit.cover,
                      alignment: Alignment(0, office.heroFocus * 2 - 1),
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) => _hall(),
                    ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Color(0x0D062358),
                      Color(0x8C062358),
                      Color(0xF0062358),
                    ],
                    stops: <double>[0.2, 0.58, 1],
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x4D000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                      BoxShadow(color: BrandColors.sealGold, spreadRadius: 5),
                      BoxShadow(color: Colors.white, spreadRadius: 3),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(office.insetAsset, fit: BoxFit.cover),
                  ),
                ),
              ),
              if (office.representative)
                const Positioned(
                  left: 14,
                  top: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xF0FFFFFF),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text(
                        'Representative photo',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: BrandColors.taytayBlueDark,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.sealGold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TaytayIcon(
                            icon: office.eyebrow == 'BUSINESS'
                                ? TaytayIcons.briefcase
                                : _officeIcon(office.icon),
                            size: 12,
                            color: BrandColors.taytayBlueDark,
                            semanticLabel: '',
                            excludeSemantics: true,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            office.eyebrow,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: BrandColors.taytayBlueDark,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      office.name,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.3,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: _cardDecoration,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < office.facts.length; i++)
            _FactRow(fact: office.facts[i], last: i == office.facts.length - 1),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact, required this.last});

  final OfficeFact fact;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: DirectoryCanvas._rowLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Tile(icon: _factIcon(fact.icon), label: fact.label),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wraps = _factValueWraps(
                  fact.value,
                  constraints.maxWidth,
                );
                return Padding(
                  padding: EdgeInsets.only(bottom: wraps ? 0.67 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(fact.label, style: _factLabel),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: <Widget>[
                          Text(fact.value, style: _factValue),
                          if (fact.sample) const SampleTag(),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.office, this.onServiceLine});

  final Office office;
  final ValueChanged<String>? onServiceLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Services', style: _cardTitle),
          const SizedBox(height: 6),
          for (final OfficeServiceLine line in office.services)
            _serviceRow(line),
        ],
      ),
    );
  }

  Widget _serviceRow(OfficeServiceLine line) {
    final String? slug = line.serviceSlug;
    final Widget row = Padding(
      padding: const EdgeInsets.fromLTRB(18, 3, 0, 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 7, right: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DirectoryCanvas._bodyInk,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 4, height: 4),
            ),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: <Widget>[
                Text(line.label, style: _service),
                if (line.sample) const SampleTag(),
              ],
            ),
          ),
        ],
      ),
    );
    if (slug == null || slug.isEmpty || onServiceLine == null) return row;
    return GestureDetector(onTap: () => onServiceLine!(slug), child: row);
  }
}

class _ComposeBody extends StatelessWidget {
  const _ComposeBody({
    required this.office,
    this.onSend,
    this.messageController,
    this.selectedTopic,
    this.onTopic,
  });

  final Office office;
  final VoidCallback? onSend;
  final TextEditingController? messageController;
  final String? selectedTopic;
  final VoidCallback? onTopic;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        // MSWDO's wrapped "To" name sits a line higher than the other drafts.
        if (office.id == 'mswdo') const SizedBox(height: 4 / 3),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Row(
            children: <Widget>[
              _Tile(
                icon: office.id == 'pio'
                    ? TaytayIcons.megaphone
                    : _officeIcon(office.icon),
                label: office.shortName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('To', style: _factLabel),
                    Text(office.composeTo ?? office.name, style: _listTitle),
                  ],
                ),
              ),
            ],
          ),
        ),
        const _FieldLabel('Topic'),
        _Hit(
          hitKey: const Key('directory-topic'),
          label: 'Topic',
          onTap: onTopic,
          child: _FieldBox(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    selectedTopic ?? office.topic ?? '',
                    style: _fieldInk,
                  ),
                ),
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
        ),
        const _FieldLabel('Message'),
        _FieldBox(
          height: 170,
          alignTop: true,
          child: messageController == null
              ? Text(office.draft ?? '', style: _fieldBody)
              : TextField(
                  key: const Key('directory-message-field'),
                  controller: messageController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: _fieldBody,
                  cursorColor: BrandColors.taytayBlue,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
        ),
        // The paperclip sits above the cap height. 10dp keeps that ink on
        // the design's attach line; 8dp lifts the run by more than 2dp.
        const SizedBox(height: 10),
        const Row(
          children: <Widget>[
            TaytayIcon(
              icon: TaytayIcons.paperclip,
              size: 16,
              color: BrandColors.taytayBlue,
              semanticLabel: '',
              excludeSemantics: true,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Attach photo or PDF (optional)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.taytayBlue,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
        // 14dp is the design gap under the attach row. The 10 above it
        // stays, so the paperclip keeps its line and the notice does not.
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration.copyWith(color: const Color(0xFFF6F8FB)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.shield,
                size: 18,
                color: BrandColors.listMeta,
                semanticLabel: '',
                excludeSemantics: true,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(office.privacy ?? '', style: _privacy)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FilledButton(
          hitKey: const Key('directory-send'),
          label: 'Send message',
          icon: TaytayIcons.send,
          onTap: onSend,
        ),
      ],
    );
  }
}

class _SentBody extends StatelessWidget {
  const _SentBody({required this.emergencyPhone, this.onMessages, this.onBack});

  final String emergencyPhone;
  final VoidCallback? onMessages;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final String phone = emergencyPhone;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(10, 40, 10, 0),
          child: Column(
            children: <Widget>[
              _SentMark(),
              SizedBox(height: 16),
              Text(
                'Message sent',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  style: _sentCopy,
                  children: <InlineSpan>[
                    TextSpan(
                      text:
                          'The office usually replies within 1–2 working days ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 1),
                        child: SampleTag(),
                      ),
                    ),
                    TextSpan(
                      text:
                          ". We'll notify you, and the conversation is saved in My Account › Messages.",
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 23),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.shield,
                size: 18,
                color: BrandColors.listMeta,
                semanticLabel: '',
                excludeSemantics: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "For emergencies don't wait for a reply: call the Sagip "
                  'Taytay Command Center, $phone.',
                  style: _privacy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FilledButton(
          hitKey: const Key('directory-go-messages'),
          label: 'Go to Messages',
          icon: TaytayIcons.inbox,
          onTap: onMessages,
        ),
        const SizedBox(height: 10),
        _StrokeButton(
          hitKey: const Key('directory-back-directory'),
          label: 'Back to Directory',
          onTap: onBack,
        ),
      ],
    );
  }
}

class _SentMark extends StatelessWidget {
  const _SentMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: Color(0xFFE6F4EC),
        shape: BoxShape.circle,
      ),
      child: const TaytayIcon(
        icon: TaytayIcons.send,
        size: 38,
        color: BrandColors.success,
        semanticLabel: '',
        excludeSemantics: true,
      ),
    );
  }
}

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({required this.bubbles, required this.dayLabel});

  final List<DirectoryThreadBubble> bubbles;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 22.33, 16, 8),
            children: <Widget>[
              Center(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF1F6),
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    child: Text(
                      dayLabel,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: BrandColors.listMeta,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final DirectoryThreadBubble bubble in bubbles)
                _Bubble(bubble: bubble),
              const SizedBox(height: 1.67),
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
          child: const Row(
            children: <Widget>[
              TaytayIcon(
                icon: TaytayIcons.paperclip,
                size: 20,
                color: BrandColors.listMeta,
                semanticLabel: 'Attach',
              ),
              SizedBox(width: 10),
              Expanded(
                child: _FieldBox(child: Text('Write a message…', style: _hint)),
              ),
              SizedBox(width: 10),
              _Hit(
                hitKey: Key('directory-thread-send'),
                label: 'Send',
                width: 42,
                height: 42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.taytayBlue,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 42,
                    height: 42,
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
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.bubble});

  final DirectoryThreadBubble bubble;

  @override
  Widget build(BuildContext context) {
    final bool mine = bubble.fromResident;
    final Widget body = bubble.attachment == null
        ? Text(
            bubble.body ?? '',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: mine ? Colors.white : BrandColors.textPrimary,
              decoration: TextDecoration.none,
            ),
          )
        : Row(
            children: <Widget>[
              const _Tile(
                icon: TaytayIcons.fileText,
                label: 'Attachment',
                size: 36,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(bubble.attachment!, style: _factValue),
                    const SizedBox(height: 7.33),
                    Text(bubble.attachmentMeta ?? '', style: _meta),
                  ],
                ),
              ),
            ],
          );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 270),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              child: body,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                4,
                bubble.when.contains('9:06') ? 8 : 6,
                4,
                bubble.when.contains('Seen')
                    ? 9
                    : bubble.when.contains('9:06')
                    ? 10
                    : 12,
              ),
              child: Text(bubble.when, style: _meta),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({
    required this.offices,
    required this.compact,
    this.onOffice,
    this.lineFor,
    this.trailingCall = false,
    this.looseSubtitle = false,
  });

  final List<Office> offices;
  final bool compact;
  final ValueChanged<Office>? onOffice;
  final String Function(Office office)? lineFor;
  final bool trailingCall;
  final bool looseSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: _cardDecoration,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < offices.length; i++)
            _OfficeRow(
              office: offices[i],
              compact: compact,
              last: i == offices.length - 1,
              line: lineFor?.call(offices[i]) ?? offices[i].listLine,
              trailingCall: trailingCall,
              looseSubtitle: looseSubtitle,
              onTap: onOffice == null ? null : () => onOffice!(offices[i]),
            ),
        ],
      ),
    );
  }
}

class _OfficeRow extends StatelessWidget {
  const _OfficeRow({
    required this.office,
    required this.compact,
    required this.last,
    required this.line,
    required this.trailingCall,
    this.looseSubtitle = false,
    this.onTap,
  });

  final Office office;
  final bool compact;
  final bool last;
  final String line;
  final bool trailingCall;
  final bool looseSubtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String title = trailingCall
        ? (office.savedName ?? office.listName)
        : office.listName;
    final bool wrapped = compact && (title.length > 26 || line.length > 36);
    return _Hit(
      hitKey: Key('directory-office-${office.id}'),
      label: title,
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 52 : 0),
        padding: EdgeInsets.fromLTRB(
          0,
          compact ? 6 : 12,
          0,
          compact ? (wrapped ? 6.5 : 6) : 12,
        ),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: DirectoryCanvas._rowLine),
                ),
        ),
        child: Row(
          children: <Widget>[
            _Tile(
              icon: _officeIcon(office.icon),
              label: office.shortName,
              size: compact ? 40 : 44,
              alignY: compact ? -0.05 : 0,
              background: office.id == 'mdrrmo' && trailingCall
                  ? const Color(0xFFFDECEC)
                  : BrandColors.surfaceMuted,
              color: office.id == 'mdrrmo' && trailingCall
                  ? BrandColors.danger
                  : BrandColors.taytayBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    textHeightBehavior: _cssHalfLeading,
                    style: compact ? _compactTitle : _listTitle,
                  ),
                  SizedBox(height: looseSubtitle ? 3 : 2),
                  Text(
                    line,
                    textHeightBehavior: looseSubtitle
                        ? _looseLeading
                        : _cssHalfLeading,
                    style: compact
                        ? _compactSub
                        : (looseSubtitle ? _rowSubLoose : _rowSub),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (trailingCall)
              _Hit(
                hitKey: Key('directory-saved-call-${office.id}'),
                label: 'Call $title',
                width: 36,
                height: 36,
                onTap: onTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: office.id == 'mdrrmo'
                        ? BrandColors.chipBlueBg
                        : BrandColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: TaytayIcon(
                    icon: TaytayIcons.phone,
                    size: 16,
                    color: office.id == 'mdrrmo'
                        ? BrandColors.danger
                        : BrandColors.taytayBlue,
                    semanticLabel: '',
                    excludeSemantics: true,
                  ),
                ),
              )
            else
              const SizedBox(
                width: 18,
                height: 40,
                child: Align(
                  alignment: Alignment(0, 0.24),
                  child: TaytayIcon(
                    icon: TaytayIcons.chevronRight,
                    size: 18,
                    color: BrandColors.chevron,
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

class _SearchBox extends StatefulWidget {
  const _SearchBox({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.active = false,
    this.showClear = true,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool active;
  final bool showClear;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  TextEditingController? _owned;

  TextEditingController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = TextEditingController();
    }
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(_SearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    (oldWidget.controller ?? _owned)?.removeListener(_changed);
    if (widget.controller == null && _owned == null) {
      _owned = TextEditingController();
    }
    _controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool filled = _controller.text.isNotEmpty;
    final bool active = widget.active || filled;
    final TextStyle ink = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 14,
      height: 1,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      color: active ? BrandColors.textPrimary : DirectoryCanvas._searchInk,
      decoration: TextDecoration.none,
    );
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? BrandColors.taytayBlue
              : DirectoryCanvas._searchBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          TaytayIcon(
            icon: TaytayIcons.search,
            size: 18,
            color: active ? BrandColors.taytayBlue : DirectoryCanvas._searchInk,
            semanticLabel: 'Search',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                maxLines: 1,
                style: ink,
                cursorColor: BrandColors.taytayBlue,
                cursorWidth: 1.2,
                decoration: InputDecoration(
                  isCollapsed: true,
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: ink.copyWith(
                    fontWeight: FontWeight.w500,
                    color: DirectoryCanvas._searchInk,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (active && widget.showClear && filled)
            const TaytayIcon(
              icon: TaytayIcons.close,
              size: 16,
              color: BrandColors.listMeta,
              semanticLabel: 'Clear search',
            ),
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.labels,
    required this.selected,
    this.wrap = false,
  });

  final List<String> labels;
  final String selected;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      for (final String label in labels)
        _Chip(label: label, on: label == selected),
    ];
    if (wrap) {
      return Wrap(spacing: 7, runSpacing: 8, children: chips);
    }
    return SizedBox(
      height: 36,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect rect) {
          return const LinearGradient(
            colors: <Color>[Colors.white, Colors.white, Colors.transparent],
            stops: <double>[0, 0.85, 1],
          ).createShader(rect);
        },
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            for (var i = 0; i < chips.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 7),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on});

  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: on ? BrandColors.taytayBlue : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: on ? BrandColors.taytayBlue : DirectoryCanvas._chipBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: on ? Colors.white : DirectoryCanvas._chipInk,
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.size = 44,
    this.background = BrandColors.surfaceMuted,
    this.color = BrandColors.taytayBlue,
    this.alignY = 0,
  });

  final IconData icon;
  final String label;
  final double size;
  final Color background;
  final Color color;
  final double alignY;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment(0, alignY),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TaytayIcon(
        icon: icon,
        size: 20,
        color: color,
        semanticLabel: label,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: BrandColors.fieldLabel,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.child,
    this.height = 44,
    this.alignTop = false,
  });

  final Widget child;
  final double height;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, alignTop ? 10.67 : 0, 12, 0),
      alignment: alignTop ? Alignment.topLeft : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DirectoryCanvas._fieldBorder, width: 1.3),
      ),
      child: child,
    );
  }
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({
    required this.label,
    this.hitKey,
    this.icon,
    this.onTap,
    this.danger = false,
  });

  final String label;
  final Key? hitKey;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      hitKey: hitKey,
      label: label,
      height: 48,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger ? BrandColors.danger : BrandColors.taytayBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              TaytayIcon(
                icon: icon!,
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
                style: _button.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokeButton extends StatelessWidget {
  const _StrokeButton({
    required this.label,
    this.hitKey,
    this.icon,
    this.onTap,
  });

  final String label;
  final Key? hitKey;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _Hit(
      hitKey: hitKey,
      label: label,
      height: 48,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandColors.taytayBlue, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              TaytayIcon(
                icon: icon!,
                size: 16,
                color: BrandColors.taytayBlue,
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
                style: _button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMark extends StatelessWidget {
  const _EmptyMark({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFFEEF1F6),
        shape: BoxShape.circle,
      ),
      child: TaytayIcon(
        icon: icon,
        size: 28,
        color: BrandColors.listMeta,
        semanticLabel: '',
        excludeSemantics: true,
      ),
    );
  }
}

/// Lays out [child] at its own size. A mark smaller than 48 dp keeps a 48 dp
/// hit without growing the layout. A row or button is the hit itself.
class _Hit extends StatelessWidget {
  const _Hit({
    required this.child,
    required this.label,
    this.hitKey,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final String label;
  final Key? hitKey;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final double? slotW = width;
    final double? slotH = height;
    if (slotW == null || slotH == null) {
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
    final double hitW = slotW < 48 ? 48 : slotW;
    final double hitH = slotH < 48 ? 48 : slotH;
    return SizedBox(
      width: slotW,
      height: slotH,
      child: OverflowBox(
        minWidth: hitW,
        maxWidth: hitW,
        minHeight: hitH,
        maxHeight: hitH,
        child: Semantics(
          button: onTap != null,
          label: label,
          child: GestureDetector(
            key: hitKey,
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: hitW,
              height: hitH,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _officeIcon(OfficeIcon icon) => switch (icon) {
  OfficeIcon.handHeart => TaytayIcons.handHeart,
  OfficeIcon.landmark => TaytayIcons.landmark,
  OfficeIcon.fileText => TaytayIcons.fileText,
  OfficeIcon.building2 => TaytayIcons.building2,
  OfficeIcon.siren => TaytayIcons.siren,
  OfficeIcon.graduationCap => TaytayIcons.graduationCap,
  OfficeIcon.newspaper => TaytayIcons.newspaper,
  OfficeIcon.users => TaytayIcons.users,
  OfficeIcon.stethoscope => TaytayIcons.stethoscope,
};

IconData _factIcon(OfficeFactIcon icon) => switch (icon) {
  OfficeFactIcon.pin => TaytayIcons.mapPin,
  OfficeFactIcon.clock => TaytayIcons.clock,
  OfficeFactIcon.phone => TaytayIcons.phone,
  OfficeFactIcon.mail => TaytayIcons.mail,
  OfficeFactIcon.message => TaytayIcons.messageSquare,
  OfficeFactIcon.siren => TaytayIcons.siren,
};

const BoxDecoration _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  border: Border.fromBorderSide(BorderSide(color: BrandColors.cardLine)),
);

const TextHeightBehavior _cssHalfLeading = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Extra leading sits between lines. The first line stays put, so a
/// single-line row does not grow.
const TextHeightBehavior _looseLeading = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

bool _factValueWraps(String value, double maxWidth) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: value, style: _factValue),
    textDirection: TextDirection.ltr,
    maxLines: 4,
  )..layout(maxWidth: maxWidth);
  final bool wraps = painter.computeLineMetrics().length > 1;
  painter.dispose();
  return wraps;
}

const TextStyle _listTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 1.2,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _compactTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.26,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _compactSub = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.26,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _meta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _rowSub = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.2,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _rowSubLoose = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 1.24,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _summary = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  height: 1.5,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight.w500,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _credit = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.5,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _factLabel = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const TextStyle _factValue = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _cardTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _service = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 13,
  height: 1.55,
  fontWeight: FontWeight.w500,
  color: DirectoryCanvas._bodyInk,
  decoration: TextDecoration.none,
);

const TextStyle _button = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  color: BrandColors.taytayBlue,
  decoration: TextDecoration.none,
);

const TextStyle _fieldInk = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _fieldBody = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  height: 1.5,
  fontWeight: FontWeight.w500,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _hint = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: DirectoryCanvas._searchInk,
  decoration: TextDecoration.none,
);

const TextStyle _sentCopy = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  height: 1.5,
  fontWeight: FontWeight.w500,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);

const TextStyle _privacy = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  height: 1.5,
  leadingDistribution: TextLeadingDistribution.even,
  fontWeight: FontWeight.w500,
  color: BrandColors.textSecondary,
  decoration: TextDecoration.none,
);
