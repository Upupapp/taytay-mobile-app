import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/assets/asset_manifest.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gold_thread_shell.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_headers.dart';
import '../../../shared/widgets/taytay_thread.dart';
import '../../../shared/widgets/welcome_backdrop.dart';

const TextHeightBehavior _cssHalfLeading = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

/// CSS `.body` is 14 × 1.55 = 21.7. Without a forced strut, the line box
/// rounds up to a whole logical pixel (22), and by the third line the ink
/// is about 4 device pixels low at 3×.
const StrutStyle _welcomeBodyStrut = StrutStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: AppTypography.body,
  height: 1.55,
  leadingDistribution: TextLeadingDistribution.even,
  forceStrutHeight: true,
);

/// Copy for one welcome page. The screen builds it from l10n. Goldens pass
/// the same design strings.
@immutable
class WelcomePageCopy {
  const WelcomePageCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.chips,
    required this.tag,
    required this.credit,
    required this.photoPath,
    required this.photoLabel,
    required this.skipLabel,
    required this.nextLabel,
    required this.getStartedLabel,
    required this.guestLabel,
    required this.guestNote,
    required this.stepLabel,
  });

  final String eyebrow;
  final String title;
  final String body;
  final List<String> chips;
  final String tag;
  final String credit;
  final String photoPath;
  final String photoLabel;
  final String skipLabel;
  final String nextLabel;
  final String getStartedLabel;
  final String guestLabel;
  final String guestNote;
  final String stepLabel;

  static List<WelcomePageCopy> fromStrings(AppStrings strings) {
    String photo(String key) => AppAssets.byKey(key)!.path;
    String label(String key) => AppAssets.byKey(key)!.semanticLabel;
    return <WelcomePageCopy>[
      WelcomePageCopy(
        eyebrow: strings.welcomeServicesEyebrow,
        title: strings.welcomeServicesTitle,
        body: strings.welcomeServicesBody,
        chips: <String>[
          strings.welcomeServicesChipDocuments,
          strings.welcomeServicesChipTax,
          strings.welcomeServicesChipHealth,
          strings.welcomeServicesChipJobs,
        ],
        tag: strings.welcomeServicesTag,
        credit: strings.welcomeServicesCredit,
        photoPath: photo('municipal_hall'),
        photoLabel: label('municipal_hall'),
        skipLabel: strings.welcomeSkip,
        nextLabel: strings.welcomeNext,
        getStartedLabel: strings.welcomeGetStarted,
        guestLabel: strings.welcomeContinueAsGuest,
        guestNote: strings.welcomeGuestNote,
        stepLabel: strings.welcomeStep(1, 3),
      ),
      WelcomePageCopy(
        eyebrow: strings.welcomeIdEyebrow,
        title: strings.welcomeIdTitle,
        body: strings.welcomeIdBody,
        chips: <String>[
          strings.welcomeIdChipDigital,
          strings.welcomeIdChipQueue,
        ],
        tag: strings.welcomeIdTag,
        credit: strings.welcomeIdCredit,
        photoPath: photo('tiangge'),
        photoLabel: label('tiangge'),
        skipLabel: strings.welcomeSkip,
        nextLabel: strings.welcomeNext,
        getStartedLabel: strings.welcomeGetStarted,
        guestLabel: strings.welcomeContinueAsGuest,
        guestNote: strings.welcomeGuestNote,
        stepLabel: strings.welcomeStep(2, 3),
      ),
      WelcomePageCopy(
        eyebrow: strings.welcomePrivacyEyebrow,
        title: strings.welcomePrivacyTitle,
        body: strings.welcomePrivacyBody,
        chips: const <String>[],
        tag: strings.welcomePrivacyTag,
        credit: strings.welcomePrivacyCredit,
        photoPath: photo('parish_church'),
        photoLabel: label('parish_church'),
        skipLabel: strings.welcomeSkip,
        nextLabel: strings.welcomeNext,
        getStartedLabel: strings.welcomeGetStarted,
        guestLabel: strings.welcomeContinueAsGuest,
        guestNote: strings.welcomeGuestNote,
        stepLabel: strings.welcomeStep(3, 3),
      ),
    ];
  }
}

/// One welcome page laid out on the 390×844 design canvas.
class WelcomeCanvas extends StatelessWidget {
  const WelcomeCanvas({
    required this.page,
    required this.copy,
    required this.onSkip,
    this.lightT,
    this.onNext,
    this.onBack,
    this.onGetStarted,
    this.onGuest,
    super.key,
  });

  final int page;
  final WelcomePageCopy copy;

  /// Null hides the speck. Goldens and reduced motion pass null.
  final double? lightT;

  final VoidCallback onSkip;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onGetStarted;
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    final arch = _arches[page];
    final curve = ThreadCurve.pages[page];
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.01;
    final showBack = page > 0;
    final last = page == 2;
    final lightT = this.lightT;
    // The shell paints the field and the thread so they survive a route
    // change. A golden pumps this canvas on its own and still paints both.
    final bool hosted = GoldThreadScope.maybeOf(context) != null;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[
        if (!hosted) Positioned.fill(child: GradientBackdrop(page: page)),
        _BackCard(arch: arch),
        _ArchPhoto(arch: arch, copy: copy),
        _Seam(arch: arch),
        if (!hosted)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: ThreadPainter(curve)),
            ),
          ),
        if (!arch.knotsInCopy)
          Positioned.fill(
            child: IgnorePointer(
              child: KnotIndicator(active: page, label: copy.stepLabel),
            ),
          ),
        if (!hosted && lightT != null)
          Positioned.fill(
            child: TravellingLight(curve: curve, t: lightT),
          ),
        Positioned(
          top: 46,
          left: 0,
          right: 0,
          child: WovenHeader(
            welcome: true,
            showBack: showBack,
            onBack: onBack,
            paintField: false,
            includeSafeArea: false,
            padding: EdgeInsets.fromLTRB(showBack ? 20 : 22, 0, 22, 0),
            trailing: _SkipButton(label: copy.skipLabel, onPressed: onSkip),
          ),
        ),
        Positioned(
          left: arch.tagLeft,
          top: arch.tagTop,
          child: _PhotoTag(copy.tag),
        ),
        Positioned(
          right: arch.creditRight,
          top: arch.creditTop,
          child: _Credit(copy.credit),
        ),
        if (large)
          Positioned(
            top: arch.textTop,
            left: 26,
            right: 26,
            bottom: last ? 220 : 110,
            child: SingleChildScrollView(
              child: _Copy(copy: copy, page: page),
            ),
          )
        else
          Positioned(
            top: arch.textTop,
            left: 26,
            right: 26,
            child: _Copy(copy: copy, page: page),
          ),
        if (!last)
          Positioned(
            right: 24,
            bottom: 30,
            child: _NextButton(label: copy.nextLabel, onPressed: onNext),
          )
        else
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: _Finish(
              copy: copy,
              onGetStarted: onGetStarted,
              onGuest: onGuest,
            ),
          ),
      ],
    );
  }
}

class _Arch {
  const _Arch({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.degrees,
    required this.shiftX,
    required this.seamLeft,
    required this.seamTop,
    required this.seamWidth,
    required this.seamHeight,
    required this.tagLeft,
    required this.tagTop,
    required this.creditRight,
    required this.creditTop,
    required this.textTop,
    required this.knotsInCopy,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double degrees;
  final double shiftX;
  final double seamLeft;
  final double seamTop;
  final double seamWidth;
  final double seamHeight;
  final double tagLeft;
  final double tagTop;
  final double creditRight;
  final double creditTop;
  final double textTop;
  final bool knotsInCopy;
}

const List<_Arch> _arches = <_Arch>[
  _Arch(
    left: 52,
    top: 116,
    width: 286,
    height: 356,
    degrees: -4,
    shiftX: -10,
    seamLeft: 60,
    seamTop: 124,
    seamWidth: 270,
    seamHeight: 340,
    tagLeft: 70,
    tagTop: 456,
    creditRight: 52,
    creditTop: 494,
    textTop: 526,
    knotsInCopy: false,
  ),
  _Arch(
    left: 52,
    top: 116,
    width: 286,
    height: 356,
    degrees: 4,
    shiftX: 10,
    seamLeft: 60,
    seamTop: 124,
    seamWidth: 270,
    seamHeight: 340,
    tagLeft: 70,
    tagTop: 456,
    creditRight: 52,
    creditTop: 494,
    textTop: 526,
    knotsInCopy: false,
  ),
  _Arch(
    left: 62,
    top: 116,
    width: 266,
    height: 296,
    degrees: -3,
    shiftX: -10,
    seamLeft: 70,
    seamTop: 124,
    seamWidth: 250,
    seamHeight: 280,
    tagLeft: 80,
    tagTop: 396,
    creditRight: 62,
    creditTop: 434,
    textTop: 458,
    knotsInCopy: true,
  ),
];

const BorderRadius _archRadius = BorderRadius.only(
  topLeft: Radius.circular(145),
  topRight: Radius.circular(145),
  bottomLeft: Radius.circular(26),
  bottomRight: Radius.circular(26),
);

class _BackCard extends StatelessWidget {
  const _BackCard({required this.arch});

  final _Arch arch;

  @override
  Widget build(BuildContext context) {
    // CSS is `left`/`top` plus `translate` then `rotate`. The translation is
    // in the parent's axes, so it is the same as placing the box there and
    // rotating about its centre.
    return Positioned(
      left: arch.left + arch.shiftX,
      top: arch.top + 10,
      width: arch.width,
      height: arch.height,
      child: Transform.rotate(
        angle: arch.degrees * math.pi / 180,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: _archRadius,
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFF1E5BC6),
                BrandColors.taytayBlue,
                BrandColors.taytayBlueDark,
              ],
              stops: <double>[0, 0.45, 1],
              transform: GradientRotation(160 * math.pi / 180 - math.pi / 2),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x40062358),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchPhoto extends StatelessWidget {
  const _ArchPhoto({required this.arch, required this.copy});

  final _Arch arch;
  final WelcomePageCopy copy;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: arch.left,
      top: arch.top,
      width: arch.width,
      height: arch.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: _archRadius,
          // CSS paints the first shadow on top. Flutter paints the last one
          // on top, so the white rim is last. `0 0 0 5px #fff`.
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x47062358),
              blurRadius: 44,
              offset: Offset(0, 22),
            ),
            BoxShadow(color: Colors.white, spreadRadius: 5),
          ],
        ),
        child: ClipRRect(
          borderRadius: _archRadius,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                copy.photoPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                semanticLabel: copy.photoLabel,
                gaplessPlayback: true,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0x00062358), Color(0x59062358)],
                    stops: <double>[0.6, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seam extends StatelessWidget {
  const _Seam({required this.arch});

  final _Arch arch;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: arch.seamLeft,
      top: arch.seamTop,
      width: arch.seamWidth,
      height: arch.seamHeight,
      child: const IgnorePointer(child: CustomPaint(painter: _SeamPainter())),
    );
  }
}

class _SeamPainter extends CustomPainter {
  const _SeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          rect.deflate(0.8),
          topLeft: const Radius.circular(137),
          topRight: const Radius.circular(137),
          bottomLeft: const Radius.circular(19),
          bottomRight: const Radius.circular(19),
        ),
      );
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0x59000000);
    canvas.save();
    canvas.translate(0, 1);
    _dash(canvas, path, shadow, dash: 4, gap: 3);
    canvas.restore();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xD9FFFFFF);
    _dash(canvas, path, paint, dash: 4, gap: 3);
  }

  @override
  bool shouldRepaint(covariant _SeamPainter oldDelegate) => false;
}

class _Copy extends StatelessWidget {
  const _Copy({required this.copy, required this.page});

  final WelcomePageCopy copy;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Eyebrow(copy.eyebrow),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            copy.title,
            textHeightBehavior: _cssHalfLeading,
            style: AppTypography.h1.copyWith(color: BrandColors.taytayBlueDark),
          ),
        ),
        const SizedBox(height: 10),
        _WelcomeBody(copy.body),
        if (copy.chips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: <Widget>[
              for (final chip in copy.chips) _WelcomeChip(chip),
            ],
          ),
        ],
        if (_arches[page].knotsInCopy) ...<Widget>[
          // w3.html keeps an empty `.chips` (margin-top 14) and then the knot
          // svg (margin-top 14). The row sits 28 px under the body.
          const SizedBox(height: 28),
          KnotIndicator(active: page, label: copy.stepLabel, inline: true),
        ],
      ],
    );
  }
}

/// Welcome body at CSS `14 × 1.55`.
///
/// The strut asks for that leading. The engine still rounds the line box to
/// a whole logical pixel (22), which is about 4 device pixels low by line 3
/// at 3×. Each line keeps the strut, and the line tops are placed `14 × 1.55`
/// apart so they follow the design instead of the rounded box.
class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyStyle.copyWith(
      color: BrandColors.welcomeCopy,
      height: 1.55,
    );
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scaler = MediaQuery.textScalerOf(context);
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              textHeightBehavior: _cssHalfLeading,
              strutStyle: _welcomeBodyStrut,
            )..layout(maxWidth: constraints.maxWidth);
            final lines = <String>[];
            var start = 0;
            while (start < text.length) {
              final range = painter.getLineBoundary(
                TextPosition(offset: start),
              );
              if (range.end <= start) break;
              lines.add(text.substring(range.start, range.end).trimRight());
              start = range.end;
            }
            final metrics = painter.computeLineMetrics();
            final step = 14 * scaler.scale(1) * 1.55;
            final lineBox = metrics.isEmpty ? step : metrics.first.height;
            painter.dispose();
            return SizedBox(
              width: constraints.maxWidth,
              height: lines.isEmpty ? 0 : step * (lines.length - 1) + lineBox,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var i = 0; i < lines.length; i++)
                    Positioned(
                      top: i * step,
                      left: 0,
                      right: 0,
                      child: Text(
                        lines[i],
                        maxLines: 1,
                        softWrap: false,
                        textHeightBehavior: _cssHalfLeading,
                        strutStyle: _welcomeBodyStrut,
                        style: style,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const CustomPaint(
          size: Size(18, 2),
          painter: _DashPainter(color: BrandColors.threadGold, strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text.toUpperCase(),
            textHeightBehavior: _cssHalfLeading,
            style: AppTypography.eyebrow.copyWith(color: BrandColors.inkGold),
          ),
        ),
      ],
    );
  }
}

class _WelcomeChip extends StatelessWidget {
  const _WelcomeChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _ChipDashPainter(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A062358),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(
            label,
            textHeightBehavior: _cssHalfLeading,
            style: AppTypography.eyebrow.copyWith(
              letterSpacing: 0,
              fontWeight: FontWeight.w700,
              color: BrandColors.taytayBlue,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipDashPainter extends CustomPainter {
  const _ChipDashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    if (rect.width <= 0 || rect.height <= 0) return;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x8C0B3D91);
    _dash(canvas, path, paint, dash: 3, gap: 3);
  }

  @override
  bool shouldRepaint(covariant _ChipDashPainter oldDelegate) => false;
}

class _PhotoTag extends StatelessWidget {
  const _PhotoTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrandColors.sealGold,
        borderRadius: BorderRadius.circular(999),
        // CSS paints the first shadow on top. The white ring is last so it
        // is not covered by the drop shadow. `0 0 0 2px #fff`.
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33062358),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
          BoxShadow(color: Colors.white, spreadRadius: 2),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Text(
          label,
          textHeightBehavior: _cssHalfLeading,
          style: AppTypography.eyebrow.copyWith(
            letterSpacing: 0,
            color: BrandColors.taytayBlueDark,
          ),
        ),
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF0F3F5FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          textHeightBehavior: _cssHalfLeading,
          style: AppTypography.eyebrow.copyWith(
            letterSpacing: 0.2,
            fontWeight: FontWeight.w700,
            color: BrandColors.creditInk,
          ),
        ),
      ),
    );
  }
}

/// Hit target for Skip. The painted pill is 44 dp, centred in this 48 dp box,
/// the same split as the back control.
const Key welcomeSkipTargetKey = Key('welcome-skip-target');

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: welcomeSkipTargetKey,
      height: A11y.minTapTarget,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x1A062358),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(color: Color(0x1A0B3D91), spreadRadius: 1),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: A11y.backButtonVisual,
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.linkSkip.copyWith(
                        color: BrandColors.taytayBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: TaytayButtonMetrics.welcome.primaryShadow,
      ),
      child: Material(
        color: BrandColors.taytayBlue,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 22, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: AppTypography.buttonWelcome.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CustomPaint(
                    size: Size(20, 20),
                    painter: _ArrowPainter(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = BrandColors.sealGold;
    canvas.drawLine(const Offset(5, 12), const Offset(19, 12), paint);
    final head = Path()
      ..moveTo(12, 5)
      ..lineTo(19, 12)
      ..lineTo(12, 19);
    canvas.drawPath(head, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => false;
}

class _Finish extends StatelessWidget {
  const _Finish({
    required this.copy,
    required this.onGetStarted,
    required this.onGuest,
  });

  final WelcomePageCopy copy;
  final VoidCallback? onGetStarted;
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PrimaryButton(
          kind: TaytayButtonKind.welcome,
          label: copy.getStartedLabel,
          onPressed: onGetStarted,
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          kind: TaytayButtonKind.welcome,
          label: copy.guestLabel,
          onPressed: onGuest,
        ),
        const SizedBox(height: 10),
        Text(
          copy.guestNote,
          textAlign: TextAlign.center,
          textHeightBehavior: _cssHalfLeading,
          style: AppTypography.listMeta.copyWith(color: BrandColors.textMuted),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);
    // Chrome's 2px dashed border on an 18px rule: three dashes, dash/gap 4/3.
    _dash(canvas, path, paint, dash: 4, gap: 3);
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

void _dash(
  Canvas canvas,
  Path path,
  Paint paint, {
  required double dash,
  required double gap,
}) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = math.min(distance + dash, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + gap;
    }
  }
}
