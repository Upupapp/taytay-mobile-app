import 'package:flutter/foundation.dart';

/// One page of a paginated collection (backend `docs/api/conventions.md` §5).
///
/// Lives in `core/api/` because pagination is a property of the API contract,
/// not of any one feature. It was originally declared inside the service
/// catalogue's domain; every collection in this app has the same envelope, and
/// a second feature needing it is the point at which a shared shape should stop
/// being borrowed from a neighbour.
@immutable
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.hasMore,
  });

  /// A single unpaginated page, for endpoints that return a plain list.
  const Paginated.single(this.items)
    : page = 1,
      perPage = 0,
      total = 0,
      totalPages = 1,
      hasMore = false;

  final List<T> items;
  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasMore;

  bool get isEmpty => items.isEmpty;
}
