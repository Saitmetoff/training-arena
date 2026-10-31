# C07 — Shareable vertical clip: spike, then implementation

Status 2026-09-23: **phase 1 done.** `docs/decisions/13-share-clip-approach.md`
recommends keeping the static card now; phase 2 (native recording) is
owner-gated and waits on R1 plus an inventory/consent decision. Record:
`qa/competitive/c07/REPORT.md`.

Depends on: C01 for real solo data; the spike decides the implementation.
Estimate: 4 h spike, 16–32 h implementation.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `prototype` — the spike is a throwaway, not production code.
- `export` — format, resolution, framerate and encoding guidance for the
  clip (1080×1920, 30 fps is the established standard in
  `docs/social/CONTENT_EXPERIMENT.md` §3).
- `tdd` — in the implementation phase only.

## Goal

The competitor's growth engine is a vertical clip of a real round with the
count visible (analysis §3). Training Arena has a static result card
(`app/lib/sharing/result_share_card_view.dart`) and nothing shareable as
motion. Phase 1 answers how to produce a truthful clip; phase 2 implements the
chosen option behind a flag.

## Phase 1 — spike (this chat, no production code)

Compare at least these options and report size, permissions, privacy impact
and effort for each:

| Option | Shape | Known concerns |
| --- | --- | --- |
| A | Android MediaProjection screen recording of the live round | per-session consent prompt; records whatever is on screen |
| B | Flutter frame capture + encoder dependency | dependency size, licensing, iOS later |
| C | Tool/server-rendered clip from receipt data (no camera feed) | needs the backend; no personal footage |
| D | Existing result card exported as an image sequence only | simplest, weakest hook |

**Privacy is a first-class constraint, not a footnote.** The current inventory
(`docs/privacy/DATA_INVENTORY.md`) states camera frames stay on-device. A clip
that includes the camera view changes that story and the Play Data Safety
answers. The spike must state for each option whether the person appears in
the export, whether frames ever leave the device, and what inventory/packet
updates the option would require. A clip containing the user is a
user-initiated export and needs explicit consent UI plus inventory changes —
do not assume it is free.

Deliverable: `docs/decisions/<next-free-number>-share-clip-approach.md` with a
recommendation, the rejected options and the exact privacy delta. No app code,
no dependency added, no assets generated from real people.

## Phase 2 — implementation (only if the owner approves the recommendation)

- Implement the chosen option behind `ARENA_FEATURE_SHARE_CLIP` in
  `app/lib/config/arena_config.dart` and the release-flag check list.
- Render from real recorded data only: no fabricated counts, scores or
  outcomes; no compositing that invents UI.
- Fixture-test the renderer: given a known session, the clip's overlay values
  match the session exactly.
- The share path stays inside the existing sharing flow and its gate
  (`ARENA_FEATURE_RESULT_SHARING`); do not add a parallel share entry.

## Owned paths

Spike: `docs/decisions/`, `prototype/` (throwaway only), `qa/competitive/c07/`.
Implementation: `app/lib/sharing/`, config and flag list, tests, docs.

## Must not

- Upload camera frames anywhere, ever; no telemetry on the clip.
- Add a cloud render service.
- Present a clip as proof of accuracy, or label it as verified.
- Publish any clip; that is the L09/content process.

## Acceptance

Phase 1: the decision record exists with the privacy delta per option, a
recommendation and an owner decision line; no app or release code changed.

Phase 2 (separate chat after approval): flag off hides the action with a
tested refusal path; overlay values match fixtures; full suite passes;
evidence under `qa/competitive/c07/`; any inventory change is listed, not
silently made.

## Handoff

Phase 1 returns the decision record path and the recommendation. Phase 2 uses
the standard handoff.
