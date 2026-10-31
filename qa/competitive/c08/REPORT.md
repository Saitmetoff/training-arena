# C08 — web battle spike: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

Deliverable: `docs/decisions/14-web-battle-approach.md`.

## What could and could not be measured

Documented facts were collected with sources: served MediaPipe pose bundle
sizes (~5.8 MB lite / ~9.4 MB full), the WASM+WebGL runtime with Safari 14+
support, and the documented iOS Safari `getUserMedia` regressions in
standalone/PWA mode.

**No device measurement was possible in this session** (no browser/mobile
measurement environment). Model load time, sustained FPS, battery behaviour
and iOS Safari in-app behaviour are explicitly marked as not measured; no
number was invented to fill the gap.

## Outcome

Recommendation: **keep `challenge-web/` as the accept/install funnel** and fix
install-drop-off measurement first. The decisive cost is not the model but the
duplicate counting implementation: a browser battle needs a second copy of the
~500-line Dart rep state machine, and the product's claim to fairness rests on
that one implementation being server-confirmed.

The decision record lists the four open questions a measured spike would have
to answer before a browser battle could be approved.

## Not done (deliberately)

- No change to `challenge-web/`, the app, the backend or CI.
- No dependency added anywhere.
- No prototype file was committed: without measurement it would be a demo,
  not evidence.
