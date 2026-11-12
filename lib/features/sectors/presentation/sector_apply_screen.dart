import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../domain/resident_sector.dart';
import 'sector_apply_canvas.dart';
import 'sector_apply_controller.dart';
import 'sectors_copy.dart';

/// Apply for a sector: senior citizen, person with disability or solo parent,
/// with a photo of the ID (D-215).
///
/// One route, three steps. Step 2's back returns to step 1; while the
/// application is being sent, back waits. The result's buttons leave the
/// flow, so back from it never reopens a form that was already sent.
class SectorApplyScreen extends StatefulWidget {
  const SectorApplyScreen({this.initial, super.key});

  /// The sector the resident tapped on Sectors and benefits, if any.
  final ResidentSector? initial;

  @override
  State<SectorApplyScreen> createState() => _SectorApplyScreenState();
}

class _SectorApplyScreenState extends State<SectorApplyScreen> {
  SectorApplyController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final AppDependencies dependencies = AppDependencies.of(context);
    _controller = SectorApplyController(
      repository: dependencies.sectorRepository,
      picker: dependencies.documentPicker,
      initial: widget.initial,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(SectorApplyController controller) async {
    final List<DocumentSource> offered = <DocumentSource>[
      // A photo of the ID: the camera or the gallery, never a file.
      for (final DocumentSource source in const <DocumentSource>[
        DocumentSource.camera,
        DocumentSource.gallery,
      ])
        if (controller.supports(source)) source,
    ];
    final DocumentSource? source = await AppSheet.show<DocumentSource>(
      context: context,
      title: SectorsCopy.sourceTitle,
      builder: (BuildContext sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (offered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Text(
                SectorsCopy.noSource,
                style: AppTypography.bodyStyle.copyWith(
                  color: BrandColors.text,
                ),
              ),
            ),
          for (final DocumentSource choice in offered)
            PickerChoiceRow(
              rowKey: Key('sector-source-${choice.name}'),
              label: documentSourceLabel(sheet, choice),
              selected: false,
              onTap: () => Navigator.of(sheet).pop(choice),
            ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    await controller.pick(source);
  }

  Future<void> _send(SectorApplyController controller) async {
    await controller.send();
    if (!mounted || controller.step != SectorApplyStep.sent) return;
    await AppHaptics.fire(
      HapticIntent.success,
      suppressed: Motion.reduced(context),
    );
  }

  void _toSectors() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.sectors.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SectorApplyController? controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, _) {
        final SectorApplyStep step = controller.step;
        return PopScope(
          canPop:
              step == SectorApplyStep.choose || step == SectorApplyStep.sent,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) controller.back();
          },
          child: SectorApplyCanvas(
            step: step,
            policy: UploadPolicy.fallback,
            chosen: controller.chosen,
            proof: controller.proof,
            refused: controller.refused,
            confirmed: controller.confirmed,
            failure: controller.failure,
            filed: controller.filed,
            onChoose: controller.choose,
            onNext: controller.next,
            onStepBack: controller.back,
            onAddPhoto: () => _addPhoto(controller),
            onConfirm: controller.confirm,
            onSend: () => _send(controller),
            onSectors: _toSectors,
            onHome: () => context.goNamed(AppRoute.home.routeName),
          ),
        );
      },
    );
  }
}
