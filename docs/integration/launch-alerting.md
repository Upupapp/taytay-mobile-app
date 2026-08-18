# Launch alerting thresholds

Defined **before** launch rather than after the first incident, which is the only
time they can be argued about calmly.

Each threshold names what it would mean if it fired, because a number with no
reading attached gets silenced by whoever is on call at 2am.

## The four that matter

| Signal | Threshold | What it would mean |
| --- | --- | --- |
| **Crash-free sessions** | below **99.0%** over 1h | Something ships broken. Below 95% is a halt-the-rollout number, not a ticket. |
| **Sign-in completion** | below **70%** of started flows over 1h | The single most diagnostic number this app has. A fall here separates "nobody is using it" from "nobody can get in", and those have opposite responses. Baseline must be measured in staged rollout before the number is trusted. |
| **Upload success** | below **90%** over 6h | The most failure-prone path. A fall usually means the proxy limit and the client ceiling have drifted apart (F25) — which is a config change, not a code one. |
| **p95 request latency** | above **5s** over 1h | On the connections this app runs over, 5s is where residents start double-tapping and creating duplicate work for the MSWDO. |

## Two the launch cannot use yet

* **Assistance submission rate** — meaningless until residents can sign in
  (F16) and reach the Verified state (F14). Recording it now would establish a
  baseline of zero and then alert on the first real submission.
* **Push delivery** — there is no messaging SDK and no delivery to measure.

## What none of these may contain

No resident identifier, no case identifier, no free-text. Every signal behind
these numbers is a count or a bucketed duration from a sealed enum, and
`test/core/observability_test.dart` fails if a free-text field is added to one.

A `request_id` joins a resident's report to a server log and travels **only** on
the failure the resident is holding — it is per request and must never become a
stable device identifier, which is asserted rather than trusted.

## The gap that makes all of this provisional

Telemetry ships **off**: consent is `notAsked`, the sink reports itself
unavailable, and all 1300-odd tests run in that state. So these thresholds
describe a system nobody has yet seen produce a number. They cannot be tuned
before a staged rollout, and the first one must be treated as calibration rather
than as monitoring.
