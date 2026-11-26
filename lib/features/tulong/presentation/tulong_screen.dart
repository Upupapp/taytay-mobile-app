import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/session_state.dart';
import '../../../l10n/app_localizations.dart';
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

class _TulongScreenState extends State<TulongScreen>
    with LiveRefresh<TulongScreen> {
  final TextEditingController _search = TextEditingController();
  List<SocialService> _services = const <SocialService>[];
  List<SocialService> _saved = const <SocialService>[];
  bool _loading = true;
  bool _failed = false;
  bool _started = false;
  String _query = '';

  /// Why the list could not be read, when no list is on screen.
  AppFailure? _failure;

  /// A read is on its way. A second one is not started beside it: a Try
  /// again tapped twice sends one read (D-221).
  bool _reading = false;

  /// A Try again under the stale note is on its way (D-221).
  bool _retryingStale = false;

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
    // The office's edits to the programmes show without a pull (D-218,
    // D-221). The search box and what was typed in it are left alone.
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.services,
    }, () => unawaited(_load(quiet: true)));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  SocialServiceRepository get _repository =>
      AppDependencies.of(context).socialServiceRepository;

  /// Try again: the skeleton while no list is on screen, or a busy button
  /// under the stale note while one is, so the tap is seen to do something
  /// and cannot send a second read (D-221).
  void _retry() {
    if (_reading) return;
    setState(() {
      if (_services.isEmpty) {
        _loading = true;
        _failed = false;
        _failure = null;
      } else {
        _retryingStale = true;
      }
    });
    unawaited(_load());
  }

  /// Reads the whole catalogue. The search term is not part of the read: it
  /// filters on the phone (D-59), so typing sends nothing.
  ///
  /// [quiet] is a re-read for a change (D-218): no loading state, and a read
  /// that fails keeps what is on screen and says nothing. It waits for a
  /// first list, not for a non-empty one: a list the office emptied by
  /// archiving its last programme still hears the next one (D-222).
  Future<void> _load({bool quiet = false}) async {
    if (_reading || (quiet && _loadedAt == null)) return;
    _reading = true;
    final Result<ServiceCatalogue> result = await _repository.readCatalogue();
    if (!mounted) {
      _reading = false;
      return;
    }
    switch (result) {
      case Ok<ServiceCatalogue>(:final value):
        _reading = false;
        setState(() {
          _services = value.services;
          _complete = value.complete;
          _loadedAt = DateTime.now();
          _loading = false;
          _failed = false;
          _failure = null;
          _stale = false;
          _retryingStale = false;
        });
      case Err<ServiceCatalogue>(:final failure):
        if (quiet) {
          _reading = false;
          return;
        }
        final List<SocialService> saved = await _repository.savedOnThisPhone();
        _reading = false;
        if (!mounted) return;
        setState(() {
          _saved = saved;
          _loading = false;
          _failed = _services.isEmpty;
          _failure = failure;
          _stale = _services.isNotEmpty;
          _retryingStale = false;
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
    final AppStrings strings = AppStrings.of(context);
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
              ? strings.tulongSubtitle
              : strings.tulongSubtitleMswdo,
          emptyMessage:
              !_loading && !_failed && visible.isEmpty && _query.isNotEmpty
              ? strings.tulongNoMatchTitle
              : null,
          staleSince: _stale ? _loadedAt : null,
          partialCatalogueCount: _complete ? null : _services.length,
          searchController: _search,
          onSearch: _onSearch,
          onOpen: _open,
          onRetry: _retry,
          retrying: _retryingStale,
          failure: _failure,
          environment: AppDependencies.of(context).config.environment,
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
