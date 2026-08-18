# Privacy and the Data Privacy Act (RA 10173)

The Master Command places this TAB late and says to start it first, because
several items depend on people and approvals with lead times measured in weeks.
This document is what an engineering pass can produce; the rest needs named
owners and dates, and is listed as such rather than described as progress.

## The blockers that are not engineering, and cannot be closed by it

The backend self-declares no-go on four non-engineering items. **Two of them bind
this app directly**, and neither can be worked around in code:

| Blocker | Why it binds this app | Owner |
| --- | --- | --- |
| **No Data Protection Officer appointed** | Without a DPO there is nobody empowered to read the audit trail or answer a resident's data-subject request. The app can *raise* a request; there is currently nobody at the other end. It is also the DPO who maintains the privacy notice this app links to — `privacy/notice` publishes a `document_url`, and the document behind it is theirs. | **LGU — unassigned** |
| **No approved retention schedule** | The app cannot honestly tell a resident how long their data is kept, and it cannot specify account closure (F13) either: what is deleted and what is retained by law is exactly what a retention schedule decides. | **LGU — unassigned** |

The other two — a backup that has never been restored, and an unproven
event-capacity race — bind the platform rather than this client, and belong to
the backend's own launch checklist.

**These must be tracked with named owners and dates on the launch checklist. A
go/no-go that treats them as code items will find them open on launch day.**

## What was wired

`PrivacyApiRepository` against the `Audit` module: `GET me/privacy/consents`,
`DELETE me/privacy/consents/{purpose}`, and the corrections route TAB 04 already
uses. This was the last resident-reachable stub in the app.

**A withdrawn consent keeps its row.** The record is the point — "did she ever
agree, and when did she change her mind" is the question a complaint asks, and
removing the row erases the evidence it exists to provide. The server keeps
`granted_at` and `withdrawn_at` side by side and the app renders both.

**Consent is addressed by purpose, not by row id.** A resident withdraws a
*purpose*; the office keeps every row either way.

## Data-subject rights: what a resident can actually start today

| Right (RA 10173) | In-app | Route |
| --- | --- | --- |
| **Access** | ✅ | `me/profile`, `me/household`, `me/cases`, `me/privacy/consents` — the resident reads their own record throughout |
| **Correction** | ✅ | `me/profile/corrections`, adjudicated by staff |
| **Object / withdraw consent** | ✅ | `DELETE me/privacy/consents/{purpose}` |
| **Erasure** | ❌ **F13** | No route exists. Also a store-submission blocker |
| **Data portability** | ❌ | No export route exists. Not previously recorded — raised here as **F29** |

Two of five cannot be started from the app, and both need a backend route rather
than a screen.

## Consent withdrawal must actually stop collection

Telemetry is gated on consent, build permission and sink availability, and all
three are checked at the moment a signal is recorded rather than at startup — so
a withdrawal takes effect on the next signal rather than the next launch. Nothing
is queued, so there is no backlog to flush or discard on withdrawal. That is a
property of shipping with the sink unavailable, and it must be re-verified when a
sink exists.

## The push-SDK decision, now that it has to be made

Deferred from TAB 13 to here, because it is a privacy decision rather than a
wiring one. **Recommendation: do not adopt a messaging SDK before launch.**

Every mainstream option collects a device identifier by default, which is exactly
what "never log identifiers" exists to prevent, and a third-party processor is a
data-sharing agreement the municipality signs — not a line in `pubspec.yaml`. It
needs the DPO who does not yet exist, and it needs naming in the privacy notice
and in both stores' data declarations, which must match exactly or the submission
is rejected.

The app already ships with `UnavailablePushService` and the inbox works without
push. Launching without notifications is a smaller loss than launching with an
undeclared processor.

## Local retention

Per TAB 15: nothing about a resident is cached at all — not encrypted-and-cached,
not cached. The only durable local state is the session token in the
Keystore/Keychain and a welcome-seen flag. Sign-out clears the session store, and
`session_registry_test.dart` asserts it rather than inspecting it.

So the honest answer to "what does this app retain and for how long" is: **a
token until sign-out or expiry, and nothing else.** That answer is stable
regardless of what the retention schedule eventually says, which is the one part
of this TAB that did not have to wait for a person.

## What has not been done

* **No Privacy Impact Assessment** for the mobile channel. It needs the DPO.
* **No privacy policy authored.** `privacy/notice` publishes a `document_url` and
  the document behind it is the DPO's to write, in Filipino and English, at a
  stable URL.
* **No data-minimisation review of every screen** by a person. The structural
  work is done and asserted — household shows a count and names nobody, sessions
  carry no movement data, notification targets are routing only, telemetry has no
  free-text field — but a screen-by-screen review is a reading task, not a test.
