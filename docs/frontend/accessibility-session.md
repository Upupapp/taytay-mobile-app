# Accessibility session — TAB 07

**19 August 2026.** What was checked, what was fixed, and — the important half —
**what could not be checked here and must not be reported as if it were.**

---

## The headline

**No screen reader was run.** Not VoiceOver, not TalkBack.

The app was built on a Windows host and closed its 28-TAB build sequence classified
`READY_FOR_HUMAN_REMOTE_AUTHORIZATION` with that session never held. This TAB did not
hold it either, and could not:

| | on this machine |
| --- | --- |
| Physical Android device | **none attached, ever, in this programme** |
| Physical iOS device | **none attached** |
| Android emulator | **no AVD images installed** — `flutter emulators` finds no sources |
| iOS Simulator | present (iPhone 17 / 17 Pro / Air, iPad Pro), and **VoiceOver does not run on it** |

The iOS Simulator can render the app. It cannot speak it. Apple's Accessibility Inspector could
read the tree from a running simulator, but it is a GUI tool driven by a person, and nobody here
can drive it.

**So the criteria that need a screen reader are deferred, listed by name below, and the suite must
not be read as covering them.**

---

## What was checked, and how

Flutter's own accessibility guidelines, run over every core route at **every access level** and in
**both languages**. These are the same rules a reviewer applies by hand, and they test the
semantics tree a screen reader would actually read.

`test/features/screen_reader_audit_test.dart`

| Guideline | What it proves | Result |
| --- | --- | --- |
| `labeledTapTargetGuideline` | every tappable control has a label — the one that matters most, because an unlabelled control is announced as "button" and nothing else | **pass**, 11 routes × 3 levels × 2 languages, plus `/verification` |
| `androidTapTargetGuideline` | 48dp minimum | **pass**, 11 routes × 3 levels |
| `iOSTapTargetGuideline` | 44pt minimum | **pass**, same |
| `textContrastGuideline` | WCAG 2.2 AA by pixel sampling | **not run — see below** |

Both directions were proven: an unlabelled `IconButton` and an undersized `TextButton`, each
planted on the sign-in screen, were caught and then removed.

---

## Finding 1 — the contrast guideline cannot judge this app, and something stronger already does

`textContrastGuideline` samples the pixels inside a semantics node and compares the lightest
against the darkest. This app's primary buttons are a brand gradient with white text, so the sample
is overwhelmingly fill: it reported the two ends of the *gradient* against each other and called a
4.5:1 button **1.06:1**.

Measured, and this is what makes it certain rather than likely: the colours it named were
`#144291` and `#0B3D91`, and **`#0B3D91` is `BrandColors.taytayBlue` exactly**. It never weighed a
white glyph.

**It was not run, and contrast was not weakened to accommodate that.** Contrast on this app is
enforced where it can be *computed* rather than sampled:

* `BrandGradient.worstCaseContrastRatio()` proves the declared foreground against the whole ramp
  **including interpolated midpoints**, not only the endpoints somebody happened to look at;
* the palette tests prove every status colour carries white text at AA;
* `A11y.minBodyContrastRatio` is 4.5 and `minLargeTextContrastRatio` is 3.0, asserted.

All in `test/core/brand_test.dart`. That is a stronger guarantee than pixel sampling, not a weaker
one — which is why the sampling guideline is the thing that was dropped.

---

## Finding 2 — this audit had a hole on its first draft, and a planted defect went undetected

The tap-target and Filipino sweeps originally ran only at `AccessLevel.verified`. `/sign-in` and
`/sign-in-help` are in the route list, and `resolveRedirect` **moves a signed-in resident off
them** — so those two routes booted, were redirected to `/home`, and passed without the screen ever
being rendered.

It was found the only way it could be: a deliberately undersized button was planted on the sign-in
screen and **the audit stayed green**.

Fixed by running every guideline at every access level, so each route is genuinely rendered at the
level where it is reachable and the sweep cannot pass by redirection. The planted defect is caught
now; it was re-planted to confirm.

**This is the second time in this sequence that a check appeared to work and was measuring
nothing** — the first was a red-proof in TAB 05 pointing at a test file that does not exist. Both
are recorded rather than quietly corrected, because the pattern is the finding.

---

## Deferred — needs a person and a device

Nothing below is claimed. Each needs a real handset with a real screen reader.

| Criterion | Why a machine cannot answer it |
| --- | --- |
| **Focus order** | The semantics tree proves labels exist, not the order a rotor walks them. A form that reads bottom-to-top passes every check above. |
| **Announcement wording** | A label can be present, correct, and still read as nonsense aloud — "Button, Sign in, Sign in" is a common shape and no guideline objects. |
| **Live-region timing** | `role="status"` regions are asserted present. Whether an announcement interrupts, queues, or is lost under a screen reader is a runtime behaviour. |
| **Rotor navigation of lists** | Headings, landmarks and list semantics as a person actually traverses them. |
| **Filipino pronunciation** | Whether the Filipino strings are read intelligibly by the platform voices, which is the whole point of shipping them. |
| **Gesture conflicts** | Swipe-to-dismiss and pull-to-refresh against screen-reader gestures. |
| **Real dynamic type** | 200% scale is asserted in `device_adaptation_test.dart` against the framework's scaler, not against the OS setting on hardware. |
| **High-contrast / reduce-motion OS settings** | Honoured in code (`Motion.reduced`), never observed switched on by a system. |

**The single most valuable next step is one hour with a real Android phone and TalkBack**, in
Filipino, walking sign-in → home → KYC claim → upload. That would answer most of the table above,
and none of it can be answered from here.

---

## What this changes about the launch dossier

The dossier's residual-scope section should gain a line: the app's accessibility evidence is
**strong on structure and absent on speech**. Saying "accessible" without that qualifier would be
the same class of claim as the session sheet's *"Nothing you submitted has been lost"* — narrowly
defensible, and read as something it does not say.
