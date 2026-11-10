import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/asset_manifest.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/taytay_back_button.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';

/// Copy for one welcome page. The screen builds it from l10n. Goldens pass
/// the same design strings.
@immutable
class WelcomePageCopy {
  const WelcomePageCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.chips,
    required this.tag,
    required this.credit,
    required this.photoPath,
    required this.photoLabel,
    required this.skipLabel,
    required this.nextLabel,
    required this.getStartedLabel,
    required this.guestLabel,
    required this.guestNote,
    required this.stepLabel,
  });

  final String eyebrow;
  final String title;
  final String body;
  final List<String> chips;
  final String tag;
  final String credit;
  final String photoPath;
  final String photoLabel;
  final String skipLabel;
  final String nextLabel;
  final String getStartedLabel;
  final String guestLabel;
  final String guestNote;
  final String stepLabel;

  static List<WelcomePageCopy> fromStrings(AppStrings strings) {
    String photo(String key) => AppAssets.byKey(key)!.path;
    String label(String key) => AppAssets.byKey(key)!.semanticLabel;
    return <WelcomePageCopy>[
      WelcomePageCopy(
        eyebrow: strings.welcomeServicesEyebrow,
        title: strings.welcomeServicesTitle,
        body: strings.welcomeServicesBody,
        chips: <String>[
          strings.welcomeServicesChipDocuments,
          strings.welcomeServicesChipTax,
          strings.welcomeServicesChipHealth,
          strings.welcomeServicesChipJobs,
        ],
        tag: strings.welcomeServicesTag,
        credit: strings.welcomeServicesCredit,
        photoPath: photo('municipal_hall'),
        photoLabel: label('municipal_hall'),
        skipLabel: strings.welcomeSkip,
        nextLabel: strings.welcomeNext,
        getStartedLabel: strings.welcomeGetStarted,
        guestLabel: strings.welcomeContinueAsGuest,
        guestNote: strings.welcomeGuestNote,
        stepLabel: strings.welcomeStep(1, 3),
      ),
      WelcomePageCopy(
        eyebrow: strings.welcomeIdEyebrow,
        title: strings.welcomeIdTitle,
        body: strings.welcomeIdBody,
        chips: <String>[
          strings.welcomeIdChipDigital,
          strings.welcomeIdChipQueue,
        ],
        tag: strings.welcomeIdTag,
        credit: strings.welcomeIdCredit,
        photoPath: photo('tiangge'),
        photoLabel: label('tiangge'),
        skipLabel: strings.welcomeSkip,
        nextLabel: strings.welcomeNext,
        getStartedLabel: strings.welcomeGetStarted,
        guestLabel: strings.welcomeContinueAsGuest,
        guestNote: strings.welcomeGuestNote,
        stepLabel: strings.welcomeStep(2, 3),
      ),
      WelcomePageCopy(
        eyebrow: strings.welcomePrivacyEyebrow,
        title: strings.welcomePrivacyTitle,
        body: strings.welcomePrivacyBody,
        chips: const <String>[],
        tag: strings.welcomePrivacyTag,
        credit: strings.welcomePrivacyCredit,
        photoPath: photo('parish_church'),
        photoLabel: label('parish_church'),
        skipLabel: strings.welcomeSkip,
        nextLabel: strings.welcomeNext,
        getStartedLabel: strings.welcomeGetStarted,
        guestLabel: strings.welcomeContinueAsGuest,
        guestNote: strings.welcomeGuestNote,
        stepLabel: strings.welcomeStep(3, 3),
      ),
    ];
  }
}

/// Hit target for Skip. The painted pill is 40 dp (CSS `.skip`), centred in
/// this 48 dp box.
const Key welcomeSkipTargetKey = Key('welcome-skip-target');

/// The gold Next disc (CSS `.fab`). It shows an arrow only; its name is
/// [WelcomePageCopy.nextLabel].
const Key welcomeNextKey = Key('welcome-next');

/// One welcome page as `Main.dc.html` draws it: the photo zone (photo, tint,
/// seal row with Skip, wave) over the top 62%, and the white panel below
/// with the pager, the title, the body and Next. The last page trades Next
/// for Get started and an equal-weight Continue as guest.
///
/// At large text the page scrolls; the zone keeps its height and the panel
/// grows below it.
class WelcomeCanvas extends StatelessWidget {
  const WelcomeCanvas({
    required this.page,
    required this.copy,
    required this.onSkip,
    this.pageCount = 3,
    this.onNext,
    this.onBack,
    this.onGetStarted,
    this.onGuest,
    super.key,
  });

  final int page;
  final int pageCount;
  final WelcomePageCopy copy;

  final VoidCallback onSkip;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onGetStarted;
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    final bool last = page >= pageCount - 1;
    return ColoredBox(
      color: BrandColors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final double zone = math.max(
            WelcomeShapes.zoneMinHeight,
            height * WelcomeShapes.zoneFraction,
          );
          // No IntrinsicHeight: the panel's body text is narrower than the
          // panel, which intrinsic sizing does not see. The panel takes at
          // least the rest of the screen and grows past it at large text.
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: zone,
                  child: _PhotoZone(
                    copy: copy,
                    showBack: page > 0,
                    onBack: onBack,
                    onSkip: onSkip,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, height - zone),
                  ),
                  child: _Panel(
                    page: page,
                    pageCount: pageCount,
                    copy: copy,
                    last: last,
                    onNext: onNext,
                    onGetStarted: onGetStarted,
                    onGuest: onGuest,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// CSS `.zone`: the photo, its tint, the seal row and the wave.
class _PhotoZone extends StatelessWidget {
  const _PhotoZone({
    required this.copy,
    required this.showBack,
    required this.onBack,
    required this.onSkip,
  });

  final WelcomePageCopy copy;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.paddingOf(context).top;
    const EdgeInsets padding = WelcomeShapes.topRowPadding;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(
            color: BrandColors.blue,
            child: Image.asset(
              copy.photoPath,
              fit: BoxFit.cover,
              alignment: WelcomeShapes.photoAlignment,
              semanticLabel: copy.photoLabel,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: WelcomeShapes.tint),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: padding.copyWith(top: padding.top + safeTop),
              child: Row(
                children: <Widget>[
                  if (showBack) ...<Widget>[
                    TaytayBackButton(onPressed: onBack, translucent: true),
                    const SizedBox(width: Spacing.md),
                  ],
                  const HeaderSeal(),
                  const SizedBox(width: Spacing.md),
                  const Expanded(child: _MunicipalName()),
                  const SizedBox(width: Spacing.sm),
                  _SkipButton(label: copy.skipLabel, onPressed: onSkip),
                ],
              ),
            ),
          ),
          // The photo's licence asks for its credit wherever it is shown.
          Positioned(
            left: Spacing.formGutter,
            right: Spacing.formGutter,
            bottom: WelcomeShapes.waveHeight,
            child: Text(
              copy.credit,
              textAlign: TextAlign.end,
              style: AppTypography.tiny.copyWith(
                color: BrandColors.onHeaderLede,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: WelcomeShapes.waveHeight,
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: WavePainter(layers: WelcomeShapes.layers),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CSS `.wtop .nm`: the municipality on the photo, white over gold.
class _MunicipalName extends StatelessWidget {
  const _MunicipalName();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Bayan ng Taytay',
          style: AppTypography.listTitle.copyWith(
            fontWeight: AppTypography.black,
            color: BrandColors.white,
            height: 1.25,
          ),
        ),
        Text(
          'Lalawigan ng Rizal',
          style: AppTypography.small.copyWith(
            fontWeight: AppTypography.strong,
            color: BrandColors.gold,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: SizedBox(
        key: welcomeSkipTargetKey,
        height: A11y.minTapTarget,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            customBorder: const StadiumBorder(),
            child: Center(
              widthFactor: 1,
              child: DecoratedBox(
                decoration: const ShapeDecoration(
                  color: WelcomeShapes.skipFill,
                  shape: StadiumBorder(),
                ),
                child: SizedBox(
                  height: WelcomeShapes.skipHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        label,
                        style: AppTypography.listTitle.copyWith(
                          fontWeight: AppTypography.strong,
                          color: BrandColors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// CSS `.panel`: pager, title, body, then Next or the two ways in.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.page,
    required this.pageCount,
    required this.copy,
    required this.last,
    required this.onNext,
    required this.onGetStarted,
    required this.onGuest,
  });

  final int page;
  final int pageCount;
  final WelcomePageCopy copy;
  final bool last;
  final VoidCallback? onNext;
  final VoidCallback? onGetStarted;
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    const EdgeInsets padding = WelcomeShapes.panelPadding;
    const SizedBox gap = SizedBox(height: WelcomeShapes.panelGap);
    return Padding(
      padding: padding.copyWith(bottom: padding.bottom + safeBottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _Pager(active: page, count: pageCount, label: copy.stepLabel),
          gap,
          Semantics(
            header: true,
            label: copy.title.replaceAll('\n', ' '),
            child: ExcludeSemantics(
              child: Text(
                copy.title,
                textAlign: TextAlign.center,
                style: AppTypography.hero.copyWith(
                  color: BrandColors.ink,
                  height: 1.15,
                ),
              ),
            ),
          ),
          gap,
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: WelcomeShapes.bodyMaxWidth,
            ),
            child: Text(
              copy.body,
              textAlign: TextAlign.center,
              style: AppTypography.bodyStyle.copyWith(
                color: BrandColors.muted,
                height: 1.55,
              ),
            ),
          ),
          gap,
          if (!last)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs + Spacing.xxs),
              child: _NextButton(label: copy.nextLabel, onPressed: onNext),
            )
          else
            _Finish(copy: copy, onGetStarted: onGetStarted, onGuest: onGuest),
        ],
      ),
    );
  }
}

/// CSS `.pager`: one dot per page, the current one long and blue. Read out as
/// "Step 1 of 3", never only as dots.
class _Pager extends StatelessWidget {
  const _Pager({
    required this.active,
    required this.count,
    required this.label,
  });

  final int active;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < count; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Spacing.xs + Spacing.xxs),
              Container(
                width: i == active
                    ? WelcomeShapes.pagerDotActive
                    : WelcomeShapes.pagerDot,
                height: WelcomeShapes.pagerDot,
                decoration: ShapeDecoration(
                  color: i == active ? BrandColors.blue : BrandColors.line2,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        key: welcomeNextKey,
        dimension: WelcomeShapes.fab,
        child: Material(
          color: BrandColors.gold,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const Center(
              child: TaytayIcon(
                icon: TaytayIcons.arrowRight,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.md,
                color: BrandColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The last page: Get started, and Continue as guest at equal weight, with the
/// sentence saying an account is not needed to browse.
class _Finish extends StatelessWidget {
  const _Finish({
    required this.copy,
    required this.onGetStarted,
    required this.onGuest,
  });

  final WelcomePageCopy copy;
  final VoidCallback? onGetStarted;
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PrimaryButton(label: copy.getStartedLabel, onPressed: onGetStarted),
        const SizedBox(height: Spacing.sm + Spacing.xxs),
        SecondaryButton(label: copy.guestLabel, onPressed: onGuest),
        const SizedBox(height: Spacing.sm + Spacing.xxs),
        Text(
          copy.guestNote,
          textAlign: TextAlign.center,
          style: AppTypography.small.copyWith(color: BrandColors.muted),
        ),
      ],
    );
  }
}
