import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';

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
            borderRadius: BorderRadius.circular(Radii.md),
            boxShadow: <BoxShadow>[BoxShadow(color: ring, spreadRadius: 3)],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: AppTypography.fieldValue.copyWith(
              color: BrandColors.textPrimary,
            ),
            cursorColor: BrandColors.taytayBlue,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.fieldValue.copyWith(
                fontWeight: AppTypography.body,
                color: BrandColors.fieldHint,
              ),
              filled: true,
              fillColor: fill,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              enabledBorder: _border(tone),
              focusedBorder: _border(BrandColors.taytayBlue),
              errorBorder: _border(BrandColors.danger),
              focusedErrorBorder: _border(BrandColors.danger),
            ),
          ),
        ),
        if (message != null && message.isNotEmpty) ...<Widget>[
          const SizedBox(height: 5),
          Text(message, style: AppTypography.label.copyWith(color: tone)),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: color, width: 1.4),
    );
  }
}
