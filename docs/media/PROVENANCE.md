# Athlete media provenance

Version 1.0.0 · built 2026-09-17 · owned by task `02`

This package contains **no third-party 3D model, no scanned human, no AI image
generation and no FitBattle media**. Every mesh, material, animation, render
and annotation in `app/assets/media/athlete/` is generated deterministically
inside this repository by the scripts listed below.

## 1. What was created, from what

| Item | Origin | Licence |
| --- | --- | --- |
| `athlete_mannequin_v1.glb` (mesh, rig, 2 clips) | procedural geometry and animation authored in `qa/media/tools/arena_athlete/` by the project | original work of the Training Arena project, redistributable with the app |
| Loop videos, still frames, posters, overlays | software-rendered from the same procedural model by the same scripts | same |
| Palette | `design/arena/tokens.json` (product token file, task `01`) | project content |
| Annotation type | bundled `Inter` family, `app/assets/fonts/` | SIL Open Font License 1.1 (`app/assets/fonts/LICENSE`); rendered text is permitted under the OFL |
| No audio, no photos, no external textures | — | — |

No network access is used during the build, no account or key is required, and
no media file is downloaded at runtime. No private credential, keystore, token
or endpoint is recorded in this package or in these documents.

The athlete is deliberately abstract: no real person's likeness, no facial
features, no identifiable hair, clothing brand or team mark. It is a training
mannequin, and the documentation and in-image copy say so.

## 2. Generation record

| Field | Value |
| --- | --- |
| Generator | `qa/media/tools/arena_athlete/` (`spec.py`, `mesh.py`, `rig.py`, `animation.py`, `render.py`, `annotations.py`, `glb.py`) |
| Entry point | `python qa/media/tools/build.py` |
| Package version | `1.0.0` |
| Build timestamp | `2026-09-17T00:00:00Z` (`ARENA_MEDIA_TIMESTAMP`, fixed so builds are reproducible) |
| Python / libraries | Python 3.14.4, Pillow 12.2.0, numpy 2.4.4 |
| Video encoder | ffmpeg 8.1.1 (`libx264`, `libwebp`), `+bitexact`, no audio, metadata stripped |
| GLB writer | in-repo exporter, glTF 2.0 binary, no third-party dependency |
| Mesh | 2 868 vertices, 3 597 triangles, 7 materials, 19 joints |
| Face/skin/hair | neutral stylised head, no features; see `ATHLETE_SPEC.md` §3 |
| Animation | two clips authored from body landmarks and two-bone IK, 25 fps |
| Verification | `qa/media/tools/validate_media_package.py`, `qa/media/tools/qa_report.py`, `qa/media/tools/measure_poses.py` |

Determinism: the timestamp is fixed, the renderer uses no randomness and
ffmpeg runs in bitexact mode, so a clean regeneration of unchanged code
reproduces identical bytes and SHA-256 hashes. Changing any generator input
invalidates the hashes recorded in `FORM_REVIEW.md` and the manifest review
status resets to `pending_human_review`.

## 3. Shipped file hashes (25 manifest entries, 23 unique files)

Reproduced from `app/assets/media/athlete/manifest.json`. Print the current
table with `python qa/media/tools/hash_table.py`.

| Key | Asset | Bytes | SHA-256 |
| --- | --- | --- | --- |
| `models.athlete` | `assets/media/athlete/models/athlete_mannequin_v1.glb` | 173972 | `380f94a0a2f9d199f42c08fd4887864ec4991eee2637cd978c8f67400f3d04f3` |
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

The GLB entry is shared by both exercises (one model, two clips).

## 4. Review status

All assets: `pending_human_review`. `release_eligible: false`.
`docs/media/FORM_REVIEW.md` holds the checklist and the sign-off table. The
release gate in `qa/media/tools/validate_media_package.py --gate release`
refuses to pass while any shipped entry is not approved, which is the mechanism
that keeps unreviewed media out of release builds.

## 5. Change policy

1. Regenerate with `python qa/media/tools/build.py` (fixed timestamp keeps
   hashes stable for unchanged code).
2. If any generator input changed, update this file and `FORM_REVIEW.md` with
   the new hashes and reset the affected rows to `pending_human_review`.
3. Never add a third-party model to this package without a licence entry here
   and an owner decision; never re-import FitBattle media.
