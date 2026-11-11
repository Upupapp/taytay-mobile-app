import 'package:flutter/material.dart';

import '../../core/design/design_tokens.dart';
import '../../core/design/typography.dart';
import '../../features/account/domain/notice_markdown.dart';
import 'app_dialog.dart';

/// What a sheet says when the LGU has not published the Terms of Use.
const String termsNotPublishedYet =
    'The full Terms of Use will be available soon. Taytay LGU has not '
    'published them in the app yet.';

/// What a sheet says when the LGU has not published the Privacy Notice.
const String privacyNoticeNotPublishedYet =
    'The full Privacy Notice will be available soon. Taytay LGU has not '
    'published it in the app yet.';

/// Opens the full text of a Terms of Use or Privacy Notice in a centred
/// dialog (design rule: popups are centred; the name is kept for callers).
///
/// [markdown] resolves to the published text, or to null or an empty string
/// when there is none; the dialog then shows [pending] instead.
Future<void> showLegalTextSheet(
  BuildContext context, {
  required String title,
  required Future<String?> markdown,
  required String pending,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialog) => Dialog(
      insetPadding: AppDialog.panelInset,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ComponentSizes.dialogMaxWidth,
        ),
        child: LegalTextSheet(
          title: title,
          markdown: markdown,
          pending: pending,
        ),
      ),
    ),
  );
}

/// The Close button under the legal text.
const Key legalTextCloseKey = Key('legal-text-close');

/// The full text behind a "read" link. When nothing is published, one plain
/// sentence says so: the resident is not shown a placeholder as if it were
/// the notice.
///
/// Registration and the re-consent screen both open this one sheet, so the
/// text a resident agrees to reads the same way wherever they agree to it.
class LegalTextSheet extends StatelessWidget {
  const LegalTextSheet({
    required this.title,
    required this.markdown,
    required this.pending,
    super.key,
  });

  final String title;
  final Future<String?> markdown;
  final String pending;

  static const TextStyle _body = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 1.5,
    color: Color(0xFF3A4560),
  );

  static const TextStyle _heading = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 15,
    height: 1.4,
    fontWeight: AppTypography.black,
    color: BrandColors.taytayBlueDark,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.formGutter,
            Spacing.formGutter,
            Spacing.formGutter,
            Spacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 18,
                    fontWeight: AppTypography.black,
                    color: BrandColors.taytayBlueDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: FutureBuilder<String?>(
                  future: markdown,
                  builder: (BuildContext context, AsyncSnapshot<String?> snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return Semantics(
                        liveRegion: true,
                        label: 'Loading $title',
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    final String text = snap.data?.trim() ?? '';
                    if (text.isEmpty) {
                      return Semantics(
                        liveRegion: true,
                        child: Text(pending, style: _body),
                      );
                    }
                    return ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        for (final NoticeLine line in parseNoticeMarkdown(text))
                          Padding(
                            padding: EdgeInsets.only(
                              top: line.heading ? 12 : 6,
                            ),
                            child: Semantics(
                              header: line.heading,
                              child: Text.rich(
                                TextSpan(
                                  style: line.heading ? _heading : _body,
                                  children: <InlineSpan>[
                                    if (line.bullet) const TextSpan(text: '• '),
                                    for (final NoticeRun run in line.runs)
                                      TextSpan(
                                        text: run.text,
                                        style: run.strong
                                            ? const TextStyle(
                                                fontWeight: AppTypography.black,
                                              )
                                            : null,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: Spacing.sm),
              // A dialog has no drag-to-close: the way out is a button a
              // screen reader and a keyboard can reach, as well as Back.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: legalTextCloseKey,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
