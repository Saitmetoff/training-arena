# Training Arena engineering prompt pack

These prompts split the unfinished Training Arena battle app into bounded tasks that can be opened in separate engineering chats. They are written against the repository as it exists on 2026-09-17, not against the old FitBattle phase plan.

## Current repository audit

The split is still a scaffold. `app/` contains an Android/Flutter shell, but the shell still has FitBattle identifiers and this checkout does not yet contain the current Flutter `pubspec.yaml` or feature source. `docs/API.md` and `supabase/migrations/20260917143538_arena_initial.sql` are partial Arena contracts. There is no production 3D athlete package, challenge landing page, complete camera counter, battle UI, share-card renderer, or end-to-end evidence. The old FitBattle files are staged for deletion as part of the split; do not restore them wholesale and do not touch `D:\Kiro`.

## How to use these files

Run `00_RECONCILE_AND_BOOTSTRAP.md` first. It creates the safe baseline and records the interfaces. After that, prompts `01` through `09` can be worked in parallel where their listed dependencies are satisfied, each in an isolated branch/worktree; then `10` and `11` close integration and release gates. If a chat starts before the baseline exists, it must inspect the repository and write an interface note instead of inventing a competing contract.

Each prompt owns a path set. Before editing, create an isolated branch/worktree named for the task (for example `codex/arena-camera`); if the chat is pointed at the shared checkout, stop after inspection and write an interface note instead of editing. A chat must not rewrite another task's owned paths. Shared changes belong in an interface note under `docs/decisions/` and should be applied by the owner of that path. Every chat must preserve unrelated user changes, avoid `git reset --hard`, avoid broad deletes, keep secrets out of the repository, and report files changed, tests run, and unresolved risks.

## Prompt order and ownership

| Prompt | State at audit | Task | Depends on | Primary owned paths |
|---|---|---|---|---|
| `00_RECONCILE_AND_BOOTSTRAP.md` | Partial | Establish the clean Training Arena shell and project contract | none | root metadata, `app/` shell, `docs/PROJECT_STATUS.md`, `docs/CONTRACT.md` |
| `01_DESIGN_SYSTEM_AND_PROTOTYPE.md` | Not started | Final charcoal/lime/violet visual system and clickable invitation prototype | `00` | `design/arena/`, `prototype/` |
| `02_3D_ATHLETE_MEDIA.md` | Not started | One consistent reviewed 3D athlete for push-ups and squats | `00`, `01` | `app/assets/media/`, `docs/media/`, `qa/media/` |
| `03_CAMERA_REP_COUNTING.md` | Not started | On-device pose tracking and rep state machine | `00`, `02` | `app/lib/camera/`, camera-specific Android bridge files, camera tests |
| `04_ARENA_BACKEND.md` | Partial | Authoritative Supabase data model, RPCs, Edge Function and RLS | `00` | `supabase/`, `backend/`, `docs/API.md` |
| `05_CHALLENGE_LINK_AND_INSTALL.md` | Not started | Durable challenge links, landing page, App Links and install recovery | `00`, `04` | `challenge-web/`, `app/lib/linking/`, Android link manifest/config |
| `06_ACCOUNT_PROFILE_LEADERBOARD.md` | Not started | Sign-in continuity, username/avatar, profile, history and leaderboard | `00`, `04`, `05` | account/profile/leaderboard Flutter features |
| `07_BATTLE_RUNTIME_UI.md` | Not started | Battle tab, preparation, countdown, live round, result and navigation | `01`, `02`, `03`, `04`, `06` | battle Flutter features and UI tests |
| `08_NOTIFICATIONS_AND_MATCHMAKING.md` | Not started | Request notifications and honest low-population ranked search | `04`, `05`, `07` | notification service, matchmaking UI integration, worker docs |
| `09_RESULT_SHARING.md` | Not started | Factual result cards, real challenge URLs, QR and export formats | `01`, `04`, `05`, `07` | sharing Flutter feature, card renderer, share tests |
| `10_INTEGRATION_AND_DEVICE_QA.md` | Not started | Full invitation-to-battle evidence and failure-state coverage | `02`–`09` | `qa/`, integration tests, QA reports |
| `11_RELEASE_PILOT.md` | Not started | Production configuration, security/release gates and invited-pair pilot | `10` | `docs/release/`, CI/release checks |

The order is a dependency guide, not permission to skip acceptance criteria. A task is complete only when its prompt's acceptance checks pass and its handoff note is written.

## Competitive-response pack — 2026-09-22

`prompts/competitive/` is a separate pack built from
`docs/research/COMPETITIVE_ANALYSIS.md` and the owner marks in
`docs/research/NOTES.md`. It is **proposed work, not approved scope**: start a
task only after the owner marks it KEEP. It runs on the already-shipped
implementation, not on tasks 00–11. Run its tasks sequentially (one writer per
tree) and paste the pack's common preamble with each task file. `C06` and
`C09` are docs/scripts only and do not touch app or backend source.

## Camera fix pack — 2026-09-23

`prompts/camera-fixes/` covers the owner's first physical-device session
(Redmi 10): the camera preview not reopening after the first use (F1),
head-on/front-view counting not working (F2), a visible skeleton overlay for
both view modes (F4), and real-device trace capture with evidence-backed
thresholds (F3). Run F1 → F2 → F4 → F3, one writer, same common preamble as
the competitive pack. F2 changes counting geometry; F4 only draws the
landmarks already in memory (no second detector); F3 only measures and
records.
