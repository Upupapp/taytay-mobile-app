import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/profile_fields.dart';

/// Privacy and your data.
///
/// ---
///
/// **Informational, with no consent toggles — deliberately.** The committed
/// contract publishes no consent endpoint, so a switch here could not record a
/// decision anywhere. Under the Data Privacy Act a consent record has to be
/// *demonstrable* by the controller; a toggle whose state lives only in a phone
/// proves nothing, and worse, it tells a resident they have withdrawn something
/// when the LGU has no idea they did. A screen that explains honestly is more
/// use than a control that lies.
///
/// The consents the LGU actually holds were given during registration (TAB 07),
/// where they were explicit, itemised and recorded with the submission. This
/// screen says where they live and how to change them, rather than presenting a
/// second, unrecorded copy.
///
/// **Nothing personal is read here.** The screen is fixed copy: it describes
/// categories, not values, so it renders identically for every resident and
/// discloses nothing by being opened. That also means it works for a guest, and
/// a person deciding whether to register can read what they would be agreeing to
/// first.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and your data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: <Widget>[
            Text(
              'Taytay LGU is responsible for your information',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'This app is one way to reach the Municipality of Taytay, Rizal. '
              'Your information belongs to your municipal record, not to the '
              'app on your phone.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xl),

            const _Section(
              title: 'What this app keeps on your phone',
              body:
                  'Only what is needed to keep you signed in: a sign-in token '
                  'in your phone’s secure keystore, your first name for the '
                  'greeting, and whether Taytay LGU has verified you. '
                  'Signing out removes all of it from this device.',
            ),
            const _Section(
              title: 'What this app never keeps',
              body:
                  'Your address, date of birth, ID images and household details '
                  'are not stored on your phone. Screens fetch them when they '
                  'show them, and nothing is written to a file or a cache.',
            ),
            const _Section(
              title: 'What Taytay LGU holds',
              body:
                  'Your municipal resident record: your name, date of birth, '
                  'address and barangay, together with anything you have '
                  'applied for. Staff see only what their work requires.',
            ),
            const _Section(
              title: 'Who else can see it',
              body:
                  'Nobody outside Taytay LGU, and no advertiser. Your '
                  'information is not sold or shared for marketing. Sharing '
                  'with another government office happens only where the law '
                  'requires it.',
            ),

            const SizedBox(height: Spacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      'Your rights',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Under the Data Privacy Act of 2012 you can ask Taytay LGU '
                    'what it holds about you, ask for a copy, ask for a mistake '
                    'to be corrected, object to how it is used, and complain to '
                    'the National Privacy Commission.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'Ask at the Taytay municipal hall with a valid ID. Staff '
                    'there can act on your record directly. You do not need '
                    'this app or your phone to do it.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // Honest about the two things this screen deliberately does not do.
            const AppBanner(
              tone: BannerTone.info,
              title: 'Changing what you agreed to',
              message:
                  'The permissions you gave when you registered are held with '
                  'your Taytay LGU record, not in this app. To change or '
                  'withdraw one, ask at the municipal hall — that way the '
                  'change is recorded where it counts.',
            ),
            const SizedBox(height: Spacing.md),
            const AppBanner(
              tone: BannerTone.info,
              title: 'Deleting your record',
              message:
                  'A municipal resident record is kept for as long as the law '
                  'requires, so it is not deleted on request. Taytay LGU can '
                  'deactivate an account and correct what is wrong.',
            ),
            const SizedBox(height: Spacing.xl),

            Text(CanonicalCorrection.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: Spacing.sm),
            Text(
              CanonicalCorrection.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
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
    );
  }
}
