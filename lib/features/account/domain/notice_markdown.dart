/// One run of notice text. [strong] is `**bold**` in the markdown.
class NoticeRun {
  const NoticeRun(this.text, {this.strong = false});

  final String text;
  final bool strong;
}

/// One line of a privacy notice after markdown is read.
class NoticeLine {
  const NoticeLine(this.runs, {this.heading = false, this.bullet = false});

  final List<NoticeRun> runs;
  final bool heading;
  final bool bullet;

  String get plain => runs.map((NoticeRun run) => run.text).join();
}

/// The small markdown a privacy notice uses: headings, bullets, bold, links.
///
/// A link is the label only. The notice does not open a URL from the markdown.
List<NoticeLine> parseNoticeMarkdown(String source) {
  final String text = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final List<NoticeLine> lines = <NoticeLine>[];
  for (final String raw in text.split('\n')) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('### ')) {
      lines.add(NoticeLine(_runs(trimmed.substring(4).trim()), heading: true));
    } else if (trimmed.startsWith('## ')) {
      lines.add(NoticeLine(_runs(trimmed.substring(3).trim()), heading: true));
    } else if (trimmed.startsWith('# ')) {
      lines.add(NoticeLine(_runs(trimmed.substring(2).trim()), heading: true));
    } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      lines.add(NoticeLine(_runs(trimmed.substring(2).trim()), bullet: true));
    } else {
      lines.add(NoticeLine(_runs(trimmed)));
    }
  }
  return lines;
}

List<NoticeRun> _runs(String input) {
  final String linked = input.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\((?:[^)]*)\)'),
    (Match match) => match.group(1) ?? '',
  );
  final List<NoticeRun> runs = <NoticeRun>[];
  final RegExp bold = RegExp(r'\*\*(.+?)\*\*');
  var cursor = 0;
  for (final Match match in bold.allMatches(linked)) {
    if (match.start > cursor) {
      runs.add(NoticeRun(linked.substring(cursor, match.start)));
    }
    final String word = match.group(1) ?? '';
    if (word.isNotEmpty) runs.add(NoticeRun(word, strong: true));
    cursor = match.end;
  }
  if (cursor < linked.length) runs.add(NoticeRun(linked.substring(cursor)));
  if (runs.isEmpty) runs.add(const NoticeRun(''));
  return runs;
}
