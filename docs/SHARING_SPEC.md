# Training Arena sharing specification

Owner: task `09` (result sharing). Version 1.0.0 · 2026-09-18.
This document fixes result-card copy, artwork geometry, challenge-URL
semantics, privacy rules and analytics events. Code lives in
`app/lib/sharing/`; the renderer consumes `design/arena/` tokens and the
receipt contract from `docs/API.md` (task `04`).

## 1. Scope and non-negotiables

Result sharing turns one immutable, server-confirmed receipt into an
invitation for a **new live casual battle**. It must never:

- change match scoring or camera counting;
- invent a score, winner, rating or result;
- upload camera frames, avatars or any device media;
- make the challenge link replay the old match, compare old scores
  asynchronously, promise an immediate rematch, or act as a referral.

A result card can be produced only from a `ResultReceipt` returned by the
arena backend with the match closed (`ArenaMatchStatus.finished` or
`no_result`, one receipt per match). A receipt-less or local match, and the
preview fixtures, cannot be shared as a confirmed outcome.

## 2. Receipt validation (fail closed)

`validateResultReceipt` runs before any card exists and throws a factual
`ResultShareException` when the data cannot be server-confirmed:

| Rule | Refusal code |
| --- | --- |
| Exactly two player lines | `invalid_receipt` |
| The signed-in viewer is one of them | `viewer_not_in_receipt` |
| Scores are not negative | `invalid_receipt` |
| `win` has a `winner_id` that is one of the players and a strictly higher score | `invalid_receipt` |
| `draw` has no winner and equal scores | `invalid_receipt` |
| `no_result` has no winner and exposes no scores | `invalid_receipt` |
| The owner chose a username | `username_required` |
| The account snapshot carries a non-empty link token | `link_unavailable` |
| The built URL parses as `https://<host>/c/<token>` on the configured host | `invalid_link` |

`ConfirmedResultShareCard` has a private constructor and is created only by
`confirmResultShareCard`. `PreviewResultShareCard` is review/test artwork and
is rejected by the share service boundary (it is not a `ConfirmedResultShareCard`).

## 3. Perspective and copy

The sharer is always the left, lime (`#D6FF3F`) player; the opponent is
always the right, violet (`#BEA1FF`) player. Headlines are perspective-aware
and factual; the fixed words are uppercase and the `@username` keeps its
exact case so identity stays readable.

| Receipt outcome | Headline | Caption (image share + text share) |
| --- | --- | --- |
| Viewer wins | `I BEAT @zuhra BY 3` | `I beat @zuhra by 3 in a 60-second Push-ups battle. New live challenge: <url>` |
| Viewer loses | `@zuhra BEAT ME BY 3` | `@zuhra beat me by 3 in a 60-second Push-ups battle. New live challenge: <url>` |
| Draw | `DRAW` (scores in the panels) | `@zuhra and I drew 24–24 in a 60-second Push-ups battle. New live challenge: <url>` |
| No result | `NO RESULT` | `No result in our 60-second Push-ups battle, so no rating changed. New live challenge: <url>` |

Identity fallback: a receipt snapshot without a username shows the contract
fallback `Arena athlete`; the CTA becomes `CHALLENGE OPPONENT`. No handle is
ever invented.

Mode copy:

- casual: `Casual · rating unchanged` (never implies a rating change);
- ranked with confirmed numbers: `Ranked · rating confirmed`, and each panel
  prints the receipt's `rating_after` plus its signed `rating_change`;
- ranked no-result: `Ranked · no rating change`.

Duration and exercise always read `Push-ups · 60 seconds` or
`Squats · 60 seconds`; the exercise is the server-selected receipt value.

Honesty notes render inside the artwork:

- confirmed: `New live challenge. It never replays this match or compares old
  scores. Opening the link is read-only until your friend accepts.`
- preview fixture: `Simulated fixture for design review. It is not a live
  challenge and cannot be shared.`

CTA: `CHALLENGE @zuhra` in a lime block with `playerInk` text. It is **painted
artwork**, not a link or a button; the share sheet is only opened from real
preview buttons.

## 4. Card geometry and safe area

Exports are exact: **1080×1920** (stories, 9:16) and **1080×1350** (feed,
4:5). Layout is logical at 540 wide with a fixed export density
`pixelRatio = 2`; multiply every logical value by 2 for export pixels.

All mandatory content — kicker, headline, both identity/score panels, meta
chips, CTA, URL, short code, QR and the honesty note — stays inside the
central safe area. Nothing mandatory may enter the outer band, and raw camera
frames are excluded by construction (the renderer only paints token surfaces
and receipt text).

| Format | Logical size | Safe insets (logical) | Content rect (logical) | Content rect (export px) |
| --- | --- | --- | --- | --- |
| Stories | 540×960 | 54 left / 156 top / 54 right / 180 bottom | 432×624 | LTRB 108, 312, 972, 1560 (864×1248) |
| Feed | 540×675 | 43 / 68 / 43 / 81 | 454×526 | LTRB 86, 136, 994, 1188 (908×1052) |

Fixed block heights (logical) guarantee the export cannot overflow or clip
mandatory facts; text blocks that need more room scale down inside their
allocated height with `FittedBox(scaleDown)`:

| Block | Stories | Feed |
| --- | --- | --- |
| Kicker | 16 | 16 |
| Headline (single line, auto-shrink) | 72 | 48 |
| Score row (two panels) | 200 | 184 |
| Meta chips | 32 | 30 |
| CTA | 64 | 52 |
| Link + QR footer | 132 | 104 |
| Honesty note (max two lines) | 44 | 38 |
| Total fixed | 560 ≤ 624 | 472 ≤ 526 |

The remaining space is distributed between blocks
(`MainAxisAlignment.spaceBetween`), which keeps the composition balanced on
both formats without moving content outside the safe area.

Card colour and type come only from `ArenaColors`, `ArenaBattleText` and
`ArenaBattleSpace` (design tokens): charcoal canvas, graphite/raised blocks,
lime for the sharer, violet for the opponent, `score` 52/900 with tabular
figures, `h1` 34/800 headline, micro kickers. No gradients, shadows, extra
accents or decorative shapes.

Avatars come only from an explicit `avatarImages` map keyed by profile id
(the receipt snapshot). Missing or failed images fall back to a two-letter
monogram. The renderer never loads a network image, so exports are
deterministic and no remote content can leak into artwork.

## 5. QR and short URL

The QR and the visible link are the same real URL
`https://<ARENA_LINK_HOST>/c/<token>`.

- Generation: `ResultShareQr.fromUrl` validates the URL with `ChallengeLink`
  (https, `/c/`, 6–32 alphanumeric token, expected host) and encodes it with
  error-correction level M. The same URL always produces the same matrix.
- Artwork: white (`softWhite`) tile, charcoal modules, four-module quiet zone
  (ISO/IEC 18004) on the perimeter. Failure to build a matrix shows a factual
  `QR unavailable` tile instead of inventing data.
- Accessible text: the QR block is announced as `QR code that opens the live
  challenge <url>`; the URL and the readable short code (`AB12-CD34-EF56`) are
  printed next to it.
- Copy text: `Copy challenge link` writes exactly the URL to the clipboard.
  A snackbar repeats the readable code for spoken sharing.

## 6. Challenge URL semantics

- The URL identifies the **sharer's durable link** (`docs/API.md` link
  object). It is not a match id and carries no score or result.
- Opening it is **read-only** until the recipient explicitly sends/accepts a
  challenge; nothing is created by opening or previewing the card.
- A link stays valid until rotated, revoked or the account is deleted; a
  username change never breaks it. Rotation invalidates the previous token.
- Offline handling: the URL is built from an already confirmed account
  snapshot when one is available (for example the one prefetched by the
  battle flow), so a link that was confirmed once works offline. When no
  snapshot exists, the preview shows `Your challenge link could not be
  loaded. Reconnect and try again.` and offers `Try again`; it never
  generates a local token.
- Destination apps that strip captions still receive the URL, code and QR in
  the image; `System share` additionally sends the caption and link as text.

## 7. Preview and share UX

`Share challenge` on the confirmed result opens `ResultSharePreviewPage`,
which renders the exact `ResultShareCardView` (the same widget that is
exported) inside a `RepaintBoundary`. Only after the preview exists can the
PNG be captured; capture without a mounted preview fails with
`preview_required`.

The preview offers three separate actions:

| Action | Behaviour |
| --- | --- |
| `Share challenge` | Captures the exact card at the selected format (1080×1920 or 1080×1350), then opens the system sheet with the PNG and the caption |
| `Copy challenge link` | Copies the real URL; never opens a share sheet |
| `System share` | Opens the system sheet with the caption and link only, no image |

The format toggle names both exact sizes (`Stories 9:16 1080×1920`,
`Feed 4:5 1080×1350`). The preview always shows the honesty banner before the
card and the caption-stripping note under the actions.

## 8. Edge cases

| Situation | Behaviour |
| --- | --- |
| Missing avatar / avatar URL | Two-letter monogram from the receipt snapshot; no network fetch |
| User renamed after the match | Card keeps the immutable receipt snapshot name; the preview notes identity snapshots |
| User deleted after the match | The card still renders the receipt snapshot; the sharer's link validity is governed by the sharer's account, and the backend reports revoked links as `link_unavailable` |
| No-result receipt | `NO RESULT`, no score digits (`—` / `no confirmed score`), no rating line, CTA still invites a new live battle |
| Offline URL creation | Prefetched confirmed snapshot works offline; otherwise factual error with retry, never an invented link |
| Malformed / winner-less / score-contradicting receipt | Refused before any artwork or sheet, with the factual message |
| Destination strips captions | Image carries CTA, URL, code and QR; `System share` is the text fallback |
| Share sheet fails to open | Preview stays visible with `The share sheet could not be opened...`; nothing is claimed as shared |
| Preview fixtures | Labelled `SIMULATED FIXTURE`, render/export only, rejected by the share service |

## 9. Privacy

- Camera frames never reach the sharing feature; the exporter paints only
  token surfaces, receipt text, avatars from the receipt snapshot and the QR
  matrix.
- No image is uploaded by the app: export happens on-device and the system
  share sheet owns any transfer the user chooses.
- The clipboard receives exactly the challenge URL.
- Analytics properties are allow-listed to `mode`, `outcome`, `format`,
  `source` and refusal `reason`. Usernames, user ids, tokens, URLs, scores,
  receipt ids and avatars are never sent.
- `result_share_blocked` records only a client reason code
  (`unconfirmed`/`invalid_receipt`/...) for refused shares.

## 10. Analytics events

Recorded through the documented `analytics` action and best effort (a failed
analytics call never blocks a share). A share-sheet opening is **not** a
referral; no recipient profile exists until a recipient accepts.

| Event | When | Properties |
| --- | --- | --- |
| `result_share_preview_opened` | Exact-card preview finished loading | `mode`, `outcome`, `format` |
| `result_share_card_exported` | PNG captured for sharing | `mode`, `outcome`, `format` |
| `result_share_sheet_opened` | Image share sheet opened successfully | `mode`, `outcome`, `format` |
| `result_share_link_copied` | URL copied to the clipboard | `mode`, `outcome` |
| `result_share_system_share_opened` | Text-only system share opened | `mode`, `outcome` |
| `result_share_blocked` | A share was refused before artwork | `source`, `reason` |
| `result_share_image_failed` | Capture or sheet opening failed | `mode`, `outcome`, `format` |

## 11. Configuration and flag

- `ARENA_FEATURE_RESULT_SHARING` (default `false`) switches the preview-first
  sharer on in `ArenaApp`. When off, result invites keep the task `05`
  text-only share path.
- `ARENA_LINK_HOST` supplies the HTTPS host; until the owner supplies the real
  domain it remains `example.invalid`, and the card shows exactly that
  configured host. `ChallengeLink` rejects foreign hosts.
- `ARENA_PUBLIC_URL` remains the public site URL; it is not used for the
  challenge link.

## 12. Verification map

| Requirement | Test |
| --- | --- |
| Perspective headlines, scores, exercise, duration, CTA, code | `test/sharing/result_share_models_test.dart`, `result_share_card_view_test.dart` |
| Ranked rating only for ranked; casual claims nothing | model and renderer tests |
| No-result renders no scores or rating | model, renderer and preview tests |
| Unconfirmed/local results cannot be shared | `result_share_challenge_sharer_test.dart` (receipt-less local match), model validation tests |
| Exact 1080×1920 / 1080×1350 exports and determinism | `result_share_export_test.dart` (PNG header + byte equality) |
| Safe area containment for all mandatory blocks | `result_share_card_view_test.dart` |
| QR validates and encodes the same URL | `result_share_qr_test.dart` |
| Preview-before-sheet, three actions, offline and caption-stripping | `result_share_preview_test.dart` |
| Fixtures for win, loss, draw, ranked, casual, no-result | `result_share_models_test.dart` (fixtures group) |
