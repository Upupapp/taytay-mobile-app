import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';

/// "Trouble signing in?" — account recovery, as far as it honestly goes.
///
/// ---
///
/// **Reset is a separate screen, and this one still collects nothing.**
/// Sign-in asks for a password. Forgot password (`02-02`) asks for an email
/// or a mobile number and does not say whether an account exists. The live
/// repository declines that call: there is no citizen reset route. This help
/// page only explains the path and never looks an account up.
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
    final AppStrings strings = AppStrings.of(context);
    // The form / notice pattern: the wave header with back over the white
    // page. Nothing here collects anything; it points at reset and explains.
    return AuthFormPage(
      title: strings.authHelpTitle,
      subtitle: strings.authHelpSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            strings.authHelpIntro,
            style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
          ),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: () => context.goNamed(AppRoute.forgotPassword.routeName),
            child: Text(strings.authResetTitle),
          ),
          const SizedBox(height: Spacing.formGap),
          _HelpItem(
            icon: TaytayIcons.messageCircle,
            title: strings.authHelpNoCodeTitle,
            body: strings.authHelpNoCodeBody,
          ),
          _HelpItem(
            icon: TaytayIcons.timer,
            title: strings.authHelpCodeFailedTitle,
            body: strings.authHelpCodeFailedBody,
          ),
          _HelpItem(
            icon: TaytayIcons.clock,
            title: strings.authHelpTooManyTitle,
            body: strings.authHelpTooManyBody,
          ),
          _HelpItem(
            icon: TaytayIcons.smartphone,
            title: strings.authHelpLostNumberTitle,
            body: strings.authHelpLostNumberBody,
          ),
          _HelpItem(
            icon: TaytayIcons.shieldAlert,
            title: strings.authHelpMisuseTitle,
            body: strings.authHelpMisuseBody,
          ),
          const SizedBox(height: Spacing.sm),
          SoftNote(
            tone: NoteTone.warning,
            live: false,
            heading: strings.authHelpNeverAskHeading,
            message: strings.authHelpNeverAskBody,
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton(
            onPressed: () => context.goNamed(AppRoute.signIn.routeName),
            child: Text(strings.authBackToSignIn),
          ),
          const SizedBox(height: Spacing.sm),
          AuthLink(
            strings.welcomeContinueAsGuest,
            muted: true,
            onPressed: () => context.goNamed(AppRoute.home.routeName),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: SoftCard(
        filled: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SettingsIcon(icon: icon),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    body,
                    style: AppTypography.listDetail.copyWith(
                      color: BrandColors.text,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
