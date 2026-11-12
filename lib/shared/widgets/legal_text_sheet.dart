import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import '../../features/account/domain/notice_markdown.dart';
import 'app_dialog.dart';
import 'loading_skeleton.dart';

/// What a sheet says when the LGU has not published the Terms of Use.
const String termsNotPublishedYet =
    'The full Terms of Use will be available soon. Taytay LGU has not '
    'published them in the app yet.';

/// What a sheet says when the LGU has not published the Privacy Notice.
const String privacyNoticeNotPublishedYet =
    'The full Privacy Notice will be available soon. Taytay LGU has not '
    'published it in the app yet.';

/// The tick for the Terms of Use. Its own act, never shared with the Privacy
/// Notice: each is recorded with its own kind and version (D-208).
const String termsConsentLabel = 'I have read and agree to the Terms of Use.';

/// The tick for the Privacy Notice, which a resident acknowledges.
const String privacyConsentLabel =
    'I have read the Privacy Notice and understand how Taytay LGU uses my '
    'personal data.';

/// Opens the full text of a Terms of Use or Privacy Notice in a centred
/// dialog (`AppDialog.show`; design rule: popups are centred; the name is
/// kept for callers).
///
/// [markdown] resolves to the published text, or to null or an empty string
/// when there is none; the dialog then shows [pending] instead. The text
/// scrolls on its own between the title and Close, so Close stays in view
/// however long the notice is.
Future<void> showLegalTextSheet(
  BuildContext context, {
  required String title,
  required Future<String?> markdown,
  required String pending,
}) {
  return AppDialog.show<void>(
    context: context,
    title: title,
    scrollable: false,
    builder: (BuildContext dialog) =>
        LegalTextSheet(title: title, markdown: markdown, pending: pending),
    // A dialog has no drag-to-close: the way out is a button a screen reader
    // and a keyboard can reach, as well as Back.
    actions: (BuildContext dialog) =>
        AppDialogActions.close(dialog, closeKey: legalTextCloseKey),
  );
}

/// The Close button under the legal text.
const Key legalTextCloseKey = Key('legal-text-close');

/// The full text behind a "read" link, the content of the dialog
/// [showLegalTextSheet] opens. When nothing is published, one plain sentence
/// says so: the resident is not shown a placeholder as if it were the notice.
///
/// Registration and the re-consent screen both open this one dialog, so the
/// text a resident agrees to reads the same way wherever they agree to it.
class LegalTextSheet extends StatelessWidget {
  const LegalTextSheet({
    required this.title,
    required this.markdown,
    required this.pending,
    super.key,
  });

  /// The notice's name, for the loading announcement.
  final String title;
  final Future<String?> markdown;
  final String pending;

  static final TextStyle _body = AppTypography.bodyStyle.copyWith(
    color: BrandColors.text,
  );

  static final TextStyle _heading = AppTypography.sectionTitle.copyWith(
    fontWeight: AppTypography.black,
    color: BrandColors.taytayBlueDark,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: markdown,
      builder: (BuildContext context, AsyncSnapshot<String?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return LoadingSkeleton(
            layout: SkeletonLayout.text,
            count: 4,
            semanticLabel: 'Loading $title',
          );
        }
        final String text = snap.data?.trim() ?? '';
        if (text.isEmpty) {
          return Semantics(
            liveRegion: true,
            child: Text(pending, style: _body),
          );
        }
        final List<NoticeLine> lines = parseNoticeMarkdown(text);
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: <Widget>[
            for (var i = 0; i < lines.length; i++)
              _Line(line: lines[i], first: i == 0),
          ],
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, required this.first});

  final NoticeLine line;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: first
            ? 0
            : line.heading
            ? Spacing.md
            : Spacing.sm,
      ),
      child: Semantics(
        header: line.heading,
        child: Text.rich(
          TextSpan(
            style: line.heading
                ? LegalTextSheet._heading
                : LegalTextSheet._body,
            children: <InlineSpan>[
              if (line.bullet) const TextSpan(text: '• '),
              for (final NoticeRun run in line.runs)
                TextSpan(
                  text: run.text,
                  style: run.strong
                      ? const TextStyle(fontWeight: AppTypography.black)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
