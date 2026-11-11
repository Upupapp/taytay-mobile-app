import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../../profile/domain/resident_profile_repository.dart';
import '../../verification/domain/verification_repository.dart';
import '../../verification/domain/verification_status_detail.dart';
import '../domain/card_preparation.dart';
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
/// is painted from memory only while `qr.isLive`. A timer fires at
/// `qr.expires_at`; the modules come down and the card is loaded again. A
/// refetch that is also past its expiry stays on "Refreshing code…" and is
/// not painted. A 404 or a null card is "Your card is being prepared"
/// (D-207): its steps are dated from `GET /me` and the current verification
/// request, read once and only when there is no card, and a step whose date
/// was not sent (or whose read failed) is drawn without one. The portrait
/// is `GET /media/{id}/content` when `photo_media_id` is set. A dev mock
/// keeps the placeholder. A failed or missing read keeps it too.
class DigitalIdScreen extends StatefulWidget {
  const DigitalIdScreen({
    super.key,
    this.repository,
    this.verificationRepository,
    this.profileRepository,
    this.now,
    this.sample,
  });

  /// The office a resident without a card writes to: the slug the Node API
  /// gives the MSWDO (`GET /offices/mswdo`), the one that issues cards.
  static const String issuingOffice = 'mswdo';

  /// Set by tests. The app reads [CredentialRepository] from the scope.
  final CredentialRepository? repository;

  /// Set by tests. The app reads both from the scope; without either, the
  /// steps of a card being prepared carry no dates.
  final VerificationRepository? verificationRepository;
  final ResidentProfileRepository? profileRepository;

  /// Set by tests. The app uses the device clock.
  final DateTime Function()? now;

  /// Set by tests. A dev mock build marks the illustration values.
  final bool? sample;

  @override
  State<DigitalIdScreen> createState() => _DigitalIdScreenState();
}

class _DigitalIdScreenState extends State<DigitalIdScreen>
    with WidgetsBindingObserver {
  bool _started = false;
  CredentialRepository? _repository;
  VerificationRepository? _verification;
  ResidentProfileRepository? _profile;
  ResidentCredential? _card;
  bool _loaded = false;
  String? _name;
  AppFailure? _failure;
  CardPreparation _preparation = CardPreparation.unknown;
  bool _preparationRead = false;
  Timer? _timer;

  /// A dead code is loaded once more. A second dead result stays on the
  /// refreshing state so the load does not chain.
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
    final AppDependencies? dependencies = context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>()
        ?.dependencies;
    _verification =
        widget.verificationRepository ?? dependencies?.verificationRepository;
    _profile =
        widget.profileRepository ?? dependencies?.residentProfileRepository;
    if (_started) return;
    _started = true;
    if (_repository == null) return;
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _gaveUpOnDeadQr = false;
    _scheduleQrRefresh();
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
    if (cardResult case Ok(value: null) when !_preparationRead) {
      // Before the page is shown, so the dates do not arrive after it.
      final CardPreparation preparation = await _readPreparation();
      if (!mounted || generation != _generation) return;
      _preparation = preparation;
      _preparationRead = true;
    }
    setState(() {
      _loaded = true;
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

  /// The dates the verification screen shows, from the same two reads. A
  /// failed read is a step without a date, never an error page: the card's
  /// own answer has already come back.
  Future<CardPreparation> _readPreparation() async {
    final VerificationRepository? verification = _verification;
    final ResidentProfileRepository? profile = _profile;
    final Future<Result<VerificationStatusDetail>>? statusFuture = verification
        ?.loadOwnStatusDetail();
    final Future<Result<ResidentProfileDetail>>? profileFuture = profile
        ?.loadOwnDetail();
    final Result<VerificationStatusDetail>? status = await statusFuture;
    final Result<ResidentProfileDetail>? detail = await profileFuture;
    return CardPreparation.from(
      profile: detail?.valueOrNull,
      verification: status?.valueOrNull,
    );
  }

  void _messageOffice() {
    unawaited(
      context.pushNamed(
        AppRoute.officeCompose.routeName,
        pathParameters: <String, String>{
          'officeId': DigitalIdScreen.issuingOffice,
        },
      ),
    );
  }

  void _scheduleQrRefresh() {
    _timer?.cancel();
    _timer = null;
    final PresentationArtifact? qr = _card?.qr;
    if (qr == null) return;
    final DateTime now = _clock();
    if (qr.isLive(now)) {
      _gaveUpOnDeadQr = false;
      final DateTime? expiry = qr.expiresAt;
      if (expiry == null) return;
      final Duration remaining = expiry.toUtc().difference(now.toUtc());
      if (remaining <= Duration.zero) return;
      _timer = Timer(remaining, () {
        if (!mounted) return;
        // This load is the refresh. A dead result must not start another.
        _gaveUpOnDeadQr = true;
        setState(() {});
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
    final AppDependencies? dependencies = context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>()
        ?.dependencies;
    return DigitalIdView(
      card: _card,
      name: _name,
      now: _clock(),
      sample: _sample(context),
      failure: _failure,
      environment: _environment(context),
      onRetry: _failure == null ? null : () => unawaited(_load()),
      loading: _repository != null && !_loaded,
      preparation: _preparation,
      onMessageOffice: _messageOffice,
      loadPhoto: dependencies == null || dependencies.config.usesMockData
          ? null
          : dependencies.mediaBytes.mediaContent,
    );
  }
}
