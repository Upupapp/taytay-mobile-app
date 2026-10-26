import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/sign_in_field.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_thread.dart';
import '../domain/code_exchange.dart';
import 'auth_bits.dart';
import 'auth_stage.dart';

/// Which `02-14` frame to paint. [waiting] is 14:32. [ready] is `02-14b`.
enum TooManyFixture { live, waiting, ready }

/// `02-14` and `02-14b`. A code lock or a rate limit, driven by the server wait.
class TooManyAttemptsScreen extends StatefulWidget {
  const TooManyAttemptsScreen({
    this.fixture = TooManyFixture.live,
    this.hold,
    this.shownRemaining,
    super.key,
  });

  final TooManyFixture fixture;
  final CodeHold? hold;

  /// Paints [TooManyFixture.waiting] at this remaining time. The capture of
  /// `02-14` leaves it null so the clock stays at 14:32.
  final Duration? shownRemaining;

  @override
  State<TooManyAttemptsScreen> createState() => _TooManyAttemptsScreenState();
}

class _TooManyAttemptsScreenState extends State<TooManyAttemptsScreen> {
  Timer? _clock;
  bool _busy = false;
  String? _status;
  late DateTime _resumeAt;

  bool get _painted => widget.fixture != TooManyFixture.live;

  @override
  void initState() {
    super.initState();
    _resumeAt = widget.hold?.resumeAt ?? DateTime.now();
    _arm();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _arm() {
    _clock?.cancel();
    if (!authClockTicks || _painted || _ready) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_ready) _clock?.cancel();
    });
  }

  Duration get _remaining {
    if (widget.fixture == TooManyFixture.waiting) {
      return widget.shownRemaining ?? const Duration(minutes: 14, seconds: 32);
    }
    if (widget.fixture == TooManyFixture.ready) return Duration.zero;
    final Duration left = _resumeAt.difference(DateTime.now());
    if (left.isNegative) return Duration.zero;
    if (left.inSeconds > CodeExchangeRules.holdWindowSeconds) {
      return const Duration(seconds: CodeExchangeRules.holdWindowSeconds);
    }
    return left;
  }

  bool get _ready => _remaining == Duration.zero;

  String get _email {
    if (_painted) return AuthSample.email;
    final String email = widget.hold?.email ?? '';
    if (email.isEmpty) return 'your email';
    return email;
  }

  String get _clockLabel => CodeExchangeRules.holdClock(_remaining);

  Future<void> _request() async {
    if (!_ready || _busy || _painted) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    final CodeHoldOrigin origin =
        widget.hold?.origin ?? CodeHoldOrigin.passwordReset;
    final result = origin == CodeHoldOrigin.emailVerification
        ? await AppDependencies.of(context).authRepository.sendEmailCode()
        : await AppDependencies.of(
            context,
          ).authRepository.requestPasswordReset(email: _email);
    if (!mounted) return;
    final DateTime now = DateTime.now();
    switch (result) {
      case Ok<CodeAcceptance>(:final value):
        if (origin == CodeHoldOrigin.emailVerification) {
          context.pop(value);
          return;
        }
        context.goNamed(
          AppRoute.resetCode.routeName,
          extra: PasswordResetDraft(
            email: _email,
            issuedAt: now,
            codeExpiresAt: now.add(CodeExchangeRules.codeLife),
            resendAvailableAt: now.add(
              Duration(seconds: value.retryAfterSeconds),
            ),
          ),
        );
      case Err<CodeAcceptance>(:final failure):
        final CodeAttemptView next = const CodeAttemptView().applyFailure(
          failure,
          now,
        );
        setState(() {
          _busy = false;
          if (next.unavailable) {
            _status = CodeAttemptView.unavailableCopy;
            return;
          }
          if (next.limited && next.resendAt != null) {
            _resumeAt = next.resendAt!;
            _status = null;
            _arm();
            return;
          }
          _status = CodeAttemptView.unavailableCopy;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ready = _ready;
    final bool short = MediaQuery.sizeOf(context).height < 800;
    final Widget sheet = Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthCopy(
            eyebrow: ready ? 'Puwede na ulit' : 'Pansamantalang naka-lock',
            title: ready ? 'Subukan ulit ngayon' : 'Masyadong maraming subok',
          ),
          const SizedBox(height: 5.66),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                height: 1.5,
                fontWeight: AppTypography.body,
                color: Color(0xFF4A5470),
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: ready
                      ? 'Puwede ka nang humingi ng bagong code. Ipapadala namin ito sa '
                      : 'Para protektahan ang account mo, pansamantala naming itinigil ang pagpapadala at pag-verify ng code para sa ',
                ),
                TextSpan(
                  text: _email,
                  style: const TextStyle(fontWeight: AppTypography.black),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 13),
          _HoldClock(ready: ready, label: _clockLabel, remaining: _remaining),
          if (!ready) ...<Widget>[
            const SizedBox(height: 21),
            const _WhyBanner(),
          ],
          SizedBox(height: ready ? 10 : 19),
          ready
              ? PrimaryButton(
                  kind: TaytayButtonKind.signIn,
                  label: 'Humingi ng bagong code',
                  onPressed: _busy
                      ? null
                      : _painted
                      ? () {}
                      : _request,
                )
              : const _LockedButton(),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _status!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: AppTypography.strong,
                  color: BrandColors.danger,
                ),
              ),
            ),
          SizedBox(height: ready ? 5 : 4),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: BrandColors.taytayBlue,
              minimumSize: const Size(48, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: AppTypography.black,
              ),
            ),
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
            child: const Text('Bumalik sa Sign in'),
          ),
        ],
      ),
    );
    return AuthStage(
      sheetTop: 252,
      wrapSheet: short,
      arch: ready ? AuthArch.holdReady : AuthArch.holdLock,
      atmosphere: ready
          ? SignInAtmosphere.tooManyReady
          : SignInAtmosphere.tooMany,
      curve: ThreadCurve.reset,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.signIn.routeName),
      child: short ? SingleChildScrollView(child: sheet) : sheet,
    );
  }
}

class _HoldClock extends StatelessWidget {
  const _HoldClock({
    required this.ready,
    required this.label,
    required this.remaining,
  });

  final bool ready;
  final String label;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final Color ink = ready ? const Color(0xFF0F7A4D) : const Color(0xFF6B4600);
    final String spoken = ready
        ? 'Tapos na ang paghihintay. 00:00'
        : 'Subukang muli sa $label';
    return Semantics(
      liveRegion: true,
      label: spoken,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ready ? const Color(0xFFE6F4EC) : const Color(0xFFFFF4D6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ready ? const Color(0xFFBFE3CF) : const Color(0xFFF0D48A),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, ready ? 19 : 12),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TaytayIcon(
                    icon: ready ? TaytayIcons.checkCircle : TaytayIcons.timer,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: 15,
                    color: ready
                        ? const Color(0xFF0F7A4D)
                        : const Color(0xFF8A5A00),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      ready ? 'Tapos na ang paghihintay' : 'Subukang muli sa',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        height: 1,
                        fontWeight: AppTypography.black,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 0),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 40,
                    height: 1,
                    fontWeight: AppTypography.black,
                    letterSpacing: 1,
                    color: ready
                        ? const Color(0xFF0F7A4D)
                        : BrandColors.taytayBlueDark,
                  ),
                ),
              ),
              SizedBox(height: ready ? 13 : 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: CodeExchangeRules.holdProgress(remaining),
                    backgroundColor: const Color(0x1A062358),
                    color: ready
                        ? const Color(0xFF0F7A4D)
                        : const Color(0xFFC9A227),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhyBanner extends StatelessWidget {
  const _WhyBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0D48A)),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TaytayIcon(
              icon: TaytayIcons.info,
              semanticLabel: '',
              excludeSemantics: true,
              size: 18,
              color: Color(0xFF8A5A00),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: AppTypography.strong,
                    color: Color(0xFF6B4600),
                  ),
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Bakit ito nangyari?\n',
                      style: TextStyle(fontWeight: AppTypography.black),
                    ),
                    TextSpan(
                      text:
                          'Masyadong maraming maling code o hiling ng bagong code sa maikling oras. Hindi mo kailangang gumawa ng bagong account.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedButton extends StatelessWidget {
  const _LockedButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      label: 'Humingi ng bagong code',
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFAEB6C8),
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TaytayIcon(
                icon: TaytayIcons.lock,
                semanticLabel: '',
                excludeSemantics: true,
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Humingi ng bagong code',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: AppTypography.black,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
