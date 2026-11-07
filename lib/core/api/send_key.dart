import '../result/result.dart';
import 'request_context.dart';

/// The idempotency key for one act of the resident's: a document request, a
/// cancellation, a message to an office.
///
/// Minted when they first press send, and **the same key on every retry of
/// that act**, so a send whose answer was lost to a timeout or a dropped
/// connection is answered with what the first one did rather than acting
/// twice (backend `0d1cb14` for document requests, `a7a1884` for messages).
/// The server compares what is sent with what the key first carried and
/// refuses a mismatch, so the key must change whenever the content does:
/// either the owner calls [reset] on every edit, or it asks through [takeFor]
/// and the key follows the content by itself.
class SendKey {
  SendKey({String Function() mint = generateIdempotencyKey}) : _mint = mint;

  final String Function() _mint;
  String? _key;
  Object? _content;

  /// The key for this send. The same one until [settle] or [reset] lets it go.
  String take() => _key ??= _mint();

  /// The key for sending [content]: the one already held while [content]
  /// equals what it was minted for, and a new one as soon as it differs.
  ///
  /// For a composer whose words, subject or attachment can change between
  /// attempts by several paths. Binding the key to the content means no edit
  /// path can forget to let it go, and a retry of unchanged content can never
  /// get a new one. [content] needs value equality (a record of strings, say);
  /// anything compared by identity is new each time it is replaced.
  String takeFor(Object content) {
    if (content != _content) {
      _key = null;
      _content = content;
    }
    return take();
  }

  /// What the answer means for the key.
  ///
  /// * Done: the act is over, and the next one is a new act.
  /// * `409` (`ConflictFailure`): the server refused this key — another act or
  ///   other content already used it, or the record moved on. Sending it
  ///   again would only be refused again, so the next press mints a new one.
  ///   It is never retried.
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
  void reset() {
    _key = null;
    _content = null;
  }
}
