import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/ringed_input_border.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_icon.dart';

/// CSS `.soft .search` on the blue header (`Directory.dc.html`): white, 16
/// radius, 54 tall, the search glyph, and a gold focus ring on the blue.
///
/// Put it in `BlueHeader.bottom`. [fieldKey] goes on the `TextField` itself so
/// a test can type into it. The hint is the field's only label, so it is also
/// announced.
class HeaderSearchField extends StatelessWidget {
  const HeaderSearchField({
    required this.hint,
    this.controller,
    this.onChanged,
    this.fieldKey,
    super.key,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    const BorderRadius corners = BorderRadius.all(Radius.circular(Radii.lg));
    return TextField(
      key: fieldKey,
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTypography.fieldValue.copyWith(
        fontWeight: AppTypography.body,
        color: BrandColors.ink,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: BrandColors.white,
        constraints: const BoxConstraints(
          minHeight: ComponentSizes.fieldHeight,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        prefixIcon: const TaytayIcon(
          icon: TaytayIcons.search,
          semanticLabel: '',
          excludeSemantics: true,
          size: IconSizes.sm,
          color: BrandColors.muted,
        ),
        border: const RingedInputBorder(
          borderSide: BorderSide.none,
          borderRadius: corners,
        ),
        enabledBorder: const RingedInputBorder(
          borderSide: BorderSide.none,
          borderRadius: corners,
        ),
        focusedBorder: RingedInputBorder(
          borderSide: BorderSide.none,
          borderRadius: corners,
          ring: BorderSide(
            color: BrandColors.gold.withValues(alpha: 0.7),
            width: FocusRing.ringWidth,
          ),
        ),
      ),
    );
  }
}
