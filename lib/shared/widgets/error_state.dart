import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_glyphs.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_glyph.dart';
import 'taytay_icon.dart';

/// The illustrated state layout shared by [ErrorState] and `EmptyState`
/// (CSS `.es`): art, a 15 / 700 title, a muted sentence at most 290 wide, and
/// an optional round action. [boxed] puts it on a white card (`.es.boxed`).
///
/// A live region, so a screen reader hears the state when it replaces a list.
class StatePanel extends StatelessWidget {
  const StatePanel({
    required this.art,
    required this.title,
    this.message,
    this.action,
    this.details = const <Widget>[],
    this.boxed = false,
    super.key,
  });

  final Widget art;
  final String title;
  final String? message;
  final Widget? action;

  /// Drawn under the action, e.g. a copyable reference.
  final List<Widget> details;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final String? message = this.message;
    final Widget? action = this.action;
    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        art,
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.sectionTitle.copyWith(
            fontWeight: AppTypography.strong,
            height: 1.3,
            letterSpacing: -0.15,
            color: BrandColors.ink,
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyStyle.copyWith(
                  height: 1.55,
                  color: BrandColors.muted,
                ),
              ),
            ),
          ),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 18), child: action),
        ...details,
      ],
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: boxed
            ? const EdgeInsets.fromLTRB(18, 22, 18, 22)
            : const EdgeInsets.fromLTRB(Spacing.lg, 20, Spacing.lg, Spacing.sm),
        decoration: boxed
            ? BoxDecoration(
                color: BrandColors.white,
                borderRadius: BorderRadius.circular(Radii.cardLarge),
              )
            : null,
        child: column,
      ),
    );
  }
}

/// The round button of an illustrated state (CSS `.es .act2`): 46 px, soft
/// blue, or solid blue when [primary]. "Try again" is primary; "Browse all
/// offices" is not.
class StateActionButton extends StatelessWidget {
  const StateActionButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  /// A Lucide icon before the label, e.g. [TaytayIcons.refreshCw].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color fill = primary ? BrandColors.blue : BrandColors.blue50;
    final Color ink = primary ? BrandColors.white : BrandColors.blue;
    final IconData? icon = this.icon;
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 46)),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: 22),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
        elevation: const WidgetStatePropertyAll<double>(0),
        backgroundColor: WidgetStatePropertyAll<Color>(fill),
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
          if (icon != null) ...<Widget>[
            TaytayIcon(
              icon: icon,
              semanticLabel: '',
              excludeSemantics: true,
              size: 18,
              color: ink,
            ),
            const SizedBox(width: Spacing.sm),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

/// Something failed to load (CSS `.es` on DirectoryOffline): art, a title
/// that says what failed, a sentence on what to do, and **Try again** when
/// trying again could work now.
///
/// [offline] draws the no-connection illustration; otherwise a red alert disc
/// ([icon] overrides its glyph). Copy comes from the caller — never the
/// server's `message`, which is operator-facing (CLAUDE.md Article 5.5).
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.offline = false,
    this.icon,
    this.boxed = false,
    this.details = const <Widget>[],
    super.key,
  });

  final String title;
  final String? message;

  /// Null hides the button: offer it only when a retry can succeed now.
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool offline;
  final IconData? icon;
  final bool boxed;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onRetry = this.onRetry;
    return StatePanel(
      art: offline
          ? const IllustrationArt(TaytayIllustration.offline)
          : _AlertDisc(icon: icon ?? TaytayIcons.circleAlert),
      title: title,
      message: message,
      boxed: boxed,
      details: details,
      action: onRetry == null
          ? null
          : StateActionButton(
              label: retryLabel,
              onPressed: onRetry,
              primary: true,
              icon: TaytayIcons.refreshCw,
            ),
    );
  }
}

class _AlertDisc extends StatelessWidget {
  const _AlertDisc({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: BrandColors.red50,
        shape: BoxShape.circle,
      ),
      child: TaytayIcon(
        icon: icon,
        semanticLabel: '',
        excludeSemantics: true,
        size: 32,
        color: BrandColors.redInk,
      ),
    );
  }
}
