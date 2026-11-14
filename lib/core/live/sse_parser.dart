import 'package:flutter/foundation.dart';

/// One dispatched server-sent event.
@immutable
class SseEvent {
  const SseEvent({required this.type, required this.data});

  /// The `event:` field, or `message` when the server named none.
  final String type;

  /// Every `data:` line of the event, joined with line feeds.
  final String data;

  @override
  bool operator ==(Object other) =>
      other is SseEvent && other.type == type && other.data == data;

  @override
  int get hashCode => Object.hash(type, data);

  @override
  String toString() => 'SseEvent($type)';
}

/// Reads `text/event-stream` text as it arrives (D-218).
///
/// Follows the WHATWG event-stream interpretation: lines end in CR, LF or
/// CRLF (a CRLF split across two chunks is one line end); a line starting
/// with `:` is a comment; one space after the colon is dropped; an empty line
/// dispatches the event; an event with no `data` dispatches nothing. Pure, so
/// every chunk boundary can be tested without a socket.
///
/// `id:` is read and discarded: the change stream has no replay, and sending
/// `Last-Event-ID` is outside the API's allowed headers (DL-222).
class SseParser {
  /// A line longer than this is dropped, so a server that never sends a line
  /// end cannot grow the buffer without limit.
  static const int maxLineLength = 64 * 1024;

  final StringBuffer _line = StringBuffer();
  bool _discardingLine = false;
  bool _afterCarriageReturn = false;
  bool _started = false;

  String _eventType = '';
  final StringBuffer _data = StringBuffer();

  Duration? _retry;

  /// The reconnection time the server last asked for with `retry:`, if any.
  Duration? get retry => _retry;

  /// Feeds [chunk] and returns the events it completed, in order.
  List<SseEvent> add(String chunk) {
    final List<SseEvent> events = <SseEvent>[];
    var text = chunk;
    if (!_started && text.isNotEmpty) {
      _started = true;
      // A byte-order mark is allowed once, at the very start of the stream.
      if (text.startsWith('﻿')) text = text.substring(1);
    }
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      final int unit = text.codeUnitAt(i);
      if (_afterCarriageReturn) {
        _afterCarriageReturn = false;
        if (unit == 0x0A) {
          start = i + 1;
          continue;
        }
      }
      if (unit == 0x0A || unit == 0x0D) {
        _append(text.substring(start, i));
        if (!_discardingLine) _processLine(_line.toString(), events);
        _line.clear();
        _discardingLine = false;
        _afterCarriageReturn = unit == 0x0D;
        start = i + 1;
      }
    }
    _append(text.substring(start));
    return events;
  }

  void _append(String part) {
    if (_discardingLine || part.isEmpty) return;
    if (_line.length + part.length > maxLineLength) {
      _line.clear();
      _discardingLine = true;
      return;
    }
    _line.write(part);
  }

  void _processLine(String line, List<SseEvent> events) {
    if (line.isEmpty) {
      _dispatch(events);
      return;
    }
    if (line.startsWith(':')) return;

    final int colon = line.indexOf(':');
    final String field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);

    switch (field) {
      case 'event':
        _eventType = value;
      case 'data':
        if (_data.length + value.length > maxLineLength) return;
        _data
          ..write(value)
          ..write('\n');
      case 'retry':
        if (RegExp(r'^[0-9]{1,9}$').hasMatch(value)) {
          _retry = Duration(milliseconds: int.parse(value));
        }
    }
  }

  void _dispatch(List<SseEvent> events) {
    if (_data.isEmpty) {
      _eventType = '';
      return;
    }
    final String raw = _data.toString();
    events.add(
      SseEvent(
        type: _eventType.isEmpty ? 'message' : _eventType,
        data: raw.substring(0, raw.length - 1),
      ),
    );
    _data.clear();
    _eventType = '';
  }
}
