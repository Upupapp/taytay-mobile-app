import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/forms/field_error.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/form_support.dart';
import '../../../shared/widgets/status_view.dart';
import '../domain/event_repository.dart';
import 'event_registration_controller.dart';

/// Registering for one LGU event.
///
/// ---
///
/// **The server owns capacity.** Nothing here decides a place is available. A
/// full event is discovered by asking, and "full" is an outcome the resident
/// reads rather than an error they report — somebody who reached the last place
/// a second after another person did nothing wrong.
///
/// **Verification is the server's call, per event.** A barangay clean-up may
/// take anyone with an account; a cash-aid orientation may not. The form says
/// which, and the app asks rather than assuming.
///
/// **No tickets, no payment, no seat map.** The Master Command rules them out,
/// and there is nothing in this flow that could grow into one.
class EventRegistrationScreen extends StatefulWidget {
  const EventRegistrationScreen({required this.eventId, super.key});

  final String eventId;

  @override
  State<EventRegistrationScreen> createState() =>
      _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  EventRegistrationController? _controller;
  final FocusNode _errorFocus = FocusNode();
  bool _celebrated = false;

  bool get _idIsValid => DeepLink.isValidIdentifier(widget.eventId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || !_idIsValid) return;

    final dependencies = AppDependencies.of(context);
    _controller =
        EventRegistrationController(
            repository: dependencies.eventRepository,
            eventId: widget.eventId,
            accessLevel: dependencies.session.state.accessLevel,
          )
          ..addListener(_onChanged)
          ..initialise();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});

    final attempt = _controller?.attempt;
    if (attempt != null && attempt.isHeld && !_celebrated) {
      _celebrated = true;
      // Only after the server said the place is held.
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
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: switch ((_idIsValid, controller)) {
          (false, _) => _Unavailable(
            message: DeepLinkRejection.invalidIdentifier.residentMessage,
          ),
          (_, null) => const AppLoadingView(),
          (_, final EventRegistrationController active) => _Body(
            controller: active,
            errorFocus: _errorFocus,
            onContinue: _continue,
            eventId: widget.eventId,
          ),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.errorFocus,
    required this.onContinue,
    required this.eventId,
  });

  final EventRegistrationController controller;
  final FocusNode errorFocus;
  final VoidCallback onContinue;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingForm) {
      return const AppLoadingView(message: 'Opening the registration form…');
    }

    final form = controller.form;
    if (form == null) {
      return const _Unavailable(
        message:
            'Registering in this app is not switched on yet. The Taytay office '
            'running this event can tell you how to join.',
      );
    }

    final block = controller.block;
    if (block != null) return _Blocked(block: block, eventId: eventId);

    if (controller.step == RegistrationStep.submitting) {
      return const AppLoadingView(message: 'Registering you…');
    }
    if (controller.step == RegistrationStep.outcome) {
      return _Outcome(controller: controller, eventId: eventId);
    }

    return _Wizard(
      controller: controller,
      form: form,
      errorFocus: errorFocus,
      onContinue: onContinue,
    );
  }
}

/// Why registration cannot proceed — each with its own way forward.
class _Blocked extends StatelessWidget {
  const _Blocked({required this.block, required this.eventId});

  final RegistrationBlock block;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final (
      String title,
      String message,
      String action,
      AppRoute route,
    ) = switch (block) {
      RegistrationBlock.alreadyRegistered => (
        'You are already registered',
        'Taytay LGU has your place for this event. Your reference is on the '
            'event page.',
        'Back to the event',
        AppRoute.eventDetail,
      ),
      RegistrationBlock.needsVerification => (
        'This event needs a verified account',
        'Taytay LGU asks for a confirmed identity before registering for '
            'this one. Verifying takes a few steps and only has to be done '
            'once.',
        'Verify my identity',
        AppRoute.verification,
      ),
      RegistrationBlock.unsupportedForm => (
        'This registration needs the office',
        'Taytay LGU has added something to this form that this version of '
            'the app cannot show. Updating the app may help. Until then the '
            'office running the event can register you in person.',
        'Back to the event',
        AppRoute.eventDetail,
      ),
      RegistrationBlock.notOpen => (
        'Registration is not open',
        'Taytay LGU is not taking registrations for this event right now.',
        'Back to the event',
        AppRoute.eventDetail,
      ),
    };

    return StatusView(
      title: title,
      kind: StatusKind.empty,
      icon: switch (block) {
        RegistrationBlock.alreadyRegistered => Icons.how_to_reg_outlined,
        RegistrationBlock.needsVerification => Icons.verified_user_outlined,
        RegistrationBlock.unsupportedForm => Icons.construction_outlined,
        RegistrationBlock.notOpen => Icons.event_busy_outlined,
      },
      message: message,
      primaryAction: AppButton(
        label: action,
        fullWidth: false,
        onPressed: () => route == AppRoute.eventDetail
            ? context.goNamed(
                route.routeName,
                pathParameters: <String, String>{'eventId': eventId},
              )
            : context.goNamed(route.routeName),
      ),
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

  final EventRegistrationController controller;
  final EventRegistrationForm form;
  final FocusNode errorFocus;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = controller.progressPosition;
    final total = controller.progressSteps.length;
    final isLast = controller.step == controller.progressSteps.last;

    return Column(
      children: <Widget>[
        if (position != null && total > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              0,
            ),
            child: Semantics(
              label: 'Step $position of $total',
              excludeSemantics: true,
              child: Text(
                'Step $position of $total',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: <Widget>[
              FormErrorSummary(
                errors: controller.errors,
                focusNode: errorFocus,
              ),

              Semantics(
                header: true,
                child: Text(
                  controller.step.title,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: Spacing.lg),

              switch (controller.step) {
                RegistrationStep.confirm => _ConfirmStep(form: form),
                RegistrationStep.questions => _QuestionsStep(
                  controller: controller,
                  form: form,
                ),
                RegistrationStep.consent => _ConsentStep(
                  controller: controller,
                  form: form,
                ),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppButton(
                label: isLast ? 'Register' : 'Continue',
                loading: controller.busy,
                hapticIntent: isLast
                    ? HapticIntent.confirm
                    : HapticIntent.selection,
                onPressed: isLast
                    ? (controller.canSubmit ? controller.submit : null)
                    : onContinue,
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
        ),
      ],
    );
  }
}

/// What is being registered for, and who is registering.
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.form});

  final EventRegistrationForm form;

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
              Text(
                'You are registering for',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: Spacing.xxs),
              Text(form.eventTitle, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // No name, no address, no birth date. The office already holds the
        // resident's record and the registration is filed against the account —
        // repeating personal details here would copy them into a second screen
        // for reassurance alone.
        Text(
          'This registration will be filed against the account you are signed '
          'in with.',
          style: theme.textTheme.bodyMedium,
        ),

        if (form.notice != null) ...<Widget>[
          const SizedBox(height: Spacing.lg),
          AppBanner(
            tone: BannerTone.info,
            title: 'From the office',
            message: form.notice!,
          ),
        ],

        const SizedBox(height: Spacing.lg),
        // Said before they commit, not after.
        Text(
          'Taytay LGU decides whether a place is available. You will see the '
          'answer on the next screen.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The office's own questions.
class _QuestionsStep extends StatelessWidget {
  const _QuestionsStep({required this.controller, required this.form});

  final EventRegistrationController controller;
  final EventRegistrationForm form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final field in form.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            child: _Field(
              field: field,
              controller: controller,
              error: _errorFor(controller.errors, field.key),
            ),
          ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.field,
    required this.controller,
    required this.error,
  });

  final ServerField field;
  final EventRegistrationController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answer = controller.answers[field.key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FieldLabel(
          label: field.prompt,
          required: field.isRequired,
          hint: field.helpText,
        ),

        switch (field.kind.known) {
          ServerFieldKind.yesNo => RadioGroup<bool>(
            groupValue: answer is bool ? answer : null,
            onChanged: (value) => controller.answer(field.key, value),
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
          ),
          ServerFieldKind.singleChoice => RadioGroup<String>(
            groupValue: answer is String ? answer : null,
            onChanged: (value) => controller.answer(field.key, value),
            child: Column(
              children: <Widget>[
                for (final choice in field.choices)
                  RadioListTile<String>(
                    value: choice.value,
                    contentPadding: EdgeInsets.zero,
                    title: Text(choice.label),
                  ),
              ],
            ),
          ),
          ServerFieldKind.multipleChoice => Column(
            children: <Widget>[
              for (final choice in field.choices)
                CheckboxListTile(
                  value:
                      answer is List<String> && answer.contains(choice.value),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) {
                    final current = answer is List<String>
                        ? List<String>.from(answer)
                        : <String>[];
                    if (checked ?? false) {
                      current.add(choice.value);
                    } else {
                      current.remove(choice.value);
                    }
                    controller.answer(
                      field.key,
                      current.isEmpty ? null : current,
                    );
                  },
                  title: Text(choice.label),
                ),
            ],
          ),
          ServerFieldKind.number => TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            controller: TextEditingController(
              text: answer == null ? '' : '$answer',
            ),
            onChanged: (value) => controller.answer(
              field.key,
              value.isEmpty ? null : (num.tryParse(value) ?? value),
            ),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          // Everything textual, including a date this build renders as text
          // rather than guessing a picker format the office did not specify.
          _ => TextField(
            maxLines: field.kind.known == ServerFieldKind.longText ? 4 : 1,
            maxLength: field.maxLength,
            // The office decides whether its question wants a paragraph, and
            // the keyboard follows.
            textInputAction: field.kind.known == ServerFieldKind.longText
                ? TextInputAction.newline
                : TextInputAction.next,
            controller: TextEditingController(
              text: answer is String ? answer : '',
            ),
            onChanged: (value) => controller.answer(field.key, value),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
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
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({required this.controller, required this.form});

  final EventRegistrationController controller;
  final EventRegistrationForm form;

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
                  value: controller.consents.contains(consent.key),
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
                  // The office's own sentence, never a paraphrase.
                  subtitle: Text(consent.statement),
                ),
                if (_errorFor(controller.errors, 'consent_${consent.key}') !=
                    null)
                  Text(
                    _errorFor(controller.errors, 'consent_${consent.key}')!,
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

/// What the server said.
class _Outcome extends StatelessWidget {
  const _Outcome({required this.controller, required this.eventId});

  final EventRegistrationController controller;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final attempt = controller.attempt;
    if (attempt == null) return const AppLoadingView();

    final reference = attempt.registration?.reference;
    final position = attempt.registration?.waitlistPosition;

    return StatusView(
      title: switch (attempt.outcome) {
        RegistrationOutcome.registered => 'You are registered',
        RegistrationOutcome.waitlisted => 'You are on the waitlist',
        RegistrationOutcome.full => 'This event is full',
        RegistrationOutcome.closed => 'Registration has closed',
        RegistrationOutcome.refused => 'Taytay LGU could not register you',
        RegistrationOutcome.couldNotSend => 'Not registered',
      },
      kind: switch (attempt.outcome) {
        RegistrationOutcome.registered ||
        RegistrationOutcome.waitlisted => StatusKind.success,
        RegistrationOutcome.couldNotSend => StatusKind.error,
        // Full, closed and refused are states, not faults. Nothing the resident
        // did was wrong, and an error icon would say otherwise.
        _ => StatusKind.empty,
      },
      icon: switch (attempt.outcome) {
        RegistrationOutcome.full ||
        RegistrationOutcome.closed => Icons.event_busy_outlined,
        _ => null,
      },
      message: <String?>[
        attempt.residentMessage,
        if (reference != null) 'Reference: $reference',
        // Only when the office publishes it — a position is a statement about
        // other people as much as about this resident.
        if (position != null) 'You are number $position on the waitlist.',
        if (attempt.registration?.instructions != null)
          attempt.registration!.instructions!,
        if (attempt.requestId != null)
          'If you contact the office, quote ${attempt.requestId}.',
      ].whereType<String>().join('\n\n'),
      primaryAction: AppButton(
        label: 'Back to the event',
        fullWidth: false,
        onPressed: () => context.goNamed(
          AppRoute.eventDetail.routeName,
          pathParameters: <String, String>{'eventId': eventId},
        ),
      ),
      secondaryAction: attempt.outcome == RegistrationOutcome.couldNotSend
          ? TextButton(
              onPressed: controller.busy ? null : controller.retry,
              child: const Text('Try again'),
            )
          : null,
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'You cannot register here yet',
      kind: StatusKind.empty,
      icon: Icons.event_busy_outlined,
      message: message,
      primaryAction: AppButton(
        label: 'See all events',
        fullWidth: false,
        onPressed: () => context.goNamed(AppRoute.events.routeName),
      ),
    );
  }
}

String? _errorFor(List<FieldError> errors, String field) {
  for (final error in errors) {
    if (error.field == field) return error.message;
  }
  return null;
}
