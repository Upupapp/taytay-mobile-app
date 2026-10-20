import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// One pixel-match of a design PNG against a Flutter render.
class GoldenReport {
  const GoldenReport({
    required this.mismatchPercent,
    required this.comparedPixels,
    required this.differingPixels,
    required this.sideBySide,
    required this.sameSize,
  });

  /// Share of compared pixels whose CIE76 ΔE is greater than 6.
  final double mismatchPercent;

  final int comparedPixels;
  final int differingPixels;
  final Image sideBySide;

  /// False when the two files had different pixel sizes. The report is then
  /// 100 percent, and the side-by-side letterboxes both images.
  final bool sameSize;
}

/// Compares [design] with [render].
///
/// Rows in `[0, excludeTop)` are drawn and ignored, so a status-bar crop can
/// be left out of the percentage. A pixel differs when CIE76 ΔE is above 6.
GoldenReport compareImages(Image design, Image render, {int excludeTop = 0}) {
  final sameSize =
      design.width == render.width && design.height == render.height;
  if (!sameSize) {
    return GoldenReport(
      mismatchPercent: 100,
      comparedPixels: 0,
      differingPixels: 0,
      sideBySide: _join(design, render, _blank(design.width, design.height)),
      sameSize: false,
    );
  }

  final heat = Image(width: design.width, height: design.height);
  var compared = 0;
  var differing = 0;
  final top = math.min(excludeTop, design.height);
  for (var y = 0; y < design.height; y++) {
    for (var x = 0; x < design.width; x++) {
      final left = design.getPixel(x, y);
      final right = render.getPixel(x, y);
      final delta = _deltaE(left, right);
      final differs = delta > 6;
      if (y >= top) {
        compared++;
        if (differs) differing++;
      }
      final mark = differs ? 220 : (left.r * 0.25).round();
      heat.setPixelRgb(x, y, mark, differs ? 40 : mark, differs ? 40 : mark);
    }
  }

  final percent = compared == 0 ? 0.0 : (differing * 100) / compared;
  return GoldenReport(
    mismatchPercent: percent,
    comparedPixels: compared,
    differingPixels: differing,
    sideBySide: _join(design, render, heat),
    sameSize: true,
  );
}

Image _blank(int width, int height) => Image(width: width, height: height);

Image _join(Image design, Image render, Image heat) {
  final width = math.max(design.width, math.max(render.width, heat.width));
  final height = math.max(design.height, math.max(render.height, heat.height));
  final canvas = Image(width: width * 3, height: height);
  compositeImage(canvas, design, dstX: 0, dstY: 0);
  compositeImage(canvas, render, dstX: width, dstY: 0);
  compositeImage(canvas, heat, dstX: width * 2, dstY: 0);
  return canvas;
}

double _deltaE(Pixel left, Pixel right) {
  final a = _lab(left.r, left.g, left.b);
  final b = _lab(right.r, right.g, right.b);
  final dl = a[0] - b[0];
  final da = a[1] - b[1];
  final db = a[2] - b[2];
  return math.sqrt((dl * dl) + (da * da) + (db * db));
}

List<double> _lab(num red, num green, num blue) {
  double linear(num channel) {
    final c = channel / 255;
    if (c <= 0.04045) return c / 12.92;
    return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linear(red);
  final g = linear(green);
  final b = linear(blue);
  final x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047;
  final y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750;
  final z = (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883;

  double f(double t) {
    if (t > 0.008856) return math.pow(t, 1 / 3).toDouble();
    return (7.787 * t) + (16 / 116);
  }

  final fx = f(x);
  final fy = f(y);
  final fz = f(z);
  return <double>[116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

/// `dart run tool/golden_compare.dart --design a.png --render b.png --out c.png`
///
/// Prints the mismatch percentage. Exit code 0 always: the caller decides
/// the threshold. Pass `--exclude-top` to ignore a status-bar band.
void main(List<String> args) {
  String? designPath;
  String? renderPath;
  String? outPath;
  var excludeTop = 0;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String next() {
      if (i + 1 >= args.length) {
        stderr.writeln('Missing value after $arg');
        exitCode = 64;
        return '';
      }
      i++;
      return args[i];
    }

    switch (arg) {
      case '--design':
        designPath = next();
      case '--render':
        renderPath = next();
      case '--out':
        outPath = next();
      case '--exclude-top':
        excludeTop = int.tryParse(next()) ?? 0;
      default:
        stderr.writeln('Unknown argument $arg');
        exitCode = 64;
        return;
    }
  }

  if (designPath == null || renderPath == null || outPath == null) {
    stderr.writeln(
      'Usage: dart run tool/golden_compare.dart '
      '--design design.png --render render.png --out side.png',
    );
    exitCode = 64;
    return;
  }

  final design = decodePng(File(designPath).readAsBytesSync());
  final render = decodePng(File(renderPath).readAsBytesSync());
  if (design == null || render == null) {
    stderr.writeln('Could not decode one of the PNG files.');
    exitCode = 1;
    return;
  }

  final report = compareImages(design, render, excludeTop: excludeTop);
  File(outPath).writeAsBytesSync(encodePng(report.sideBySide));
  stdout.writeln(
    'mismatch ${report.mismatchPercent.toStringAsFixed(2)}% '
    '(${report.differingPixels}/${report.comparedPixels}) '
    'sameSize ${report.sameSize}',
  );
}
