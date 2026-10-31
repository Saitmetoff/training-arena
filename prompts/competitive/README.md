# Competitive-response prompt pack — 2026-09-22

Source: `docs/research/COMPETITIVE_ANALYSIS.md` (draft) and the plan in its §7.
Owner marks: `docs/research/NOTES.md` (owner-owned; executors read it, never
edit it).

Status: **proposed work only.** Nothing in this pack is approved scope. A task
starts only after the owner marks it KEEP in `NOTES.md` or says so in the chat.
The pack does not change `docs/CONTRACT.md`; the tasks that need a contract
change run after C00 records the owner decision.

Re-analysis 2026-09-23: **none of C00–C09 has deliverables in the tree.** C04
and C05 partially overlap pre-existing L01 code; everything else is absent.
See `docs/research/IMPLEMENTATION_REANALYSIS_2026-09-23.md` before running any
task.

## How to use these files

1. Open one chat per task. Paste the **common preamble** below, then exactly one
   task file. Do not paste two tasks into one chat.
2. Run order is the table below. **One writer per working tree** — this
   repository's documented rule. Run tasks sequentially. If you must run two in
   parallel, create a separate `git worktree` per task and merge in order;
   never point two chats at the same checkout.
3. `C06` and `C09` are docs/scripts only and can be run while no other writer
   is active. Everything else touches app or backend source.
4. After each code task, run a separate read-only review chat (see §Review).

## Common preamble — paste with every task

You are the sole coding executor for Training Arena in `D:/TrainingArena`.
Model: `opencode-go/deepseek-v4.1-flash`. Do not change `D:/Kiro` or upgrade
its shared toolchain.

Read before editing: `docs/CONTRACT.md`, the latest entry in
`docs/PROJECT_STATUS.md`, `docs/research/COMPETITIVE_ANALYSIS.md`, the task
file's named evidence, and `docs/research/NOTES.md` for owner decisions.
`NOTES.md` is owner-owned: read it, never edit it.

Preserve all unrelated dirty and untracked files. Trace all callers before a
fix. Reuse the existing design system, API gateway, test tools and release
checks; do not add a framework, service or dependency unless this task says so
and justifies it in one line. No product expansion beyond this prompt, no
speculative abstraction, no generated or simulated evidence, no weakened
release gate. Keep ponytail mode active; the smallest complete change wins.

Truth rules from `docs/social/CONTENT_EXPERIMENT.md` §2 bind any public-facing
copy you touch: no accuracy percentages, no "cheat-proof", no fitness or
medical claims, no fabricated reviews, results or testimonials.

For any research claim, use the evidence labels from
`docs/research/COMPETITIVE_ANALYSIS.md` (`[V]` verified, `[E]` third-party
estimate, `[I]` inference) and cite the source.

Shell is Windows PowerShell 5.1. Report the exact commands you ran and their
exit status. Never invent a device test, signature, deployment or approval; if
something cannot be executed here, finish the independent local work and
report it BLOCKED with the exact missing input.

Make a short plan, implement the smallest complete change, verify it, and
update `docs/PROJECT_STATUS.md` with a dated section containing exact remaining
work. Commit only a scoped change, only after the repository secret scan
passes.

## Prompt order

| Prompt | Task | Depends on | Skills to load | Estimate |
| --- | --- | --- | --- | --- |
| `C00_OWNER_DIRECTION_DECISIONS.md` | Record the five direction decisions as one ADR | owner marks in NOTES.md | `domain-modeling` | 1–2 h |
| `C01_SOLO_MODE_V1.md` | Solo max-reps session (first value moment) | C00 | `tdd`, `implement` | 8–16 h |
| `C02_DAILY_GOAL_AND_STREAK.md` | Daily goal + streak, server truth | C01 | `supabase`, `supabase-postgres-best-practices`, `tdd` | 12–24 h |
| `C03_PERSONAL_BESTS_AND_BADGES.md` | Personal bests, badges, stats view | C02 | `supabase-postgres-best-practices`, `tdd` | 8–16 h |
| `C04_TRUST_SURFACE.md` | Verified-rep / no-recording / server-confirmed UI | none (C00 for wording) | `accessibility`, `tdd` | 4–8 h |
| `C05_COUNTING_ROBUSTNESS_AND_HARNESS.md` | Landmark replay harness + shake/depth robustness | none | `diagnosing-bugs`, `tdd` | 12–24 h |
| `C06_STORE_LISTING_AND_ASO.md` | Listing copy + keyword pass | none (docs only) | `research` | 3–6 h |
| `C07_SHARE_CLIP_RENDERER.md` | Clip-render spike, then implementation | C01 (data), spike decision | `prototype`, `export`, `tdd` | 4 h spike, 16–32 h impl |
| `C08_WEB_BATTLE_SPIKE.md` | Browser battle feasibility (throwaway) | none | `prototype`, `research` | 6–12 h |
| `C09_OWNER_INPUT_WIZARDS.md` | PowerShell wizards for signing, hosting, Play | none (scripts only) | `wizard` | 4–8 h |

Estimates are active work for one executor, not calendar time. `C02` is the
riskiest task in the pack: streak math across timezones, midnight and DST is
where this class of feature usually breaks.

## Skills and plugins

Skills are loaded on demand by the agent through opencode's native `skill`
tool; the agent sees every installed skill and can load one when told. To use
one, include a line in the chat: "Load the `tdd` skill before editing."
Everything the pack needs is already installed on this machine under
`C:/Users/ADMIN/.agents/skills/`; **nothing needs to be installed for these
tasks.**

Skills used by this pack: `ponytail` (active mode, keep on), `tdd`,
`implement`, `supabase`, `supabase-postgres-best-practices`, `diagnosing-bugs`,
`domain-modeling`, `prototype`, `research`, `wizard`, `accessibility`,
`export`, `to-spec`, `grill-me`, `handoff`, `code-review`.

Not to use here: `stripe-*` — mobile digital subscriptions must go through
Google Play Billing, not Stripe, and no billing task exists in this pack.
`remotion` — React-only video tooling; this app is Flutter.

### Optional one-time setup (owner)

1. **Project skill instead of the pasted preamble.** Put the preamble into
   `.opencode/skills/training-arena/SKILL.md` (frontmatter: `name`,
   `description`) so each chat only needs the task file. The `create-skill`
   skill can draft it.
2. **Skill permissions.** `opencode.json` can allow or deny skills:
   `"permission": { "skill": { "*": "allow" } }`. Nothing is required today.
3. **Writer-lock plugin (recommended, not written).** This repo has lost work
   twice to concurrent writers (`.opencode/plugins/writer-lock.ts` idea: on the
   first `edit`/`write` tool call, create a session-stamped lock file; if
   another live lock exists, throw with the owner session id). A local plugin
   is a `.ts`/`.js` file in `.opencode/plugins/`; npm plugins are listed in
   `opencode.json` under `"plugin": [...]` and installed automatically with
   Bun. Build it in its own chat if wanted; it is not part of any task above.
4. Ponytail is already installed as an npm package and its skills are visible
   in the agent's skill list; no config change is needed.

## Review

After a code task reports PASS, open a **separate** review chat with no other
writer active. Paste: the common preamble plus "Review `Cxx` changes since the
task's start commit using `git diff`; load the `code-review` skill for the
Standards/Spec structure. Read-only: do not edit files." The `code-review`
skill spawns read-only sub-agents; if the one-writer/no-subagent rule is read
strictly, do the same review manually with `git diff` and the task's acceptance
list instead.

## Handoff — every task returns this

- Repo, branch, starting and ending commit, actual model.
- What changed, with the relevant diff; no completion-by-summary alone.
- Actual commands, exit status, evidence path, skipped checks.
- Each acceptance criterion: PASS / FAIL / BLOCKED.
- Remaining dependencies, human decisions, measured active time.
- Scoped commit only after the secret scan and the relevant verification pass.

## What is deliberately not in this pack

Clans, global chat, coins, battle pass, spin wheel, pets, rival AI coach,
arcade minigame and extra exercise types (analysis §7 reject list). Renaming or
iOS are owner decisions recorded in C00, not tasks yet. Publishing content is
the existing L09 packet plus `docs/social/briefs/BRIEF-04`.
