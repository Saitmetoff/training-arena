# C00 — Owner direction decisions (one ADR, no code)

Depends on: owner marks in `docs/research/NOTES.md`. Estimate: 1–2 h.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `domain-modeling` — use its ADR/glossary conventions for the decision record.
- `to-spec` (optional) — if the owner wants the chosen options turned into a
  spec in the same session.
- `grill-me` (optional, owner-facing) — stress-test the decisions before they
  are recorded.

## Goal

Produce one decision record that lets every later task in this pack proceed
without inventing product scope. Read `docs/research/COMPETITIVE_ANALYSIS.md`
§7 (draft plan) and the owner's marks in `docs/research/NOTES.md` first. List
`docs/decisions/` and take the next free number; do not renumber existing
records.

For each decision below, write: the options, the evidence pointer (analysis ID
and section), the cost and blast radius, the draft recommendation, and a
**default if the owner does not answer** (what the pack does meanwhile).

| ID | Decision | Draft options | Evidence |
| --- | --- | --- | --- |
| D-A | Solo scope: reopen `CONTRACT.md` §1? | (a) full solo mode, (b) max-reps test only, (c) keep the ban | CA-G2, analysis §4/§7 |
| D-B | Name/brand: rename before the listing locks, or keep "Training Arena" | (a) rename now, (b) keep, (c) keep but ASO against "Arena" variants | CA-G8, analysis §1 |
| D-C | First pilot camera scope | (a) sign R1 checklist and enable counting, (b) ship camera-off with no counted round, (c) camera-off plus manual solo only | R1/R7, `GO_NO_GO.md` §2 |
| D-D | Monetization intent | (a) free through validation, (b) design annual-first trial funnel now for a later switch-on | analysis §5, CA-G7 |
| D-E | Reps-as-screen-time mechanic | (a) study, (b) ignore, (c) reject | analysis §4 |

Also record explicitly: whether a **manual/self-report entry** is allowed for
solo only (the contract currently bans manual score entry outright), and that
any billing later must use Google Play Billing, never Stripe, for digital
goods.

## Owned paths

`docs/decisions/<next-number>-competitive-direction.md` (new). Nothing else.

## Must not

- Edit `docs/CONTRACT.md` yourself; the ADR records the decision, and the
  contract amendment is a separate scoped edit after owner approval.
- Edit `docs/research/NOTES.md`.
- Change app, backend or release code. No billing integration.

## Acceptance

- The decision record exists with all five decisions, each with options,
  evidence, recommendation and a stated default.
- Each decision line says exactly what later tasks may assume until the owner
  answers.
- `docs/PROJECT_STATUS.md` gets a dated section naming the record and its
  status (DRAFT/answered).
- No source, config, release gate or test file changed.

## Handoff

Standard handoff. State which decisions are still unanswered and which tasks
are therefore blocked or proceeding on a default.
