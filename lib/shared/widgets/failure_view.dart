import 'package:flutter/material.dart';

import '../../core/config/app_environment.dart';
import '../../core/design/design_tokens.dart';
import '../../core/result/result.dart';

/// The one way a failure is shown to a resident.
///
/// It renders [AppFailure.residentMessage] — never the server's `message`, which
/// is operator-facing by contract. The correlation id is shown only where it is
/// useful and safe: it is opaque, it identifies a request rather than a person,
/// and quoting it lets the LGU support desk find the exact call.
///
/// In production the id is presented quietly as a reference; in non-production
/// builds the developer-facing detail is shown too, because the alternative is
/// developers reading it out of logs and, eventually, printing it in release.
class FailureView extends StatelessWidget {
  const FailureView({
    required this.failure,
    required this.environment,
    this.onRetry,
    super.key,
  });

  final AppFailure failure;
  final AppEnvironment environment;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestId = failure.requestId;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              _iconFor(failure),
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              failure.residentMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (requestId != null) ...<Widget>[
              const SizedBox(height: Spacing.sm),
              Text(
                'Reference: $requestId',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (environment.allowsDiagnosticsUi &&
                failure.debugMessage != null) ...<Widget>[
              const SizedBox(height: Spacing.sm),
              Text(
                '[${environment.badgeLabel}] ${failure.kind}: ${failure.debugMessage}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (onRetry != null && failure.isRetryable) ...<Widget>[
              const SizedBox(height: Spacing.xl),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(AppFailure failure) => switch (failure) {
    NetworkFailure() || TimeoutFailure() => Icons.wifi_off_outlined,
    UnauthenticatedFailure() => Icons.lock_outline,
    ForbiddenFailure() => Icons.no_accounts_outlined,
    NotFoundFailure() => Icons.search_off_outlined,
    ValidationFailure() => Icons.edit_note_outlined,
    ConflictFailure() => Icons.sync_problem_outlined,
    RateLimitedFailure() => Icons.hourglass_top_outlined,
    ServerFailure() || ContractFailure() || UnexpectedFailure() =>
      Icons.error_outline,
  };
}
