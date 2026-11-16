import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../domain/own_assistance_request.dart';
import 'my_requests_canvas.dart';

/// One of the resident's own assistance requests (D-223), opened from My
/// requests or from an `assistance_request_updated` notice.
///
/// The API has no route for one request, so it is found in her list. A
/// request the list does not carry is said as not shown here, the same way
/// whatever the reason.
class MyRequestDetailScreen extends StatefulWidget {
  const MyRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  State<MyRequestDetailScreen> createState() => _MyRequestDetailScreenState();
}

class _MyRequestDetailScreenState extends State<MyRequestDetailScreen>
    with LiveRefresh<MyRequestDetailScreen> {
  bool _started = false;
  bool _loading = true;
  OwnAssistanceRequest? _request;
  AppFailure? _failure;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_load());
    // The notice that a request moved raises her `notifications` topic
    // (ADR 0003 C): the request open here re-reads then.
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.notifications,
    }, () => unawaited(_loadQuietly()));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final Result<OwnAssistanceRequest> result = await AppDependencies.of(
      context,
    ).ownAssistanceRepository.findOwn(widget.requestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _request = value;
        case Err(:final failure):
          _request = null;
          _failure = failure;
      }
    });
  }

  /// A quiet re-read (D-218): the request is replaced when it reads, and on
  /// any failure what is on screen stays.
  Future<void> _loadQuietly() async {
    if (_loading) return;
    final Result<OwnAssistanceRequest> result = await AppDependencies.of(
      context,
    ).ownAssistanceRepository.findOwn(widget.requestId);
    if (!mounted || _loading) return;
    if (result case Ok(:final value)) {
      setState(() {
        _request = value;
        _failure = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyRequestDetailCanvas(
      environment: AppDependencies.of(context).config.environment,
      request: _request,
      failure: _failure,
      loading: _loading,
      onRetry: _loading ? null : () => unawaited(_load()),
      onSeeAll: () => context.goNamed(AppRoute.myRequests.routeName),
    );
  }
}
