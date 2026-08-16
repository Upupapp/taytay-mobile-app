# Taytay resident mobile — post detail, reactions, comments and sharing

The exact interactions the Taytay Newsfeed scope allows, and the several places
this flow refuses an affordance it cannot honour.

Implemented in `lib/features/news/` — `domain/post_interaction.dart`,
`presentation/post_detail_controller.dart`, `presentation/news_post_screen.dart`
— and `lib/core/sharing/`.

---

## 1. Nothing is offered that the backend did not declare

`PostCapabilities` carries five flags — react, comment, share, delete own
comment, report comment — and **every one defaults to false**. A capability the
server did not mention is one the app does not offer.

The reasoning is concrete rather than tidy-minded:

* A comment box that fails on submit wastes somebody's typing.
* A report control the backend cannot record tells a resident their complaint
  went somewhere when it went nowhere — which is worse than no control at all,
  because they stop looking for another way to raise it.

The guard is in **two places**: the screen does not render the control, and the
controller refuses the call. A stale frame cannot mutate anything.

**There is no moderation capability and there cannot be one.** Hiding or
deleting another resident's comment, pinning, archiving and viewing moderation
metrics are admin-console actions. `deleteOwnComment` is the only delete, it
takes the resident's own comment id, and the controller re-checks `isMine`
before calling it.

---

## 2. Optimistic reactions always reconcile — acceptance 2

A tap lands immediately, and then one of two things happens:

| | |
| --- | --- |
| **Server answers** | its count and its `myReaction` **replace** the guess |
| **Server refuses** | exactly what was there before is put back |

The app's arithmetic is wrong the moment two people react at once; the server's
is not. So `setReaction`/`clearReaction` return a `ReactionOutcome` carrying the
new total, and the controller adopts it rather than keeping its own increment. A
test drives a server that answers `42` against a guess of `6` and asserts the
screen shows `42`.

A reaction that silently stuck when the server refused it is a lie the resident
cannot see, so the revert restores the whole prior state, not just the count.

Three details:

* **Tapping the reaction you already have clears it** — modelled as a toggle, so
  the screen needs one control rather than two.
* **Switching reactions does not change the total** optimistically, because it
  does not change it on the server either.
* **An absent count is never invented.** A post the office published no count for
  stays countless through a reaction; only the server's answer introduces a
  number. Same rule as TAB 19's "an absent count is not a zero".

Each attempt carries an idempotency key.

---

## 3. A failed comment keeps its words

One idempotency key per comment attempt, reused across retries of that attempt,
retired once the server answers. A retry replays rather than posting the same
paragraph twice.

On failure the text **stays in the box** and the banner says so: *"Nothing was
sent, and what you wrote is still in the box. Trying again will not post it
twice."* Losing a paragraph somebody typed on a phone because a bus went through
a tunnel is the failure this exists to prevent.

Deleting an own comment is optimistic too, and restores the comment **at its
original index** when the server refuses — not appended to the end, which would
silently reorder a conversation.

---

## 4. Moderation state is rendered, never second-guessed

A comment the office hid arrives with `isHiddenByModerator` and is shown as
*"This comment was removed by Taytay LGU"* — **kept, not dropped**.

Dropping it would leave a reply pointing at nothing, and would hide from a
resident that their own comment was moderated. The Master Command's instruction
is explicit, and this is what following it looks like in the rendering.

An **official** reply is distinguished by the server's `authorKind`, never by the
app comparing a display name — inferring it would let any resident who set the
right name appear to speak for the municipality. It carries an icon, a colour and
the words "Taytay LGU", so it never depends on colour alone.

---

## 5. Guest gating preserves the action — acceptance 3

A guest reads the post and every comment. The gate appears only at the point of
acting, via the existing `AccessGateSheet` and the `likePost` /`commentOnPost`
intents that TAB 06 already defined. The intent is held, the resident returns
here, and the tap that was interrupted is the tap they finish.

The gate **never acts on their behalf** — a test asserts that meeting it results
in zero calls to the repository.

---

## 6. Sharing, and the link this app will not invent

`ShareableContent.url` is **the server's canonical link or nothing**. This client
does not know the LGU's public web address, and composing one from a host and an
id would put a fabricated link inside a shared typhoon advisory — sending people
to a 404, or to a domain somebody else owns. When the backend publishes a link it
is shared; when it does not, the text goes alone and still says where it came
from.

Only public content is ever built into a share. Nothing personal has a field on
the type, and `toString` is redacted.

Outcomes are four, not two:

| Outcome | What the resident sees |
| --- | --- |
| `shared` | nothing — it worked |
| `dismissed` | nothing — backing out is a choice, not a failure |
| `copiedToClipboard` | "Copied. You can paste this into any app." |
| `unavailable` | "Sharing is not available on this device." |

`PlatformShareService` wraps `share_plus` and **degrades rather than throws**: no
sheet, an unregistered channel, or an OS refusal all fall back to copying, which
is a real way to pass an advisory to a neighbour. A resident forwarding a typhoon
notice should never meet an exception.

`share_plus` is pinned at `^13` rather than `^12`: the older line depends on
`win32 ^5`, which conflicts with `flutter_secure_storage`'s `win32 ^6`.
Downgrading the secure storage was the other resolution and was rejected — that
package holds this app's credential material, and a share sheet is not a reason
to move it backwards.

---

## 7. An unrecognised reaction is shown but not pressable

A reaction kind this build does not know is rendered with the server's own raw
label and **cannot be tapped**. Sending a value the app does not understand is
worse than showing that it exists; and hiding it would misrepresent what the post
offers.

Symmetrically, a kind this build knows but the server did not offer is not shown
at all. Neither direction is guessed.

---

## 8. Haptics

A light `selection` haptic on the press of a reaction or the comment button; the
`confirm` haptic fires **only after the server accepted** the comment. Nothing
celebratory happens for something that has not landed.

---

## 9. Tests

`test/features/post_detail_test.dart` — 34 tests.

* capabilities: nothing offered by default; a post with none refuses every
  mutation and renders no control; comments are not even fetched; the shipped
  repository declines every interaction
* reactions: the server's count replaces the guess, including when it disagrees;
  a failure restores the prior state exactly; tapping again clears; switching
  does not change the total; an absent count is not invented; each attempt
  carries a key
* comments: a failed post replays one key; a success retires it and moves the
  count; an empty comment is not sent; a refused delete restores the comment;
  a comment that is not mine cannot be deleted; a hidden comment is kept and
  marked; reporting asks without acting
* guest gating: reacting and commenting both meet the gate, hold the right
  intent, and call nothing; a guest still reads the post and its comments
* sharing: the server's link is shared; no link is invented when there is none;
  the clipboard fallback is explained; dismissing says nothing; the content type
  redacts itself
* screen: official replies distinguished by word; hidden comments withheld; an
  unrecognised reaction is unpressable; delete only on own comment; a failed
  comment keeps its text; no moderation control; a missing post; 200% text scale
