import '../result/result.dart';

/// What opening the change stream (`GET changes`, D-218) came to.
///
/// A closed set rather than a `Result`, because "this server has no change
/// stream" is not a failure to report or retry: live updates simply stay off,
/// and screens still re-read when the app comes back to the foreground.
sealed class ChangeStreamOpening {
  const ChangeStreamOpening();
}

/// The stream is open. [text] is its body, chunk by chunk.
///
/// Whoever holds it cancels its subscription to close the connection.
final class ChangeStreamOpen extends ChangeStreamOpening {
  const ChangeStreamOpen(this.text);

  final Stream<String> text;

  @override
  String toString() => 'ChangeStreamOpen';
}

/// This build or this server offers no change stream: the transport cannot
/// hold a response open, or the API answered `404` or `501`, or answered with
/// something that is not an event stream.
final class ChangeStreamNotOffered extends ChangeStreamOpening {
  const ChangeStreamNotOffered();

  @override
  String toString() => 'ChangeStreamNotOffered';
}

/// The stream could not be opened this time.
final class ChangeStreamFailed extends ChangeStreamOpening {
  const ChangeStreamFailed(this.failure);

  final AppFailure failure;

  @override
  String toString() => 'ChangeStreamFailed(${failure.runtimeType})';
}
