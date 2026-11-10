import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/forms/field_error.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/consent_check_card.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/form_support.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_states.dart';
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
///
/// Drawn as the form / step pattern (`RegDetails.dc.html`): the wave header
/// with the step and its bar, the white page, filled fields, the actions in
/// the footer. A held place is the success pattern (`RegDone.dc.html`).
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
      backgroundColor: BrandColors.white,
      body: switch ((_idIsValid, controller)) {
        (false, _) => _Unavailable(
          message: DeepLinkRejection.invalidIdentifier.residentMessage,
        ),
        (_, null) => const _Waiting(label: 'Opening the registration form…'),
        (_, final EventRegistrationController active) => _Body(
          controller: active,
          errorFocus: _errorFocus,
          onContinue: _continue,
          eventId: widget.eventId,
        ),
      },
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
      return const _Waiting(label: 'Opening the registration form…');
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
      return const _Waiting(label: 'Registering you…');
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

/// A page of the flow that is not a step: the wave header titled Register,
/// and the state on the white page below it.
class _StatePage extends StatelessWidget {
  const _StatePage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AuthFormPage(title: 'Register', child: child);
  }
}

/// Busy, with the loading skeleton and the sentence a screen reader hears.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _StatePage(
      child: LoadingSkeleton(
        layout: SkeletonLayout.detail,
        count: 1,
        semanticLabel: label,
      ),
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

    return _StatePage(
      child: EmptyState(
        title: title,
        message: message,
        actionLabel: action,
        primaryAction: true,
        onAction: () => route == AppRoute.eventDetail
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
    final position = controller.progressPosition;
    final total = controller.progressSteps.length;
    final isLast = controller.step == controller.progressSteps.last;
    final bool stepped = position != null && total > 1;

    return AuthFormPage(
      title: controller.step.title,
      subtitle: 'Event registration',
      stepLabel: stepped ? 'Step $position of $total' : null,
      progress: stepped ? position / total : null,
      progressSemanticLabel: stepped ? 'Step $position of $total' : null,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FormErrorSummary(errors: controller.errors, focusNode: errorFocus),
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
    );
  }
}

/// What is being registered for, and who is registering.
class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.form});

  final EventRegistrationForm form;

  @override
  Widget build(BuildContext context) {
    final String? notice = form.notice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SoftCard(
          filled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'You are registering for',
                style: AppTypography.small.copyWith(
                  fontWeight: AppTypography.medium,
                  color: BrandColors.muted,
                ),
              ),
              const SizedBox(height: Spacing.xxs),
              Text(
                form.eventTitle,
                style: AppTypography.sectionTitle.copyWith(
                  color: BrandColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.formGap),

        // No name, no address, no birth date. The office already holds the
        // resident's record and the registration is filed against the account —
        // repeating personal details here would copy them into a second screen
        // for reassurance alone.
        Text(
          'This registration will be filed against the account you are signed '
          'in with.',
          style: _body,
        ),

        if (notice != null) ...<Widget>[
          const SizedBox(height: Spacing.formGap),
          // The heading is its own line so the office's sentence stays
          // exactly as it sent it.
          Text(
            'From the office',
            style: AppTypography.small.copyWith(
              fontWeight: AppTypography.medium,
              color: BrandColors.muted,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          SoftNote(message: notice),
        ],

        const SizedBox(height: Spacing.formGap),
        // Said before they commit, not after.
        Text(
          'Taytay LGU decides whether a place is available. You will see the '
          'answer on the next screen.',
          style: _muted,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final field in form.fields)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.formGap),
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
    final answer = controller.answers[field.key];
    final String? error = this.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          // The theme's filled field (RegDetails `.field`).
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
          ),
        },

        if (error != null) ...<Widget>[
          const SizedBox(height: Spacing.xs),
          Text(
            error,
            style: AppTypography.fieldHelp.copyWith(color: BrandColors.danger),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final consent in form.consents)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.formGap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ConsentCheckCard(
                  value: controller.consents.contains(consent.key),
                  onChanged: (checked) =>
                      controller.toggleConsent(consent.key, given: checked),
                  label: consent.isRequired
                      ? consent.label
                      : '${consent.label} (optional)',
                  // The office's own sentence, never a paraphrase.
                  description: consent.statement,
                ),
                if (_errorFor(controller.errors, 'consent_${consent.key}')
                    case final String message) ...<Widget>[
                  const SizedBox(height: Spacing.xs),
                  Text(
                    message,
                    style: AppTypography.fieldHelp.copyWith(
                      color: BrandColors.danger,
                    ),
                  ),
                ],
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
    if (attempt == null) return const _Waiting(label: 'Registering you…');

    final reference = attempt.registration?.reference;
    final position = attempt.registration?.waitlistPosition;
    final String? instructions = attempt.registration?.instructions;
    final String? requestId = attempt.requestId;

    final String title = switch (attempt.outcome) {
      RegistrationOutcome.registered => 'You are registered',
      RegistrationOutcome.waitlisted => 'You are on the waitlist',
      RegistrationOutcome.full => 'This event is full',
      RegistrationOutcome.closed => 'Registration has closed',
      RegistrationOutcome.refused => 'Taytay LGU could not register you',
      // A send whose answer was lost may have registered the resident, so
      // its heading never says they are not registered (D-188, D-191).
      RegistrationOutcome.couldNotSend =>
        controller.isUnconfirmed
            ? 'Registration not confirmed'
            : 'Not registered',
    };
    final String message = <String?>[
      attempt.residentMessage,
      if (reference != null) 'Reference: $reference',
      // Only when the office publishes it — a position is a statement about
      // other people as much as about this resident.
      if (position != null) 'You are number $position on the waitlist.',
      instructions,
      if (requestId != null) 'If you contact the office, quote $requestId.',
    ].whereType<String>().join('\n\n');

    void backToEvent() => context.goNamed(
      AppRoute.eventDetail.routeName,
      pathParameters: <String, String>{'eventId': eventId},
    );

    return switch (attempt.outcome) {
      // A held place is the success pattern (RegDone).
      RegistrationOutcome.registered ||
      RegistrationOutcome.waitlisted => SuccessScreen(
        mark: SuccessMarkStyle.medal,
        title: title,
        message: message,
        primaryLabel: 'Back to the event',
        onPrimary: backToEvent,
        showBack: true,
      ),
      RegistrationOutcome.couldNotSend => _StatePage(
        child: ErrorState(
          title: title,
          message: message,
          onRetry: controller.busy ? null : controller.retry,
          details: <Widget>[
            TextButton(
              onPressed: backToEvent,
              child: const Text('Back to the event'),
            ),
          ],
        ),
      ),
      // Full, closed and refused are states, not faults. Nothing the resident
      // did was wrong, and an error mark would say otherwise.
      _ => _StatePage(
        child: EmptyState(
          title: title,
          message: message,
          actionLabel: 'Back to the event',
          primaryAction: true,
          onAction: backToEvent,
        ),
      ),
    };
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _StatePage(
      child: EmptyState(
        title: 'You cannot register here yet',
        message: message,
        actionLabel: 'See all events',
        primaryAction: true,
        onAction: () => context.goNamed(AppRoute.events.routeName),
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

final TextStyle _body = AppTypography.bodyStyle.copyWith(
  color: BrandColors.text,
);

final TextStyle _muted = AppTypography.listDetail.copyWith(
  color: BrandColors.muted,
);
