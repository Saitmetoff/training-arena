# Task 00 — reconcile the split and establish the Training Arena baseline

You are the foundation engineer for the new **Training Arena** battle app. Work only in `D:\TrainingArena`. Never edit or restore files in `D:\Kiro`, and do not use the old FitBattle application as a runtime dependency.

## Situation to verify first

Inspect `git status`, the current tree, `docs/API.md`, and `supabase/migrations/20260917143538_arena_initial.sql`. The split currently has an Android/Flutter shell under `app/`, but the shell still contains FitBattle package names, labels, comments, and deep-link values. This checkout may not have `app/pubspec.yaml` or current Dart feature source. Old FitBattle files are staged for deletion; preserve that split and do not run a broad restore or clean.

## Outcome

Create a small, buildable Training Arena shell that later tasks can safely extend. Record a product contract in `docs/CONTRACT.md` and the actual state/decisions in `docs/PROJECT_STATUS.md`.

The non-negotiable product contract is:

- App name: **Training Arena**.
- Scope: camera-counted push-up and squat battles only. No pull-ups, training plans, chat, followers, currency, async score challenges, or bots.
- Bottom navigation: **Leaderboard** on the left, **Battle** in the center and selected by default, **Profile** on the right.
- Visual identity: charcoal `#17191A`, graphite `#242729`, raised surface `#303537`, lime `#D6FF3F` for the current player and primary action, violet `#BEA1FF` for the opponent, soft-white `#F6F7F2`, secondary `#B6BDB9`, quiet `#9BA59E`, positive `#7AE5A0`, warning `#FFD66E`, danger `#FF807C`.
- Invite-first loop: receive a challenge → accept → both ready → 60-second battle → confirmed result → share a new challenge.
- Sign-in is required. New users choose a unique username; avatar upload is optional and can be deferred. No generic onboarding before a friend challenge resumes.
- Camera frames stay on device. Competitive reps come from the camera counter; there is no manual score entry.
- Ranked matchmaking changes Elo (start 1,000, K=32) only after a server-confirmed ranked result. Personal challenges and friend rematches are casual and do not change rating.

## Required work

1. Make `app/` a valid Flutter project with a pinned SDK/dependency set and a minimal app that builds on Android API 24+. If the source was omitted by the split, recreate only the minimal shell; do not copy legacy FitBattle screens.
2. Rename every application-facing identifier to Training Arena. Use Android application ID `app.trainingarena.mobile`, namespace/package `app.trainingarena.mobile`, and label `Training Arena`. Remove `com.fitbattle.fitbattle`, `fitbattle.app`, and FitBattle comments from the new runtime. Keep the HTTPS host configurable as `ARENA_LINK_HOST` with safe default `example.invalid` until the owner supplies a real domain. Leave challenge intent filters and link-specific manifest entries to task `05`.
3. Set the base Android manifest and Gradle values for internet and the Flutter shell, keeping minSdk 24. Camera/notification permissions and challenge link filters belong to their owning tasks. Do not add debug Firebase files or credentials.
4. Establish a small Dart interface layer for `ArenaExercise`, `ArenaMatchMode`, `ArenaMatchStatus`, `ChallengeContext`, `ArenaProfile`, and `ResultReceipt`. Keep these value objects independent from Supabase and camera implementations.
5. Add a config reader for public URL, link host, Supabase URL/key placeholders and feature flags. Public client keys may be placeholders; service keys must never be committed.
6. Add a focused smoke test that starts the app and verifies the three-tab shell and Battle as the default tab. Keep the test deterministic and accessible.
7. Document which files are intentionally deleted by the split, which files this task owns, and any missing owner decision in `docs/PROJECT_STATUS.md`.

## Guardrails

Do not implement the full battle, backend, camera counter or sharing here. Do not publish, deploy, rotate keys or commit generated secrets. Do not overwrite another chat's changes. If a shared interface needs a later decision, document it under `docs/decisions/` and keep the shell compiling.

## Acceptance checks

- `flutter pub get`, `flutter analyze` and the focused Flutter test pass from `app/`.
- A debug Android build resolves `app.trainingarena.mobile` and displays `Training Arena`.
- `rg -n "fitbattle|FitBattle|com\.fitbattle" app docs --glob '!docs/PROJECT_STATUS.md'` returns no runtime references.
- The app opens on Battle with Leaderboard/Battle/Profile in the specified order and colors are sourced from one token file.
- `docs/CONTRACT.md` and `docs/PROJECT_STATUS.md` describe the exact interfaces for tasks `01`–`11`.

At handoff, report the baseline commit or branch, build/test commands and any intentionally unresolved values such as the real HTTPS domain.
