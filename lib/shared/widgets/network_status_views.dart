import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_glyphs.dart';
import '../../core/design/typography.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/time/manila_time.dart';
import '../../l10n/app_localizations.dart';
import 'app_banner.dart';
import 'taytay_glyph.dart';

/// The strip that appears when Taytay LGU cannot be reached.
///
/// ---
///
/// **It waits for evidence.** `NetworkMonitor` reports `unknown` until a request
/// has actually been attempted, and does not warn until two requests in a row
/// have failed to arrive. One dropped request on a Philippine mobile connection
/// is ordinary; a banner that flashes on every one of them is a banner residents
/// learn to scroll past, which is worse than no banner at all.
///
/// **It never claims to know why.** "You appear to be offline" is a guess about
/// the resident's phone. What the app actually knows is that its requests are
/// not arriving, so that is what it says.
///
/// **It never appears over a server refusal.** A `403` or a `404` is the server
/// speaking, and telling somebody to check their connection over a permission
/// decision sends them to a load-up stall for nothing.
///
/// **It never says what happened to a send.** The failures that raise it
/// include timeouts and connections that dropped after the request left the
/// phone, when the office may already hold what was sent. It used to promise
/// "nothing has been sent", which was true only for some of them (D-189). Each
/// send says for itself whether it went (D-188).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({this.onRetry, super.key});

  /// Offered when the surface underneath has something to retry.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // A design specimen drawn without the app has no network monitor, so
    // there is nothing to warn about.
    final AppDependenciesScope? scope = context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    if (scope == null) return const SizedBox.shrink();
    final monitor = scope.dependencies.network;

    return AnimatedBuilder(
      animation: monitor,
      builder: (context, _) {
        if (!monitor.shouldWarn) return const SizedBox.shrink();
        final strings = AppStrings.of(context);

        final banner = Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.section,
            Spacing.lg,
            0,
          ),
          child: OfflineNotice(
            title: strings.networkUnreachableTitle,
            message: strings.networkUnreachableMessage,
            retryLabel: strings.actionTryAgain,
            onRetry: onRetry,
          ),
        );

        // Functional motion shortens under reduced motion rather than
        // disappearing: the banner arriving without warning is a jump.
        return AnimatedSize(
          duration: Motion.reduced(context)
              ? MotionTokens.instant
              : MotionTokens.fast,
          curve: MotionTokens.enterEase,
          alignment: Alignment.topCenter,
          child: banner,
        );
      },
    );
  }
}

/// The offline strip itself (CSS `.off` on DirectoryOffline): soft gold, a
/// gold disc with the no-connection glyph, a bold line and a smaller one.
/// [OfflineBanner] shows it when the network monitor has evidence; use this
/// directly only where a screen already knows it is showing saved content.
///
/// The words come from the caller. Both lines are plain [Text], and the strip
/// is a status region, so a screen reader hears it once when it appears.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final String? message = this.message;
    final VoidCallback? onRetry = this.onRetry;
    final String? retryLabel = this.retryLabel;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: BrandColors.gold50,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: BrandColors.gold,
                shape: BoxShape.circle,
              ),
              child: const GlyphIcon(
                TaytayGlyph.cloudOff,
                size: 18,
                color: BrandColors.navy,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        message,
                        style: AppTypography.small.copyWith(
                          color: BrandColors.goldInk,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (onRetry != null && retryLabel != null) ...<Widget>[
              const SizedBox(width: Spacing.sm),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: BrandColors.ink,
                  textStyle: AppTypography.link,
                ),
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Says how old the content underneath is.
///
/// **Used whenever a screen shows something it did not just fetch.** The Master
/// Command asks for last-updated timestamps on cached views, and the reason is
/// specific to a government app: a resident acting on a three-hour-old
/// announcement about a relief distribution needs to know it is three hours old
/// before they walk to the covered court.
///
/// Renders nothing when the content is fresh — a timestamp on every screen is
/// noise, and noise is how the one that matters gets missed.
class StaleContentNotice extends StatelessWidget {
  const StaleContentNotice({
    required this.storedAt,
    this.isFresh = false,
    this.onRefresh,
    super.key,
  });

  /// When the office actually answered.
  final DateTime storedAt;

  /// When true this renders nothing.
  final bool isFresh;

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isFresh) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.history_outlined,
            size: IconSizes.sm,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              // Manila time, like every other LGU timestamp in this app: the
              // phone can be set to any timezone and Taytay is in one. The
              // timestamp is formatted before it reaches the translation, so
              // no locale can reorder a date a resident acts on.
              strings.staleContentMessage(ManilaTime.formatDateTime(storedAt)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onRefresh != null)
            TextButton(
              onPressed: onRefresh,
              child: Text(strings.actionRefresh),
            ),
        ],
      ),
    );
  }
}

/// Marks work the resident finished but the office has not received.
///
/// ---
///
/// ## Why the word is "not sent" and never "saved"
///
/// The Master Command is explicit: a submission must never display success until
/// the backend confirms, and a locally-kept draft has to be labelled clearly as
/// unsent. "Saved" is the word that breaks this — a resident who reads "saved"
/// on an assistance request believes the office has it, stops chasing it, and
/// finds out weeks later that nothing was ever filed.
///
/// So this says what is true from the resident's side: their answers are still
/// on the phone, and Taytay LGU has not confirmed it has them.
///
/// ## Why it says "not confirmed" and never "nothing was filed"
///
/// The notice follows a send that failed, and a send can fail after it left
/// the phone: a timeout, or a connection dropped before the answer. Then the
/// office may already have it, and "nothing was filed" is untrue (D-188). Only
/// the screen that made the send knows which, so this widget says the one thing
/// true of both: it was not confirmed (D-191).
///
/// That sending again cannot file it twice is said only when the caller passes
/// [resendIsSafe]. The widget cannot know whether the send carried an
/// idempotency key kept for its retry, and without one the promise is false.
class UnsentNotice extends StatelessWidget {
  const UnsentNotice({
    required this.what,
    this.resendIsSafe = false,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  /// What is not confirmed, in the resident's terms — "your application",
  /// "your comment", "your registration".
  final String what;

  /// Whether sending [what] again cannot file it twice.
  ///
  /// True only for a send whose idempotency key is kept for every retry of
  /// the same content (`SendKey`), or one idempotent by nature. Defaults to
  /// false: without it, the notice makes no promise about a second send.
  final bool resendIsSafe;

  final VoidCallback? onRetry;

  /// Overrides the default retry wording. Null takes the translated default.
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AppBanner(
      tone: BannerTone.warning,
      title: strings.unsentTitle,
      message: resendIsSafe
          ? '${strings.unsentMessage(what)} ${strings.unsentResendSafe}'
          : strings.unsentMessage(what),
      action: onRetry == null
          ? null
          : TextButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? strings.actionTrySendingAgain),
            ),
    );
  }
}
