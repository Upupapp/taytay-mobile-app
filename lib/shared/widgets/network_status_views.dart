import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/design/design_tokens.dart';
import '../../core/motion/motion_tokens.dart';
import '../../core/time/manila_time.dart';
import '../../l10n/app_localizations.dart';
import 'app_banner.dart';

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
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({this.onRetry, super.key});

  /// Offered when the surface underneath has something to retry.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final monitor = AppDependencies.of(context).network;
    final strings = AppStrings.of(context);

    return AnimatedBuilder(
      animation: monitor,
      builder: (context, _) {
        if (!monitor.shouldWarn) return const SizedBox.shrink();

        final banner = Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            0,
          ),
          child: AppBanner(
            tone: BannerTone.warning,
            title: strings.networkUnreachableTitle,
            message: strings.networkUnreachableMessage,
            action: onRetry == null
                ? null
                : TextButton(
                    onPressed: onRetry,
                    child: Text(strings.actionTryAgain),
                  ),
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
/// on the phone, Taytay LGU does not have them, and the way to change that is to
/// send again.
class UnsentNotice extends StatelessWidget {
  const UnsentNotice({
    required this.what,
    this.onRetry,
    this.retryLabel,
    super.key,
  });

  /// What is unsent, in the resident's terms — "your application", "your
  /// comment", "your registration".
  final String what;

  final VoidCallback? onRetry;

  /// Overrides the default retry wording. Null takes the translated default.
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AppBanner(
      tone: BannerTone.warning,
      title: strings.unsentTitle,
      message: strings.unsentMessage(what),
      action: onRetry == null
          ? null
          : TextButton(
              onPressed: onRetry,
              child: Text(retryLabel ?? strings.actionTrySendingAgain),
            ),
    );
  }
}
