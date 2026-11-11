import 'social_service.dart';

/// Tulong's search, which runs on the phone (D-59, D-205).
///
/// A search term typed into a municipal app ("solo parent", "burial",
/// "dialysis") is a sentence about somebody's circumstances. The catalogue is
/// public and small, so the app reads all of it and filters here; the term
/// never leaves the device, and no repository method takes one.
///
/// Matching is on what a resident reads on the row and the page header: the
/// list title, the name, the summary, the category and the office. Not the
/// slug or the id, which a resident never sees, so a match on them could not
/// be explained (D-59).
///
/// Every word typed must appear somewhere, in any order. Case and the
/// common Latin accents are ignored, so "nino" finds "Niño" and "SENIOR"
/// finds "senior".
List<SocialService> searchServices(List<SocialService> services, String query) {
  final List<String> words = searchWords(query);
  if (words.isEmpty) return services;
  return <SocialService>[
    for (final SocialService service in services)
      if (_matchesAll(_haystack(service), words)) service,
  ];
}

/// [query] folded and split into words. Empty when nothing was typed.
List<String> searchWords(String query) => <String>[
  for (final String word in foldForSearch(query).split(' '))
    if (word.isNotEmpty) word,
];

/// Lower case, accents removed, runs of white space as one space.
String foldForSearch(String text) {
  final StringBuffer out = StringBuffer();
  for (final int rune in text.toLowerCase().runes) {
    // A combining accent typed after its letter (decomposed text) goes too.
    if (rune >= 0x300 && rune <= 0x36F) continue;
    final String char = String.fromCharCode(rune);
    out.write(_folded[char] ?? char);
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _matchesAll(String haystack, List<String> words) {
  for (final String word in words) {
    if (!haystack.contains(word)) return false;
  }
  return true;
}

String _haystack(SocialService service) => foldForSearch(
  <String?>[
    service.listTitle,
    service.name,
    service.summary,
    service.category,
    service.officeName,
    service.officeShortName,
  ].whereType<String>().join(' '),
);

/// The accented letters Filipino and English text in this catalogue use.
const Map<String, String> _folded = <String, String>{
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
  'ý': 'y',
  'ÿ': 'y',
};
