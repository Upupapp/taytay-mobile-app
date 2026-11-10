import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/ringed_input_border.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/message_field.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/pill_button_row.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/status_line.dart';
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
    this.emergencyPhone = '',
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
      _ => Column(
        children: <Widget>[
          _messagingHeader(current),
          Expanded(child: _messagingBody(current)),
        ],
      ),
    };
    return Material(
      color: frame == DirectoryFrame.detail
          ? BrandColors.white
          : BrandColors.background,
      child: page,
    );
  }

  Widget _messagingHeader(Office? current) {
    return switch (frame) {
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
      _ => MunicipalHeader(
        title: current?.shortName ?? '',
        subtitle: current?.name ?? '',
        onBack: onBack,
        plainSeal: true,
      ),
    };
  }

  Widget _messagingBody(Office? current) {
    return switch (frame) {
      DirectoryFrame.compose when current != null => _ComposeBody(
        office: current,
        onSend: onSend,
        messageController: messageController,
        selectedTopic: selectedTopic,
        onTopic: onTopic,
        onAttach: onAttach,
        attachmentLabel: attachmentLabel,
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
              _CategoryChip(
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fill = selected ? BrandColors.blue : BrandColors.chipFill;
    final Color ink = selected ? BrandColors.white : BrandColors.text;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: A11y.minTapTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: fill,
                shape: const StadiumBorder(),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ComponentSizes.chipHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.section,
                    vertical: Spacing.sm,
                  ),
                  child: Text(
                    label,
                    style: AppTypography.chip.copyWith(color: ink),
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

class _ComposeBody extends StatelessWidget {
  const _ComposeBody({
    required this.office,
    this.onSend,
    this.messageController,
    this.selectedTopic,
    this.onTopic,
    this.onAttach,
    this.attachmentLabel,
  });

  final Office office;
  final VoidCallback? onSend;
  final TextEditingController? messageController;
  final String? selectedTopic;
  final VoidCallback? onTopic;
  final VoidCallback? onAttach;
  final String? attachmentLabel;

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
                // No chevron when there is nothing to choose: the field then
                // only says what the subject will be.
                if (office.offersTopics)
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
        MessageField(
          controller: messageController,
          preview: office.draft ?? '',
          fieldKey: const Key('directory-message-field'),
        ),
        // The paperclip sits above the cap height. 10dp keeps that ink on
        // the design's attach line; 8dp lifts the run by more than 2dp.
        const SizedBox(height: 10),
        _attachBlock(),
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

  /// The specimen row when nothing is attached and the control is not live.
  Widget _attachBlock() {
    const Widget row = Row(
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
    );
    if (onAttach == null && attachmentLabel == null) return row;
    final String? label = attachmentLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Hit(
          hitKey: const Key('directory-attach'),
          label: 'Attach photo or PDF (optional)',
          onTap: onAttach,
          child: row,
        ),
        if (label != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrandColors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
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

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, this.size = 44});

  final IconData icon;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BrandColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TaytayIcon(
        icon: icon,
        size: 20,
        color: BrandColors.taytayBlue,
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
  const _FieldBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MessageField.border, width: 1.3),
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
        decoration: BoxDecoration(
          color: BrandColors.taytayBlue,
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
  const _StrokeButton({required this.label, this.hitKey, this.onTap});

  final String label;
  final Key? hitKey;
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

const TextStyle _listTitle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 1.2,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.textPrimary,
  decoration: TextDecoration.none,
);

const TextStyle _meta = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
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

const TextStyle _hint = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: BrandColors.muted,
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
