import 'package:flutter/material.dart';

import '../../core/config/app_environment.dart';
import '../../core/design/design_tokens.dart';
import '../../core/result/result.dart';
import 'error_state.dart';

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
/// Built on [ErrorState] so a failure looks like every other illustrated state
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
      // Copyable, not just visible. The backend echoes `request_id` in every
      // error body precisely so a resident can quote it to the support desk, and
      // a reference somebody has to transcribe by hand off a phone screen is one
      // they get wrong.
      if (requestId != null) 'Reference: $requestId',
      if (environment.allowsDiagnosticsUi && failure.debugMessage != null)
        '[${environment.badgeLabel}] ${failure.kind}: ${failure.debugMessage}',
    ];

    final bool canRetry =
        onRetry != null && failure.affordance == FailureAffordance.retryNow;
    final Widget state = ErrorState(
      title: failure.residentMessage,
      offline: failure is NetworkFailure || failure is TimeoutFailure,
      icon: _iconFor(failure),
      // Offered only when trying again could work *now*. A `429` is retryable
      // and a button beside it is a lie: the server has said when to come back,
      // and an action that fails again spends a resident's data teaching them
      // nothing.
      onRetry: canRetry ? onRetry : null,
      details: <Widget>[
        for (final detail in details)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            // Selectable so the reference can be copied rather than
            // transcribed off a phone screen — which is how a support
            // desk ends up searching for an id that was never issued.
            child: SelectableText(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );

    // A full-surface state: centred when it fits, scrolling rather than
    // clipping when it does not (200% text on a short screen).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight - Spacing.xxl
                : 0,
          ),
          child: Center(child: state),
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
    CodeExchangeFailure(:final exchangeKind) =>
      exchangeKind == CodeExchangeKind.locked
          ? Icons.hourglass_top_outlined
          : Icons.edit_note_outlined,
    ConflictFailure() => Icons.sync_problem_outlined,
    RateLimitedFailure() => Icons.hourglass_top_outlined,
    UnacceptableUploadFailure() => Icons.photo_size_select_large_outlined,
    ServerFailure() ||
    ContractFailure() ||
    UnexpectedFailure() => Icons.error_outline,
  };
}
