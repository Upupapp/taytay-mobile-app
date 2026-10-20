import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';

import '../../tool/golden_compare.dart';

void main() {
  test('identical images report no mismatch', () {
    final image = Image(width: 2, height: 2);
    image.clear(ColorRgb8(10, 20, 30));
    final report = compareImages(image, Image.from(image));
    expect(report.sameSize, isTrue);
    expect(report.mismatchPercent, 0);
    expect(report.sideBySide.width, 6);
  });

  test('a changed pixel is counted, and the top band can be ignored', () {
    final design = Image(width: 1, height: 2);
    design.setPixelRgb(0, 0, 0, 0, 0);
    design.setPixelRgb(0, 1, 0, 0, 0);
    final render = Image.from(design);
    render.setPixelRgb(0, 0, 255, 0, 0);
    render.setPixelRgb(0, 1, 255, 0, 0);

    final full = compareImages(design, render);
    expect(full.differingPixels, 2);
    expect(full.mismatchPercent, 100);

    final cropped = compareImages(design, render, excludeTop: 1);
    expect(cropped.differingPixels, 1);
    expect(cropped.comparedPixels, 1);
  });

  test('a mask is left out of the percentage', () {
    final design = Image(width: 2, height: 1);
    design.setPixelRgb(0, 0, 0, 0, 0);
    design.setPixelRgb(1, 0, 0, 0, 0);
    final render = Image.from(design);
    render.setPixelRgb(0, 0, 255, 0, 0);
    render.setPixelRgb(1, 0, 255, 0, 0);
    final report = compareImages(
      design,
      render,
      masks: const <GoldenMask>[GoldenMask(0, 0, 1, 1)],
    );
    expect(report.differingPixels, 1);
    expect(report.comparedPixels, 1);
  });

  test('different sizes report a full mismatch', () {
    final report = compareImages(
      Image(width: 2, height: 2),
      Image(width: 3, height: 2),
    );
    expect(report.sameSize, isFalse);
    expect(report.mismatchPercent, 100);
  });
}
