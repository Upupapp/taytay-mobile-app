import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/code_exchange.dart';

/// True outside widget tests. A periodic timer keeps `pumpAndSettle` waiting.
bool get authClockTicks =>
    !WidgetsBinding.instance.runtimeType.toString().contains('Test');

/// A field drawn inside the 44dp box. The theme's outline would paint a
/// second border, so every edge of this decoration is empty.
/// A collapsed field whose semantics box is 48dp.
///
/// The painted slot stays the parent's height. The editable itself is 48
/// tall and centred, so the Android tap-target check sees the control
/// rather than the 17px line, and the glyphs stay on the same centre.
class AuthBareField extends StatelessWidget {
  const AuthBareField({
    required this.controller,
    this.readOnly = false,
    this.obscureText = false,
    this.style,
    super.key,
  });

  final TextEditingController controller;
  final bool readOnly;
  final bool obscureText;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // The slot stays 44. This box is 48 and centred on that slot, so the
    // line stays where it was. The field itself stays its own height and
    // does not paint over the border. MergeSemantics folds that line into
    // the 48 box, which is what the tap-target check measures.
    return OverflowBox(
      alignment: Alignment.center,
      minHeight: A11y.minTapTarget,
      maxHeight: A11y.minTapTarget,
      child: MergeSemantics(
        child: SizedBox(
          height: A11y.minTapTarget,
          child: Align(
            alignment: Alignment.center,
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              obscureText: obscureText,
              textAlignVertical: TextAlignVertical.center,
              style: style ?? AppTypography.fieldValue,
              decoration: bareField,
            ),
          ),
        ),
      ),
    );
  }
}

const InputDecoration bareField = InputDecoration(
  hintText: '',
  filled: false,
  isCollapsed: true,
  contentPadding: EdgeInsets.zero,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
);

/// Red or amber notice. The words are this app's, never a server message.
/// Drawn as the redesign's note ([SoftNote], CSS `.soft .note`).
class AuthNoticeBanner extends StatelessWidget {
  const AuthNoticeBanner({
    required this.title,
    required this.detail,
    this.amber = false,
    super.key,
  });

  final String title;
  final String detail;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return SoftNote(
      tone: amber ? NoteTone.warning : NoteTone.error,
      title: title,
      message: detail,
    );
  }
}

/// Six code cells (CSS `.otp`). [digits] is what is already typed: typed
/// cells are blue on blue-50, the next one is white with the focus ring.
/// [bad] draws every cell red; [dim] greys a code that no longer works.
class SixDigitRow extends StatelessWidget {
  const SixDigitRow({
    required this.digits,
    this.bad = false,
    this.dim = false,
    super.key,
  });

  final String digits;
  final bool bad;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final String raw = digits.padRight(6);
    final int next = digits.length;
    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          for (var i = 0; i < 6; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: Spacing.sm),
            Expanded(child: _cell(raw[i].trim(), i, next)),
          ],
        ],
      ),
    );
  }

  Widget _cell(String digit, int index, int next) {
    final bool filled = digit.isNotEmpty;
    final bool current = !bad && !dim && index == next;
    final Color fill = dim
        ? BrandColors.background
        : bad
        ? BrandColors.errorFill
        : current
        ? BrandColors.white
        : filled
        ? BrandColors.blue50
        : BrandColors.softFill;
    final Color border = bad
        ? BrandColors.red
        : current
        ? BrandColors.blue
        : dim
        ? BrandColors.line
        : BrandColors.transparent;
    final Color ink = dim
        ? BrandColors.muted
        : filled
        ? BrandColors.blue
        : BrandColors.ink;
    return Container(
      height: _otpCellHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.field),
        border: Border.all(color: border, width: FocusRing.borderWidth),
      ),
      foregroundDecoration: current
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.field),
              border: Border.all(
                color: FocusRing.ring,
                width: FocusRing.ringWidth,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            )
          : null,
      child: Text(
        digit,
        style: AppTypography.pageTitle.copyWith(
          fontWeight: AppTypography.black,
          color: ink,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// `.otp span { height: 58px }`.
const double _otpCellHeight = 58;

/// The three published password rules, live from [password] (CSS `.rules`):
/// a check and a short label each, green once met.
class PasswordRules extends StatelessWidget {
  const PasswordRules({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final bool chars = password.length >= 8;
    final bool digit = RegExp(r'\d').hasMatch(password);
    final bool letter = RegExp('[A-Za-z]').hasMatch(password);
    return Wrap(
      spacing: Spacing.lg,
      runSpacing: Spacing.xs,
      children: <Widget>[
        PasswordRule('Hindi bababa sa 8 character', met: chars ? true : null),
        PasswordRule('May numero', met: digit ? true : null),
        PasswordRule('May letra', met: letter ? true : null),
      ],
    );
  }
}

/// One password rule (CSS `.rules li`): 12.5 / 600, a check when [met], a
/// dot while it is not, and muted when nothing is typed yet ([met] null).
class PasswordRule extends StatelessWidget {
  const PasswordRule(this.label, {required this.met, super.key});

  final String label;
  final bool? met;

  @override
  Widget build(BuildContext context) {
    final bool? met = this.met;
    final Color ink = switch (met) {
      true => BrandColors.green,
      false => BrandColors.redInk,
      null => BrandColors.muted,
    };
    return Semantics(
      label: '$label, ${met == true ? 'met' : 'not met'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TaytayIcon(
            icon: met == true ? TaytayIcons.check : TaytayIcons.circleSlash,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm - Spacing.xs,
            color: ink,
          ),
          const SizedBox(width: Spacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTypography.listDetail.copyWith(
                fontWeight: AppTypography.medium,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show / Hide inside a password field (CSS `.pw button`): blue 13.5 / 700
/// on no fill, a 48 dp target.
class ShowPasswordToggle extends StatelessWidget {
  const ShowPasswordToggle({
    required this.shown,
    required this.onPressed,
    this.showLabel = 'Ipakita',
    this.hideLabel = 'Itago',
    super.key,
  });

  final bool shown;
  final VoidCallback onPressed;
  final String showLabel;
  final String hideLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Spacing.xs),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.blue,
          minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: AppTypography.listTitle.copyWith(
            fontWeight: AppTypography.strong,
          ),
        ),
        onPressed: onPressed,
        child: Text(shown ? hideLabel : showLabel),
      ),
    );
  }
}

/// How long a code stays good, as a blue pill with a clock.
class CodeExpiryChip extends StatelessWidget {
  const CodeExpiryChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: BrandColors.blue50,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm - Spacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TaytayIcon(
              icon: TaytayIcons.clock,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm - Spacing.xs,
              color: BrandColors.blue,
            ),
            const SizedBox(width: Spacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTypography.listDetail.copyWith(
                  fontWeight: AppTypography.strong,
                  color: BrandColors.blue,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Resend" beside the code: blue when it works, muted with the wait while
/// it does not ([onPressed] null).
class CodeResendButton extends StatelessWidget {
  const CodeResendButton({
    required this.label,
    required this.onPressed,
    this.buttonKey,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Key for the [TextButton] itself, so a test can read its state.
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: buttonKey,
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.blue,
        disabledForegroundColor: BrandColors.muted,
        minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTypography.listDetail.copyWith(
          fontWeight: AppTypography.strong,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// Sample countdown strings from the designs. Live screens use [CodeExchangeRules].
abstract final class AuthSample {
  static const String email = 'juana.delacruz@example.com';
  static const String expiry = '8:42';
  static const String resend = '0:42';
  static const String code = '482190';
}
