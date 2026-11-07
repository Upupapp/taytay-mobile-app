import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../domain/issuance_type.dart';

/// Asks which way to add a file: camera, photo library or file, whichever
/// this phone offers. The same three sources, through the same picker, as
/// the identity-verification and requirements uploads.
Future<DocumentSource?> chooseIssuanceSource(
  BuildContext context, {
  required String label,
  required bool Function(DocumentSource source) supports,
}) {
  return AppSheet.show<DocumentSource>(
    context: context,
    title: 'Add: $label',
    builder: (BuildContext sheetContext) {
      final List<DocumentSource> offered = <DocumentSource>[
        for (final DocumentSource source in DocumentSource.values)
          if (supports(source)) source,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (offered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'This phone cannot pick a file. The office can take the '
                'document in person at the Municipal Hall.',
              ),
            ),
          for (final DocumentSource source in offered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppButton(
                key: Key('issuance-source-${source.name}'),
                label: documentSourceLabel(sheetContext, source),
                variant: source == DocumentSource.camera
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                icon: switch (source) {
                  DocumentSource.camera => Icons.photo_camera_outlined,
                  DocumentSource.gallery => Icons.photo_library_outlined,
                  DocumentSource.file => Icons.folder_open_outlined,
                },
                onPressed: () => Navigator.of(sheetContext).pop(source),
              ),
            ),
        ],
      );
    },
  );
}

/// One requirement and the file chosen for it, if any.
class IssuanceFileSlot extends StatelessWidget {
  const IssuanceFileSlot({
    required this.requirement,
    required this.chosen,
    required this.policy,
    required this.onAdd,
    required this.onRemove,
    this.refused,
    this.missing = false,
    this.flagged = false,
    this.optionalNote,
    super.key,
  });

  final IssuanceRequirement requirement;
  final CapturedDocument? chosen;
  final UploadPolicy policy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// The file the phone refused, and why.
  final ({DocumentRejection reason, int bytes})? refused;

  /// Required and still empty, after the resident asked to review.
  final bool missing;

  /// The server named this file in a refusal.
  final bool flagged;

  /// Replaces "Optional" for a resubmission, where every file is optional.
  final String? optionalNote;

  @override
  Widget build(BuildContext context) {
    final CapturedDocument? file = chosen;
    final String? hint = requirement.hint;
    final ({DocumentRejection reason, int bytes})? refusal = refused;
    final String need =
        optionalNote ?? (requirement.required ? 'Required' : 'Optional');
    final String? problem = refusal != null
        ? localisedDocumentRejection(
            context,
            refusal.reason,
            actualBytes: refusal.bytes,
            policy: policy,
          )
        : flagged
        ? 'The office could not accept this file. Choose it again, or choose '
              'another.'
        : missing
        ? 'Add this file to continue.'
        : null;
    return Container(
      key: Key('issuance-slot-${requirement.code}'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandColors.surfaceCard,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: problem == null ? BrandColors.cardLine : BrandColors.danger,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${requirement.label} · $need',
            style: s3Type(
              13,
              AppTypography.strong,
              BrandColors.textPrimary,
              height: 1.5,
            ),
          ),
          if (hint != null)
            Text(
              hint,
              style: s3Type(
                12,
                AppTypography.body,
                BrandColors.textSecondary,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 8),
          if (file != null)
            Row(
              children: <Widget>[
                TaytayIcon(
                  icon: file.isImage ? TaytayIcons.image : TaytayIcons.fileText,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 18,
                  color: BrandColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${file.isImage ? 'Photo' : 'PDF'} added · '
                    '${file.readableSize}',
                    style: s3Type(
                      13,
                      AppTypography.body,
                      BrandColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                TextButton(
                  key: Key('issuance-remove-${requirement.code}'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      A11y.minTapTarget,
                      A11y.minTapTarget,
                    ),
                  ),
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
              ],
            )
          else
            AppButton(
              key: Key('issuance-add-${requirement.code}'),
              label: 'Add file',
              variant: AppButtonVariant.secondary,
              icon: Icons.add,
              onPressed: onAdd,
            ),
          if (problem != null) ...<Widget>[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                problem,
                style: s3Type(
                  12,
                  AppTypography.body,
                  BrandColors.danger,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
