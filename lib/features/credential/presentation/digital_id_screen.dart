import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/result/result.dart';
import '../domain/credential_repository.dart';
import 'digital_id_canvas.dart';

/// The resident's Taytay digital ID.
///
/// A credential is rendered from what the server issued, never assembled on
/// the device from profile fields. "Valid" is a server-side cryptographic
/// verdict — this screen may display a credential, and it never decides that
/// one is genuine.
///
/// The name is GET /me `name`. It is not stored on the session. The QR token
/// is painted from memory and dropped when the code expires. A 404 or a null
/// card keeps the not-issued card. The portrait media id is not fetched:
/// this client has no media-bytes route for it.
class DigitalIdScreen extends StatefulWidget {
  const DigitalIdScreen({super.key, this.repository, this.now, this.sample});

  /// Set by tests. The app reads [CredentialRepository] from the scope.
  final CredentialRepository? repository;

  /// Set by tests. The app uses the device clock.
  final DateTime Function()? now;

  /// Set by tests. A dev mock build marks the illustration values.
  final bool? sample;

  @override
  State<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

class _DigitalIdScreenState extends State<DigitalIdScreen>
    with WidgetsBindingObserver {
  /// A code that still has longer than this to live is refreshed when the
  /// app resumes, not by a timer. A long timer would hold `pumpAndSettle`.
  static const Duration _refreshWindow = Duration(minutes: 10);

  bool _started = false;
  CredentialRepository? _repository;
  ResidentCredential? _card;
  String? _name;
  AppFailure? _failure;
  Timer? _timer;
  bool _gaveUpOnDeadQr = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository =
        widget.repository ??
        context
            .dependOnInheritedWidgetOfExactType<AppDependenciesScope>()
            ?.dependencies
            .credentialRepository;
    if (_started) return;
    _started = true;
    if (_repository == null) return;
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleQrRefresh();
  }

  DateTime _clock() => widget.now?.call() ?? DateTime.now();

  bool _sample(BuildContext context) {
    final bool? sample = widget.sample;
    if (sample != null) return sample;
    return context
            .dependOnInheritedWidgetOfExactType<AppDependenciesScope>()
            ?.dependencies
            .config
            .usesMockData ??
        false;
  }

  AppEnvironment _environment(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppDependenciesScope>()
            ?.dependencies
            .config
            .environment ??
        AppEnvironment.dev;
  }

  Future<void> _load() async {
    final CredentialRepository? repository = _repository;
    if (repository == null) return;
    final int generation = ++_generation;
    final Future<Result<ResidentCredential?>> cardFuture = repository
        .loadOwnCredential();
    final Future<Result<String?>> nameFuture = repository.loadResidentName();
    final Result<ResidentCredential?> cardResult = await cardFuture;
    final Result<String?> nameResult = await nameFuture;
    if (!mounted || generation != _generation) return;
    setState(() {
      switch (cardResult) {
        case Ok(:final value):
          _failure = null;
          _card = value;
        case Err(:final failure):
          _failure = failure;
          _card = null;
      }
      _name = nameResult.valueOrNull;
    });
    _scheduleQrRefresh();
  }

  void _scheduleQrRefresh() {
    _timer?.cancel();
    _timer = null;
    final PresentationArtifact? qr = _card?.qr;
    final DateTime? expiry = qr?.expiresAt;
    if (qr == null || expiry == null) return;
    final DateTime now = _clock();
    if (qr.isLive(now)) {
      _gaveUpOnDeadQr = false;
      final Duration remaining = expiry.toUtc().difference(now.toUtc());
      if (remaining > _refreshWindow) return;
      _timer = Timer(remaining, () {
        if (!mounted) return;
        unawaited(_load());
      });
      return;
    }
    if (_gaveUpOnDeadQr) return;
    _gaveUpOnDeadQr = true;
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    return DigitalIdView(
      card: _card,
      name: _name,
      now: _clock(),
      sample: _sample(context),
      failure: _failure,
      environment: _environment(context),
      onRetry: _failure == null ? null : () => unawaited(_load()),
    );
  }
}
