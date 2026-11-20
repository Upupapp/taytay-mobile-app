import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/api/send_key.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/result/result.dart';
import '../../../core/router/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/success_screen.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_states.dart';
import '../domain/own_assistance_request.dart';
import 'apply_failure_copy.dart';
import 'assistance_copy.dart';
import 'document_slot.dart';

/// Sending the documents a returned request still needs (D-226, backend
/// `6794f8d`): one file per document the office named, as a new version
/// beside anything sent before. Nothing she sent earlier is removed (DL-77).
///
/// The request is read from her own list, like one request is; one the list
/// does not carry, or that the office is no longer waiting on, is said so and
/// offers nothing to send.
class AddRequestDocumentsScreen extends StatefulWidget {
  const AddRequestDocumentsScreen({required this.requestId, super.key});

  final String requestId;

  @override
  State<AddRequestDocumentsScreen> createState() =>
      _AddRequestDocumentsScreenState();
}

class _AddRequestDocumentsScreenState extends State<AddRequestDocumentsScreen> {
  bool _started = false;
  bool _loading = true;
  OwnAssistanceRequest? _request;
  AppFailure? _loadFailure;

  final Map<String, CapturedDocument> _files = <String, CapturedDocument>{};
  final Map<String, ({DocumentRejection reason, int bytes})> _refused =
      <String, ({DocumentRejection reason, int bytes})>{};
  final SendKey _key = SendKey();
  bool _checked = false;
  bool _sending = false;
  bool _sent = false;
  AppFailure? _sendFailure;
  Set<String> _flagged = const <String>{};

  /// The route sends no `accepts` block, so files are held to the app's
  /// labelled fallback, under the server's 10 MB (D-226).
  static const UploadPolicy _policy = UploadPolicy.fallback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _files.clear();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailure = null;
    });
    final Result<OwnAssistanceRequest> result = await AppDependencies.of(
      context,
    ).ownAssistanceRepository.findOwn(widget.requestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok(:final value):
          _request = value;
        case Err(:final failure):
          _request = null;
          _loadFailure = failure;
      }
    });
  }

  void _edited() {
    _sendFailure = null;
    _flagged = const <String>{};
    _key.reset();
  }

  Future<void> _add(MissingDocument document) async {
    final DocumentPicker picker = AppDependencies.of(context).documentPicker;
    final DocumentSource? source = await chooseDocumentSource(
      context,
      label: document.name,
      supports: picker.supports,
    );
    if (source == null || !mounted) return;
    final CapturedDocument? picked = await picker.pick(source, _policy);
    if (picked == null || !mounted) return;
    final DocumentRejection? refusal = DocumentCapturePolicy.inspect(
      picked,
      _policy,
    );
    setState(() {
      if (refusal != null) {
        _refused[document.code] = (reason: refusal, bytes: picked.sizeBytes);
        _files.remove(document.code);
      } else {
        _refused.remove(document.code);
        _files[document.code] = picked;
      }
      _edited();
    });
  }

  void _remove(String code) {
    setState(() {
      _files.remove(code);
      _refused.remove(code);
      _edited();
    });
  }

  Future<void> _send() async {
    final OwnAssistanceRequest? request = _request;
    if (request == null || _sending) return;
    setState(() => _checked = true);
    if (_files.isEmpty) return;
    final String key = _key.take();
    setState(() {
      _sending = true;
      _sendFailure = null;
    });
    final Result<OwnAssistanceRequest> result =
        await AppDependencies.of(context).ownAssistanceRepository.addDocuments(
          request.id,
          files: Map<String, CapturedDocument>.of(_files),
          idempotencyKey: key,
        );
    _key.settle(result);
    if (!mounted) return;
    setState(() {
      _sending = false;
      switch (result) {
        case Ok(:final value):
          _request = value;
          _files.clear();
          _sent = true;
        case Err(:final failure):
          _sendFailure = failure;
          _flagged = failure is ValidationFailure
              ? failure.fieldErrors.keys.toSet()
              : const <String>{};
      }
    });
  }

  void _backToRequest() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(
      AppRoute.myRequestDetail.routeName,
      pathParameters: <String, String>{'requestId': widget.requestId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    if (_sent) {
      return SuccessScreen(
        key: const Key('add-docs-done'),
        title: s.addDocsDoneTitle,
        message: s.addDocsDoneMessage,
        primaryLabel: s.addDocsBackToRequest,
        onPrimary: _backToRequest,
      );
    }
    final OwnAssistanceRequest? request = _request;
    final AppFailure? loadFailure = _loadFailure;
    if (request == null || !request.takesDocuments) {
      return AuthFormPage(
        title: s.addDocsTitle,
        onBack: _backToRequest,
        child: _loading
            ? LoadingSkeleton(
                layout: SkeletonLayout.detail,
                count: 1,
                semanticLabel: s.myRequestLoading,
              )
            : request == null && loadFailure is! NotFoundFailure
            ? FailureView(
                failure: loadFailure ?? const UnexpectedFailure(),
                environment: AppDependencies.of(context).config.environment,
                onRetry: _load,
                boxed: true,
              )
            : request == null
            // Said as the one-request page says it: nothing about why.
            ? EmptyState(
                key: const Key('add-docs-not-shown'),
                title: s.myRequestNotShownTitle,
                message: s.myRequestNotShownMessage,
                actionLabel: s.myRequestsSeeAll,
                onAction: () => context.goNamed(AppRoute.myRequests.routeName),
                boxed: true,
              )
            : EmptyState(
                key: const Key('add-docs-none-needed'),
                title: s.addDocsNoneNeeded,
                message: AssistanceCopy.stage(s, request.stage),
                actionLabel: s.addDocsBackToRequest,
                onAction: _backToRequest,
                boxed: true,
              ),
      );
    }
    final AppFailure? sendFailure = _sendFailure;
    return PopScope(
      canPop: !_sending,
      child: AuthFormPage(
        title: s.addDocsTitle,
        subtitle: AssistanceCopy.programme(s, request),
        onBack: _backToRequest,
        backEnabled: !_sending,
        footer: PrimaryButton(
          key: const Key('add-docs-send'),
          label: _sending ? s.applySending : s.addDocsSend,
          onPressed: _sending ? null : _send,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (sendFailure != null)
              SendFailureNotice(failure: sendFailure, documents: true),
            if (request.referenceNumber.isNotEmpty)
              Text(
                request.referenceNumber,
                style: AppTypography.listDetail.copyWith(
                  color: BrandColors.muted,
                ),
              ),
            const SizedBox(height: Spacing.xs),
            Text(
              s.addDocsIntro(_policy.maxMegabytes),
              key: const Key('add-docs-limit'),
              style: AppTypography.bodyStyle.copyWith(
                color: BrandColors.text,
                height: 1.5,
              ),
            ),
            for (final MissingDocument document in request.missingDocuments)
              DocumentSlot(
                code: document.code,
                name: document.name,
                need: switch (document.state) {
                  MissingDocumentState.notSent => s.addDocsStateNotSent,
                  MissingDocumentState.sendAgain => s.addDocsStateSendAgain,
                  MissingDocumentState.other => s.addDocsStateOther,
                },
                note: document.instruction,
                chosen: _files[document.code],
                refused: _refused[document.code],
                policy: _policy,
                flagged: _flagged.contains(document.code),
                onAdd: () => _add(document),
                onRemove: () => _remove(document.code),
              ),
            if (_checked && _files.isEmpty) ...<Widget>[
              const SizedBox(height: Spacing.formGap),
              SoftNote(
                key: const Key('add-docs-nothing-chosen'),
                tone: NoteTone.error,
                message: s.addDocsNothingChosen,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
