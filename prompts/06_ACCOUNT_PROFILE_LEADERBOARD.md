# Task 06 — implement sign-in continuity, minimal profile and leaderboard

You own account/profile/leaderboard surfaces for Training Arena. Work only in `D:\TrainingArena`; read the backend API contract and design system first. Keep challenge landing and battle runtime in their owners’ paths. Never edit `D:\Kiro` or add unrelated social features.

## Authentication continuity

Support Google and email-code sign-in through the configured auth provider. Sign-in is required for a battle. When sign-in was entered from a challenge link, return to that exact pending challenge after success, process restart or a supported install recovery. Do not insert generic onboarding or fitness questionnaires into that route. On first sign-in, require a unique normalized username; avatar upload is optional and can be deferred.

Handle cancellation, expired auth, duplicate username, offline retry and sign-out with plain copy. Never log tokens or email addresses. Keep auth/session logic behind a small interface so tests use fakes.

## Profile

The signed-in profile contains only: photo/avatar, username, Arena rating, ranked wins, ranked battles, **Edit profile**, **Battle history** and **Settings**. Make the current player lime; opponent identity is violet elsewhere. Avatar upload accepts the backend’s safe image limits, has remove/retry states and never accepts camera frames. Username changes update future displays but immutable result receipts retain the confirmed snapshot.

Public player cards show safe public identity and rating context plus **Report** and **Block**. Blocking must hide future requests/queue opponents according to the backend contract; do not add followers, chat, badges, training plans or currency.

## Leaderboard and history

Leaderboard is the left bottom tab. Show ranked players with username, avatar and rating, include the current player when outside the top page, and explain that participation appears after the first completed ranked match. Never mix casual results into rating. Battle history shows confirmed receipts only, with exercise, duration, scores, outcome, mode and rating change only when applicable. Handle empty/loading/offline/deleted-user states.

## Acceptance checks

- A challenge sign-in round trip returns to the same challenge token.
- Username validation is normalized and race-safe through the backend; client errors are actionable.
- Profile has no clutter beyond the specified fields and remains readable at large text sizes.
- Public profile/report/block actions have tests and do not expose private email, camera data or auth tokens.
- Leaderboard/rating/history are derived from confirmed receipts and never optimistic guesses.

At handoff, list the auth redirect configuration expected from the release task and any interface notes needed by battle UI.

