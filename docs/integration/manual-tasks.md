# Master manual-task list

**Everything here needs a person, not a commit.** A decision only the LGU can
make, credential material an agent must never hold, an organisational
appointment, or a fact about a deployment nobody has told this repository.

**Nothing implementable appears on this list.** If a finding can be closed by
writing code, it is not here — it is in `backend-baseline.md` with an owner and
gets closed by work, not by asking. This list exists so that the things which
*cannot* be closed that way are in one place instead of scattered through
twenty-five TAB reports.

Ordered by lead time, longest first, because the long ones decide the launch
date and the short ones do not.

---

## 1. Appoint a Data Protection Officer and adopt a retention schedule

**Owner: LGU. Blocks: launch, and the specification of F13.**

RA 10173 requires a designated DPO for a public-sector personal information
controller, and the privacy notice this app ships names an office that does not
yet exist. The retention schedule is the harder half: **F13 cannot even be
specified without it**, because an in-app account deletion path has to say what
is erased and what is kept — and a municipal record cannot always simply be
erased. Both stores require the deletion path, so this is on the critical path
to submission, not after it.

## 2. Custody of the release signing keys — F03

**Owner: LGU. Blocks: any releasable artifact at all.**

The Android release keystore and the Apple signing identity must be generated
and held by the municipality, not by a contractor and not by this repository.
`android/app/build.gradle.kts` reads them from `key.properties` and **has no
debug fallback**, so a release build fails loudly rather than shipping something
signed with a throwaway key — which is the correct behaviour and also means
there is no artifact until somebody does this.

An agent must never generate, hold or rotate these. Losing the Android keystore
means the app can never be updated under the same listing again.

## 3. Store accounts and listings

**Owner: LGU. Blocks: submission.**

A Google Play developer account and an Apple Developer Program membership under
the municipality's own identity, plus the listing itself: description,
screenshots, support contact, and the privacy declarations — which must match
what `PrivacyInfo.xcprivacy` and the data-safety form actually say. See
`store-readiness.md` for what the app already declares.

## 4. Is onboarding staff-mediated? — F15

**Owner: LGU, with the backend owner. Blocks: a P0 either way.**

There is no route by which a resident can create their own account. Citizen
accounts are created by staff on the admin console and bound to a login there.
This app ships a seven-field self-registration wizard with no server counterpart.

Two answers, and they lead to opposite work:

* **Yes, staff-mediated.** The wizard is deleted, and the app's entry point
  becomes "sign in with the number the office registered". Honest, and matches
  what the platform does today.
* **No, residents self-enrol.** The backend needs a self-registration route,
  and the LGU needs a policy for identity assurance at enrolment.

Nobody can pick this from the code. It is what the municipality intends the
service to be.

## 5. The deployed proxy's body limit — F25

**Owner: whoever operates the deployment.**

The app refuses uploads over **8 MB client-side, and that number is a guess.** A
body over nginx's `client_max_body_size` is refused by nginx before the
application, so the answer is not the JSON envelope and on some stacks looks
like a dropped connection. Too high and residents meet an unreadable failure
after paying to upload; too low and the app refuses documents the office would
have accepted. Needs the real value from the real deployment.

## 6. A staging environment

**Owner: whoever operates the deployment.**

There is none. Everything proven against a running server in this repository was
proven against the backend booted locally on sqlite — which is real evidence and
is recorded as such in `qa-and-evidence.md`, but it is not the deployment. The
contract harness (`tool/record_fixtures.sh`, `tool/check_fixture_drift.sh`) is
built to point at a staging URL and will work the day one exists.

## 7. Is the newsfeed public in production? — F30

**Owner: LGU.**

`Route::get('newsfeed')` carries no auth middleware, but the controller refuses
an anonymous reader unless `newsfeed.public_access` is on, which defaults off.
Reading the route file says public; calling it returns 401. The app handles both
correctly. What is missing is a statement of which is intended, because it
decides whether municipal announcements are readable by a resident who has not
signed in — the residents least likely to have an account.

## 8. Whose page size wins

**Owner: backend owner.**

`app/bootstrap` publishes `default_page_size: 15` for the `citizen-mobile`
channel. This app clamps and sends its own. Nothing is broken, but a page size
chosen for this channel by the backend is being overridden by a number chosen in
a client, and that should be a decision rather than a silent divergence.

## 9. Confirm the `case` entity — carried from the Master Command

**Owner: backend owner.**

Whether a "case" in `Welfare` and a KYC case in `ResidentProfile` are the same
thing to the office. They are different modules with different lifecycles here,
and the app models them separately; this was raised at TAB 09 and never
answered.

## 10. What each service asks for — F24

**Owner: the office that adjudicates each service.**

There is no per-service intake form on the server, and this app will not
hardcode a question list: that is a form the office never agreed to, collecting
answers nobody reads, discovered wrong the first time a caseworker opens an
application. Somebody in the office has to say what each service asks before the
backend can publish it.

---

## Not on this list, deliberately

**F16** (sign-in codes are never dispatched), **F26** (no content-reporting
route), **F28** (a KYC case has nowhere to put a document) and the
implementation of **F13** once the schedule exists are all code. They are
tracked in `backend-baseline.md` and closed by writing it.
