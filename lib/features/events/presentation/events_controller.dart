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

  /// Bumped by every read that changes the list, so a quiet re-read that
  /// started before it is dropped rather than applied over newer data.
  int _generation = 0;
  bool _quietInFlight = false;
  bool _disposed = false;

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
    _generation++;
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

  /// Re-reads what is loaded, with no loading state (D-218).
  ///
  /// Every page the resident has scrolled through is read again, in order,
  /// and the list is replaced only when all of them arrive: a partial re-read
  /// would shorten the list under the resident's thumb. A failure keeps what
  /// is on screen and says nothing. Skipped while another read is running;
  /// the change that asked for it is covered by that read.
  Future<void> refreshQuietly() async {
    if (_quietInFlight || _loadingFirstPage || _loadingMore) return;
    final int generation = _generation;
    final EventScope scope = _scope;
    final int pages = _page < 1 ? 1 : _page;
    final List<LguEvent> fresh = <LguEvent>[];
    var read = 0;
    var hasMore = true;
    _quietInFlight = true;
    try {
      while (read < pages && hasMore) {
        final result = await _repository.listEvents(
          scope: scope,
          page: read + 1,
        );
        if (_disposed || generation != _generation) return;
        switch (result) {
          case Ok(:final value):
            fresh.addAll(value.items.where((event) => event.isResidentVisible));
            hasMore = value.hasMore;
            read++;
          case Err():
            return;
        }
      }
    } finally {
      _quietInFlight = false;
    }
    _items
      ..clear()
      ..addAll(fresh);
    _page = read;
    _hasMore = hasMore;
    _failure = null;
    _pageFailure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _fetch({required bool isFirstPage}) async {
    final next = _page + 1;
    final result = await _repository.listEvents(scope: _scope, page: next);
    if (_disposed) return;
    _generation++;

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
