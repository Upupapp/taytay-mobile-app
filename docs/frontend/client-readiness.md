# Client readiness — the front-end sequence's closing verdict

**Measured 23 August 2026 at decision time.** Every figure below came from a run made for this
document, not carried from TAB 00.

---

## Re-read on 30 August 2026, after twenty-two commits. THE VERDICT IS UNCHANGED.

**That is the finding, and it is not a disappointment — it is the point of writing a verdict down.**
A week of work happened between these two dates: every reachable piece of resident-facing enum copy
was localised, four classes of guard were built and red-proofed, an architecture clause was found
untrue and amended by the owner, a certification script was written, and a release gate that had
been confidently wrong for eleven days was fixed. **None of it touched any of the three reasons
below.** Activity is not progress toward readiness, and a reader arriving at a busy changelog
should be told so plainly rather than left to infer it.

| | Then (`efa74d1`, 23 Aug) | Now (`b6957e0`, 30 Aug) |
|---|---|---|
| `flutter test` | 1,464 passing | **1,513 passing** |
| Ahead of `origin/main` | 71 commits, nothing ever pushed | **0 — everything pushed** |
| Route guard | 50 declared, 48 served, **2 ahead** | 52 declared, 48 served, **4 ahead** |
| Gates run from | the working tree | **a detached worktree, SHA stamped** |
| Android journeys | never driven | **never driven** |
| Screen reader | never run | **never run** |

**The "2 ahead" figure in reason 3 below is wrong now: C-09 is four routes.** It has been four since
27 August, and it is corrected here rather than edited silently in place, because the wrongness is
the useful part — a verdict document with a stale number in its own reasoning is exactly the failure
audited across `docs/` on 30 August.

Current state is stamped in `docs/frontend/gate-certification.md` against a named SHA and produced
by `tool/certify.sh`. **This document is a dated verdict, not a live dashboard**, and the two
figures above are here to show what did and did not move — not to turn it into one.

---

## Verdict

# NOT READY — on the client's own scope

**And that is the useful part.** The previous sequence closed NO-GO for reasons almost entirely
outside this repository: no SMS provider, no DPO, no signing keys, no self-registration route. A
front-end team reading that verdict learns nothing about whether the client is finished.

This one says: **it is not**, for three reasons that belong to this repository and to nobody else.

None of the three is an LGU blocker. None is softened by one, and none hides behind one.

---

## Measured at decision time

| | |
| --- | --- |
| HEAD | `efa74d1` |
| Working tree | clean but for this document's own edits |
| Ahead of `origin/main` | **71 commits, nothing ever pushed** |
| `flutter analyze` | **clean** |
| `flutter test` | **1,464 passing, 1 skipped** |
| Repositories | **16 wired, 1 stubbed** (`registrationRepository`, F15-blocked) |
| Module guard | **OK — 17 agree** at `api-baseline-2026-08` |
| Route guard | **OK — 50 declared, 48 served, 2 ahead** (C-09) |
| Correctable-field guard | **OK — 12 agree** |
| iOS | builds, installs, launches, **journeys pass** on iPhone 17 simulator |
| Android | builds, installs, launches, **renders at `minSdk = 24`**; journeys **did not run** |
| Release build | **refuses to sign itself**, verified for the right reason |

---

## The three reasons, and they are the client's

### 1. Android journeys are unverified, and Android is the majority platform

The app renders correctly at API 24 — that was established for the first time in this app's
history during TAB 08, and it is real. But nothing has ever *driven* it on Android. The walk was
killed after 74 minutes on the onboarding screen, and a probe containing a single `Text` widget
hung for twelve hours, which rules this repository out of the diagnosis and leaves the question
unanswered rather than answered well.

**A client that cannot demonstrate its own majority platform is not ready.** That the cause is
tooling rather than code changes who should fix it, not whether the criterion is met.

### 2. No screen reader has ever been run against this app

Not VoiceOver, not TalkBack, in fifty-four TABs. The automated evidence is genuinely strong —
every tappable control labelled, across 11 routes × 3 access levels × 2 languages — and it is
evidence about a *tree*, not about speech. Focus order, announcement wording, live-region timing
and Filipino pronunciation are all unproven.

This app serves senior citizens and persons with disability. They are two of the sectors the office
exists to serve, named in RA 9994 and RA 10754. **Shipping an unverified accessibility claim to
them is the specific failure worth refusing.**

### 3. The app calls two routes that do not exist at its own pinned baseline

`GET barangays` and `POST newsfeed-comments/{comment}/reports` (C-09). Both exist at backend HEAD
and neither exists at `eec71e6`, the commit this repository declares itself built against. Nothing
is broken today; the **claim** is wrong, and a repository that misstates its own contract cannot be
certified against it.

It is guarded — a ratchet that fails on a third occurrence and equally on an entry that turns out
to be served — but a guard holding a line is not the line being correct.

---

## What was closed, with evidence

| | Finding | Evidence |
| --- | --- | --- |
| **C-01** | Two upload ceilings disagreed — 10 MB at capture, 8 MB at send, so a 9 MB PDF passed one and died at the other | `UploadPolicy` reads the server's `accepts`; one ceiling in `lib/`, guarded; 9 MB regression test |
| **C-02** | A push registration could not be withdrawn (F27) | The id was being *discarded*, not missing. Now held with the token's lifetime; withdrawal on both session-ending paths, before the store is cleared |
| **C-03** | A registration wizard with no server counterpart (F15) | `OnboardingMode` from `app/bootstrap`, default staff-mediated, wizard unreachable **in the route guard** rather than by hiding a button |
| **C-04** | KYC corrections keyed by category here, by field on the server (F23) | The server's 12 fields modelled; the resident is asked *which*; a document is refused **before** the input |
| **C-05** | The client overrode the server's page size | Three declared defaults and four values actually sent, none of them the published 15. Now one `PagePolicy`, read |
| **C-06** | "One expiry is one sign-out" was decided, and **was not holding** | 10 concurrent 401s produced 10 teardowns. Single-flighted. The sheet's *"Nothing you submitted has been lost"* corrected to what is true |
| **C-10** | The baseline guard's network path could never work | Defaults to the sibling clone; the tag has never been pushed |

Every guard in that table was **proven red before being trusted**.

---

## Not the client's, restated and not adopted

Re-verified at backend HEAD on the day of this verdict. Detail in
`docs/integration/manual-tasks.md`.

| Blocker | State | Owner |
| --- | --- | --- |
| **F16** SMS provider | seam built; only `Null` and `Log` senders exist — **no vendor adapter** | LGU procurement |
| **F15** self-registration route | **absent** | LGU product, then backend |
| **F13** account closure | **absent** — and cannot be specified until a retention schedule exists | LGU, then backend |
| **F24** per-service intake form | **absent** | the office that adjudicates each service |
| **F29** data-portability export | **absent** | backend |
| KYC document upload | **absent** under `me/kyc` | backend |
| **F03** signing keystore | not generated — correctly, and never by an agent | LGU |
| **F25** proxy body limit | unknown | whoever operates the deployment |
| DPO, retention schedule, store accounts, staging, privacy policy | open | LGU |

**The client verdict is not softened by any of these.** If every one closed tomorrow, the three
client reasons above would still stand.

---

## What has still never been proven

**Nothing in this programme has run against a deployed Taytay backend.** Every "closed" here means
closed against a contract read from source at a pinned commit, a suite run against scripted
transports, and — new in this sequence — a real Flutter engine on an iOS simulator with a
deliberately unreachable API.

That sentence survived from the last dossier into this one deliberately. It was true then and it is
true now.

---

## Dissent, recorded against myself

**Four times in nine TABs a tool said something narrow and I heard something absolute, and every
one of those errors made the work look better than it was.**

| TAB | The tool said | I heard | Cost |
| --- | --- | --- | --- |
| 05 | a test run failed | a guard fired | the red-proof pointed at a file that does not exist |
| 07 | the audit passed | the routes were checked | it passed by *redirection*; a planted defect went undetected |
| 08 | 10.2 s elapsed | a slow cold start | it was `pumpAndSettle` waiting on an animation |
| 08 | "no emulator sources" | Android cannot run here | it needed one download; Android ran that evening |

None was caught by the suite. Three were caught by deliberately trying to make a check fail; the
fourth by questioning a sentence I had already written down. **The asymmetry is the finding** — the
errors ran one way, toward flattering the work — and it is the reason this verdict is conservative
about what it claims to have verified.

The programme's own earlier lesson, recorded as a dissent in the previous dossier, was *a status
document is not evidence*. This sequence adds a narrower one: **a passing check is not evidence
either, until somebody has watched it fail.**

---

## What would change this verdict

Three things, in order of value per hour spent:

1. **One Android handset over `adb`, one hour.** Answers the journeys, the frame budget, the real
   camera on the upload path, and settles whether the emulator hang is real.
2. **One TalkBack session in Filipino**, same handset — sign-in → home → KYC claim → upload.
3. **A backend tag taken when that repository is still**, so the pin can move and C-09 can close.

None needs an LGU decision. All three are engineering, and together they are about a day.
