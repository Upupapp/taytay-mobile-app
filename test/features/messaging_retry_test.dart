import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/api/send_key.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/features/messaging/domain/message_send_failure.dart';
import 'package:taytay_resident/features/messaging/domain/office_messaging_repository.dart';

void main() {
  group('a message key follows what is sent', () {
    test('the same words keep it; other words, subject or file do not', () {
      int minted = 0;
      final SendKey key = SendKey(mint: () => 'k-${++minted}');
      final OutgoingFile photo = OutgoingFile(
        bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0x00]),
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );

      final String first = key.takeFor(('office-1', 'Cedula', 'Saan po', null));
      key.settle(const Err<Object?>(TimeoutFailure()));
      expect(key.takeFor(('office-1', 'Cedula', 'Saan po', null)), first);
      key.settle(const Err<Object?>(NetworkFailure(mayHaveArrived: true)));
      expect(key.takeFor(('office-1', 'Cedula', 'Saan po', null)), first);

      final String words = key.takeFor((
        'office-1',
        'Cedula',
        'Saan po ang pila?',
        null,
      ));
      expect(words, isNot(first));
      final String subject = key.takeFor((
        'office-1',
        'Tax',
        'Saan po ang pila?',
        null,
      ));
      expect(subject, isNot(words));
      final String file = key.takeFor((
        'office-1',
        'Tax',
        'Saan po ang pila?',
        photo,
      ));
      expect(file, isNot(subject));
      expect(
        key.takeFor(('office-1', 'Tax', 'Saan po ang pila?', photo)),
        file,
      );

      // Going back to earlier words is a new message too: that key was let go.
      expect(
        key.takeFor(('office-1', 'Cedula', 'Saan po', null)),
        isNot(first),
      );
    });

    test('a sent message or a 409 lets the key go; nothing else does', () {
      int minted = 0;
      final SendKey key = SendKey(mint: () => 'k-${++minted}');
      const (String, String) reply = ('thread-1', 'Salamat po');

      final String first = key.takeFor(reply);
      key.settle(const Err<Object?>(ForbiddenFailure()));
      expect(key.takeFor(reply), first);

      key.settle(const Ok<Object?>(null));
      final String second = key.takeFor(reply);
      expect(second, isNot(first));

      // The server refused the key itself. It is a fault, never retried.
      key.settle(const Err<Object?>(ConflictFailure()));
      expect(key.takeFor(reply), isNot(second));
    });

    test('a minted key is a version 4 UUID', () {
      expect(
        SendKey().takeFor(('thread-1', 'Salamat po')),
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });

  group('a message whose outcome is unknown is not called unsent', () {
    const List<AppFailure> unknown = <AppFailure>[
      TimeoutFailure(),
      NetworkFailure(mayHaveArrived: true),
      ContractFailure(),
      UnexpectedFailure(),
      ServerFailure(),
    ];

    test('says it could not confirm, and that sending again is safe', () {
      for (final MessageAct act in MessageAct.values) {
        for (final AppFailure failure in unknown) {
          final String said = messageSendFailure(failure, act: act);
          final String reason = '${act.name} ${failure.kind}';
          expect(said, act.unconfirmed, reason: reason);
          expect(said, contains('could not confirm'), reason: reason);
          expect(said, contains('will not be posted twice'), reason: reason);
          expect(said, isNot(contains('Nothing was')), reason: reason);
          expect(said, isNot(contains('offline')), reason: reason);
        }
      }
      expect(MessageAct.start.unconfirmed, contains('check Messages'));
    });

    test('says nothing was sent only when it failed before leaving', () {
      for (final MessageAct act in MessageAct.values) {
        expect(
          messageSendFailure(const NetworkFailure(), act: act),
          '$messageNotSent ${const NetworkFailure().residentMessage}',
        );
        // A refusal keeps the failure's own words, and claims nothing more.
        expect(
          messageSendFailure(const ValidationFailure(), act: act),
          const ValidationFailure().residentMessage,
        );
      }
    });

    test('a 409 on a first message is a fault of ours, said generically', () {
      const String serverText =
          'That idempotency key was already used for a different message.';
      final String start = messageSendFailure(
        const ConflictFailure(debugMessage: serverText),
        act: MessageAct.start,
      );
      expect(start, startsWith(messageNotSent));
      expect(start, contains('Open Messages'));
      expect(start, isNot(contains(serverText)));
      // On a reply a 409 is also a closed thread; the screen says so.
      expect(
        messageSendFailure(const ConflictFailure(), act: MessageAct.reply),
        const ConflictFailure().residentMessage,
      );
    });
  });
}
