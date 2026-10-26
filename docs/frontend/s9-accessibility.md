# S9 accessibility report

Headless widget-test run on the development host. Light mode only. This is not a TalkBack or VoiceOver session, and it does not measure a device.

| Check | Result |
| --- | --- |
| Welcome Skip semantics | Button, label "Skip", tap action |
| Welcome headline semantics | Header |
| Skip target | 48dp tall and at least 48dp wide |
| Next control | At least 48dp tall and 48dp wide |
| Page 2 back control | At least 48×48dp |
| 200% text | Welcome still shows Skip and the headline, Skip stays at least 48dp, no exception |
| Reduced motion | The gold thread stays. The travelling tip is absent. The 7s clock does not run |
| `disableAnimations: true` | Same result, from the platform flag rather than the in-app preference |
| Sign-in, create-account, services | `androidTapTargetGuideline`, `labeledTapTargetGuideline`, and `textContrastGuideline` |

The same checks are `test/features/s9_acceptance_test.dart`. They run with `flutter test` on this machine. They are not a GitHub Actions job.
