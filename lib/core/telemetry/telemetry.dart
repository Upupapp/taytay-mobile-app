import 'package:flutter/foundation.dart';

import '../result/app_failure.dart';
import '../storage/secure_secret_store.dart';
import 'telemetry_events.dart';

export 'telemetry_events.dart';

/// Whether the resident has agreed to operational telemetry.
///
/// Three states, not a boolean: **not having answered is not the same as saying
/// no**, and the app needs to tell them apart to know whether it may ask.
enum TelemetryConsent {
  /// Nobody has asked yet. Telemetry is **off**.
  notAsked('not_asked'),

  granted('granted'),

  /// Declined. Telemetry is off and the app does not ask again.
  declined('declined');

  const TelemetryConsent(this.wireValue);

  final String wireValue;

  static TelemetryConsent parse(String? stored) {
    for (final value in TelemetryConsent.values) {
      if (value.wireValue == stored) return value;
    }
    // An unreadable or absent value is treated as unanswered, which is the
    // state that collects nothing.
    return TelemetryConsent.notAsked;
  }
}

/// Where a telemetry signal goes.
///
/// An interface so the whole app is instrumented against a seam rather than
/// against a vendor, and so the shipped build can send nothing without every
/// call site knowing.
abstract interface class TelemetrySink {
  /// Whether this sink can send anything at all.
  ///
  /// Distinct from consent: a sink may be unavailable because no analytics
  /// service is configured, which is a different fact from a resident declining.
  bool get isAvailable;

  Future<void> send(TelemetrySignal signal);

  /// Reports a crash or an unhandled error.
  Future<void> reportCrash(CrashReport report);
}

/// The only sink this app ships.
///
/// ---
///
/// **No analytics SDK is wired, and that is the decision rather than an
/// omission.** Three reasons, in order of weight:
///
/// 1. **There is nowhere to send.** The backend publishes no telemetry endpoint,
///    and the municipality has commissioned no analytics service. Adding one
///    would be this client choosing where Taytay residents' usage data lives.
/// 2. **A third-party analytics SDK is a data-processor decision.** Under
///    RA 10173 the LGU is the personal information controller; sending resident
///    usage to Google, Amplitude or anyone else needs a data-sharing agreement
///    the municipality signs, not a line in `pubspec.yaml`.
/// 3. **Every mainstream mobile analytics SDK collects a device identifier by
///    default** — an advertising id, an install id, a resettable device id —
///    which is precisely what the Master Command's "never log IDs" rule exists
///    to prevent, and which is on by default in most of them.
///
/// So the seam is complete, the catalogue is defined, the redaction rules are
/// written and tested, and the sink reports itself unavailable. When the
/// municipality names a service, one class implements this interface and nothing
/// else in the app changes.
final class DisabledTelemetrySink implements TelemetrySink {
  const DisabledTelemetrySink();

  @override
  bool get isAvailable => false;

  @override
  Future<void> send(TelemetrySignal signal) async {}

  @override
  Future<void> reportCrash(CrashReport report) async {}
}

/// A crash or unhandled error, with nothing of the resident left in it.
///
/// ---
///
/// ## Why the message is thrown away
///
/// A Dart exception message routinely **quotes the value that caused it**:
///
/// * `FormatException: Invalid number (at character 1): 09171234567`
/// * `Invalid argument(s): {given_name: Ana, family_name: Dela Cruz}`
/// * `RangeError: Value not in range: household_members[3]`
/// * A `TypeError` from a decoder, carrying the decoded map
///
/// Every one of those is a crash report containing a resident's data, and
/// nobody wrote a line of code to put it there. Redaction by pattern — stripping
/// things that look like phone numbers, stripping things that look like names —
/// is a losing game, because the next message has a shape nobody anticipated.
///
/// So this type has **no field for the message**. The report carries the
/// exception's *type*, the library it came from, and a stack whose frames name
/// functions and files. That is what a fix is actually made from; the message
/// almost never is.
@immutable
class CrashReport {
  const CrashReport({
    required this.errorType,
    required this.frames,
    this.library,
    this.fatal = false,
  });

  /// The exception's runtime type — `FormatException`, `StateError`. A type
  /// name is written by a programmer, never by a resident.
  final String errorType;

  /// Stack frames, scrubbed. See `CrashRedaction.redactStack`.
  final List<String> frames;

  /// Flutter's own label for where it happened — "widgets library".
  final String? library;

  final bool fatal;

  @override
  String toString() => 'CrashReport($errorType, ${frames.length} frames)';
}

/// Turns an error and a stack into something safe to send.
///
/// The one place this conversion happens, so there is one place to review.
abstract final class CrashRedaction {
  /// Frames kept from the top of the stack.
  ///
  /// Deep frames are framework internals that say nothing about the defect, and
  /// a shorter report is a smaller surface.
  static const int maxFrames = 24;

  /// Builds a report from an error, keeping only what a fix needs.
  static CrashReport describe(
    Object error,
    StackTrace? stack, {
    String? library,
    bool fatal = false,
  }) => CrashReport(
    // `runtimeType`, never `toString()`: the first is the class name, the
    // second is the class name **and the offending value**.
    errorType: error.runtimeType.toString(),
    frames: redactStack(stack),
    library: library,
    fatal: fatal,
  );

  /// Scrubs a stack trace into a list of frames.
  ///
  /// Two things go:
  ///
  /// * **Absolute filesystem paths.** A release stack can carry the build
  ///   machine's home directory, which names a person. `file:///C:/Users/ana/...`
  ///   becomes `.../lib/...`.
  /// * **Anything past [maxFrames].**
  ///
  /// What stays is `package:` and `dart:` frames, which name functions and
  /// source files — the part a fix is made from.
  static List<String> redactStack(StackTrace? stack) {
    if (stack == null) return const <String>[];

    return stack
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(maxFrames)
        .map(_scrubPaths)
        .toList(growable: false);
  }

  static final RegExp _absolutePath = RegExp(
    // file:///C:/Users/someone/project/lib/x.dart  and  /home/someone/lib/x.dart
    r'(file://)?/?([A-Za-z]:)?[/\\](?:[^/\\\s]+[/\\])+(?=lib[/\\]|test[/\\])',
  );

  static final RegExp _remainingAbsolute = RegExp(
    r'(file://)?/?([A-Za-z]:)?[/\\](?:[^/\\\s]+[/\\]){2,}',
  );

  static String _scrubPaths(String frame) {
    var scrubbed = frame.replaceAll(_absolutePath, '');
    // A path that never reaches `lib/` or `test/` — a pub cache entry, an SDK
    // path — still has directories in it, and one of them may be a username.
    scrubbed = scrubbed.replaceAll(_remainingAbsolute, '');
    return scrubbed;
  }

  /// The telemetry category for a failure, from its **kind**.
  ///
  /// Never from `residentMessage` and never from the server's `message`.
  static TelemetryResult resultOf(AppFailure? failure) => switch (failure) {
    null => TelemetryResult.succeeded,
    NetworkFailure() => TelemetryResult.network,
    TimeoutFailure() => TelemetryResult.timeout,
    UnauthenticatedFailure() => TelemetryResult.unauthenticated,
    ForbiddenFailure() => TelemetryResult.forbidden,
    NotFoundFailure() => TelemetryResult.notFound,
    ValidationFailure() => TelemetryResult.validation,
    ConflictFailure() => TelemetryResult.conflict,
    RateLimitedFailure() => TelemetryResult.rateLimited,
    ServerFailure() => TelemetryResult.server,
    ContractFailure() => TelemetryResult.contract,
    UnexpectedFailure() => TelemetryResult.unexpected,
  };
}

/// The app's one telemetry entry point.
///
/// ---
///
/// ## Off by default, and off unless three things agree
///
/// A signal is sent only when **the resident has granted consent**, **the build
/// permits telemetry**, and **a sink is available**. Any one of them absent and
/// [record] returns without doing anything. That ordering is deliberate: consent
/// is checked first, so a resident who declined is never even the subject of a
/// question about whether the build allows it.
///
/// The shipped configuration fails all three. Consent starts at
/// [TelemetryConsent.notAsked], no analytics service is configured, and the only
/// sink reports itself unavailable — so the app currently sends nothing at all,
/// which is the state every test in this repository runs in and therefore the
/// state that is actually proven to work.
///
/// ## Why it never throws
///
/// Instrumentation that can break a submission is worse than no instrumentation.
/// Every path here swallows, and a sink that throws is disabled for the rest of
/// the process rather than being given another chance to take a screen down.
class Telemetry extends ChangeNotifier {
  Telemetry({
    TelemetrySink sink = const DisabledTelemetrySink(),
    SecretStore? secrets,
    bool allowedByBuild = true,
  }) : _sink = sink,
       _secrets = secrets,
       _allowedByBuild = allowedByBuild;

  /// Where the resident's answer is kept.
  ///
  /// The same store the launch state uses. Not a credential, but it belongs
  /// with the app's other durable device-local answers rather than in a second
  /// mechanism nobody remembers to clear.
  static const String consentKey = 'telemetry_consent';

  TelemetrySink _sink;
  final SecretStore? _secrets;

  /// Whether this build permits telemetry at all.
  ///
  /// A product/policy switch above consent: a build the municipality has not
  /// cleared for analytics collects nothing even from a resident who agreed.
  final bool _allowedByBuild;

  TelemetryConsent _consent = TelemetryConsent.notAsked;
  bool _sinkFailed = false;

  TelemetryConsent get consent => _consent;

  /// True only when everything agrees.
  bool get isCollecting =>
      _consent == TelemetryConsent.granted &&
      _allowedByBuild &&
      _sink.isAvailable &&
      !_sinkFailed;

  /// Whether it is worth asking the resident.
  ///
  /// False when they have already answered, when the build forbids it, or when
  /// there is nowhere to send — asking for permission to do something the app
  /// cannot do is a dialog that costs trust and buys nothing.
  bool get shouldAskForConsent =>
      _consent == TelemetryConsent.notAsked &&
      _allowedByBuild &&
      _sink.isAvailable;

  /// Reads the stored answer. Safe to call more than once.
  Future<void> restore() async {
    final stored = await _secrets?.read(consentKey);
    _consent = TelemetryConsent.parse(stored);
    notifyListeners();
  }

  /// Records the resident's answer and honours it immediately.
  Future<void> setConsent(TelemetryConsent consent) async {
    _consent = consent;
    await _secrets?.write(consentKey, consent.wireValue);
    notifyListeners();
  }

  /// Sends one signal, if everything agrees.
  ///
  /// Returns whether it was sent, which is what the tests assert on.
  Future<bool> record(TelemetrySignal signal) async {
    if (!isCollecting) return false;
    try {
      await _sink.send(signal);
      return true;
    } on Object catch (_) {
      // A sink that throws does not get to do it twice.
      _sinkFailed = true;
      return false;
    }
  }

  /// Reports a crash.
  ///
  /// **Consent applies here too.** A crash report is still data about a
  /// resident's device and session, and a government app that collected it from
  /// someone who declined would be treating "analytics" and "diagnostics" as
  /// different words for the same promise.
  Future<bool> recordCrash(
    Object error,
    StackTrace? stack, {
    String? library,
    bool fatal = false,
  }) async {
    if (!isCollecting) return false;
    try {
      await _sink.reportCrash(
        CrashRedaction.describe(error, stack, library: library, fatal: fatal),
      );
      return true;
    } on Object catch (_) {
      _sinkFailed = true;
      return false;
    }
  }

  /// Replaces the sink. For tests and for the day a service is configured.
  @visibleForTesting
  void useSink(TelemetrySink sink) {
    _sink = sink;
    _sinkFailed = false;
    notifyListeners();
  }
}
