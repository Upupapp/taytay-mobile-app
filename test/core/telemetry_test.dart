import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/core/result/result.dart';
import 'package:taytay_resident/core/router/app_routes.dart';
import 'package:taytay_resident/core/storage/secure_secret_store.dart';
import 'package:taytay_resident/core/telemetry/telemetry.dart';
import 'package:taytay_resident/core/telemetry/telemetry_route_observer.dart';

/// Captures what would have been sent.
class RecordingSink implements TelemetrySink {
  RecordingSink({this.isAvailable = true, this.throws = false});

  @override
  bool isAvailable;
  bool throws;

  final List<TelemetrySignal> signals = <TelemetrySignal>[];
  final List<CrashReport> crashes = <CrashReport>[];

  @override
  Future<void> send(TelemetrySignal signal) async {
    if (throws) throw StateError('sink is broken');
    signals.add(signal);
  }

  @override
  Future<void> reportCrash(CrashReport report) async {
    if (throws) throw StateError('sink is broken');
    crashes.add(report);
  }
}

/// Every signal shape, so the payload scan below covers the catalogue rather
/// than a sample of it.
List<TelemetrySignal> everySignalShape() => <TelemetrySignal>[
  const ScreenViewed(AppRoute.eventDetail),
  const FlowStep(
    flow: TelemetryFlow.assistanceApplication,
    stage: TelemetryStage.submitted,
  ),
  const OperationFinished(
    operation: TelemetryOperation.uploadDocument,
    result: TelemetryResult.validation,
    retried: true,
  ),
  SpanMeasured(
    span: TelemetrySpan.documentUpload,
    took: const Duration(seconds: 4),
  ),
  const ReachabilityChanged(reachable: false),
  const AccessGateShown(
    route: AppRoute.digitalId,
    requirement: 'verifiedResident',
  ),
  const ClientLimitationHit(
    limitation: TelemetryLimitation.unrenderableFormField,
  ),
];

Future<Telemetry> consented(RecordingSink sink) async {
  final telemetry = Telemetry(sink: sink, secrets: InMemorySecretStore());
  await telemetry.setConsent(TelemetryConsent.granted);
  return telemetry;
}

void main() {
  // ── The app works with telemetry off ────────────────────────────────────
  //
  // Acceptance 2, and the state every other test in this repository runs in.

  group('Off by default', () {
    test('the shipped sink is unavailable', () {
      expect(const DisabledTelemetrySink().isAvailable, isFalse);
    });

    test('a fresh Telemetry has not asked and collects nothing', () async {
      final telemetry = Telemetry(secrets: InMemorySecretStore());
      expect(telemetry.consent, TelemetryConsent.notAsked);
      expect(telemetry.isCollecting, isFalse);
      expect(
        await telemetry.record(const ScreenViewed(AppRoute.home)),
        isFalse,
      );
    });

    test('the shipped configuration never asks either', () {
      // There is nowhere to send, so a consent prompt would be asking
      // permission to do something the app cannot do.
      final telemetry = Telemetry(secrets: InMemorySecretStore());
      expect(telemetry.shouldAskForConsent, isFalse);
    });

    test('consent alone is not enough — the sink must exist', () async {
      final telemetry = Telemetry(secrets: InMemorySecretStore());
      await telemetry.setConsent(TelemetryConsent.granted);

      expect(telemetry.consent, TelemetryConsent.granted);
      expect(telemetry.isCollecting, isFalse);
      expect(
        await telemetry.record(const ScreenViewed(AppRoute.home)),
        isFalse,
      );
    });

    test('a sink alone is not enough — the resident must agree', () async {
      final sink = RecordingSink();
      final telemetry = Telemetry(sink: sink, secrets: InMemorySecretStore());

      expect(telemetry.isCollecting, isFalse);
      await telemetry.record(const ScreenViewed(AppRoute.home));
      expect(sink.signals, isEmpty);
    });

    test('the build switch overrides a resident who agreed', () async {
      final sink = RecordingSink();
      final telemetry = Telemetry(
        sink: sink,
        secrets: InMemorySecretStore(),
        allowedByBuild: false,
      );
      await telemetry.setConsent(TelemetryConsent.granted);

      // A build the municipality has not cleared for analytics collects
      // nothing, whatever the resident said.
      expect(telemetry.isCollecting, isFalse);
      await telemetry.record(const ScreenViewed(AppRoute.home));
      expect(sink.signals, isEmpty);
    });

    test('declining is remembered and never re-asked', () async {
      final secrets = InMemorySecretStore();
      final sink = RecordingSink();

      final first = Telemetry(sink: sink, secrets: secrets);
      await first.setConsent(TelemetryConsent.declined);

      final second = Telemetry(sink: sink, secrets: secrets);
      await second.restore();

      expect(second.consent, TelemetryConsent.declined);
      expect(second.shouldAskForConsent, isFalse);
      expect(second.isCollecting, isFalse);
    });

    test('an unreadable stored answer is treated as unanswered', () {
      expect(TelemetryConsent.parse(null), TelemetryConsent.notAsked);
      expect(TelemetryConsent.parse(''), TelemetryConsent.notAsked);
      expect(TelemetryConsent.parse('yes'), TelemetryConsent.notAsked);
      expect(TelemetryConsent.parse('granted'), TelemetryConsent.granted);
    });
  });

  group('With consent and a sink', () {
    test('a signal is sent', () async {
      final sink = RecordingSink();
      final telemetry = await consented(sink);

      expect(telemetry.isCollecting, isTrue);
      expect(await telemetry.record(const ScreenViewed(AppRoute.home)), isTrue);
      expect(sink.signals, hasLength(1));
    });

    test('withdrawing consent stops it immediately', () async {
      final sink = RecordingSink();
      final telemetry = await consented(sink);
      await telemetry.record(const ScreenViewed(AppRoute.home));

      await telemetry.setConsent(TelemetryConsent.declined);
      await telemetry.record(const ScreenViewed(AppRoute.news));

      expect(sink.signals, hasLength(1));
    });

    test('a sink that throws is disabled rather than retried', () async {
      final sink = RecordingSink(throws: true);
      final telemetry = await consented(sink);

      // Instrumentation that can break a submission is worse than none.
      expect(
        await telemetry.record(const ScreenViewed(AppRoute.home)),
        isFalse,
      );
      expect(telemetry.isCollecting, isFalse);

      sink.throws = false;
      expect(
        await telemetry.record(const ScreenViewed(AppRoute.news)),
        isFalse,
      );
    });
  });

  // ── No PII in any payload ───────────────────────────────────────────────
  //
  // Acceptance 1.

  group('Payloads carry no resident data', () {
    test('every parameter value comes from a declared wire constant', () {
      // The set of every value any enum in the catalogue can produce, plus the
      // two booleans and the route names. Anything outside it is free text that
      // reached a payload.
      final allowed = <String>{
        'true',
        'false',
        for (final v in TelemetryFlow.values) v.wireValue,
        for (final v in TelemetryStage.values) v.wireValue,
        for (final v in TelemetryOperation.values) v.wireValue,
        for (final v in TelemetryResult.values) v.wireValue,
        for (final v in TelemetrySpan.values) v.wireValue,
        for (final v in TelemetryDurationBucket.values) v.wireValue,
        for (final v in TelemetryCountBucket.values) v.wireValue,
        for (final v in TelemetryLimitation.values) v.wireValue,
        for (final v in AppRoute.values) v.routeName,
        // The gate's requirement, which is an enum name on the route table.
        'verifiedResident',
      };

      for (final signal in everySignalShape()) {
        for (final entry in signal.parameters.entries) {
          expect(
            allowed,
            contains(entry.value),
            reason:
                '${signal.name}.${entry.key} = "${entry.value}" is not a '
                'declared constant. A payload that accepts free text is how a '
                'resident name reaches an analytics service.',
          );
        }
      }
    });

    test('an event name describes an action, not a person or a record', () {
      final forbidden = <String>[
        'resident',
        'citizen',
        'user_id',
        'account',
        'name',
        'address',
        'phone',
        'household',
      ];
      for (final signal in everySignalShape()) {
        for (final word in forbidden) {
          expect(signal.name, isNot(contains(word)), reason: signal.name);
        }
      }
    });

    test('a screen is identified by its route, never by its path', () {
      const signal = ScreenViewed(AppRoute.eventDetail);
      final screen = signal.parameters['screen']!;

      // `/events/e-1` names one event and, with a few siblings, one resident's
      // week at the municipal hall. `eventDetail` names neither.
      expect(screen, AppRoute.eventDetail.routeName);
      expect(screen, isNot(contains('/')));
      expect(screen, isNot(contains(':')));
    });

    test('durations are buckets, not milliseconds', () {
      // A precise timing is a weak identifier; enough of them distinguish one
      // device from another.
      final sample = SpanMeasured(
        span: TelemetrySpan.appStart,
        took: const Duration(milliseconds: 1234),
      );
      expect(sample.parameters['duration'], 'lt_3s');
      expect(sample.parameters.values.join(), isNot(contains('1234')));
    });

    test('bucketing covers its boundaries', () {
      expect(
        TelemetryDurationBucket.of(const Duration(milliseconds: 99)),
        TelemetryDurationBucket.under100ms,
      );
      expect(
        TelemetryDurationBucket.of(const Duration(milliseconds: 100)),
        TelemetryDurationBucket.under500ms,
      );
      expect(
        TelemetryDurationBucket.of(const Duration(seconds: 10)),
        TelemetryDurationBucket.over10s,
      );
      expect(TelemetryCountBucket.of(0), TelemetryCountBucket.none);
      expect(TelemetryCountBucket.of(9), TelemetryCountBucket.few);
      expect(TelemetryCountBucket.of(10), TelemetryCountBucket.some);
      expect(TelemetryCountBucket.of(500), TelemetryCountBucket.many);
    });

    test('an outcome is a category derived from the failure kind', () {
      expect(CrashRedaction.resultOf(null), TelemetryResult.succeeded);
      expect(
        CrashRedaction.resultOf(const NetworkFailure()),
        TelemetryResult.network,
      );
      expect(
        CrashRedaction.resultOf(
          const ServerFailure(debugMessage: 'SQLSTATE[23505] duplicate key'),
        ),
        TelemetryResult.server,
      );
    });

    test('no server message survives the mapping', () {
      final result = CrashRedaction.resultOf(
        const ValidationFailure(
          debugMessage: 'given_name must not be Ana Dela Cruz',
        ),
      );
      expect(result.wireValue, 'validation');
      expect(result.wireValue, isNot(contains('Ana')));
    });
  });

  // ── Crash redaction ─────────────────────────────────────────────────────

  group('Crash reports keep nothing of the resident', () {
    test('the exception message is dropped entirely', () {
      // A real Dart message: `FormatException` quotes the value that broke it,
      // and the value is a resident's mobile number.
      final report = CrashRedaction.describe(
        const FormatException('Invalid number (at character 1): 09171234567'),
        StackTrace.current,
      );

      expect(report.errorType, 'FormatException');
      expect(report.toString(), isNot(contains('09171234567')));
      for (final frame in report.frames) {
        expect(frame, isNot(contains('09171234567')));
      }
    });

    test('an argument error carrying a decoded map is dropped too', () {
      final report = CrashRedaction.describe(
        ArgumentError.value(<String, Object?>{
          'given_name': 'Ana',
          'family_name': 'Dela Cruz',
        }, 'profile'),
        StackTrace.current,
      );

      expect(report.errorType, contains('ArgumentError'));
      expect(report.toString(), isNot(contains('Ana')));
      expect(report.toString(), isNot(contains('Dela Cruz')));
    });

    test('there is nowhere on the report to put a message', () {
      // Structural, not filtered: the type has no message field, so a future
      // caller cannot add one by passing it through.
      final report = CrashRedaction.describe(
        StateError('anything at all'),
        StackTrace.current,
      );
      expect(report.toString(), isNot(contains('anything at all')));
    });

    test('absolute filesystem paths are scrubbed from frames', () {
      final frames = CrashRedaction.redactStack(
        StackTrace.fromString(
          '#0 doThing (file:///C:/Users/ana/projects/taytay/lib/x.dart:12:3)\n'
          '#1 other (/home/ana/dev/taytay/lib/y.dart:4:1)\n'
          '#2 third (package:taytay_resident/core/z.dart:9:2)',
        ),
      );

      final joined = frames.join('\n');
      // A build machine's home directory names a person.
      expect(joined, isNot(contains('ana')));
      expect(joined, isNot(contains('Users')));
      // What a fix is actually made from survives.
      expect(joined, contains('doThing'));
      expect(joined, contains('lib/x.dart'));
      expect(joined, contains('package:taytay_resident'));
    });

    test('the stack is bounded', () {
      final long = StackTrace.fromString(
        List<String>.generate(
          200,
          (i) => '#$i frame (package:x/y.dart:$i:1)',
        ).join('\n'),
      );
      expect(
        CrashRedaction.redactStack(long),
        hasLength(CrashRedaction.maxFrames),
      );
    });

    test('a missing stack is not an error', () {
      expect(CrashRedaction.redactStack(null), isEmpty);
      final report = CrashRedaction.describe(StateError('x'), null);
      expect(report.frames, isEmpty);
    });

    test('a crash is not reported without consent either', () async {
      final sink = RecordingSink();
      final telemetry = Telemetry(sink: sink, secrets: InMemorySecretStore());

      // "Analytics" and "diagnostics" are not different words for the same
      // promise: a crash report is still data about a resident's session.
      expect(
        await telemetry.recordCrash(StateError('x'), StackTrace.current),
        isFalse,
      );
      expect(sink.crashes, isEmpty);
    });

    test('and is reported when they agreed', () async {
      final sink = RecordingSink();
      final telemetry = await consented(sink);

      expect(
        await telemetry.recordCrash(
          StateError('x'),
          StackTrace.current,
          fatal: true,
        ),
        isTrue,
      );
      expect(sink.crashes.single.fatal, isTrue);
      expect(sink.crashes.single.errorType, 'StateError');
    });
  });

  // ── The route observer ──────────────────────────────────────────────────

  group('Screen views carry a route, never a location', () {
    test('a path with an identifier resolves to its route', () {
      final resolved = TelemetryRouteObserver.resolve('/events/e-1');
      expect(resolved, isNotNull);
      expect(resolved!.routeName, isNot(contains('e-1')));
    });

    test('an unresolvable path sends nothing rather than the raw string', () {
      // The case where the raw string is most likely to be something
      // unexpected is exactly the case where it must not travel.
      expect(TelemetryRouteObserver.resolve('/nonsense/PH-1234-5678'), isNull);
      expect(TelemetryRouteObserver.resolve(''), isNull);
      expect(TelemetryRouteObserver.resolve(null), isNull);
    });

    test('a query string never reaches the payload', () {
      final resolved = TelemetryRouteObserver.resolve(
        '/services?from=/requests/req-8823',
      );
      if (resolved != null) {
        expect(resolved.routeName, isNot(contains('req-8823')));
        expect(resolved.routeName, isNot(contains('?')));
      }
    });
  });

  // ── Guardrails on the repository itself ─────────────────────────────────

  group('Privacy guardrails', () {
    test('no advertising or attribution SDK is declared', () {
      // Acceptance 3. Named rather than pattern-matched, because these are the
      // packages that would actually be reached for.
      final pubspec = File('pubspec.yaml').readAsStringSync().toLowerCase();
      const forbidden = <String>[
        'firebase_analytics',
        'google_mobile_ads',
        'facebook_app_events',
        'appsflyer',
        'adjust_sdk',
        'branch_io',
        'amplitude',
        'mixpanel',
        'segment_analytics',
        'onesignal',
        'sentry_flutter',
        'firebase_crashlytics',
        'app_tracking_transparency',
        'advertising_id',
        'device_info_plus',
      ];
      for (final package in forbidden) {
        expect(
          pubspec,
          isNot(contains(package)),
          reason:
              '$package would put resident usage in a third party\'s hands, '
              'which is a data-sharing decision the municipality signs — not a '
              'line in pubspec.yaml.',
        );
      }
    });

    test('the telemetry catalogue declares no free-text payload field', () {
      // Structural: every payload field is an enum, a bool or a bucket. A
      // `String` field is the door PII walks through.
      final source = File(
        'lib/core/telemetry/telemetry_events.dart',
      ).readAsStringSync();

      // Field declarations only — `final <type> <name>;` — after stripping
      // doc comments, which legitimately discuss strings.
      final withoutDocs = source
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('///'))
          .join('\n');

      final fields = RegExp(
        r'^\s*final\s+([A-Za-z0-9_<>?]+)\s+\w+;',
        multiLine: true,
      ).allMatches(withoutDocs).map((m) => m.group(1)!).toList();

      expect(fields, isNotEmpty, reason: 'the scan found nothing to check');

      // `wireValue` on the enums is the one String, and it holds a constant
      // this file declares. The signal payload classes must have none.
      final signalSection = withoutDocs.substring(
        withoutDocs.indexOf('sealed class TelemetrySignal'),
      );
      final signalFields = RegExp(
        r'^\s*final\s+([A-Za-z0-9_<>?]+)\s+\w+;',
        multiLine: true,
      ).allMatches(signalSection).map((m) => m.group(1)!).toSet();

      expect(
        signalFields.where((type) => type.startsWith('String')),
        // `AccessGateShown.requirement` is the single documented exception and
        // is fed an enum name from the route table.
        hasLength(lessThanOrEqualTo(1)),
        reason: 'signal payload fields: $signalFields',
      );
    });

    test('nothing outside core/telemetry constructs a raw crash report', () {
      // One redactor, one place to review.
      final offenders = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        if (file.path.contains('telemetry')) continue;
        final source = file.readAsStringSync();
        if (source.contains('CrashReport(')) offenders.add(file.path);
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });
}
