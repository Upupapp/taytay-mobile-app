import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../domain/resident_sector.dart';
import '../domain/sector_repository.dart';
import 'sectors_canvas.dart';

/// Sectors and benefits: the resident's own non-sensitive sectors and their
/// sector applications (D-215).
///
/// Both reads happen when the page opens and again when Apply for a sector
/// closes. Nothing is cached: a sector is personal data, fetched by the screen
/// that shows it (Article 5.1). The route admits verified residents only; the
/// server decides that again on every read.
class SectorsScreen extends StatefulWidget {
  const SectorsScreen({super.key});

  @override
  State<SectorsScreen> createState() => _SectorsScreenState();
}

class _SectorsScreenState extends State<SectorsScreen> {
  bool _started = false;
  bool _loading = false;
  SectorOverview? _overview;
  AppFailure? _failure;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final SectorRepository repository = AppDependencies.of(
      context,
    ).sectorRepository;
    setState(() {
      _loading = true;
      _failure = null;
    });
    final Result<List<OwnSector>> own = await repository.listOwn();
    if (!mounted) return;
    final Result<List<SectorApplication>> applications = await repository
        .listApplications();
    if (!mounted) return;
    setState(() {
      _loading = false;
      // Both or neither: half a list reads as "nothing else is on file".
      switch ((own, applications)) {
        case (Ok(value: final recorded), Ok(value: final sent)):
          _overview = SectorOverview(recorded: recorded, applications: sent);
          _failure = null;
        case (Err(:final failure), _) || (_, Err(:final failure)):
          _overview = null;
          _failure = failure;
      }
    });
  }

  Future<void> _apply(ResidentSector sector) async {
    await context.pushNamed<void>(
      AppRoute.sectorApply.routeName,
      // Not in the URL: which sector a resident is applying for is theirs.
      extra: sector,
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependencies.of(context);
    return SectorsCanvas(
      today: dependencies.clock(),
      environment: dependencies.config.environment,
      overview: _overview,
      failure: _failure,
      loading: _loading,
      onRetry: _load,
      onApply: _apply,
    );
  }
}
