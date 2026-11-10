import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/ringed_input_border.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/motion/motion_tokens.dart';
import 'taytay_icon.dart';

/// The day above a run of messages (CSS `.log .day`): a grey pill.
class ConversationDayChip extends StatelessWidget {
  const ConversationDayChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: BrandColors.chipFill,
          shape: StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xxs + 1,
          ),
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.medium,
              color: BrandColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// One message (`Conversation.dc.html` `.me` / `.them`): the resident's own
/// on the right in solid blue, the office's on the left in white, each at
/// most 82% of the row, with the time line under it.
///
/// [attachments] sit inside the bubble under the words, e.g. a file chip.
class ConversationBubble extends StatelessWidget {
  const ConversationBubble({
    required this.body,
    required this.meta,
    required this.mine,
    this.attachments = const <Widget>[],
    super.key,
  });

  final String body;

  /// "BPLO · 9:05 AM", or the time alone on the resident's own message.
  final String meta;
  final bool mine;
  final List<Widget> attachments;

  @override
  Widget build(BuildContext context) {
    const Radius round = Radius.circular(Radii.card);
    const Radius tail = Radius.circular(Spacing.xs + Spacing.xxs);
    final BorderRadius corners = mine
        ? const BorderRadius.only(
            topLeft: round,
            topRight: round,
            bottomLeft: round,
            bottomRight: tail,
          )
        : const BorderRadius.only(
            topLeft: round,
            topRight: round,
            bottomLeft: tail,
            bottomRight: round,
          );
    final Color ink = mine ? BrandColors.white : BrandColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm + Spacing.xxs),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: ComponentSizes.bubbleWidthFactor,
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: mine ? BrandColors.blue : BrandColors.white,
                  borderRadius: corners,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.section,
                    vertical: Spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (body.isNotEmpty)
                        Text(
                          body,
                          style: AppTypography.bodyStyle.copyWith(
                            color: ink,
                            height: 1.45,
                          ),
                        ),
                      for (final Widget attachment in attachments) ...<Widget>[
                        if (body.isNotEmpty) const SizedBox(height: Spacing.sm),
                        attachment,
                      ],
                    ],
                  ),
                ),
              ),
              if (meta.isNotEmpty) ...<Widget>[
                const SizedBox(height: Spacing.xs),
                Text(
                  meta,
                  style: AppTypography.tiny.copyWith(color: BrandColors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The composer under a conversation (CSS `.comp`): a round attach button,
/// the pill-shaped field, and the solid round send button. The chosen file
/// sits above the row with a way to remove it.
class ConversationComposer extends StatelessWidget {
  const ConversationComposer({
    this.controller,
    this.onAttach,
    this.onSend,
    this.sendEnabled = true,
    this.attachmentLabel,
    this.onClearAttachment,
    this.hint = 'Write a message…',
    this.attachKey,
    this.sendKey,
    this.fieldKey,
    this.clearKey,
    super.key,
  });

  final TextEditingController? controller;
  final VoidCallback? onAttach;
  final VoidCallback? onSend;

  /// False while a message is in flight.
  final bool sendEnabled;
  final String? attachmentLabel;
  final VoidCallback? onClearAttachment;
  final String hint;
  final Key? attachKey;
  final Key? sendKey;
  final Key? fieldKey;
  final Key? clearKey;

  @override
  Widget build(BuildContext context) {
    final String? label = attachmentLabel;
    final VoidCallback? onClear = onClearAttachment;
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: BrandColors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.sm + Spacing.xxs,
          Spacing.md,
          Spacing.lg + Spacing.xs + safeBottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (label != null) ...<Widget>[
              Row(
                children: <Widget>[
                  const TaytayIcon(
                    icon: TaytayIcons.paperclip,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: IconSizes.sm,
                    color: BrandColors.blue,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.listDetail.copyWith(
                        fontWeight: AppTypography.medium,
                        color: BrandColors.text,
                      ),
                    ),
                  ),
                  if (onClear != null)
                    ConversationRoundButton(
                      gestureKey: clearKey,
                      icon: TaytayIcons.close,
                      semanticLabel: 'Remove attachment',
                      onPressed: onClear,
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
            ],
            Row(
              children: <Widget>[
                ConversationRoundButton(
                  gestureKey: attachKey,
                  icon: TaytayIcons.paperclip,
                  semanticLabel: 'Attach photo or PDF',
                  onPressed: onAttach,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.bodyStyle.copyWith(
                      color: BrandColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Spacing.lg,
                        vertical: Spacing.md,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(
                          Radius.circular(Radii.pill),
                        ),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(
                          Radius.circular(Radii.pill),
                        ),
                      ),
                      focusedBorder: const RingedInputBorder(
                        borderSide: BorderSide(
                          color: BrandColors.blue,
                          width: FocusRing.borderWidth,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(Radii.pill),
                        ),
                        ring: BorderSide(
                          color: FocusRing.ring,
                          width: FocusRing.ringWidth,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                ConversationRoundButton(
                  gestureKey: sendKey,
                  icon: TaytayIcons.send,
                  semanticLabel: 'Send',
                  solid: true,
                  onPressed: sendEnabled ? onSend : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A 44 px round button in a 48 dp target (CSS `.ib2`): soft blue, or solid
/// blue for send. [gestureKey] marks the gesture detector itself, so a test
/// can read whether it is live.
class ConversationRoundButton extends StatelessWidget {
  const ConversationRoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.solid = false,
    this.gestureKey,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool solid;
  final Key? gestureKey;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onPressed = this.onPressed;
    final bool enabled = onPressed != null;
    final Color fill = solid ? BrandColors.blue : BrandColors.blue50;
    final Color ink = solid ? BrandColors.white : BrandColors.blue;
    final bool reduced = Motion.reduced(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        key: gestureKey,
        behavior: HitTestBehavior.opaque,
        onTap: onPressed == null
            ? null
            : () {
                unawaited(
                  AppHaptics.fire(HapticIntent.selection, suppressed: reduced),
                );
                onPressed();
              },
        child: SizedBox(
          width: A11y.minTapTarget,
          height: A11y.minTapTarget,
          child: Center(
            child: Container(
              width: ComponentSizes.headerIconButton,
              height: ComponentSizes.headerIconButton,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled
                    ? fill
                    : fill.withValues(alpha: Opacities.disabled),
                shape: BoxShape.circle,
              ),
              child: TaytayIcon(
                icon: icon,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
