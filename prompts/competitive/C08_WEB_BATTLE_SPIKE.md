# C08 — Web battle spike (throwaway, no production changes)

Status 2026-09-23: **phase 1 done as a paper spike; no device measurement was
possible in this session.** `docs/decisions/14-web-battle-approach.md`
recommends keeping the web as the accept/install funnel. Record:
`qa/competitive/c08/REPORT.md`.

Depends on: nothing. Estimate: 6–12 h.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `prototype` — this is a throwaway to answer one question, not a feature.
- `research` — current browser pose-detection options and their real bundle
  sizes and device support; label claims `[V]`/`[E]`/`[I]`.

## Goal

The leader's own reviewers ask for Android↔iOS cross-play (analysis §2), and
Training Arena's only current answer is "install the app". `challenge-web/` is
a dependency-free static landing. Before anyone commits to a browser battle,
answer: can a challenged friend without the app complete a fair round in the
browser, and at what cost?

## The question, precisely

1. Can on-device pose counting run acceptably in a mobile browser
   (MediaPipe Tasks for Web, TensorFlow.js MoveNet, or equivalent)? Measure on
   a real mid-range Android phone if one is available; otherwise say so and
   mark the result unverified.
2. What is the delivered cost: model download size, first-load time, battery
   and CPU behaviour during a 60-second round?
3. iOS Safari specifically: does it work there? If it cannot be tested, the
   spike says "unknown", not "supported".
4. Permissions and privacy: camera permission in-browser, no frame upload,
   and what the privacy inventory and store Data Safety answers would need to
   change.
5. The fallback shape: if browser counting is not viable, is a manual or
   self-reported browser round worth anything, or is the honest answer
   "watch-only + install"? Say which.

## Deliverable

- One throwaway prototype under `qa/competitive/c08/spike/` (standalone HTML
  and assets; no accounts, no backend calls, no production files). It may
  count reps from the camera on the test device, nothing else.
- One decision record `docs/decisions/<next-free-number>-web-battle.md` with
  measurements, the go/no-go recommendation, the rejected options and the
  privacy delta.
- No changes to `challenge-web/` in this task.

## Must not

- Touch `challenge-web/`, the app, the backend or CI.
- Add a dependency to any production package file.
- Claim iOS, low-end or cross-device support that was not measured.
- Upload or retain any camera frame; the spike runs locally and says so.

## Acceptance

- The decision record answers all five questions, each with its evidence tier
  and the exact measurement or a stated unknown.
- The prototype runs locally from a file (no build step, no network) and its
  README states what was measured, on what device, and what was not.
- `git diff` shows no production file changed.
- A clear recommendation: build, defer or reject — with the one measurement
  that would change the answer.

## Handoff

Standard handoff, plus the measured numbers and the device used.
