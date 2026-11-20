import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/intent/resident_intent.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/session/access_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../../issuance/domain/issuance_terms.dart';
import '../../profile/domain/resident_profile_detail.dart';
import '../../tulong/domain/social_service.dart';
import '../domain/assistance_application.dart';
import 'apply_controller.dart';
import 'apply_failure_copy.dart';
import 'document_slot.dart';

/// Applying for Tulong from a page whose `can_apply` is true (D-226,
/// backend `6794f8d`, ADR 0004 decision 2).
///
/// One route, four steps — what this is and who can apply, the application,
/// the documents, the review — then the send and the control number. Like
/// the document-request form, the screen changes state and never navigates to
/// its own successor; the router only opens it and closes it.
class ApplyForTulongScreen extends StatefulWidget {
  const ApplyForTulongScreen({required this.serviceSlug, super.key});

  final String serviceSlug;

  @override
  State<ApplyForTulongScreen> createState() => _ApplyForTulongScreenState();
}

class _ApplyForTulongScreenState extends State<ApplyForTulongScreen> {
  bool _started = false;
  bool _notOffered = false;
  AppFailure? _loadFailure;
  ApplyController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  /// Reads the page again for the wizard: its requirements come on the
  /// single read only, and whether it still takes applications is the
  /// server's to say now, not what a list said earlier.
  Future<void> _load() async {
    setState(() {
      _loadFailure = null;
      _notOffered = false;
    });
    final AppDependencies dependencies = AppDependencies.of(context);
    // The one access decision, read the way every gate reads it.
    final bool verified =
        AccessPolicy.evaluate(
              session: dependencies.session.state,
              requirement: ResidentIntentKind.applyForService.requirement,
            )
            is AccessAllowed;
    // Whether the MSWDO has linked the account is asked beside the page, so
    // she is told before typing anything she could not send. A failed read
    // is "not said", and the send's `409` says it instead.
    final Future<Result<ResidentProfileDetail>>? me = verified
        ? dependencies.residentProfileRepository.loadOwnDetail()
        : null;
    final Result<SocialService> result = await dependencies
        .socialServiceRepository
        .loadService(widget.serviceSlug);
    final bool? linked = me == null
        ? null
        : switch (await me) {
            Ok(:final ResidentProfileDetail value) =>
              value.linkedToOfficeRecord,
            Err() => null,
          };
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value) when value.takesApplications:
          _controller = ApplyController(
            repository: dependencies.ownAssistanceRepository,
            picker: dependencies.documentPicker,
            service: value,
            verified: verified,
            linkedToOfficeRecord: linked,
          )..addListener(_changed);
        case Ok():
          _notOffered = true;
        case Err(failure: NotFoundFailure()):
          _notOffered = true;
        case Err(:final failure):
          _loadFailure = failure;
      }
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(AppRoute.programs.routeName);
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ApplyController? controller = _controller;
    if (controller != null) {
      return ApplyForTulongView(controller: controller, onLeave: _leave);
    }
    final AppStrings s = AppStrings.of(context);
    final AppFailure? failure = _loadFailure;
    return AuthFormPage(
      title: s.applyTitle,
      onBack: _leave,
      child: _notOffered
          ? EmptyState(
              key: const Key('apply-not-offered'),
              title: s.applyNotOfferedTitle,
              message: s.applyNotOfferedMessage,
              actionLabel: s.applyBackToProgramme,
              onAction: _leave,
              boxed: true,
            )
          : failure != null
          ? FailureView(
              failure: failure,
              environment: AppDependencies.of(context).config.environment,
              onRetry: _load,
              boxed: true,
            )
          : LoadingSkeleton(
              layout: SkeletonLayout.detail,
              count: 1,
              semanticLabel: s.applyLoading,
            ),
    );
  }
}

/// The wizard itself, driven by its controller. Public so tests and the
/// design frames can draw each stage.
class ApplyForTulongView extends StatefulWidget {
  const ApplyForTulongView({
    required this.controller,
    required this.onLeave,
    super.key,
  });

  final ApplyController controller;

  /// Leaves the wizard for the page it was opened from.
  final VoidCallback onLeave;

  @override
  State<ApplyForTulongView> createState() => _ApplyForTulongViewState();
}

class _ApplyForTulongViewState extends State<ApplyForTulongView> {
  late final TextEditingController _purpose = TextEditingController(
    text: widget.controller.purpose,
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.controller.amountText,
  );

  ApplyController get _c => widget.controller;

  @override
  void dispose() {
    _purpose.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _add(ApplicationRequirement requirement) async {
    final DocumentSource? source = await chooseDocumentSource(
      context,
      label: requirement.name,
      supports: _c.supports,
    );
    if (source == null) return;
    await _c.choose(requirement.code, source);
  }

  /// The back arrow: a step back inside the wizard, or out of it.
  void _back() {
    if (_c.stage == ApplyStage.sending) return;
    if (!_c.back()) widget.onLeave();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (BuildContext context, Widget? _) {
        final ApplyStage stage = _c.stage;
        return PopScope(
          canPop:
              stage == ApplyStage.about ||
              stage == ApplyStage.done ||
              stage == ApplyStage.notVerified ||
              stage == ApplyStage.unlinked,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop && stage != ApplyStage.sending) _c.back();
          },
          child: switch (stage) {
            ApplyStage.about => _about(context),
            ApplyStage.details => _details(context),
            ApplyStage.documents => _documents(context),
            ApplyStage.review || ApplyStage.sending => _review(context),
            ApplyStage.done => _done(context),
            ApplyStage.notVerified => _notVerified(context),
            ApplyStage.unlinked => _unlinked(context),
            ApplyStage.notLinked => _notLinked(context),
          },
        );
      },
    );
  }

  /// The page frame every step shares: the title, the programme, the step.
  Widget _page(
    BuildContext context, {
    required Widget child,
    Widget? footer,
    Key? key,
  }) {
    final AppStrings s = AppStrings.of(context);
    final int? step = _c.stepNumber;
    final String? stepLabel = step == null
        ? null
        : s.applyStepOf(step, ApplyController.stepCount);
    return AuthFormPage(
      pageKey: key,
      title: s.applyTitle,
      subtitle: _c.service.name,
      stepLabel: stepLabel,
      progress: step == null ? null : step / ApplyController.stepCount,
      progressSemanticLabel: stepLabel,
      onBack: _back,
      backEnabled: _c.stage != ApplyStage.sending,
      footer: footer,
      child: child,
    );
  }

  String _need(AppStrings s, ApplicationRequirement requirement) =>
      switch (requirement.obligation) {
        ApplicationObligation.required => s.applyObligationRequired,
        ApplicationObligation.optional => s.applyObligationOptional,
        ApplicationObligation.conditional => s.applyObligationConditional,
      };

  /// The office's condition for a conditional document, or that the office
  /// will say. Null for the others.
  String? _condition(AppStrings s, ApplicationRequirement requirement) =>
      requirement.obligation == ApplicationObligation.conditional
      ? requirement.condition ?? s.applyConditionUnstated
      : null;

  // Step 1 ------------------------------------------------------------------

  Widget _about(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final List<ApplicationRequirement> requirements = _c.requirements;
    return _page(
      context,
      key: const Key('apply-about'),
      footer: PrimaryButton(
        key: const Key('apply-start'),
        label: s.applyStart,
        onPressed: _c.start,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ProgrammeCard(service: _c.service),
          const SizedBox(height: Spacing.formGap),
          _Heading(s.applyAboutHeading),
          _Body(s.applyAboutBody),
          const SizedBox(height: Spacing.formGap),
          _Heading(s.applyWhoHeading),
          _Body(s.applyWhoBody),
          const SizedBox(height: Spacing.formGap),
          _Heading(s.applyNeedsHeading),
          if (requirements.isEmpty)
            _Body(s.applyNeedsNone)
          else
            for (final ApplicationRequirement requirement in requirements)
              _Line(
                key: Key('apply-about-${requirement.code}'),
                icon: TaytayIcons.fileText,
                text: '${requirement.name} · ${_need(s, requirement)}',
                detail: _condition(s, requirement),
              ),
          const SizedBox(height: Spacing.formGap),
          SoftNote(live: false, message: s.applyInPersonAlso),
        ],
      ),
    );
  }

  // Step 2 ------------------------------------------------------------------

  Widget _details(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final bool show = _c.showDetailProblems;
    final String? purposeError = _c.serverFlagged('purpose')
        ? s.applyServerFlagged
        : !show
        ? null
        : switch (_c.purposeProblem) {
            ApplicationPurposeProblem.empty => s.applyPurposeEmpty,
            ApplicationPurposeProblem.tooShort => s.applyPurposeTooShort(
              applicationPurposeMin,
            ),
            ApplicationPurposeProblem.tooLong => s.applyPurposeTooLong(
              applicationPurposeMax,
            ),
            null => null,
          };
    final String? amountError = _c.serverFlagged('requested_amount_centavos')
        ? s.applyServerFlagged
        : !show
        ? null
        : switch (_c.amountProblem) {
            ApplicationAmountProblem.unreadable => s.applyAmountUnreadable,
            ApplicationAmountProblem.zero => s.applyAmountZero,
            ApplicationAmountProblem.tooLarge => s.applyAmountTooLarge,
            null => null,
          };
    return _page(
      context,
      key: const Key('apply-details'),
      footer: PrimaryButton(
        key: const Key('apply-details-next'),
        label: s.applyNext,
        onPressed: _c.toDocuments,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_c.failure case final AppFailure failure)
            SendFailureNotice(failure: failure),
          _Heading(s.applyDetailsHeading),
          const SizedBox(height: Spacing.sm),
          AuthFieldLabel(s.applyPurposeLabel, requiredField: true),
          const SizedBox(height: Spacing.sm),
          TextField(
            key: const Key('apply-purpose'),
            controller: _purpose,
            onChanged: _c.setPurpose,
            minLines: 3,
            maxLines: 8,
            maxLength: applicationPurposeMax,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.fieldValue.copyWith(color: BrandColors.ink),
            decoration: InputDecoration(
              hintText: s.applyPurposeHint,
              helperText: s.applyPurposeHelp,
              errorText: purposeError,
              errorMaxLines: 3,
              helperMaxLines: 2,
              hintMaxLines: 2,
            ),
          ),
          const SizedBox(height: Spacing.formGap),
          AuthFieldLabel(s.applyAmountLabel),
          const SizedBox(height: Spacing.sm),
          TextField(
            key: const Key('apply-amount'),
            controller: _amount,
            onChanged: _c.setAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.fieldValue.copyWith(color: BrandColors.ink),
            decoration: InputDecoration(
              prefixText: '₱ ',
              hintText: s.applyAmountHint,
              helperText: s.applyAmountHelp,
              errorText: amountError,
              errorMaxLines: 3,
              helperMaxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // Step 3 ------------------------------------------------------------------

  Widget _documents(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final List<ApplicationRequirement> requirements = _c.requirements;
    final Set<String> missing = _c.showDocumentProblems
        ? <String>{for (final ApplicationRequirement r in _c.missing) r.code}
        : const <String>{};
    return _page(
      context,
      key: const Key('apply-documents'),
      footer: PrimaryButton(
        key: const Key('apply-documents-next'),
        label: s.applyNext,
        onPressed: _c.toReview,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_c.failure case final AppFailure failure)
            SendFailureNotice(failure: failure),
          _Heading(s.applyDocumentsHeading),
          const SizedBox(height: Spacing.xs),
          if (requirements.isEmpty)
            _Body(s.applyNeedsNone)
          else ...<Widget>[
            Text(
              s.applyDocumentsIntro(_c.uploadPolicy.maxMegabytes),
              key: const Key('apply-documents-limit'),
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
                height: 1.5,
              ),
            ),
            for (final ApplicationRequirement requirement in requirements)
              DocumentSlot(
                code: requirement.code,
                name: requirement.name,
                need: _need(s, requirement),
                note: _condition(s, requirement),
                chosen: _c.files[requirement.code],
                refused: _c.refusedFor(requirement.code),
                policy: _c.uploadPolicy,
                missing: missing.contains(requirement.code),
                flagged: _c.serverFlagged(requirement.code),
                onAdd: () => _add(requirement),
                onRemove: () => _c.remove(requirement.code),
              ),
          ],
          if (missing.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.formGap),
            SoftNote(
              key: const Key('apply-required-missing'),
              tone: NoteTone.error,
              message: s.applyRequiredMissing,
            ),
          ],
        ],
      ),
    );
  }

  // Step 4 ------------------------------------------------------------------

  Widget _review(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final bool sending = _c.stage == ApplyStage.sending;
    final int? amount = _c.amountCentavos;
    return _page(
      context,
      key: const Key('apply-review'),
      footer: PrimaryButton(
        key: const Key('apply-send'),
        label: sending ? s.applySending : s.applySend,
        onPressed: sending ? null : _c.submit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_c.failure case final AppFailure failure when !sending)
            SendFailureNotice(failure: failure),
          _Heading(s.applyReviewHeading),
          const SizedBox(height: Spacing.sm),
          _ReviewCard(
            title: s.applyDetailsHeading,
            editKey: const Key('apply-edit-details'),
            onEdit: sending ? null : () => _c.edit(ApplyStage.details),
            children: <Widget>[
              _Pair(label: s.applyReviewProgramme, value: _c.service.name),
              _Pair(label: s.applyReviewPurpose, value: _c.purpose.trim()),
              _Pair(
                label: s.applyReviewAmount,
                value: amount == null
                    ? s.applyReviewNoAmount
                    : formatPesos(amount),
              ),
            ],
          ),
          const SizedBox(height: Spacing.section),
          _ReviewCard(
            title: s.applyReviewDocuments,
            editKey: const Key('apply-edit-documents'),
            onEdit: sending ? null : () => _c.edit(ApplyStage.documents),
            children: <Widget>[
              if (_c.requirements.isEmpty) _Body(s.applyNeedsNone),
              for (final ApplicationRequirement requirement in _c.requirements)
                _Line(
                  icon: _c.files.containsKey(requirement.code)
                      ? TaytayIcons.circleCheck
                      : TaytayIcons.circleSlash,
                  text: switch (_c.files[requirement.code]) {
                    final CapturedDocument file => s.applyReviewFile(
                      requirement.name,
                      fileKind(s, file),
                      file.readableSize,
                    ),
                    null => s.applyReviewNotSent(requirement.name),
                  },
                ),
            ],
          ),
          const SizedBox(height: Spacing.section),
          SoftNote(live: false, message: s.applyReviewNote),
        ],
      ),
    );
  }

  // After the send ----------------------------------------------------------

  /// The control number, what happens next, and the two ways on. Said the same
  /// to every resident: nothing here reveals that a request will not be
  /// listed to her (ADR 0004, a protected person).
  Widget _done(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String reference = _c.filed?.referenceNumber ?? '';
    return SuccessScreen(
      key: const Key('apply-done'),
      mark: SuccessMarkStyle.medal,
      title: s.applyDoneTitle,
      message: s.applyDoneMessage,
      details: <SuccessDetail>[
        SuccessDetail(
          label: s.applyDoneControlNumber,
          value: reference.isEmpty ? '—' : reference,
        ),
        SuccessDetail(label: s.applyReviewProgramme, value: _c.service.name),
      ],
      note: s.applyDoneNote,
      primaryLabel: s.applyOpenMyRequests,
      onPrimary: () => context.goNamed(AppRoute.myRequests.routeName),
      secondaryLabel: s.applyBackToTulong,
      onSecondary: () => context.goNamed(AppRoute.programs.routeName),
    );
  }

  Widget _notVerified(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return _page(
      context,
      key: const Key('apply-not-verified'),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            key: const Key('apply-go-verify'),
            label: s.applyGoToVerification,
            onPressed: () => context.goNamed(AppRoute.verification.routeName),
          ),
          const SizedBox(height: Spacing.sm),
          SecondaryButton(
            key: const Key('apply-back-to-programme'),
            label: s.applyBackToProgramme,
            onPressed: widget.onLeave,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ProgrammeCard(service: _c.service),
          const SizedBox(height: Spacing.formGap),
          SoftNote(
            tone: NoteTone.warning,
            heading: s.applyNotVerifiedTitle,
            message: s.applyNotVerifiedBody,
          ),
          const SizedBox(height: Spacing.section),
          SoftNote(live: false, message: s.applyInPersonAlso),
        ],
      ),
    );
  }

  /// `GET /me` said the account is not linked, before anything was typed.
  /// The same explanation the send's `409` gives, without the form: nothing
  /// she wrote could be sent yet. Never a dead end: the counter, a message to
  /// the office, and the page to come back to once it is linked.
  Widget _unlinked(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String? office = _c.service.officeSlug;
    return _page(
      context,
      key: const Key('apply-unlinked'),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (office != null && office.isNotEmpty) ...<Widget>[
            PrimaryButton(
              key: const Key('apply-message-office'),
              label: s.applyMessageOffice,
              onPressed: () => context.pushNamed(
                AppRoute.officeCompose.routeName,
                pathParameters: <String, String>{'officeId': office},
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          SecondaryButton(
            key: const Key('apply-back-to-programme'),
            label: s.applyBackToProgramme,
            onPressed: widget.onLeave,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ProgrammeCard(service: _c.service),
          const SizedBox(height: Spacing.formGap),
          SoftNote(
            tone: NoteTone.warning,
            heading: s.applyNotLinkedTitle,
            message: s.applyUnlinkedBody,
          ),
          const SizedBox(height: Spacing.section),
          SoftNote(live: false, message: s.applyInPersonAlso),
        ],
      ),
    );
  }

  /// The server's 409: verified, not linked. Never a dead end: the counter,
  /// a message to the office, and sending again once it is linked.
  Widget _notLinked(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final String? office = _c.service.officeSlug;
    return _page(
      context,
      key: const Key('apply-not-linked'),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            key: const Key('apply-try-again'),
            label: s.applyTryAgain,
            onPressed: _c.submit,
          ),
          if (office != null && office.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            SecondaryButton(
              key: const Key('apply-message-office'),
              label: s.applyMessageOffice,
              onPressed: () => context.pushNamed(
                AppRoute.officeCompose.routeName,
                pathParameters: <String, String>{'officeId': office},
              ),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ProgrammeCard(service: _c.service),
          const SizedBox(height: Spacing.formGap),
          SoftNote(
            tone: NoteTone.warning,
            heading: s.applyNotLinkedTitle,
            message: s.applyNotLinkedBody,
          ),
          const SizedBox(height: Spacing.section),
          SoftNote(live: false, message: s.applyInPersonAlso),
          if (_c.failure?.requestId case final String reference)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: SelectableText(
                s.applyFailureReference(reference),
                style: AppTypography.small.copyWith(color: BrandColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// The programme applied for, at the top of a step.
class _ProgrammeCard extends StatelessWidget {
  const _ProgrammeCard({required this.service});

  final SocialService service;

  @override
  Widget build(BuildContext context) {
    final String? office = service.officeShortName ?? service.officeName;
    return SoftCard(
      filled: true,
      child: Row(
        children: <Widget>[
          const IconTile.glyph(glyph: TaytayGlyph.document),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  service.name,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                if (office != null) ...<Widget>[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    office,
                    style: AppTypography.listDetail.copyWith(
                      color: BrandColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: AppTypography.sectionTitle.copyWith(color: BrandColors.ink),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Text(
        text,
        style: AppTypography.bodyStyle.copyWith(
          color: BrandColors.text,
          height: 1.5,
        ),
      ),
    );
  }
}

/// An icon and a line, with the office's own words under it when it has any.
class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.detail, super.key});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final String? detail = this.detail;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TaytayIcon(
            icon: icon,
            semanticLabel: '',
            excludeSemantics: true,
            size: IconSizes.sm,
            color: BrandColors.navy,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: AppTypography.listDetail.copyWith(
                      color: BrandColors.muted,
                      height: 1.5,
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

/// A labelled answer on the review.
class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
          ),
          const SizedBox(height: Spacing.xxs),
          Text(
            value,
            style: AppTypography.bodyStyle.copyWith(color: BrandColors.ink),
          ),
        ],
      ),
    );
  }
}

/// A block of the review, with a Change link back to its step.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.children,
    required this.editKey,
    this.onEdit,
  });

  final String title;
  final List<Widget> children;
  final Key editKey;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
              ),
              TextButton(
                key: editKey,
                onPressed: onEdit,
                child: Text(s.applyEdit),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}
