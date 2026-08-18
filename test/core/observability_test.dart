import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/telemetry/telemetry_events.dart';

/// TAB 16's guarantee, held mechanically.
///
/// **Redaction that depends on reviewer memory fails silently.** Somebody adds a
/// parameter to debug a funnel, the value turns out to be a case narrative, and
/// nothing anywhere objects — the payload was always allowed to be a map. These
/// tests are the objection.
void main() {
  group('a telemetry payload cannot carry personal data', () {
    test('every signal parameter is a wire constant, never free text', () {
      // The structural defence, and the reason the payload is a sealed set. A
      // parameter bag is how PII reaches an analytics service — not by decision,
      // but because it accepts anything, and one day somebody adds
      // {'service': service.name} to debug a funnel and the service name turns
      // out to be "Medical assistance — Ana Dela Cruz (re-submitted)".
      final List<TelemetrySignal> signals = <TelemetrySignal>[
        const FlowStep(
          flow: TelemetryFlow.signIn,
          stage: TelemetryStage.started,
        ),
        const OperationFinished(
          operation: TelemetryOperation.loadCatalogue,
          result: TelemetryResult.succeeded,
        ),
        const ReachabilityChanged(reachable: false),
      ];

      final RegExp wireConstant = RegExp(r'^[a-z0-9_]+$');
      for (final TelemetrySignal signal in signals) {
        expect(signal.name, matches(wireConstant), reason: signal.name);
        signal.parameters.forEach((String key, String value) {
          expect(key, matches(wireConstant), reason: '${signal.name}.$key');
          // Values are enum wire constants or booleans rendered as such. A space
          // or a capital is the first sign of a sentence.
          expect(
            value,
            matches(RegExp(r'^[a-z0-9_.\-]+$')),
            reason: '${signal.name}.$key = "$value"',
          );
        });
      }
    });

    test('no signal type declares a free-text field', () {
      // The check that survives somebody adding a new signal. A `String` field
      // that is not an enum's wire value is a place a name can land.
      // Comments stripped first: the file explains at length why a parameter
      // bag is forbidden, and a check that flags the explanation is one somebody
      // switches off rather than reads.
      final String source = File('lib/core/telemetry/telemetry_events.dart')
          .readAsStringSync()
          .split('\n')
          .where((String line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      for (final String forbidden in <String>[
        'final String message',
        'final String detail',
        'final String note',
        'final String narrative',
        'final String query',
        'Map<String, dynamic>',
        'Map<String, Object?>',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test('a crash report has nowhere to put the message', () {
      // A Dart exception routinely quotes the value that broke it —
      // "FormatException: Invalid number: 09171234567". Redaction by pattern is
      // a losing game because the next message has a shape nobody anticipated,
      // so the type carries the error's *kind* and a scrubbed stack and has no
      // field for the text at all.
      final String source = File(
        'lib/core/telemetry/telemetry.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('errorMessage')));
      expect(source, contains('_scrubPaths'));
    });
  });

  group('the funnels TAB 16 names are actually recorded', () {
    test('each has a call site, not merely an enum value', () {
      // The finding this TAB started from: the vocabulary was complete and
      // nothing recorded it. Five flows, zero call sites — declared telemetry
      // that would have reported an empty funnel as a quiet one.
      final Map<TelemetryFlow, String> owners = <TelemetryFlow, String>{
        TelemetryFlow.signIn: 'lib/features/auth/data/auth_api_repository.dart',
        TelemetryFlow.assistanceApplication:
            'lib/features/services/data/assistance_api_repository.dart',
        TelemetryFlow.documentUpload:
            'lib/features/requirements/data/requirement_api_repository.dart',
        TelemetryFlow.eventRegistration:
            'lib/features/events/data/event_api_repository.dart',
        TelemetryFlow.verification:
            'lib/features/verification/data/kyc_api_repository.dart',
      };

      owners.forEach((TelemetryFlow flow, String path) {
        final String source = File(path).readAsStringSync();
        expect(
          source,
          contains('TelemetryFlow.${flow.name}'),
          reason: '${flow.name} has no recorder in $path',
        );
      });
    });
  });

  group('correlation without identification', () {
    test('the request id is per request, never a stable device id', () {
      // A correlation id that persists across sessions becomes a tracking
      // identifier. The current per-request design is correct and the risk is
      // that somebody "improves" it into something stable.
      final String source = File('lib/core/api/request_context.dart')
          .readAsStringSync()
          .split('\n')
          .where((String line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      for (final String forbidden in <String>[
        'deviceId',
        'installationId',
        'static final String _requestId',
        'persist',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: forbidden);
      }
    });
  });
}
