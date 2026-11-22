import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/documents/document_capture.dart';
import '../../../core/documents/upload_policy.dart';
import '../../../core/l10n/app_locales.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/soft_note.dart';
import '../../../shared/widgets/upload_slot.dart';

/// Asks which way to add a file: camera, photo library or file, whichever
/// this phone offers (D-226). The same three sources, through the same
/// picker, as a document request and identity verification. A picker is a
/// list of choices, so it is the one thing a bottom sheet may be (D-202).
Future<DocumentSource?> chooseDocumentSource(
  BuildContext context, {
  required String label,
  required bool Function(DocumentSource source) supports,
}) {
  final AppStrings s = AppStrings.of(context);
  return AppSheet.show<DocumentSource>(
    context: context,
    title: s.applyChooseSource(label),
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
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Text(s.applyNoPicker),
            ),
          for (final DocumentSource source in offered)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: AppButton(
                key: Key('apply-source-${source.name}'),
                label: documentSourceLabel(sheetContext, source),
                variant: source == DocumentSource.camera
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                icon: switch (source) {
                  DocumentSource.camera => TaytayIcons.camera,
                  DocumentSource.gallery => TaytayIcons.image,
                  DocumentSource.file => TaytayIcons.fileText,
                },
                onPressed: () => Navigator.of(sheetContext).pop(source),
              ),
            ),
        ],
      );
    },
  );
}

/// "Photo added · 1.2 MB": a chosen file's kind and size, in her language.
String chosenFileLine(AppStrings s, CapturedDocument file) =>
    s.applyFileAdded(fileKind(s, file), file.readableSize);

String fileKind(AppStrings s, CapturedDocument file) =>
    file.isImage ? s.applyFilePhoto : s.applyFilePdf;

/// The note an officer wrote for her about one document
/// (`missing_documents[].applicant_note`, ADR 0009, D-230), under a heading
/// that says whose words they are. The words are shown exactly; they are the
/// MSWDO's, not the app's, and never the office's remarks.
class ApplicantNote extends StatelessWidget {
  const ApplicantNote({required this.note, super.key});

  final String note;

  @override
  Widget build(BuildContext context) => SoftNote(
    heading: AppStrings.of(context).myRequestApplicantNoteFrom,
    message: note,
    // Part of the page as it opens, not news arriving.
    live: false,
  );
}

/// One document the office asks for, and the file chosen for it, if any
/// (D-226). Its name, what it needs ([need]), the office's own words under
/// it ([note]), what an officer wrote for her about it ([applicantNote],
/// D-230), then the file or an empty slot, then any problem.
class DocumentSlot extends StatelessWidget {
  const DocumentSlot({
    required this.code,
    required this.name,
    required this.need,
    required this.chosen,
    required this.policy,
    required this.onAdd,
    required this.onRemove,
    this.note,
    this.applicantNote,
    this.refused,
    this.missing = false,
    this.flagged = false,
    super.key,
  });

  /// The field the file is sent under; it keys the slot's controls.
  final String code;
  final String name;

  /// "Required", "Optional", "Only if this applies to you", "Send it again".
  final String need;

  /// A condition or an instruction in the office's words. Null hides it.
  final String? note;

  /// What an officer wrote for her about this document when asking for it
  /// again (D-230). Null hides it.
  final String? applicantNote;
  final CapturedDocument? chosen;
  final UploadPolicy policy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  /// The file the phone refused, and why.
  final ({DocumentRejection reason, int bytes})? refused;

  /// Required and still empty, after she asked to go on.
  final bool missing;

  /// The server named this document in a refusal.
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final CapturedDocument? file = chosen;
    final String? note = this.note;
    final String? applicantNote = this.applicantNote;
    final ({DocumentRejection reason, int bytes})? refusal = refused;
    final String? problem = refusal != null
        ? localisedDocumentRejection(
            context,
            refusal.reason,
            actualBytes: refusal.bytes,
            policy: policy,
          )
        : flagged
        ? s.applyFileFlagged
        : missing
        ? s.applyMissingFile
        : null;
    return Padding(
      key: Key('apply-slot-$code'),
      padding: const EdgeInsets.only(top: Spacing.formGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '$name · $need',
            style: AppTypography.label.copyWith(color: BrandColors.text),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: Spacing.xxs),
            Text(
              note,
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
                height: 1.5,
              ),
            ),
          ],
          if (applicantNote != null) ...<Widget>[
            const SizedBox(height: Spacing.sm),
            ApplicantNote(
              key: Key('apply-applicant-note-$code'),
              note: applicantNote,
            ),
          ],
          const SizedBox(height: Spacing.sm),
          if (file != null)
            AttachedFileCard(
              icon: file.isImage ? TaytayIcons.image : TaytayIcons.fileText,
              title: name,
              status: chosenFileLine(s, file),
              actionLabel: s.applyRemoveFile,
              actionKey: Key('apply-remove-$code'),
              onAction: onRemove,
            )
          else
            UploadSlot(
              key: Key('apply-add-$code'),
              label: s.applyAddFile,
              error: problem != null,
              onPressed: onAdd,
            ),
          if (problem != null) ...<Widget>[
            const SizedBox(height: Spacing.xs + Spacing.xxs),
            Semantics(
              liveRegion: true,
              child: Text(
                problem,
                style: AppTypography.fieldHelp.copyWith(
                  color: BrandColors.danger,
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
