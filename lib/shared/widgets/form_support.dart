import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../features/registration/domain/registration_validation.dart';
import 'app_banner.dart';

/// Lists everything wrong on the current step, above the fields.
///
/// ---
///
/// **Why a summary as well as inline messages.** An inline message sits beside
/// its field, which means a resident whose invalid field is below the fold sees
/// a form that simply refuses to continue with no visible reason. It is worse
/// for a screen-reader user: focus stays on the button, and nothing announces
/// what happened.
///
/// So the summary is a live region placed at the top, focus moves to it when
/// submission fails, and each entry names its field. This is the pattern the
/// GOV.UK Design System settled on for exactly this problem, and the reasoning
/// carries: a government form is used once, under time pressure, by people who
/// will not hunt for the reason it stopped.
class FormErrorSummary extends StatelessWidget {
  const FormErrorSummary({required this.errors, this.focusNode, super.key});

  final List<FieldError> errors;

  /// Focused after a failed attempt, so assistive technology lands here.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Focus(
      focusNode: focusNode,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Spacing.lg),
        child: AppBanner(
          tone: BannerTone.error,
          title: errors.length == 1
              ? 'There is a problem'
              : 'There are ${errors.length} problems',
          message: '',
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final error in errors)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xs),
                  child: Text(
                    '• ${error.message}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
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

/// A field label that states whether it is required.
///
/// **Both states are labelled, not just one.** Marking only required fields with
/// an asterisk leaves a resident inferring that everything unmarked is optional
/// — and an asterisk carries no meaning at all to a screen reader unless it is
/// spelled out. Saying "(optional)" in words costs a little space and removes
/// the guess.
class FieldLabel extends StatelessWidget {
  const FieldLabel({
    required this.label,
    this.required = true,
    this.hint,
    super.key,
  });

  final String label;
  final bool required;

  /// Format guidance shown under the label — "as it appears on your ID".
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          required ? label : '$label (optional)',
          style: theme.textTheme.titleSmall,
        ),
        if (hint != null) ...<Widget>[
          const SizedBox(height: Spacing.xxs),
          Text(
            hint!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: Spacing.sm),
      ],
    );
  }
}

/// An expandable explanation of why a sensitive field is being collected.
///
/// ---
///
/// **This is a transparency obligation, not a nicety.** RA 10173 requires that a
/// data subject be informed of the purpose of processing, and consent is only
/// informed if the purpose is available at the moment of collection — not buried
/// in a privacy notice a resident agreed to three screens earlier.
///
/// Collapsed by default so it does not crowd the form, expandable in place so
/// reading it never costs a resident their progress. Each panel states the
/// purpose, who sees it, and what happens if the resident declines.
class WhyWeAsk extends StatelessWidget {
  const WhyWeAsk({
    required this.purpose,
    required this.whoSeesIt,
    this.ifYouDecline,
    this.title = 'Why we ask for this',
    super.key,
  });

  /// What the LGU does with it.
  final String purpose;

  /// Who inside the LGU can see it.
  final String whoSeesIt;

  /// What happens if it is not provided. Omitted for genuinely required data.
  final String? ifYouDecline;

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      // Removes the default divider lines so the panel reads as part of the
      // field rather than as a separate section.
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: Spacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: Icon(
          Icons.help_outline,
          size: IconSizes.sm,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        children: <Widget>[
          _Line(label: 'Why', value: purpose),
          _Line(label: 'Who sees it', value: whoSeesIt),
          if (ifYouDecline != null)
            _Line(label: 'If you would rather not', value: ifYouDecline!),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

/// Guidance shown above an upload control.
///
/// Says what a good photo looks like *before* the picker opens. A resident who
/// finds out their photo was unreadable after a review queue rejected it days
/// later has lost days for a reason nobody told them.
class UploadGuidance extends StatelessWidget {
  const UploadGuidance({required this.points, super.key});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('For this to be accepted', style: theme.textTheme.titleSmall),
          const SizedBox(height: Spacing.sm),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.check,
                    size: IconSizes.sm,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(point, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
