# Taytay resident mobile — Home

What a resident sees first, what changes with their access level, and what Home
deliberately refuses to show.

Implemented in `lib/features/home/` and `lib/shared/widgets/home_hero.dart`,
`next_action_card.dart`.

---

## 1. One identity, three emphases

| Section | Guest | Unverified | Verified |
| --- | :---: | :---: | :---: |
| Hero | ✅ | ✅ | ✅ |
| Next action | invitation | verification status | verification / ID |
| Your requests | — | — | ✅ |
| Municipal services | ✅ | ✅ | ✅ |
| Latest from Taytay LGU | ✅ | ✅ | ✅ |
| Coming up in Taytay | ✅ | ✅ | ✅ |
| Taytay Municipal Hall | ✅ | ✅ | ✅ |

The hero, the catalogue, the announcements and the events are the same for
everyone, in the same order. What changes is the single next-action card near the
top — and, for a verified resident, a summary of their own requests placed
**above** the public content, because what the LGU needs *from them* outranks
what the LGU is telling everyone.

The layout is declared as data in `HomeEmphasis`, not as `if` statements in a
build method. Home is the one screen whose contents differ by access level, which
makes it the screen most likely to show something to the wrong person; expressing
it as a list means a test can assert what a guest's Home contains — and, more to
the point, what it does not — without pumping a widget and reading pixels.

---

## 2. Guest Home is useful without signing up — acceptance 2

A guest gets a welcome hero, the real service catalogue, public announcements and
events, and the municipal hall. Nothing on the screen is a locked door.

**The sign-in invitation is present but not coercive.** It is one card among
several, it says what an account is *for* rather than what the reader is missing,
it offers "Just browsing" beside "Sign in", it is not a modal, it does not repeat,
and nothing else on Home is behind it. A government service that nags is a
government service people stop opening — and the residents most likely to be put
off are the ones least able to complete a registration.

---

## 3. A guest reads nothing personal — acceptance 3

The guarantee is stated in its strongest form: **not "nothing was shown" but
"nothing was ever fetched"**. A guest's Home issues no `/me/` request at all, so
there is nothing to leak into a screenshot, a log, a crash report or a cache.

Three layers hold it:

1. `HomeEmphasis` marks personal sections, and a guest's emphasis contains none.
2. Every personal read is additionally gated on `CapabilityService.canOpen` — the
   same evaluation the router and every tile use (TAB 10). Reading `/me/` data is
   exactly the operation that must not depend on being reached only by the right
   caller.
3. Tests use counting repositories and assert `listCalls == 0` and
   `statusCalls == 0` for a guest, then scan the rendered text for personal
   wording. Signing out is tested to remove personal content in the same frame.

The only personal value Home ever renders is the greeting name, which is a first
name the server supplied and the only such field the session holds.

---

## 4. It is not a dashboard

**No counts. No percentages. No progress rings. No turnaround promises.**

This app has no authoritative source for "3 pending", "2 unread" or "60%
complete". A count would have to be derived from a page of results — which is a
page, not a total — and a completion percentage would have to be derived from a
draft the app deliberately does not persist. A fabricated figure on a government
service is worse than an absent one, because a resident acts on it.

Enforced by tests that scan Home's rendered text for `N pending/new/unread`, for
`%`, for `N days/weeks`, and for "guarantee"; and by a source scan asserting no
file in `lib/features/home/` constructs an `Announcement`, an `LguEvent` or a
`ServiceRequest` — sample announcements on a municipal app are a fabricated
statement by a local government, and a sample event sends people to a hall on a
date that was never announced.

Every card describes a **state and a step**.

---

## 5. Missing content is absent, not apologetic

The rule that distinguishes Home from every other screen:

| | Destination screen | Home section |
| --- | --- | --- |
| Backend unavailable | explains, offers the hall | **renders nothing** |

A resident who opens the News tab chose to, and deserves an explanation. A
summary screen made of apologies answers "what can I do now?" with a shrug.

What **never** disappears is the hero, the service catalogue and the municipal
hall — so Home is always worth opening, even with every planned module absent.
That is why the catalogue section keeps its card when the list is empty, pointing
at the Services destination, rather than vanishing with the rest.

---

## 6. What was withheld, and why

| Asked for | Status | Reason |
| --- | --- | --- |
| Saved / in-progress onboarding context | **omitted** | The registration draft is held in memory only and dies with the process (TAB 07, a deliberate privacy decision). There is no authoritative, privacy-safe source to summarise, and deriving "you are 60% done" from a widget's local state would be a fabricated claim about a resident's application. |
| Upcoming **registered** events | **omitted** | The endpoint matrix has no event-registration row. A list captioned "yours" built from anything else would be a claim this app cannot support. Public upcoming events are shown instead. |
| Notifications preview | **omitted** | `GET /api/v1/me/notifications` is `planned`. Under the Home rule an unavailable section renders nothing, so a preview would be permanently invisible while adding a `/me/` read; it belongs in the TAB that ships the Notification module. |
| Household / family summary | **omitted** | Already withheld in TAB 10 (D-44): the only household row is a staff route. |
| Assistance request cards | **built, capability-gated** | The `/me/assistance-requests` row exists; the repository declines today, so the section is simply absent. |

---

## 7. Craft

**Hero.** A layered soft gradient built from `primary`, `surfaceTint` and
`primary` again, with the middle stop at 55% so the transition happens *behind*
the text block rather than across it. Colour comes from the `ColorScheme`, never
a hard-coded brand gradient, so dark mode and high contrast follow without a
second implementation. Every text child is painted in `onPrimary` and the
gradient uses only colours the theme pairs with it, so no combination of stops
can produce a heading that fails 4.5:1. The painted Taytay horizon sits behind at
16% opacity — texture, not content.

**Motion.** The hero's fade is decorative, so `Motion.reduced` removes it
entirely rather than shortening it. It is the most repeated animation in the app
— every visit to Home — and therefore the one most worth suppressing for someone
with a vestibular disorder. Tested in both directions.

**Cards.** `NextActionCard` has three tones, each with a distinct icon *and*
wording as well as a distinct container colour, so "we need something from you"
and "this is in hand" survive monochrome vision and a greyscale screenshot
(WCAG 2.2 §1.4.1). Actions sit in a `Wrap`, because at 200% text two buttons do
not fit on one line and a clipped action is an action the resident cannot take.
Section headers do the same with their "See all" link.

**States.** Each preview section has a loading state; failure and empty collapse
to the same outcome on Home, by design (§5).

---

## 8. Verification

`dart format` clean · `flutter analyze` clean · **581 tests pass** · debug and
release APKs build.

TAB 11 coverage (24 tests): the emphasis rules — hero, next action and municipal
hall at every level, public order preserved, no personal section for a guest or
an unverified resident, requests ahead of announcements for a verified one, no
section twice; guest Home welcoming, explaining and offering somewhere to go;
the invitation present, declinable and non-modal; public content rendering for a
guest; **zero `/me/` calls for a guest**, no personal wording on screen, and
personal content disappearing the moment a session ends; one step named for an
unverified resident, the ID offered to a verified one, TAB 08's own vocabulary
reused for a flagged status, and exactly one next-action card at every level; no
counts, percentages, progress bars or turnaround promises; no fabricated content
in any Home source file; unavailable sections disappearing while the hero,
catalogue and hall remain; 200% text scale; a wide surface beside the rail; and
the hero animating only when motion is allowed.

Eight pre-existing tests asserted the previous Home's tile list. They were
**updated, not deleted** — the gate behaviour they cover is unchanged; only the
path a resident takes to reach it moved to the Profile destination.

Two defects were found while building: scattered `AccessLevel` comparisons in the
new Home code (caught by TAB 10's own scan, fixed by routing through
`CapabilityService`), and a verified resident being offered "Check my status"
instead of their digital ID.

---

## 9. Gaps

| # | Gap | Effect |
| --- | --- | --- |
| H-1 | Announcements and events endpoints are `planned` | Both preview sections are invisible today. Home still shows the hero, catalogue and hall. |
| H-2 | Assistance-request endpoints are `planned` | The requests section is invisible for a verified resident. |
| H-3 | No notifications preview | Deferred to the Notification module — see §6. |
| H-4 | No saved-draft or onboarding-progress card | No authoritative source exists — see §6. |
| H-5 | Service shortcuts open the catalogue, not a detail screen | There is no per-service route yet; the catalogue is one tap away. |
| H-6 | No pull-to-refresh on Home | Each section loads once per mount. Switching branches and back re-uses the loaded state, which is correct for a summary but means new announcements need a tab change. |
| H-7 | English only | Filipino copy arrives with app-wide localisation. |
