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
    this.danger = false,
    this.semanticLabel,
    this.buttonKey,
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

  /// The solid red pill, for a call to an emergency line. Wins over
  /// [primary].
  final bool danger;

  /// Key on the pill's button, for a test or a capture to find it.
  final Key? buttonKey;
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
    this.wrap = false,
    super.key,
  });

  final List<PillAction> actions;

  /// The scroll view's padding. The design bleeds the row to the screen edge
  /// and insets its first pill by the page gutter.
  final EdgeInsetsGeometry padding;

  /// Wraps the pills onto a second line instead of scrolling sideways, so
  /// every action is on screen without a swipe (an office page's Message).
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: Spacing.sm,
          children: <Widget>[
            for (final PillAction action in actions)
              _Pill(action: action, wraps: true),
          ],
        ),
      );
    }
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
  const _Pill({required this.action, this.wraps = false});

  final PillAction action;

  /// In a wrapping row a label longer than the line wraps inside its pill.
  final bool wraps;

  @override
  Widget build(BuildContext context) {
    final bool primary = action.primary || action.danger;
    final Color fill = action.danger
        ? BrandColors.red
        : primary
        ? BrandColors.blue
        : BrandColors.blue50;
    final Color ink = primary ? BrandColors.white : BrandColors.blue;
    final TaytayGlyph? glyph = action.glyph;
    final Widget button = TextButton(
      key: action.buttonKey,
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
          if (wraps)
            Flexible(child: Text(action.label))
          else
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
