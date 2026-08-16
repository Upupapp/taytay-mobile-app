import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../domain/event_repository.dart';

/// Loads and pages one scope of the events list.
///
/// ---
///
/// ## What this class guarantees
///
/// * **Only resident-visible events reach the screen.** Filtering happens once,
///   here, so no card can render an event the office marked as a draft or an
///   archived entry. See `LguEvent.isResidentVisible`.
/// * **A page failure never discards the pages already read.**
/// * **The end of the list is the server's answer**, never inferred from a short
///   page — a page can be short because entries on it were filtered out here.
/// * **Nothing is re-sorted.** The office decides the order events appear in.
class EventsController extends ChangeNotifier {
  EventsController({required EventRepository repository})
    : _repository = repository;

  final EventRepository _repository;

  EventScope _scope = EventScope.upcoming;
  final List<LguEvent> _items = <LguEvent>[];
  int _page = 0;
  bool _hasMore = true;
  bool _loadingFirstPage = true;
  bool _loadingMore = false;
  AppFailure? _failure;
  AppFailure? _pageFailure;

  EventScope get scope => _scope;
  List<LguEvent> get items => List<LguEvent>.unmodifiable(_items);

  bool get isLoadingFirstPage => _loadingFirstPage;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  AppFailure? get failure => _failure;
  AppFailure? get pageFailure => _pageFailure;

  /// True when the list is empty **and nothing went wrong** — the only state in
  /// which "there is nothing here" is a statement rather than a guess.
  bool get isEmptyAndHealthy => _items.isEmpty && _failure == null;

  /// Switches scope and reloads. A no-op when the scope is unchanged, so a
  /// resident tapping the segment they are already on does not refetch.
  Future<void> changeScope(EventScope scope) async {
    if (scope == _scope) return;
    _scope = scope;
    await refresh();
  }

  /// Loads the first page of the current scope, discarding anything held.
  Future<void> refresh() async {
    _items.clear();
    _page = 0;
    _hasMore = true;
    _failure = null;
    _pageFailure = null;
    _loadingFirstPage = true;
    notifyListeners();

    await _fetch(isFirstPage: true);
  }

  Future<void> loadMore() async {
    if (_loadingMore || _loadingFirstPage || !_hasMore) return;
    _loadingMore = true;
    _pageFailure = null;
    notifyListeners();

    await _fetch(isFirstPage: false);
  }

  Future<void> retryPage() async {
    if (_loadingMore) return;
    await loadMore();
  }

  Future<void> _fetch({required bool isFirstPage}) async {
    final next = _page + 1;
    final result = await _repository.listEvents(scope: _scope, page: next);

    result.fold(
      onOk: (page) {
        _page = next;
        // The one place the visibility rule is applied.
        _items.addAll(page.items.where((event) => event.isResidentVisible));
        _hasMore = page.hasMore;
        _failure = null;
        _pageFailure = null;
      },
      onErr: (failure) {
        if (isFirstPage) {
          _failure = failure;
        } else {
          _pageFailure = failure;
        }
      },
    );

    _loadingFirstPage = false;
    _loadingMore = false;
    notifyListeners();
  }
}
