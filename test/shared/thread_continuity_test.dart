import 'package:flutter_test/flutter_test.dart';
import 'package:taytay_resident/shared/widgets/taytay_thread.dart';

void main() {
  test('the joined stitch meets at each page boundary', () {
    for (var page = 0; page < ThreadCurve.pages.length - 1; page++) {
      final exit = pointOnThread(ThreadCurve.pages[page], 1);
      final entry = pointOnThread(ThreadCurve.pages[page + 1], 0);
      expect(exit.dy, entry.dy);
      // Page n's right edge and page n+1's left edge are the same point
      // once the next page is placed 390 px to the right.
      final worldExit = exit + Offset(390.0 * page, 0);
      final worldEntry = entry + Offset(390.0 * (page + 1), 0);
      expect((worldExit - worldEntry).distance, lessThan(8));
    }
  });

  test('a swipe keeps the speck on the joined path', () {
    const phase = 0.6;
    final settled = placeSpeck(page: 0, phase: phase, anchor: 0);
    final justMoved = placeSpeck(page: 0.02, phase: phase, anchor: 0);
    final atSeam = placeSpeck(page: 1, phase: phase, anchor: 0);

    expect(settled.page, 0);
    expect(settled.t, closeTo(phase, 0.001));
    expect(justMoved.page, 0);

    final before = pointOnThread(ThreadCurve.pages[0], settled.t);
    final after = pointOnThread(ThreadCurve.pages[0], justMoved.t);
    // Resetting t to the page fraction (the old behaviour) threw the speck
    // back to the entry, about 230 px. The joined path moves it a few pixels.
    expect((before - after).distance, lessThan(40));

    expect(atSeam.page, 1);
    expect(atSeam.t, 0);
    final leaving = placeSpeck(page: 0.999, phase: phase, anchor: 0);
    expect(leaving.page, 0);
    final exit = pointOnThread(ThreadCurve.pages[0], leaving.t);
    final entry = pointOnThread(ThreadCurve.pages[1], atSeam.t);
    final worldExit = exit;
    final worldEntry = entry + const Offset(390, 0);
    expect((worldExit - worldEntry).distance, lessThan(12));
  });

  test('backing up arrives on the previous page at its exit', () {
    final mid = placeSpeck(page: 0.5, phase: 0.4, anchor: 1);
    expect(mid.page, 1);
    expect(mid.t, lessThan(0.4));

    final arrived = placeSpeck(page: 0, phase: 0.999, anchor: 0);
    expect(arrived.page, 0);
    expect(arrived.t, greaterThan(0.95));
  });
}
