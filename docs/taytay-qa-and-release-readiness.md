# QA, test journeys and release readiness

TAB 28. The final pass: seven fictional residents, the journeys they actually
take, and an audit of what ships.

---

## The fictional dataset

`test/support/taytay_personas.dart` — seven linked personas.

| Persona | State | Story |
| --- | --- | --- |
| — | guest | Has not registered. Browsing to decide whether to. |
| Ana | unverified | Registered last night; waiting for the LGU to confirm who she is. |
| Jun | verified | Verified, nothing in flight. |
| Marites | verified | One approved medical assistance case, `TR-2026-000041`. |
| Rosa | verified | Open case `TR-2026-000058`, blocked on a barangay clearance. |
| Ben | verified | Waitlisted for a full dental mission. |
| Lito | unverified | Signed in, commented on a road-closure announcement. |

**Every name is invented**, and the dataset is *linked*: Rosa's missing
requirement belongs to Rosa's case, which belongs to a service in the catalogue;
Ben's waitlist place belongs to an event that is full. Ids that agree across
fixtures are the difference between testing a screen and testing a resident's
afternoon.

**No mobile number, address, PhilSys number or date of birth appears in the file
at all** — not even a fake one (D-170). A fixture file full of plausible-looking
government identifiers is a file somebody eventually pastes into a bug report,
and the safest fake identifier is the one that was never written down.

Lito is deliberately **unverified**: reading and commenting on public municipal
announcements is not a resident-linked service, and a build that quietly required
verification for it would have narrowed the public square.

---

## QA journey checklist

`test/features/resident_journeys_test.dart` — 35 tests driving the **real app**
with the **shipped repositories**. Nothing is stubbed, so the honest-refusal
states of the planned modules are part of what is checked rather than something
the tests paper over.

| # | Journey | Result |
| --- | --- | --- |
| 1 | First launch → welcome → Continue as Guest | ✅ lands on welcome, offers a way in with no mobile number |
| 2 | Guest browses News, Events, Services, Help, Privacy | ✅ all reachable without an account |
| 3 | Guest taps a gated action → gate → sign-in, intent preserved | ✅ intent held, replayed on sign-in, dropped on sign-out |
| 4 | Registration wizard → pending verification | ✅ unverified reaches verification, not the ID |
| 5 | Verification declines rather than collecting | ✅ no "uploading", no false success |
| 6 | Verified resident unlocks resident-linked services | ✅ ID, requests and household all open |
| 7 | Assistance case → requirements → timeline | ✅ Marites and Rosa reach theirs; unverified and guest cannot |
| 8 | Newsfeed engagement | ✅ Lito reaches his post while unverified |
| 9 | Event register / waitlist / cancel | ✅ Ben reaches his place; registering needs an account; a guest still reads the event |
| 10 | Notification deep link, signed in and out | ✅ opens directly, or lands on sign-in — never "not found" |
| 11 | Expired session | ✅ moved off the gated screen; public content still there |
| 12 | Weak / offline network | ✅ banner + "nothing has been sent"; a `403` never dressed up as offline; public browsing continues |
| 13 | Large text | ✅ all seven personas reach Home at 200% |
| 14 | Reduced motion | ✅ nothing reachable changes |
| 15 | Device sizes and safe areas | ✅ covered by `device_adaptation_test.dart` — 5 shapes, notch, landscape |
| 16 | No admin surface for any persona | ✅ 13 admin-shaped paths refused for all three states |
| 17 | Staff vocabulary absent from every core screen | ✅ |

---

## Two defects the journeys found

### A held intent survived sign-out

`IntentController.onSessionChanged` documented itself as *"wired to sign-out and
to fail-closed invalidation"*. It was wired to the `401` path **only**.

A resident who signed out deliberately kept their pending intent, and the next
person to sign in on the same handset had it replayed as them. In Taytay one
smartphone per household is ordinary, so that is a real afternoon and not a
hypothetical: Ana signs out, her brother signs in, and the app resumes "apply for
assistance" as him.

Fixed by observing the boundary on the **session itself** rather than on any of
the three routes into it (D-171), so sign-out, expiry and a future account switch
all reach it and none of them can be added later without it.

### And the fix, over-corrected, broke the resume

The first version cleared on *any* account-id change — which includes a guest
signing in, and that is the entire reason an intent is held. `welcome_and_gates_test.dart`
caught it on the next run.

The rule is now precise (D-172): **signing in is not a boundary, it is the
resume.** A boundary is a session *ending*, or one account replacing another.
Both leave a held intent belonging to somebody who is no longer holding the
phone.

That sequence is worth recording as much as the fix: a journey test found a real
leak, and the existing suite immediately caught the over-correction. Neither
would have been enough alone.

---

## Release-readiness audit

`test/core/release_readiness_test.dart` — 17 checks.

### Branding

* No `esperanza`, `servana` or `upupapp` in any shipped `lib/` source, asset
  filename, manifest, plist, gradle file or `pubspec.yaml`.
* Comments are stripped first. The prose in this repository names the reference
  apps constantly — it is how a decision explains what it learned from where —
  and a scan that tripped on an explanation is a scan nobody keeps green.
* The app names itself `Taytay LGU IDS`, ships under `ph.gov.taytay.lguids`, and
  the package is `taytay_resident`.

### Product boundary

* **Every route declares an `AccessRequirement`.** There is no default, which is
  the client-side echo of the backend's deny-by-default rule.
* No route is named or pathed like a staff surface — twelve forbidden stems
  checked against every route name *and* path.
* `AccessLevel` has exactly three values. A fourth would be the door.
* No shipped source models a staff concept (`isAdmin`, `assignedTo`,
  `internalNote`, `reviewerId`, …). The decoders' own deny-lists are stripped
  before the scan, because a decoder that *rejects* `assigned_to` has to name it.

### Android

* **Exactly two permissions**: `INTERNET` and `USE_BIOMETRIC`. No `CAMERA` — the
  document picker delegates to the system camera app deliberately (D-72) — and
  no `READ_MEDIA_IMAGES`, because the photo picker returns only what the
  resident chose.
* No advertising, location, contacts or phone-state permission.
* Cleartext traffic is not enabled.
* `applicationId = ph.gov.taytay.lguids.taytay_resident`.

XML comments are stripped first: the manifest documents the permissions this app
does **not** declare and why, which is exactly the prose a permission scan must
not trip on.

### iOS

* No `NSUserTrackingUsageDescription` — the key an app adds when it intends to
  track. Its absence is the statement.
* No `NSAllowsArbitraryLoads`.

### Configuration

* No `--dart-define` name matches `KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL`. Those
  values ship in clear text inside the APK.
* No `.env` file exists, and `.gitignore` covers it.

### The record

* The supervisor state records all 28 TABs complete.
* TABs 15–28 each have a completion report. TABs 01–14 were certified before the
  report directory existed; their record is the commit history and `docs/`. The
  scan says which is which rather than asserting a number that was never true.
* The decision log is numbered **1 … 172 with no gaps or duplicates**.
* `CLAUDE.md` still declares itself the highest-authority document and still
  carries Article 10.

---

## Final Servana alignment audit

Compared as *principle*, never as asset. Nothing here is traced from
ServanaClientAPP artwork; `taytay_scenes.dart` says so in its own header.

| Dimension | State |
| --- | --- |
| Welcome scenes | Taytay-specific illustrations, drawn as Flutter primitives |
| Gradients | `BrandGradient` with contrast-checked `onColor`, asserted in tests |
| Card depth | `AppCard` elevation tokens; dimension from surface tint, not shadow spam |
| Banner styling | One `AppBanner` with four tones; every caller goes through it |
| CTA feel | One `AppButton`, four variants, 48 dp floor, loading state announced |
| Pop-ups | `AppSheet` + `ConfirmSheet` + `AccessGateSheet` — three, not per-screen dialogs |
| Motion | `MotionTokens` only; `Motion.reduced` honoured everywhere |
| Haptics | `HapticIntent`, never the only signal, never on typing or scroll |

**Polish improved during this run** rather than at the end: TAB 24 replaced
ad-hoc confirmations with one sheet whose `consequence` is required; TAB 25 gave
the offline banner functional motion that shortens under reduced motion; TAB 26
raised snackbar duration for 200% text and gave every outcome a spoken channel.

---

## Automated coverage

| Gate | Result |
| --- | --- |
| `flutter analyze` | clean — no errors, warnings or infos |
| `flutter test` | **1,205 passing** |
| `dart format` | clean |
| `flutter build apk --debug` | passing |

By level: unit tests for the guard, access policy, decoders, config, cache,
network monitor, telemetry redaction and Manila time; widget tests for every
resident-reachable screen from all three session states including the denied
path; journey tests for the seventeen flows above; and repository-wide scans for
security, privacy, branding and the product boundary.

**No integration-test harness is used.** The Master Command allows for it "where
project setup permits", and here it does not add coverage the widget-level
journeys lack: with the shipped repositories declining, an integration driver
would exercise the same honest-refusal states through a slower harness, on the
same single Android target.

---

## Environment gaps at the end of the run

Stated plainly, because a release decision is made on what is *not* verified.

* **No iOS build.** The development host is Windows; `flutter build ios` requires
  macOS. The iOS runner is configured and audited statically, and the code is
  platform-agnostic Dart, but **no iOS binary has been produced or run**.
* **No physical device run at all.** The debug APK builds; it has not been
  installed. No TalkBack or VoiceOver session, no DevTools trace, no scroll
  profile on a mid-range handset.
* **Six of nine backend modules are `planned`.** `Identity`, `ResidentProfile`,
  `Credential`, `Verification`, `ServiceDelivery` and `Notification` publish no
  endpoints; every repository for them declines honestly and every screen renders
  its refusal state. The journeys exercise the real flows through injected
  repositories in the feature suites.
* **No release signing configuration**, no store listing, no privacy-policy URL,
  no version. All of those are municipal decisions and remote acts, and Article
  10 puts every one of them outside this run.

---

## Release readiness verdict

**Ready for human review and a device-testing pass. Not ready to publish**, and
nothing in this repository claims otherwise.

What is done: the whole resident product against the committed contract, with the
planned modules declining rather than pretending; 1,205 automated checks; a clean
analyzer; a debug APK; and a decision log of 172 numbered entries explaining why
each thing is the way it is.

What a human must do next, in order:

1. Run the app on a physical Android device and a physical iPhone.
2. Run TalkBack and VoiceOver through the seventeen journeys above.
3. Decide the analytics question — whether Taytay LGU commissions a service at
   all, and if so under what data-sharing agreement.
4. Produce release signing material and a store listing.
5. Authorize the first push. **Nothing in this run has been pushed.**
