# Taytay resident mobile — the resident newsfeed

Municipal announcements (`balita`) as a feed a guest can read, and the rules that
keep an app which only *consumes* from behaving like one that publishes.

Implemented in `lib/features/news/` — `domain/announcement_repository.dart`,
`presentation/news_feed_controller.dart`, `presentation/news_screen.dart`.

---

## 1. Public, and deliberately so

`GET /api/v1/announcements` is public by contract, and the feed follows. What a
local government publishes to its residents is the last thing that should sit
behind a sign-in wall: **the people most likely to lack an account are the people
most likely to need a typhoon advisory.**

A guest reads the whole feed and every post. Nothing on this screen asks them to
register, and a test asserts no sign-in prompt appears anywhere on it.

---

## 2. Only published posts appear — and the asymmetry that decides it

`Announcement.isResidentVisible` is applied once, in the controller, so no card
can render a post the office marked as not for residents.

| Publication state | Shown? |
| --- | --- |
| `published` | yes |
| `draft`, `scheduled`, `archived` | **no** |
| unrecognised | **yes** |
| absent | yes |

The last two rows are the interesting ones, and they are the opposite default to
`ResidentRequirement.acceptsUpload`, which fails closed on an unknown status.

* **Unknown fails open** because the server chose to send the post, and hiding
  unknown states would turn one backend change into a blank feed on every
  unpatched phone — during exactly the kind of event that makes a municipality
  add a new publication state.
* **Known non-public fails closed** because there the app knows what it was told,
  and displaying a withdrawn typhoon advisory as current is worse than a gap.

The general rule: **fail closed when acting on a record, fail open when
displaying public content the server deliberately sent.**

---

## 3. An absent count is not a zero

`AnnouncementEngagement` carries three nullable counts, and absent renders as
*nothing* rather than `0`.

"0 comments" is a claim — it says the office counted and found none. When the
backend has not sent a number the app has not been told anything, and printing a
zero invents a fact. On a municipal advisory that matters: an empty comment count
reads as "nobody else is affected".

---

## 4. The end of the feed is the server's answer

`hasMore` comes from the pagination envelope, never from "this page was shorter
than `perPage`". A page can be short *because posts on it were filtered out here*
— which would make a short-page heuristic stop the feed early and hide
everything after a single archived post.

Pagination is prefetched 600px before the bottom so an image-heavy feed does not
stall at the end of every page.

---

## 5. A page failure keeps what has already been read

Losing signal at post forty must not empty the screen somebody was reading. A
first-page failure and a later-page failure are separate fields:

* **First page fails** → a full-surface error, distinct from the empty state.
* **A later page fails** → a footer banner with a retry, and every post already
  loaded stays exactly where it was.

"Taytay LGU has published nothing" and "we could not reach Taytay LGU" are
different sentences with different icons, and during an emergency the difference
is the whole point.

---

## 6. Pinned and advisory emphasis

Pinned posts lift to the top of the list, **stably** — two pinned posts keep the
order the office published them in, and the app never re-sorts anything else. The
office decides the order; the app only honours the pin.

Emphasis is a word as well as a colour: *Emergency advisory*, *Advisory*, or
*Pinned by Taytay LGU*. An advisory level this build does not recognise falls
back to the pinned treatment rather than being dropped or guessed at.

---

## 7. The preview is the office's, not the app's

`preview` is the office's `summary` when it wrote one, and the **full body**
otherwise. It is never machine-truncated at the model level, because a truncated
first paragraph of an emergency advisory can cut off the half that says what to
do. The card clamps to three lines visually; the text underneath is complete.

---

## 8. Remote media

* **Space is reserved before the bytes arrive**, from the width and height the
  server sends. Without them an image-heavy feed reflows as each picture lands,
  which moves whatever is under the resident's thumb. Missing dimensions fall
  back to 16:9 — one card reflowing, not the whole list.
* **A broken image never takes the post down.** `errorBuilder` renders a
  placeholder; the words are the part that matters in an advisory.
* **Alt text is the LGU's or nothing.** When the office wrote one it becomes the
  semantic label; when it did not, the image is excluded from semantics rather
  than given a description this app invented for a picture it cannot see.
* The first load shows **card-shaped skeletons**, so the feed does not jump from
  a centred spinner to a dense list, and a slow connection shows the shape of
  what is coming.

---

## 9. This app consumes; it never publishes

No compose control, no schedule, no pin, no archive, no moderation — and no
repository method that could express one. Those are admin-console actions.

**Interactions arrive in TAB 20.** This screen renders the counts the office
publishes and offers no like or comment control at all. A disabled one would be
an advertisement for a feature that does not exist yet, and native share belongs
with the post detail where TAB 20 places it.

A test scans the rendered feed for admin *controls* rather than for words —
resident copy legitimately says "Taytay LGU has published", and a word-match on
"publish" flags that while catching no actual affordance.

---

## 10. Tests

`test/features/news_feed_test.dart` — 30 tests.

* visibility: published shown; draft/scheduled/archived hidden; unrecognised and
  absent shown
* preview falls back to the body; advisory levels; media aspect ratio only with
  both dimensions; engagement knows when nothing was sent
* the shipped repository declines rather than inventing news
* controller: non-visible posts never reach the screen; pinned lifts stably; load
  more appends; the end of the feed comes from the server not a short page; a
  page failure keeps the pages read; a first-page failure is distinct from empty;
  refresh discards rather than appends; load more stops when the server says stop
* screen: a guest reads without signing in; failure and empty say different
  things; an emergency advisory is named; a pinned post is labelled; counts
  appear only when published; the byline names office, category and date; the end
  of the feed is stated; tapping opens the post; a broken cover image does not
  take the post down; no publishing control exists; 200% text scale
