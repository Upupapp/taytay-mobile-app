import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_banner.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/form_support.dart';
import '../../../shared/widgets/status_view.dart';
import '../../services/domain/lgu_service.dart' show ServerValue;
import '../domain/resident_requirement.dart';
import 'requirements_controller.dart';

/// The documents Taytay LGU is waiting for on one request, and how to send them.
///
/// ---
///
/// **Submitted is not verified, and this screen never blurs them.** Acceptance 3
/// of TAB 16 is that a resident can tell the difference, so the two states get
/// different words, different colours and different next actions. "Sent" means
/// the LGU has the file; "Checked and accepted" means a person read it.
///
/// **There is no completion meter.** A local percentage implies approval, and
/// approval is a decision only LGU staff make. The screen counts what is still
/// outstanding — a statement about the resident's to-do list — and stops there.
class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({required this.requestId, super.key});

  final String requestId;

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  RequirementsController? _controller;

  /// Re-validated at the point of use: this is the most sensitive deep-link
  /// target in the app and it is reached from a push notification.
  bool get _idIsValid => DeepLink.isValidIdentifier(widget.requestId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || !_idIsValid) return;

    final dependencies = AppDependencies.of(context);
    _controller =
        RequirementsController(
            repository: dependencies.requirementRepository,
            picker: dependencies.documentPicker,
            requestId: widget.requestId,
          )
          ..addListener(_onChanged)
          ..load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _openUploadSheet(ResidentRequirement requirement) async {
    final controller = _controller;
    if (controller == null) return;

    controller.beginUpload(requirement.code);
    await AppSheet.show<void>(
      context: context,
      title: requirement.label,
      builder: (context) =>
          _UploadSheet(controller: controller, requirement: requirement),
    );
    // Whatever happened, the sheet is gone — release the bytes.
    controller.endUpload();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('Documents needed')),
      body: SafeArea(
        child: CapabilityGate(
          capability: ResidentCapability.submitRequirements,
          child: switch ((_idIsValid, controller)) {
            (false, _) => _Unavailable(
              message: DeepLinkRejection.invalidIdentifier.residentMessage,
            ),
            (_, null) => const AppLoadingView(),
            (_, final RequirementsController active) => _Checklist(
              controller: active,
              onUpload: _openUploadSheet,
            ),
          },
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.controller, required this.onUpload});

  final RequirementsController controller;
  final void Function(ResidentRequirement) onUpload;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const AppLoadingView(message: 'Checking what is needed…');
    }

    final checklist = controller.checklist;
    if (checklist == null) {
      return _Unavailable(
        message:
            'Taytay LGU has not switched on document uploads in this app yet. '
            'Bring the documents the office asked for to the municipal hall.',
        onRetry: controller.load,
      );
    }
    if (checklist.isEmpty) {
      return const StatusView(
        title: 'Nothing is outstanding',
        kind: StatusKind.success,
        icon: Icons.task_alt_outlined,
        message:
            'Taytay LGU is not waiting on any documents from you for this '
            'request.',
      );
    }

    final theme = Theme.of(context);
    final outstanding = checklist.outstandingCount;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              // A count of what is left, never a percentage complete. See
              // `RequirementChecklist.outstandingCount`.
              outstanding == 0
                  ? 'Taytay LGU has everything it asked you for.'
                  : outstanding == 1
                  ? 'Taytay LGU is waiting for 1 document.'
                  : 'Taytay LGU is waiting for $outstanding documents.',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Sending a document is not the same as it being accepted. The '
            'office checks each one, and this list changes when they do.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          for (final requirement in checklist.items)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: _RequirementCard(
                requirement: requirement,
                onUpload: () => onUpload(requirement),
              ),
            ),
        ],
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({required this.requirement, required this.onUpload});

  final ResidentRequirement requirement;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = _StatusPresentation.of(requirement.status, theme);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Never colour alone: the icon, the words and the colour all
              // carry the state.
              Icon(
                presentation.icon,
                size: IconSizes.md,
                color: presentation.colour,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(requirement.label, style: theme.textTheme.titleSmall),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      presentation.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: presentation.colour,
                      ),
                    ),
                  ],
                ),
              ),
              _ObligationChip(obligation: requirement.obligation),
            ],
          ),

          if (requirement.instruction != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(requirement.instruction!, style: theme.textTheme.bodySmall),
          ],

          if (requirement.reviewerMessage != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            AppBanner(
              tone: BannerTone.warning,
              title: 'What the office said',
              message: requirement.reviewerMessage!,
            ),
          ],

          if (requirement.lastSubmittedAt != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              'Last sent ${_formatDate(requirement.lastSubmittedAt!)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (requirement.acceptsUpload) ...<Widget>[
            const SizedBox(height: Spacing.md),
            AppButton(
              label: requirement.status.known == RequirementStatus.missing
                  ? 'Send this document'
                  : 'Replace this document',
              variant: AppButtonVariant.secondary,
              onPressed: onUpload,
            ),
          ] else if (requirement.status.known ==
              RequirementStatus.underVerification) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              'You cannot replace this while it is being checked. If something '
              'is wrong with it, the office will ask you for another one.',
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

class _ObligationChip extends StatelessWidget {
  const _ObligationChip({required this.obligation});

  final ServerValue<RequirementObligation> obligation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (obligation.known) {
      RequirementObligation.required => 'Required',
      RequirementObligation.optional => 'Optional',
      RequirementObligation.conditional => 'If it applies',
      // An unknown obligation is shown as required: telling someone a document
      // is optional when the office considers it mandatory costs them a trip.
      null => 'Required',
    };

    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Words, icon and colour for one status.
///
/// The wording is the whole point of this class: `submitted` reads as "Sent, not
/// checked yet", never as "Done".
class _StatusPresentation {
  const _StatusPresentation(this.label, this.icon, this.colour);

  final String label;
  final IconData icon;
  final Color colour;

  static _StatusPresentation of(
    ServerValue<RequirementStatus> status,
    ThemeData theme,
  ) {
    final scheme = theme.colorScheme;
    return switch (status.known) {
      RequirementStatus.missing => _StatusPresentation(
        'Not sent yet',
        Icons.upload_file_outlined,
        scheme.onSurfaceVariant,
      ),
      RequirementStatus.submitted => _StatusPresentation(
        'Sent — not checked yet',
        Icons.schedule_outlined,
        scheme.onSurfaceVariant,
      ),
      RequirementStatus.underVerification => _StatusPresentation(
        'Being checked by the office',
        Icons.hourglass_top_outlined,
        scheme.primary,
      ),
      RequirementStatus.needsReplacement => _StatusPresentation(
        'Needs to be sent again',
        Icons.error_outline,
        scheme.error,
      ),
      RequirementStatus.verified => _StatusPresentation(
        'Checked and accepted',
        Icons.verified_outlined,
        scheme.primary,
      ),
      RequirementStatus.expired => _StatusPresentation(
        'Out of date — send a current one',
        Icons.update_disabled_outlined,
        scheme.error,
      ),
      // A status this build does not recognise is reported neutrally rather
      // than guessed. "Being processed" is true of every state the app might
      // not know about, and alarms nobody.
      null => _StatusPresentation(
        'Being processed',
        Icons.info_outline,
        scheme.onSurfaceVariant,
      ),
    };
  }
}

// ─── The upload sheet ───────────────────────────────────────────────────────

/// Choose → preview → send → result, in one sheet.
class _UploadSheet extends StatefulWidget {
  const _UploadSheet({required this.controller, required this.requirement});

  final RequirementsController controller;
  final ResidentRequirement requirement;

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        switch (controller.stage) {
          UploadStage.choosing => _ChooseStage(controller: controller),
          UploadStage.previewing => _PreviewStage(controller: controller),
          UploadStage.uploading => _UploadingStage(controller: controller),
          UploadStage.accepted => _AcceptedStage(
            onDone: () => Navigator.of(context).pop(),
          ),
          UploadStage.stopped => _StoppedStage(controller: controller),
        },
      ],
    );
  }
}

class _ChooseStage extends StatelessWidget {
  const _ChooseStage({required this.controller});

  final RequirementsController controller;

  @override
  Widget build(BuildContext context) {
    final rejection = controller.rejection;
    // The document that was refused, still held so the message can name its
    // size, and the policy that refused it — the server's, not a constant.
    final refusedSize = controller.refusedSizeBytes;
    final policy = controller.checklist?.uploadPolicy ?? UploadPolicy.fallback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (rejection != null) ...<Widget>[
          AppBanner(
            tone: BannerTone.error,
            title: AppStrings.of(context).uploadRefusedTitle,
            message: localisedDocumentRejection(
              context,
              rejection,
              actualBytes: refusedSize,
              policy: policy,
            ),
          ),
          const SizedBox(height: Spacing.lg),
        ],

        // Guidance before the picker opens, not after a rejection days later.
        const UploadGuidance(
          points: <String>[
            'Lay the document flat and fill the frame.',
            'Make sure every word is in focus and readable.',
            'Avoid glare — turn away from a window or lamp.',
          ],
        ),
        const SizedBox(height: Spacing.lg),

        for (final source in DocumentSource.values)
          if (controller.supportsSource(source))
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: AppButton(
                label: documentSourceLabel(context, source),
                variant: source == DocumentSource.camera
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                icon: switch (source) {
                  DocumentSource.camera => Icons.photo_camera_outlined,
                  DocumentSource.gallery => Icons.photo_library_outlined,
                  DocumentSource.file => Icons.folder_open_outlined,
                },
                onPressed: () => controller.choose(source),
              ),
            ),

        if (!DocumentSource.values.any(controller.supportsSource))
          const AppBanner(
            tone: BannerTone.info,
            title: 'This device cannot pick a document',
            message:
                'Taytay municipal hall can take the document in person, or you '
                'can try again from a phone with a camera.',
          ),
      ],
    );
  }
}

class _PreviewStage extends StatelessWidget {
  const _PreviewStage({required this.controller});

  final RequirementsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = controller.document;
    if (document == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Check this is readable before you send it.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.md),

        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.md),
          child: document.isImage
              ? Image.memory(
                  document.bytes,
                  height: 240,
                  fit: BoxFit.contain,
                  // Announced as what it is, so a screen-reader user knows a
                  // preview exists without it being described as content.
                  semanticLabel: 'Preview of the document you chose',
                  // A file can start with the right signature and still be
                  // truncated — a photo copied off a phone mid-transfer, a
                  // download that stopped. The signature check cannot see that,
                  // the decoder can, and an uncaught decode error here would
                  // take down the sheet a resident is standing in.
                  errorBuilder: (context, error, stackTrace) =>
                      const _PreviewFallback(
                        message:
                            'This file could not be shown. It may be damaged — '
                            'take a photo of the document instead.',
                      ),
                )
              : Container(
                  height: 120,
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: IconSizes.xxl,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '${document.fileName} · ${document.readableSize}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),

        AppButton(
          label: 'Send to Taytay LGU',
          hapticIntent: HapticIntent.confirm,
          onPressed: controller.canSend ? controller.send : null,
        ),
        const SizedBox(height: Spacing.sm),
        AppButton(
          label: 'Choose a different one',
          variant: AppButtonVariant.text,
          onPressed: controller.discard,
        ),
      ],
    );
  }
}

/// Shown when a chosen image will not decode.
///
/// Deliberately still allows sending: the server is the authority on whether a
/// file is usable, and a preview this device could not render is not proof that
/// the office cannot read it.
class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 120,
      padding: const EdgeInsets.all(Spacing.md),
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.broken_image_outlined,
            size: IconSizes.lg,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _UploadingStage extends StatelessWidget {
  const _UploadingStage({required this.controller});

  final RequirementsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (controller.progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          liveRegion: true,
          child: Text('Sending — $percent%', style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: Spacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.sm),
          child: LinearProgressIndicator(
            value: controller.progress,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        // A full bar is not an accepted document, and saying so here is cheaper
        // than a resident leaving on the strength of it.
        Text(
          'Keep this open until Taytay LGU confirms it has the document.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        AppButton(
          label: 'Stop sending',
          variant: AppButtonVariant.text,
          onPressed: controller.cancel,
        ),
      ],
    );
  }
}

class _AcceptedStage extends StatelessWidget {
  const _AcceptedStage({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
              size: IconSizes.lg,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'Taytay LGU has your document',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        // The sentence acceptance 3 turns on.
        Text(
          'It has not been checked yet. The office will look at it and this '
          'list will change when they have.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Spacing.lg),
        AppButton(label: 'Done', onPressed: onDone),
      ],
    );
  }
}

class _StoppedStage extends StatelessWidget {
  const _StoppedStage({required this.controller});

  final RequirementsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = controller.uploadFailure;
    final serverMessages = controller.serverFieldMessages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          failure == null ? 'Sending stopped' : 'That did not send',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          failure == null
              ? 'Nothing was sent to Taytay LGU. You can send it again whenever '
                    'you are ready.'
              : 'Nothing was sent to Taytay LGU, so trying again will not send '
                    'it twice.',
          style: theme.textTheme.bodyMedium,
        ),

        // Server validation text is shown here and only here, because it is the
        // one place it tells the resident something they can act on.
        if (serverMessages.isNotEmpty) ...<Widget>[
          const SizedBox(height: Spacing.md),
          for (final message in serverMessages)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Text('• $message', style: theme.textTheme.bodySmall),
            ),
        ],

        if (failure?.requestId != null) ...<Widget>[
          const SizedBox(height: Spacing.sm),
          Text(
            'If you contact the office, quote ${failure!.requestId}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: Spacing.lg),
        if (controller.document != null)
          AppButton(label: 'Try again', onPressed: controller.retry),
        const SizedBox(height: Spacing.sm),
        AppButton(
          label: 'Choose a different one',
          variant: AppButtonVariant.text,
          onPressed: controller.discard,
        ),
      ],
    );
  }
}

// ─── Shared ─────────────────────────────────────────────────────────────────

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return StatusView(
      title: 'Documents are not available here yet',
      kind: StatusKind.empty,
      icon: Icons.folder_off_outlined,
      message: message,
      primaryAction: onRetry == null
          ? null
          : TextButton(
              onPressed: () => onRetry!(),
              child: const Text('Check again'),
            ),
      secondaryAction: TextButton(
        onPressed: () => context.goNamed(AppRoute.requests.routeName),
        child: const Text('See my requests'),
      ),
    );
  }
}

/// `dd MMM yyyy`, written out because a numeric date is ambiguous between
/// Philippine and US conventions and there is no localisation seam yet.
String _formatDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} ${date.year}';
}
