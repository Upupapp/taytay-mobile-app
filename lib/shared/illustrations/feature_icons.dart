import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';

/// Icons for the authoritative LGU service categories.
///
/// **These are Material icons, not shipped image files, and that is the whole
/// point.** The Material icon font is already in the bundle and is tree-shaken
/// to the glyphs actually referenced — TAB 03's release build shrank it from
/// 1,645,184 to 5,612 bytes. A set of six PNG or SVG pictograms would add real
/// install weight, need `2.0x`/`3.0x` variants, need re-colouring for dark mode,
/// and would have to re-earn the optical alignment and stroke consistency the
/// Material set already has.
///
/// The keys are the backend's own category values from
/// `Modules\ServiceCatalog\Domain\ServiceCategory` — `dokumento`, `buwis`,
/// `kalusugan`, `trabaho`, `ids`, `national` — so an unknown category coming
/// from the server falls back rather than crashing a released app.
enum ServiceCategoryIcon {
  dokumento('dokumento', Icons.description_outlined),
  buwis('buwis', Icons.receipt_long_outlined),
  kalusugan('kalusugan', Icons.local_hospital_outlined),
  trabaho('trabaho', Icons.work_outline),
  ids('ids', Icons.badge_outlined),
  national('national', Icons.account_balance_outlined);

  const ServiceCategoryIcon(this.categoryCode, this.icon);

  /// Wire value from the backend's `ServiceCategory` enum.
  final String categoryCode;

  final IconData icon;

  // The English `label` that used to live here was deleted on 2026-08-29. It
  // was a second source of truth for six names that `serviceCategoryLabel` now
  // owns, it could not be translated because an enum constant has no
  // BuildContext, and nothing ever rendered it — `FeatureIcon` has no
  // production caller. Meanwhile `services_screen.dart` was showing the
  // backend's wire codes because the labels it needed were stranded here.
  //
  // This enum now selects a glyph and nothing else. Callers that need an
  // accessible name pass one in, from a place that can translate it.

  /// Resolves a server-supplied category code.
  ///
  /// An unrecognised code returns `null` rather than throwing: the backend may
  /// add a category without a version bump, and a released app must degrade to a
  /// neutral icon instead of failing.
  static ServiceCategoryIcon? fromCode(String? code) {
    if (code == null) return null;
    for (final value in ServiceCategoryIcon.values) {
      if (value.categoryCode == code) return value;
    }
    return null;
  }
}

/// A category icon inside a soft tinted container.
///
/// The container is what gives a row of icons a consistent optical size — icons
/// differ in how much of their box they fill, and a shared backing shape hides
/// that far better than nudging each glyph.
class FeatureIcon extends StatelessWidget {
  const FeatureIcon({
    required this.icon,
    this.size = IconSizes.lg,
    this.semanticLabel,
    this.tone,
    super.key,
  });

  /// Convenience for a known service category.
  FeatureIcon.category(
    ServiceCategoryIcon category, {
    required this.semanticLabel,
    this.size = IconSizes.lg,
    this.tone,
    super.key,
  }) : icon = category.icon;

  /// Falls back to a neutral mark for a category this build does not know.
  FeatureIcon.categoryCode(
    String? code, {
    this.semanticLabel,
    this.size = IconSizes.lg,
    this.tone,
    super.key,
  }) : icon = ServiceCategoryIcon.fromCode(code)?.icon ?? Icons.apps_outlined;

  final IconData icon;
  final double size;

  /// `null` hides the icon from assistive technology, which is correct when
  /// adjacent text already names the thing.
  final String? semanticLabel;

  /// Overrides the tint. Defaults to the theme's primary.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = tone ?? scheme.primary;
    final box = size * 1.6;

    final content = Container(
      width: box,
      height: box,
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(box * 0.28),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size, color: colour),
    );

    return semanticLabel == null
        ? ExcludeSemantics(child: content)
        : Semantics(label: semanticLabel, image: true, child: content);
  }
}
