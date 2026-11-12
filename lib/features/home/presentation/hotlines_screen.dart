import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../../citizen_api/domain/citizen_contract.dart';
import '../data/home_catalogue.dart';
import '../domain/home_content.dart';

/// Emergency hotlines from `GET /hotlines`, then `GET /home`.
///
/// A dev mock uses the catalogue when both are empty. Call uses `tel:`.
/// A phone with no dialer gets a toast and stays on this screen.
class HotlinesScreen extends StatefulWidget {
  const HotlinesScreen({super.key});

  @override
  State<HotlinesScreen> createState() => _HotlinesScreenState();
}

class _HotlinesScreenState extends State<HotlinesScreen> {
  bool _started = false;
  bool _loaded = false;
  List<HomeHotline> _lines = const <HomeHotline>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final AppDependencies dependencies = AppDependencies.of(context);
    final Result<List<MunicipalHotline>> listed = await dependencies.citizenApi
        .listHotlines();
    List<MunicipalHotline> rows = listed.fold(
      onOk: (List<MunicipalHotline> value) => value,
      onErr: (_) => const <MunicipalHotline>[],
    );
    if (rows.isEmpty) {
      final Result<HomeFeed> home = await dependencies.citizenApi.loadHome();
      rows = home.fold(
        onOk: (HomeFeed feed) => feed.hotlines,
        onErr: (_) => const <MunicipalHotline>[],
      );
    }
    final List<HomeHotline> mapped = <HomeHotline>[
      for (final MunicipalHotline row in rows)
        if (row.active)
          HomeHotline(
            id: row.id,
            name: row.name,
            number: row.number,
            category: row.category,
            kind: row.kind,
          ),
    ];
    List<HomeHotline> resolved = mapped;
    if (resolved.isEmpty && dependencies.config.usesMockData) {
      resolved = (await HomeCatalogue.mockFeed()).hotlines;
    }
    if (!mounted) return;
    setState(() {
      _lines = resolved;
      _loaded = true;
    });
  }

  Future<void> _dial(String number) async {
    final LinkOutcome outcome = await AppDependencies.of(
      context,
    ).externalLinks.dial(number);
    if (!mounted) return;
    if (outcome == LinkOutcome.unavailable) {
      Outcome.problem(context, 'This phone has no app that can place a call.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HotlinesCanvas(
      lines: _lines,
      loading: !_loaded,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed(AppRoute.home.routeName);
        }
      },
      onCall: _dial,
    );
  }
}

/// The hotlines page from `04-04`, without the tab bar.
///
/// The shell paints the bar. A capture composes this canvas and the bar.
class HotlinesCanvas extends StatelessWidget {
  const HotlinesCanvas({
    required this.lines,
    this.loading = false,
    this.onBack,
    this.onCall,
    super.key,
  });

  final List<HomeHotline> lines;

  /// True until the first read answers. The list draws a skeleton meanwhile.
  final bool loading;
  final VoidCallback? onBack;
  final Future<void> Function(String number)? onCall;

  @override
  Widget build(BuildContext context) {
    final List<HomeHotline> municipal = lines
        .where((HomeHotline line) => !line.isBarangay)
        .toList(growable: false);
    final List<HomeHotline> barangay = lines
        .where((HomeHotline line) => line.isBarangay)
        .toList(growable: false);
    return Material(
      color: BrandColors.background,
      child: Column(
        children: <Widget>[
          BlueHeader(
            title: 'Emergency hotlines',
            subtitle: 'Bayan ng Taytay · Rizal',
            showBack: true,
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.xl,
              ),
              children: <Widget>[
                if (loading)
                  const LoadingSkeleton(semanticLabel: 'Loading hotlines')
                else if (lines.isEmpty)
                  const EmptyState(
                    title: 'No hotlines to show',
                    message:
                        'Taytay LGU has not published any hotlines here yet.',
                    boxed: true,
                  ),
                if (municipal.isNotEmpty) ...<Widget>[
                  const _Heading('Municipal', first: true),
                  _Group(
                    lines: municipal,
                    onCall: (String number) => onCall?.call(number),
                  ),
                ],
                if (barangay.isNotEmpty) ...<Widget>[
                  _Heading('Barangay', first: municipal.isEmpty),
                  _Group(
                    lines: barangay,
                    onCall: (String number) => onCall?.call(number),
                  ),
                ],
                const SizedBox(height: Spacing.md),
                Text(
                  'Source: Taytay LGU / Taytay Public Information Office.',
                  style: AppTypography.tiny.copyWith(
                    fontWeight: AppTypography.medium,
                    color: BrandColors.muted,
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

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.xxs,
        first ? 0 : Spacing.lg,
        Spacing.xxs,
        Spacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: AppTypography.sectionTitle.copyWith(
            fontWeight: AppTypography.strong,
            color: BrandColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.lines, required this.onCall});

  final List<HomeHotline> lines;
  final void Function(String number) onCall;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < lines.length; i++)
            _Line(
              line: lines[i],
              divider: i > 0,
              onCall: () => onCall(lines[i].number),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.line,
    required this.divider,
    required this.onCall,
  });

  final HomeHotline line;
  final bool divider;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    // The red siren is the line's `kind`, set by the office: emergency,
    // command center, police, fire, medical or disaster. Never its name, and
    // never its free-text category: renaming a line must not change what it
    // is said to be for (D-196, D-214).
    final bool emergency = line.kind.isEmergency;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? const Border(top: BorderSide(color: BrandColors.divider))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Row(
          children: <Widget>[
            IconTile.glyph(
              glyph: emergency ? TaytayGlyph.siren : TaytayGlyph.phone,
              tone: emergency ? TileTone.red : TileTone.blue,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    line.name,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    line.number,
                    style: AppTypography.listDetail.copyWith(
                      color: BrandColors.muted,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Call ${line.name}',
              excludeSemantics: true,
              child: GestureDetector(
                key: Key('hotline-call-${line.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: onCall,
                child: SizedBox.square(
                  dimension: A11y.minTapTarget,
                  child: Center(
                    child: Container(
                      width: ComponentSizes.headerIconButton,
                      height: ComponentSizes.headerIconButton,
                      decoration: const BoxDecoration(
                        color: BrandColors.blue50,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: TaytayIcon(
                          icon: TaytayIcons.phone,
                          semanticLabel: '',
                          excludeSemantics: true,
                          size: IconSizes.sm,
                          color: BrandColors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
