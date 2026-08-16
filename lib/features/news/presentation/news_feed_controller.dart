import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../domain/announcement_repository.dart';

/// Loads and pages the resident newsfeed.
///
/// ---
///
/// ## What this class guarantees
///
/// * **Only resident-visible posts reach the screen.** Filtering happens once,
///   here, so no card can render a post the server marked as a draft or an
///   archived advisory. See `Announcement.isResidentVisible`.
/// * **Pinned posts are surfaced without being re-sorted.** The office decides
///   the order; the app only lifts what the office pinned to the top of the
///   first page, and it does so **stably** — two pinned posts stay in the order
///   they were published in.
/// * **A page failure never discards the pages already read.** Losing signal at
///   post forty must not empty the screen a resident was reading.
/// * **The end of the feed is a fact from the server**, not an inference from a
///   short page. A page smaller than `perPage` is not proof there is no more.
class NewsFeedController extends ChangeNotifier {
  NewsFeedController({required AnnouncementRepository repository})
    : _repository = repository;

  final AnnouncementRepository _repository;

  final List<Announcement> _items = <Announcement>[];
  int _page = 0;
  bool _hasMore = true;
  bool _loadingFirstPage = true;
  bool _loadingMore = false;

  /// Failure that left the screen with nothing to show.
  AppFailure? _failure;

  /// Failure while extending a feed that already has content.
  AppFailure? _pageFailure;

  /// Posts to render: pinned first, then the rest, each in server order.
  List<Announcement> get items => <Announcement>[
    ..._items.where((post) => post.isPinned),
    ..._items.where((post) => !post.isPinned),
  ];

  bool get isLoadingFirstPage => _loadingFirstPage;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;

  AppFailure? get failure => _failure;
  AppFailure? get pageFailure => _pageFailure;

  bool get isEmpty => _items.isEmpty;

  /// True when the feed is empty **and nothing went wrong** — the only state in
  /// which "there is nothing to show" is a true statement rather than a guess.
  bool get isEmptyAndHealthy => _items.isEmpty && _failure == null;

  /// Loads the first page, discarding anything already held.
  ///
  /// This is pull-to-refresh as well as the initial load: a resident pulling
  /// down is asking for the current state of the feed, not for more of the old
  /// one.
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

  /// Loads the next page, keeping what is already on screen.
  Future<void> loadMore() async {
    if (_loadingMore || _loadingFirstPage || !_hasMore) return;
    _loadingMore = true;
    _pageFailure = null;
    notifyListeners();

    await _fetch(isFirstPage: false);
  }

  /// Retries only the page that failed.
  Future<void> retryPage() async {
    if (_loadingMore) return;
    await loadMore();
  }

  Future<void> _fetch({required bool isFirstPage}) async {
    final next = _page + 1;
    final result = await _repository.listAnnouncements(page: next);

    result.fold(
      onOk: (page) {
        _page = next;
        // The one place the visibility rule is applied.
        _items.addAll(page.items.where((post) => post.isResidentVisible));
        // The server's own answer. A short page is not proof of the end — a
        // page can be short because posts on it were filtered out here.
        _hasMore = page.hasMore;
        _failure = null;
        _pageFailure = null;
      },
      onErr: (failure) {
        if (isFirstPage) {
          _failure = failure;
        } else {
          // Keep what the resident was reading.
          _pageFailure = failure;
        }
      },
    );

    _loadingFirstPage = false;
    _loadingMore = false;
    notifyListeners();
  }
}
