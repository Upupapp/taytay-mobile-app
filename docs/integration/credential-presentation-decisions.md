# Digital ID — the decisions TAB 06 had to make and could not defer

## FLAG_SECURE: not set, and this is the decision rather than the default

Android's `FLAG_SECURE` (and its iOS equivalent) would block screenshots and hide
the ID from the app switcher and from screen recording. It is **not set**, and
the Master Command is explicit that this must be a documented product decision
rather than something arrived at by leaving a line out.

**Why not.** Residents legitimately want to save their ID — to send to a relative
who is queueing for them, to keep when the phone has no signal at the counter, to
print. On a municipal identity app the population most likely to need that is the
one least likely to have a second way of proving who they are. Blocking
screenshots does not stop a determined copy either: a second phone photographs
the screen, and the resident who loses out is the one who was trying to be
organised.

**What it costs.** A screenshot of a QR sitting in a gallery is a credential
sitting in a gallery, and on a shared phone that is a real exposure.

**What makes the trade acceptable.** The QR is short-lived and server-checked. A
screenshot captures something that stops being worth anything within the TTL the
server mints it with, and a verifier re-checks it against the server at scan
time — so a stale image is refused rather than honoured. That is the property
doing the work here, not the flag.

**When to revisit.** If the credential ever gains an offline-verifiable form,
this decision must be re-taken: an offline-verifiable QR in a gallery is a
credential that does not expire in any way a screenshot can tell.

## Screen brightness: deferred, with a reason

The Master Command asks that brightness be raised while the QR is displayed and
restored afterwards — a code that will not scan under a barangay hall's lighting
is a code that does not work.

Not implemented at TAB 06. It needs a platform-channel dependency, and Article 1
requires a stated reason, a maintenance review and a data-egress review before
any package is added. Adding one in the same change that wires the repository
would mean the dependency review happened as a footnote to something else.

Recorded as work for **TAB 17**, where the dependency surface is audited as a
whole. Until then the ID renders at the device's own brightness, which scans in
most conditions and fails visibly rather than silently.

## Offline presentation: out of scope, and it is a launch-scope decision

Residents will be in places with no signal. Offline presentation needs the
backend's offline-verification key distribution, which belongs to the **planned**
`Verification` module (F12) — so it cannot be built here and cannot be improvised.
The launch scope must say plainly that the ID needs a connection to present.

## What cannot be proven before launch

`Verification` is planned, so the QR can be **produced** and the end-to-end scan
cannot be **tested** until the verifier client exists. "The digital ID works"
must not be reported when only half the loop is testable.
