import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/design/brand_assets.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/design/taytay_icons.dart';
import '../../../core/design/typography.dart';
import '../../../core/result/app_failure.dart';
import '../../../shared/widgets/failure_view.dart';
import '../../../shared/widgets/media_bytes_image.dart';
import '../../../shared/widgets/municipal_header.dart';
import '../../../shared/widgets/taytay_icon.dart';
import '../../../shared/widgets/taytay_rows.dart';
import '../domain/credential_repository.dart';
import '../domain/digital_id_face.dart';

/// The issued card, the four non-active explanations, and the not-issued card.
///
/// The shell paints the tab bar. A golden composes this view with that bar.
/// The QR token is painted and then dropped: it is not a label, a key, or a
/// diagnostic field.
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

  @override
  Widget build(BuildContext context) {
    final String? published = publishedResidentName(name);
    final DigitalIdFace? face = digitalIdFace(card, now);
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: BrandColors.textPrimary,
        decoration: TextDecoration.none,
      ),
      child: ColoredBox(
        color: BrandColors.surface,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double height = constraints.maxHeight;
            final double stop = height <= 0
                ? 1
                : (260 / height).clamp(0.0, 1.0);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const <Color>[
                    BrandColors.surfaceMuted,
                    BrandColors.surface,
                  ],
                  stops: <double>[0, stop],
                ),
              ),
              child: Column(
                children: <Widget>[
                  const MunicipalHeader(
                    title: 'My Taytay ID',
                    subtitle: 'Bayan ng Taytay · Rizal',
                    plainSeal: true,
                  ),
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: _Body(
                            card: card,
                            name: published,
                            face: face,
                            sample: sample,
                            failure: failure,
                            environment: environment,
                            onRetry: onRetry,
                            now: now,
                            loadPhoto: loadPhoto,
                          ),
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 28,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Color(0x00F3F5FA),
                                    BrandColors.surface,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.card,
    required this.name,
    required this.face,
    required this.sample,
    required this.failure,
    required this.environment,
    required this.onRetry,
    required this.now,
    this.loadPhoto,
  });

  final ResidentCredential? card;
  final String? name;
  final DigitalIdFace? face;
  final bool sample;
  final AppFailure? failure;
  final AppEnvironment environment;
  final VoidCallback? onRetry;
  final DateTime now;
  final MediaBytesLoader? loadPhoto;

  @override
  Widget build(BuildContext context) {
    final AppFailure? failure = this.failure;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        if (failure != null)
          FailureView(
            failure: failure,
            environment: environment,
            onRetry: onRetry,
          )
        else if (card == null || face == null)
          const _NotIssued()
        else
          _Issued(
            card: card!,
            name: name,
            face: face!,
            sample: sample,
            now: now,
            loadPhoto: loadPhoto,
          ),
      ],
    );
  }
}

class _NotIssued extends StatelessWidget {
  const _NotIssued();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        _CardShell(
          dimmed: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SealRow(),
              SizedBox(height: 40),
              _Ink(
                'Not yet issued',
                size: 13,
                weight: FontWeight.w700,
                color: Color(0xCCFFFFFF),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: _Ink(
            'Your digital ID will appear here once Taytay LGU issues it.',
            size: 13,
            weight: FontWeight.w500,
            color: BrandColors.textSecondary,
            height: 1.5,
            align: TextAlign.center,
            maxLines: 4,
          ),
        ),
      ],
    );
  }
}

class _Issued extends StatelessWidget {
  const _Issued({
    required this.card,
    required this.name,
    required this.face,
    required this.sample,
    required this.now,
    this.loadPhoto,
  });

  final ResidentCredential card;
  final String? name;
  final DigitalIdFace face;
  final bool sample;
  final DateTime now;
  final MediaBytesLoader? loadPhoto;

  @override
  Widget build(BuildContext context) {
    final bool dimmed = face != DigitalIdFace.active;
    final PresentationArtifact? qr = face == DigitalIdFace.active
        ? card.qr
        : null;
    final String? resident = name;
    return Column(
      children: <Widget>[
        _CardShell(
          dimmed: dimmed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SealRow(),
              if (resident != null) ...<Widget>[
                const SizedBox(height: 14),
                _MiddleLine(
                  text: 'NAME ',
                  style: _label,
                  // `.kv` is `opacity: .75`, and the SAMPLE chip sits inside it.
                  chip: sample ? const _SampleChip(opacity: 0.75) : null,
                ),
                const SizedBox(height: 2),
                _ResidentName(name: resident),
              ],
              SizedBox(height: resident == null ? 16 : 12),
              _PhotoRow(
                card: card,
                face: face,
                sample: sample,
                loadPhoto: loadPhoto,
              ),
            ],
          ),
        ),
        if (qr != null) ...<Widget>[
          const SizedBox(height: 14),
          _QrCard(qr: qr, now: now),
          // `.card` margin-bottom 12 and `.cs` margin-top 12 collapse.
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: _FractionalLines(
              text:
                  'Taytay LGU issued this card. A scanner checks the code. '
                  'This phone does not decide that the card is genuine.',
              size: 13,
              weight: FontWeight.w500,
              color: BrandColors.textSecondary,
              step: _bodyLine,
              align: TextAlign.center,
            ),
          ),
        ],
        if (dimmed) ...<Widget>[
          const SizedBox(height: 14),
          _Notice(face: face),
        ],
        if (sample) ...<Widget>[
          // Active: the disclaimer margin-bottom is 0, so the footer
          // margin-top of 10 stands. Dimmed: the sheet margin-bottom of
          // 12 collapses with that 10.
          SizedBox(height: dimmed ? 12 : 10),
          const _SampleFooter(),
        ],
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.dimmed, required this.child});

  final bool dimmed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // CSS 160deg: 0° is up and the angle grows clockwise, so the last stop
    // sits down and to the right.
    const Alignment end = Alignment(0.3420201433, 0.9396926208);
    const Alignment begin = Alignment(-0.3420201433, -0.9396926208);
    final List<Color> colors = dimmed
        ? const <Color>[
            BrandColors.cardDimStart,
            BrandColors.cardDimMid,
            BrandColors.cardDimEnd,
          ]
        : const <Color>[
            BrandColors.taytayBlueLight,
            BrandColors.taytayBlue,
            BrandColors.taytayBlueDark,
          ];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: TaytayShadows.digitalId,
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: const <double>[0, 0.45, 1],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            // The design SVG viewport is 120×214. The paths are authored
            // out to y 220, and the viewport clips them.
            const Positioned(
              right: -6,
              top: 0,
              width: 120,
              height: 214,
              child: ClipRect(
                child: CustomPaint(
                  painter: _StitchPainter(),
                  size: Size(120, 214),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }
}

class _SealRow extends StatelessWidget {
  const _SealRow();

  @override
  Widget build(BuildContext context) {
    const BrandAsset seal = BrandAssets.municipalSeal;
    return const Row(
      children: <Widget>[
        _Seal(seal: seal),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Ink(
                'MUNICIPALITY OF TAYTAY',
                size: 11,
                weight: FontWeight.w800,
                color: Color(0xCCFFFFFF),
                letterSpacing: 1.2,
              ),
              SizedBox(height: 1),
              _Ink(
                'Resident Digital ID',
                size: 16,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Seal extends StatelessWidget {
  const _Seal({required this.seal});

  final BrandAsset seal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: seal.semanticLabel,
      image: true,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          seal.assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: seal.semanticLabel,
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.card,
    required this.face,
    required this.sample,
    this.loadPhoto,
  });

  final ResidentCredential card;
  final DigitalIdFace face;
  final bool sample;
  final MediaBytesLoader? loadPhoto;

  @override
  Widget build(BuildContext context) {
    final String? number = card.idNumber;
    final DateTime? issued = card.issuedAt;
    final DateTime? expires = card.expiresAt;
    final String? media = card.photoMediaId;
    final Widget portrait = media == null || media.isEmpty || loadPhoto == null
        ? const _PhotoPlaceholder()
        : MediaBytesHost(
            id: media,
            load: loadPhoto,
            builder: (Uint8List? bytes) {
              if (bytes == null) return const _PhotoPlaceholder();
              return _PhotoBytes(bytes: bytes);
            },
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        portrait,
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Ink(
                'ID NUMBER',
                size: 11,
                weight: FontWeight.w700,
                color: _labelColor,
                letterSpacing: 0.4,
                slot: TypeMetrics.line(11),
              ),
              const SizedBox(height: 1),
              _MiddleLine(
                text: number == null ? '' : '$number ',
                style: _value,
                chip: sample ? const _SampleChip() : null,
              ),
              const SizedBox(height: 8),
              _Ink(
                'STATUS',
                size: 11,
                weight: FontWeight.w700,
                color: _labelColor,
                letterSpacing: 0.4,
                slot: TypeMetrics.line(11),
              ),
              const SizedBox(height: 3),
              _StatusTag(face: face),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  if (issued != null)
                    Flexible(
                      child: _DateColumn(
                        label: 'ISSUED',
                        value: formatDigitalIdDate(issued),
                      ),
                    ),
                  if (issued != null && expires != null)
                    const SizedBox(width: 16),
                  if (expires != null)
                    Flexible(
                      child: _DateColumn(
                        label: 'EXPIRES',
                        value: formatDigitalIdDate(expires),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Ink(
          label,
          size: 11,
          weight: FontWeight.w700,
          color: _labelColor,
          letterSpacing: 0.4,
          slot: TypeMetrics.line(11),
        ),
        const SizedBox(height: 1),
        _Ink(
          value,
          size: 13,
          weight: FontWeight.w800,
          color: Colors.white,
          features: const <FontFeature>[FontFeature.tabularFigures()],
          slot: TypeMetrics.line(13),
          // 13 px normal is a 16.33 line. The rounded strut sits the
          // glyphs above Chrome's baseline, which is 13.33 into that line.
          pinBaseline: true,
        ),
      ],
    );
  }
}

class _PhotoBytes extends StatelessWidget {
  const _PhotoBytes({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 84,
        height: 104,
        child: DecodedMemoryImage(
          bytes: bytes,
          fit: BoxFit.cover,
          semanticLabel: 'ID photo',
          placeholder: const _PhotoPlaceholder(),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Photo placeholder',
      child: CustomPaint(
        foregroundPainter: const _DashedRRectPainter(
          color: Color(0x99FFFFFF),
          radius: 12,
          strokeWidth: 1.5,
        ),
        child: Container(
          width: 84,
          height: 104,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TaytayIcon(
                  icon: TaytayIcons.userRound,
                  semanticLabel: '',
                  excludeSemantics: true,
                  size: 26,
                  color: Colors.white,
                ),
                SizedBox(height: 6),
                _PhotoCaption(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.face});

  final DigitalIdFace face;

  @override
  Widget build(BuildContext context) {
    final _TagStyle style = _TagStyle.of(face);
    // The chip is inline-flex in a block that inherits the body's 16 px
    // normal line. Its baseline is the bottom of the 12 px icon, a replaced
    // flex item centered on the 11 px label. The chip therefore starts below
    // the strut and the line grows to 20.5 instead of the chip's own 19.67.
    const double icon = 12;
    const double pad = 3;
    final double label = TypeMetrics.line(11);
    final double chip = label + pad * 2;
    final double baseline = pad + (label - icon) / 2 + icon;
    final double top = TypeMetrics.ascender(16) - baseline;
    final double line = math.max(TypeMetrics.line(16), top + chip);
    return SizedBox(
      height: line,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: Semantics(
            label: style.label,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                child: ExcludeSemantics(
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
                      const SizedBox(width: 4),
                      _Ink(
                        style.label,
                        size: 11,
                        weight: FontWeight.w800,
                        color: style.foreground,
                        slot: TypeMetrics.line(11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
      BrandColors.chipGreenBg,
      BrandColors.success,
      TaytayIcons.circleCheck,
    ),
    DigitalIdFace.suspended => const _TagStyle(
      'Suspended',
      BrandColors.chipAmberBg,
      BrandColors.warning,
      TaytayIcons.pause,
    ),
    DigitalIdFace.revoked => const _TagStyle(
      'Revoked',
      BrandColors.chipRedBg,
      BrandColors.danger,
      TaytayIcons.circleSlash,
    ),
    DigitalIdFace.expired => const _TagStyle(
      'Expired',
      BrandColors.chipGreyBg,
      BrandColors.textSecondary,
      TaytayIcons.clock,
    ),
  };
}

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
    // Container keeps the 1 dp border outside the 16 dp padding. A bare
    // DecoratedBox paints that stroke over the padding and the sheet is
    // 2 dp short of the CSS border box.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.cardLine),
        boxShadow: TaytayShadows.card,
      ),
      child: Column(
        children: <Widget>[
          _FractionalLines(
            text: 'Show this code to be scanned',
            size: 14,
            weight: FontWeight.w800,
            color: BrandColors.textPrimary,
            step: TypeMetrics.line(14),
            align: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (live) _QrFrame(token: qr.payload) else const _RefreshingCode(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const TaytayIcon(
                icon: TaytayIcons.refreshCw,
                semanticLabel: '',
                excludeSemantics: true,
                size: 14,
                color: BrandColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: _Ink(
                  refresh,
                  size: 12,
                  weight: FontWeight.w700,
                  color: BrandColors.textSecondary,
                  align: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the token as modules. The field is omitted from diagnostics.
class _QrFrame extends StatelessWidget {
  const _QrFrame({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: DigitalIdView.qrKey,
      label: 'QR code',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: Colors.white,
          child: CustomPaint(
            size: const Size(208, 208),
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
    return const SizedBox(
      width: 208,
      height: 208,
      child: Center(
        child: Text(
          'Refreshing code…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.25,
            leadingDistribution: TextLeadingDistribution.even,
            color: BrandColors.textSecondary,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.face});

  final DigitalIdFace face;

  @override
  Widget build(BuildContext context) {
    final _NoticeCopy copy = _NoticeCopy.of(face);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.cardLine),
        boxShadow: TaytayShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: copy.tile,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TaytayIcon(
                  icon: copy.icon,
                  semanticLabel: copy.title,
                  size: 20,
                  color: copy.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _FractionalLines(
                      text: copy.title,
                      size: 14,
                      weight: FontWeight.w800,
                      color: BrandColors.textPrimary,
                      step: TypeMetrics.line(14),
                    ),
                    const SizedBox(height: 4),
                    _FractionalLines(
                      text: copy.body,
                      size: 13,
                      weight: FontWeight.w500,
                      color: BrandColors.textSecondary,
                      step: _bodyLine,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _Ink(
            'No code is shown while the card is not active.',
            size: 12,
            weight: FontWeight.w500,
            color: BrandColors.listMeta,
            maxLines: 2,
          ),
        ],
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
      BrandColors.chipAmberBg,
      BrandColors.warning,
      TaytayIcons.shieldAlert,
    ),
    DigitalIdFace.revoked => const _NoticeCopy(
      'This ID is no longer valid',
      'Taytay LGU has revoked this card. Visit the Municipal Hall if you '
          'need a new one.',
      BrandColors.chipRedBg,
      BrandColors.danger,
      TaytayIcons.circleSlash,
    ),
    DigitalIdFace.expired => const _NoticeCopy(
      'Your ID has expired',
      'This card passed its expiry date. Visit the Municipal Hall to renew it.',
      BrandColors.chipGreyBg,
      BrandColors.textSecondary,
      TaytayIcons.clock,
    ),
    DigitalIdFace.active => const _NoticeCopy(
      '',
      '',
      BrandColors.surface,
      BrandColors.textPrimary,
      TaytayIcons.circleCheck,
    ),
  };
}

class _SampleFooter extends StatelessWidget {
  const _SampleFooter();

  @override
  Widget build(BuildContext context) {
    // The line's strut is the body's 16 px `normal` box. The chip is
    // `vertical-align: middle` on that strut, and the 12 px label sits on
    // the same baseline. Centering the two on each other lifts the label.
    final double strut = TypeMetrics.line(16);
    final double chipHeight = TypeMetrics.line(11) + 6;
    final double chipTop = _middleTop(
      fontSize: 16,
      weight: FontWeight.w400,
      boxHeight: chipHeight,
    );
    final double textLine = TypeMetrics.line(12);
    final double textTop = TypeMetrics.ascender(16) - TypeMetrics.ascender(12);
    final double shift = math.max(0, math.max(-chipTop, -textTop));
    final double height =
        math.max(strut, math.max(chipTop + chipHeight, textTop + textLine)) +
        shift;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double chipWidth = _sampleChipWidth();
          final double textWidth = _spanWidth(
            _sampleCaption,
            _sampleCaptionStyle,
          );
          const double gap = 4;
          final double total = chipWidth + gap + textWidth;
          final double left = math.max(0, (constraints.maxWidth - total) / 2);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: left,
                top: shift + chipTop,
                width: chipWidth,
                height: chipHeight,
                child: const _SampleChip(),
              ),
              Positioned(
                left: left + chipWidth + gap,
                top: shift + textTop,
                width: textWidth,
                height: textLine,
                child: const Text(
                  _sampleCaption,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: _sampleCaptionStyle,
                  strutStyle: _sampleCaptionStrut,
                  textHeightBehavior: _evenLeading,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const String _sampleCaption = 'number and dates for illustration';

const TextStyle _sampleCaptionStyle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 15 / 12,
  leadingDistribution: TextLeadingDistribution.even,
  color: BrandColors.listMeta,
  decoration: TextDecoration.none,
);

const StrutStyle _sampleCaptionStrut = StrutStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w500,
  height: 15 / 12,
  leadingDistribution: TextLeadingDistribution.even,
  forceStrutHeight: true,
);

class _SampleChip extends StatelessWidget {
  const _SampleChip({this.opacity = 1});

  /// `.kv` sets `opacity: .75` on the NAME line. The ID number chip sits in
  /// `.vv`, which does not, so only the NAME chip passes this.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final Widget tag = SampleTag(
      lineHeight: TypeMetrics.line(11) / 11,
      lineSlot: TypeMetrics.line(11),
    );
    if (opacity == 1) return tag;
    return Opacity(opacity: opacity, child: tag);
  }
}

/// CSS `vertical-align: middle` for a SAMPLE chip on a label line.
///
/// The parent's line stays at the top. The line grows downward when the chip
/// hangs below that strut. The centre is the alphabetic baseline plus half
/// the x-height. On a 14 px line that baseline is 14.33, and the ID-number
/// row is 20.34 rather than the 20.68 a 14.67 ascender would make.
class _MiddleLine extends StatelessWidget {
  const _MiddleLine({required this.text, required this.style, this.chip});

  final String text;
  final TextStyle style;
  final Widget? chip;

  @override
  Widget build(BuildContext context) {
    final double fontSize = style.fontSize ?? 11;
    final FontWeight weight = style.fontWeight ?? FontWeight.w400;
    final double strut = TypeMetrics.line(fontSize);
    final Widget? chip = this.chip;
    final double chipHeight = chip == null ? 0 : TypeMetrics.line(11) + 6;
    final double chipTop = chip == null
        ? 0
        : _middleTop(fontSize: fontSize, weight: weight, boxHeight: chipHeight);
    final double shift = math.max(0.0, -chipTop);
    final double height = math.max(strut, chipTop + chipHeight) + shift;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double leadWidth = text.isEmpty ? 0 : _spanWidth(text, style);
          final double chipWidth = chip == null ? 0 : _sampleChipWidth();
          var x = 0.0;
          final List<Widget> children = <Widget>[];
          if (text.isNotEmpty) {
            children.add(
              Positioned(
                left: x,
                top: shift,
                width: leadWidth,
                height: strut,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: style,
                  textHeightBehavior: _evenLeading,
                ),
              ),
            );
            x += leadWidth;
          }
          if (chip != null) {
            children.add(
              Positioned(
                left: x,
                top: shift + chipTop,
                width: chipWidth,
                height: chipHeight,
                child: chip,
              ),
            );
          }
          return Stack(clipBehavior: Clip.none, children: children);
        },
      ),
    );
  }
}

double _middleTop({
  required double fontSize,
  required FontWeight weight,
  required double boxHeight,
}) {
  final int units = switch (weight) {
    FontWeight.w500 => 539,
    FontWeight.w600 => 541,
    FontWeight.w700 => 544,
    FontWeight.w800 || FontWeight.w900 => 546,
    _ => 536,
  };
  final double centre =
      TypeMetrics.baseline(fontSize) - (fontSize * units / 1000) / 2;
  return centre - boxHeight / 2;
}

double _spanWidth(String text, TextStyle style) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
    textHeightBehavior: _evenLeading,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}

double _sampleChipWidth() {
  return _spanWidth(
        'SAMPLE',
        AppTypography.labelStrong.copyWith(letterSpacing: 0.6),
      ) +
      16;
}

const TextHeightBehavior _evenLeading = TextHeightBehavior(
  applyHeightToFirstAscent: true,
  applyHeightToLastDescent: true,
  leadingDistribution: TextLeadingDistribution.even,
);

const Color _labelColor = Color(0xBFFFFFFF);

const TextStyle _label = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 13.6666667 / 11,
  letterSpacing: 0.4,
  leadingDistribution: TextLeadingDistribution.even,
  color: _labelColor,
  decoration: TextDecoration.none,
);

const TextStyle _value = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w800,
  height: 17.6666667 / 14,
  leadingDistribution: TextLeadingDistribution.even,
  color: Colors.white,
  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  decoration: TextDecoration.none,
);

/// Glyphs are 17 / 800, line-height 1.25, as specified.
///
/// The screenshotted HTML had already been polished from 17 to 18, so the
/// design's line box is 22.5. The strut keeps that box. The following rows
/// stay on the specimen while the letters stay 17.
const TextStyle _nameStyle = TextStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 17,
  fontWeight: FontWeight.w800,
  height: 1.25,
  leadingDistribution: TextLeadingDistribution.even,
  color: Colors.white,
  decoration: TextDecoration.none,
);

const StrutStyle _nameStrut = StrutStyle(
  fontFamily: AppTypography.fontFamily,
  fontSize: 18,
  height: 1.25,
  leadingDistribution: TextLeadingDistribution.even,
  forceStrutHeight: true,
);

/// `.nmv` in the screenshotted HTML is 18 × 1.25, so each line box is 22.5.
///
/// The glyphs stay 17. SkParagraph rounds the strut to a whole logical
/// pixel (22 with Plus Jakarta loaded), which shortens the block and pulls
/// the photo row up. The slot keeps the CSS advance.
class _ResidentName extends StatelessWidget {
  const _ResidentName({required this.name});

  final String name;

  static const double _step = 22.5;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 300;
            final int lines = _nameLines(name, maxWidth, context);
            return SizedBox(
              height: _step * lines,
              width: maxWidth,
              child: Text(
                name,
                key: DigitalIdView.nameKey,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: _nameStyle,
                strutStyle: _nameStrut,
                textHeightBehavior: _evenLeading,
              ),
            );
          },
        ),
      ),
    );
  }
}

int _nameLines(String text, double maxWidth, BuildContext context) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: _nameStyle),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    textHeightBehavior: _evenLeading,
    strutStyle: _nameStrut,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  var lines = 0;
  var start = 0;
  while (start < text.length && lines < 2) {
    final TextRange range = painter.getLineBoundary(
      TextPosition(offset: start),
    );
    if (range.end <= start) break;
    lines += 1;
    start = range.end;
  }
  painter.dispose();
  return lines == 0 ? 1 : lines;
}

/// `.ph1` caption: 11 / 700, line-height 1.25, two lines, centered under the
/// icon with a 6 px gap. The step stays 13.75 so the second line is not the
/// rounded 14 px strut.
class _PhotoCaption extends StatelessWidget {
  const _PhotoCaption();

  static const double _step = 11 * 1.25;

  static const TextStyle _style = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.25,
    leadingDistribution: TextLeadingDistribution.even,
    color: Colors.white,
    decoration: TextDecoration.none,
  );

  static const StrutStyle _strut = StrutStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.25,
    leadingDistribution: TextLeadingDistribution.even,
    forceStrutHeight: true,
  );

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _step * 2,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text(
              'Photo',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: _style,
              strutStyle: _strut,
              textHeightBehavior: _evenLeading,
            ),
          ),
          Positioned(
            top: _step,
            left: 0,
            right: 0,
            child: Text(
              'placeholder',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: _style,
              strutStyle: _strut,
              textHeightBehavior: _evenLeading,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.cs` is 13 px at `line-height: 1.5`. Chrome's line boxes are exactly
/// 19.5 apart, and a 3-line block is 58.5.
const double _bodyLine = 13 * 1.5;

/// Lines stacked on a CSS `line-height`, not on the rounded strut.
///
/// SkParagraph rounds a fractional strut to a whole logical pixel. A 14 px
/// normal line becomes 18 instead of 17.67, and 13 × 1.5 becomes 20 instead
/// of 19.5. Each line is placed `step` apart, so the paragraph is `n` times
/// the CSS advance. A normal line then pins its glyphs to Chrome's alphabetic
/// baseline inside that box. An explicit line-height, such as 13 × 1.5, keeps
/// the strut: those lines are already 19.5 apart.
class _FractionalLines extends StatelessWidget {
  const _FractionalLines({
    required this.text,
    required this.size,
    required this.weight,
    required this.color,
    required this.step,
    this.align = TextAlign.start,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double step;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final bool normal = (step - TypeMetrics.line(size)).abs() < 0.001;
    // A normal line is an em box pinned to the baseline. The explicit
    // line-height keeps its own strut, which is what spaces 13 × 1.5.
    final double fontHeight = normal ? 1 : step / size;
    final TextStyle style = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: fontHeight,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
      decoration: TextDecoration.none,
    );
    final StrutStyle strut = StrutStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: fontHeight,
      leadingDistribution: TextLeadingDistribution.even,
      forceStrutHeight: true,
    );
    final double topInset = normal
        ? TypeMetrics.baseline(size) - _emBaseline(size, weight)
        : 0;
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final TextPainter painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textAlign: align,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              textHeightBehavior: _evenLeading,
              strutStyle: strut,
            )..layout(maxWidth: constraints.maxWidth);
            final List<String> lines = <String>[];
            var start = 0;
            while (start < text.length) {
              final TextRange range = painter.getLineBoundary(
                TextPosition(offset: start),
              );
              if (range.end <= start) break;
              lines.add(text.substring(range.start, range.end).trimRight());
              start = range.end;
            }
            painter.dispose();
            if (lines.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              width: constraints.maxWidth,
              height: step * lines.length,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (var i = 0; i < lines.length; i++)
                    Positioned(
                      top: step * i + topInset,
                      left: 0,
                      right: 0,
                      child: Text(
                        lines[i],
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        textAlign: align,
                        style: style,
                        strutStyle: strut,
                        textHeightBehavior: _evenLeading,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Baseline of an em-box strut (`height: 1`) for [size] and [weight].
double _emBaseline(double size, FontWeight weight) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: 'Ag',
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ),
    textDirection: TextDirection.ltr,
    textHeightBehavior: _evenLeading,
    strutStyle: StrutStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: 1,
      leadingDistribution: TextLeadingDistribution.even,
      forceStrutHeight: true,
    ),
  )..layout();
  final double baseline = painter.computeLineMetrics().first.baseline;
  painter.dispose();
  return baseline;
}

class _Ink extends StatelessWidget {
  const _Ink(
    this.text, {
    required this.size,
    required this.weight,
    required this.color,
    this.height,
    this.letterSpacing,
    this.align,
    this.maxLines = 1,
    this.features,
    this.slot,
    this.pinBaseline = false,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  final double? height;
  final double? letterSpacing;
  final TextAlign? align;
  final int maxLines;
  final List<FontFeature>? features;

  /// CSS line box when the strut would round to a whole logical pixel.
  final double? slot;

  /// Place the glyphs on Chrome's alphabetic baseline inside [slot].
  final bool pinBaseline;

  @override
  Widget build(BuildContext context) {
    final double line = height ?? (TypeMetrics.line(size) / size);
    final TextStyle style = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: line,
      letterSpacing: letterSpacing,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
      fontFeatures: features,
      decoration: TextDecoration.none,
    );
    final Widget textWidget = Text(
      text,
      maxLines: maxLines,
      softWrap: maxLines > 1,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
      style: style,
      strutStyle: StrutStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: line,
        leadingDistribution: TextLeadingDistribution.even,
        forceStrutHeight: true,
      ),
      textHeightBehavior: _evenLeading,
    );
    final double? slot = this.slot;
    if (slot == null) return textWidget;
    if (!pinBaseline) return SizedBox(height: slot, child: textWidget);
    final double top = TypeMetrics.baseline(size) - _emBaseline(size, weight);
    return SizedBox(
      height: slot,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: Text(
            text,
            maxLines: maxLines,
            softWrap: maxLines > 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: style.copyWith(height: 1),
            strutStyle: StrutStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: size,
              fontWeight: weight,
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
              forceStrutHeight: true,
            ),
            textHeightBehavior: _evenLeading,
          ),
        ),
      ),
    );
  }
}

class _StitchPainter extends CustomPainter {
  const _StitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Path solid = Path()
      ..moveTo(86, -6)
      ..cubicTo(48, 60, 48, 150, 84, 220);
    canvas.drawPath(
      solid,
      Paint()
        ..color = BrandColors.sealGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    final Path dashed = Path()
      ..moveTo(96, -6)
      ..cubicTo(60, 60, 60, 150, 94, 220);
    final Paint dashPaint = Paint()
      ..color = BrandColors.threadGold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final ui.PathMetric metric in dashed.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final double next = math.min(distance + 6, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), dashPaint);
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StitchPainter oldDelegate) => false;
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double inset = strokeWidth / 2;
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(math.max(0, radius - inset)),
        ),
      );
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final double next = math.min(distance + 4, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 3;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
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
