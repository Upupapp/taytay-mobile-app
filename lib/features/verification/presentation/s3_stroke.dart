import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';

/// A Lucide stroke icon at the design's pixel size.
///
/// The icon font's padding merges runs the SVG strokes keep apart.
class S3StrokeIcon extends StatelessWidget {
  const S3StrokeIcon({
    required this.paths,
    required this.size,
    this.color = BrandColors.taytayBlue,
    this.strokeWidth = 2,
    this.circles = const <S3StrokeCircle>[],
    super.key,
  });

  final List<String> paths;
  final List<S3StrokeCircle> circles;
  final double size;
  final Color color;
  final double strokeWidth;

  static const S3StrokeIcon user = S3StrokeIcon(
    size: 18,
    paths: <String>['M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2'],
    circles: <S3StrokeCircle>[S3StrokeCircle(12, 7, 4)],
  );

  static const S3StrokeIcon house = S3StrokeIcon(
    size: 18,
    paths: <String>[
      'M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8',
      'M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
    ],
  );

  static const S3StrokeIcon paperclip = S3StrokeIcon(
    size: 18,
    paths: <String>[
      'm16 6-8.414 8.586a2 2 0 0 0 2.829 2.829l8.414-8.586a4 4 0 1 0-5.657-5.657l-8.379 8.551a6 6 0 1 0 8.485 8.485l8.379-8.551',
    ],
  );

  static const S3StrokeIcon listChecks = S3StrokeIcon(
    size: 18,
    paths: <String>[
      'M13 5h8',
      'M13 12h8',
      'M13 19h8',
      'm3 17 2 2 4-4',
      'm3 7 2 2 4-4',
    ],
  );

  /// `.in` chevron. `m6 9 6 6 6-6`, 16px, `#5A6480`.
  static const S3StrokeIcon chevronDown = S3StrokeIcon(
    size: 16,
    color: BrandColors.listMeta,
    paths: <String>['m6 9 6 6 6-6'],
  );

  /// Birthdate mark. The ticks at y=2 are what start that input's run.
  static const S3StrokeIcon calendar = S3StrokeIcon(
    size: 16,
    color: BrandColors.textSecondary,
    paths: <String>[
      'M8 2v3',
      'M16 2v3',
      'M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z',
      'M3 9h18',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StrokePainter(
        paths: paths,
        circles: circles,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class S3StrokeCircle {
  const S3StrokeCircle(this.cx, this.cy, this.r);

  final double cx;
  final double cy;
  final double r;
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({
    required this.paths,
    required this.circles,
    required this.color,
    required this.strokeWidth,
  });

  final List<String> paths;
  final List<S3StrokeCircle> circles;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24;
    canvas.scale(scale);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final String data in paths) {
      canvas.drawPath(_parse(data), paint);
    }
    for (final S3StrokeCircle circle in circles) {
      canvas.drawCircle(Offset(circle.cx, circle.cy), circle.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => false;
}

Path _parse(String data) {
  final Path path = Path();
  final List<_Tok> tokens = _tokenize(data);
  var i = 0;
  var cx = 0.0;
  var cy = 0.0;
  var sx = 0.0;
  var sy = 0.0;
  String command = '';

  double num() => tokens[i++].number;

  while (i < tokens.length) {
    if (tokens[i].command != null) command = tokens[i++].command!;
    final bool rel = command.toLowerCase() == command;
    switch (command.toLowerCase()) {
      case 'm':
        final double x = num() + (rel ? cx : 0);
        final double y = num() + (rel ? cy : 0);
        path.moveTo(x, y);
        cx = x;
        cy = y;
        sx = x;
        sy = y;
        command = rel ? 'l' : 'L';
      case 'l':
        final double x = num() + (rel ? cx : 0);
        final double y = num() + (rel ? cy : 0);
        path.lineTo(x, y);
        cx = x;
        cy = y;
      case 'h':
        final double x = num() + (rel ? cx : 0);
        path.lineTo(x, cy);
        cx = x;
      case 'v':
        final double y = num() + (rel ? cy : 0);
        path.lineTo(cx, y);
        cy = y;
      case 'a':
        final double rx = num();
        final double ry = num();
        final double rot = num();
        final bool large = num() != 0;
        final bool sweep = num() != 0;
        final double x = num() + (rel ? cx : 0);
        final double y = num() + (rel ? cy : 0);
        _arc(path, cx, cy, rx, ry, rot, large, sweep, x, y);
        cx = x;
        cy = y;
      case 'z':
        path.close();
        cx = sx;
        cy = sy;
      default:
        throw FormatException('Unsupported SVG command $command');
    }
  }
  return path;
}

class _Tok {
  _Tok.command(this.command) : number = 0;
  _Tok.number(this.number) : command = null;

  final String? command;
  final double number;
}

List<_Tok> _tokenize(String data) {
  final List<_Tok> out = <_Tok>[];
  final String source = data.replaceAll(',', ' ');
  var i = 0;
  while (i < source.length) {
    final String char = source[i];
    if (char.trim().isEmpty) {
      i++;
      continue;
    }
    if (RegExp('[A-Za-z]').hasMatch(char)) {
      out.add(_Tok.command(char));
      i++;
      continue;
    }
    final int start = i;
    if (char == '+' || char == '-') i++;
    var dot = false;
    var exp = false;
    while (i < source.length) {
      final String c = source[i];
      if (c == '.' && !dot && !exp) {
        dot = true;
        i++;
      } else if ((c == 'e' || c == 'E') && !exp) {
        exp = true;
        i++;
        if (i < source.length && (source[i] == '+' || source[i] == '-')) i++;
      } else if (RegExp('[0-9]').hasMatch(c)) {
        i++;
      } else {
        break;
      }
    }
    out.add(_Tok.number(double.parse(source.substring(start, i))));
  }
  return out;
}

void _arc(
  Path path,
  double x1,
  double y1,
  double rx,
  double ry,
  double rotation,
  bool large,
  bool sweep,
  double x2,
  double y2,
) {
  if (rx == 0 || ry == 0) {
    path.lineTo(x2, y2);
    return;
  }
  final double phi = rotation * math.pi / 180;
  final double cos = math.cos(phi);
  final double sin = math.sin(phi);
  final double dx = (x1 - x2) / 2;
  final double dy = (y1 - y2) / 2;
  final double x1p = cos * dx + sin * dy;
  final double y1p = -sin * dx + cos * dy;
  var rxsq = rx * rx;
  var rysq = ry * ry;
  final double x1psq = x1p * x1p;
  final double y1psq = y1p * y1p;
  final double lambda = x1psq / rxsq + y1psq / rysq;
  if (lambda > 1) {
    final double scale = math.sqrt(lambda);
    rx *= scale;
    ry *= scale;
    rxsq = rx * rx;
    rysq = ry * ry;
  }
  final double sign = large == sweep ? -1 : 1;
  final double num = math.max(0, rxsq * rysq - rxsq * y1psq - rysq * x1psq);
  final double den = rxsq * y1psq + rysq * x1psq;
  final double coef = sign * math.sqrt(num / den);
  final double cxp = coef * rx * y1p / ry;
  final double cyp = coef * -ry * x1p / rx;
  final double cx = cos * cxp - sin * cyp + (x1 + x2) / 2;
  final double cy = sin * cxp + cos * cyp + (y1 + y2) / 2;
  final double theta1 = _angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
  var delta = _angle(
    (x1p - cxp) / rx,
    (y1p - cyp) / ry,
    (-x1p - cxp) / rx,
    (-y1p - cyp) / ry,
  );
  if (!sweep && delta > 0) delta -= 2 * math.pi;
  if (sweep && delta < 0) delta += 2 * math.pi;
  final int steps = math.max(1, (delta.abs() / (math.pi / 8)).ceil());
  for (var step = 1; step <= steps; step++) {
    final double t = theta1 + delta * step / steps;
    final double ex = math.cos(t) * rx;
    final double ey = math.sin(t) * ry;
    path.lineTo(cos * ex - sin * ey + cx, sin * ex + cos * ey + cy);
  }
}

double _angle(double ux, double uy, double vx, double vy) {
  final double dot = ux * vx + uy * vy;
  final double len = math.sqrt(ux * ux + uy * uy) * math.sqrt(vx * vx + vy * vy);
  var ang = math.acos((dot / len).clamp(-1.0, 1.0));
  if (ux * vy - uy * vx < 0) ang = -ang;
  return ang;
}
