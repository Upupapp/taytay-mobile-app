import '../../../core/result/result.dart';

/// The two ways a resident writes to an office.
enum MessageAct {
  /// The first message, which opens a thread (`POST /threads`).
  start(
    'We could not confirm that your message was received. Sending it again '
    'is safe: it will not be posted twice. You can also check Messages.',
  ),

  /// A message in a thread already open (`POST /threads/{id}/messages`).
  reply(
    'We could not confirm that your message was received. Sending it again '
    'is safe: it will not be posted twice.',
  );

  const MessageAct(this.unconfirmed);

  /// The sentence for a message that may have reached the office.
  ///
  /// True because every message carries an idempotency key that is kept for
  /// the retry of the same words and image (`SendKey`): the server answers a
  /// repeat with the message the first send made, and never posts it twice.
  final String unconfirmed;
}

/// The sentence for a message that certainly did not reach the office.
const String messageNotSent = 'Nothing was sent.';

/// What a resident reads under the composer when a message did not go through.
///
/// Every line is this app's own; the server's `message` never reaches the
/// screen (Article 5.5). It says whether the message reached the office only
/// where the app knows (D-188): "nothing was sent" for a connection that
/// failed before the request left the phone, "could not confirm" for a
/// timeout, a connection dropped after sending, an unreadable answer or a
/// server that failed part-way. Other refusals keep the failure's own words.
///
/// Once a send's answer was lost, every later failure in the same composer
/// says "could not confirm" until a send goes through, the rule events follow
/// (D-191, D-192): a retry that fails before it leaves the phone sent nothing,
/// but the earlier send may have reached the office. [unconfirmed] is
/// `SendKey.unconfirmed`, read after settling this failure.
String messageSendFailure(
  AppFailure failure, {
  required MessageAct act,
  bool unconfirmed = false,
}) {
  return switch (failure) {
    _ when failure.outcomeUnknown || unconfirmed => act.unconfirmed,
    // Past the guard above, the connection failed before anything was sent.
    NetworkFailure() => '$messageNotSent ${failure.residentMessage}',
    // A first message has no thread state to conflict with: a 409 means its
    // key was already used for other content, a fault in this app, or that
    // a thread opened under it a moment ago. Never retried with the same key.
    ConflictFailure() when act == MessageAct.start =>
      '$messageNotSent Something went wrong on our side. Open Messages to '
          'check what the office has before trying again.',
    _ => failure.residentMessage,
  };
}
