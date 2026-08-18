import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/app_bootstrap.dart';

/// The two screens the server can put in front of everything else.
///
/// ---
///
/// One widget, two states, because they are the same shape of moment: the app
/// cannot proceed, the reason is not the resident's fault, and the only useful
/// content is a plain explanation and a way to reach a person. Building two
/// near-identical screens is how the second one drifts and stops matching.
///
/// **Neither offers a retry that cannot work.** The upgrade screen has no retry
/// at all — the fix is in a store, not in this app — and the maintenance screen
/// clears itself when a request succeeds rather than asking the resident to
/// judge whether the office is back.
///
/// **Neither shows a server message.** Article 5.5: the operator-facing text is
/// written once in one language and would arrive untranslated in front of a
/// Filipino reader even if it were safe to show.
class BlockingNoticeScreen extends StatelessWidget {
  const BlockingNoticeScreen({required this.kind, super.key});

  final BlockingNoticeKind kind;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);
    final SupportContact support = AppDependencies.of(context).platform.support;

    final bool isUpgrade = kind == BlockingNoticeKind.updateRequired;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Scrolls rather than shrinks: this screen must survive 200% text,
            // and it is the one screen a resident cannot navigate away from.
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    isUpgrade
                        ? Icons.system_update_outlined
                        : Icons.construction_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isUpgrade
                        ? strings.updateRequiredTitle
                        : strings.maintenanceTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUpgrade
                        ? strings.updateRequiredBody
                        : strings.maintenanceBody,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (support.hasAny) ...<Widget>[
                    const SizedBox(height: 24),
                    Text(
                      strings.blockingNoticeSupport,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    // Rendered as text rather than a launcher: this screen can be
                    // reached with no connection, and a dead "call" button is
                    // worse than a number somebody can read out.
                    if (support.phone.isNotEmpty)
                      SelectableText(
                        support.phone,
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (support.email.isNotEmpty)
                      SelectableText(
                        support.email,
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Which of the two blocking states is being shown.
enum BlockingNoticeKind { updateRequired, maintenance }
