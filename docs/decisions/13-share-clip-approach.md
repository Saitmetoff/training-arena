# 13 — Share clip approach (C07 spike)

Date: 2026-09-23 · Phase 1 spike only; no app code, no dependency, no asset.
Owner decision required before Phase 2.

## Question

How should Training Arena produce a truthful vertical clip for sharing? The
category's growth engine is exactly that (analysis §3), and today the app can
share only a static result card plus a challenge link.

## Constraints (binding)

- Camera frames must not leave the device without an explicit, inventoried
  user-initiated export (`docs/privacy/DATA_INVENTORY.md`; Play Data Safety).
- No fabricated counts, scores or outcomes; no compositing that invents UI.
- The share path stays inside the existing sharing flow and its
  `ARENA_FEATURE_RESULT_SHARING` gate; no parallel share entry.
- **The pilot ships with camera counting off (R1).** There is no honest
  motion content to record yet: a clip of a camera-off build would either be
  static or fabricated.

## Options

| Option | Shape | Privacy delta | Effort / risk |
| --- | --- | --- | --- |
| A. MediaProjection screen recording | Record the live round screen natively | **High**: whatever is on screen is recorded to a local file, including the camera preview if visible; the file is then shared. Requires a consent screen, an inventory entry, Data Safety review and a retention rule | Medium–high, Android-native + bridge; per-session system prompt |
| B. Flutter frame capture + encoder dependency | Compose frames in Dart and encode | Same camera-image export as A when the camera is visible; plus a codec dependency (`ffmpeg_kit` is discontinued; alternatives are heavy or unmaintained) | High, dependency risk |
| C. Tool/server-rendered clip from receipt data | Render a clip server-side from the confirmed score timeline | No camera imagery at all; but it is a server feature and needs hosting (R2/R3 blocked) | High; weak hook without the person |
| D. Static card only (status quo) | Keep the existing share card + QR + link | None | Zero; already shipped |

## Recommendation

**D now. Revisit A only after R1 flips camera counting on, with an explicit
inventory and consent decision. Reject B and C for this cycle.**

Reasons: with camera counting off there is nothing honest to record (C07's
own red line); B's encoder path is a dependency trap for a Flutter app; C is
blocked on hosting and produces the weakest hook. The static card already
carries the challenge link, which is the product's actual growth mechanic
(a real battle between two people).

## What Phase 2 would require (only if the owner approves A)

1. An inventory entry for "user-initiated clip export" and a Data Safety
   answer update, before any code.
2. A consent screen naming exactly what is recorded and where it goes.
3. `ARENA_FEATURE_SHARE_CLIP` flag, release-hold entry and a tested refusal
   path when off.
4. Fixture test: overlay values in the clip match the session exactly; no
   fabricated values.
5. The recording must be optional and never automatic.

## Owner decision

- [ ] Accept D (recommended) — no clip work this cycle.
- [ ] Approve A — open a Phase 2 task with the inventory decision first.
- [ ] Other:
