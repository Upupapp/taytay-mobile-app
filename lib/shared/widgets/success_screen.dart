import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/taytay_icons.dart';
import '../../core/design/typography.dart';
import 'taytay_buttons.dart';
import 'taytay_icon.dart';
import 'wave_header.dart';

/// The two success marks of the design.
enum SuccessMarkStyle {
  /// MessageSent `.badge`: a white disc with a gold ring and a green tick.
  badge,

  /// RegDone `.medal`: a gold disc in a soft white halo with a navy tick.
  medal,
}

/// The success mark drawn on the wave header. Decorative: the title says
/// what succeeded.
class SuccessMark extends StatelessWidget {
  const SuccessMark({this.style = SuccessMarkStyle.badge, super.key});

  final SuccessMarkStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget mark = switch (style) {
      SuccessMarkStyle.badge => Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: BrandColors.gold, width: 4),
        ),
        child: const TaytayIcon(
          icon: TaytayIcons.check,
          semanticLabel: '',
          excludeSemantics: true,
          size: 30,
          color: BrandColors.green,
        ),
      ),
      SuccessMarkStyle.medal => Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BrandColors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: BrandColors.gold,
            shape: BoxShape.circle,
          ),
          child: const TaytayIcon(
            icon: TaytayIcons.check,
            semanticLabel: '',
            excludeSemantics: true,
            size: 34,
            color: BrandColors.navy,
          ),
        ),
      ),
    };
    return ExcludeSemantics(child: mark);
  }
}

/// One labelled line of a success receipt ("To · MSWDO").
@immutable
class SuccessDetail {
  const SuccessDetail({required this.label, required this.value});

  final String label;
  final String value;
}

/// The result step of a form flow (MessageSent, RegDone): a centred wave
/// header with a [SuccessMark], the [title] and [message], then a receipt of
/// [details] with an optional [note] under a perforation, any extra [body],
/// and the actions at the foot.
///
/// Fills its parent: put it in a route's body. Header and receipt scroll
/// together, so 200% text never clips; the actions stay at the foot.
///
/// The title is announced when the screen appears. Every value — what was
/// sent, a reference number, when to expect a reply — comes from the caller.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    this.message,
    this.details = const <SuccessDetail>[],
    this.note,
    this.body,
    this.secondaryLabel,
    this.onSecondary,
    this.mark = SuccessMarkStyle.badge,
    this.stepLabel,
    this.progress,
    this.progressSemanticLabel,
    this.showBack = false,
    this.onBack,
    super.key,
  });

  final String title;
  final String? message;
  final List<SuccessDetail> details;

  /// The sentence under the receipt's perforation.
  final String? note;

  /// Anything else the step shows, e.g. a status card.
  final Widget? body;

  final String primaryLabel;
  final VoidCallback? onPrimary;

  /// A quiet text link under the main button ("Back to Directory").
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  final SuccessMarkStyle mark;

  /// Registration's last "Step 6 of 6" and full bar.
  final String? stepLabel;
  final double? progress;
  final String? progressSemanticLabel;

  /// A back control on the header, for a result that is a route of its own
  /// (every non-root route has one). [onBack] overrides the default pop.
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Widget? body = this.body;
    final String? secondaryLabel = this.secondaryLabel;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final bool hasReceipt = details.isNotEmpty || note != null;

    return Material(
      color: BrandColors.white,
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    liveRegion: true,
                    child: WaveHeader(
                      title: title,
                      subtitle: message,
                      centered: true,
                      badge: SuccessMark(style: mark),
                      stepLabel: stepLabel,
                      progress: progress,
                      progressSemanticLabel: progressSemanticLabel,
                      showBack: showBack,
                      onBack: onBack,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.formGutter,
                      Spacing.xs,
                      Spacing.formGutter,
                      Spacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (hasReceipt) _Receipt(details: details, note: note),
                        if (hasReceipt && body != null)
                          const SizedBox(height: Spacing.lg),
                        ?body,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Spacing.formGutter,
              Spacing.md,
              Spacing.formGutter,
              Spacing.xl + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PrimaryButton(label: primaryLabel, onPressed: onPrimary),
                if (secondaryLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.sm),
                    child: TextButton(
                      onPressed: onSecondary,
                      style: TextButton.styleFrom(
                        foregroundColor: BrandColors.blue,
                        minimumSize: const Size(0, A11y.minTapTarget),
                        textStyle: AppTypography.link.copyWith(
                          fontWeight: AppTypography.strong,
                        ),
                      ),
                      child: Text(secondaryLabel),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// MessageSent `.rcpt`: soft fill, radius 18, rows of label and value, then a
/// dashed perforation with notches and the note.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.details, required this.note});

  final List<SuccessDetail> details;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final String? note = this.note;
    final TextStyle rowStyle = AppTypography.bodyStyle.copyWith(height: 1.35);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: BrandColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < details.length; i++)
                      Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : Spacing.md),
                        child: MergeSemantics(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  details[i].label,
                                  style: rowStyle.copyWith(
                                    color: BrandColors.muted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Spacing.lg),
                              Expanded(
                                child: Text(
                                  details[i].value,
                                  textAlign: TextAlign.end,
                                  style: rowStyle.copyWith(
                                    fontWeight: AppTypography.strong,
                                    color: BrandColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (details.isNotEmpty && note != null) const _Perforation(),
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: TaytayIcon(
                        icon: TaytayIcons.info,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: 18,
                        color: BrandColors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note,
                        style: AppTypography.listDetail.copyWith(
                          height: 1.5,
                          color: BrandColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox(
        height: 22,
        child: CustomPaint(painter: _PerforationPainter()),
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2;
    final Paint dash = Paint()
      ..color = BrandColors.line2
      ..strokeWidth = 2;
    const double inset = 18;
    for (double x = inset; x < size.width - inset; x += 10) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 5).clamp(0, size.width - inset), y),
        dash,
      );
    }
    final Paint notch = Paint()..color = BrandColors.white;
    canvas
      ..drawCircle(Offset(0, y), 11, notch)
      ..drawCircle(Offset(size.width, y), 11, notch);
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter oldDelegate) => false;
}
