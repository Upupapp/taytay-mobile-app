import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/illustrations/state_illustrations.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/form_support.dart';
import '../domain/correctable_field.dart';
import '../domain/verification_status_detail.dart';
import 'verification_controller.dart';

/// Identity verification: where a resident sees where they stand and what to do.
///
/// ---
///
/// **What this screen deliberately never shows.** No reviewer name, no risk or
/// confidence score, no caseworker note, no audit trail, no matching candidate,
/// no rejection code. The decoder that feeds it reads an allow-list, so those
/// fields have nowhere to arrive; this screen adds no way to display them.
///
/// **No turnaround promises.** Nothing here says "within three working days".
/// The app has no basis for that number, a municipal queue does not honour it,
/// and a missed promise from a government service costs more trust than saying
/// nothing. The copy states what is happening and what the resident can do.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late final VerificationController _controller;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final dependencies = AppDependencies.of(context);
    _controller = VerificationController(
      repository: dependencies.verificationRepository,
      session: dependencies.session,
    )..addListener(_onChanged);
    _controller.refresh();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity verification'),
        actions: <Widget>[
          IconButton(
            onPressed: _controller.loading ? null : _controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Check again',
          ),
        ],
      ),
      body: SafeArea(
        child: _controller.loading && status == null
            ? const AppLoadingView(message: 'Checking your status…')
            : RefreshIndicator(
                onRefresh: _controller.refresh,
                child: ListView(
                  padding: const EdgeInsets.all(Spacing.lg),
                  children: <Widget>[
                    if (_controller.failure != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.lg),
                        child: AppBanner(
                          tone: BannerTone.warning,
                          title: 'Could not check your status',
                          message: _controller.failure!.residentMessage,
                          action: AppButton(
                            label: 'Try again',
                            variant: AppButtonVariant.secondary,
                            fullWidth: false,
                            onPressed: _controller.refresh,
                          ),
                        ),
                      ),
                    if (status != null) ...<Widget>[
                      _StageHeader(status: status),
                      const SizedBox(height: Spacing.xl),
                      if (status.residentGuidance != null) ...<Widget>[
                        AppBanner(
                          tone: status.stage.needsResidentAction
                              ? BannerTone.warning
                              : BannerTone.info,
                          title: 'From Taytay LGU',
                          message: status.residentGuidance!,
                        ),
                        const SizedBox(height: Spacing.xl),
                      ],
                      if (status.hasIssues) ...<Widget>[
                        _CorrectionSection(controller: _controller),
                        const SizedBox(height: Spacing.xl),
                      ],
                      if (status.submittedCategories.isNotEmpty) ...<Widget>[
                        _SubmittedItems(status: status),
                        const SizedBox(height: Spacing.xl),
                      ],
                      _NextSteps(status: status, controller: _controller),
                    ] else if (_controller.failure == null)
                      const AppLoadingView(message: 'Checking your status…'),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Headline: where the resident stands, in one word and one sentence.
class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.status});

  final VerificationStatusDetail status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = status.stage;

    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: switch (stage) {
              ResidentVerificationStage.verified => StateIllustrations.success(
                size: 120,
              ),
              ResidentVerificationStage.unsuccessful =>
                StateIllustrations.error(size: 120),
              _ => StateIllustrations.empty(size: 120),
            },
          ),
          const SizedBox(height: Spacing.lg),
          Text(stage.label, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.sm),
          Text(
            stage.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (status.submittedAt != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              'Sent on ${_formatDate(status.submittedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// The categories of information the LGU holds — never the values.
class _SubmittedItems extends StatelessWidget {
  const _SubmittedItems({required this.status});

  final VerificationStatusDetail status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'What Taytay LGU has from you',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: Spacing.md),
          for (final category in status.submittedCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.check_circle_outline,
                    size: IconSizes.sm,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(category.label, style: theme.textTheme.bodyMedium),
                        Text(
                          category.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Spacing.sm),
          const WhyWeAsk(
            title: 'Why can I not see what I sent?',
            purpose:
                'This page shows the kinds of information Taytay LGU holds for '
                'your check, not the details themselves.',
            whoSeesIt:
                'Showing your date of birth or ID photo again here would put '
                'them on a screen that can be read over your shoulder, without '
                'telling you anything you do not already know.',
          ),
        ],
      ),
    );
  }
}

/// The "needs more information" correction flow.
///
/// Only the flagged categories appear, each with the office's own instruction
/// and a single field. A resident answering a specific request should not have
/// to redo a submission the office has not questioned.
class _CorrectionSection extends StatelessWidget {
  const _CorrectionSection({required this.controller});

  final VerificationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = controller.status!;

    return AppCard(
      emphasis: CardEmphasis.selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              status.issues.length == 1
                  ? 'One thing to fix'
                  : '${status.issues.length} things to fix',
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: Spacing.md),
          for (final issue in status.issues) ...<Widget>[
            FieldLabel(label: issue.category.label, hint: issue.instruction),

            // A CATEGORY THIS ROUTE CANNOT CARRY GETS A SENTENCE, NOT A FIELD
            // (TAB 04, F23). "Proof of identity" and "photo of you" are
            // documents, and `me/profile/corrections` adjudicates named profile
            // fields. Offering a text box here and refusing afterwards is a
            // refusal disguised as a form: the resident types, taps send, and
            // is told the thing they were invited to do was never possible.
            if (!issue.category.isCorrectable)
              Text(
                AppStrings.of(context).correctionNotByMessage,
                style: theme.textTheme.bodyMedium,
              )
            else ...<Widget>[
              // ASKED, NEVER GUESSED. "Your address" is a barangay, a street and
              // a purok; picking one on the resident's behalf files a correction
              // against a field the office never questioned, and the office
              // reads it, finds nothing wrong, and the resident believes they
              // have been heard.
              if (issue.category.needsFieldChoice) ...<Widget>[
                Text(
                  AppStrings.of(context).correctionWhichDetail,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Spacing.xs),
                for (final field in issue.category.fields)
                  RadioListTile<CorrectableField>(
                    value: field,
                    // ignore: deprecated_member_use
                    groupValue: controller.chosenFieldFor(issue.category),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(correctableFieldLabel(context, field)),
                    // ignore: deprecated_member_use
                    onChanged: (value) => value == null
                        ? null
                        : controller.chooseField(issue.category, value),
                  ),
                const SizedBox(height: Spacing.xs),
              ],
              if (controller.chosenFieldFor(issue.category) case final field?)
                TextFormField(
                  key: ValueKey<CorrectableField>(field),
                  initialValue: controller.corrections[field] ?? '',
                  textCapitalization: TextCapitalization.sentences,
                  // One correction per issue, and there may be several, so
                  // "next" walks the resident down the list.
                  textInputAction: TextInputAction.next,
                  onChanged: (value) =>
                      controller.updateCorrection(field, value),
                ),
            ],
            const SizedBox(height: Spacing.lg),
          ],
          AppButton(
            label: 'Send corrections',
            loading: controller.submitting,
            onPressed: controller.correctionsComplete
                ? controller.submitCorrections
                : null,
          ),
          if (!controller.correctionsComplete) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              'Fill in every item above to send.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What happens next, and the safe route when the app cannot help.
///
/// **Every stage reaches a next step here.** Even the two that cannot be
/// resolved in the app — `unsuccessful` and `manualReview` — end with the
/// municipal hall, which is a route that works when nothing else does.
class _NextSteps extends StatelessWidget {
  const _NextSteps({required this.status, required this.controller});

  final VerificationStatusDetail status;
  final VerificationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = status.stage;
    final actionLabel = stage.nextActionLabel;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text('What happens next', style: theme.textTheme.titleSmall),
          ),
          const SizedBox(height: Spacing.sm),
          Text(_nextStepCopy(stage), style: theme.textTheme.bodyMedium),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            AppButton(
              label: actionLabel,
              loading: controller.submitting,
              onPressed: controller.submitting ? null : () => _act(context),
            ),
          ],
          if (stage.suggestsInPerson ||
              status.manualReviewAvailable) ...<Widget>[
            const SizedBox(height: Spacing.lg),
            const Divider(),
            const SizedBox(height: Spacing.md),
            Semantics(
              header: true,
              child: Text(
                'Finish at the municipal hall',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Bring a valid government-issued ID to the Taytay municipal hall '
              'and staff can complete your verification with you. You do not '
              'need anything from this app to do that.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  /// What the button does, per stage.
  ///
  /// ---
  ///
  /// **This used to send every stage to the registration wizard**, which has no
  /// server counterpart at all (F15): a resident who tapped "Start verification"
  /// was taken to a seven-field form that could never submit. The wizard is
  /// still there and still blocked — but verification itself is not, now that
  /// `POST me/kyc` accepts an identifier a client can obtain (F14), so the
  /// stages that lead to a KYC case go to the KYC form instead.
  ///
  /// `needsMoreInformation` keeps the old destination deliberately: the
  /// correction section is already on this screen and is the real path, and
  /// re-opening a case would discard what the office already holds.
  void _act(BuildContext context) {
    switch (status.stage) {
      // No case, or a terminal one. Both start a claim; the server opens a new
      // case only when there is no open one, so this cannot duplicate.
      case ResidentVerificationStage.notStarted:
      case ResidentVerificationStage.unsuccessful:
        context.goNamed(AppRoute.verificationClaim.routeName);

      // A draft the resident owns. The only thing left is to send it, and that
      // is the moment it enters a municipal queue — so it is its own press,
      // never folded into saving the form.
      case ResidentVerificationStage.inProgress:
        controller.sendForReview();

      case ResidentVerificationStage.needsMoreInformation:
        context.goNamed(AppRoute.register.routeName);

      // No button is offered for these.
      case ResidentVerificationStage.pendingReview:
      case ResidentVerificationStage.verified:
      case ResidentVerificationStage.manualReview:
        break;
    }
  }

  /// Copy per stage.
  ///
  /// Written to state facts and actions only. No estimate of how long a review
  /// takes appears anywhere — the app has no basis for one, and a government
  /// service that misses a promised date loses more than it gained by making it.
  static String _nextStepCopy(
    ResidentVerificationStage stage,
  ) => switch (stage) {
    ResidentVerificationStage.notStarted =>
      'Verifying your identity lets you hold your Taytay digital ID and '
          'apply for municipal services.',
    ResidentVerificationStage.inProgress =>
      'Your details are saved but have not been sent. Taytay LGU cannot see '
          'them until you send them for review.',
    ResidentVerificationStage.pendingReview =>
      'Taytay LGU staff will check your details against the municipal '
          'resident register. You will be notified when there is an update, '
          'and you can check this page any time.',
    ResidentVerificationStage.needsMoreInformation =>
      'Fix the items above and send them back. Everything else you sent is '
          'still with Taytay LGU — you do not need to start again.',
    ResidentVerificationStage.verified =>
      'Your digital ID and municipal services are now available in this '
          'app.',
    ResidentVerificationStage.unsuccessful =>
      'You can try again with clearer details, or finish in person at the '
          'municipal hall.',
    ResidentVerificationStage.manualReview =>
      'This one needs Taytay LGU staff to look at it directly.',
  };
}
