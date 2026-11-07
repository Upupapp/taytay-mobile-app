import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/s3_surface.dart';
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
            : const Center(child: CircularProgressIndicator()),
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
    return IssuanceScaffold(
      title: 'Request a document',
      footer: PrimaryButton(
        key: const Key('issuance-review'),
        label: 'Review request',
        onPressed: controller.review,
      ),
      body: ListView(
        padding: s3PagePadding,
        children: <Widget>[
          if (controller.failure case final AppFailure failure)
            _FailureNotice(failure: failure),
          _TypeSummary(type: type),
          IssuanceCard(
            title: 'What is the document for?',
            child: TextField(
              key: const Key('issuance-purpose'),
              controller: _purpose,
              onChanged: controller.setPurpose,
              minLines: 2,
              maxLines: 5,
              maxLength: issuancePurposeMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Purpose',
                hintText: 'For example: for a school enrolment requirement',
                helperText: 'The office reads this. Keep it short.',
                errorText: purposeError,
                errorMaxLines: 3,
                helperMaxLines: 2,
              ),
            ),
          ),
          if (type.requirements.isNotEmpty)
            IssuanceCard(
              title: 'Files the office needs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  IssuanceText(
                    'One file each: ${acceptedFilesLine(type.uploadPolicy)}. '
                    'Lay paper flat, fill the frame, and make every word '
                    'readable.',
                  ),
                  for (final IssuanceRequirement requirement
                      in type.requirements)
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
              ),
            ),
          if (controller.showProblems && !controller.isComplete)
            Semantics(
              liveRegion: true,
              child: const Padding(
                padding: EdgeInsets.only(bottom: s3CardGap),
                child: IssuanceText(
                  'Some answers are missing. They are marked above.',
                  color: BrandColors.danger,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context, IssuanceRequestController controller) {
    final IssuanceType type = controller.type;
    final bool sending = controller.stage == IssuanceFormStage.sending;
    return IssuanceScaffold(
      title: 'Review your request',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            key: const Key('issuance-send'),
            label: sending ? 'Sending…' : 'Send request',
            onPressed: sending ? null : controller.submit,
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            key: const Key('issuance-edit'),
            label: 'Change something',
            onPressed: sending ? null : controller.backToEditing,
          ),
        ],
      ),
      body: ListView(
        padding: s3PagePadding,
        children: <Widget>[
          if (controller.failure case final AppFailure failure)
            _FailureNotice(failure: failure),
          _TypeSummary(type: type),
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
          const IssuanceCard(
            child: IssuanceText(
              'Check it before sending. You can cancel the request yourself '
              'until the office starts on it. After that, message the office.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _done(BuildContext context, IssuanceRequestController controller) {
    final IssuanceRequestDetail? filed = controller.filed;
    final IssuanceType type = controller.type;
    return IssuanceScaffold(
      title: 'Request sent',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PrimaryButton(
            key: const Key('issuance-view-filed'),
            label: 'Follow this request',
            onPressed: filed == null
                ? null
                : () => context.goNamed(
                    AppRoute.issuanceRequestDetail.routeName,
                    pathParameters: <String, String>{'requestId': filed.id},
                  ),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Back to documents',
            onPressed: () =>
                context.goNamed(AppRoute.issuanceCatalogue.routeName),
          ),
        ],
      ),
      body: ListView(
        padding: s3PagePadding,
        children: <Widget>[
          IssuanceCard(
            child: Column(
              children: <Widget>[
                const IconTile(
                  icon: TaytayIcons.circleCheck,
                  fill: BrandColors.chipGreenBg,
                  ink: BrandColors.success,
                  size: 60,
                  iconSize: 30,
                ),
                const SizedBox(height: 10),
                Semantics(
                  header: true,
                  child: Text(
                    'The office has your request',
                    textAlign: TextAlign.center,
                    style: s3Type(
                      16,
                      AppTypography.black,
                      BrandColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Reference number',
                  style: s3Type(
                    12,
                    AppTypography.strong,
                    BrandColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  filed?.summary.referenceNumber ?? '—',
                  key: const Key('issuance-reference'),
                  textAlign: TextAlign.center,
                  style: s3Type(
                    22,
                    AppTypography.black,
                    BrandColors.taytayBlue,
                  ),
                ),
                const SizedBox(height: 8),
                const IssuanceText(
                  'Keep this number. The office uses it when you ask about '
                  'your request.',
                ),
              ],
            ),
          ),
          IssuanceCard(
            title: 'What happens next',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const IssuanceText(
                  'The office will review it. Each step shows here and in your '
                  'notifications, including when it is ready to claim.',
                  color: BrandColors.textPrimary,
                ),
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
          ),
        ],
      ),
    );
  }
}

/// The document being asked for, at the top of every stage.
class _TypeSummary extends StatelessWidget {
  const _TypeSummary({required this.type});

  final IssuanceType type;

  @override
  Widget build(BuildContext context) {
    return IssuanceCard(
      child: Row(
        children: <Widget>[
          const IconTile(
            icon: TaytayIcons.fileText,
            fill: BrandColors.chipBlueBg,
            ink: BrandColors.taytayBlue,
            size: 44,
            iconSize: 22,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  type.name,
                  style: s3Type(
                    14,
                    AppTypography.black,
                    BrandColors.textPrimary,
                  ),
                ),
                IssuanceText(
                  '${type.officeName} · ${issuanceFeeLine(type.feeCentavos)}',
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
        issuanceSendFailure(failure, nothing: 'Nothing was sent.');
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('issuance-send-failure'),
        margin: const EdgeInsets.only(bottom: s3CardGap),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrandColors.chipRedBg,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              copy.title,
              style: s3Type(14, AppTypography.black, BrandColors.danger),
            ),
            const SizedBox(height: 4),
            IssuanceText(copy.body, color: BrandColors.textPrimary),
            if (failure.requestId case final String reference)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  'Reference: $reference',
                  style: s3Type(11, FontWeight.w400, BrandColors.textSecondary),
                ),
              ),
            if (copy.offerVerification) ...<Widget>[
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Go to verification',
                onPressed: () =>
                    context.goNamed(AppRoute.verification.routeName),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
