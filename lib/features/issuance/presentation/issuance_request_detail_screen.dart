import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_glyphs.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/l10n/issuance_copy.dart';
import '../../../core/live/live_message.dart';
import '../../../core/live/live_refresh.dart';
import '../../../core/result/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/detail_page.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/outcome_feedback.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/issuance_form.dart';
import '../domain/issuance_repository.dart';
import '../domain/issuance_request.dart';
import '../domain/issuance_status.dart';
import '../domain/issuance_type.dart';
import 'issuance_failure_copy.dart';
import 'issuance_file_slot.dart';
import 'issuance_send_key.dart';
import 'issuance_widgets.dart';

/// What the confirmation before cancelling a request says, in one place so a
/// test can open it at every phone width and at 200% text (D-202).
///
/// The English, no-context fallback. The screen shows the same sentences in
/// the resident's language (`issuanceCancel…` in the ARB files).
abstract final class IssuanceCancelCopy {
  static const String title = 'Cancel this request?';
  static String message(String reference) =>
      'The office will stop working on $reference. A cancelled request '
      'cannot be opened again; you would send a new one.';
  static const String confirm = 'Cancel request';
  static const String keep = 'Keep it';
}

/// One of the resident's own document requests: where it stands, what the
/// office said, how to claim it, and the two acts the server may allow —
/// sending more, and cancelling.
class IssuanceRequestDetailScreen extends StatefulWidget {
  const IssuanceRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  State<IssuanceRequestDetailScreen> createState() =>
      _IssuanceRequestDetailScreenState();
}

class _IssuanceRequestDetailScreenState
    extends State<IssuanceRequestDetailScreen>
    with LiveRefresh<IssuanceRequestDetailScreen> {
  bool _started = false;
  AppFailure? _failure;
  IssuanceRequestDetail? _detail;
  bool _cancelling = false;

  /// Held across a cancel that timed out, so pressing it again cancels once.
  final IssuanceSendKey _cancelKey = IssuanceSendKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
    // The office moving this request along shows here without a pull
    // (D-218).
    listenLive(AppDependencies.of(context).live, const <String>{
      LiveTopics.issuanceRequests,
    }, () => unawaited(_loadQuietly()));
  }

  /// Re-reads the request for a change (D-218): no loading state, nothing
  /// read while a cancellation is on its way, and a failure keeps the request
  /// on screen and says nothing.
  Future<void> _loadQuietly() async {
    if (_cancelling || _detail == null) return;
    final String requestId = widget.requestId;
    final Result<IssuanceRequestDetail> result = await AppDependencies.of(
      context,
    ).issuanceRepository.loadOwn(requestId);
    if (!mounted || _cancelling || requestId != widget.requestId) return;
    if (result case Ok(:final value)) {
      setState(() {
        _detail = value;
        _failure = null;
      });
    }
  }

  // A notification for another request can arrive while this one is open; the
  // router may keep this State and change only the id.
  @override
  void didUpdateWidget(IssuanceRequestDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId == widget.requestId) return;
    _detail = null;
    _cancelKey.reset();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failure = null);
    final Result<IssuanceRequestDetail> result = await AppDependencies.of(
      context,
    ).issuanceRepository.loadOwn(widget.requestId);
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Ok(:final value):
          _detail = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _cancel() async {
    final IssuanceRequestDetail? detail = _detail;
    if (detail == null || _cancelling) return;
    final AppStrings strings = AppStrings.of(context);
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: strings.issuanceCancelTitle,
      message: strings.issuanceCancelMessage(detail.summary.referenceNumber),
      confirmLabel: strings.issuanceCancelConfirm,
      cancelLabel: strings.issuanceCancelKeep,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    final Result<IssuanceRequestDetail> result = await AppDependencies.of(
      context,
    ).issuanceRepository.cancel(detail.id, idempotencyKey: _cancelKey.take());
    _cancelKey.settle(result);
    if (!mounted) return;
    setState(() {
      _cancelling = false;
      if (result case Ok(:final value)) _detail = value;
    });
    switch (result) {
      case Ok():
        Outcome.succeeded(context, strings.issuanceCancelDone);
      case Err(:final failure):
        Outcome.problem(
          context,
          issuanceSendFailure(
            failure,
            act: IssuanceAct.cancel,
            strings: strings,
          ).body,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final IssuanceRequestDetail? detail = _detail;
    final AppFailure? failure = _failure;
    final AppStrings strings = AppStrings.of(context);
    return IssuanceScaffold(
      title: strings.issuanceDetailTitle,
      white: failure == null,
      body: failure != null
          ? IssuanceLoadFailure(
              failure: failure,
              onRetry: _load,
              failedTitle: strings.issuanceLoadFailedRequest,
            )
          : detail == null
          ? ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: <Widget>[
                LoadingSkeleton(
                  layout: SkeletonLayout.detail,
                  count: 1,
                  semanticLabel: strings.issuanceDetailLoading,
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: IssuanceRequestDetailView(
                detail: detail,
                repository: AppDependencies.of(context).issuanceRepository,
                picker: AppDependencies.of(context).documentPicker,
                onChanged: (IssuanceRequestDetail next) =>
                    setState(() => _detail = next),
                onCancel: detail.canCancel && !_cancelling ? _cancel : null,
              ),
            ),
    );
  }
}

/// The request itself, as the Office detail pattern: the white sheet with
/// the document, its status in words and the reference, then what the office
/// said, the progress and what was sent. Public so the design frames can draw
/// it from sample data.
class IssuanceRequestDetailView extends StatelessWidget {
  const IssuanceRequestDetailView({
    required this.detail,
    required this.repository,
    required this.picker,
    required this.onChanged,
    this.onCancel,
    super.key,
  });

  final IssuanceRequestDetail detail;
  final IssuanceRepository repository;
  final DocumentPicker picker;
  final ValueChanged<IssuanceRequestDetail> onChanged;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final IssuanceStatus? status = detail.status;
    final String? asked = detail.needsInfoMessage;
    final String? claim = detail.claimDetails;
    final String? refusal = detail.refusalReason;
    final String? instructions = detail.claimInstructions;
    final VoidCallback? onCancel = this.onCancel;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: Spacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        DetailSheet(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconTile.glyph(
                  glyph: TaytayGlyph.document,
                  tone: status == IssuanceStatus.needsInfo
                      ? TileTone.gold
                      : TileTone.blue,
                  tileSize: IconTileSize.large,
                ),
                const SizedBox(width: Spacing.section),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: Text(
                          detail.summary.typeName,
                          style: AppTypography.pageTitle.copyWith(
                            color: BrandColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xxs),
                      IssuanceText(
                        detail.summary.officeName,
                        color: BrandColors.muted,
                      ),
                      const SizedBox(height: Spacing.sm),
                      IssuanceStatusChip(status: status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.section),
            IssuanceText(issuanceStatusExplanationText(strings, status)),
            const SizedBox(height: Spacing.sm),
            const Divider(height: 1, thickness: 1, color: BrandColors.divider),
            _ReferenceFact(reference: detail.summary.referenceNumber),
            const SizedBox(height: Spacing.formGap),
            if (status == IssuanceStatus.needsInfo && asked != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.section),
                child: IssuanceQuote(
                  key: const Key('issuance-needs-info'),
                  label: strings.issuanceAskedLabel,
                  text: asked,
                  tone: IssuanceQuoteTone.action,
                ),
              ),
            if (detail.canResubmit)
              IssuanceResubmitSection(
                key: ValueKey<String>('resubmit-${detail.id}'),
                detail: detail,
                repository: repository,
                picker: picker,
                onSent: onChanged,
              ),
            if (status == IssuanceStatus.readyForPickup)
              IssuanceCard(
                title: strings.issuanceHowToClaim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (claim != null)
                      IssuanceQuote(
                        key: const Key('issuance-claim-details'),
                        label: strings.issuanceFromOffice,
                        text: claim,
                        tone: IssuanceQuoteTone.ready,
                      ),
                    if (instructions != null) ...<Widget>[
                      const SizedBox(height: Spacing.sm),
                      IssuanceText(instructions, color: BrandColors.ink),
                    ],
                    IssuanceFact(
                      icon: TaytayIcons.handCoins,
                      text: issuanceFeeText(strings, detail.feeCentavos),
                    ),
                    IssuanceFact(
                      icon: TaytayIcons.idCard,
                      text: strings.issuanceBringId,
                    ),
                  ],
                ),
              ),
            if (status == IssuanceStatus.rejected && refusal != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.section),
                child: IssuanceQuote(
                  label: strings.issuanceRefusalLabel,
                  text: refusal,
                  tone: IssuanceQuoteTone.refused,
                ),
              ),
            IssuanceCard(
              title: strings.issuanceProgress,
              child: IssuanceHistoryTimeline(detail: detail),
            ),
            IssuanceCard(
              title: strings.issuanceYourRequest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  IssuanceQuote(
                    label: strings.issuancePurpose,
                    text: detail.purpose,
                  ),
                  if (status != IssuanceStatus.readyForPickup) ...<Widget>[
                    IssuanceFact(
                      icon: TaytayIcons.handCoins,
                      text: issuanceFeeText(strings, detail.feeCentavos),
                    ),
                    IssuanceFact(
                      icon: TaytayIcons.clock,
                      text: issuanceProcessingText(
                        strings,
                        detail.processingDays,
                      ),
                    ),
                  ],
                  if (detail.attachments.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Spacing.md),
                    Text(
                      strings.issuanceFilesSent,
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                    for (final IssuanceAttachment attachment
                        in detail.attachments)
                      _AttachmentLine(
                        detail: detail,
                        attachment: attachment,
                        repository: repository,
                      ),
                  ],
                ],
              ),
            ),
            if (onCancel != null)
              FilledButton(
                key: const Key('issuance-cancel'),
                style: TaytayButtonStyles.soft(),
                onPressed: onCancel,
                child: Text(strings.issuanceCancelButton),
              ),
          ],
        ),
      ],
    );
  }
}

/// The reference as an Office `.fact` row, selectable so it can be copied
/// for the office.
class _ReferenceFact extends StatelessWidget {
  const _ReferenceFact({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.section),
      child: Row(
        children: <Widget>[
          Container(
            width: ComponentSizes.tileSmall,
            height: ComponentSizes.tileSmall,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BrandColors.background,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: const TaytayIcon(
              icon: TaytayIcons.fileText,
              semanticLabel: '',
              excludeSemantics: true,
              size: IconSizes.sm,
              color: BrandColors.blue,
            ),
          ),
          const SizedBox(width: Spacing.section),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.of(context).myRequestReference,
                  style: AppTypography.small.copyWith(
                    fontWeight: AppTypography.medium,
                    color: BrandColors.muted,
                  ),
                ),
                const SizedBox(height: 1),
                SelectableText(
                  reference,
                  key: const Key('issuance-detail-reference'),
                  style: AppTypography.listTitle.copyWith(
                    color: BrandColors.blue,
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

class _AttachmentLine extends StatelessWidget {
  const _AttachmentLine({
    required this.detail,
    required this.attachment,
    required this.repository,
  });

  final IssuanceRequestDetail detail;
  final IssuanceAttachment attachment;
  final IssuanceRepository repository;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = AppStrings.of(context);
    final String label =
        detail.requirementLabel(attachment.requirementCode) ??
        strings.issuanceFile;
    final String facts = <String>[
      if (attachment.isImage) strings.applyFilePhoto else strings.applyFilePdf,
      if (attachment.version > 1)
        strings.issuanceAttachmentVersion(attachment.version),
      if (!attachment.current) strings.issuanceAttachmentReplaced,
      issuanceDate(attachment.createdAt, strings.localeName),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: IssuanceText(
              '$label: $facts',
              color: BrandColors.textPrimary,
            ),
          ),
          if (attachment.isImage)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(A11y.minTapTarget, A11y.minTapTarget),
              ),
              onPressed: () => _show(context, label),
              child: Text(strings.issuanceView),
            ),
        ],
      ),
    );
  }

  /// Fetches the resident's own photo and shows it. The bytes belong to the
  /// dialog and go when it closes; nothing is written to the phone.
  Future<void> _show(BuildContext context, String label) {
    return AppDialog.show<void>(
      context: context,
      title: label,
      builder: (BuildContext dialog) => _AttachmentPhoto(
        load: () => repository.loadAttachmentImage(detail.id, attachment.id),
        label: label,
      ),
      actions: AppDialogActions.close,
    );
  }
}

/// The photo inside the attachment dialog. Fetched once, when the dialog
/// opens; a rebuild (a rotation, the keyboard) does not fetch it again.
class _AttachmentPhoto extends StatefulWidget {
  const _AttachmentPhoto({required this.load, required this.label});

  final Future<Result<Uint8List>> Function() load;
  final String label;

  @override
  State<_AttachmentPhoto> createState() => _AttachmentPhotoState();
}

class _AttachmentPhotoState extends State<_AttachmentPhoto> {
  late final Future<Result<Uint8List>> _photo = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<Uint8List>>(
      future: _photo,
      builder: (BuildContext context, AsyncSnapshot<Result<Uint8List>> snap) {
        final AppStrings strings = AppStrings.of(context);
        return switch (snap.data) {
          null => LoadingSkeleton(
            layout: SkeletonLayout.photo,
            semanticLabel: strings.issuancePhotoLoading(widget.label),
          ),
          Ok(:final value) => Image.memory(
            value,
            fit: BoxFit.contain,
            semanticLabel: strings.issuancePhotoSemantic(widget.label),
          ),
          Err(:final failure) => IssuanceText(
            failure is NetworkFailure || failure is TimeoutFailure
                ? strings.issuancePhotoOffline
                : strings.issuancePhotoUnavailable,
            color: BrandColors.textPrimary,
          ),
        };
      },
    );
  }
}

/// Sending what the office asked for: an optional note and any new files.
///
/// Every file here is optional, because the server takes a note on its own;
/// at least one of the two is needed. A new file is a new version beside the
/// old one, and the screen says so.
class IssuanceResubmitSection extends StatefulWidget {
  const IssuanceResubmitSection({
    required this.detail,
    required this.repository,
    required this.picker,
    required this.onSent,
    super.key,
  });

  final IssuanceRequestDetail detail;
  final IssuanceRepository repository;
  final DocumentPicker picker;
  final ValueChanged<IssuanceRequestDetail> onSent;

  @override
  State<IssuanceResubmitSection> createState() =>
      _IssuanceResubmitSectionState();
}

class _IssuanceResubmitSectionState extends State<IssuanceResubmitSection> {
  final TextEditingController _note = TextEditingController();
  final Map<String, CapturedDocument> _files = <String, CapturedDocument>{};
  final Map<String, ({DocumentRejection reason, int bytes})> _refused =
      <String, ({DocumentRejection reason, int bytes})>{};
  bool _checked = false;
  bool _sending = false;
  AppFailure? _failure;
  final IssuanceSendKey _key = IssuanceSendKey();

  /// The request's own `accepts` block (backend `0d1cb14`): what the server
  /// checks a resubmission against, still there after the type is retired.
  /// The server checks every file again regardless.
  late UploadPolicy _policy = widget.detail.uploadPolicy;

  @override
  void initState() {
    super.initState();
    if (_policy.source == UploadPolicySource.fallback) _readPolicy();
  }

  /// Only for a request read from a server older than `0d1cb14`, which sent
  /// no `accepts` on it: the type's block, if the type is still listed. A
  /// retired type is a 404 and the labelled fallback stays — the lower
  /// ceiling costs a resident at most a smaller photo.
  Future<void> _readPolicy() async {
    final String? typeId = widget.detail.summary.typeId;
    if (typeId == null) return;
    final Result<IssuanceType> type = await widget.repository.loadType(typeId);
    if (!mounted) return;
    if (type case Ok(:final value)) {
      setState(() => _policy = value.uploadPolicy);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _files.clear();
    super.dispose();
  }

  void _edited() {
    _failure = null;
    _key.reset();
  }

  Future<void> _add(IssuanceRequirement requirement) async {
    final DocumentSource? source = await chooseIssuanceSource(
      context,
      label: requirement.label,
      supports: widget.picker.supports,
    );
    if (source == null) return;
    final CapturedDocument? picked = await widget.picker.pick(source, _policy);
    if (picked == null || !mounted) return;
    final DocumentRejection? refusal = DocumentCapturePolicy.inspect(
      picked,
      _policy,
    );
    setState(() {
      _edited();
      if (refusal != null) {
        _refused[requirement.code] = (reason: refusal, bytes: picked.sizeBytes);
        _files.remove(requirement.code);
      } else {
        _refused.remove(requirement.code);
        _files[requirement.code] = picked;
      }
    });
  }

  Future<void> _send() async {
    setState(() => _checked = true);
    if (!resubmissionHasContent(note: _note.text, files: _files)) return;
    if (_note.text.trim().length > issuanceNoteMax) return;
    final String key = _key.take();
    setState(() {
      _sending = true;
      _failure = null;
    });
    final Result<IssuanceRequestDetail> result = await widget.repository
        .resubmit(
          widget.detail.id,
          note: _note.text,
          files: Map<String, CapturedDocument>.of(_files),
          idempotencyKey: key,
        );
    _key.settle(result);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _files.clear();
        setState(() => _sending = false);
        Outcome.succeeded(context, AppStrings.of(context).issuanceResubmitDone);
        widget.onSent(value);
      case Err(:final failure):
        setState(() {
          _sending = false;
          _failure = failure;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool empty = !resubmissionHasContent(note: _note.text, files: _files);
    final bool tooLong = _note.text.trim().length > issuanceNoteMax;
    final AppFailure? failure = _failure;
    final AppStrings strings = AppStrings.of(context);
    final ({String title, String body, bool offerVerification})? copy =
        failure == null
        ? null
        : issuanceSendFailure(
            failure,
            act: IssuanceAct.resubmit,
            strings: strings,
          );
    return IssuanceCard(
      title: strings.issuanceResubmitTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IssuanceText(strings.issuanceResubmitIntro),
          const SizedBox(height: 10),
          TextField(
            key: const Key('issuance-resubmit-note'),
            controller: _note,
            minLines: 2,
            maxLines: 5,
            maxLength: issuanceNoteMax,
            onChanged: (_) => setState(_edited),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: strings.issuanceResubmitNoteLabel,
              errorText: tooLong
                  ? strings.applyPurposeTooLong(issuanceNoteMax)
                  : null,
            ),
          ),
          for (final IssuanceRequirement requirement
              in widget.detail.requirements)
            IssuanceFileSlot(
              requirement: requirement,
              chosen: _files[requirement.code],
              refused: _refused[requirement.code],
              policy: _policy,
              optionalNote: strings.issuanceResubmitOptional,
              onAdd: () => _add(requirement),
              onRemove: () => setState(() {
                _edited();
                _files.remove(requirement.code);
                _refused.remove(requirement.code);
              }),
            ),
          if (_checked && empty)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: IssuanceText(
                strings.issuanceResubmitEmpty,
                color: BrandColors.danger,
              ),
            ),
          if (copy != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: IssuanceQuote(
                key: const Key('issuance-resubmit-failure'),
                label: copy.title,
                text: copy.body,
                tone: IssuanceQuoteTone.refused,
              ),
            ),
          const SizedBox(height: 10),
          PrimaryButton(
            key: const Key('issuance-resubmit-send'),
            label: _sending
                ? strings.applySending
                : strings.issuanceSendToOffice,
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }
}
