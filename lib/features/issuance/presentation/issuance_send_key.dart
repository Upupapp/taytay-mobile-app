import '../../../core/api/request_context.dart';
import '../../../core/result/result.dart';

/// The idempotency key for one act of the resident's: a submit, a resubmit
/// or a cancel.
///
/// Minted when they first press send, and **the same key on every retry of
/// that act**, so a send whose answer was lost to a timeout or a dropped
/// connection is answered with what the first one did rather than filed
/// twice (backend `0d1cb14`). The server compares the fields and files too,
/// so the key must change whenever they do: the owner calls [reset] on every
/// edit.
class IssuanceSendKey {
  IssuanceSendKey({String Function() mint = generateIdempotencyKey})
    : _mint = mint;

  final String Function() _mint;
  String? _key;

  /// The key for this send. The same one until [settle] or [reset] lets it go.
  String take() => _key ??= _mint();

  /// What the answer means for the key.
  ///
  /// * Done: the act is over, and the next one is a new act.
  /// * `409` (`ConflictFailure`): the server refused this key — another act or
  ///   other content already used it, or the request moved on. Sending it
  ///   again would only be refused again, so the next press mints a new one.
  /// * Anything else is kept. A timeout or a lost connection may have reached
  ///   the office, and only the same key makes trying again safe. A refusal
  ///   (`403`, `422`, `413`) claimed nothing, so keeping the key costs nothing.
  void settle(Result<Object?> result) {
    switch (result) {
      case Ok():
      case Err(failure: ConflictFailure()):
        _key = null;
      case Err():
        break;
    }
  }

  /// The resident changed what will be sent: it is a new act.
  void reset() => _key = null;
}
