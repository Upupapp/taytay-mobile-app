# Asset directories

Every file here is declared in `lib/core/assets/asset_manifest.dart` and checked
by `test/core/asset_manifest_test.dart`. **A file that is present but not
declared fails the build**, because an undeclared asset has no recorded licence,
no size budget and no approved hash.

```
assets/
  illustrations/   drawn scenes            2.0x/ 3.0x/   ≤ 120 KB per density
  banners/         wide promotional strips 2.0x/ 3.0x/   ≤  80 KB
  icons/           pictograms              (SVG only)    ≤  12 KB
  placeholders/    stand-ins for remote images 2.0x/ 3.0x/ ≤ 40 KB
  brand/           official LGU artwork    —             ≤ 200 KB
```

## Why these directories are empty

The app's illustrations, scenes, state artwork, placeholders and banner motifs
are **painted in Flutter** (`lib/shared/illustrations/`), not shipped as files.
For flat geometric artwork that is strictly better:

- **no install bytes** — residents frequently pay for them by the megabyte;
- **no density variants** to keep in step;
- **correct in light and dark mode**, because the colours come from the active
  `ColorScheme` rather than from baked-in pixels;
- **no licence surface** at all.

A file earns its place only when it is *materially* better than geometry: a
photographic or hand-painted texture that cannot be expressed as shapes. The
pipeline exists so that when such a file arrives it is checked rather than merely
dropped in.

`assets/brand/` is reserved for official artwork supplied by the Municipality of
Taytay. It is governed additionally by `lib/core/design/brand_assets.dart` and
`SealIntegrityRules`. **No seal is present** — see `docs/taytay-brand-system.md`
§1 for why the available candidate was rejected.

## Adding a file

1. Put the 1x file in the directory for its kind, and the density variants in
   `2.0x/` and `3.0x/` beside it (raster only; SVG needs none).
2. Register an `AssetEntry` in `asset_manifest.dart` with its `sha256`,
   `licence`, `provenance` and `semanticLabel`.
3. Declare the directory under `flutter: assets:` in `pubspec.yaml`.
4. Run `flutter test test/core/asset_manifest_test.dart`.

The tests then enforce: the file exists; its bytes hash to the declared value;
it is within budget; its **format matches its magic bytes** rather than its
extension; PNGs carry alpha; density variants are present; the provenance and
licence are recorded; and — for illustrations — the accessible name begins with
`Illustration:` and claims nothing photographic.
