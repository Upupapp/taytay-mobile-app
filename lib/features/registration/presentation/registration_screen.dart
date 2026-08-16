import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/illustrations/state_illustrations.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/form_support.dart';
import '../data/planned_registration_repository.dart';
import '../domain/registration_domain.dart';
import '../domain/registration_validation.dart';
import 'registration_controller.dart';

/// The guided citizen registration wizard.
///
/// One step per screen, with progress, a safe back path that keeps everything
/// entered, an error summary, and an expandable explanation beside every
/// sensitive field.
///
/// The steps shown are whatever [RegistrationController.steps] yields, which is
/// derived from server capabilities — this widget never decides that a document
/// or a selfie is needed.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late final RegistrationController _controller;
  final FocusNode _errorSummaryFocus = FocusNode();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _controller = RegistrationController(
      repository: AppDependencies.of(context).registrationRepository,
    );
    _controller.addListener(_onChanged);
    _controller.initialise();
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _errorSummaryFocus.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final advanced = await _controller.next();
    if (!advanced && mounted && _controller.errors.isNotEmpty) {
      // Move assistive focus to the summary. Without this the resident is left
      // on a button that appeared to do nothing.
      _errorSummaryFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _controller.step;
    final position = _controller.progressPosition;
    final total = _controller.progressSteps.length;

    return PopScope(
      // Back inside the wizard steps backwards rather than leaving, so a
      // system-back gesture does not discard everything entered.
      canPop: !_controller.canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _controller.back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(step.title),
          leading: _controller.canGoBack
              ? IconButton(
                  onPressed: _controller.back,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                )
              : null,
          actions: <Widget>[
            if (step != RegistrationStep.submitting)
              TextButton(
                onPressed: () => context.goNamed(AppRoute.home.routeName),
                child: const Text('Close'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              if (position != null)
                _StepProgress(position: position, total: total, step: step),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FormErrorSummary(
                        errors: _controller.errors,
                        focusNode: _errorSummaryFocus,
                      ),
                      if (_controller.failure != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.lg),
                          child: AppBanner(
                            tone: BannerTone.error,
                            message: _residentSafeMessage(
                              _controller.failure!,
                              step,
                            ),
                          ),
                        ),
                      _StepBody(controller: _controller),
                    ],
                  ),
                ),
              ),
              _StepActions(controller: _controller, onNext: _next),
            ],
          ),
        ),
      ),
    );
  }

  /// Resident-facing copy for a failure, chosen so it never enumerates.
  ///
  /// ---
  ///
  /// **The non-enumeration rule.** On the contact step, the answer must be the
  /// same whether or not the number belongs to an existing account. "This number
  /// is already registered" turns the registration form into an oracle: anyone
  /// could test numbers and learn who is a Taytay resident. The committed
  /// contract states this requirement on the `POST /api/v1/auth/otp` row —
  /// *"must not reveal whether the number is registered"* — and the client must
  /// not undo it by rendering a conflict as a distinguishable message.
  ///
  /// The same applies to identity matching: a submission that collides with an
  /// existing resident record is reported as "we need to check this at the
  /// municipal hall", never as "someone with this name and birth date already
  /// exists".
  static String _residentSafeMessage(
    AppFailure failure,
    RegistrationStep step,
  ) {
    if (failure is ConflictFailure) {
      return switch (step) {
        RegistrationStep.contact || RegistrationStep.verifyCode =>
          'If this mobile number can be used, we have sent a code to it. '
              'Check your messages and enter the code.',
        _ =>
          'We could not complete this automatically. Please visit the Taytay '
              'municipal hall with a valid ID so staff can help you finish.',
      };
    }
    if (failure is ValidationFailure) {
      // Field-level server messages are shown against their fields; the banner
      // stays generic so a server message cannot leak a record detail here.
      return 'Please check the highlighted details and try again.';
    }
    return failure.residentMessage;
  }
}

/// "Step 3 of 6" plus a bar.
///
/// The text carries the meaning; the bar is decoration and is hidden from
/// assistive technology, which would otherwise announce a percentage nobody
/// asked for.
class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.position,
    required this.total,
    required this.step,
  });

  final int position;
  final int total;
  final RegistrationStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xl, Spacing.md, Spacing.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            label: 'Step $position of $total. ${step.title}.',
            child: ExcludeSemantics(
              child: Text(
                'Step $position of $total',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: position / total,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            step.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Continue / Back / Submit, pinned below the scrolling content.
class _StepActions extends StatelessWidget {
  const _StepActions({required this.controller, required this.onNext});

  final RegistrationController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final step = controller.step;
    if (step == RegistrationStep.submitting) return const SizedBox.shrink();

    if (step == RegistrationStep.status) {
      final failed =
          controller.result?.outcome != RegistrationOutcome.submitted;
      return Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          children: <Widget>[
            if (failed)
              AppButton(
                label: 'Try again',
                loading: controller.busy,
                onPressed: controller.retrySubmission,
              ),
            if (failed) const SizedBox(height: Spacing.sm),
            AppButton(
              label: 'Back to home',
              variant: failed
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              onPressed: () => context.goNamed(AppRoute.home.routeName),
            ),
          ],
        ),
      );
    }

    final isReview = step == RegistrationStep.review;
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: <Widget>[
          AppButton(
            label: isReview ? 'Submit registration' : 'Continue',
            icon: isReview ? null : Icons.arrow_forward,
            iconTrailing: true,
            loading: controller.busy,
            hapticIntent: isReview
                ? HapticIntent.confirm
                : HapticIntent.selection,
            onPressed: isReview ? controller.submit : onNext,
          ),
          if (controller.canGoBack) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            AppButton(
              label: 'Back',
              variant: AppButtonVariant.text,
              onPressed: controller.back,
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders whichever step is current.
class _StepBody extends StatelessWidget {
  const _StepBody({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) => switch (controller.step) {
    RegistrationStep.contact => _ContactStep(controller: controller),
    RegistrationStep.verifyCode => _VerifyCodeStep(controller: controller),
    RegistrationStep.personalDetails => _PersonalStep(controller: controller),
    RegistrationStep.address => _AddressStep(controller: controller),
    RegistrationStep.consent => _ConsentStep(controller: controller),
    RegistrationStep.identityDocument => _UploadStep(
      controller: controller,
      isFace: false,
    ),
    RegistrationStep.faceCapture => _UploadStep(
      controller: controller,
      isFace: true,
    ),
    RegistrationStep.review => _ReviewStep(controller: controller),
    RegistrationStep.submitting => const _SubmittingStep(),
    RegistrationStep.status => _StatusStep(controller: controller),
  };
}

/// Finds a field's message for inline display.
String? _errorFor(RegistrationController controller, String field) {
  for (final error in controller.errors) {
    if (error.field == field) return error.message;
  }
  return null;
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const FieldLabel(
          label: 'Mobile number',
          hint: 'We send a one-time code to this number.',
        ),
        TextFormField(
          initialValue: controller.draft.mobileNumber,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          // The only field on this step, so the keyboard closes rather than
          // offering a "next" that goes nowhere.
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          decoration: InputDecoration(
            hintText: '09XXXXXXXXX',
            errorText: _errorFor(controller, 'mobile_number'),
            prefixIcon: const Icon(Icons.phone_iphone_outlined),
          ),
          onChanged: (value) => controller.updateDraft(
            (draft) => draft.copyWith(mobileNumber: value),
          ),
        ),
        const SizedBox(height: Spacing.md),
        const WhyWeAsk(
          purpose:
              'Your mobile number is how you sign in, and how Taytay LGU tells '
              'you what is happening with anything you apply for.',
          whoSeesIt:
              'Municipal staff handling your requests. It is never used for '
              'advertising and never shared with anyone outside the LGU.',
        ),
      ],
    );
  }
}

class _VerifyCodeStep extends StatelessWidget {
  const _VerifyCodeStep({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'We sent a code to the number you entered. Enter it below to confirm '
          'the number is yours.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: Spacing.xl),
        const FieldLabel(label: 'One-time code'),
        TextFormField(
          initialValue: controller.code,
          keyboardType: TextInputType.number,
          autofillHints: const <String>[AutofillHints.oneTimeCode],
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            errorText: _errorFor(controller, 'one_time_code'),
            prefixIcon: const Icon(Icons.sms_outlined),
          ),
          onChanged: controller.updateCode,
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'Did not get a code? Go back and check the number, then try again.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PersonalStep extends StatelessWidget {
  const _PersonalStep({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const FieldLabel(
          label: 'First name',
          hint: 'As it appears on your government ID.',
        ),
        TextFormField(
          initialValue: draft.givenName,
          textCapitalization: TextCapitalization.words,
          // The on-screen keyboard offers "next" and moves to the following
          // field. Without this every field shows a "done" key that dismisses
          // the keyboard, and a resident on a seven-field form taps back into
          // it seven times.
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            errorText: _errorFor(controller, 'given_name'),
          ),
          onChanged: (value) =>
              controller.updateDraft((d) => d.copyWith(givenName: value)),
        ),
        const SizedBox(height: Spacing.lg),
        const FieldLabel(label: 'Middle name', required: false),
        TextFormField(
          initialValue: draft.middleName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (value) =>
              controller.updateDraft((d) => d.copyWith(middleName: value)),
        ),
        const SizedBox(height: Spacing.lg),
        const FieldLabel(label: 'Last name'),
        TextFormField(
          initialValue: draft.familyName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            errorText: _errorFor(controller, 'family_name'),
          ),
          onChanged: (value) =>
              controller.updateDraft((d) => d.copyWith(familyName: value)),
        ),
        const SizedBox(height: Spacing.lg),
        const FieldLabel(
          label: 'Suffix',
          required: false,
          hint: 'Jr., Sr., III — leave blank if you have none.',
        ),
        TextFormField(
          initialValue: draft.suffix,
          // Last field of the run: the date of birth below is a picker, so the
          // keyboard closes rather than pointing at nothing.
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Jr.'),
          onChanged: (value) =>
              controller.updateDraft((d) => d.copyWith(suffix: value)),
        ),
        const SizedBox(height: Spacing.lg),
        const FieldLabel(label: 'Date of birth'),
        _BirthDateField(controller: controller),
        const SizedBox(height: Spacing.md),
        const WhyWeAsk(
          purpose:
              'Taytay LGU matches your name and date of birth against the '
              'municipal resident register to confirm you are a resident. '
              'Without both, a match cannot be made.',
          whoSeesIt:
              'Municipal staff who review registrations. This app asks for '
              'nothing about your income, household or circumstances.',
        ),
      ],
    );
  }
}

class _BirthDateField extends StatelessWidget {
  const _BirthDateField({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthDate = controller.draft.birthDate;
    final error = _errorFor(controller, 'birth_date');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  birthDate ?? DateTime(now.year - 25, now.month, now.day),
              firstDate: DateTime(now.year - RegistrationValidation.maximumAge),
              lastDate: now,
              helpText: 'Date of birth',
            );
            if (picked != null) {
              controller.updateDraft((d) => d.copyWith(birthDate: picked));
            }
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            birthDate == null
                ? 'Choose your date of birth'
                : _formatDate(birthDate),
          ),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: Spacing.xs),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

class _AddressStep extends StatelessWidget {
  const _AddressStep({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final draft = controller.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const FieldLabel(label: 'Barangay'),
        DropdownButtonFormField<Barangay>(
          initialValue: draft.barangay,
          decoration: InputDecoration(
            errorText: _errorFor(controller, 'barangay'),
          ),
          items: <DropdownMenuItem<Barangay>>[
            for (final barangay in TaytayBarangays.fallback)
              DropdownMenuItem<Barangay>(
                value: barangay,
                child: Text(barangay.name),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              controller.updateDraft((d) => d.copyWith(barangay: value));
            }
          },
        ),
        const SizedBox(height: Spacing.lg),
        const FieldLabel(
          label: 'House number and street',
          hint: 'For example: 12 Rizal Street, Purok 3.',
        ),
        TextFormField(
          initialValue: draft.streetAddress,
          textCapitalization: TextCapitalization.words,
          maxLines: 2,
          // Multi-line by design — an address wraps — so the return key inserts
          // a line rather than leaving the field.
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            errorText: _errorFor(controller, 'street_address'),
          ),
          onChanged: (value) =>
              controller.updateDraft((d) => d.copyWith(streetAddress: value)),
        ),
        const SizedBox(height: Spacing.md),
        const WhyWeAsk(
          purpose:
              'Your barangay decides which Taytay office handles your requests, '
              'and confirms you live in the municipality.',
          whoSeesIt:
              'Municipal staff and your barangay office. Your full address is '
              'never shown to other residents.',
        ),
      ],
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = controller.draft;
    final needsBiometric = controller.capabilities.requiresFaceCapture;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Before Taytay LGU processes your information, please read and accept '
          'the following. Each is a separate choice.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: Spacing.lg),
        for (final kind in ConsentKind.values)
          // The biometric consent is only meaningful when the server actually
          // asks for a face capture. Presenting it otherwise would collect a
          // consent for processing that will not happen.
          if (kind != ConsentKind.biometricProcessing || needsBiometric)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CheckboxListTile(
                      value: draft.hasConsent(kind),
                      onChanged: (value) =>
                          controller.toggleConsent(kind, given: value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        kind.required ? kind.label : '${kind.label} (optional)',
                        style: theme.textTheme.titleSmall,
                      ),
                      subtitle: Text(kind.explanation),
                      isError:
                          _errorFor(controller, 'consent_${kind.name}') != null,
                    ),
                    if (_errorFor(controller, 'consent_${kind.name}') != null)
                      Text(
                        _errorFor(controller, 'consent_${kind.name}')!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        const WhyWeAsk(
          title: 'How long is my information kept?',
          purpose:
              'Registration records are kept for as long as the Data Privacy '
              'Act and municipal records rules require, then disposed of.',
          whoSeesIt:
              'You can ask Taytay LGU what it holds about you, and ask for '
              'corrections, at the municipal hall.',
          ifYouDecline:
              'You can keep using this app to browse municipal services '
              'without registering.',
        ),
      ],
    );
  }
}

/// The identity-document and face-capture steps.
///
/// **Reached only when the server asked for them.** Both are `planned` in the
/// committed contract and there is no agreed upload mechanism (backend gap
/// **G-18**), so the picker itself is not wired: the step explains what will be
/// needed and says plainly that it is not available yet, rather than opening a
/// camera and holding an image the app cannot send.
class _UploadStep extends StatelessWidget {
  const _UploadStep({required this.controller, required this.isFace});

  final RegistrationController controller;
  final bool isFace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UploadGuidance(
          points: isFace
              ? const <String>[
                  'Face the camera in good light',
                  'Remove hats and sunglasses',
                  'Only you in the frame',
                ]
              : const <String>[
                  'All four corners of the ID visible',
                  'Text readable, no glare',
                  'The ID is valid and not expired',
                ],
        ),
        const SizedBox(height: Spacing.lg),
        AppBanner(
          tone: BannerTone.info,
          title: 'Not available yet',
          message: isFace
              ? 'Taytay LGU has not enabled photo checks in this app yet. '
                    'Nothing is captured or sent.'
              : 'Taytay LGU has not enabled ID upload in this app yet. '
                    'Nothing is captured or sent.',
        ),
        const SizedBox(height: Spacing.lg),
        WhyWeAsk(
          purpose: isFace
              ? 'A photo lets Taytay LGU confirm the ID you uploaded belongs to '
                    'you. Your photo is sensitive personal information under the '
                    'Data Privacy Act and is processed only for this check.'
              : 'A government ID lets Taytay LGU confirm your identity before '
                    'issuing a municipal credential.',
          whoSeesIt:
              'Municipal staff reviewing your registration. Images are stored '
              'privately and are never published or shown to other residents.',
          ifYouDecline: isFace
              ? 'You can complete verification in person at the municipal hall '
                    'instead.'
              : 'You can bring your ID to the municipal hall instead.',
        ),
        const SizedBox(height: Spacing.md),
        Text(
          'You can continue without this while it is unavailable.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = controller.draft;
    final middle = draft.middleName.trim();
    final suffix = draft.suffix.trim();
    final fullName = <String>[
      draft.givenName.trim(),
      if (middle.isNotEmpty) middle,
      draft.familyName.trim(),
      if (suffix.isNotEmpty) suffix,
    ].join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Check that this matches your government ID. You can change anything '
          'before you submit.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: Spacing.lg),
        _ReviewRow(
          label: 'Mobile number',
          value: draft.mobileNumber,
          onEdit: () => controller.editStep(RegistrationStep.contact),
        ),
        _ReviewRow(
          label: 'Name',
          value: fullName,
          onEdit: () => controller.editStep(RegistrationStep.personalDetails),
        ),
        _ReviewRow(
          label: 'Date of birth',
          value: draft.birthDate == null ? '' : _formatDate(draft.birthDate!),
          onEdit: () => controller.editStep(RegistrationStep.personalDetails),
        ),
        _ReviewRow(
          label: 'Barangay',
          value: draft.barangay?.name ?? '',
          onEdit: () => controller.editStep(RegistrationStep.address),
        ),
        _ReviewRow(
          label: 'Address',
          value: draft.streetAddress,
          onEdit: () => controller.editStep(RegistrationStep.address),
        ),
        _ReviewRow(
          label: 'Accepted',
          value: draft.consents.map((c) => c.label).join(', '),
          onEdit: () => controller.editStep(RegistrationStep.consent),
        ),
        const SizedBox(height: Spacing.lg),
        Text(
          'Submitting sends this to Taytay LGU for review. You will be told '
          'what happens next.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: Semantics(
              label: 'Change $label',
              child: const ExcludeSemantics(child: Text('Change')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittingStep extends StatelessWidget {
  const _SubmittingStep();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        const SizedBox(height: Spacing.xxl),
        Semantics(
          liveRegion: true,
          label: 'Sending your registration to Taytay LGU',
          child: const ExcludeSemantics(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: Spacing.xl),
        Text(
          'Sending your registration…',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Do not close the app.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = controller.result;
    final succeeded = result?.outcome == RegistrationOutcome.submitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: succeeded
              ? StateIllustrations.success(size: 120)
              : StateIllustrations.error(size: 120),
        ),
        const SizedBox(height: Spacing.xl),
        Semantics(
          liveRegion: true,
          child: Text(
            succeeded
                ? 'Registration sent for review'
                : 'Registration not sent',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          result?.residentMessage ??
              'We could not send your registration. Nothing was submitted.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        if (result?.referenceId != null) ...<Widget>[
          const SizedBox(height: Spacing.md),
          Text(
            'Reference: ${result!.referenceId}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: Spacing.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('What happens next', style: theme.textTheme.titleSmall),
              const SizedBox(height: Spacing.sm),
              Text(
                succeeded
                    ? 'Taytay LGU staff will check your details against the '
                          'municipal resident register. You will be notified '
                          'when your account is verified, and you can check '
                          'progress under Identity verification.'
                    : 'Nothing was submitted, so you can try again without '
                          'registering twice. If it keeps failing, you can '
                          'register in person at the Taytay municipal hall with '
                          'a valid ID.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
