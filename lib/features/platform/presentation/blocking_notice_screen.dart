import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/wave_header.dart';
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
    final SupportContact support = AppDependencies.of(context).platform.support;

    final bool isUpgrade = kind == BlockingNoticeKind.updateRequired;

    // The notice pattern (RegTerms / DirectoryOffline): a centred wave header
    // with the reason's tile, the explanation, and the office's contact as a
    // card. No back control: this screen is in front of everything else.
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: SingleChildScrollView(
        // Scrolls rather than shrinks: this screen must survive 200% text,
        // and it is the one screen a resident cannot navigate away from.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            WaveHeader(
              centered: true,
              badge: IconTile.lucide(
                icon: isUpgrade ? TaytayIcons.download : TaytayIcons.settings,
                tone: isUpgrade ? TileTone.blue : TileTone.gold,
                tileSize: IconTileSize.large,
              ),
              title: isUpgrade
                  ? strings.updateRequiredTitle
                  : strings.maintenanceTitle,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.formGutter,
                Spacing.sm,
                Spacing.formGutter,
                Spacing.xl + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    isUpgrade
                        ? strings.updateRequiredBody
                        : strings.maintenanceBody,
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.text,
                    ),
                  ),
                  if (support.hasAny) ...<Widget>[
                    const SizedBox(height: Spacing.formGap),
                    SoftCard(
                      filled: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            strings.blockingNoticeSupport,
                            style: AppTypography.listTitle.copyWith(
                              color: BrandColors.ink,
                            ),
                          ),
                          const SizedBox(height: Spacing.xs),
                          // Rendered as text rather than a launcher: this
                          // screen can be reached with no connection, and a
                          // dead call button is worse than a number
                          // somebody can read out.
                          if (support.phone.isNotEmpty)
                            SelectableText(
                              support.phone,
                              style: AppTypography.bodyStyle.copyWith(
                                color: BrandColors.ink,
                              ),
                            ),
                          if (support.email.isNotEmpty)
                            SelectableText(
                              support.email,
                              style: AppTypography.bodyStyle.copyWith(
                                color: BrandColors.ink,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Which of the two blocking states is being shown.
enum BlockingNoticeKind { updateRequired, maintenance }
