import '../../../core/api/paginated.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import 'own_assistance_request.dart';

/// The resident's own assistance requests (D-223, backend `d1e997c`), and
/// applying for one from a Tulong page (D-226, backend `6794f8d`).
///
/// **The server decides who may apply.** A verified resident whose account
/// the office has linked to her registry record. A registered account gets a
/// `ForbiddenFailure` whose `requiresVerification` is true; a verified
/// account the office has not linked yet gets a `ConflictFailure`. The
/// screen explains each. Nothing here checks a tier before asking.
///
/// **Every send takes an idempotency key**, minted when she presses send and
/// the same on every retry of that send, so a retry after a timeout is
/// answered with the first filing instead of filing twice.
///
/// The office moves a request; she never does. The two writes here file a new
/// one and add documents to one the office returned to her.
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

  /// `POST me/assistance-applications`, multipart: the Tulong page by its
  /// [serviceSlug], her [purpose], an optional amount in integer centavos,
  /// and [files] keyed by each requirement's code, which is also the field
  /// each file travels under. Answers with her own row, as her list shows it,
  /// carrying the control number the office issued.
  Future<Result<OwnAssistanceRequest>> apply({
    required String serviceSlug,
    required String purpose,
    int? requestedAmountCentavos,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  });

  /// `POST me/assistance-requests/{id}/documents`, multipart: one file per
  /// missing document's code, while the office has returned the request
  /// (a `ConflictFailure` otherwise). Each is a new version beside the one
  /// before; nothing she sent earlier is removed.
  Future<Result<OwnAssistanceRequest>> addDocuments(
    String requestId, {
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  });
}
