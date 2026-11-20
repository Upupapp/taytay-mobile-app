import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/paginated.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../domain/own_assistance_repository.dart';
import '../domain/own_assistance_request.dart';
import 'my_requests_canvas.dart';

/// My requests: the resident's own filed assistance requests, newest filing
/// first, a page at a time (D-223, backend `d1e997c`).
///
/// Registered or verified; the server decides that again on every read.
/// Nothing is cached: a request is personal data, fetched by the screen that
/// shows it (Article 5.1).
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with LiveRefresh<MyRequestsScreen> {
  bool _started = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _moreFailed = false;
  AppFailure? _failure;
  List<OwnAssistanceRequest>? _items;
  String? _next;

  /// Pages read since the last full load. A quiet re-read refreshes the
  /// first and keeps the rest.
  int _pages = 0;

  /// `linked_to_office_record` from `GET /me`; null until it answers, and
  /// when it does not say (D-226).
  bool? _linked;

  OwnAssistanceRepository get _repository =>
      AppDependencies.of(context).ownAssistanceRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_load());
    // A move the resident is told of raises her own `notifications` topic;
    // the API has no topic for these requests (ADR 0003 C). Moves she is not
    // told of show on the next read, on return to the app or a reconnect.
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.notifications,
    }, () => unawaited(_loadQuietly()));
    unawaited(_loadLink());
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.account,
    }, () => unawaited(_loadLink()));
  }

  /// Whether the MSWDO has linked the account, said under an empty list.
  /// Quiet: a failed read leaves the page as it was.
  Future<void> _loadLink() async {
    final Result<ResidentProfileDetail> me = await AppDependencies.of(
      context,
    ).residentProfileRepository.loadOwnDetail();
    if (!mounted) return;
    if (me case Ok(:final ResidentProfileDetail value)) {
      setState(() => _linked = value.linkedToOfficeRecord);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
      _moreFailed = false;
    });
    final Result<Paginated<OwnAssistanceRequest>> result = await _repository
        .listOwn();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _items = List<OwnAssistanceRequest>.of(value.items);
          _next = _cursorOf(value);
          _pages = 1;
        case Err(:final failure):
          // A failed Try again leaves no stale list under the failure.
          _items = null;
          _failure = failure;
      }
    });
  }

  /// Re-reads the first page for a change (D-218): no loading state, the
  /// requests paged in below it stay, and a failure keeps the list as it is
  /// and says nothing.
  Future<void> _loadQuietly() async {
    if (_loading || _loadingMore) return;
    final Result<Paginated<OwnAssistanceRequest>> result = await _repository
        .listOwn();
    if (!mounted || _loading || _loadingMore) return;
    if (result case Ok(:final value)) {
      setState(() {
        final List<OwnAssistanceRequest> shown =
            _items ?? const <OwnAssistanceRequest>[];
        if (_pages <= 1) {
          _items = List<OwnAssistanceRequest>.of(value.items);
          _next = _cursorOf(value);
          _pages = 1;
        } else {
          final Set<String> seen = <String>{
            for (final OwnAssistanceRequest item in value.items) item.id,
          };
          _items = <OwnAssistanceRequest>[
            ...value.items,
            for (final OwnAssistanceRequest item in shown)
              if (seen.add(item.id)) item,
          ];
        }
        _failure = null;
      });
    }
  }

  Future<void> _more() async {
    final String? cursor = _next;
    if (cursor == null || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    final Result<Paginated<OwnAssistanceRequest>> result = await _repository
        .listOwn(cursor: cursor);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      switch (result) {
        case Ok(:final value):
          final Set<String> seen = <String>{
            for (final OwnAssistanceRequest item
                in _items ?? const <OwnAssistanceRequest>[])
              item.id,
          };
          _items = <OwnAssistanceRequest>[
            ...?_items,
            for (final OwnAssistanceRequest item in value.items)
              if (seen.add(item.id)) item,
          ];
          _next = _cursorOf(value);
          _pages++;
        case Err():
          _moreFailed = true;
      }
    });
  }

  static String? _cursorOf(Paginated<OwnAssistanceRequest> page) {
    final String? next = page.nextCursor;
    return page.hasMore && next != null && next.isNotEmpty ? next : null;
  }

  void _open(OwnAssistanceRequest request) {
    unawaited(
      context.pushNamed<void>(
        AppRoute.myRequestDetail.routeName,
        pathParameters: <String, String>{'requestId': request.id},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyRequestsCanvas(
      environment: AppDependencies.of(context).config.environment,
      items: _items,
      failure: _failure,
      loading: _loading,
      hasMore: _next != null,
      loadingMore: _loadingMore,
      moreFailed: _moreFailed,
      onRetry: _loading ? null : () => unawaited(_load()),
      onMore: () => unawaited(_more()),
      onOpen: _open,
      accountLinked: _linked,
    );
  }
}
