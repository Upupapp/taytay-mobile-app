import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/forms/field_error.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/form_support.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/assistance_intake.dart';
import 'assistance_intake_controller.dart';

/// Applying for one municipal service.
///
/// ---
///
/// **A wizard, not one long form.** A government application asked for on one
/// screen is abandoned: a resident cannot tell how much is left, an error at the
/// bottom is invisible from the top, and at a 200% text scale the whole thing is
/// a single unbounded scroll. Steps also mean a person can stop, and come back
/// to the step they were on rather than to the beginning.
///
/// **Every question comes from the server.** There is no per-service branch in
/// this file. See `assistance_intake.dart` for why that rule is absolute.
///
/// **Nothing here is a verdict.** The screen collects and sends. Whether the
/// resident qualifies, and what they receive, is decided by Taytay LGU staff —
/// the app does not assess, does not score, and does not hint.
class AssistanceIntakeScreen extends StatefulWidget {
  const AssistanceIntakeScreen({required this.serviceCode, super.key});

  final String serviceCode;

  @override
  State<AssistanceIntakeScreen> createState() => _AssistanceIntakeScreenState();
}

class _AssistanceIntakeScreenState extends State<AssistanceIntakeScreen> {
  AssistanceIntakeController? _controller;

  /// Focused when a step is rejected, so assistive technology lands on the
  /// summary rather than staying on the button that refused.
  final FocusNode _errorFocus = FocusNode();

  /// Fired once, on the transition into a successful outcome. Guarded so a
  /// rebuild cannot buzz the phone repeatedly for the same submission.
  bool _celebrated = false;

  /// The identifier arrives in a path and may have been typed, restored from the
  /// back stack or pasted from a message, so it is re-validated at the point of
  /// use rather than trusted because the router matched it.
  bool get _codeIsValid => DeepLink.isValidIdentifier(widget.serviceCode);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || !_codeIsValid) return;

    _controller =
        AssistanceIntakeController(
            repository: AppDependencies.of(context).serviceRequestRepository,
            serviceCode: widget.serviceCode,
          )
          ..addListener(_onChanged)
          ..initialise();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});

    final submission = _controller?.submission;
    if (submission != null && submission.isSuccess && !_celebrated) {
      _celebrated = true;
      // A milestone, and paired with a visible confirmation — never the only
      // signal that something happened.
      unawaited(
        AppHaptics.fire(
          HapticIntent.success,
          suppressed: Motion.reduced(context),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    _errorFocus.dispose();
    super.dispose();
  }

  void _continue() {
    final advanced = _controller?.next() ?? false;
    if (!advanced) _errorFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Apply')),
      body: SafeArea(
        // Belt and braces with the route guard, which is verified-only. A
        // screen that also states its own requirement keeps telling the truth
        // if it is ever opened from somewhere with a weaker one.
        child: CapabilityGate(
          capability: ResidentCapability.applyForAssistance,
          child: switch ((_codeIsValid, controller)) {
            (false, _) => const _CannotApply(
              message:
                  'That link does not point at a Taytay service we can open.',
            ),
            (_, null) => const AppLoadingView(),
            (_, final AssistanceIntakeController active) => _Body(
              controller: active,
              errorFocus: _errorFocus,
              onContinue: _continue,
            ),
          },
        ),
      ),
    );
  }
}

/// Loading, unavailable, or the wizard itself.
class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.errorFocus,
    required this.onContinue,
  });

  final AssistanceIntakeController controller;
  final FocusNode errorFocus;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingForm) {
      return const AppLoadingView(message: 'Opening the application form…');
    }

    final form = controller.form;
    if (form == null) {
      // The honest state while `ServiceDelivery` is unpublished: the app does
      // not know what this office asks for, so it says so and names the place
      // that does, rather than inventing a form.
      return const _CannotApply(
        message:
            'Applying in this app is not switched on yet. Taytay municipal '
            'hall can take your application in person, and the service page '
            'lists what to bring.',
      );
    }

    return _Wizard(
      controller: controller,
      form: form,
      errorFocus: errorFocus,
      onContinue: onContinue,
    );
  }
}

class _Wizard extends StatelessWidget {
  const _Wizard({
    required this.controller,
    required this.form,
    required this.errorFocus,
    required this.onContinue,
  });

  final AssistanceIntakeController controller;
  final AssistanceIntakeForm form;
  final FocusNode errorFocus;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = controller.step;
    final position = controller.progressPosition;
    final total = controller.progressSteps.length;

    if (step == IntakeStep.submitting) {
      return const AppLoadingView(
        message: 'Sending your application to Taytay LGU…',
      );
    }
    if (step == IntakeStep.outcome) {
      return _OutcomeStep(controller: controller);
    }

    return Column(
      children: <Widget>[
        if (position != null)
          _StepProgress(position: position, total: total, step: step),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              FormErrorSummary(
                errors: controller.errors,
                focusNode: errorFocus,
              ),
              if (controller.activeRequest != null) ...<Widget>[
                _ActiveRequestWarning(notice: controller.activeRequest!),
                const SizedBox(height: Spacing.lg),
              ],
              if (controller.isBlockedByUnknownQuestions) ...<Widget>[
                const _UnknownQuestionsWarning(),
                const SizedBox(height: Spacing.lg),
              ],
              Semantics(
                header: true,
                child: Text(step.title, style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: Spacing.lg),
              switch (step) {
                IntakeStep.context => _ContextStep(
                  controller: controller,
                  form: form,
                ),
                IntakeStep.describe => _DescribeStep(
                  controller: controller,
                  form: form,
                ),
                IntakeStep.questions => _QuestionsStep(
                  controller: controller,
                  form: form,
                ),
                IntakeStep.documents => _DocumentsStep(form: form),
                IntakeStep.consent => _ConsentStep(
                  controller: controller,
                  form: form,
                ),
                IntakeStep.review => _ReviewStep(
                  controller: controller,
                  form: form,
                ),
                IntakeStep.submitting ||
                IntakeStep.outcome => const SizedBox.shrink(),
              },
            ],
          ),
        ),
        _StepActions(controller: controller, onContinue: onContinue),
      ],
    );
  }
}

/// "Step 3 of 5", as text and as a bar.
///
/// Both, because a bar alone conveys nothing to a screen reader and a number
/// alone gives no sense of how much is left.
class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.position,
    required this.total,
    required this.step,
  });

  final int position;
  final int total;
  final IntakeStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            label: 'Step $position of $total, ${step.title}',
            excludeSemantics: true,
            child: Text(
              'Step $position of $total',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.sm),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : position / total,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Back and Continue, pinned below the scrolling step.
class _StepActions extends StatelessWidget {
  const _StepActions({required this.controller, required this.onContinue});

  final AssistanceIntakeController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isReview = controller.step == IntakeStep.review;
    final blocked = controller.isBlockedByUnknownQuestions;

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppButton(
            label: isReview ? 'Send my application' : 'Continue',
            // Disabled while an attempt is in flight and while the form
            // contains something this build cannot render. Both are the same
            // guarantee stated twice: the controller refuses as well, so a
            // stale frame cannot submit.
            onPressed: isReview
                ? (controller.canSubmit ? controller.submit : null)
                : (blocked ? null : onContinue),
            loading: controller.busy,
            // `confirm` only where something is actually being sent.
            hapticIntent: isReview
                ? HapticIntent.confirm
                : HapticIntent.selection,
          ),
          if (controller.canGoBack) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            AppButton(
              label: 'Back',
              variant: AppButtonVariant.text,
              onPressed: controller.busy ? null : controller.back,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Steps ──────────────────────────────────────────────────────────────────

/// Who the application is for, and against which service.
///
/// **No personal data is fetched or shown here.** The resident's own record is
/// `/me`-scoped and belongs to the profile feature; repeating a name and address
/// on this screen would copy personal data into a second place for no purpose
/// beyond reassurance. The confirmation is that the application goes against the
/// signed-in account, which is the fact that actually matters.
class _ContextStep extends StatelessWidget {
  const _ContextStep({required this.controller, required this.form});

  final AssistanceIntakeController controller;
  final AssistanceIntakeForm form;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('You are applying for', style: theme.textTheme.labelMedium),
              const SizedBox(height: Spacing.xxs),
              Text(form.serviceName, style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Text(
                'Reference code ${form.serviceCode}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'This application will be filed against the Taytay resident record '
          'linked to the account you are signed in with.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.md),
        const WhyWeAsk(
          purpose:
              'So the office can match your application to your resident '
              'record and your household without asking you for those details '
              'again.',
          whoSeesIt:
              'The Taytay LGU staff who process applications for this service.',
        ),
        const SizedBox(height: Spacing.md),
        CheckboxListTile(
          value: controller.draft.contextConfirmed,
          onChanged: (value) =>
              controller.confirmContext(confirmed: value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'These are my details, and I am applying for myself.',
          ),
          subtitle: const Text(
            'Applying on behalf of someone else is done at the municipal hall.',
          ),
        ),
      ],
    );
  }
}

/// The resident's own account of what they need.
class _DescribeStep extends StatelessWidget {
  const _DescribeStep({required this.controller, required this.form});

  final AssistanceIntakeController controller;
  final AssistanceIntakeForm form;

  @override
  Widget build(BuildContext context) {
    final maximum = form.narrativeMaxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FieldLabel(
          label: form.narrativePrompt ?? 'Tell us what you need help with',
          hint: 'In your own words. Plain language is fine.',
        ),
        TextField(
          maxLines: 6,
          maxLength: maximum,
          textCapitalization: TextCapitalization.sentences,
          // A narrative wraps, so the return key inserts a line rather than
          // dismissing the keyboard mid-sentence.
          textInputAction: TextInputAction.newline,
          onChanged: controller.updateNarrative,
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: controller.draft.narrative,
              selection: TextSelection.collapsed(
                offset: controller.draft.narrative.length,
              ),
            ),
          ),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: _errorFor(context, controller.errors, 'narrative'),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        const WhyWeAsk(
          purpose:
              'It is the first thing a caseworker reads, and it decides which '
              'office picks the application up.',
          whoSeesIt: 'Taytay LGU staff handling social welfare applications.',
        ),
      ],
    );
  }
}

/// The server's questions, rendered by kind.
class _QuestionsStep extends StatelessWidget {
  const _QuestionsStep({required this.controller, required this.form});

  final AssistanceIntakeController controller;
  final AssistanceIntakeForm form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final question in form.questions)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            child: _QuestionField(
              question: question,
              controller: controller,
              error: _errorFor(context, controller.errors, question.key),
            ),
          ),
      ],
    );
  }
}

/// One question. Falls back to an explanation rather than a guess.
class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.question,
    required this.controller,
    required this.error,
  });

  final IntakeQuestion question;
  final AssistanceIntakeController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!question.isRenderable) {
      // Named, not hidden. A resident who is being sent to the municipal hall
      // deserves to know which question this app could not put to them.
      return AppBanner(
        tone: BannerTone.warning,
        title: question.prompt,
        message:
            'This app version cannot show this question. Taytay municipal hall '
            'can take the answer in person.',
      );
    }

    final answer = controller.draft.answerFor(question.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FieldLabel(
          label: question.prompt,
          required: question.isRequired,
          hint: question.helpText,
        ),
        switch (question.kind.known) {
          IntakeAnswerKind.longText => _text(context, answer, lines: 5),
          IntakeAnswerKind.shortText => _text(context, answer, lines: 1),
          IntakeAnswerKind.number => _number(context, answer),
          IntakeAnswerKind.date => _date(context, answer),
          IntakeAnswerKind.yesNo => _yesNo(answer),
          IntakeAnswerKind.singleChoice => _singleChoice(answer),
          IntakeAnswerKind.multipleChoice => _multipleChoice(answer),
          // Unreachable: `isRenderable` already returned early.
          null => const SizedBox.shrink(),
        },
        if (error != null) ...<Widget>[
          const SizedBox(height: Spacing.xs),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _text(BuildContext context, Object? answer, {required int lines}) {
    final text = answer is String ? answer : '';
    return TextField(
      maxLines: lines,
      maxLength: question.maxLength,
      textCapitalization: TextCapitalization.sentences,
      // The office decides whether its question wants a paragraph or a line,
      // and the keyboard follows: a one-line answer gets "next", a multi-line
      // one gets a return key that actually returns.
      textInputAction: lines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      ),
      onChanged: (value) => controller.answer(question.key, value),
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }

  Widget _number(BuildContext context, Object? answer) {
    final text = answer == null ? '' : '$answer';
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      ),
      // Stored as a number when it parses and as the raw text when it does not,
      // so validation can say "that is not a number" instead of the app
      // silently sending a string the server will reject.
      onChanged: (value) => controller.answer(
        question.key,
        value.isEmpty
            ? null
            : (num.tryParse(value.replaceAll(',', '')) ?? value),
      ),
      decoration: const InputDecoration(border: OutlineInputBorder()),
    );
  }

  Widget _date(BuildContext context, Object? answer) {
    final selected = answer is DateTime ? answer : null;
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_outlined, size: IconSizes.sm),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? now,
          // A wide, uninterpreted window. Narrowing it would be the app
          // inventing a rule about which dates this office accepts.
          firstDate: DateTime(now.year - 120),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) controller.answer(question.key, picked);
      },
      label: Text(selected == null ? 'Choose a date' : _formatDate(selected)),
    );
  }

  // Both single-answer inputs use `RadioGroup`, which owns the selected value
  // and the change callback for the whole set. The per-tile `groupValue`/
  // `onChanged` pair it replaces is deprecated, and it was the shape that let a
  // group be built with tiles disagreeing about which value was selected.
  Widget _yesNo(Object? answer) {
    return RadioGroup<bool>(
      groupValue: answer is bool ? answer : null,
      onChanged: (picked) => controller.answer(question.key, picked),
      child: const Column(
        children: <Widget>[
          RadioListTile<bool>(
            value: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Yes'),
          ),
          RadioListTile<bool>(
            value: false,
            contentPadding: EdgeInsets.zero,
            title: Text('No'),
          ),
        ],
      ),
    );
  }

  Widget _singleChoice(Object? answer) {
    return RadioGroup<String>(
      groupValue: answer is String ? answer : null,
      onChanged: (picked) => controller.answer(question.key, picked),
      child: Column(
        children: <Widget>[
          for (final choice in question.choices)
            RadioListTile<String>(
              value: choice.value,
              contentPadding: EdgeInsets.zero,
              title: Text(choice.label),
            ),
        ],
      ),
    );
  }

  Widget _multipleChoice(Object? answer) {
    final selected = answer is List<String> ? answer : const <String>[];
    return Column(
      children: <Widget>[
        for (final choice in question.choices)
          CheckboxListTile(
            value: selected.contains(choice.value),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (checked) {
              final next = List<String>.from(selected);
              if (checked ?? false) {
                next.add(choice.value);
              } else {
                next.remove(choice.value);
              }
              controller.answer(question.key, next.isEmpty ? null : next);
            },
            title: Text(choice.label),
          ),
      ],
    );
  }
}

/// What the office will need to see.
///
/// **This step lists; it does not upload.** Capturing, compressing, sending and
/// retrying a document is TAB 16's flow, and it is owned once there so that the
/// rules — readability after compression, no file contents in analytics, secure
/// references — hold for both a new application and an existing one. Listing the
/// requirements here still does the thing that matters most at this moment: a
/// resident learns what to bring *before* they commit to the trip.
class _DocumentsStep extends StatelessWidget {
  const _DocumentsStep({required this.form});

  final AssistanceIntakeForm form;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Taytay LGU will ask for these. You can send this application now — '
          'the office will tell you where to bring anything still outstanding.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.lg),
        for (final requirement in form.requirements)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.description_outlined,
                        size: IconSizes.sm,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          requirement.label,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (!requirement.isRequired)
                        Text(
                          'Optional',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (requirement.description != null) ...<Widget>[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      requirement.description!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        const UploadGuidance(
          points: <String>[
            'Bring the original and one photocopy of each document.',
            'Make sure names match your Taytay resident record.',
          ],
        ),
      ],
    );
  }
}

/// Acknowledgements the LGU requires, exactly as it declared them.
class _ConsentStep extends StatelessWidget {
  const _ConsentStep({required this.controller, required this.form});

  final AssistanceIntakeController controller;
  final AssistanceIntakeForm form;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final consent in form.consents)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CheckboxListTile(
                  value: controller.draft.hasConsent(consent.key),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) => controller.toggleConsent(
                    consent.key,
                    given: checked ?? false,
                  ),
                  title: Text(
                    consent.isRequired
                        ? consent.label
                        : '${consent.label} (optional)',
                  ),
                  // The full statement, never a summary the app wrote. What a
                  // person agreed to under RA 10173 is the sentence the LGU
                  // authored, not a paraphrase.
                  subtitle: Text(consent.statement),
                ),
                if (_errorFor(
                      context,
                      controller.errors,
                      'consent_${consent.key}',
                    ) !=
                    null)
                  Text(
                    _errorFor(
                      context,
                      controller.errors,
                      'consent_${consent.key}',
                    )!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Everything, before it is sent.
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller, required this.form});

  final AssistanceIntakeController controller;
  final AssistanceIntakeForm form;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = controller.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Check this is right. Once it is sent, changes go through the office.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.lg),

        _ReviewSection(
          title: 'What you need',
          onEdit: () => controller.editStep(IntakeStep.describe),
          children: <Widget>[Text(draft.narrative)],
        ),

        if (form.questions.isNotEmpty)
          _ReviewSection(
            title: 'Your answers',
            onEdit: () => controller.editStep(IntakeStep.questions),
            children: <Widget>[
              for (final question in form.questions)
                if (question.isRenderable)
                  _ReviewLine(
                    label: question.prompt,
                    value: _displayAnswer(draft.answerFor(question.key)),
                  ),
            ],
          ),

        if (form.consents.isNotEmpty)
          _ReviewSection(
            title: 'What you agreed to',
            onEdit: () => controller.editStep(IntakeStep.consent),
            children: <Widget>[
              for (final consent in form.consents)
                _ReviewLine(
                  label: consent.label,
                  value: draft.hasConsent(consent.key)
                      ? 'Agreed'
                      : 'Not agreed',
                ),
            ],
          ),

        const SizedBox(height: Spacing.md),
        const AppBanner(
          tone: BannerTone.info,
          title: 'What happens next',
          message:
              'Taytay LGU decides whether you qualify and what you receive. '
              'This app cannot tell you the outcome in advance, and sending '
              'this does not guarantee approval.',
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleSmall),
                  ),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Semantics(
                    label: 'Change $title',
                    excludeSemantics: true,
                    child: const Text('Change'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// The end of a submission attempt.
class _OutcomeStep extends StatelessWidget {
  const _OutcomeStep({required this.controller});

  final AssistanceIntakeController controller;

  @override
  Widget build(BuildContext context) {
    final submission = controller.submission;
    if (submission == null) return const AppLoadingView();

    final reference = submission.referenceNumber;

    return StatusView(
      title: switch (submission.outcome) {
        IntakeOutcome.submitted => 'Application sent',
        IntakeOutcome.alreadyOpen => 'You have already applied',
        IntakeOutcome.couldNotSend => 'Not sent',
      },
      kind: switch (submission.outcome) {
        IntakeOutcome.submitted => StatusKind.success,
        IntakeOutcome.alreadyOpen => StatusKind.empty,
        IntakeOutcome.couldNotSend => StatusKind.error,
      },
      message: <String?>[
        submission.residentMessage,
        if (reference != null) 'Reference: $reference',
        if (submission.requestId != null)
          'If you contact the office, quote ${submission.requestId}.',
      ].whereType<String>().join('\n\n'),
      primaryAction: switch (submission.outcome) {
        IntakeOutcome.couldNotSend => AppButton(
          label: 'Try again',
          fullWidth: false,
          onPressed: controller.busy ? null : controller.retrySubmission,
        ),
        _ => AppButton(
          label: 'See my requests',
          fullWidth: false,
          onPressed: () => context.goNamed(AppRoute.requests.routeName),
        ),
      },
      secondaryAction: TextButton(
        onPressed: () => context.goNamed(AppRoute.services.routeName),
        child: const Text('Back to services'),
      ),
    );
  }
}

// ─── Warnings ───────────────────────────────────────────────────────────────

/// The server saying an application is already open.
///
/// Shown from the first step rather than at submission, so a resident who has
/// already applied finds out before filling the form in again — and it is a
/// warning, never a block: only the server decides whether a second application
/// is refused.
class _ActiveRequestWarning extends StatelessWidget {
  const _ActiveRequestWarning({required this.notice});

  final ActiveRequestNotice notice;

  @override
  Widget build(BuildContext context) {
    final reference = notice.referenceNumber;

    return AppBanner(
      tone: BannerTone.warning,
      title: 'You already have an application for this service',
      message: reference == null
          ? 'Sending another one will not make it move faster.'
          : 'Reference $reference. Sending another one will not make it move '
                'faster.',
      action: TextButton(
        onPressed: () => context.goNamed(AppRoute.requests.routeName),
        child: const Text('Check its status'),
      ),
    );
  }
}

/// The form contains something this build cannot present.
class _UnknownQuestionsWarning extends StatelessWidget {
  const _UnknownQuestionsWarning();

  @override
  Widget build(BuildContext context) {
    return const AppBanner(
      tone: BannerTone.warning,
      title: 'This application needs the municipal hall',
      message:
          'Taytay LGU has added something to this form that this version of '
          'the app cannot show. Updating the app may help. Until then the '
          'municipal hall can take your application in full.',
    );
  }
}

/// The honest dead end.
class _CannotApply extends StatelessWidget {
  const _CannotApply({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'You cannot apply here yet',
      kind: StatusKind.empty,
      icon: Icons.assignment_outlined,
      message: message,
      primaryAction: AppButton(
        label: 'See all services',
        fullWidth: false,
        onPressed: () => context.goNamed(AppRoute.services.routeName),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

/// The error for [field], in the reader's language.
///
/// Takes a `BuildContext` because this app's own validation messages are
/// localised and the server's are not — `localisedFieldError` is what tells them
/// apart. Before the copy sweep this returned `error.message` directly, so every
/// client-composed sentence on the assistance intake form reached a Filipino
/// reader in English, on the screen they use to ask for help.
String? _errorFor(BuildContext context, List<FieldError> errors, String field) {
  for (final error in errors) {
    if (error.field == field) return localisedFieldError(context, error);
  }
  return null;
}

/// Renders an answer for the review list.
///
/// Deliberately plain: a review row shows what the resident entered, never an
/// interpretation of it.
String _displayAnswer(Object? answer) => switch (answer) {
  null => 'Not answered',
  final bool value => value ? 'Yes' : 'No',
  final DateTime value => _formatDate(value),
  final List<Object?> value =>
    value.isEmpty ? 'Not answered' : value.map((item) => '$item').join(', '),
  final String value => value.trim().isEmpty ? 'Not answered' : value,
  _ => '$answer',
};

/// `dd MMM yyyy`, written out rather than localised, because a numeric date is
/// ambiguous between Philippine and US conventions and this app has no
/// localisation seam yet.
String _formatDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}
