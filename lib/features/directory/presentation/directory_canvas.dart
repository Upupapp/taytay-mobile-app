import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/l10n/directory_copy.dart';
import '../../../core/result/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/conversation.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/header_search_field.dart';
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
    this.officeUnavailable = false,
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
    this.failure,
    this.environment = AppEnvironment.prod,
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
    this.selectedChip = Office.allChip,
    this.onChip,
    this.onBell,
    this.officeMissing = false,
    this.composeError,
    this.commandCenter,
    this.commandCenterLoading = false,
    this.onCallCommandCenter,
    super.key,
  });

  final DirectoryFrame frame;
  final List<Office> offices;
  final List<String> chips;

  /// Opens the Emergency hotlines page from the sent page's emergency note.
  ///
  /// The messaged office's own line is never offered: it is not an emergency
  /// line. The button stays whether or not a command center is named.
  final VoidCallback? onHotlines;

  /// The active hotline whose `kind` is `command-center` (backend `ebd7aeb`),
  /// for the sent page's emergency note: its name and number, and a call
  /// button. Null keeps the note that names no number (D-196): none is
  /// marked, the hotlines are still loading, or they could not be read
  /// (D-214). Never chosen by a name or a category.
  final EmergencyLine? commandCenter;

  /// The hotlines the note reads are still loading.
  final bool commandCenterLoading;

  /// Calls [commandCenter].
  final VoidCallback? onCallCommandCenter;

  /// The day chip on the thread. The fixture supplies it.
  final String dayLabel;
  final Office? office;

  /// The compose page's office read answered with nothing; [onRetry] reads
  /// it again.
  final bool officeUnavailable;
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

  /// Why [DirectoryFrame.offline] could not read the list. Only no
  /// connection is said as offline; any other failure is a [FailureView] in
  /// its own words, without the "You're offline" strip (D-221). Null draws
  /// the offline frame, as the design does.
  final AppFailure? failure;

  /// Decides whether a failure's diagnostics show. Production by default, so
  /// a caller that forgets it never shows them.
  final AppEnvironment environment;
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
    final AppStrings strings = AppStrings.of(context);
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
                    title: strings.navServices,
                    subtitle: strings.dirOfficeDetails,
                    showBack: true,
                    onBack: onBack,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(Spacing.lg),
                      children: <Widget>[
                        officeMissing
                            ? ErrorState(
                                title: strings.dirOfficeNotShownTitle,
                                message: strings.dirOfficeNotShownBody,
                                onRetry: onRetry,
                                boxed: true,
                              )
                            : LoadingSkeleton(
                                layout: SkeletonLayout.detail,
                                semanticLabel: strings.dirLoadingOffice,
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
    final AppStrings strings = AppStrings.of(context);
    final Widget header = BlueHeader(
      leading: search ? null : const HeaderSeal(),
      showBack: search,
      onBack: c.onBack,
      title: search ? strings.dirSearchTitle : strings.navServices,
      subtitle: search ? strings.navServices : strings.dirMunicipalOffices,
      actions: <Widget>[
        if (!search)
          HeaderIconButton(
            key: const Key('directory-bell'),
            icon: TaytayIcons.bell,
            semanticLabel: strings.dirNotifications,
            onPressed: onBell,
          ),
      ],
      bottom: offline || search
          ? null
          : HeaderSearchField(
              hint: strings.dirSearchHint,
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
        failure: c.failure,
        environment: c.environment,
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
    final AppStrings strings = AppStrings.of(context);
    return Semantics(
      container: true,
      label: strings.dirCategory,
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
                label: directoryChipLabel(strings, labels[i]),
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
    final String chip = chips.contains(selectedChip)
        ? selectedChip
        : Office.allChip;
    final List<Office> visible = offices
        .where((Office office) => office.matches(query, chip))
        .toList(growable: false);
    final String trimmed = query.trim();
    final AppStrings strings = AppStrings.of(context);
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
                      ? strings.dirNoOfficesInCategory
                      : strings.dirNoOfficesFound(trimmed),
                  message: strings.dirTryAnotherWord,
                  actionLabel: onBrowseAll == null
                      ? null
                      : strings.dirBrowseAll,
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
            TextSpan(
              text: ' ${AppStrings.of(context).dirOfficeCountNoun(count)}',
            ),
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
        _ChipsRow(labels: chips, selected: Office.allChip),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.section,
            Spacing.lg,
            0,
          ),
          child: SoftCard(
            child: LoadingSkeleton(
              count: 6,
              semanticLabel: AppStrings.of(context).dirLoadingDirectory,
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
  const _OfflineBody({
    required this.offices,
    required this.environment,
    this.onRetry,
    this.onCall,
    this.failure,
  });

  final List<Office> offices;
  final VoidCallback? onRetry;
  final VoidCallback? onCall;
  final AppFailure? failure;
  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final AppFailure? failure = this.failure;
    final bool offline = failure == null || FailureView.isOffline(failure);
    final AppStrings strings = AppStrings.of(context);
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
        if (offline) ...<Widget>[
          const _OfflineStrip(),
          const SizedBox(height: Spacing.section),
          EmptyState(
            title: strings.dirCantLoadTitle,
            message: strings.dirCantLoadBody,
            illustration: TaytayIllustration.offline,
            actionLabel: strings.actionTryAgain,
            actionIcon: TaytayIcons.refreshCw,
            onAction: onRetry,
            primaryAction: true,
            boxed: true,
            actionKey: const Key('directory-retry'),
          ),
        ] else
          FailureView(
            failure: failure,
            environment: environment,
            onRetry: onRetry,
            boxed: true,
          ),
        if (saved.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.xl),
          SettingsSectionTitle(strings.dirSavedOnPhone),
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
    final AppStrings strings = AppStrings.of(context);
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
                      strings.dirOfflineTitle,
                      style: AppTypography.listTitle.copyWith(
                        fontWeight: AppTypography.strong,
                        color: BrandColors.goldInk,
                      ),
                    ),
                    Text(
                      strings.dirOfflineShowingSaved,
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
        label: AppStrings.of(context).dirCallName(title),
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
    return HeaderSearchField(
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
    final AppStrings strings = AppStrings.of(context);
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
                    ? strings.dirRepresentativePhotoCredit(credit)
                    : strings.dirRepresentativePhoto,
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
    final AppStrings strings = AppStrings.of(context);
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
                  label: officeCallLabel(strings, office),
                  glyph: TaytayGlyph.phone,
                  primary: true,
                  danger: office.callIsEmergency,
                  onPressed: onCall,
                ),
                PillAction(
                  buttonKey: const Key('directory-directions'),
                  label: strings.dirActionDirections,
                  glyph: TaytayGlyph.pin,
                  onPressed: onDirections,
                ),
                PillAction(
                  buttonKey: const Key('directory-message'),
                  label: office.messageable
                      ? strings.dirActionMessage
                      : strings.dirActionApp,
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
                    officeFactLabel(AppStrings.of(context), fact),
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
        SettingsSectionTitle(AppStrings.of(context).dirServices),
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
    final AppStrings strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BlueHeader(
          title: strings.dirNewMessage,
          subtitle: 'Bayan ng Taytay · Rizal',
          showBack: true,
          onBack: canvas.onBack,
          actions: const <Widget>[HeaderSeal()],
        ),
        Expanded(
          child: office == null && canvas.officeUnavailable
              // The office read answered with nothing: say so, with Try
              // again, never a skeleton that stays (DESIGN_SYSTEM.md §5).
              ? ListView(
                  padding: const EdgeInsets.all(Spacing.lg),
                  children: <Widget>[
                    ErrorState(
                      title: strings.dirOfficeDidNotLoadTitle,
                      message: strings.dirOfficeDidNotLoadBody,
                      onRetry: canvas.onRetry,
                      boxed: true,
                    ),
                  ],
                )
              : office == null
              ? Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: LoadingSkeleton(
                    layout: SkeletonLayout.detail,
                    semanticLabel: strings.dirLoadingOffice,
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
                    AuthFieldLabel(strings.dirTopic),
                    const SizedBox(height: Spacing.sm),
                    _TopicField(
                      topic: canvas.selectedTopic ?? office.topic ?? '',
                      chooser: office.offersTopics,
                      onTap: canvas.onTopic,
                    ),
                    const SizedBox(height: Spacing.formGap),
                    AuthFieldLabel(strings.dirFieldMessage),
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
                      decoration: InputDecoration(
                        hintText: strings.dirMessageHint,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    _AttachButton(
                      onAttach: canvas.onAttach,
                      label: canvas.attachmentLabel,
                    ),
                    const SizedBox(height: Spacing.md),
                    SoftNote(message: _privacyLine(strings, office)),
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
                    label: Text(strings.dirSendMessage),
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
  static String _privacyLine(AppStrings strings, Office office) {
    final String own = (office.privacy ?? '').trim();
    final String warning = strings.dirPrivacyWarning;
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
                  AppStrings.of(context).dirTo,
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
    final AppStrings strings = AppStrings.of(context);
    final String shown = directoryTopicLabel(strings, topic);
    return Semantics(
      button: onTap != null,
      label: shown.isEmpty ? strings.dirTopic : strings.dirTopicValue(shown),
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
                      shown,
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
          label: Text(AppStrings.of(context).dirAttach),
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

/// The note's call button for the command center.
const Key messageSentCallKey = Key('message-sent-call');

/// One hotline the emergency note may name: the office marked it as the
/// command center (`kind`), and it is active.
typedef EmergencyLine = ({String name, String number});

/// What the sent page's emergency note says: the mock-up's bold title, then
/// the sentence. With no command center marked it names no number and no line
/// (D-196); with one, its name and number (D-214). The hotlines button stays
/// either way.
///
/// The English words, kept for tests and as the no-context fallback. The page
/// draws the same sentences from [AppStrings] (`dirEmergency…`).
abstract final class MessageSentCopy {
  static const String emergencyHeading =
      "For emergencies don't wait for a reply";
  static const String emergency = 'Call an emergency hotline.';
  static const String hotlinesButton = 'See emergency hotlines';

  /// The sentence when the office marked a command center.
  static String callLine(EmergencyLine line) =>
      'Call ${line.name}: ${line.number}.';

  /// The call button's words.
  static String callButton(EmergencyLine line) => 'Call ${line.name}';

  /// Announced while the hotlines load.
  static const String loading = 'Loading the emergency hotline';
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
    final EmergencyLine? line = canvas.commandCenter;
    final VoidCallback? onCall = canvas.onCallCommandCenter;
    final AppStrings strings = AppStrings.of(context);
    final List<PillAction> actions = <PillAction>[
      if (line != null && onCall != null)
        PillAction(
          label: strings.dirCallName(line.name),
          glyph: TaytayGlyph.phone,
          primary: true,
          danger: true,
          buttonKey: messageSentCallKey,
          onPressed: onCall,
        ),
      if (onHotlines != null)
        PillAction(
          label: strings.dirSeeHotlines,
          glyph: TaytayGlyph.phone,
          danger: true,
          buttonKey: messageSentHotlinesKey,
          onPressed: onHotlines,
        ),
    ];
    final Widget? pills = actions.isEmpty
        ? null
        // The design system's pill (`PillButtonRow`, the danger tone): a
        // 40 px pill in a 48 dp target, wrapping at 200%.
        : PillButtonRow(wrap: true, padding: EdgeInsets.zero, actions: actions);
    return SuccessScreen(
      title: strings.dirMessageSentTitle,
      message: strings.dirMessageSentBody,
      details: <SuccessDetail>[
        if (office != null)
          SuccessDetail(label: strings.dirTo, value: office.shortName),
      ],
      // Never the messaged office's line: it is not an emergency line. A
      // number only when the office marked a command center (D-214).
      body: SoftNote(
        key: messageSentEmergencyNoteKey,
        tone: NoteTone.emergency,
        heading: strings.dirEmergencyHeading,
        message: line == null
            ? strings.dirEmergencyBody
            : strings.dirEmergencyCallLine(line.name, line.number),
        // Part of the page, not news: read in order, not announced over the
        // page's own title.
        live: false,
        action: canvas.commandCenterLoading
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LoadingSkeleton(
                    layout: SkeletonLayout.text,
                    count: 1,
                    semanticLabel: strings.dirLoadingHotline,
                  ),
                  if (pills != null) ...<Widget>[
                    const SizedBox(height: Spacing.sm),
                    pills,
                  ],
                ],
              )
            : pills,
      ),
      primaryLabel: strings.dirGoToMessages,
      onPrimary: canvas.onMessages,
      secondaryLabel: strings.dirBackToDirectory,
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
            label: AppStrings.of(context).dirConversation,
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
