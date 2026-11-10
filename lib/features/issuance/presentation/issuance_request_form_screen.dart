import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../domain/issuance_form.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_terms.dart';
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
      return IssuanceScaffold(
        title: 'Request a document',
        body: failure != null
            ? IssuanceLoadFailure(
                failure: failure,
                onRetry: _load,
                what: 'this document',
              )
            : ListView(
                padding: const EdgeInsets.all(Spacing.lg),
                children: const <Widget>[
                  LoadingSkeleton(
                    layout: SkeletonLayout.detail,
                    count: 1,
                    semanticLabel: 'Opening the form',
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
        ? purposeProblemText(purposeProblem)
        : controller.serverFlagged('purpose')
        ? 'The office could not accept this. Check what you wrote.'
        : null;
    return AuthFormPage(
      title: 'Request a document',
      subtitle: type.name,
      stepLabel: 'Step 1 of 2',
      progress: 0.5,
      progressSemanticLabel: 'Step 1 of 2',
      footer: PrimaryButton(
        key: const Key('issuance-review'),
        label: 'Review request',
        onPressed: controller.review,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (controller.failure case final AppFailure failure)
            _FailureNotice(failure: failure),
          _TypeSummary(type: type),
          const SizedBox(height: Spacing.formGap),
          const AuthFieldLabel('What is the document for?'),
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
              hintText: 'For example: for a school enrolment requirement',
              helperText: 'The office reads this. Keep it short.',
              errorText: purposeError,
              errorMaxLines: 3,
              helperMaxLines: 2,
            ),
          ),
          if (type.requirements.isNotEmpty) ...<Widget>[
            const SizedBox(height: Spacing.formGap),
            const IssuanceHeading('Files the office needs'),
            const SizedBox(height: Spacing.xs),
            IssuanceText(
              'One file each: ${acceptedFilesLine(type.uploadPolicy)}. '
              'Lay paper flat, fill the frame, and make every word '
              'readable.',
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
            const SoftNote(
              tone: NoteTone.error,
              message: 'Some answers are missing. They are marked above.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _review(BuildContext context, IssuanceRequestController controller) {
    final IssuanceType type = controller.type;
    final bool sending = controller.stage == IssuanceFormStage.sending;
    return AuthFormPage(
      title: 'Review your request',
      subtitle: type.name,
      stepLabel: 'Step 2 of 2',
      progress: 1,
      progressSemanticLabel: 'Step 2 of 2',
      backEnabled: !sending,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            key: const Key('issuance-send'),
            label: sending ? 'Sending…' : 'Send request',
            onPressed: sending ? null : controller.submit,
          ),
          const SizedBox(height: Spacing.sm),
          SecondaryButton(
            key: const Key('issuance-edit'),
            label: 'Change something',
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
            title: 'You are asking for it',
            child: IssuanceQuote(
              label: 'Purpose',
              text: controller.purpose.trim(),
            ),
          ),
          if (type.requirements.isNotEmpty)
            IssuanceCard(
              title: 'Files you are sending',
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
                        final CapturedDocument file =>
                          '${requirement.label}: '
                              '${file.isImage ? 'photo' : 'PDF'}, '
                              '${file.readableSize}',
                        null => '${requirement.label}: not sent (optional)',
                      },
                    ),
                ],
              ),
            ),
          const SoftNote(
            message:
                'Check it before sending. You can cancel the request yourself '
                'until the office starts on it. After that, message the office.',
          ),
        ],
      ),
    );
  }

  /// RegDone: the medal, the reference number on the receipt, what happens
  /// next, and the two ways on.
  Widget _done(BuildContext context, IssuanceRequestController controller) {
    final IssuanceRequestDetail? filed = controller.filed;
    final IssuanceType type = controller.type;
    return SuccessScreen(
      mark: SuccessMarkStyle.medal,
      title: 'The office has your request',
      message:
          'Keep this number. The office uses it when you ask about your '
          'request.',
      details: <SuccessDetail>[
        SuccessDetail(
          label: 'Reference number',
          value: filed?.summary.referenceNumber ?? '—',
        ),
        SuccessDetail(label: 'Document', value: type.name),
        SuccessDetail(label: 'Office', value: type.officeName),
      ],
      note:
          'The office will review it. Each step shows here and in your '
          'notifications, including when it is ready to claim.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IssuanceFact(
            icon: TaytayIcons.clock,
            text: issuanceProcessingLine(type.processingDays),
          ),
          IssuanceFact(
            icon: TaytayIcons.handCoins,
            text: issuanceFeeLine(type.feeCentavos),
          ),
        ],
      ),
      showBack: true,
      primaryLabel: 'Follow this request',
      onPrimary: filed == null
          ? null
          : () => context.goNamed(
              AppRoute.issuanceRequestDetail.routeName,
              pathParameters: <String, String>{'requestId': filed.id},
            ),
      secondaryLabel: 'Back to documents',
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
                  '${type.officeName} · ${issuanceFeeLine(type.feeCentavos)}',
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
    final ({String title, String body, bool offerVerification}) copy =
        issuanceSendFailure(failure, act: IssuanceAct.submit);
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
                      'Reference: $reference',
                      style: AppTypography.small.copyWith(
                        color: BrandColors.muted,
                      ),
                    ),
                  ),
                if (copy.offerVerification) ...<Widget>[
                  const SizedBox(height: Spacing.md),
                  SecondaryButton(
                    label: 'Go to verification',
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
