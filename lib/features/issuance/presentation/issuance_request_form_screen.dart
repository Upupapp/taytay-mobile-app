import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/l10n/issuance_copy.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../domain/issuance_form.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_type.dart';
import 'issuance_failure_copy.dart';
import 'issuance_file_slot.dart';
import 'issuance_request_controller.dart';
import 'issuance_widgets.dart';

/// Filing a document request: the purpose and the files, a review, the send,
/// and the reference number.
///
/// One route with four stages, like the identity-verification wizard: the
/// screen changes state and never navigates to its own successor.
class IssuanceRequestFormScreen extends StatefulWidget {
  const IssuanceRequestFormScreen({required this.typeId, super.key});

  final String typeId;

  @override
  State<IssuanceRequestFormScreen> createState() =>
      _IssuanceRequestFormScreenState();
}

class _IssuanceRequestFormScreenState extends State<IssuanceRequestFormScreen> {
  bool _started = false;
  AppFailure? _loadFailure;
  IssuanceRequestController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  // Another type's form starts empty, never with this one's answers.
  @override
  void didUpdateWidget(IssuanceRequestFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.typeId == widget.typeId) return;
    _controller
      ?..removeListener(_changed)
      ..dispose();
    _controller = null;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadFailure = null);
    final AppDependencies dependencies = AppDependencies.of(context);
    final Result<IssuanceType> result = await dependencies.issuanceRepository
        .loadType(widget.typeId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value):
          _controller = IssuanceRequestController(
            repository: dependencies.issuanceRepository,
            picker: dependencies.documentPicker,
            type: value,
          )..addListener(_changed);
        case Err(:final failure):
          _loadFailure = failure;
      }
    });
  }

  void _changed() {
    if (mounted) setState(() {});
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
    final IssuanceRequestController? controller = _controller;
    final AppFailure? failure = _loadFailure;
    if (controller == null) {
      final AppStrings strings = AppStrings.of(context);
      return IssuanceScaffold(
        title: strings.issuanceRequestTitle,
        body: failure != null
            ? IssuanceLoadFailure(
                failure: failure,
                onRetry: _load,
                failedTitle: strings.issuanceLoadFailedDocument,
              )
            : ListView(
                padding: const EdgeInsets.all(Spacing.lg),
                children: <Widget>[
                  LoadingSkeleton(
                    layout: SkeletonLayout.detail,
                    count: 1,
                    semanticLabel: strings.issuanceFormLoading,
                  ),
                ],
              ),
      );
    }
    return IssuanceRequestFormView(controller: controller);
  }
}

/// The form itself, driven by its controller. Public so the design frames can
/// draw each stage from sample data.
class IssuanceRequestFormView extends StatefulWidget {
  const IssuanceRequestFormView({required this.controller, super.key});

  final IssuanceRequestController controller;

  @override
  State<IssuanceRequestFormView> createState() =>
      _IssuanceRequestFormViewState();
}

class _IssuanceRequestFormViewState extends State<IssuanceRequestFormView> {
  late final TextEditingController _purpose = TextEditingController(
    text: widget.controller.purpose,
  );

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _add(IssuanceRequirement requirement) async {
    final IssuanceRequestController controller = widget.controller;
    final DocumentSource? source = await chooseIssuanceSource(
      context,
      label: requirement.label,
      supports: controller.supports,
    );
    if (source == null) return;
    await controller.choose(requirement.code, source);
  }

  @override
  Widget build(BuildContext context) {
    final IssuanceRequestController controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? _) {
        return switch (controller.stage) {
          IssuanceFormStage.editing => _editing(context, controller),
          IssuanceFormStage.reviewing ||
          IssuanceFormStage.sending => _review(context, controller),
          IssuanceFormStage.done => _done(context, controller),
        };
      },
    );
  }

  Widget _editing(BuildContext context, IssuanceRequestController controller) {
    final AppStrings strings = AppStrings.of(context);
    final IssuanceType type = controller.type;
    final PurposeProblem? purposeProblem = controller.showProblems
        ? controller.purposeProblem
        : null;
    final Set<String> missing = controller.showProblems
        ? <String>{
            for (final IssuanceRequirement r in controller.missing) r.code,
          }
        : const <String>{};
    final String? purposeError = purposeProblem != null
        ? purposeProblemMessage(strings, purposeProblem)
        : controller.serverFlagged('purpose')
        ? strings.applyServerFlagged
        : null;
    return AuthFormPage(
      title: strings.issuanceRequestTitle,
      subtitle: type.name,
      stepLabel: strings.applyStepOf(1, 2),
      progress: 0.5,
      progressSemanticLabel: strings.applyStepOf(1, 2),
      footer: PrimaryButton(
        key: const Key('issuance-review'),
        label: strings.issuanceReviewButton,
        onPressed: controller.review,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (controller.failure case final AppFailure failure)
            _FailureNotice(failure: failure),
          _TypeSummary(type: type),
          const SizedBox(height: Spacing.formGap),
          AuthFieldLabel(strings.issuancePurposeLabel),
          const SizedBox(height: Spacing.sm),
          TextField(
            key: const Key('issuance-purpose'),
            controller: _purpose,
            onChanged: controller.setPurpose,
            minLines: 2,
            maxLines: 5,
            maxLength: issuancePurposeMax,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.fieldValue.copyWith(color: BrandColors.ink),
            decoration: InputDecoration(
              hintText: strings.issuancePurposeHint,
              helperText: strings.issuancePurposeHelp,
              errorText: purposeError,
              errorMaxLines: 3,
              helperMaxLines: 2,
            ),
          ),
          if (type.requirements.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.formGap),
            IssuanceHeading(strings.issuanceFilesNeeded),
            const SizedBox(height: Spacing.xs),
            IssuanceText(
              strings.issuanceFilesIntro(
                acceptedFilesText(strings, type.uploadPolicy),
              ),
              color: BrandColors.muted,
              small: true,
            ),
            for (final IssuanceRequirement requirement in type.requirements)
              IssuanceFileSlot(
                requirement: requirement,
                chosen: controller.files[requirement.code],
                refused: controller.refusedFor(requirement.code),
                policy: type.uploadPolicy,
                missing: missing.contains(requirement.code),
                flagged: controller.serverFlagged(requirement.code),
                onAdd: () => _add(requirement),
                onRemove: () => controller.remove(requirement.code),
              ),
          ],
          if (controller.showProblems && !controller.isComplete) ...<Widget>[
            const SizedBox(height: Spacing.formGap),
            SoftNote(
              tone: NoteTone.error,
              message: strings.issuanceMissingAnswers,
            ),
          ],
        ],
      ),
    );
  }

  Widget _review(BuildContext context, IssuanceRequestController controller) {
    final AppStrings strings = AppStrings.of(context);
    final IssuanceType type = controller.type;
    final bool sending = controller.stage == IssuanceFormStage.sending;
    return AuthFormPage(
      title: strings.issuanceReviewTitle,
      subtitle: type.name,
      stepLabel: strings.applyStepOf(2, 2),
      progress: 1,
      progressSemanticLabel: strings.applyStepOf(2, 2),
      backEnabled: !sending,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            key: const Key('issuance-send'),
            label: sending ? strings.applySending : strings.issuanceSendRequest,
            onPressed: sending ? null : controller.submit,
          ),
          const SizedBox(height: Spacing.sm),
          SecondaryButton(
            key: const Key('issuance-edit'),
            label: strings.issuanceChangeSomething,
            onPressed: sending ? null : controller.backToEditing,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (controller.failure case final AppFailure failure)
            _FailureNotice(failure: failure),
          _TypeSummary(type: type),
          const SizedBox(height: Spacing.formGap),
          IssuanceCard(
            title: strings.issuanceAskingFor,
            child: IssuanceQuote(
              label: strings.issuancePurpose,
              text: controller.purpose.trim(),
            ),
          ),
          if (type.requirements.isNotEmpty)
            IssuanceCard(
              title: strings.issuanceFilesSending,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final IssuanceRequirement requirement
                      in type.requirements)
                    IssuanceFact(
                      icon: controller.files.containsKey(requirement.code)
                          ? TaytayIcons.circleCheck
                          : TaytayIcons.circleSlash,
                      text: switch (controller.files[requirement.code]) {
                        final CapturedDocument file => strings.applyReviewFile(
                          requirement.label,
                          file.isImage ? strings.issuanceKindPhoto : 'PDF',
                          file.readableSize,
                        ),
                        null => strings.issuanceReviewNotSent(
                          requirement.label,
                        ),
                      },
                    ),
                ],
              ),
            ),
          SoftNote(message: strings.issuanceReviewNote),
        ],
      ),
    );
  }

  /// RegDone: the medal, the reference number on the receipt, what happens
  /// next, and the two ways on.
  Widget _done(BuildContext context, IssuanceRequestController controller) {
    final AppStrings strings = AppStrings.of(context);
    final IssuanceRequestDetail? filed = controller.filed;
    final IssuanceType type = controller.type;
    return SuccessScreen(
      mark: SuccessMarkStyle.medal,
      title: strings.issuanceDoneTitle,
      message: strings.issuanceDoneMessage,
      details: <SuccessDetail>[
        SuccessDetail(
          label: strings.myRequestReference,
          value: filed?.summary.referenceNumber ?? '—',
        ),
        SuccessDetail(label: strings.issuanceDocument, value: type.name),
        SuccessDetail(label: strings.issuanceOffice, value: type.officeName),
      ],
      note: strings.issuanceDoneNote,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IssuanceFact(
            icon: TaytayIcons.clock,
            text: issuanceProcessingText(strings, type.processingDays),
          ),
          IssuanceFact(
            icon: TaytayIcons.handCoins,
            text: issuanceFeeText(strings, type.feeCentavos),
          ),
        ],
      ),
      showBack: true,
      primaryLabel: strings.issuanceFollowRequest,
      onPrimary: filed == null
          ? null
          : () => context.goNamed(
              AppRoute.issuanceRequestDetail.routeName,
              pathParameters: <String, String>{'requestId': filed.id},
            ),
      secondaryLabel: strings.issuanceBackToDocuments,
      onSecondary: () => context.goNamed(AppRoute.issuanceCatalogue.routeName),
    );
  }
}

/// The document being asked for, at the top of every stage.
class _TypeSummary extends StatelessWidget {
  const _TypeSummary({required this.type});

  final IssuanceType type;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
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
                  type.name,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.ink,
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                IssuanceText(
                  '${type.officeName} · ${issuanceFeeText(strings, type.feeCentavos)}',
                  color: BrandColors.muted,
                  small: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Says plainly that the request did not reach the office, in this app's
/// words, and offers the way to verification when that is the reason.
class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final ({String title, String body, bool offerVerification}) copy =
        issuanceSendFailure(failure, act: IssuanceAct.submit, strings: strings);
    return Semantics(
      liveRegion: true,
      child: Padding(
        key: const Key('issuance-send-failure'),
        padding: const EdgeInsets.only(bottom: Spacing.formGap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BrandColors.red50,
            borderRadius: BorderRadius.circular(Radii.note),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.section),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  copy.title,
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.redInk,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                IssuanceText(copy.body, color: BrandColors.ink),
                if (failure.requestId case final String reference)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: SelectableText(
                      strings.applyFailureReference(reference),
                      style: AppTypography.small.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ),
                if (copy.offerVerification) ...<Widget>[
                  const SizedBox(height: Spacing.md),
                  SecondaryButton(
                    label: strings.applyGoToVerification,
                    onPressed: () =>
                        context.goNamed(AppRoute.verification.routeName),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
