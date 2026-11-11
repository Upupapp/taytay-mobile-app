import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_state.dart';
import '../domain/service_search.dart';
import '../domain/social_service.dart';
import '../domain/social_service_repository.dart';
import 'tulong_canvas.dart';

/// Tulong — municipal social services, as information.
///
/// Public. A guest, an unverified resident, and a verified resident see the
/// same list. Nothing on this screen submits an application.
///
/// The search runs on the phone over the whole catalogue, and no request
/// carries what was typed (D-59, D-205).
class TulongScreen extends StatefulWidget {
  const TulongScreen({super.key});

  @override
  State<TulongScreen> createState() => _TulongScreenState();
}

class _TulongScreenState extends State<TulongScreen> {
  final TextEditingController _search = TextEditingController();
  List<SocialService> _services = const <SocialService>[];
  List<SocialService> _saved = const <SocialService>[];
  bool _loading = true;
  bool _failed = false;
  bool _started = false;
  String _query = '';

  /// False when the catalogue is longer than the app reads (D-205).
  bool _complete = true;

  /// When the list on screen was read. Set on every successful read.
  DateTime? _loadedAt;

  /// A refresh failed while a list was on screen: the list stays, labelled
  /// with [_loadedAt] (D-205, the offline pattern in DESIGN_SYSTEM.md §5).
  bool _stale = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  SocialServiceRepository get _repository =>
      AppDependencies.of(context).socialServiceRepository;

  /// Reads the whole catalogue. The search term is not part of the read: it
  /// filters on the phone (D-59), so typing sends nothing.
  Future<void> _load() async {
    final Result<ServiceCatalogue> result = await _repository.readCatalogue();
    if (!mounted) return;
    switch (result) {
      case Ok<ServiceCatalogue>(:final value):
        setState(() {
          _services = value.services;
          _complete = value.complete;
          _loadedAt = DateTime.now();
          _loading = false;
          _failed = false;
          _stale = false;
        });
      case Err<ServiceCatalogue>():
        final List<SocialService> saved = await _repository.savedOnThisPhone();
        if (!mounted) return;
        setState(() {
          _saved = saved;
          _loading = false;
          _failed = _services.isEmpty;
          _stale = _services.isNotEmpty;
        });
    }
  }

  void _onSearch(String value) {
    final String next = value.trim();
    if (next == _query) return;
    setState(() => _query = next);
  }

  void _open(SocialService service) {
    context.pushNamed(
      AppRoute.programDetail.routeName,
      pathParameters: <String, String>{'programId': service.slug},
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool guest =
        AppDependencies.of(context).session.state is! AuthenticatedSession;
    final List<SocialService> visible = searchServices(_services, _query);
    final TulongFrame frame = _failed
        ? TulongFrame.offline
        : _loading
        ? TulongFrame.loading
        : TulongFrame.list;
    return Scaffold(
      backgroundColor: BrandColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        child: TulongCanvas(
          frame: frame,
          services: visible,
          saved: _saved,
          offlineSubtitle: _failed
              ? 'Social services & programmes'
              : 'Social services · MSWDO',
          emptyMessage:
              !_loading && !_failed && visible.isEmpty && _query.isNotEmpty
              ? 'No programmes match that search.'
              : null,
          staleSince: _stale ? _loadedAt : null,
          partialCatalogueCount: _complete ? null : _services.length,
          searchController: _search,
          onSearch: _onSearch,
          onOpen: _open,
          onRetry: _load,
          onBell: () => context.goNamed(
            guest
                ? AppRoute.signIn.routeName
                : AppRoute.notifications.routeName,
          ),
        ),
      ),
    );
  }
}
