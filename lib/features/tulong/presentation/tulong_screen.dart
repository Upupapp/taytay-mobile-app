import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_state.dart';
import '../domain/social_service.dart';
import '../domain/social_service_repository.dart';
import 'tulong_canvas.dart';

/// Tulong — municipal social services, as information.
///
/// Public. A guest, an unverified resident, and a verified resident see the
/// same list. Nothing on this screen submits an application.
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

  Future<void> _load() async {
    final Result<Paginated<SocialService>> result = await _repository
        .listServices(query: _query);
    if (!mounted) return;
    switch (result) {
      case Ok<Paginated<SocialService>>(:final value):
        setState(() {
          _services = value.items;
          _loading = false;
          _failed = false;
        });
      case Err<Paginated<SocialService>>():
        final List<SocialService> saved = await _repository.savedOnThisPhone();
        if (!mounted) return;
        setState(() {
          _saved = saved;
          _loading = false;
          _failed = _services.isEmpty;
        });
    }
  }

  void _onSearch(String value) {
    final String next = value.trim();
    if (next == _query) {
      setState(() {});
      return;
    }
    setState(() => _query = next);
    _load();
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
    final List<SocialService> visible = _filter(_services, _query);
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

List<SocialService> _filter(List<SocialService> services, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return services;
  return <SocialService>[
    for (final SocialService service in services)
      if ('${service.listTitle} ${service.name} ${service.summary}'
          .toLowerCase()
          .contains(q))
        service,
  ];
}
