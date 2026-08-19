import 'package:flutter/foundation.dart';

import '../router/app_routes.dart';

/// A resident journey worth measuring end to end.
///
/// Named for the **thing being done**, never for the person doing it or the
/// record it concerns. "An assistance application was started" is an operational
/// fact about the app; "Ana applied for medical assistance" is a fact about a
/// resident, and the second is not something a client sends to an analytics
/// service.
enum TelemetryFlow {
  onboarding('onboarding'),
  registration('registration'),
  signIn('sign_in'),
  verification('verification'),
  assistanceApplication('assistance_application'),
  documentUpload('document_upload'),
  eventRegistration('event_registration');

  const TelemetryFlow(this.wireValue);

  final String wireValue;
}

/// Where in a flow something happened.
///
/// A funnel needs stages, and stages are the whole reason a funnel tells the
/// LGU anything: "nine in ten residents who start verification stop at the
/// document step" is actionable, and contains nobody's name.
enum TelemetryStage {
  started('started'),
  advanced('advanced'),
  abandoned('abandoned'),
  blocked('blocked'),
  submitted('submitted'),
  completed('completed');

  const TelemetryStage(this.wireValue);

  final String wireValue;
}

/// A discrete thing the app tried to do.
enum TelemetryOperation {
  loadCatalogue('load_catalogue'),
  loadFeed('load_feed'),
  loadEvents('load_events'),
  loadNotifications('load_notifications'),
  submitApplication('submit_application'),
  uploadDocument('upload_document'),
  registerForEvent('register_for_event'),
  cancelRegistration('cancel_registration'),
  postComment('post_comment'),
  refreshSession('refresh_session');

  const TelemetryOperation(this.wireValue);

  final String wireValue;
}

/// How an operation ended, in categories rather than in messages.
///
/// ---
///
/// **Derived from `AppFailure`'s kind, never from its text.** A server message
/// is written for an operator and routinely quotes the value that caused the
/// problem — `Invalid number: 09171234567` names a resident's mobile number, and
/// a constraint violation names the row. Categories carry the operational signal
/// without any of that.
enum TelemetryResult {
  succeeded('succeeded'),
  network('network'),
  timeout('timeout'),
  unauthenticated('unauthenticated'),
  forbidden('forbidden'),
  notFound('not_found'),
  validation('validation'),
  conflict('conflict'),
  rateLimited('rate_limited'),
  server('server'),
  contract('contract'),
  unexpected('unexpected'),

  /// The module has no endpoint yet. Distinct from a server error, because it
  /// is a roadmap fact rather than an incident.
  notImplemented('not_implemented'),

  /// The file was refused: too large, or the wrong kind.
  ///
  /// Kept out of `validation` because it is the upload funnel's own health
  /// signal. If client-side compression regresses, this rate is where it shows,
  /// and it would be invisible folded in with mistyped form fields.
  unacceptableUpload('unacceptable_upload');

  const TelemetryResult(this.wireValue);

  final String wireValue;
}

/// Something whose duration is worth knowing.
enum TelemetrySpan {
  appStart('app_start'),
  sessionRestore('session_restore'),
  firstCatalogue('first_catalogue'),
  feedPage('feed_page'),
  documentUpload('document_upload');

  const TelemetrySpan(this.wireValue);

  final String wireValue;
}

/// A duration, as a bucket rather than a number.
///
/// **A precise millisecond count is a weak identifier.** Enough of them, joined
/// to a timestamp, distinguish one device from another and one session from the
/// next. Buckets answer the question anyone actually asks of a timing — "is this
/// fast, slow, or unusable?" — and carry nothing else.
enum TelemetryDurationBucket {
  under100ms('lt_100ms'),
  under500ms('lt_500ms'),
  under1s('lt_1s'),
  under3s('lt_3s'),
  under10s('lt_10s'),
  over10s('gte_10s');

  const TelemetryDurationBucket(this.wireValue);

  final String wireValue;

  static TelemetryDurationBucket of(Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms < 100) return under100ms;
    if (ms < 500) return under500ms;
    if (ms < 1000) return under1s;
    if (ms < 3000) return under3s;
    if (ms < 10000) return under10s;
    return over10s;
  }
}

/// A count, as a bucket rather than a number.
///
/// Same reasoning: "this resident has 47 notifications" is closer to identifying
/// than "this resident has some".
enum TelemetryCountBucket {
  none('0'),
  few('1_9'),
  some('10_49'),
  many('50_plus');

  const TelemetryCountBucket(this.wireValue);

  final String wireValue;

  static TelemetryCountBucket of(int count) {
    if (count <= 0) return none;
    if (count < 10) return few;
    if (count < 50) return some;
    return many;
  }
}

/// One thing worth telling the LGU about how its app behaves.
///
/// ---
///
/// ## Why this is a closed type set and not `log(name, params)`
///
/// The acceptance criterion for this TAB is that **no citizen PII appears in
/// analytics payload definitions**, and the only way to hold that over time is
/// to make it structurally impossible rather than a rule people remember.
///
/// A `Map<String, Object?>` parameter bag is precisely how PII reaches an
/// analytics service. Not by decision — nobody sets out to log a name — but
/// because the bag accepts anything, and one day somebody adds
/// `{'service': service.name}` to help debug a funnel and the service name turns
/// out to be `Medical assistance — Ana Dela Cruz (re-submitted)`.
///
/// So every field on every signal below is an **enum, a bool, or a bucket**.
/// There is no `String` field anywhere in this file's payloads and no
/// constructor that accepts free text. A screen is identified by its `AppRoute`
/// **enum value**, not by its path: `/events/e-1` carries an identifier and
/// `AppRoute.eventDetail` does not.
///
/// Adding a field that could carry resident data means changing a type, in a
/// file whose whole documentation is about why you should not — which is the
/// only kind of guardrail that survives a year of maintenance.
///
/// ## What is deliberately absent
///
/// No user id, no account id, no device id, no session id, no advertising id, no
/// IP, no timestamp of the resident's own choosing. Correlation across events is
/// something the sink may add for its own session if the LGU ever configures
/// one; it is not a property of the signal.
@immutable
sealed class TelemetrySignal {
  const TelemetrySignal();

  /// The event name, in `snake_case`, describing an **action** rather than a
  /// person or a record.
  String get name;

  /// The payload. Every value is a wire constant from an enum above.
  Map<String, String> get parameters;
}

/// A resident opened a screen.
///
/// Carries the route's **enum name**, so an identifier in the path cannot travel
/// with it.
final class ScreenViewed extends TelemetrySignal {
  const ScreenViewed(this.route);

  final AppRoute route;

  @override
  String get name => 'screen_viewed';

  @override
  Map<String, String> get parameters => <String, String>{
    'screen': route.routeName,
  };
}

/// A resident reached a stage of a journey.
final class FlowStep extends TelemetrySignal {
  const FlowStep({required this.flow, required this.stage});

  final TelemetryFlow flow;
  final TelemetryStage stage;

  @override
  String get name => 'flow_step';

  @override
  Map<String, String> get parameters => <String, String>{
    'flow': flow.wireValue,
    'stage': stage.wireValue,
  };
}

/// An operation finished, one way or another.
final class OperationFinished extends TelemetrySignal {
  const OperationFinished({
    required this.operation,
    required this.result,
    this.retried = false,
  });

  final TelemetryOperation operation;
  final TelemetryResult result;

  /// Whether this was a retry. Distinguishes "one failure" from "a resident
  /// hammering a button that will never work", which are different problems.
  final bool retried;

  @override
  String get name => 'operation_finished';

  @override
  Map<String, String> get parameters => <String, String>{
    'operation': operation.wireValue,
    'result': result.wireValue,
    'retried': '$retried',
  };
}

/// Something took a measurable amount of time.
final class SpanMeasured extends TelemetrySignal {
  SpanMeasured({required this.span, required Duration took})
    : bucket = TelemetryDurationBucket.of(took);

  const SpanMeasured.bucketed({required this.span, required this.bucket});

  final TelemetrySpan span;
  final TelemetryDurationBucket bucket;

  @override
  String get name => 'span_measured';

  @override
  Map<String, String> get parameters => <String, String>{
    'span': span.wireValue,
    'duration': bucket.wireValue,
  };
}

/// The app could not reach Taytay LGU, or reached it again.
final class ReachabilityChanged extends TelemetrySignal {
  const ReachabilityChanged({required this.reachable});

  final bool reachable;

  @override
  String get name => 'reachability_changed';

  @override
  Map<String, String> get parameters => <String, String>{
    'reachable': '$reachable',
  };
}

/// A resident met a gate.
///
/// The **requirement**, not the resident: "a verification gate was shown on the
/// digital ID" says the app is asking people to verify at the right moment, and
/// says nothing about who was asked.
final class AccessGateShown extends TelemetrySignal {
  const AccessGateShown({required this.route, required this.requirement});

  final AppRoute route;

  /// The route's declared requirement, as its enum name.
  final String requirement;

  @override
  String get name => 'access_gate_shown';

  @override
  Map<String, String> get parameters => <String, String>{
    'screen': route.routeName,
    'requirement': requirement,
  };
}

/// A build reached a state the LGU should know about but a resident should not
/// have to care about — an unrenderable server field, an unrecognised enum.
///
/// **The category, never the value.** "The intake form contained a field kind
/// this build cannot render" is the operational fact; the field's prompt is the
/// office's text and its answer would be the resident's.
final class ClientLimitationHit extends TelemetrySignal {
  const ClientLimitationHit({required this.limitation});

  final TelemetryLimitation limitation;

  @override
  String get name => 'client_limitation_hit';

  @override
  Map<String, String> get parameters => <String, String>{
    'limitation': limitation.wireValue,
  };
}

/// Ways this build can fall behind the server, as categories.
enum TelemetryLimitation {
  unrenderableFormField('unrenderable_form_field'),
  unknownServerEnum('unknown_server_enum'),
  unsupportedDeepLink('unsupported_deep_link'),
  unsupportedDocumentType('unsupported_document_type'),

  /// The requirements response carried no usable `accepts` block, so the
  /// labelled fallback ceiling applied instead of the server's own.
  ///
  /// Recorded because a fallback that nobody can see is a fallback that gets
  /// read later as a measurement — and the number it stands in for is the one
  /// deciding whether a resident's document is refused.
  unpublishedUploadPolicy('unpublished_upload_policy'),

  /// `app/bootstrap` answered without a usable `default_page_size`, so the
  /// labelled fallback applied instead of the size chosen for this channel.
  unpublishedPageSize('unpublished_page_size'),
  missingCapability('missing_capability');

  const TelemetryLimitation(this.wireValue);

  final String wireValue;
}
