/// The redesign's solid icons (design/icons), drawn by `GlyphIcon` and
/// `IconTile.glyph` in `lib/shared/widgets/`.
///
/// Feature code names a glyph, never a file path: the paths live here once,
/// and every one of them is declared in `AppAssets` with its hash, so a renamed
/// or edited file fails `asset_manifest_test.dart` instead of drawing nothing.
///
/// The files fill with `currentColor`; the widget paints them in one colour.
/// Lucide (`TaytayIcons`) stays for line icons the set does not have.
enum TaytayGlyph {
  bank('bank'),
  briefcase('brief'),
  graduationCap('cap'),
  chat('chat'),
  check('check'),
  clock('clock'),
  cloud('cloud'),
  cloudOff('cloudoff'),
  medicalCross('cross'),
  directory('dir'),
  document('doc'),
  globe('globe'),
  heart('heart'),
  megaphone('mega'),
  phone('phone'),
  pin('pin'),
  search('search'),
  send('send'),
  siren('siren'),
  users('users');

  const TaytayGlyph(this.file);

  /// File name in `assets/icons/`, without the extension.
  final String file;

  String get assetPath => 'assets/icons/$file.svg';
}

/// The two empty-state illustrations (design/icons `empty_*.svg`), 168 × 132.
enum TaytayIllustration {
  /// A search that found nothing. Empty lists and searches.
  noResults('empty_no_results'),

  /// A cloud with a red cross. Offline and could-not-load states.
  offline('empty_offline');

  const TaytayIllustration(this.file);

  final String file;

  String get assetPath => 'assets/illustrations/$file.svg';

  /// The art's own size (CSS `.es .art`).
  static const double width = 168;
  static const double height = 132;
}
