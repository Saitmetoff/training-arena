# C06 — store listing and ASO pass: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

## What changed

`docs/release/PLAY_STORE_PACKET.md` §2 gains three subsections:

- **2.1 Keyword pass** — a target-term table with source and truth
  constraint. Terms come from category search language and the competitor's
  missing keywords (analysis §2); none is repeated for ranking.
- **2.2 Forbidden-claims checklist** — a submission-time checklist mirroring
  the product's truth rules (no accuracy percentage, no "cheat-proof", no
  guarantee, no medical claim, no feature claim for a disabled flag).
- **2.3 Conditional additions** — the solo-set sentence is added only when
  `ARENA_FEATURE_SOLO_MODE=true` ships; the name decision (12 D-B) is
  recorded as "keep, revisit before submission".
- **2.4 Follow-up list** — documents whose copy predates the solo feature.

The listing copy itself (variant A, the only valid variant for the camera-off
artifact) was **not** rewritten: it already names the movements, the
60-second round and the friend challenge truthfully. Variant B stays blocked
behind R1/R13.

## Verification

Docs-only change: no source, test, asset, workflow or release gate touched.
The copy passes the new §2.2 checklist by inspection; variant A makes no
camera-counting, ranked, notification or cross-play claim.

## Deliberately not done

- No store graphics, package name, version or app label changed.
- No Play Console action, submission or purchase.
- No claim was added for a feature that is off in the shipped artifact.
