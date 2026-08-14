import 'package:flutter/material.dart';

import '../../core/config/app_environment.dart';
import '../../core/design/design_tokens.dart';
import '../../core/result/result.dart';
import 'app_button.dart';
import 'status_view.dart';

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
///
/// Built on [StatusView] so a failure looks like every other full-surface state
/// in the app rather than like a special case.
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

    final details = <String>[
      if (requestId != null) 'Reference: $requestId',
      if (environment.allowsDiagnosticsUi && failure.debugMessage != null)
        '[${environment.badgeLabel}] ${failure.kind}: ${failure.debugMessage}',
    ];

    return StatusView(
      kind: StatusKind.error,
      icon: _iconFor(failure),
      title: failure.residentMessage,
      primaryAction: onRetry != null && failure.isRetryable
          ? AppButton(
              label: 'Try again',
              variant: AppButtonVariant.secondary,
              fullWidth: false,
              onPressed: onRetry,
            )
          : null,
      secondaryAction: details.isEmpty
          ? null
          : Column(
              children: <Widget>[
                for (final detail in details)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
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
    ServerFailure() ||
    ContractFailure() ||
    UnexpectedFailure() => Icons.error_outline,
  };
}
