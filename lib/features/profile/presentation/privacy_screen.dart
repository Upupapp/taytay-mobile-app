import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/notice_panel.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
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
    final TextStyle body = AppTypography.bodyStyle.copyWith(
      color: BrandColors.text,
    );

    return AuthFormPage(
      title: 'Privacy and your data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const NoticePanel(
            title: 'Taytay LGU is responsible for your information',
            icon: TaytayIcons.shieldCheck,
            intro:
                'This app is one way to reach the Municipality of Taytay, '
                'Rizal. Your information belongs to your municipal record, not '
                'to the app on your phone.',
            points: <NoticePoint>[
              NoticePoint(
                title: 'What this app keeps on your phone',
                body:
                    'Only what is needed to keep you signed in: a sign-in '
                    'token in your phone’s secure keystore, your first name for '
                    'the greeting, and whether Taytay LGU has verified you. '
                    'Signing out removes all of it from this device.',
              ),
              NoticePoint(
                title: 'What this app never keeps',
                body:
                    'Your address, date of birth, ID images and household '
                    'details are not stored on your phone. Screens fetch them '
                    'when they show them, and nothing is written to a file or a '
                    'cache.',
              ),
              NoticePoint(
                title: 'What Taytay LGU holds',
                body:
                    'Your municipal resident record: your name, date of birth, '
                    'address and barangay, together with anything you have '
                    'applied for. Staff see only what their work requires.',
              ),
              NoticePoint(
                title: 'Who else can see it',
                body:
                    'Nobody outside Taytay LGU, and no advertiser. Your '
                    'information is not sold or shared for marketing. Sharing '
                    'with another government office happens only where the law '
                    'requires it.',
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          SoftCard(
            filled: true,
            radius: Radii.cardLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    'Your rights',
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Under the Data Privacy Act of 2012 you can ask Taytay LGU '
                  'what it holds about you, ask for a copy, ask for a mistake '
                  'to be corrected, object to how it is used, and complain to '
                  'the National Privacy Commission.',
                  style: body,
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'Ask at the Taytay municipal hall with a valid ID. Staff '
                  'there can act on your record directly. You do not need '
                  'this app or your phone to do it.',
                  style: body,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Honest about the two things this screen deliberately does not do.
          const SoftNote(
            title: 'Changing what you agreed to. ',
            message:
                'The permissions you gave when you registered are held with '
                'your Taytay LGU record, not in this app. To change or '
                'withdraw one, ask at the municipal hall — that way the '
                'change is recorded where it counts.',
          ),
          const SizedBox(height: Spacing.md),
          const SoftNote(
            title: 'Deleting your record. ',
            message:
                'A municipal resident record is kept for as long as the law '
                'requires, so it is not deleted on request. Taytay LGU can '
                'deactivate an account and correct what is wrong.',
          ),
          const SizedBox(height: Spacing.xl),

          Semantics(
            header: true,
            child: Text(
              CanonicalCorrection.title,
              style: AppTypography.sectionTitle.copyWith(
                color: BrandColors.ink,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            CanonicalCorrection.explanation,
            style: body.copyWith(color: BrandColors.muted),
          ),
        ],
      ),
    );
  }
}
