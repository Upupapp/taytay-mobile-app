import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/brand_gradients.dart';
import '../../../core/design/button_styles.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/deep_link.dart';
import '../../../core/session/resident_capability.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/capability_gate.dart';
import '../../../shared/widgets/form_page.dart';
import '../../../shared/widgets/form_support.dart';
import '../../../shared/widgets/icon_tile.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/network_status_views.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/settings_list.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_states.dart';
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
///
/// Drawn as the `List` pattern (Directory.dc): the blue header with the back
/// control, the count, and one soft card per document.
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
      backgroundColor: BrandColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const BlueHeader(title: 'Documents needed', showBack: true),
          const OfflineBanner(),
          Expanded(
            child: CapabilityGate(
              capability: ResidentCapability.submitRequirements,
              child: switch ((_idIsValid, controller)) {
                (false, _) => _Unavailable(
                  message: DeepLinkRejection.invalidIdentifier.residentMessage,
                ),
                (_, null) => const _Loading(),
                (_, final RequirementsController active) => _Checklist(
                  controller: active,
                  onUpload: _openUploadSheet,
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

EdgeInsets _pagePadding(BuildContext context) => EdgeInsets.fromLTRB(
  Spacing.lg,
  Spacing.section,
  Spacing.lg,
  Spacing.xl + MediaQuery.paddingOf(context).bottom,
);

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pagePadding(context),
      children: const <Widget>[
        LoadingSkeleton(
          layout: SkeletonLayout.cards,
          semanticLabel: 'Checking what is needed…',
        ),
      ],
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.controller, required this.onUpload});

  final RequirementsController controller;
  final void Function(ResidentRequirement) onUpload;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) return const _Loading();

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
      return ListView(
        padding: _pagePadding(context),
        children: const <Widget>[_NothingOutstanding()],
      );
    }

    final outstanding = checklist.outstandingCount;

    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _pagePadding(context),
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
              style: AppTypography.sectionTitle.copyWith(
                color: BrandColors.ink,
              ),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Sending a document is not the same as it being accepted. The '
            'office checks each one, and this list changes when they do.',
            style: AppTypography.listDetail.copyWith(color: BrandColors.muted),
          ),
          const SizedBox(height: Spacing.section),
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

/// Nothing outstanding: a statement, not a celebration — the office still
/// decides the request.
class _NothingOutstanding extends StatelessWidget {
  const _NothingOutstanding();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconTile.lucide(
            icon: TaytayIcons.circleCheck,
            tone: TileTone.green,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    'Nothing is outstanding',
                    style: AppTypography.listTitle.copyWith(
                      color: BrandColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.xxs),
                Text(
                  'Taytay LGU is not waiting on any documents from you for '
                  'this request.',
                  style: AppTypography.bodyStyle.copyWith(
                    color: BrandColors.text,
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

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({required this.requirement, required this.onUpload});

  final ResidentRequirement requirement;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final presentation = _StatusPresentation.of(requirement.status);
    final String? instruction = requirement.instruction;
    final String? reviewerMessage = requirement.reviewerMessage;
    final DateTime? lastSubmittedAt = requirement.lastSubmittedAt;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Never colour alone: the icon, the words and the colour all
              // carry the state.
              SettingsIcon(icon: presentation.icon, tone: presentation.tone),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      requirement.label,
                      style: AppTypography.listTitle.copyWith(
                        color: BrandColors.ink,
                      ),
                    ),
                    const SizedBox(height: Spacing.xxs),
                    Text(
                      presentation.label,
                      style: AppTypography.listDetail.copyWith(
                        fontWeight: AppTypography.strong,
                        color: presentation.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              _ObligationChip(obligation: requirement.obligation),
            ],
          ),

          if (instruction != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            Text(
              instruction,
              style: AppTypography.bodyStyle.copyWith(color: BrandColors.text),
            ),
          ],

          if (reviewerMessage != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            SoftNote(
              tone: NoteTone.warning,
              heading: 'What the office said',
              message: reviewerMessage,
            ),
          ],

          if (lastSubmittedAt != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              'Last sent ${_formatDate(lastSubmittedAt)}',
              style: AppTypography.small.copyWith(color: BrandColors.muted),
            ),
          ],

          if (requirement.acceptsUpload) ...<Widget>[
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              style: TaytayButtonStyles.soft(),
              onPressed: onUpload,
              icon: const TaytayIcon(
                icon: TaytayIcons.paperclip,
                semanticLabel: '',
                excludeSemantics: true,
                size: IconSizes.sm,
                color: BrandColors.blue,
              ),
              label: Text(
                requirement.status.known == RequirementStatus.missing
                    ? 'Send this document'
                    : 'Replace this document',
              ),
            ),
          ] else if (requirement.status.known ==
              RequirementStatus.underVerification) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            Text(
              'You cannot replace this while it is being checked. If something '
              'is wrong with it, the office will ask you for another one.',
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
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
    final label = switch (obligation.known) {
      RequirementObligation.required => 'Required',
      RequirementObligation.optional => 'Optional',
      RequirementObligation.conditional => 'If it applies',
      // An unknown obligation is shown as required: telling someone a document
      // is optional when the office considers it mandatory costs them a trip.
      null => 'Required',
    };

    return StatusPill(label: label, tone: PillTone.neutral);
  }
}

/// Words, icon and colour for one status.
///
/// The wording is the whole point of this class: `submitted` reads as "Sent, not
/// checked yet", never as "Done".
class _StatusPresentation {
  const _StatusPresentation(this.label, this.icon, this.tone, this.ink);

  final String label;
  final IconData icon;
  final SettingsTone tone;
  final Color ink;

  static _StatusPresentation of(ServerValue<RequirementStatus> status) {
    return switch (status.known) {
      RequirementStatus.missing => const _StatusPresentation(
        'Not sent yet',
        TaytayIcons.paperclip,
        SettingsTone.blue,
        BrandColors.muted,
      ),
      RequirementStatus.submitted => const _StatusPresentation(
        'Sent — not checked yet',
        TaytayIcons.clock,
        SettingsTone.blue,
        BrandColors.muted,
      ),
      RequirementStatus.underVerification => const _StatusPresentation(
        'Being checked by the office',
        TaytayIcons.hourglass,
        SettingsTone.gold,
        BrandColors.blue,
      ),
      RequirementStatus.needsReplacement => const _StatusPresentation(
        'Needs to be sent again',
        TaytayIcons.circleAlert,
        SettingsTone.red,
        BrandColors.redInk,
      ),
      RequirementStatus.verified => const _StatusPresentation(
        'Checked and accepted',
        TaytayIcons.badgeCheck,
        SettingsTone.green,
        BrandColors.green,
      ),
      RequirementStatus.expired => const _StatusPresentation(
        'Out of date — send a current one',
        TaytayIcons.calendarX,
        SettingsTone.red,
        BrandColors.redInk,
      ),
      // A status this build does not recognise is reported neutrally rather
      // than guessed. "Being processed" is true of every state the app might
      // not know about, and alarms nobody.
      null => const _StatusPresentation(
        'Being processed',
        TaytayIcons.info,
        SettingsTone.blue,
        BrandColors.muted,
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
          SoftNote(
            tone: NoteTone.error,
            heading: AppStrings.of(context).uploadRefusedTitle,
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
                  DocumentSource.camera => TaytayIcons.camera,
                  DocumentSource.gallery => TaytayIcons.image,
                  DocumentSource.file => TaytayIcons.fileText,
                },
                onPressed: () => controller.choose(source),
              ),
            ),

        if (!DocumentSource.values.any(controller.supportsSource))
          const SoftNote(
            tone: NoteTone.info,
            heading: 'This device cannot pick a document',
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
                  color: BrandColors.background,
                  alignment: Alignment.center,
                  child: const Icon(
                    TaytayIcons.fileText,
                    size: IconSizes.xxl,
                    color: BrandColors.muted,
                  ),
                ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '${document.fileName} · ${document.readableSize}',
          style: theme.textTheme.bodySmall?.copyWith(color: BrandColors.muted),
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
      color: BrandColors.background,
      alignment: Alignment.center,
      child: Row(
        children: <Widget>[
          const Icon(
            TaytayIcons.image,
            size: IconSizes.lg,
            color: BrandColors.muted,
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
          style: theme.textTheme.bodySmall?.copyWith(color: BrandColors.muted),
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
            const Icon(
              TaytayIcons.circleCheck,
              color: BrandColors.green,
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
              color: BrandColors.muted,
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
    final Future<void> Function()? retry = onRetry;
    return ListView(
      padding: _pagePadding(context),
      children: <Widget>[
        EmptyState(
          title: 'Documents are not available here yet',
          message: message,
          actionLabel: retry == null ? null : 'Check again',
          onAction: retry,
          boxed: true,
        ),
        const SizedBox(height: Spacing.sm),
        AuthLink(
          'See my requests',
          onPressed: () => context.goNamed(AppRoute.requests.routeName),
        ),
      ],
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
