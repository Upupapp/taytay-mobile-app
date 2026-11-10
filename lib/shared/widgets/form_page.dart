import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import 'blue_header.dart';
import 'taytay_icon.dart';
import 'wave_header.dart';

/// The form / step page of the redesign (`SignIn.dc.html`, `Reg*.dc.html`):
/// a [WaveHeader] over a white page, the form below it, and the actions in a
/// footer (CSS `.obfoot`) that stays above the keyboard.
///
/// The header scrolls away with the form rather than staying pinned, so a
/// long title at 200% text never squeezes the fields out of the screen.
/// [pageKey] marks the white page; tests read its colour.
class AuthFormPage extends StatelessWidget {
  const AuthFormPage({
    required this.child,
    this.title,
    this.subtitle,
    this.eyebrow,
    this.showBack = true,
    this.onBack,
    this.backEnabled = true,
    this.stepLabel,
    this.progress,
    this.progressSemanticLabel,
    this.footer,
    this.pageKey,
    super.key,
  });

  final String? title;
  final String? subtitle;

  /// Above the title, e.g. [AuthBrandRow] on sign-in.
  final Widget? eyebrow;
  final bool showBack;
  final VoidCallback? onBack;
  final bool backEnabled;

  /// "Step 2 of 6", top right of the header.
  final String? stepLabel;

  /// The gold bar under the top row, 0–1. Null hides it.
  final double? progress;
  final String? progressSemanticLabel;

  /// The actions. Null leaves the page without a footer.
  final Widget? footer;
  final Key? pageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final Widget? footer = this.footer;
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: Material(
        key: pageKey,
        color: BrandColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    WaveHeader(
                      title: title,
                      subtitle: subtitle,
                      eyebrow: eyebrow,
                      showBack: showBack,
                      onBack: onBack,
                      backEnabled: backEnabled,
                      stepLabel: stepLabel,
                      progress: progress,
                      progressSemanticLabel: progressSemanticLabel,
                    ),
                    // CSS `.obbody.after`: 8 under the wave, 20 at the sides.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.formGutter,
                        Spacing.sm,
                        Spacing.formGutter,
                        Spacing.xl,
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Spacing.formGutter,
                  Spacing.md,
                  Spacing.formGutter,
                  Spacing.xl + safeBottom,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Sign-in's seal and brand line on the wave header (CSS `.brandrow`).
class AuthBrandRow extends StatelessWidget {
  const AuthBrandRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const HeaderSeal(diameter: _brandSeal),
        const SizedBox(width: Spacing.sm + Spacing.xxs),
        Flexible(
          child: Text(
            'Bayan ng Taytay · Lalawigan ng Rizal',
            style: AppTypography.listDetail.copyWith(
              fontWeight: AppTypography.strong,
              color: BrandColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}

/// `.brandrow .seal`: 40 px.
const double _brandSeal = 40;

/// A labelled filled field (CSS `.fld` + `.ifield` + `.inp`): the label
/// above, the field filled `#F2F4F8` with an optional leading icon, and the
/// error or [hint] below. The fill, radius and focus ring come from the
/// theme's input decoration.
///
/// [onTap] with [readOnly] makes it a picker (the barangay); [trailing] holds
/// a control inside the field, such as Show / Hide.
class AuthField extends StatelessWidget {
  const AuthField({
    required this.label,
    required this.controller,
    this.requiredField = false,
    this.icon,
    this.error,
    this.hint,
    this.placeholder,
    this.obscure = false,
    this.readOnly = false,
    this.enabled = true,
    this.trailing,
    this.onTap,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.fieldKey,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Adds a red asterisk to the label.
  final bool requiredField;
  final IconData? icon;
  final String? error;

  /// Help under the field, shown when there is no error (CSS `.hint`).
  final String? hint;
  final String? placeholder;
  final bool obscure;
  final bool readOnly;
  final bool enabled;
  final Widget? trailing;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  /// Key for the editable itself, so a test can find one field among many.
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final IconData? icon = this.icon;
    final String? hint = this.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AuthFieldLabel(label, requiredField: requiredField),
        const SizedBox(height: Spacing.sm),
        TextFormField(
          key: fieldKey,
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          style: AppTypography.fieldValue.copyWith(color: BrandColors.ink),
          decoration: InputDecoration(
            hintText: placeholder,
            errorText: error,
            errorMaxLines: 3,
            prefixIcon: icon == null
                ? null
                : TaytayIcon(
                    icon: icon,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: IconSizes.sm,
                  ),
            suffixIcon: trailing,
          ),
        ),
        if (hint != null && error == null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(
              hint,
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// A field label (CSS `.fld`): 12.5 / 600 in body colour, with a red
/// asterisk when [requiredField].
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {this.requiredField = false, super.key});

  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: AppTypography.label.copyWith(color: BrandColors.text),
        children: <InlineSpan>[
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: BrandColors.redInk),
            ),
        ],
      ),
    );
  }
}

/// A text action (CSS `.soft .link`): 13.5 / 600, blue and underlined, in a
/// 48 dp target. [muted] is the grey "Continue as guest".
class AuthLink extends StatelessWidget {
  const AuthLink(
    this.label, {
    required this.onPressed,
    this.muted = false,
    this.alignment = Alignment.center,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool muted;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final Color ink = muted ? BrandColors.muted : BrandColors.blue;
    return Align(
      alignment: alignment,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: AppTypography.listTitle.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: ink,
          ),
        ),
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
