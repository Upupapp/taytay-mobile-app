# TAB COMPLETION REPORT

**TAB:** 23 — Notifications, Push, Inbox & Deep Links
**LOCAL COMPLETION:** 100%
**CERTIFICATION VERDICT:** CERTIFIED_WITH_NONBLOCKING_ENVIRONMENT_GAPS
**DATE:** 2026-08-16

## Completed scope

A push-permission timing policy that is a tested pure function rather than a
convention; a push seam with no SDK behind it; nine notification categories with
two that cannot be silenced; an inbox grouped by Manila recency with optimistic
read/unread; deep-link opening through the existing resolver; and a preferences
screen that restores a switch when a save fails.

## Deliverables

* `lib/core/push/push_service.dart` — `PushPermission`, `PushService`,
  `UnavailablePushService`, `PushMoment`, `PushPromptPolicy`, `PushPayload`
* `NotificationCategory` (9), `ResidentNotification.target`, per-category
  `NotificationPreferences` with `isCritical` handling
* `markAllRead`, `registerPushToken`, `unregisterPushToken` on the repository;
  planned implementation declines all
* `notification_inbox_controller.dart` — `InboxGroup`, `InboxSection`,
  optimistic read and mark-all with restore
* `notification_inbox_screen.dart` — inbox and `NotificationPreferencesScreen`
* Routes `/notifications` and `/notifications/settings` (`authenticated`)
* `ResidentCapability.readNotifications`
* `docs/taytay-notifications.md`; decision log D-122 … D-129
* `test/features/notifications_test.dart` — 36 tests

## Material decisions

D-122 the push prompt waits for a meaningful moment and is never re-asked ·
D-123 no push SDK until an endpoint exists · D-124 a payload redacts itself
including its keys · D-125 advisories and security notices have no off switch ·
D-126 an unset category defaults on · D-127 the inbox groups by Manila recency ·
D-128 reading is optimistic and restores on refusal · D-129 a notification is a
pointer, detail fetched under the live session.

## Built on TAB 10 rather than rebuilt

The deep-link resolver already rejected personal keys outright, refused
action-shaped targets, and constrained identifiers to a shape that cannot carry a
path segment. TAB 23 uses it as-is: the inbox resolves a stored target through
the same function a push tap would, and the router's guard re-evaluates access on
the way in. No new deep-link target was added — every notification destination is
a place a resident could already reach by tapping.

## Final verification

| | |
| --- | --- |
| `flutter analyze` | **PASS** — no issues found |
| `flutter test` | **PASS** — 992 tests (956 → 992) |
| `dart format` | **PASS** — clean |
| `flutter build apk --debug` | **PASS** — `app-debug.apk` |
| Guest / unverified / verified | **PASS** — all three exercised |

## Recovery event

`flutter analyze` failed once with a PowerShell `OutOfMemoryException` — a host
error, not a compile failure; the test run in the same command succeeded. Re-run
through Bash, it reported no issues. No code changed in response.

## Environment / production-only gaps

* The `Notification` module is `planned`: no list, no preferences, no token
  registration. `PlannedNotificationRepository` declines all of them and both
  screens render their honest states. Tests exercise the full flow through an
  injected repository.
* **No push SDK is wired**, deliberately (D-123). `PushService` has one
  implementation and it reports `unsupported`. The prompt policy, the payload
  type and the deep-link path are all built and tested; the plugin lands with the
  endpoint.
* The debug APK builds but was not installed on a device.

## Remote actions

Push: **NO** · Deploy: **NO** · Production access: **NO** · Remote mutation: **NO**

## Next indexed TAB

**TAB 24 — Settings, Privacy, Consent, Help & Account Controls.**
Automatic advancement: AUTHORIZED.
