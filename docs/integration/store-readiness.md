# Store readiness

**Verdict: submission is impossible today, and not for reasons this repository
can fix.** Two hard store requirements have no endpoint behind them. This document
records what is ready, what blocks, and the wording that must match across three
places or the submission is rejected for a reason nobody enjoys discovering.

## What blocks submission

| Blocker | Store rule | Why it is not a client fix |
| --- | --- | --- |
| **F13 — no account deletion** | Both stores require an in-app route to delete an account | No module publishes a closure, erasure or deletion route. It also needs TAB 18's retention schedule first: a municipal record cannot always simply be erased, and the screen has to say what is deleted and what is kept by law |
| **F26 — no content reporting** | Both stores require a reporting path for user-generated content | The newsfeed's comments are the only UGC this app has. The backend's moderation surface is staff-only; calling it from here would breach Article 0 twice |
| **Developer account** | Must be the LGU, not an individual or a contractor | A trust and continuity requirement, and the item most often discovered late. Nobody has created one |
| **Privacy policy at a stable URL** | Required by both, in both languages | `privacy/notice` publishes a `document_url`; the document behind it is the DPO's to write, and there is no DPO (TAB 18) |

**F15 and F16 compound it**: a reviewer cannot sign in. There is no
self-registration route and no code is ever dispatched, so the test account both
stores require **cannot be created or used**. A reviewer who cannot sign in
rejects the app — and a wrong-role account has already caused a rejection on a
sibling project in this workspace.

## What is ready

**`PrivacyInfo.xcprivacy`** — written, registered in the Xcode project, and
**verified present in the built `.app`** rather than merely committed. Its answers
are unusually short and that is the product rather than an oversight: no
analytics SDK, no crash SDK, no messaging SDK, so there is no third-party
processor to declare. Four required-reason APIs, all of them the engine's own.

**Permission justifications**, matching the usage strings already in `Info.plist`
and the four permissions the *artifact* declares (TAB 17 found two more than the
manifest suggested):

| Permission | Listing justification |
| --- | --- |
| `INTERNET` | Reaching the municipality's own service. No other host is contacted |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | Optional app lock. Biometrics unlock local access to a session already established; they are never an authentication factor to the server and no biometric data leaves the phone |
| Camera *(runtime)* | Photographing a document an office has asked for. Only at the moment of use |
| Photo library *(runtime)* | Choosing that document instead. Only the file picked is read |
| `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | Signature-level, granted by the app to itself so its own runtime receivers are not exported. Grants nothing to anybody |

## The three declarations that must agree

Play's Data safety form, Apple's nutrition labels and the privacy notice must
say the same thing. A mismatch is a common rejection and an entirely avoidable
one. What all three should say, from what the app actually does:

* **Data collected by the app for its own purposes: none.** No analytics, no
  crash reporting, no advertising identifier, no third-party processor.
* **Data shared with third parties: none.**
* **Data transmitted to the LGU:** the details a resident enters to apply for a
  municipal service, and documents they choose to send — transmitted to the
  municipality's own server as the service being performed.
* **Data stored on the device:** a session token in the Keychain/Keystore, and a
  welcome-seen flag. Nothing about a resident is cached (TAB 15).
* **Account deletion:** *this is where the declaration currently cannot be made
  truthfully.* Both stores ask how a user deletes their account, and the honest
  answer today is that they cannot.

**Reconcile these against `docs/integration/privacy-and-dpa.md` and
`docs/integration/launch-alerting.md` before submitting.** Engineers and store
reviewers read "collection" differently, and the version that matters is theirs.

## Listing copy — draft, needs a Filipino reviewer

**English — short description:** *The official app of the Municipality of Taytay,
Rizal. Browse municipal services and programmes, follow an assistance request,
and hold your LGU ID.*

**Filipino — maikling paglalarawan:** *Ang opisyal na app ng Munisipyo ng Taytay,
Rizal. Tingnan ang mga serbisyo at programa, subaybayan ang iyong hiling na
tulong, at hawakan ang iyong LGU ID.*

Not final. TAB 19 records that a literal translation of bureaucratic English is
not an accessible Filipino service, and store copy is the first Filipino most
residents will read.

**Screenshots and the feature graphic are not produced.** They need a device or
emulator run against a server with data, and neither exists.

## Staged rollout and rollback

Recommended: **5% → 20% → 50% → 100%**, held at each stage until the crash-free
and sign-in-completion numbers in `launch-alerting.md` have a full day of data.

The halt must be *practised* before the first release, not read about. A staged
rollout is only a safety net if somebody has stopped one. Note what rollback
cannot do: Play halts distribution of a new version but does not remove it from
phones that already updated, so a client defect that ships is fixed forward. That
is the argument for the small first stage rather than for confidence in rollback.

## Reviewer notes — draft, blocked on a test account

> This is the resident-facing app of a Philippine municipal government. It has no
> administrative or staff features by design.
>
> Sign-in is by one-time code sent to a registered mobile number. Accounts are
> created by municipal staff, not self-service, so the test account below was
> provisioned by the LGU.
>
> **[TEST ACCOUNT — CANNOT BE PROVIDED YET, see F15/F16]**
>
> Without signing in, the app browses municipal services, assistance programmes,
> the newsfeed and events. Those are public by design and demonstrate most of the
> app.

The bracketed line is the submission blocker in one sentence.
