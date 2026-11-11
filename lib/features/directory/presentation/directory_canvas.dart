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
import '../../../shared/widgets/conversation.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/pill_button_row.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/status_line.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../../shared/widgets/taytay_states.dart';
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
/// The list, search and offline frames follow `Directory.dc.html`,
/// `DirectorySearch.dc.html` and `DirectoryOffline.dc.html`: the blue header
/// with the search field, category chips, and the offices as one soft list
/// with gradient tiles. An office page follows `Office.dc.html`: the photo,
/// the white sheet riding over it, pill actions and the facts. Office pages
/// are public information (D11).
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
    this.onHotlines,
    this.dayLabel = '',
    this.query = '',
    this.searchController,
    this.onSearch,
    this.messageController,
    this.selectedTopic,
    this.onTopic,
    this.onAttach,
    this.attachmentLabel,
    this.loadHero,
    this.onServiceLine,
    this.selectedChip = 'All',
    this.onChip,
    this.onBell,
    this.officeMissing = false,
    this.composeError,
    super.key,
  });

  final DirectoryFrame frame;
  final List<Office> offices;
  final List<String> chips;

  /// Opens the Emergency hotlines page from the sent page's emergency note.
  ///
  /// The note names no number. An office's own line is not an emergency line,
  /// and `GET /hotlines` has no field that marks the Command Center or the
  /// primary emergency line (only a free-text name and category), so the note
  /// sends the resident to the page that lists every published hotline.
  final VoidCallback? onHotlines;

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
  final VoidCallback? onAttach;

  /// Chosen file name, or "Attachment" when an existing media id is held.
  final String? attachmentLabel;

  /// `GET /offices/{slug}/hero`. Null keeps the bundled hall.
  final MediaBytesLoader? loadHero;

  /// Opens a Tulong page for a catalogue line. Directory lines have no slug.
  final ValueChanged<String>? onServiceLine;

  /// The category chip in force. 'All' shows every category.
  final String selectedChip;

  /// Null leaves the chips as labels.
  final ValueChanged<String>? onChip;

  /// The header bell. Null draws it without an action.
  final VoidCallback? onBell;

  /// The office page's read answered without an office. The page then says
  /// so, with [onRetry], instead of waiting.
  final bool officeMissing;

  /// What went wrong with the last send, drawn above Send.
  final String? composeError;

  @override
  Widget build(BuildContext context) {
    final Office? current = office;
    final Widget page = switch (frame) {
      DirectoryFrame.list ||
      DirectoryFrame.loading ||
      DirectoryFrame.offline ||
      DirectoryFrame.searchSpecimen => _ListPage(canvas: this),
      DirectoryFrame.detail =>
        current == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BlueHeader(
                    title: 'Directory',
                    subtitle: 'Office details',
                    showBack: true,
                    onBack: onBack,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(Spacing.lg),
                      children: <Widget>[
                        officeMissing
                            ? ErrorState(
                                title: 'This office could not be shown',
                                message:
                                    'Taytay LGU could not be reached, or the '
                                    'office is no longer listed. You can try '
                                    'again.',
                                onRetry: onRetry,
                                boxed: true,
                              )
                            : const LoadingSkeleton(
                                layout: SkeletonLayout.detail,
                                semanticLabel: 'Loading the office',
                              ),
                      ],
                    ),
                  ),
                ],
              )
            : _DetailPage(
                office: current,
                loadHero: loadHero,
                onBack: onBack,
                onCall: onCall,
                onDirections: onDirections,
                onMessage: onMessage,
                onApp: onApp,
                onServiceLine: onServiceLine,
              ),
      DirectoryFrame.compose => _ComposePage(canvas: this),
      DirectoryFrame.sent => _SentPage(canvas: this),
      DirectoryFrame.thread => _ThreadPage(canvas: this),
    };
    return Material(
      color: frame == DirectoryFrame.detail
          ? BrandColors.white
          : BrandColors.background,
      child: page,
    );
  }
}

/// The glyph and tile colour for an office's icon key. An office from the
/// API sends no icon (README "API fields needed"), so it draws the blue
/// directory tile.
(TaytayGlyph, TileTone) _officeTile(OfficeIcon icon) => switch (icon) {
  OfficeIcon.handHeart => (TaytayGlyph.heart, TileTone.green),
  OfficeIcon.landmark => (TaytayGlyph.bank, TileTone.blue),
  OfficeIcon.fileText => (TaytayGlyph.document, TileTone.navy),
  OfficeIcon.building2 => (TaytayGlyph.directory, TileTone.blue),
  OfficeIcon.siren => (TaytayGlyph.siren, TileTone.red),
  OfficeIcon.graduationCap => (TaytayGlyph.graduationCap, TileTone.sky),
  OfficeIcon.newspaper => (TaytayGlyph.megaphone, TileTone.navy),
  OfficeIcon.users => (TaytayGlyph.users, TileTone.gold),
  OfficeIcon.stethoscope => (TaytayGlyph.medicalCross, TileTone.red),
};

/// The office's line without the category it may already start with (the
/// bundled catalogue writes "Business · Ground Floor"), so the category is
/// never said twice.
String _placeOf(Office office, String line) {
  final String prefix = '${office.category} · ';
  if (office.category.isNotEmpty && line.startsWith(prefix)) {
    return line.substring(prefix.length);
  }
  return line == office.category ? '' : line;
}

Widget _tileFor(Office office, {IconTileSize size = IconTileSize.medium}) {
  final (TaytayGlyph glyph, TileTone tone) = _officeTile(office.icon);
  return IconTile.glyph(glyph: glyph, tone: tone, tileSize: size);
}

/// The list, loading, offline and search frames: the blue header (with the
/// search field, except offline), then the frame's body.
class _ListPage extends StatelessWidget {
  const _ListPage({required this.canvas});

  final DirectoryCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final DirectoryCanvas c = canvas;
    final bool search = c.frame == DirectoryFrame.searchSpecimen;
    final bool offline = c.frame == DirectoryFrame.offline;
    final VoidCallback? onBell = c.onBell;
    final Widget header = BlueHeader(
      leading: search ? null : const HeaderSeal(),
      showBack: search,
      onBack: c.onBack,
      title: search ? 'Search' : 'Directory',
      subtitle: search ? 'Directory' : 'Municipal offices',
      actions: <Widget>[
        if (!search)
          HeaderIconButton(
            key: const Key('directory-bell'),
            icon: TaytayIcons.bell,
            semanticLabel: 'Notifications',
            onPressed: onBell,
          ),
      ],
      bottom: offline || search
          ? null
          : _SearchField(
              hint: 'Search offices or services',
              controller: c.searchController,
              onChanged: c.onSearch,
            ),
    );
    final Widget body = switch (c.frame) {
      DirectoryFrame.loading => _LoadingBody(chips: c.chips),
      DirectoryFrame.offline => _OfflineBody(
        offices: c.offices,
        onRetry: c.onRetry,
        onCall: c.onCall,
      ),
      DirectoryFrame.searchSpecimen => _SearchSpecimen(
        offices: c.offices,
        onOffice: c.onOffice,
        onBrowseAll: c.onBrowseAll,
      ),
      _ => _ListBody(
        offices: c.offices,
        chips: c.chips,
        query: c.query,
        selectedChip: c.selectedChip,
        onChip: c.onChip,
        onOffice: c.onOffice,
        onBrowseAll: c.onBrowseAll,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header,
        Expanded(child: body),
      ],
    );
  }
}

/// CSS `.soft .search`: white, 16 radius, 50 tall, the search glyph, and a
/// gold focus outline on the blue header.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, this.controller, this.onChanged});

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    const BorderRadius corners = BorderRadius.all(Radius.circular(Radii.lg));
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTypography.fieldValue.copyWith(
        fontWeight: AppTypography.body,
        color: BrandColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
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

/// CSS `.chipsrow`: the categories in one sideways-scrolling row. The chip
/// in force is solid blue; the rest are the soft grey pill.
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.labels, required this.selected, this.onChip});

  final List<String> labels;
  final String selected;
  final ValueChanged<String>? onChip;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final ValueChanged<String>? onChip = this.onChip;
    return Semantics(
      container: true,
      label: 'Category',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.section,
          Spacing.lg,
          Spacing.xxs,
        ),
        child: Row(
          children: <Widget>[
            for (var i = 0; i < labels.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Spacing.sm),
              SoftChoiceChip(
                label: labels[i],
                selected: labels[i] == selected,
                onTap: onChip == null ? null : () => onChip(labels[i]),
              ),
            ],
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
    required this.selectedChip,
    this.onChip,
    this.onOffice,
    this.onBrowseAll,
  });

  final List<Office> offices;
  final List<String> chips;
  final String query;
  final String selectedChip;
  final ValueChanged<String>? onChip;
  final ValueChanged<Office>? onOffice;
  final VoidCallback? onBrowseAll;

  @override
  Widget build(BuildContext context) {
    final String chip = chips.contains(selectedChip) ? selectedChip : 'All';
    final List<Office> visible = offices
        .where((Office office) => office.matches(query, chip))
        .toList(growable: false);
    final String trimmed = query.trim();
    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: <Widget>[
        _ChipsRow(labels: chips, selected: chip, onChip: onChip),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.section,
            Spacing.lg,
            0,
          ),
          child: visible.isEmpty
              ? EmptyState(
                  title: trimmed.isEmpty
                      ? 'No offices in this category'
                      : 'No offices found for “$trimmed”',
                  message: 'Try another word, or browse by category.',
                  actionLabel: onBrowseAll == null
                      ? null
                      : 'Browse all offices',
                  onAction: onBrowseAll,
                  boxed: true,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _CountLine(count: visible.length),
                    const SizedBox(height: Spacing.sm + Spacing.xxs),
                    _OfficeList(offices: visible, onOffice: onOffice),
                  ],
                ),
        ),
      ],
    );
  }
}

/// CSS `.count`: "9 offices", the number in bold ink.
class _CountLine extends StatelessWidget {
  const _CountLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.listDetail.copyWith(
      fontWeight: AppTypography.medium,
      color: BrandColors.muted,
    );
    return Semantics(
      liveRegion: true,
      child: Text.rich(
        TextSpan(
          style: style,
          children: <InlineSpan>[
            TextSpan(
              text: '$count',
              style: const TextStyle(
                fontWeight: AppTypography.black,
                color: BrandColors.ink,
              ),
            ),
            TextSpan(text: count == 1 ? ' office' : ' offices'),
          ],
        ),
      ),
    );
  }
}

/// The offices as one soft list: gradient tile, name, category and line.
class _OfficeList extends StatelessWidget {
  const _OfficeList({required this.offices, this.onOffice, this.lineFor});

  final List<Office> offices;
  final ValueChanged<Office>? onOffice;
  final String Function(Office office)? lineFor;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<Office>? onOffice = this.onOffice;
    return SettingsList(
      children: <Widget>[
        for (final Office office in offices)
          _OfficeRow(
            office: office,
            line: lineFor?.call(office) ?? office.listLine,
            onTap: onOffice == null ? null : () => onOffice(office),
          ),
      ],
    );
  }
}

/// CSS `.li` on Directory: the tile, the office name, and the category in
/// body ink before the rest of the line (`.d .k`).
class _OfficeRow extends StatelessWidget {
  const _OfficeRow({required this.office, required this.line, this.onTap});

  final Office office;
  final String line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String category = office.category;
    final TextStyle detail = AppTypography.listDetail.copyWith(
      color: BrandColors.muted,
    );
    final String rest = _placeOf(office, line);
    return SettingsRow(
      key: Key('directory-office-${office.id}'),
      leading: _tileFor(office),
      title: office.listName,
      detail: <String>[
        if (category.isNotEmpty) category,
        if (rest.isNotEmpty) rest,
      ].join(' · '),
      detailStyle: detail,
      semanticLabel: <String>[
        office.listName,
        if (category.isNotEmpty) category,
        if (rest.isNotEmpty) rest,
      ].join(', '),
      onTap: onTap,
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: <Widget>[
        _ChipsRow(labels: chips, selected: 'All'),
        const Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.section,
            Spacing.lg,
            0,
          ),
          child: SoftCard(
            child: LoadingSkeleton(
              count: 6,
              semanticLabel: 'Loading the directory',
            ),
          ),
        ),
      ],
    );
  }
}

/// `DirectoryOffline.dc.html`: the gold offline strip, the boxed "Can't
/// load" state with Try again, and the numbers saved on this phone.
class _OfflineBody extends StatelessWidget {
  const _OfflineBody({required this.offices, this.onRetry, this.onCall});

  final List<Office> offices;
  final VoidCallback? onRetry;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.section,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        const _OfflineStrip(),
        const SizedBox(height: Spacing.section),
        EmptyState(
          title: "Can't load the directory",
          message:
              'Check your mobile data or Wi-Fi, then try again. '
              'Saved office numbers are listed below.',
          illustration: TaytayIllustration.offline,
          actionLabel: 'Try again',
          actionIcon: TaytayIcons.refreshCw,
          onAction: onRetry,
          primaryAction: true,
          boxed: true,
          actionKey: const Key('directory-retry'),
        ),
        if (saved.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.xl),
          const SettingsSectionTitle('Saved on this phone'),
          SettingsList(
            children: <Widget>[
              for (final Office office in saved)
                _SavedRow(office: office, onCall: onCall),
            ],
          ),
        ],
      ],
    );
  }
}

/// CSS `.off`: gold-tinted, "You're offline" over "Showing what was saved".
class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.gold50,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.section,
            vertical: Spacing.md,
          ),
          child: Row(
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.wifiOff,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: BrandColors.goldInk,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "You're offline",
                      style: AppTypography.listTitle.copyWith(
                        fontWeight: AppTypography.strong,
                        color: BrandColors.goldInk,
                      ),
                    ),
                    Text(
                      'Showing what was saved on this phone',
                      style: AppTypography.small.copyWith(
                        color: BrandColors.goldInk,
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

/// A saved office number with its round call button (CSS `.call`).
class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.office, this.onCall});

  final Office office;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final String title = office.savedName ?? office.listName;
    final bool emergency = office.callIsEmergency;
    return SettingsRow(
      leading: _tileFor(office),
      title: title,
      detail: office.phone,
      trailing: Semantics(
        button: true,
        label: 'Call $title',
        excludeSemantics: true,
        child: InkResponse(
          key: Key('directory-saved-call-${office.id}'),
          onTap: onCall,
          radius: A11y.minTapTarget / 2,
          child: SizedBox(
            width: A11y.minTapTarget,
            height: A11y.minTapTarget,
            child: Center(
              child: Container(
                width: ComponentSizes.headerIconButton,
                height: ComponentSizes.headerIconButton,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emergency ? BrandColors.red : BrandColors.blue,
                  shape: BoxShape.circle,
                ),
                child: const TaytayIcon(
                  icon: TaytayIcons.phone,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: IconSizes.sm,
                  color: BrandColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `DirectorySearch.dc.html` as a design specimen: two searches side by side,
/// one that finds offices and one that does not. Not routed; captures and
/// tests paint it.
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
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.lg,
        Spacing.lg,
        Spacing.xl,
      ),
      children: <Widget>[
        _SpecimenSearch(
          key: const Key('directory-search-cedula'),
          controller: _cedula,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Text(
            '${found.length} $countWord for “${_cedula.text}”',
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.strong,
              color: BrandColors.muted,
            ),
          ),
        ),
        if (found.isNotEmpty)
          _OfficeList(
            offices: found,
            lineFor: (Office office) => office.searchLine ?? office.listLine,
            onOffice: widget.onOffice,
          ),
        const SizedBox(height: Spacing.xl),
        _SpecimenSearch(
          key: const Key('directory-search-passport'),
          controller: _passport,
        ),
        const SizedBox(height: Spacing.md),
        if (missed.isEmpty)
          EmptyState(
            title: 'No offices found for “${_passport.text}”',
            message:
                'Passports are handled by the DFA, not the municipality. '
                'Try another word, or browse by category.',
            actionLabel: 'Browse all offices',
            onAction: widget.onBrowseAll,
            actionKey: const Key('directory-browse'),
            boxed: true,
          )
        else
          _OfficeList(offices: missed, onOffice: widget.onOffice),
      ],
    );
  }
}

/// The search field of the specimen, on the grey page.
class _SpecimenSearch extends StatelessWidget {
  const _SpecimenSearch({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _SearchField(
      hint: 'Search offices or services',
      controller: controller,
    );
  }
}

/// `Office.dc.html`: the office photo with the back control and seal over
/// it, then the white sheet: tile, names, the category line, the open line
/// when hours are structured, pill actions, the summary and the facts.
class _DetailPage extends StatelessWidget {
  const _DetailPage({
    required this.office,
    this.loadHero,
    this.onBack,
    this.onCall,
    this.onDirections,
    this.onMessage,
    this.onApp,
    this.onServiceLine,
  });

  final Office office;
  final MediaBytesLoader? loadHero;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;
  final VoidCallback? onApp;
  final ValueChanged<String>? onServiceLine;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // No per-item repaint / semantics wrappers: they hit-test only their
      // own box, so the strip GlassOverlap raises over the header would not
      // take a tap.
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      children: <Widget>[
        _Hero(office: office, loadHero: loadHero, onBack: onBack),
        GlassOverlap(
          amount: Radii.sheetLarge,
          child: _Sheet(
            office: office,
            onCall: onCall,
            onDirections: onDirections,
            onMessage: onMessage,
            onApp: onApp,
            onServiceLine: onServiceLine,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.office, this.loadHero, this.onBack});

  final Office office;
  final MediaBytesLoader? loadHero;
  final VoidCallback? onBack;

  static const double _height = 250;

  Widget _hall() {
    return Image.asset(
      office.heroAsset,
      fit: BoxFit.cover,
      alignment: Alignment(0, office.heroFocus * 2 - 1),
    );
  }

  Widget _picture() {
    final Widget hall = _hall();
    final MediaBytesLoader? load = loadHero;
    if (office.heroUrl == null || load == null) return hall;
    return MediaBytesHost(
      id: office.id,
      load: load,
      builder: (Uint8List? bytes) {
        if (bytes == null || bytes.isEmpty) return hall;
        return DecodedMemoryImage(
          bytes: bytes,
          fit: BoxFit.cover,
          alignment: Alignment(0, office.heroFocus * 2 - 1),
          placeholder: hall,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.paddingOf(context).top;
    final String credit = office.credit;
    return SizedBox(
      height: _height + top,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Semantics(
            image: true,
            label: credit.isNotEmpty ? credit : office.name,
            child: ColoredBox(color: BrandColors.navy, child: _picture()),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  BrandColors.navy.withValues(alpha: 0.55),
                  BrandColors.navy.withValues(alpha: 0),
                ],
                stops: const <double>[0, 0.38],
              ),
            ),
          ),
          Positioned(
            left: Spacing.lg,
            right: Spacing.lg,
            top: top + Spacing.section,
            child: Row(
              children: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: A11y.backButtonVisual,
                      height: A11y.backButtonVisual,
                      decoration: BoxDecoration(
                        color: BrandColors.navy.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    TaytayBackButton(onPressed: onBack, translucent: true),
                  ],
                ),
                const Spacer(),
                const HeaderSeal(key: Key('directory-seal')),
              ],
            ),
          ),
          if (office.representative)
            Positioned(
              right: Spacing.section,
              bottom: Radii.sheetLarge + Spacing.section,
              child: _HeroTag(
                credit.isNotEmpty
                    ? 'Representative photo · $credit'
                    : 'Representative photo',
              ),
            )
          else if (credit.isNotEmpty)
            Positioned(
              right: Spacing.section,
              left: Spacing.lg,
              bottom: Radii.sheetLarge + Spacing.section,
              child: Align(
                alignment: Alignment.centerRight,
                child: _HeroTag(credit),
              ),
            ),
        ],
      ),
    );
  }
}

/// CSS `.hero .rep`: a navy pill on the photo.
class _HeroTag extends StatelessWidget {
  const _HeroTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrandColors.navy.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm + Spacing.xxs,
            vertical: Spacing.xs,
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.tiny.copyWith(
              fontWeight: AppTypography.medium,
              color: BrandColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// CSS `.sheet`: white, 28 px top corners, 22 / 20 padding, 18 between parts.
class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.office,
    this.onCall,
    this.onDirections,
    this.onMessage,
    this.onApp,
    this.onServiceLine,
  });

  final Office office;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;
  final VoidCallback? onMessage;
  final VoidCallback? onApp;
  final ValueChanged<String>? onServiceLine;

  @override
  Widget build(BuildContext context) {
    final String category = office.category;
    final String place = _placeOf(office, office.listLine);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: BrandColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Radii.sheetLarge),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.formGutter,
          Spacing.xl - Spacing.xxs,
          Spacing.formGutter,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                _tileFor(office),
                const SizedBox(width: Spacing.section),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          office.shortName,
                          style: AppTypography.pageTitle.copyWith(
                            color: BrandColors.ink,
                          ),
                        ),
                      ),
                      if (office.name != office.shortName) ...<Widget>[
                        const SizedBox(height: Spacing.xxs),
                        Text(
                          office.name,
                          style: AppTypography.listDetail.copyWith(
                            fontWeight: AppTypography.body,
                            color: BrandColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (category.isNotEmpty || place.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.md),
              _MetaLine(category: category, place: place),
            ],
            // Structured hours are an "API field needed": until the API
            // sends them the open / closed line is not drawn.
            StatusLine(hours: null, now: DateTime.now()),
            const SizedBox(height: Spacing.formGap),
            PillButtonRow(
              padding: EdgeInsets.zero,
              wrap: true,
              actions: <PillAction>[
                PillAction(
                  buttonKey: const Key('directory-call'),
                  label: office.callLabel,
                  glyph: TaytayGlyph.phone,
                  primary: true,
                  danger: office.callIsEmergency,
                  onPressed: onCall,
                ),
                PillAction(
                  buttonKey: const Key('directory-directions'),
                  label: 'Directions',
                  glyph: TaytayGlyph.pin,
                  onPressed: onDirections,
                ),
                PillAction(
                  buttonKey: const Key('directory-message'),
                  label: office.messageable ? 'Message' : 'App',
                  glyph: office.messageable
                      ? TaytayGlyph.chat
                      : TaytayGlyph.phone,
                  onPressed: office.messageable ? onMessage : onApp,
                ),
              ],
            ),
            if (office.summary.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              Text(
                office.summary,
                style: AppTypography.bodyStyle.copyWith(
                  color: BrandColors.text,
                  height: 1.55,
                ),
              ),
            ],
            if (office.facts.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              const Divider(
                height: 1,
                thickness: 1,
                color: BrandColors.divider,
              ),
              for (final OfficeFact fact in office.facts) _FactRow(fact: fact),
            ],
            if (office.services.isNotEmpty) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              _Services(office: office, onServiceLine: onServiceLine),
            ],
          ],
        ),
      ),
    );
  }
}

/// CSS `.meta`: the category in green, a dot, then the place.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.category, required this.place});

  final String category;
  final String place;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTypography.bodyStyle.copyWith(
      color: BrandColors.text,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          if (category.isNotEmpty)
            TextSpan(
              text: category,
              style: const TextStyle(
                color: BrandColors.green,
                fontWeight: AppTypography.medium,
              ),
            ),
          if (category.isNotEmpty && place.isNotEmpty)
            const TextSpan(text: '  ·  '),
          if (place.isNotEmpty) TextSpan(text: place),
        ],
      ),
    );
  }
}

/// CSS `.fact`: a 36 px soft glyph square, the label over the value, and a
/// hairline under each row.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final OfficeFact fact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BrandColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.section),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: ComponentSizes.tileSmall,
              height: ComponentSizes.tileSmall,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandColors.background,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: TaytayIcon(
                icon: _factIcon(fact.icon),
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: BrandColors.blue,
              ),
            ),
            const SizedBox(width: Spacing.section),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    fact.label,
                    style: AppTypography.small.copyWith(
                      fontWeight: AppTypography.medium,
                      color: BrandColors.muted,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Spacing.xs + Spacing.xxs,
                    children: <Widget>[
                      Text(
                        fact.value,
                        style: AppTypography.bodyStyle.copyWith(
                          color: BrandColors.ink,
                        ),
                      ),
                      if (fact.sample) const SampleTag(),
                    ],
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

/// The office's Tulong lines. A line with a page opens it.
class _Services extends StatelessWidget {
  const _Services({required this.office, this.onServiceLine});

  final Office office;
  final ValueChanged<String>? onServiceLine;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<String>? open = onServiceLine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SettingsSectionTitle('Services'),
        SettingsList(
          children: <Widget>[
            for (final OfficeServiceLine line in office.services)
              SettingsRow(
                title: line.label,
                trailing: line.sample ? const SampleTag() : null,
                showChevron: true,
                onTap: _slugOf(line) == null || open == null
                    ? null
                    : () => open(_slugOf(line) ?? ''),
              ),
          ],
        ),
      ],
    );
  }

  static String? _slugOf(OfficeServiceLine line) {
    final String? slug = line.serviceSlug;
    return slug == null || slug.isEmpty ? null : slug;
  }
}

/// `NewMessage.dc.html`: the blue header, who the message is to, the
/// topic, the message, an optional file, the privacy note, and Send in the
/// footer with any problem stated just above it.
class _ComposePage extends StatelessWidget {
  const _ComposePage({required this.canvas});

  final DirectoryCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final Office? office = canvas.office;
    final String? error = canvas.composeError;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BlueHeader(
          title: 'New message',
          subtitle: 'Bayan ng Taytay · Rizal',
          showBack: true,
          onBack: canvas.onBack,
          actions: const <Widget>[HeaderSeal()],
        ),
        Expanded(
          child: office == null
              ? const Padding(
                  padding: EdgeInsets.all(Spacing.lg),
                  child: LoadingSkeleton(
                    layout: SkeletonLayout.detail,
                    semanticLabel: 'Loading the office',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.lg,
                    Spacing.xl,
                  ),
                  children: <Widget>[
                    _ToRow(office: office),
                    const SizedBox(height: Spacing.formGap),
                    const AuthFieldLabel('Topic'),
                    const SizedBox(height: Spacing.sm),
                    _TopicField(
                      topic: canvas.selectedTopic ?? office.topic ?? '',
                      chooser: office.offersTopics,
                      onTap: canvas.onTopic,
                    ),
                    const SizedBox(height: Spacing.formGap),
                    const AuthFieldLabel('Message'),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      key: const Key('directory-message-field'),
                      controller: canvas.messageController,
                      minLines: 6,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTypography.fieldValue.copyWith(
                        fontWeight: AppTypography.body,
                        color: BrandColors.ink,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write your message',
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _AttachButton(
                      onAttach: canvas.onAttach,
                      label: canvas.attachmentLabel,
                    ),
                    const SizedBox(height: Spacing.md),
                    SoftNote(message: _privacyLine(office)),
                  ],
                ),
        ),
        if (office != null)
          ColoredBox(
            color: BrandColors.white,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.md,
                Spacing.lg,
                Spacing.lg + Spacing.xs + safeBottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (error != null) ...<Widget>[
                    SoftNote(tone: NoteTone.error, message: error),
                    const SizedBox(height: Spacing.md),
                  ],
                  FilledButton.icon(
                    key: const Key('directory-send'),
                    onPressed: canvas.onSend,
                    icon: const TaytayIcon(
                      icon: TaytayIcons.send,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: IconSizes.sm,
                    ),
                    label: const Text('Send message'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// The office's own privacy sentence when it published one, then the
  /// warning every message carries.
  static String _privacyLine(Office office) {
    final String own = (office.privacy ?? '').trim();
    const String warning =
        'Don’t share passwords or one-time codes in a message.';
    return own.isEmpty ? warning : '$own $warning';
  }
}

/// CSS `.to`: the office tile, "To", and the office's full name.
class _ToRow extends StatelessWidget {
  const _ToRow({required this.office});

  final Office office;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.section,
        vertical: Spacing.md,
      ),
      radius: Radii.lg,
      child: Row(
        children: <Widget>[
          _tileFor(office),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'To',
                  style: AppTypography.small.copyWith(
                    fontWeight: AppTypography.strong,
                    color: BrandColors.muted,
                  ),
                ),
                Text(
                  office.composeTo ?? office.name,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The subject as a filled field. It opens the office's topics when there
/// are any to choose; otherwise it only says what the subject will be.
class _TopicField extends StatelessWidget {
  const _TopicField({required this.topic, required this.chooser, this.onTap});

  final String topic;
  final bool chooser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius corners = BorderRadius.circular(Radii.field);
    return Semantics(
      button: onTap != null,
      label: topic.isEmpty ? 'Topic' : 'Topic, $topic',
      excludeSemantics: true,
      child: Material(
        color: BrandColors.softFill,
        borderRadius: corners,
        child: InkWell(
          key: const Key('directory-topic'),
          borderRadius: corners,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ComponentSizes.fieldHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      topic,
                      style: AppTypography.fieldValue.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                  ),
                  if (chooser)
                    const TaytayIcon(
                      icon: TaytayIcons.chevronDown,
                      semanticLabel: '',
                      excludeSemantics: true,
                      size: IconSizes.sm,
                      color: BrandColors.chevron,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CSS `.attach`: a soft blue pill, then the chosen file's name.
class _AttachButton extends StatelessWidget {
  const _AttachButton({this.onAttach, this.label});

  final VoidCallback? onAttach;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final String? label = this.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilledButton.tonalIcon(
          key: const Key('directory-attach'),
          onPressed: onAttach,
          style: TaytayButtonStyles.compact().copyWith(
            shape: const WidgetStatePropertyAll<OutlinedBorder>(
              StadiumBorder(),
            ),
          ),
          icon: const TaytayIcon(
            icon: TaytayIcons.paperclip,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
          ),
          label: const Text('Attach photo or PDF (optional)'),
        ),
        if (label != null) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.listDetail.copyWith(
              fontWeight: AppTypography.medium,
              color: BrandColors.text,
            ),
          ),
        ],
      ],
    );
  }
}

/// The emergency note on the sent page.
const Key messageSentEmergencyNoteKey = Key('message-sent-emergency');

/// The note's button to the Emergency hotlines page.
const Key messageSentHotlinesKey = Key('message-sent-hotlines');

/// What the sent page's emergency note says: the mock-up's bold title, then
/// the sentence. It names no number and no line (D-196): the button opens the
/// hotlines Taytay LGU publishes.
abstract final class MessageSentCopy {
  static const String emergencyHeading =
      "For emergencies don't wait for a reply";
  static const String emergency = 'Call an emergency hotline.';
  static const String hotlinesButton = 'See emergency hotlines';
}

/// `MessageSent.dc.html`: the success page with who it went to, what
/// happens next, an emergency note that opens the hotlines, and the way to
/// Messages and back to the Directory.
class _SentPage extends StatelessWidget {
  const _SentPage({required this.canvas});

  final DirectoryCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final Office? office = canvas.office;
    final VoidCallback? onHotlines = canvas.onHotlines;
    return SuccessScreen(
      title: 'Message sent',
      message:
          "We'll notify you, and the conversation is saved in My Account › "
          'Messages.',
      details: <SuccessDetail>[
        if (office != null) SuccessDetail(label: 'To', value: office.shortName),
      ],
      // No number: the messaged office's line is not an emergency line, and
      // nothing in `GET /hotlines` marks which hotline is the primary one.
      body: SoftNote(
        key: messageSentEmergencyNoteKey,
        tone: NoteTone.emergency,
        heading: MessageSentCopy.emergencyHeading,
        message: MessageSentCopy.emergency,
        // Part of the page, not news: read in order, not announced over the
        // page's own title.
        live: false,
        action: onHotlines == null
            ? null
            // The design system's pill (`PillButtonRow`, the danger tone): a
            // 40 px pill in a 48 dp target, wrapping at 200%.
            : PillButtonRow(
                wrap: true,
                padding: EdgeInsets.zero,
                actions: <PillAction>[
                  PillAction(
                    label: MessageSentCopy.hotlinesButton,
                    glyph: TaytayGlyph.phone,
                    danger: true,
                    buttonKey: messageSentHotlinesKey,
                    onPressed: onHotlines,
                  ),
                ],
              ),
      ),
      primaryLabel: 'Go to Messages',
      onPrimary: canvas.onMessages,
      secondaryLabel: 'Back to Directory',
      onSecondary: canvas.onBack,
      showBack: true,
      onBack: canvas.onBack,
    );
  }
}

/// A read-only conversation with an office (`Conversation.dc.html` without
/// the composer): the office in the header, the day, and the bubbles.
class _ThreadPage extends StatelessWidget {
  const _ThreadPage({required this.canvas});

  final DirectoryCanvas canvas;

  @override
  Widget build(BuildContext context) {
    final Office? office = canvas.office;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BlueHeader(
          title: office?.shortName ?? '',
          subtitle: office == null || office.name == office.shortName
              ? null
              : office.name,
          showBack: true,
          onBack: canvas.onBack,
        ),
        Expanded(
          child: Semantics(
            container: true,
            label: 'Conversation',
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.section,
                Spacing.lg,
                Spacing.xl,
              ),
              children: <Widget>[
                if (canvas.dayLabel.isNotEmpty) ...<Widget>[
                  ConversationDayChip(canvas.dayLabel),
                  const SizedBox(height: Spacing.md),
                ],
                for (final DirectoryThreadBubble bubble in canvas.bubbles)
                  ConversationBubble(
                    body: bubble.body ?? '',
                    meta: bubble.when,
                    mine: bubble.fromResident,
                    attachments: <Widget>[
                      if (bubble.attachment case final String name)
                        _FileLine(
                          name: name,
                          meta: bubble.attachmentMeta,
                          mine: bubble.fromResident,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// CSS `.file`: a file in a message, its name over its type and size.
class _FileLine extends StatelessWidget {
  const _FileLine({required this.name, required this.mine, this.meta});

  final String name;
  final String? meta;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final String? meta = this.meta;
    final Color ink = mine ? BrandColors.white : BrandColors.ink;
    return Row(
      children: <Widget>[
        const IconTile.glyph(
          glyph: TaytayGlyph.document,
          tone: TileTone.red,
          tileSize: IconTileSize.small,
        ),
        const SizedBox(width: Spacing.md),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: AppTypography.listTitle.copyWith(
                  fontWeight: AppTypography.strong,
                  color: ink,
                ),
              ),
              if (meta != null)
                Text(
                  meta,
                  style: AppTypography.small.copyWith(
                    color: mine ? BrandColors.onHeaderLede : BrandColors.muted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _factIcon(OfficeFactIcon icon) => switch (icon) {
  OfficeFactIcon.pin => TaytayIcons.mapPin,
  OfficeFactIcon.clock => TaytayIcons.clock,
  OfficeFactIcon.phone => TaytayIcons.phone,
  OfficeFactIcon.mail => TaytayIcons.mail,
  OfficeFactIcon.message => TaytayIcons.messageSquare,
  OfficeFactIcon.siren => TaytayIcons.siren,
};
