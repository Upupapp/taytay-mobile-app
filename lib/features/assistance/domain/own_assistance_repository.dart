import '../../../core/api/paginated.dart';
import '../../../core/result/result.dart';
import 'own_assistance_request.dart';

/// The resident's own assistance requests (D-223, backend `d1e997c`).
///
/// Read only. The resident files nothing and changes nothing here: a request
/// is filed and moved at the MSWDO.
abstract interface class OwnAssistanceRepository {
  /// One page of her filed requests, newest filing first. [cursor] is the
  /// previous page's `next_cursor`; null reads the first page.
  ///
  /// An empty page is an answer, never a failure, and says nothing about
  /// why: an account the office has not linked, a resident who has filed
  /// nothing and a person whose requests are discussed only in person all
  /// read the same empty list.
  Future<Result<Paginated<OwnAssistanceRequest>>> listOwn({String? cursor});

  /// One request by [id], found in the list (the API has no route for one).
  ///
  /// A [NotFoundFailure] when the list does not carry it, which is said the
  /// same way as an empty list: nothing about why.
  Future<Result<OwnAssistanceRequest>> findOwn(String id);
}
