import 'dart:async';
import 'dart:math';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter/foundation.dart';

import '../api/change_stream.dart';
import '../result/result.dart';
import '../session/session_controller.dart';
import '../session/session_state.dart';
import 'live_message.dart';
import 'sse_parser.dart';

/// Opens the server's change stream. `ApiClient.openChangeStream` in the app.
typedef ChangeStreamOpener = Future<ChangeStreamOpening> Function();

/// Where the change stream stands. For diagnostics and tests; no screen
/// shows it.
enum LiveStatus {
  /// No stream will be opened: this build or this server offers none.
  off,

  /// Not wanted now: the app is in the background, or nobody is signed in.
  idle,

  /// Opening.
  connecting,

  /// Open and reading.
  open,

  /// Dropped; waiting out the backoff before opening again.
  waiting,
}

/// A screen's registration with [LiveUpdates.listen]. Cancel it with the
/// screen.
class LiveSubscription {
  LiveSubscription._(this._cancel);

  final void Function() _cancel;
  bool _cancelled = false;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancel();
  }
}

/// Screens update themselves when the office changes their data (D-218).
///
/// ---
///
/// ## What this class does
///
/// It holds the server's change stream (`GET changes`, DL-222) open **only
/// while the app is in the foreground and somebody is signed in**, and tells
/// each screen when one of its topics changed, so the screen re-reads through
/// its normal, authorised endpoint. A hint names topics and nothing else.
///
/// * **No polling, ever.** When the stream is not offered (a `404` or `501`
///   from an older API) live updates are off, and screens re-read only when
///   the app comes back to the foreground. A resident's battery and load are
///   not spent asking a server that has nothing new.
/// * **No push.** Nothing is received while the app is in the background.
/// * **Re-read on return.** Coming back to the foreground re-reads every
///   screen that listens, once the stream is open again, so nothing that
///   changed while the app was away stays stale.
/// * **Re-read after a gap.** Every reconnect after the first `ready`, and
///   every `resync`, re-reads every screen that listens: the server may have
///   changed something while no stream was open.
/// * **Backoff with jitter** from one second to thirty, never shorter than
///   the server's `retry:`; at once after `expired`, which the server sends
///   before it closes a stream at the token's expiry.
/// * **Throttled per screen** to one re-read every two seconds, the first at
///   once and the last at the end of the window, so a burst of changes is
///   one or two reads rather than ten.
///
/// Nothing here writes, queues or retries a write, and a hint is never taken
/// as proof that anything was saved (DL-87, DL-118).
class LiveUpdates extends ChangeNotifier {
  LiveUpdates({
    required ChangeStreamOpener open,
    required SessionController session,
    Random? random,
    DateTime Function()? clock,
    this.throttle = const Duration(seconds: 2),
    this.idleTimeout = const Duration(seconds: 60),
    this.resumeGrace = const Duration(seconds: 3),
  }) : _open = open,
       _session = session,
       _random = random ?? Random(),
       _clock = clock ?? DateTime.now {
    session.addListener(_onSession);
    _accountId = _signedInAccount();
  }

  /// Never connects and never calls a listener. For builds with no server
  /// (dev mock data) and for tests that build the dependencies by hand.
  LiveUpdates.disabled()
    : _open = null,
      _session = null,
      _random = Random(),
      _clock = DateTime.now,
      throttle = const Duration(seconds: 2),
      idleTimeout = const Duration(seconds: 60),
      resumeGrace = const Duration(seconds: 3) {
    _status = LiveStatus.off;
  }

  /// Whether `AppDependencies.build` may hold a change stream at all.
  ///
  /// Production leaves this true. The test suite sets it false, as it does
  /// `WelcomeMotion.enabled`: a stream is never meant to end, and a test that
  /// finishes with one being opened leaves its timers behind. A test that is
  /// about live updates constructs its own [LiveUpdates], which this does not
  /// touch.
  static bool enabledByDefault = true;

  /// The shortest gap between two re-reads of one screen.
  final Duration throttle;

  /// How long an open stream may stay silent before it is presumed dead.
  ///
  /// The server sends a comment every 25 seconds. A connection that has
  /// carried nothing for longer than two of those is a half-open socket (a
  /// phone that changed networks), which would otherwise never report an
  /// error.
  final Duration idleTimeout;

  /// How long a return to the foreground waits for the stream's `ready`
  /// before re-reading anyway. Waiting for `ready` means one re-read covers
  /// both the time away and the moment the stream opened.
  final Duration resumeGrace;

  static const Duration _minimumDelay = Duration(seconds: 1);
  static const Duration _maximumDelay = Duration(seconds: 30);

  final ChangeStreamOpener? _open;
  final SessionController? _session;
  final Random _random;
  final DateTime Function() _clock;

  LiveStatus _status = LiveStatus.idle;
  LiveStatus get status => _status;

  Set<String> _readyTopics = const <String>{};

  /// What the server said, in its last `ready`, this connection can receive.
  Set<String> get readyTopics => _readyTopics;

  final List<_LiveListener> _listeners = <_LiveListener>[];

  String? _accountId;
  bool _foreground = false;
  bool _everForeground = false;
  bool _notOffered = false;
  bool _disposed = false;

  /// Bumped on every disconnect, so callbacks from an old stream are ignored.
  int _generation = 0;
  StreamSubscription<String>? _subscription;
  SseParser? _parser;
  bool _readyThisConnection = false;
  bool _everReady = false;
  bool _resumePending = false;
  int _attempt = 0;
  Duration? _serverRetry;
  Timer? _retryTimer;
  Timer? _watchdog;
  Timer? _resumeTimer;

  /// Registers [onChange] for [topics].
  ///
  /// It runs when any of [topics] changes, when the stream reconnects after a
  /// gap or says `resync`, and when the app comes back to the foreground —
  /// at most once per [throttle], the first at once and the last when the
  /// window ends.
  LiveSubscription listen(Set<String> topics, VoidCallback onChange) {
    final _LiveListener listener = _LiveListener(
      Set<String>.unmodifiable(topics),
      onChange,
      throttle,
      _clock,
    );
    _listeners.add(listener);
    return LiveSubscription._(() {
      listener.cancel();
      _listeners.remove(listener);
    });
  }

  /// Follows the app's lifecycle. Only `resumed` is the foreground.
  void handleLifecycle(AppLifecycleState state) {
    if (_disposed) return;
    final bool foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (!foreground) {
      _resumePending = false;
      _cancelResumeTimer();
      _disconnect();
      return;
    }
    final bool returning = _everForeground;
    _everForeground = true;
    _attempt = 0;
    if (returning) {
      _resumed();
    } else {
      _reconcile();
    }
  }

  bool get _wanted =>
      _open != null &&
      !_notOffered &&
      !_disposed &&
      _foreground &&
      _accountId != null;

  String? _signedInAccount() => switch (_session?.state) {
    AuthenticatedSession(:final ResidentSession resident) => resident.accountId,
    _ => null,
  };

  void _onSession() {
    final String? account = _signedInAccount();
    if (account == _accountId) return;
    _accountId = account;
    // A different account is a different stream, and its first `ready` is
    // not a reconnect: the screens loaded for this account a moment ago.
    _everReady = false;
    _attempt = 0;
    _disconnect();
    _reconcile();
  }

  void _resumed() {
    if (!_wanted) {
      // Signed out, or no stream offered: re-read now, once.
      _emitAll();
      return;
    }
    _resumePending = true;
    _cancelResumeTimer();
    _resumeTimer = Timer(resumeGrace, _flushResume);
    _reconcile();
  }

  void _flushResume() {
    _cancelResumeTimer();
    if (!_resumePending) return;
    _resumePending = false;
    _emitAll();
  }

  void _cancelResumeTimer() {
    _resumeTimer?.cancel();
    _resumeTimer = null;
  }

  void _reconcile() {
    if (!_wanted) {
      _disconnect();
      return;
    }
    if (_status == LiveStatus.idle || _status == LiveStatus.off) {
      unawaited(_connect());
    }
  }

  Future<void> _connect() async {
    final ChangeStreamOpener? open = _open;
    if (open == null) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    final int generation = ++_generation;
    _setStatus(LiveStatus.connecting);

    final ChangeStreamOpening opening = await open();
    if (generation != _generation || !_wanted) {
      if (opening case ChangeStreamOpen(:final Stream<String> text)) {
        unawaited(text.listen(null).cancel());
      }
      return;
    }

    switch (opening) {
      case ChangeStreamNotOffered():
        _notOffered = true;
        _setStatus(LiveStatus.off);
        _flushResume();
      case ChangeStreamFailed(:final AppFailure failure):
        _flushResume();
        if (failure.isRetryable) {
          // No connection, a timeout, a busy or failing server: worth another
          // try after the backoff.
          _scheduleReconnect();
        } else {
          // A refusal that asking again cannot change: a 401 the session
          // layer has already handled, a closed or deactivated account (403),
          // or a request the server will not take. Wait for the next sign-in
          // or the next return to the foreground.
          _setStatus(LiveStatus.idle);
        }
      case ChangeStreamOpen(:final Stream<String> text):
        _parser = SseParser();
        _readyThisConnection = false;
        _subscription = text.listen(
          (String chunk) => _onChunk(generation, chunk),
          onError: (Object _) => _onDropped(generation),
          onDone: () => _onDropped(generation),
          cancelOnError: true,
        );
        _setStatus(LiveStatus.open);
        _armWatchdog(generation);
    }
  }

  void _onChunk(int generation, String chunk) {
    if (generation != _generation) return;
    _armWatchdog(generation);
    final SseParser? parser = _parser;
    if (parser == null) return;
    final List<SseEvent> events = parser.add(chunk);
    _serverRetry = parser.retry ?? _serverRetry;
    for (final SseEvent event in events) {
      if (generation != _generation) return;
      final LiveMessage? message = LiveMessage.from(event);
      if (message != null) _onMessage(message);
    }
  }

  void _onMessage(LiveMessage message) {
    switch (message) {
      case LiveReady(:final Set<String> topics):
        _readyTopics = Set<String>.unmodifiable(topics);
        _readyThisConnection = true;
        _attempt = 0;
        final bool reread = _everReady || _resumePending;
        _everReady = true;
        _resumePending = false;
        _cancelResumeTimer();
        if (reread) _emitAll();
      case LiveChange(:final Set<String> topics):
        _emitTopics(topics);
      case LiveResync():
        _emitAll();
      case LiveExpired():
        final bool reachedReady = _readyThisConnection;
        _closeStream();
        if (!_wanted) {
          _setStatus(LiveStatus.idle);
        } else if (reachedReady) {
          unawaited(_connect());
        } else {
          // Expired before it was ever ready: opening again at once could
          // loop. Back off like any other drop.
          _scheduleReconnect();
        }
    }
  }

  void _onDropped(int generation) {
    if (generation != _generation) return;
    _closeStream();
    if (_wanted) {
      _scheduleReconnect();
    } else {
      _setStatus(LiveStatus.idle);
    }
  }

  void _armWatchdog(int generation) {
    _watchdog?.cancel();
    _watchdog = Timer(idleTimeout, () => _onDropped(generation));
  }

  void _scheduleReconnect() {
    _retryTimer?.cancel();
    final Duration delay = delayFor(_attempt);
    _attempt++;
    _setStatus(LiveStatus.waiting);
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (_wanted) unawaited(_connect());
    });
  }

  /// The wait before reconnect number [attempt] (from zero).
  ///
  /// Doubles from one second to thirty, then spread by a quarter either way
  /// so that a server restart is not met by every phone at the same instant.
  /// Never shorter than the server's own `retry:`.
  @visibleForTesting
  Duration delayFor(int attempt) {
    final int doublings = min(attempt, 5);
    final int base = min(
      _maximumDelay.inMilliseconds,
      _minimumDelay.inMilliseconds * (1 << doublings),
    );
    final double spread = 0.75 + _random.nextDouble() * 0.5;
    final int floor = max(
      _minimumDelay.inMilliseconds,
      min(_serverRetry?.inMilliseconds ?? 0, _maximumDelay.inMilliseconds),
    );
    final int jittered = (base * spread).round();
    return Duration(
      milliseconds: jittered.clamp(floor, _maximumDelay.inMilliseconds),
    );
  }

  /// Closes the current stream, if any, and ignores anything still in flight.
  void _closeStream() {
    _generation++;
    _watchdog?.cancel();
    _watchdog = null;
    final Future<void>? cancelled = _subscription?.cancel();
    _subscription = null;
    _parser = null;
    _readyThisConnection = false;
    if (cancelled != null) unawaited(cancelled);
  }

  void _disconnect() {
    _closeStream();
    _retryTimer?.cancel();
    _retryTimer = null;
    _setStatus(_notOffered || _open == null ? LiveStatus.off : LiveStatus.idle);
  }

  void _emitTopics(Set<String> topics) {
    if (topics.isEmpty || _open == null) return;
    for (final _LiveListener listener in List<_LiveListener>.of(_listeners)) {
      if (listener.topics.any(topics.contains)) listener.fire();
    }
  }

  void _emitAll() {
    if (_open == null) return;
    for (final _LiveListener listener in List<_LiveListener>.of(_listeners)) {
      listener.fire();
    }
  }

  void _setStatus(LiveStatus next) {
    if (_status == next || _disposed) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session?.removeListener(_onSession);
    _cancelResumeTimer();
    _disconnect();
    for (final _LiveListener listener in _listeners) {
      listener.cancel();
    }
    _listeners.clear();
    super.dispose();
  }

  @override
  String toString() => 'LiveUpdates(${_status.name})';
}

/// One screen's callback, throttled: at once when it has not run for a
/// window, otherwise once when the window ends, however many changes arrived
/// in it. No timer is held unless a call is owed.
class _LiveListener {
  _LiveListener(this.topics, this._onChange, this._throttle, this._clock);

  final Set<String> topics;
  final VoidCallback _onChange;
  final Duration _throttle;
  final DateTime Function() _clock;

  DateTime? _lastRun;
  Timer? _trailing;
  bool _cancelled = false;

  void fire() {
    if (_cancelled || _trailing != null) return;
    final DateTime now = _clock();
    final DateTime? last = _lastRun;
    final Duration since = last == null ? _throttle : now.difference(last);
    if (since >= _throttle || since.isNegative) {
      _run(now);
      return;
    }
    _trailing = Timer(_throttle - since, () {
      _trailing = null;
      if (!_cancelled) _run(_clock());
    });
  }

  void _run(DateTime now) {
    _lastRun = now;
    try {
      _onChange();
    } on Object catch (error, stack) {
      // One screen's failure must not stop the others hearing the change.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'live updates',
        ),
      );
    }
  }

  void cancel() {
    _cancelled = true;
    _trailing?.cancel();
    _trailing = null;
  }
}
