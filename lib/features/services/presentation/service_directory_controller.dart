import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../domain/lgu_service.dart';
import '../domain/service_catalog_repository.dart';

/// Drives the Programs and Services directory: load, search, filter, staleness.
///
/// ---
///
/// **Search runs on the device, over data the server already returned.**
///
/// The committed endpoint accepts two filters — `?category=` and `?channel=` —
/// and no `?search=`. So a search box could not be a server query without
/// inventing one. But the local choice is also the better one, for a reason
/// worth stating plainly: **a search term is a disclosure.** "burial
/// assistance", "solo parent", "medical" — typed into a municipal app by a named
/// account — is a sentence about somebody's circumstances, and sending it to be
/// logged buys nothing when the catalogue is small enough to filter on the
/// phone. Filtering locally means the LGU never learns what a resident was
/// looking for.
///
/// **Nothing here decides eligibility.** The controller filters a public
/// catalogue by words. It has no access to a profile, no rule evaluation and no
/// concept of "suitable for you" — see `EligibilityCriterion` for why that line
/// is drawn hard (acceptance 2).
///
/// **Staleness is explicit.** When a refresh fails and previously-loaded entries
/// are still on screen, [isShowingStale] is true and the screen says so. The
/// alternative — silently keeping the old list — shows a resident a programme
/// window that closed last week and looks identical to a working app.
class ServiceDirectoryController extends ChangeNotifier {
  ServiceDirectoryController({
    required ServiceCatalogRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _now = clock ?? DateTime.now;

  final ServiceCatalogRepository _repository;
  final DateTime Function() _now;

  List<LguService> _all = const <LguService>[];
  bool _loading = false;
  bool _hasLoaded = false;
  AppFailure? _failure;
  DateTime? _loadedAt;

  String _query = '';
  ServiceCategory? _category;

  bool get loading => _loading;

  /// True once a load has completed, successfully or not.
  bool get hasLoaded => _hasLoaded;

  AppFailure? get failure => _failure;

  /// When the entries on screen were actually fetched. Null before any success.
  DateTime? get loadedAt => _loadedAt;

  String get query => _query;
  ServiceCategory? get category => _category;

  /// Everything the server returned, unfiltered. The denominator for "no
  /// results for that word" versus "the catalogue is empty".
  int get totalCount => _all.length;

  /// True when the last attempt failed but earlier entries are still shown.
  bool get isShowingStale => _failure != null && _all.isNotEmpty;

  /// True when the catalogue could not be loaded at all.
  bool get hasNothingToShow => _failure != null && _all.isEmpty;

  /// The categories actually present in what was returned.
  ///
  /// Built from the data rather than from the enum, so the filter row never
  /// offers a category that would produce an empty list — and never advertises
  /// a category the LGU does not currently publish.
  List<ServiceCategory> get availableCategories {
    final present = <ServiceCategory>{};
    for (final service in _all) {
      final known = service.category.known;
      if (known != null) present.add(known);
    }
    return present.toList(growable: false)
      ..sort((a, b) => a.wireValue.compareTo(b.wireValue));
  }

  /// What the list should render, after the local query and category filter.
  List<LguService> get visible {
    final needle = _query.trim().toLowerCase();
    return _all
        .where((service) {
          final category = _category;
          if (category != null && service.category.known != category) {
            return false;
          }
          if (needle.isEmpty) return true;
          // Name, description and the server's own category label. Deliberately not
          // the code: `AICS` is not a word a resident searches for, and matching it
          // produces results they cannot explain.
          return service.name.toLowerCase().contains(needle) ||
              service.description.toLowerCase().contains(needle) ||
              service.category.raw.toLowerCase().contains(needle);
        })
        .toList(growable: false);
  }

  /// True when a filter is hiding entries that were loaded.
  bool get isFiltered => _query.trim().isNotEmpty || _category != null;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final result = await _repository.listServices();

    _loading = false;
    _hasLoaded = true;
    switch (result) {
      case Ok<Paginated<LguService>>(:final value):
        _all = value.items;
        _failure = null;
        _loadedAt = _now();
      case Err<Paginated<LguService>>(:final failure):
        // Deliberately does **not** clear `_all`. A resident on a weak
        // connection keeps the catalogue they had, labelled as saved rather
        // than fresh.
        _failure = failure;
    }
    notifyListeners();
  }

  void search(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// Passing the current category clears it, so the chip row toggles.
  void filterByCategory(ServiceCategory? value) {
    _category = _category == value ? null : value;
    notifyListeners();
  }

  void clearFilters() {
    if (!isFiltered) return;
    _query = '';
    _category = null;
    notifyListeners();
  }

  /// Finds a loaded entry by its stable code.
  ///
  /// The committed contract has **no service-detail route** — only the list — so
  /// a detail screen is rendered from the entry the app already holds. That is
  /// why the deep-link identifier is the `code` and not the UUID: a code is
  /// stable across a re-seed, is what an office quotes, and is legible in a link.
  LguService? byCode(String code) {
    for (final service in _all) {
      if (service.code == code) return service;
    }
    return null;
  }

  /// Public reference data, no personal state — safe to log.
  @override
  String toString() =>
      'ServiceDirectoryController(loaded: $totalCount, stale: $isShowingStale)';
}
