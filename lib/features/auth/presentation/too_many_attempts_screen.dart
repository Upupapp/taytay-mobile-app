import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/code_exchange.dart';
import 'auth_bits.dart';

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

  /// The address the hold is for, or empty when it names none.
  String get _email {
    if (_painted) return AuthSample.email;
    return widget.hold?.email ?? '';
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
        final String unavailable = AppStrings.of(
          context,
        ).authCodeServiceUnavailable;
        setState(() {
          _busy = false;
          if (next.unavailable) {
            _status = unavailable;
            return;
          }
          if (next.limited && next.resendAt != null) {
            _resumeAt = next.resendAt!;
            _status = null;
            _arm();
            return;
          }
          _status = unavailable;
        });
    }
  }

  /// The notice pattern on the form page (RegTerms): the wave header says
  /// what happened, the clock counts down in a tinted card, and the request
  /// stays locked until the server's hold is over. Nothing here shortens the
  /// hold or hints at a way round it.
  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final bool ready = _ready;
    final String? status = _status;
    final String lead = ready
        ? strings.authHoldLeadReady
        : strings.authHoldLeadLocked;
    final String email = _email.isEmpty ? strings.authYourEmail : _email;
    return AuthFormPage(
      title: ready ? strings.authHoldTitleReady : strings.authHoldTitleLocked,
      subtitle: ready
          ? strings.authHoldSubtitleReady
          : strings.authHoldSubtitleLocked,
      onBack: () => context.canPop()
          ? context.pop()
          : context.goNamed(AppRoute.signIn.routeName),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (ready)
            PrimaryButton(
              kind: TaytayButtonKind.signIn,
              label: strings.authRequestNewCode,
              onPressed: _busy
                  ? null
                  : _painted
                  ? () {}
                  : _request,
            )
          else
            const _LockedButton(),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: AppTypography.fieldHelp.copyWith(
                  fontWeight: AppTypography.strong,
                  color: BrandColors.danger,
                ),
              ),
            ),
          const SizedBox(height: Spacing.xs),
          AuthLink(
            strings.authResetBackToSignIn,
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: lead),
                TextSpan(
                  text: email,
                  style: const TextStyle(fontWeight: AppTypography.black),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
          ),
          const SizedBox(height: Spacing.formGap),
          _HoldClock(ready: ready, label: _clockLabel, remaining: _remaining),
          if (!ready) ...<Widget>[
            const SizedBox(height: Spacing.md),
            SoftNote(
              tone: NoteTone.warning,
              live: false,
              heading: strings.authHoldWhyHeading,
              message: strings.authHoldWhyBody,
            ),
          ],
        ],
      ),
    );
  }
}

/// The countdown (a tinted card: gold while held, green when over): the
/// state in words, the time left in tabular figures, and the hold's
/// progress. One live region says the same in a sentence.
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
    final AppStrings strings = AppStrings.of(context);
    final Color ink = ready ? BrandColors.green : BrandColors.goldInk;
    final String spoken = ready
        ? strings.authHoldSpokenReady
        : strings.authHoldSpokenWaiting(label);
    return Semantics(
      liveRegion: true,
      label: spoken,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ready ? BrandColors.green50 : BrandColors.gold50,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TaytayIcon(
                    icon: ready ? TaytayIcons.checkCircle : TaytayIcons.timer,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: IconSizes.sm,
                    color: ink,
                  ),
                  const SizedBox(width: Spacing.sm - Spacing.xxs),
                  Flexible(
                    child: Text(
                      ready
                          ? strings.authHoldClockReady
                          : strings.authHoldClockWaiting,
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(color: ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.hero.copyWith(
                  color: ready ? BrandColors.green : BrandColors.navy,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: LinearProgressIndicator(
                  value: CodeExchangeRules.holdProgress(remaining),
                  minHeight: Spacing.sm - Spacing.xxs,
                  backgroundColor: BrandColors.white,
                  color: ready ? BrandColors.green : BrandColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The request while the hold lasts: the same button, disabled, with the
/// lock in front of the words. It cannot be pressed.
class _LockedButton extends StatelessWidget {
  const _LockedButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: null,
      icon: const TaytayIcon(
        icon: TaytayIcons.lock,
        semanticLabel: '',
        excludeSemantics: true,
        size: IconSizes.sm,
        color: BrandColors.muted,
      ),
      label: Text(AppStrings.of(context).authRequestNewCode),
    );
  }
}
