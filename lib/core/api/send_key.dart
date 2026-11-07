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
///
/// It also remembers whether a send may have arrived without an answer
/// ([unconfirmed]), so a screen never calls a later failure "not sent" while an
/// earlier send may have reached the office (D-191, D-192).
class SendKey {
  SendKey({String Function() mint = generateIdempotencyKey}) : _mint = mint;

  final String Function() _mint;
  String? _key;
  Object? _content;
  bool _unconfirmed = false;

  /// Whether a send made with this holder may have reached the server without
  /// its answer reaching the phone, and no answer has come since.
  ///
  /// [settle] sets it for a failure whose outcome is unknown (D-188), and only
  /// an `Ok` clears it. A refusal or a `409` on a later try, a new key for
  /// changed content, and [reset] all leave it: the send whose answer was lost
  /// may still have arrived. Read after [settle], it covers the send just
  /// settled too, so a retry that fails before it leaves the phone still says
  /// "could not confirm", never "not sent".
  bool get unconfirmed => _unconfirmed;

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
  ///
  /// An `Ok` clears [unconfirmed]; a failure whose outcome is unknown sets it.
  void settle(Result<Object?> result) {
    switch (result) {
      case Ok():
        _key = null;
        _unconfirmed = false;
      case Err(failure: ConflictFailure()):
        _key = null;
      case Err(:final failure):
        if (failure.outcomeUnknown) _unconfirmed = true;
    }
  }

  /// The resident changed what will be sent: it is a new act.
  void reset() {
    _key = null;
    _content = null;
  }
}
