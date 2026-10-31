# L04 instructional-media review packet (R13)

Prepared: 2026-09-20 · Repository: `D:/TrainingArena` · Branch:
`codex/training-arena` · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`)
Review document: `docs/media/FORM_REVIEW.md` · Status: **prepared, unsigned —
no reviewer has reviewed any asset.**

This packet is what the qualified reviewer needs. It does not replace
`docs/media/FORM_REVIEW.md`; the criteria, reviewer requirements and sign-off
procedure are there and remain binding. The reviewer works from the local
repository; nothing is uploaded.

## 1. Reviewer requirement

The reviewer must be able to assess push-up and squat technique — for example a
certified strength coach, physiotherapist or equivalent trainer
(`docs/media/FORM_REVIEW.md` §7). A product reviewer alone may approve copy,
layout and provenance but **not** form accuracy. Do not simulate, pre-fill or
delegate the signature.

## 2. Reviewer kit (open these before judging)

| Artifact | Path |
| --- | --- |
| Same-athlete check | `qa/media/identity_strip.png` |
| Start/mid/end comparison, both exercises | `qa/media/contact_sheet_athlete.png` |
| Annotated fallback posters | `qa/media/contact_sheet_posters.png` |
| Loop key frames | `qa/media/loop_keyframes_pushup.png`, `qa/media/loop_keyframes_squat.png` |
| 360 dp legibility proof | `qa/media/legibility_360dp.png` |
| GLB vs pipeline render | `qa/media/glb_roundtrip_check.png` |
| Machine checks | `qa/media/validation_report.json`, `qa/media/qa_report.json` |
| Joint measurements | `python qa/media/tools/measure_poses.py` |

## 3. Criteria to check

- Push-up criteria P1–P12: `docs/media/FORM_REVIEW.md` §3.
- Squat criteria S1–S12: `docs/media/FORM_REVIEW.md` §4.
- Open questions Q1–Q7 in `docs/media/FORM_REVIEW.md` §8 must be answered in
  the notes or left open; an unanswered question keeps the asset excluded.

## 4. Asset hashes at review time (verified 2026-09-20)

Every file below was verified byte-for-byte against
`app/assets/media/athlete/manifest.json` by the machine gate on 2026-09-20
(`qa/launch/l04/media_prototype_gate.txt`, exit 0). The release gate labels the
same entries as `exercises.<exercise>.assets.<name>`; the table uses the
`hash_table.py` labels. If any file is regenerated these hashes change and the
review restarts.

| Key | Asset | Bytes | SHA-256 |
| --- | --- | --- | --- |
| `models.athlete` | `assets/media/athlete/models/athlete_mannequin_v1.glb` | 173972 | `380f94a0a2f9d199f42c08fd4887864ec4991eee2637cd978c8f67400f3d04f3` |
| `pushups.glb` | `assets/media/athlete/models/athlete_mannequin_v1.glb` | 173972 | `380f94a0a2f9d199f42c08fd4887864ec4991eee2637cd978c8f67400f3d04f3` |
| `pushups.loop_mp4` | `assets/media/athlete/loops/pushup_loop.mp4` | 42538 | `552d982c3ee1fe594ce756cfb89d18cc42214ee53e15ab933de4f1b0eddbd36c` |
| `pushups.loop_webp` | `assets/media/athlete/loops/pushup_loop.webp` | 279918 | `749b23ba1f9df08c25e2bc51c9b55aaa08d5b6646d72c0fc8216cc856ae7407f` |
| `pushups.frame_start` | `assets/media/athlete/frames/pushup_start.webp` | 6794 | `6e3a80e874bfdae70b4f603da93a89eabb2ed61db52918bf574d3fff201c7dc2` |
| `pushups.frame_mid` | `assets/media/athlete/frames/pushup_mid.webp` | 6526 | `a195e81fe557d47dc2afab69b80e02e0e26ad7af92b50ef05dc680ae7233f174` |
| `pushups.frame_end` | `assets/media/athlete/frames/pushup_end.webp` | 6256 | `3f50b71fbd2042d28907db926bbe6208c0ccbab258b059d7492a056cdeaace4e` |
| `pushups.overlay_start` | `assets/media/athlete/overlays/pushup_start.webp` | 6316 | `98f7ef25a4c2bb056cec379c33dfc52cf096ea2fa8cb09fe4a790543d65c17fa` |
| `pushups.overlay_end` | `assets/media/athlete/overlays/pushup_end.webp` | 7350 | `f05c4e51b4089f648d428c61c8253d9974bd064930640ab89c38bea4fbb0964b` |
| `pushups.poster_start` | `assets/media/athlete/posters/pushup_start.webp` | 20168 | `9d0265e369e1098d73eb6e8c1cdace056f2c3d0bd93e97a9338a401b5ffee9a5` |
| `pushups.poster_end` | `assets/media/athlete/posters/pushup_end.webp` | 19846 | `0c8f5cc3bbb0ce1fa6d43247280fa7d26bc2aa2a2d38292c9f2569d7edcbc9eb` |
| `pushups.poster_start_png` | `assets/media/athlete/posters/pushup_start.png` | 69928 | `6685633174a69f0c3c290a8c21dd2ad84ceff57e79602bf598332a3abddc2a04` |
| `pushups.poster_end_png` | `assets/media/athlete/posters/pushup_end.png` | 71963 | `d48d6af703dc764d996457737c95b15894001389120a0ad19e8e1fc736448398` |
| `squats.glb` | `assets/media/athlete/models/athlete_mannequin_v1.glb` | 173972 | `380f94a0a2f9d199f42c08fd4887864ec4991eee2637cd978c8f67400f3d04f3` |
| `squats.loop_mp4` | `assets/media/athlete/loops/squat_loop.mp4` | 61609 | `b760fdcdbc6bf5901d5dfde7e46575f4fd3c2fbc4742bb6de47d44bc320c7137` |
| `squats.loop_webp` | `assets/media/athlete/loops/squat_loop.webp` | 344054 | `489e3ec6a699b4a6c7dd3443f8880224f2dbab211e88092077ae68f991c9354a` |
| `squats.frame_start` | `assets/media/athlete/frames/squat_start.webp` | 5512 | `e3ae5e5894c14666e337e47a95c837cd522bbf13d71e4099e04204c7f9d3b73d` |
| `squats.frame_mid` | `assets/media/athlete/frames/squat_mid.webp` | 6958 | `49f8ade0c1248ce944f2cf4e40825b8fdf48df45462b0af107fc31f05259d0a6` |
| `squats.frame_end` | `assets/media/athlete/frames/squat_end.webp` | 6780 | `367ee3699ad9e2b2aa40cdbbd3a6498b00f7fbb761cc9dfb666330e15e8f2709` |
| `squats.overlay_start` | `assets/media/athlete/overlays/squat_start.webp` | 6168 | `60a5cffab557468a91b81bfb2a17be45c94400a3480ba726c8eadc1fe8c08f1c` |
| `squats.overlay_end` | `assets/media/athlete/overlays/squat_end.webp` | 6986 | `c2292ec0ab779c4c5bfa4432dd8d3b7e047f8c05ecea7f278e914380b931deb5` |
| `squats.poster_start` | `assets/media/athlete/posters/squat_start.webp` | 15546 | `935891dadf9c18aac2f86ee1c5b146b5b8c42efa6322ae112bacea3130c80b2a` |
| `squats.poster_end` | `assets/media/athlete/posters/squat_end.webp` | 20280 | `be1a5eecc366fa2485b3acec3f2fbd20cb209678844586a77f3a93c5e8275e47` |
| `squats.poster_start_png` | `assets/media/athlete/posters/squat_start.png` | 56207 | `087b16ffc832a013a1b48e093c507589bc4b232006110c38d6bc884c7ceed00a` |
| `squats.poster_end_png` | `assets/media/athlete/posters/squat_end.png` | 80557 | `e276d58a3eaf1665a06bf1f52d73d1787ca2a9fc109e327a416fd1c05d5fa0b8` |

Current review state: all 25 entries are `pending_human_review`;
`qa/media/validation_report_release.json` reports `release_eligible: false`
and the release gate fails (exit 1) by design.

## 5. What the app does while assets are unreviewed

The preparation demonstration now refuses to render any asset whose manifest
`review_status` is not `approved` and shows the documented placeholder
("Form guide pending review") instead
(`app/lib/battle/ui/battle_athlete_demo.dart`, regression tests in
`app/test/battle/battle_athlete_demo_review_test.dart`). The manifest policy
`missing_media_policy.release_builds` and the Python release gate implement the
same rule. No unreviewed poster or loop can ship silently; approval flips the
manifest status and the asset renders.

## 6. Sign-off procedure (after a real review)

1. Record the verdict per exercise in `docs/media/FORM_REVIEW.md` §6 with the
   reviewer's name, date and confirmed asset hashes.
2. For every approved asset in `app/assets/media/athlete/manifest.json`:
   set `"review_status": "approved"`, add
   `"review": {"reviewer", "reviewed_at", "reviewed_asset_sha256"}`, and set
   the exercise `review.status`/`reviewer`/`reviewed_at` (§6 of FORM_REVIEW).
3. Re-run `python qa/media/tools/validate_media_package.py --gate release`;
   it must pass with every entry approved and hash-pinned.
4. Record the reviewer's authority in `qa/launch/l04/L04.md` and update
   `docs/PROJECT_STATUS.md` / `docs/release/GO_NO_GO.md` (R13 closed).

If an asset is rejected: fix and re-render it, or exclude it — the app falls
back to the placeholder, which is the reviewed instructional alternative. A
rejected asset must not be left renderable and must not be replaced with an
unreviewed fallback poster.

## 7. Blocked — exact missing resource

| Missing input | Status |
| --- | --- |
| Qualified form reviewer (coach / physiotherapist / trainer) | not identified |
| Reviewer availability (est. 1–2 h with the kit) | not scheduled |

Until the review happens, the media gate stays failed and R13 stays open. No
signature may be simulated and no asset may be marked approved by this packet.
