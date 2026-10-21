import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/links/external_link_service.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/taytay_icon.dart';
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
          ),
    ];
    List<HomeHotline> resolved = mapped;
    if (resolved.isEmpty && dependencies.config.usesMockData) {
      resolved = (await HomeCatalogue.mockFeed()).hotlines;
    }
    if (!mounted) return;
    setState(() => _lines = resolved);
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
    this.onBack,
    this.onCall,
    super.key,
  });

  final List<HomeHotline> lines;
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
    return ColoredBox(
      color: BrandColors.surface,
      child: Column(
        children: <Widget>[
          MunicipalHeader(
            title: 'Emergency hotlines',
            subtitle: 'Bayan ng Taytay · Rizal',
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                if (municipal.isNotEmpty) ...<Widget>[
                  const _Heading('Municipal', first: true),
                  _Group(
                    lines: municipal,
                    onCall: (String number) => onCall?.call(number),
                  ),
                ],
                if (barangay.isNotEmpty) ...<Widget>[
                  const _Heading('Barangay'),
                  _Group(
                    lines: barangay,
                    onCall: (String number) => onCall?.call(number),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Source: Taytay LGU / Taytay Public Information Office.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: BrandColors.listMeta,
                    decoration: TextDecoration.none,
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
      padding: EdgeInsets.only(top: first ? 4 : 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: BrandColors.textPrimary,
          decoration: TextDecoration.none,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.cardLine),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < lines.length; i++)
            _Line(
              line: lines[i],
              border: i < lines.length - 1,
              onCall: () => onCall(lines[i].number),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, required this.border, required this.onCall});

  final HomeHotline line;
  final bool border;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final bool emergency = !line.isBarangay && line.name != 'Taytay PNP';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.35),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: border
              ? const Border(bottom: BorderSide(color: Color(0xFFEEF1F6)))
              : null,
        ),
        child: Row(
          children: <Widget>[
            _Tile(
              background: emergency
                  ? const Color(0xFFFDECEC)
                  : BrandColors.surfaceMuted,
              icon: emergency ? TaytayIcons.siren : TaytayIcons.phone,
              color: emergency ? BrandColors.danger : BrandColors.taytayBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    line.name,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line.number,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BrandColors.listMeta,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 36,
              height: 36,
              child: OverflowBox(
                minWidth: 48,
                maxWidth: 48,
                minHeight: 48,
                maxHeight: 48,
                child: Semantics(
                  button: true,
                  label: 'Call ${line.name}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onCall,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: BrandColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: TaytayIcon(
                            icon: TaytayIcons.phone,
                            semanticLabel: '',
                            excludeSemantics: true,
                            size: 16,
                            color: BrandColors.taytayBlue,
                          ),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.background,
    required this.icon,
    required this.color,
  });

  final Color background;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: TaytayIcon(
          icon: icon,
          semanticLabel: '',
          excludeSemantics: true,
          size: 20,
          color: color,
        ),
      ),
    );
  }
}
