import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/design/brand_assets.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/app_failure.dart';
import '../../../core/time/manila_time.dart';
import '../../../shared/widgets/blue_header.dart';
import '../../../shared/widgets/dashed_outline.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/s3_surface.dart';
import '../../../shared/widgets/surface_cards.dart';
import '../../../shared/widgets/taytay_buttons.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../../verification/domain/verification_id_type.dart';
import '../domain/card_preparation.dart';
import '../domain/credential_repository.dart';
import '../domain/digital_id_face.dart';
import 'card_preparing_copy.dart';

/// The issued card, the four non-active explanations, the "being prepared"
/// page for a resident with no card (design `DigitalID.dc.html` and
/// `IDStatus.dc.html`, the card pattern on a glass page), and the not-issued
/// card for a status this build does not recognise.
///
/// The shell paints the tab bar. The QR token is painted and then dropped: it
/// is not a label, a key, or a diagnostic field. The card shows what the
/// server sent and nothing else; this phone never decides it is genuine.
class DigitalIdView extends StatelessWidget {
  const DigitalIdView({
    required this.now,
    this.card,
    this.name,
    this.sample = false,
    this.failure,
    this.environment = AppEnvironment.dev,
    this.onRetry,
    this.loadPhoto,
    this.loading = false,
    this.preparation = CardPreparation.unknown,
    this.onMessageOffice,
    super.key,
  });

  /// The scannable code. Tests read this box to mask the design comparison.
  static const Key qrKey = Key('digital-id-qr');

  /// The resident's name, when the NAME block is shown.
  static const Key nameKey = Key('digital-id-name');

  final ResidentCredential? card;

  /// GET /me `name`, already trimmed. Blank hides the NAME block.
  final String? name;

  final DateTime now;
  final bool sample;
  final AppFailure? failure;
  final AppEnvironment environment;
  final VoidCallback? onRetry;

  /// `GET /media/{id}/content` for the card portrait. Null keeps the placeholder.
  final MediaBytesLoader? loadPhoto;

  /// True until the first read answers, so "Not yet issued" is never shown
  /// for a card that is still loading.
  final bool loading;

  /// The dates of the steps already taken, for a resident with no card.
  final CardPreparation preparation;

  /// Opens a message to the MSWDO. Null hides the button.
  final VoidCallback? onMessageOffice;

  @override
  Widget build(BuildContext context) {
    final String? published = publishedResidentName(name);
    final ResidentCredential? card = this.card;
    final DigitalIdFace? face = digitalIdFace(card, now);
    final AppFailure? failure = this.failure;
    final List<Widget> body;
    if (loading) {
      body = const <Widget>[
        LoadingSkeleton(
          layout: SkeletonLayout.detail,
          semanticLabel: 'Loading your digital ID',
        ),
      ];
    } else if (failure != null) {
      body = <Widget>[
        GlassCard(
          child: FailureView(
            failure: failure,
            environment: environment,
            onRetry: onRetry,
          ),
        ),
      ];
    } else if (card == null) {
      // No card (a 404 or a null `data`): the API sends no state for this,
      // so it is not given one; the steps say what already happened (D-207).
      body = <Widget>[
        const _PreparingCard(),
        _PreparingSteps(preparation: preparation),
        _AboutCard(onMessageOffice: onMessageOffice),
      ];
    } else if (face == null) {
      // A card in a status this build cannot read is not called "being
      // prepared" (it exists) nor shown as working (CLAUDE.md Article 5.8).
      body = <Widget>[
        const _IdCard(),
        Text(
          'Your digital ID will appear here once Taytay LGU issues it.',
          textAlign: TextAlign.center,
          style: _note,
        ),
      ];
    } else {
      final PresentationArtifact? qr = face == DigitalIdFace.active
          ? card.qr
          : null;
      body = <Widget>[
        _IdCard(
          card: card,
          name: published,
          face: face,
          sample: sample,
          loadPhoto: loadPhoto,
        ),
        if (qr != null) _QrCard(qr: qr, now: now),
        if (face != DigitalIdFace.active) _Notice(face: face),
        Text(
          'Taytay LGU issued this card. A scanner checks the code. '
          'This phone does not decide that the card is genuine.',
          textAlign: TextAlign.center,
          style: _note,
        ),
        if (sample) const _SampleFooter(),
      ];
    }
    // Material gives the page the theme's text style wherever it is hosted
    // (the shell, a golden frame), so no text falls back to the debug style.
    return Material(
      type: MaterialType.transparency,
      child: GlassBackground(
        child: ListView(
          // No per-item repaint / semantics wrappers: they hit-test only their
          // own box, so the strip GlassOverlap raises over the header would not
          // take a tap.
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
          padding: const EdgeInsets.only(bottom: Spacing.xl),
          children: <Widget>[
            const BlueHeader(
              title: 'My Taytay ID',
              subtitle: 'Bayan ng Taytay · Rizal',
              showBack: true,
              overlap: true,
              actions: <Widget>[HeaderSeal()],
            ),
            GlassOverlap(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (var i = 0; i < body.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: Spacing.section),
                      body[i],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final TextStyle _note = AppTypography.listDetail.copyWith(
  color: BrandColors.muted,
);

/// `.idc`: the card. A null [card] draws the not-issued face.
class _IdCard extends StatelessWidget {
  const _IdCard({
    this.card,
    this.name,
    this.face,
    this.sample = false,
    this.loadPhoto,
  });

  final ResidentCredential? card;
  final String? name;
  final DigitalIdFace? face;
  final bool sample;
  final MediaBytesLoader? loadPhoto;

  /// A card does not stretch across a tablet: ID-1 proportions stop here.
  static const double _maxWidth = 420;

  /// ID-1 card proportions (85.6 × 54 mm). Large text grows the card instead.
  static const double _ratio = 1.586;

  @override
  Widget build(BuildContext context) {
    final ResidentCredential? card = this.card;
    final DigitalIdFace? face = this.face;
    final bool dimmed = face != null && face != DigitalIdFace.active;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            Widget content = Semantics(
              container: true,
              label: 'Resident Digital ID',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.lg),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.white,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(color: BrandColors.line2),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: width / _ratio),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: <Widget>[
                        const Positioned.fill(
                          child: ExcludeSemantics(
                            child: Opacity(
                              opacity: 0.55,
                              child: CustomPaint(painter: _GuillochePainter()),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -34,
                          bottom: -30,
                          width: 190,
                          height: 190,
                          child: ExcludeSemantics(
                            child: Opacity(
                              opacity: 0.09,
                              child: ColorFiltered(
                                colorFilter: _grayscale(1),
                                child: Image.asset(
                                  BrandAssets.municipalSeal.assetPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (card == null || face == null) ...<Widget>[
                              const _Band(),
                              Padding(
                                padding: const EdgeInsets.all(Spacing.lg),
                                child: Text(
                                  'Not yet issued',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.label.copyWith(
                                    fontWeight: AppTypography.black,
                                    letterSpacing: 1,
                                    color: BrandColors.muted,
                                  ),
                                ),
                              ),
                              const _Stripe(),
                            ] else ...<Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  const _Band(),
                                  _Middle(
                                    card: card,
                                    name: name,
                                    face: face,
                                    sample: sample,
                                    photoWidth: width * 0.27,
                                    loadPhoto: loadPhoto,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _Bottom(face: face),
                                  const _Stripe(),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            if (dimmed) {
              content = ColorFiltered(
                colorFilter: _grayscale(0.7),
                child: content,
              );
            }
            return content;
          },
        ),
      ),
    );
  }
}

/// CSS `grayscale(amount)` as a colour matrix.
ColorFilter _grayscale(double amount) {
  final double k = 1 - amount;
  return ColorFilter.matrix(<double>[
    0.2126 + 0.7874 * k,
    0.7152 - 0.7152 * k,
    0.0722 - 0.0722 * k,
    0,
    0,
    0.2126 - 0.2126 * k,
    0.7152 + 0.2848 * k,
    0.0722 - 0.0722 * k,
    0,
    0,
    0.2126 - 0.2126 * k,
    0.7152 - 0.7152 * k,
    0.0722 + 0.9278 * k,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);
}

/// `.idc .top`: the municipal band with its gold underline.
class _Band extends StatelessWidget {
  const _Band();

  @override
  Widget build(BuildContext context) {
    const BrandAsset seal = BrandAssets.municipalSeal;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            BrandColors.navy,
            BrandColors.blue,
            Color.lerp(BrandColors.blue, BrandColors.sky, 0.4) ??
                BrandColors.blue,
          ],
          stops: const <double>[0, 0.6, 1],
        ),
        border: const Border(
          bottom: BorderSide(color: BrandColors.gold, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: <Widget>[
            Semantics(
              label: seal.semanticLabel,
              image: true,
              child: Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: BrandColors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  seal.assetPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'LALAWIGAN NG RIZAL',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.category.copyWith(
                      fontWeight: AppTypography.strong,
                      letterSpacing: 1.2,
                      color: BrandColors.onHeaderMuted,
                    ),
                  ),
                  Text(
                    'MUNICIPALITY OF TAYTAY',
                    maxLines: 2,
                    style: AppTypography.category.copyWith(
                      color: BrandColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Resident\nDigital ID',
              textAlign: TextAlign.right,
              style: AppTypography.small.copyWith(
                fontWeight: AppTypography.black,
                height: 1.1,
                color: BrandColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.idc .mid`: the portrait and the four fields.
class _Middle extends StatelessWidget {
  const _Middle({
    required this.card,
    required this.name,
    required this.face,
    required this.sample,
    required this.photoWidth,
    this.loadPhoto,
  });

  final ResidentCredential card;
  final String? name;
  final DigitalIdFace face;
  final bool sample;
  final double photoWidth;
  final MediaBytesLoader? loadPhoto;

  @override
  Widget build(BuildContext context) {
    final String? resident = name;
    final String? number = card.idNumber;
    final DateTime? issued = card.issuedAt;
    final DateTime? expires = card.expiresAt;
    final bool expired = face == DigitalIdFace.expired;
    final String? media = card.photoMediaId;
    final MediaBytesLoader? load = loadPhoto;
    final Size photo = Size(photoWidth, photoWidth * 4 / 3);
    final Widget portrait = media == null || media.isEmpty || load == null
        ? _PhotoPlaceholder(size: photo)
        : MediaBytesHost(
            id: media,
            load: load,
            builder: (Uint8List? bytes) => bytes == null
                ? _PhotoPlaceholder(size: photo)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.tag),
                    child: SizedBox.fromSize(
                      size: photo,
                      child: DecodedMemoryImage(
                        bytes: bytes,
                        fit: BoxFit.cover,
                        semanticLabel: 'ID photo',
                        keepInImageCache: false,
                        placeholder: _PhotoPlaceholder(size: photo),
                      ),
                    ),
                  ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          portrait,
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (resident != null) ...<Widget>[
                  const _Key('NAME'),
                  Text(
                    resident,
                    key: DigitalIdView.nameKey,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: _nameStyle,
                  ),
                  const SizedBox(height: 6),
                ],
                const _Key('ID NUMBER'),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: <Widget>[
                    Text(
                      number ?? '',
                      style: AppTypography.listTitle.copyWith(
                        fontWeight: AppTypography.black,
                        letterSpacing: 0.54,
                        color: BrandColors.ink,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                    if (sample) const SampleTag(),
                  ],
                ),
                if (issued != null || expires != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (issued != null)
                        Expanded(
                          child: _Field(
                            label: 'ISSUED',
                            value: formatDigitalIdDate(issued),
                          ),
                        ),
                      if (issued != null && expires != null)
                        const SizedBox(width: 10),
                      if (expires != null)
                        Expanded(
                          child: _Field(
                            label: 'EXPIRES',
                            value: formatDigitalIdDate(expires),
                            color: expired ? BrandColors.redInk : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The name: 14 / 800 at line height 1.25, as printed. Never recased.
final TextStyle _nameStyle = AppTypography.fieldValue.copyWith(
  fontWeight: AppTypography.black,
  height: 1.25,
  color: BrandColors.ink,
);

class _Key extends StatelessWidget {
  const _Key(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      style: AppTypography.category.copyWith(
        letterSpacing: 1.2,
        color: color ?? BrandColors.muted,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Key(label, color: color),
        Text(
          value,
          style: AppTypography.small.copyWith(
            fontWeight: AppTypography.black,
            height: 1.25,
            color: color ?? BrandColors.ink,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Photo placeholder',
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[BrandColors.blue50, BrandColors.blue100],
          ),
          borderRadius: BorderRadius.circular(Radii.tag),
          border: Border.all(color: BrandColors.line2),
        ),
        child: ExcludeSemantics(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 6),
              Text(
                'PHOTO',
                maxLines: 1,
                style: AppTypography.category.copyWith(
                  color: BrandColors.muted,
                ),
              ),
              Expanded(
                child: FittedBox(
                  child: TaytayIcon(
                    icon: TaytayIcons.userRound,
                    semanticLabel: '',
                    excludeSemantics: true,
                    size: size.width * 0.84,
                    color: BrandColors.muted.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.idc .bot`: decorative bars and the status pill.
class _Bottom extends StatelessWidget {
  const _Bottom({required this.face});

  final DigitalIdFace face;

  @override
  Widget build(BuildContext context) {
    final _TagStyle style = _TagStyle.of(face);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, Spacing.sm, 14, Spacing.sm),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: ExcludeSemantics(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.6,
                child: SizedBox(
                  height: 18,
                  child: Opacity(
                    opacity: 0.55,
                    child: CustomPaint(painter: _BarsPainter()),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: 'Status: ${style.label}',
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xxs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TaytayIcon(
                        icon: style.icon,
                        semanticLabel: '',
                        excludeSemantics: true,
                        size: 12,
                        color: style.foreground,
                      ),
                      const SizedBox(width: Spacing.xs),
                      Text(
                        style.label,
                        style: AppTypography.category.copyWith(
                          letterSpacing: 0,
                          color: style.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagStyle {
  const _TagStyle(this.label, this.background, this.foreground, this.icon);

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  static _TagStyle of(DigitalIdFace face) => switch (face) {
    DigitalIdFace.active => const _TagStyle(
      'Active',
      BrandColors.green50,
      BrandColors.green,
      TaytayIcons.circleCheck,
    ),
    DigitalIdFace.suspended => const _TagStyle(
      'Suspended',
      BrandColors.gold,
      BrandColors.navy,
      TaytayIcons.pause,
    ),
    DigitalIdFace.revoked => const _TagStyle(
      'Revoked',
      BrandColors.red,
      BrandColors.white,
      TaytayIcons.circleSlash,
    ),
    DigitalIdFace.expired => const _TagStyle(
      'Expired',
      BrandColors.line2,
      BrandColors.text,
      TaytayIcons.clock,
    ),
  };
}

/// `.idc .stripe`: blue, red and gold.
class _Stripe extends StatelessWidget {
  const _Stripe();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox(
        height: 6,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: 70, child: ColoredBox(color: BrandColors.blue)),
            Expanded(flex: 18, child: ColoredBox(color: BrandColors.red)),
            Expanded(flex: 12, child: ColoredBox(color: BrandColors.gold)),
          ],
        ),
      ),
    );
  }
}

/// `.idc .guil`: fine rings and diagonal hatching, the card's security print.
class _GuillochePainter extends CustomPainter {
  const _GuillochePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = BrandColors.sky.withValues(alpha: 0.10);
    final Offset centre = Offset(size.width * 0.78, size.height * 0.62);
    final double reach = size.longestSide * 1.2;
    for (double r = 7.5; r < reach; r += 8) {
      canvas.drawCircle(centre, r, ring);
    }
    final Paint hatch = Paint()
      ..strokeWidth = 1
      ..color = BrandColors.gold.withValues(alpha: 0.10);
    // 115deg hatching: lines rising to the right, 15 px apart.
    final double slope = math.tan(25 * math.pi / 180);
    for (double x = -size.height; x < size.width + size.height; x += 15) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * slope, 0),
        hatch,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuillochePainter oldDelegate) => false;
}

/// `.idc .bars`: a printed-barcode texture. It encodes nothing.
class _BarsPainter extends CustomPainter {
  const _BarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bar = Paint()..color = BrandColors.text;
    const List<(double, double)> unit = <(double, double)>[
      (0, 2),
      (4, 1),
      (8, 3),
    ];
    for (double x = 0; x < size.width; x += 13) {
      for (final (double, double) b in unit) {
        final double left = x + b.$1;
        if (left >= size.width) break;
        canvas.drawRect(
          Rect.fromLTWH(
            left,
            0,
            math.min(b.$2, size.width - left),
            size.height,
          ),
          bar,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) => false;
}

/// The active card's code, in a glass card.
class _QrCard extends StatelessWidget {
  const _QrCard({required this.qr, required this.now});

  final PresentationArtifact qr;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final bool live = qr.isLive(now);
    final DateTime? expiry = qr.expiresAt;
    final String refresh = expiry == null
        ? 'Code refreshes'
        : 'Code refreshes · valid until ${formatDigitalIdClock(expiry)}';
    return GlassCard(
      child: Column(
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'Show this code to be scanned',
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                fontWeight: AppTypography.strong,
                color: BrandColors.ink,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          if (live) _QrFrame(token: qr.payload) else const _RefreshingCode(),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.refreshCw,
                semanticLabel: '',
                excludeSemantics: true,
                size: 14,
                color: BrandColors.text,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  refresh,
                  textAlign: TextAlign.center,
                  style: AppTypography.listDetail.copyWith(
                    fontWeight: AppTypography.medium,
                    color: BrandColors.text,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const double _qrSide = 200;

/// Paints the token as modules. The field is omitted from diagnostics.
class _QrFrame extends StatelessWidget {
  const _QrFrame({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: DigitalIdView.qrKey,
      container: true,
      label: 'QR code',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.lg),
        child: ColoredBox(
          color: BrandColors.white,
          child: CustomPaint(
            size: const Size(_qrSide, _qrSide),
            painter: _QrPainter(token, View.of(context).devicePixelRatio),
          ),
        ),
      ),
    );
  }
}

/// Shown in the code's box once `expires_at` has passed, including when the
/// refetch is also past its expiry. The modules are not painted.
class _RefreshingCode extends StatelessWidget {
  const _RefreshingCode();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _qrSide, minHeight: _qrSide),
      child: Center(
        child: Text(
          'Refreshing code…',
          textAlign: TextAlign.center,
          style: AppTypography.fieldValue.copyWith(
            fontWeight: AppTypography.strong,
            color: BrandColors.text,
          ),
        ),
      ),
    );
  }
}

/// Suspended, revoked or expired: what happened and what to do.
class _Notice extends StatelessWidget {
  const _Notice({required this.face});

  final DigitalIdFace face;

  @override
  Widget build(BuildContext context) {
    final _NoticeCopy copy = _NoticeCopy.of(face);
    return Semantics(
      container: true,
      liveRegion: true,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: copy.tile,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: TaytayIcon(
                    icon: copy.icon,
                    semanticLabel: copy.title,
                    size: 20,
                    color: copy.ink,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        copy.title,
                        style: AppTypography.fieldValue.copyWith(
                          fontWeight: AppTypography.strong,
                          color: BrandColors.ink,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        copy.body,
                        style: AppTypography.bodyStyle.copyWith(
                          color: BrandColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'No code is shown while the card is not active.',
              style: AppTypography.listDetail.copyWith(
                color: BrandColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCopy {
  const _NoticeCopy(this.title, this.body, this.tile, this.ink, this.icon);

  final String title;
  final String body;
  final Color tile;
  final Color ink;
  final IconData icon;

  static _NoticeCopy of(DigitalIdFace face) => switch (face) {
    DigitalIdFace.suspended => const _NoticeCopy(
      'Your ID is suspended',
      'Taytay LGU has paused this card. Visit the Municipal Hall or '
          'message the LGU to find out why.',
      BrandColors.gold50,
      BrandColors.goldInk,
      TaytayIcons.shieldAlert,
    ),
    DigitalIdFace.revoked => const _NoticeCopy(
      'This ID is no longer valid',
      'Taytay LGU has revoked this card. Visit the Municipal Hall if you '
          'need a new one.',
      BrandColors.red50,
      BrandColors.redInk,
      TaytayIcons.circleSlash,
    ),
    DigitalIdFace.expired => const _NoticeCopy(
      'Your ID has expired',
      'This card passed its expiry date. Visit the Municipal Hall to renew it.',
      BrandColors.blue50,
      BrandColors.muted,
      TaytayIcons.clock,
    ),
    DigitalIdFace.active => const _NoticeCopy(
      '',
      '',
      BrandColors.background,
      BrandColors.ink,
      TaytayIcons.circleCheck,
    ),
  };
}

/// `.ghost`: where the card will be, drawn as a dashed outline of the same
/// ID-1 proportions with the state in words.
class _PreparingCard extends StatelessWidget {
  const _PreparingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _IdCard._maxWidth),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Semantics(
              container: true,
              child: CustomPaint(
                foregroundPainter: const DashedOutline(
                  colour: BrandColors.cardPendingOutline,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandColors.white,
                    borderRadius: BorderRadius.circular(Radii.lg),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxWidth / _IdCard._ratio,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const IconTile.lucide(
                              icon: TaytayIcons.idCard,
                              tileSize: IconTileSize.large,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Semantics(
                              header: true,
                              child: Text(
                                CardPreparingCopy.title,
                                textAlign: TextAlign.center,
                                style: _cardHeading,
                              ),
                            ),
                            const SizedBox(height: Spacing.xs),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                CardPreparingCopy.body,
                                textAlign: TextAlign.center,
                                style: _note,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "Where your card is": the five steps. The first three are dated only by
/// what the server sent; an undated step is still drawn, without a date.
class _PreparingSteps extends StatelessWidget {
  const _PreparingSteps({required this.preparation});

  final CardPreparation preparation;

  static String _date(DateTime? instant) =>
      instant == null ? '' : ManilaTime.formatDate(instant);

  @override
  Widget build(BuildContext context) {
    final String idType = idTypeLabel(preparation.idType);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(CardPreparingCopy.stepsTitle, style: _cardHeading),
          ),
          const SizedBox(height: Spacing.xs),
          Timeline(
            steps: <TimelineStep>[
              TimelineStep(
                icon: TaytayIcons.check,
                title: CardPreparingCopy.accountCreated,
                detail: _date(preparation.accountCreatedAt),
                tone: TimelineTone.done,
              ),
              TimelineStep(
                icon: TaytayIcons.check,
                title: CardPreparingCopy.idSent,
                detail: CardPreparingCopy.detail(<String>[
                  _date(preparation.sentAt),
                  idType,
                ]),
                tone: TimelineTone.done,
              ),
              TimelineStep(
                icon: TaytayIcons.check,
                title: CardPreparingCopy.verified,
                detail: _date(preparation.verifiedAt),
                tone: TimelineTone.done,
              ),
              const TimelineStep(
                icon: TaytayIcons.clock,
                title: CardPreparingCopy.issued,
                detail: CardPreparingCopy.issuedDetail,
                tone: TimelineTone.current,
              ),
              const TimelineStep(
                icon: TaytayIcons.idCard,
                title: CardPreparingCopy.show,
                detail: CardPreparingCopy.showDetail,
                tone: TimelineTone.upcoming,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "About your card", with the way to ask the MSWDO.
class _AboutCard extends StatelessWidget {
  const _AboutCard({this.onMessageOffice});

  final VoidCallback? onMessageOffice;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onMessageOffice = this.onMessageOffice;
    final TextStyle fact = AppTypography.listDetail.copyWith(
      color: BrandColors.text,
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(CardPreparingCopy.aboutTitle, style: _cardHeading),
          ),
          const SizedBox(height: Spacing.md),
          Text(CardPreparingCopy.aboutWhat, style: fact),
          const SizedBox(height: Spacing.sm),
          Text(CardPreparingCopy.aboutStops, style: fact),
          if (onMessageOffice != null) ...<Widget>[
            const SizedBox(height: Spacing.md),
            SecondaryButton(
              label: CardPreparingCopy.message,
              onPressed: onMessageOffice,
              icon: const TaytayIcon(
                icon: TaytayIcons.messageCircle,
                semanticLabel: '',
                excludeSemantics: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final TextStyle _cardHeading = AppTypography.sectionTitle.copyWith(
  fontWeight: AppTypography.strong,
  color: BrandColors.ink,
);

/// Dev mock only: says the number and dates are illustrations.
class _SampleFooter extends StatelessWidget {
  const _SampleFooter();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.xs,
      children: <Widget>[
        const SampleTag(),
        Text('number and dates for illustration', style: _note),
      ],
    );
  }
}

/// Renders a token as modules. `toString` stays redacted.
class _QrPainter extends CustomPainter {
  const _QrPainter(this._token, this._devicePixelRatio);

  final String _token;
  final double _devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final QrImage? matrix = _matrix(_token);
    if (matrix == null) return;
    final int count = matrix.moduleCount;
    final double dpr = _devicePixelRatio <= 0 ? 1 : _devicePixelRatio;
    final double cell = size.shortestSide / (count + 8);
    final double origin = (size.shortestSide - cell * count) / 2;
    final Path path = Path();
    final double min = 1 / dpr;
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (!matrix.isDark(row, col)) continue;
        final double left = _snap(origin + col * cell, dpr);
        final double top = _snap(origin + row * cell, dpr);
        var right = _snap(origin + (col + 1) * cell, dpr);
        var bottom = _snap(origin + (row + 1) * cell, dpr);
        if (right <= left) right = left + min;
        if (bottom <= top) bottom = top + min;
        path.addRect(Rect.fromLTRB(left, top, right, bottom));
      }
    }
    canvas.drawPath(path, Paint()..color = BrandColors.textPrimary);
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate._token != _token ||
      oldDelegate._devicePixelRatio != _devicePixelRatio;

  @override
  String toString() => 'QrPainter';
}

double _snap(double logical, double devicePixelRatio) =>
    (logical * devicePixelRatio).round() / devicePixelRatio;

QrImage? _matrix(String token) {
  try {
    return QrImage(
      QrCode(
        payload: QrPayload.fromString(token),
        errorCorrectLevel: QrErrorCorrectLevel.medium,
      ),
    );
  } on InputTooLongException {
    return null;
  }
}
