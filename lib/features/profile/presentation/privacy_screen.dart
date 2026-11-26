import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/notice_panel.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';

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
    final strings = AppStrings.of(context);

    return AuthFormPage(
      title: strings.profPrivacyRow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NoticePanel(
            title: strings.profPrivacyResponsibleTitle,
            icon: TaytayIcons.shieldCheck,
            intro: strings.profPrivacyResponsibleIntro,
            points: <NoticePoint>[
              NoticePoint(
                title: strings.profPrivacyKeptTitle,
                body: strings.profPrivacyKeptBody,
              ),
              NoticePoint(
                title: strings.profPrivacyNeverKeptTitle,
                body: strings.profPrivacyNeverKeptBody,
              ),
              NoticePoint(
                title: strings.profPrivacyLguHoldsTitle,
                body: strings.profPrivacyLguHoldsBody,
              ),
              NoticePoint(
                title: strings.profPrivacyWhoElseTitle,
                body: strings.profPrivacyWhoElseBody,
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
                    strings.profPrivacyRightsTitle,
                    style: AppTypography.listTitle.copyWith(
                      fontWeight: AppTypography.strong,
                      color: BrandColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(strings.profPrivacyRightsBody, style: body),
                const SizedBox(height: Spacing.md),
                Text(strings.profPrivacyRightsHow, style: body),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Honest about the two things this screen deliberately does not do.
          SoftNote(
            title: '${strings.profPrivacyConsentTitle} ',
            message: strings.profPrivacyConsentBody,
          ),
          const SizedBox(height: Spacing.md),
          SoftNote(
            title: '${strings.profPrivacyDeleteTitle} ',
            message: strings.profPrivacyDeleteBody,
          ),
          const SizedBox(height: Spacing.xl),

          Semantics(
            header: true,
            child: Text(
              strings.profCanonicalTitle,
              style: AppTypography.sectionTitle.copyWith(
                color: BrandColors.ink,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            strings.profCanonicalExplanation,
            style: body.copyWith(color: BrandColors.muted),
          ),
        ],
      ),
    );
  }
}
