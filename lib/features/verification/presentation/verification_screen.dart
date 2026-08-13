import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/session/access_level.dart';

/// Identity verification: where an unverified resident goes to become verified,
/// and where a verified resident sees their status.
///
/// The submission flow itself (document capture, PhilSys, liveness) is a later
/// TAB — it depends on the backend's `ResidentProfile` and `Credential` modules,
/// which are not built. What exists here is the destination the access guard
/// redirects to, so an unverified resident who taps a verified-only service
/// lands on an explanation instead of a dead end.
class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.of(context);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: dependencies.session,
      builder: (context, _) {
        final isVerified =
            dependencies.session.state.accessLevel == AccessLevel.verified;

        return Scaffold(
          appBar: AppBar(title: const Text('Identity verification')),
          body: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              Icon(
                isVerified
                    ? Icons.verified_outlined
                    : Icons.assignment_ind_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                isVerified
                    ? 'Your identity is verified'
                    : 'Verify your identity with Taytay LGU',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                isVerified
                    ? 'Taytay LGU has confirmed your identity. You can hold and '
                          'present your municipal digital ID.'
                    : 'Verification lets Taytay LGU confirm that you are who you '
                          'say you are, so your digital ID and service '
                          'applications can be trusted by municipal offices.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              if (!isVerified) ...<Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'What you will be asked for',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: Spacing.md),
                        const _Bullet('A valid government-issued ID'),
                        const _Bullet('A photo of yourself, taken in the app'),
                        const _Bullet('Your address within Taytay'),
                        const SizedBox(height: Spacing.md),
                        Text(
                          'Taytay LGU collects only what is needed to confirm '
                          'your identity and residency, and keeps it under the '
                          'Data Privacy Act of 2012 (RA 10173).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xl),
                const FilledButton(
                  // Deliberately inert: the verification service does not exist
                  // yet, and a button that pretends otherwise would collect
                  // identity documents with nowhere to send them.
                  onPressed: null,
                  child: Text('Start verification'),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Verification opens once Taytay LGU enables it in this app.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
