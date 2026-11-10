import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_glyphs.dart';
import '../../core/design/typography.dart';
import 'taytay_glyph.dart';

/// One action in a [PillButtonRow].
@immutable
class PillAction {
  const PillAction({
    required this.label,
    required this.onPressed,
    this.glyph,
    this.primary = false,
    this.semanticLabel,
  });

  /// The visible word ("Call", "Directions").
  final String label;

  /// Null draws the pill disabled.
  final VoidCallback? onPressed;
  final TaytayGlyph? glyph;

  /// The solid blue pill. Use for the one main action; the rest are soft.
  final bool primary;

  /// Read instead of [label] when the word alone is ambiguous ("Call MSWDO").
  final String? semanticLabel;
}

/// The detail page's row of round actions (CSS `.pills` / `.pl` on Office):
/// 40 px pills, soft blue, the first usually solid. Scrolls sideways when
/// they do not fit, so a long label or 200% text never clips.
///
/// Each pill keeps a 48 px tap target around its 40 px shape.
class PillButtonRow extends StatelessWidget {
  const PillButtonRow({
    required this.actions,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.formGutter),
    super.key,
  });

  final List<PillAction> actions;

  /// The scroll view's padding. The design bleeds the row to the screen edge
  /// and insets its first pill by the page gutter.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: <Widget>[
          for (var i = 0; i < actions.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: Spacing.sm),
            _Pill(action: actions[i]),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.action});

  final PillAction action;

  @override
  Widget build(BuildContext context) {
    final bool primary = action.primary;
    final Color fill = primary ? BrandColors.blue : BrandColors.blue50;
    final Color ink = primary ? BrandColors.white : BrandColors.blue;
    final TaytayGlyph? glyph = action.glyph;
    final Widget button = TextButton(
      onPressed: action.onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 40)),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: Spacing.lg),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        elevation: const WidgetStatePropertyAll<double>(0),
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.disabled)
              ? fill.withValues(alpha: 0.5)
              : fill,
        ),
        foregroundColor: WidgetStatePropertyAll<Color>(ink),
        overlayColor: WidgetStatePropertyAll<Color>(
          (primary ? BrandColors.white : BrandColors.blue).withValues(
            alpha: 0.12,
          ),
        ),
        textStyle: WidgetStatePropertyAll<TextStyle>(AppTypography.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (glyph != null) ...<Widget>[
            GlyphIcon(glyph, size: 18, color: ink),
            const SizedBox(width: Spacing.sm),
          ],
          Text(action.label),
        ],
      ),
    );
    final String? label = action.semanticLabel;
    if (label == null) return button;
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      enabled: action.onPressed != null,
      onTap: action.onPressed,
      child: button,
    );
  }
}
