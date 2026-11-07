import 'dart:typed_data';

import '../../../core/api/paginated.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import 'issuance_request.dart';
import 'issuance_type.dart';

/// Document requests: the public catalogue, and a verified resident's own
/// requests to a municipal office.
///
/// **The server decides who may file.** Only a verified resident may submit;
/// anybody else gets a `ForbiddenFailure` back, and the screen explains it.
/// Nothing here checks a tier before asking.
abstract interface class IssuanceRepository {
  /// `GET issuance-types`. Public; the whole list.
  Future<Result<List<IssuanceType>>> listTypes();

  /// `GET issuance-types/{id}`. A retired or unknown type is `NotFoundFailure`.
  Future<Result<IssuanceType>> loadType(String typeId);

  /// `POST me/issuance-requests`, multipart. [files] is keyed by requirement
  /// code, which is also the field each file travels under.
  Future<Result<IssuanceRequestDetail>> submit({
    required String typeId,
    required String purpose,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  });

  /// `GET me/issuance-requests`, newest first, one cursor page at a time.
  Future<Result<Paginated<IssuanceRequestSummary>>> listOwn({String? cursor});

  /// `GET me/issuance-requests/{id}`. Somebody else's is `NotFoundFailure`.
  Future<Result<IssuanceRequestDetail>> loadOwn(String requestId);

  /// `POST me/issuance-requests/{id}/cancel`, with an optional reason.
  Future<Result<IssuanceRequestDetail>> cancel(
    String requestId, {
    String? reason,
    required String idempotencyKey,
  });

  /// `POST me/issuance-requests/{id}/resubmit`: an optional note and any new
  /// files. Each file is a new version beside the one before.
  Future<Result<IssuanceRequestDetail>> resubmit(
    String requestId, {
    String? note,
    required Map<String, CapturedDocument> files,
    required String idempotencyKey,
  });

  /// `GET me/issuance-requests/{id}/attachments/{attachmentId}/content`: the
  /// resident's own photo, to look at. Bytes live only as long as the screen
  /// that shows them.
  Future<Result<Uint8List>> loadAttachmentImage(
    String requestId,
    String attachmentId,
  );
}
