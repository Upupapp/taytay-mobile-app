import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

/// What a [SoftNote] says about the moment it describes.
enum NoteTone {
  /// Context to read before acting (blue).
  info,

  /// Waiting, or something to watch (gold).
  warning,

  /// Something failed or needs fixing (red).
  error,

  /// Something is done (green).
  success,
}

/// A note inside a form or a notice page (CSS `.soft .note`): a tinted,
/// rounded box with an icon and a sentence. Each tone has its own icon, so
/// colour is never the only signal (WCAG 1.4.1).
///
/// [title] is drawn bold in front of [message], on the same run of text.
/// [heading] is a bold line of its own above [message] instead — for a note
/// whose title is a statement in its own right ("Taytay LGU has your
/// report"), or whose message is somebody else's words kept exactly.
/// A note is a live region by default, so a screen reader announces it when
/// it appears. Pass [focusNode] when focus should move to it, as an error
/// summary does after a refused submit.
class SoftNote extends StatelessWidget {
  const SoftNote({
    required this.message,
    this.title,
    this.heading,
    this.tone = NoteTone.info,
    this.live = true,
    this.focusNode,
    super.key,
  });

  final String message;
  final String? title;
  final String? heading;
  final NoteTone tone;
  final bool live;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final (
      Color fill,
      Color ink,
      IconData icon,
      String iconLabel,
    ) = switch (tone) {
      NoteTone.info => (
        BrandColors.blue50,
        BrandColors.text,
        TaytayIcons.info,
        'Information',
      ),
      NoteTone.warning => (
        BrandColors.gold50,
        BrandColors.goldInk,
        TaytayIcons.clock,
        'Note',
      ),
      NoteTone.error => (
        BrandColors.red50,
        BrandColors.redInk,
        TaytayIcons.circleAlert,
        'Error',
      ),
      NoteTone.success => (
        BrandColors.green50,
        BrandColors.green,
        TaytayIcons.circleCheck,
        'Done',
      ),
    };
    final String? title = this.title;
    final String? heading = this.heading;
    final TextStyle style = AppTypography.listDetail.copyWith(
      color: ink,
      height: 1.45,
    );
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.note),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.section,
          vertical: Spacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TaytayIcon(
              icon: icon,
              semanticLabel: iconLabel,
              size: IconSizes.sm,
              color: ink,
            ),
            const SizedBox(width: Spacing.sm + Spacing.xxs),
            Expanded(
              child: heading != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          heading,
                          style: style.copyWith(
                            fontWeight: AppTypography.strong,
                          ),
                        ),
                        const SizedBox(height: Spacing.xxs),
                        Text(message, style: style),
                      ],
                    )
                  : Text.rich(
                      TextSpan(
                        style: style,
                        children: <InlineSpan>[
                          if (title != null)
                            TextSpan(
                              text: title,
                              style: const TextStyle(
                                fontWeight: AppTypography.strong,
                              ),
                            ),
                          TextSpan(text: message),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    final FocusNode? focusNode = this.focusNode;
    if (focusNode != null) box = Focus(focusNode: focusNode, child: box);
    return Semantics(
      container: true,
      liveRegion: live,
      focusable: focusNode != null,
      child: box,
    );
  }
}
