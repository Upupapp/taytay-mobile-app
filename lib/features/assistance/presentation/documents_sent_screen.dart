import 'package:flutter/material.dart';

import '../../../core/time/manila_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/success_screen.dart';
import '../domain/own_assistance_request.dart';
import 'assistance_copy.dart';

/// One file she sent: the document it answers, and what the file was. Only
/// what the receipt says; the bytes are let go once the send answers.
@immutable
class SentDocument {
  const SentDocument({
    required this.name,
    required this.isImage,
    required this.size,
  });

  final String name;
  final bool isImage;

  /// Already readable ("1.2 MB").
  final String size;
}

/// The result of Add documents (D-226, D-231): what was sent and when, what
/// happens next, and the way back to the request.
///
/// Every line comes from the send's own answer or from what she chose: the
/// request as the API returned it (`201`), its `documents_sent_at`, and the
/// documents named in the send. Nothing promises a time (D-37). A request the
/// office still names documents on says which, so she is not told the office
/// has everything when it does not.
class DocumentsSentScreen extends StatelessWidget {
  const DocumentsSentScreen({
    required this.request,
    required this.sent,
    required this.onBackToRequest,
    super.key,
  });

  /// The request as the send returned it.
  final OwnAssistanceRequest request;
  final List<SentDocument> sent;
  final VoidCallback onBackToRequest;

  @override
  Widget build(BuildContext context) {
    final AppStrings s = AppStrings.of(context);
    final DateTime? sentAt = request.documentsSentAt;
    final List<MissingDocument> stillNeeded = request.missingDocuments;
    return SuccessScreen(
      key: const Key('add-docs-done'),
      title: s.addDocsDoneTitle,
      message: stillNeeded.isEmpty
          ? s.addDocsDoneMessage
          : s.addDocsDoneStillNeeded(
              stillNeeded.map((MissingDocument d) => d.name).join(', '),
            ),
      details: <SuccessDetail>[
        if (request.referenceNumber.isNotEmpty)
          SuccessDetail(
            label: s.myRequestReference,
            value: request.referenceNumber,
          ),
        SuccessDetail(
          label: s.applyReviewProgramme,
          value: AssistanceCopy.programme(s, request),
        ),
        for (final SentDocument document in sent)
          SuccessDetail(
            label: document.name,
            value: s.addDocsDoneFile(
              document.isImage ? s.applyFilePhoto : s.applyFilePdf,
              document.size,
            ),
          ),
        // The server's record of the send; an API that does not send it
        // leaves the line out rather than the phone's clock standing in.
        if (sentAt != null)
          SuccessDetail(
            label: s.addDocsDoneSentOn,
            value: ManilaTime.formatDateTime(
              sentAt,
              languageCode: Localizations.localeOf(context).languageCode,
            ),
          ),
      ],
      note: s.addDocsDoneNote,
      primaryLabel: s.addDocsBackToRequest,
      onPrimary: onBackToRequest,
    );
  }
}
