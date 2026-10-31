# Interface note 09 — result sharing boundary and preview-first flow

Date: 2026-09-18
Author: task `09` (result sharing)
Status: implemented; `flutter analyze` clean (task-owned paths) and all 411
app tests pass, including 74 task-09 tests

## Why this note exists

`docs/CONTRACT.md` section 8 requires shared changes to be recorded, and
`prompts/README.md` requires each task to report files changed, tests run and
unresolved risks. This note records the task `09` card contract, the additive
shared-path changes needed to wire it, and the exact seam other tasks consume.

Task `09` consumed, and did not modify:

- `design/arena/` token values and component rules (task `01`),
- `ResultReceipt`, `ArenaReceiptPlayer`, `ArenaProfile` (task `00` contract),
- `ChallengeAccountSnapshot`, `ChallengeShareService`,
  `ChallengeAnalyticsSink`, `ChallengeLink` (task `05`),
- `BattleChallengeInvite`, `BattleChallengeSharer` (task `07`).

`D:\Kiro` was not read or modified.

## What this task delivered (owned paths)

- `app/lib/sharing/result_share_models.dart` — export formats, the sealed
  `ResultShareCard` / `ConfirmedResultShareCard` / `PreviewResultShareCard`
  model, receipt validation and the only production factory
  `confirmResultShareCard`.
- `app/lib/sharing/result_share_copy.dart` — exact perspective copy,
  captions, CTA, semantic summary and the honesty notes.
- `app/lib/sharing/result_share_qr.dart` — validated, deterministic QR matrix
  (`qr` package) and the token-painted QR view with URL alt text.
- `app/lib/sharing/result_share_card_view.dart` — the exact renderer for
  1080×1920 and 1080×1350 with fixed-height blocks and the central safe area.
- `app/lib/sharing/result_share_service.dart` — account loading, native share
  adapter (`share_plus`), clipboard adapter, `RepaintBoundary` PNG capture,
  analytics events.
- `app/lib/sharing/result_share_preview.dart` — the exact-card preview page
  and its three separate actions.
- `app/lib/sharing/result_share_challenge_sharer.dart` — the task `07`
  `BattleChallengeSharer` implementation that routes confirmed receipts to the
  preview and everything else to the task `05` text share.
- `app/lib/sharing/fixtures/result_share_fixtures.dart` — win, loss, draw,
  ranked, casual and no-result fixtures, preview-only.
- `app/test/sharing/` — model, QR, renderer, export, preview and adapter
  tests.
- `docs/SHARING_SPEC.md` — the full copy, safe-area, URL, privacy and
  analytics specification.

## Additive shared-path changes (recorded, minimal)

| Path | Change | Why |
| --- | --- | --- |
| `app/pubspec.yaml` | adds `qr: ^3.0.2` (pure Dart) | deterministic QR matrices; already present in the local pub cache |
| `app/lib/battle/runtime/battle_runtime.dart` | `BattleRuntime.fromConfig` gains an optional `BattleChallengeSharer? resultShareSharer`; when supplied it replaces the default sharer, otherwise behaviour is unchanged | task `07` owns the file; the change is additive and keeps `PendingBattleChallengeSharer`/`ChallengeShareServiceSharer` as defaults |
| `app/lib/arena_app.dart` | builds the task `09` sharer in `_resultShareSharer()` and passes it to `fromConfig` only when `ARENA_FEATURE_RESULT_SHARING` is enabled | composition root already owns sharer/service wiring; the text-share fallback is preserved for non-result invites |

No change was made to match scoring, camera capture, the receipt wire shapes,
the challenge-link path, or any other task's UI.

## Fixed interface decisions

1. **Only a confirmed receipt can be shared.** `ConfirmedResultShareCard` has
   a private constructor and is produced only by `confirmResultShareCard`
   after `validateResultReceipt` and a confirmed account link. A receipt-less
   or structurally contradictory result cannot cross the share service
   boundary; `PreviewResultShareCard` is render/export-only.
2. **The URL is a new-challenge identity, never a match reference.** It is
   always `https://<ARENA_LINK_HOST>/c/<token>` for a new live casual battle.
   The card never claims a replay, an immediate rematch, an asynchronous score
   comparison, a chance to beat the old score or a referral.
3. **Preview first.** Tapping `Share challenge` on the result screen opens the
   exact-card preview with an explicit render. The card CTA is painted
   artwork; only the real buttons below it act. The PNG is captured from the
   same `RepaintBoundary` the sharer sees.
4. **Three separate actions.** `Share challenge` (image + caption),
   `Copy challenge link` (URL only) and `System share` (caption + link, no
   image).
5. **Analytics event names** (recorded through the existing `analytics`
   action, best effort): `result_share_preview_opened`,
   `result_share_card_exported`, `result_share_sheet_opened`,
   `result_share_link_copied`, `result_share_system_share_opened`,
   `result_share_blocked`, `result_share_image_failed`. Properties are limited
   to `mode`, `outcome`, `format`, `source` and refusal `reason`; no identity,
   token, URL, score or receipt id.
6. **Two exact exports.** 1080×1920 (stories) and 1080×1350 (feed) at
   `pixelRatio = 2`. `docs/SHARING_SPEC.md` fixes the safe areas and every
   block height.

## Consumption notes

- Task `07`/`00` hosts that build their own runtime can pass any
  `BattleChallengeSharer` via `BattleRuntime.fromConfig(resultShareSharer:)`;
  no other wiring is required.
- `ChallengeShareServiceSharer` remains the fallback for receives without a
  receipt; the `ResultShareChallengeSharer` wraps it and never bypasses it.
- The feature is gated by the existing `ARENA_FEATURE_RESULT_SHARING` flag
  (default off), matching the other feature flags.

## Verification

- `flutter analyze` reports no issues in any task `09` path.
- `flutter test test/sharing` — 74 tests: cards and copy, receipt validation
  (including malformed/winner-less/score-contradicting receipts), QR
  validation and determinism, renderer safe-area containment for both
  formats, exact PNG dimensions and byte-for-byte determinism, preview
  actions, offline/prefetched link behaviour, no-result and missing-avatar
  handling, and the sharer's refusal to open a preview without a receipt.
- `flutter test` — all 411 app tests pass.

## Unresolved risks

- The challenge host remains `example.invalid` until the owner supplies the
  real domain (task `05` decision D1); the card renders that configured host
  and never fabricates one.
- Real system share sheets and gallery exports still need a device pass in
  task `10`; the tests exercise the adapter seam, not the platform UI.
- `qr` encoder output is deterministic for the same URL as long as the
  pinned package version does not change.
