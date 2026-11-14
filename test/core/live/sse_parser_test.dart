import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/live/live_message.dart';
import 'package:taytay_resident/core/live/sse_parser.dart';

/// D-218: the change stream is read as `text/event-stream`, chunk by chunk.
void main() {
  List<SseEvent> parseAll(List<String> chunks) {
    final SseParser parser = SseParser();
    return <SseEvent>[for (final String chunk in chunks) ...parser.add(chunk)];
  }

  group('the event-stream parser', () {
    test('reads the contract\'s opening: retry, a comment, then ready', () {
      final SseParser parser = SseParser();
      final List<SseEvent> events = parser.add(
        'retry: 5000\n: connected\n\nevent: ready\n'
        'data: {"topics":["news","notifications"]}\n\n',
      );
      expect(events, <SseEvent>[
        const SseEvent(
          type: 'ready',
          data: '{"topics":["news","notifications"]}',
        ),
      ]);
      expect(parser.retry, const Duration(milliseconds: 5000));
    });

    test('a comment alone dispatches nothing', () {
      expect(parseAll(<String>[': ping\n\n', ':\n\n']), isEmpty);
    });

    test('an event with no data dispatches nothing', () {
      expect(parseAll(<String>['event: change\n\n']), isEmpty);
    });

    test('an event split anywhere across chunks is one event', () {
      const String whole =
          'event: change\ndata: {"topics":["verification"]}\n\n';
      for (var cut = 1; cut < whole.length; cut++) {
        expect(
          parseAll(<String>[whole.substring(0, cut), whole.substring(cut)]),
          <SseEvent>[
            const SseEvent(type: 'change', data: '{"topics":["verification"]}'),
          ],
          reason: 'cut at $cut',
        );
      }
    });

    test('CRLF, CR and LF all end a line, and a CRLF split is one end', () {
      expect(
        parseAll(<String>['event: resync\r', '\ndata: {}\r', '\n\r\n']),
        <SseEvent>[const SseEvent(type: 'resync', data: '{}')],
      );
      expect(parseAll(<String>['event: expired\rdata: {}\r\r']), <SseEvent>[
        const SseEvent(type: 'expired', data: '{}'),
      ]);
    });

    test('data lines join with a line feed; one leading space is dropped', () {
      expect(parseAll(<String>['data:a\ndata:  b\n\n']), <SseEvent>[
        const SseEvent(type: 'message', data: 'a\n b'),
      ]);
    });

    test('the event type does not leak into the next event', () {
      expect(
        parseAll(<String>['event: change\ndata: 1\n\ndata: 2\n\n']),
        <SseEvent>[
          const SseEvent(type: 'change', data: '1'),
          const SseEvent(type: 'message', data: '2'),
        ],
      );
    });

    test('a byte-order mark is dropped once, at the start', () {
      expect(parseAll(<String>['﻿data: x\n\n']), <SseEvent>[
        const SseEvent(type: 'message', data: 'x'),
      ]);
    });

    test('id, unknown fields and a retry that is not digits are ignored', () {
      final SseParser parser = SseParser();
      final List<SseEvent> events = parser.add(
        'id: 41\nflavour: x\nretry: soon\ndata: y\n\n',
      );
      expect(events, <SseEvent>[const SseEvent(type: 'message', data: 'y')]);
      expect(parser.retry, isNull);
    });

    test('a line longer than the limit is dropped, not buffered', () {
      final SseParser parser = SseParser();
      final String huge = 'x' * (SseParser.maxLineLength + 10);
      expect(parser.add('data: $huge'), isEmpty);
      expect(parser.add('\n\ndata: ok\n\n'), <SseEvent>[
        const SseEvent(type: 'message', data: 'ok'),
      ]);
    });
  });

  group('a hint keeps topics and nothing else', () {
    test('ready and change carry the topic names', () {
      final LiveMessage? ready = LiveMessage.from(
        const SseEvent(type: 'ready', data: '{"topics":["news","threads"]}'),
      );
      expect(ready, isA<LiveReady>());
      expect((ready! as LiveReady).topics, <String>{'news', 'threads'});

      final LiveMessage? change = LiveMessage.from(
        const SseEvent(type: 'change', data: '{"topics":["verification"]}'),
      );
      expect((change! as LiveChange).topics, <String>{'verification'});
    });

    test('anything beside the topics is dropped, ids above all', () {
      final LiveMessage? change = LiveMessage.from(
        const SseEvent(
          type: 'change',
          data:
              '{"topics":["threads", 7, "Not A Topic", "a/b"],'
              '"id":"thread-1","count":3}',
        ),
      );
      expect((change! as LiveChange).topics, <String>{'threads'});
    });

    test('resync and expired are recognised; an unknown event is not', () {
      expect(
        LiveMessage.from(const SseEvent(type: 'resync', data: '{}')),
        isA<LiveResync>(),
      );
      expect(
        LiveMessage.from(const SseEvent(type: 'expired', data: '{}')),
        isA<LiveExpired>(),
      );
      expect(
        LiveMessage.from(const SseEvent(type: 'message', data: '{}')),
        isNull,
      );
    });

    test('a body that is not JSON names no topics rather than throwing', () {
      final LiveMessage? change = LiveMessage.from(
        const SseEvent(type: 'change', data: 'not json'),
      );
      expect((change! as LiveChange).topics, isEmpty);
    });
  });
}
