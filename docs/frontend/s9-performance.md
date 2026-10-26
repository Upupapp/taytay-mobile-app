# S9 performance report

Headless stand-in for a device frame time. Light mode only. The welcome gold thread was already on screen. The test then pumped 45 steps of 33ms, which is the 30fps capture step, and timed each pump with a host stopwatch.

| Figure | Value |
| --- | --- |
| Pumps | 45 × 33ms |
| Mean host pump | 1.77 ms |
| Slowest host pump | 6.00 ms |
| Thread | The cycle value changed across the pumps |

These numbers are host `WidgetTester.pump` cost. They are not a frame time on a phone, not a cold start, and not the 60fps list budget in `docs/integration/performance-budgets.md`. No device figure is invented here. The bound in the test is 2000ms, so a stalled pump fails. The run is `test/features/s9_acceptance_test.dart` with `TAYTAY_S9_REPORT=1`. It is not a GitHub Actions job.
