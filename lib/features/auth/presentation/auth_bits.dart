import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../domain/code_exchange.dart';

/// True outside widget tests. A periodic timer keeps `pumpAndSettle` waiting.
bool get authClockTicks =>
    !WidgetsBinding.instance.runtimeType.toString().contains('Test');

/// Red or amber notice. The words are this app's, never a server message.
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
    final Color ink = amber ? const Color(0xFF6B4600) : const Color(0xFF7A1C16);
    final Color icon = amber
        ? const Color(0xFF8A5A00)
        : const Color(0xFFB3261E);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: amber ? const Color(0xFFFFF4D6) : const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: amber ? const Color(0xFFF0D48A) : const Color(0xFFF3C1BE),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              amber ? Icons.schedule : Icons.error_outline,
              size: 18,
              color: icon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: AppTypography.medium,
                    color: ink,
                  ),
                  children: <InlineSpan>[
                    TextSpan(
                      text: title,
                      style: const TextStyle(fontWeight: AppTypography.black),
                    ),
                    TextSpan(text: detail),
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

/// Six code cells. [digits] is what is already typed.
class SixDigitRow extends StatelessWidget {
  const SixDigitRow({required this.digits, this.bad = false, super.key});

  final String digits;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    final String raw = digits.padRight(6);
    return Row(
      children: <Widget>[
        for (var i = 0; i < 6; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bad ? const Color(0xFFFFF7F7) : BrandColors.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: bad
                      ? const Color(0xFFB3261E)
                      : BrandColors.fieldBorder,
                  width: 1.4,
                ),
                boxShadow: bad
                    ? const <BoxShadow>[
                        BoxShadow(color: Color(0x1AB3261E), spreadRadius: 3),
                      ]
                    : null,
              ),
              child: Text(
                raw[i].trim(),
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 22,
                  fontWeight: AppTypography.black,
                  color: Color(0xFF1C2540),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The three published password rules, live from [password].
class PasswordRules extends StatelessWidget {
  const PasswordRules({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final bool chars = password.length >= 8;
    final bool digit = RegExp(r'\d').hasMatch(password);
    final bool letter = RegExp('[A-Za-z]').hasMatch(password);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: <Widget>[
        _Rule('Hindi bababa sa 8 character', met: chars),
        _Rule('May numero', met: digit),
        _Rule('May letra', met: letter),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.label, {required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final Color ink = met ? const Color(0xFF0F7A4D) : const Color(0xFF5B6680);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check, size: 13, color: ink),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: AppTypography.strong,
              color: ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Ipakita" / "Itago". The painted row stays 44; the hit target is 48.
class ShowPasswordToggle extends StatelessWidget {
  const ShowPasswordToggle({
    required this.shown,
    required this.onPressed,
    super.key,
  });

  final bool shown;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 44,
      child: OverflowBox(
        maxWidth: 120,
        maxHeight: 48,
        alignment: Alignment.centerRight,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5B6680),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: AppTypography.strong,
            ),
          ),
          onPressed: onPressed,
          child: Text(shown ? 'Itago' : 'Ipakita'),
        ),
      ),
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
