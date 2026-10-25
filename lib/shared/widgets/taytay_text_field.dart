import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

/// Visual state of a field. The resident always gets text, not colour alone.
///
/// These values name a border. The words a resident reads are the field's
/// label and message, which the caller supplies.
enum TaytayFieldState {
  /// Resting border.
  normal,

  /// Focused border.
  focused,

  /// The inline message is an error.
  error,

  /// The inline message is a confirmation.
  success,
}

/// Text field with an inline message for error and success.
///
/// The message is the thing a resident can act on. Colour repeats it; it does
/// not replace it.
class TaytayTextField extends StatelessWidget {
  const TaytayTextField({
    required this.label,
    this.controller,
    this.hint,
    this.state = TaytayFieldState.normal,
    this.message,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TaytayFieldState state;
  final String? message;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final tone = switch (state) {
      TaytayFieldState.error => BrandColors.danger,
      TaytayFieldState.success => BrandColors.success,
      TaytayFieldState.focused => BrandColors.taytayBlue,
      TaytayFieldState.normal => BrandColors.fieldBorder,
    };
    final fill = switch (state) {
      TaytayFieldState.error => BrandColors.fieldErrorFill,
      TaytayFieldState.focused => BrandColors.surfaceCard,
      _ => BrandColors.fieldFill,
    };
    final ring = switch (state) {
      TaytayFieldState.focused => BrandColors.taytayBlue.withValues(
        alpha: 0.12,
      ),
      TaytayFieldState.error => BrandColors.danger.withValues(alpha: 0.10),
      _ => const Color(0x00000000),
    };
    final message = this.message;
    final showAlert = state == TaytayFieldState.error && message != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.label.copyWith(color: BrandColors.fieldLabel),
        ),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: tone, width: 1.4),
            boxShadow: <BoxShadow>[BoxShadow(color: ring, spreadRadius: 3)],
          ),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              onChanged: onChanged,
              keyboardType: keyboardType,
              // An obscured field cannot expand: Flutter requires one line.
              expands: !obscureText,
              maxLines: obscureText ? 1 : null,
              textAlignVertical: TextAlignVertical.center,
              style: AppTypography.fieldValue.copyWith(
                color: BrandColors.fieldInk,
              ),
              cursorColor: BrandColors.taytayBlue,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.fieldValue.copyWith(
                  fontWeight: AppTypography.body,
                  color: BrandColors.fieldHint,
                ),
                filled: false,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (message != null && message.isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Row(
            children: <Widget>[
              if (showAlert) ...<Widget>[
                TaytayIcon(
                  icon: TaytayIcons.circleAlert,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 14,
                  color: tone,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  message,
                  style: AppTypography.label.copyWith(color: tone),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
