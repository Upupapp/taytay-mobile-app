import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_card.dart';

/// "Trouble signing in?" — account recovery, as far as it honestly goes.
///
/// ---
///
/// **There is no forgot-password flow, because there is no password.** The
/// committed contract signs a citizen in with a one-time code on their mobile
/// number (`POST /api/v1/auth/otp`). Nothing is memorised, so nothing can be
/// forgotten, and there is no reset link for anyone to phish. A "reset your
/// password" screen here would be a form that could never work.
///
/// **This screen never confirms whether a number has an account.** Every answer
/// below is true regardless of who is reading it. A recovery screen is the
/// softest place to leak an account oracle — the copy is helpful, the flow feels
/// low-stakes, and "we couldn't find that number" reads like kindness. For an
/// LGU it would be a public lookup for whether a named person is a registered
/// Taytay resident, so this screen collects nothing and looks nothing up.
///
/// **Losing the number is a real case with a real answer.** A resident who
/// changed SIM cannot receive the code, and no amount of client code fixes that:
/// changing the number on an account is an identity decision, and the LGU makes
/// it in person against a physical ID. Saying so plainly is more useful than a
/// form that ends in an unanswered support queue.
class SignInHelpScreen extends StatelessWidget {
  const SignInHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Trouble signing in?')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: <Widget>[
            Text(
              'There is no password to reset',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Taytay LGU IDS signs you in with a one-time code sent to your '
              'mobile number. Nothing to memorise, and nothing anyone can trick '
              'you into resetting.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            const _HelpItem(
              icon: Icons.sms_failed_outlined,
              title: 'The code did not arrive',
              body:
                  'Check that you typed the number correctly, and that your '
                  'phone has signal. Messages can take a few minutes. You can '
                  'ask for a new code from the sign-in screen.',
            ),
            const _HelpItem(
              icon: Icons.timer_off_outlined,
              title: 'The code did not work',
              body:
                  'Codes are short-lived and single-use. Ask for a new one and '
                  'enter it as soon as it arrives.',
            ),
            const _HelpItem(
              icon: Icons.lock_clock_outlined,
              title: 'It says too many attempts',
              body:
                  'Taytay LGU limits sign-in attempts to protect your account. '
                  'Wait a little while, then try again. Nothing is wrong with '
                  'your account.',
            ),
            const _HelpItem(
              icon: Icons.sim_card_outlined,
              title: 'You no longer have that number',
              body:
                  'Changing the number on an account is an identity decision, '
                  'so Taytay LGU makes it in person. Visit the municipal hall '
                  'with a valid ID and ask to update your registered mobile '
                  'number. You do not need this app or your old phone to do it.',
            ),
            const _HelpItem(
              icon: Icons.shield_outlined,
              title: 'Someone else may have used your account',
              body:
                  'Sign in and sign out of this device from Sign-in and '
                  'security. If you cannot sign in, report it at the municipal '
                  'hall — staff there can act on your account directly.',
            ),
            const SizedBox(height: Spacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      'What we will never ask you',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Taytay LGU staff will never ask for your one-time code, by '
                    'phone, text or message. If somebody asks you for it, they '
                    'are not from the LGU. Do not share it.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
            FilledButton(
              onPressed: () => context.goNamed(AppRoute.signIn.routeName),
              child: const Text('Back to sign in'),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: () => context.goNamed(AppRoute.home.routeName),
              child: const Text('Continue as guest'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleSmall),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
