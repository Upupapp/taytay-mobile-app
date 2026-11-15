import 'dart:convert';

import 'sse_parser.dart';

/// The change-stream topics this app's screens listen to (DL-222).
///
/// Kebab-case, as the server names them. A topic the server sends that is not
/// here is ignored; a topic here that never arrives only means its screens
/// re-read on reconnect and on resume, not on every change.
abstract final class LiveTopics {
  /// The resident's own account row: verification tier, role, profile.
  static const String account = 'account';
  static const String notifications = 'notifications';
  static const String verification = 'verification';
  static const String threads = 'threads';
  static const String digitalIds = 'digital-ids';
  static const String sectorApplications = 'sector-applications';

  /// The resident's own document requests, and also the server's topic for
  /// the document catalogue (`issuance_types`). Those catalogue rows have no
  /// owner, so the server sends their changes only to the staff who keep the
  /// catalogue: the catalogue screens hear this topic for the resident's own
  /// changes, reconnects and returns, never for a catalogue edit (D-221).
  static const String issuanceRequests = 'issuance-requests';
  static const String eventRegistrations = 'event-registrations';

  /// The resident's own household and its members.
  static const String households = 'households';

  /// The resident's own consent records.
  static const String consents = 'consents';
  static const String news = 'news';
  static const String events = 'events';
  static const String home = 'home';
  static const String hotlines = 'hotlines';

  /// The municipal offices (the Directory).
  static const String offices = 'offices';

  /// The social services and programmes (Tulong).
  static const String services = 'services';
}

/// One message on the change stream, reduced to what the app may keep.
///
/// A hint names topics and nothing else. It carries no id, no count and no
/// personal data (DL-222), and anything else a payload might hold is dropped
/// here rather than carried upward.
sealed class LiveMessage {
  const LiveMessage();

  /// Reads [event], or returns `null` for one this build does not know.
  static LiveMessage? from(SseEvent event) => switch (event.type) {
    'ready' => LiveReady(_topicsOf(event.data)),
    'change' => LiveChange(_topicsOf(event.data)),
    'resync' => const LiveResync(),
    'expired' => const LiveExpired(),
    _ => null,
  };

  static final RegExp _topicShape = RegExp(r'^[a-z][a-z0-9-]{0,63}$');

  static Set<String> _topicsOf(String data) {
    final Object? decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException {
      return const <String>{};
    }
    if (decoded case {'topics': final List<Object?> topics}) {
      return <String>{
        for (final Object? topic in topics)
          if (topic is String && _topicShape.hasMatch(topic)) topic,
      };
    }
    return const <String>{};
  }
}

/// Sent once, first: every topic this connection can ever receive.
final class LiveReady extends LiveMessage {
  const LiveReady(this.topics);

  final Set<String> topics;

  @override
  String toString() => 'LiveReady(${topics.length} topics)';
}

/// These topics changed in the server's last coalescing window.
final class LiveChange extends LiveMessage {
  const LiveChange(this.topics);

  final Set<String> topics;

  @override
  String toString() => 'LiveChange(${topics.join(', ')})';
}

/// The server may have missed changes: re-read everything on screen.
final class LiveResync extends LiveMessage {
  const LiveResync();

  @override
  String toString() => 'LiveResync';
}

/// The server is about to close this stream. Reopen with a fresh token.
final class LiveExpired extends LiveMessage {
  const LiveExpired();

  @override
  String toString() => 'LiveExpired';
}
