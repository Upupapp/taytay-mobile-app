import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../../../core/time/manila_time.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/notification_repository.dart';

/// How the inbox groups a message by when it arrived.
///
/// **Grouped by recency, not by date heading.** "Today" and "This week" are what
/// a resident is actually asking when they open an inbox; a run of date headers
/// makes them do the arithmetic themselves.
enum InboxGroup {
  today('Today'),
  thisWeek('Earlier this week'),
  thisMonth('Earlier this month'),
  older('Older'),
  undated('No date');

  const InboxGroup(this.label);

  /// The heading in the resident's language.
  ///
  /// An accessor rather than a function in `app_locales.dart` — the second of
  /// the two shapes `resident_copy_localisation_test.dart` accepts, and the one
  /// `ShellDestination` uses. It has to be this shape here: `InboxGroup` lives
  /// in a presentation file, and `core/l10n` importing `features/**/presentation`
  /// would be a layering violation that only `app_router.dart` is allowed.
  String labelIn(AppStrings strings) => switch (this) {
    InboxGroup.today => strings.inboxGroupToday,
    InboxGroup.thisWeek => strings.inboxGroupThisWeek,
    InboxGroup.thisMonth => strings.inboxGroupThisMonth,
    InboxGroup.older => strings.inboxGroupOlder,
    InboxGroup.undated => strings.inboxGroupUndated,
  };

  final String label;

  /// Which group [sentAt] belongs to, in Manila days.
  ///
  /// Compared in **Manila** wall time rather than the device's: a message sent
  /// at 9 AM in Taytay should read as "today" for a resident whose phone is set
  /// to another timezone, not as yesterday.
  static InboxGroup of(DateTime? sentAt, {DateTime? now}) {
    if (sentAt == null) return InboxGroup.undated;

    final sent = ManilaTime.of(sentAt);
    final today = ManilaTime.of(now ?? DateTime.now());

    final sentDay = DateTime.utc(sent.year, sent.month, sent.day);
    final todayDay = DateTime.utc(today.year, today.month, today.day);
    final days = todayDay.difference(sentDay).inDays;

    if (days <= 0) return InboxGroup.today;
    if (days < 7) return InboxGroup.thisWeek;
    if (days < 31) return InboxGroup.thisMonth;
    return InboxGroup.older;
  }
}

/// One group of messages, ready to render.
@immutable
class InboxSection {
  const InboxSection({required this.group, required this.items});

  final InboxGroup group;
  final List<ResidentNotification> items;

  @override
  String toString() => 'InboxSection(${group.name}, ${items.length})';
}

/// Loads the inbox, groups it, and marks things read.
///
/// ---
///
/// ## What this class guarantees
///
/// * **Reading is optimistic and reconciles.** Tapping a message clears its
///   unread mark immediately — a badge that lingers after a tap reads as a
///   broken app — and the mark comes back if the server refuses.
/// * **The server's order is kept inside every group.** The office decides what
///   is most recent; the app only decides which heading a message sits under.
/// * **A page failure never discards what was already read.**
class NotificationInboxController extends ChangeNotifier {
  NotificationInboxController({
    required NotificationRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final NotificationRepository _repository;
  final DateTime Function() _clock;

  final List<ResidentNotification> _items = <ResidentNotification>[];
  int _page = 0;
  bool _hasMore = true;
  bool _loadingFirstPage = true;
  bool _loadingMore = false;
  AppFailure? _failure;
  AppFailure? _pageFailure;

  List<ResidentNotification> get items =>
      List<ResidentNotification>.unmodifiable(_items);

  bool get isLoadingFirstPage => _loadingFirstPage;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  AppFailure? get failure => _failure;
  AppFailure? get pageFailure => _pageFailure;

  bool get isEmptyAndHealthy => _items.isEmpty && _failure == null;

  int get unreadCount => _items.where((item) => item.isUnread).length;

  /// The inbox, grouped. Empty groups are omitted rather than shown as headings
  /// with nothing under them.
  List<InboxSection> get sections {
    final now = _clock();
    final buckets = <InboxGroup, List<ResidentNotification>>{};

    for (final item in _items) {
      final group = InboxGroup.of(item.sentAt, now: now);
      buckets.putIfAbsent(group, () => <ResidentNotification>[]).add(item);
    }

    return <InboxSection>[
      for (final group in InboxGroup.values)
        if (buckets[group]?.isNotEmpty ?? false)
          InboxSection(group: group, items: buckets[group]!),
    ];
  }

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

  Future<void> _fetch({required bool isFirstPage}) async {
    final next = _page + 1;
    final result = await _repository.listOwn(page: next);

    result.fold(
      onOk: (page) {
        _page = next;
        _items.addAll(page.items);
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

  /// Marks one message read, optimistically.
  Future<void> markRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || !_items[index].isUnread) return;

    final before = _items[index];
    _items[index] = _copyRead(before, _clock());
    notifyListeners();

    final result = await _repository.markRead(id);
    result.fold(
      onOk: (_) {},
      // Put the unread mark back. A badge that cleared for something the server
      // never recorded means the resident loses track of what they have seen.
      onErr: (_) {
        final current = _items.indexWhere((item) => item.id == id);
        if (current >= 0) _items[current] = before;
        notifyListeners();
      },
    );
  }

  /// Marks everything read, optimistically.
  Future<void> markAllRead() async {
    if (unreadCount == 0) return;

    final before = List<ResidentNotification>.from(_items);
    final now = _clock();
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].isUnread) _items[i] = _copyRead(_items[i], now);
    }
    notifyListeners();

    final result = await _repository.markAllRead();
    result.fold(
      onOk: (_) {},
      onErr: (_) {
        _items
          ..clear()
          ..addAll(before);
        notifyListeners();
      },
    );
  }

  static ResidentNotification _copyRead(
    ResidentNotification item,
    DateTime readAt,
  ) => ResidentNotification(
    id: item.id,
    title: item.title,
    body: item.body,
    sentAt: item.sentAt,
    readAt: readAt,
    category: item.category,
    target: item.target,
  );
}
