# Task 07 — implement the battle runtime and state-driven UI

You own the production Flutter battle surfaces for Training Arena. Work only in `D:\TrainingArena`; consume the interfaces from camera, backend, account and design tasks rather than duplicating them. Do not implement alternate scoring, fake bots or a second color system. Never touch `D:\Kiro`.

## Navigation and home hierarchy

Bottom navigation is **Leaderboard · Battle · Profile** with Battle selected by default. On Battle, render this order:

1. An incoming request card, when one exists.
2. Large lime **Challenge a friend**.
3. **Find an opponent** for ranked matchmaking.
4. Small **Join with code** fallback.

Keep **Challenge a friend** available while ranked search is running. After 15 seconds offer it as an alternative without claiming anyone is online; stop search at 60 seconds with explicit Retry and Challenge a friend. Switching cancels the queue seat.

## State machine

Implement an explicit state model for link/request/inbox, preparation, practice, ready, countdown, live, reconnecting, result, no-result and exit. A request accept creates a match but never starts unattended. One server-selected exercise (push-ups or squats) is revealed before camera setup. Both players see identity/photo and authoritative score; raw camera footage is private and local.

Preparation includes the reviewed 3D athlete demonstration, privacy explanation, framing guidance and exactly one unscored practice rep. Both players ready → server countdown 1–5 → 60-second round. Camera tracking loss pauses only that player’s count while the shared clock continues. A single-player connection loss gets ten seconds to recover before forfeiture; shared service failure yields no result/rating change. Ties remain ties.

The UI must never allow manual competitive rep entry or infer a winner from local state before the server receipt arrives. Show retry/reconnect actions with honest copy and preserve the match ID across process/lifecycle changes.

## Screens and accessibility

Implement loading, empty, offline, permission denied, blocked, expired request, busy player, cancelled, no-result and completed states. Use large timer/reps, a high-contrast status banner, clear haptics/cues via the native interface, and semantic labels for scores and controls. Keep animation useful for countdown and transitions; respect reduced-motion settings.

## Tests

- Widget/state tests cover every transition and back/leave behavior.
- Contract tests prove the UI renders only server-confirmed result receipts and handles duplicate polling/events idempotently.
- Tests cover a new user returning from challenge sign-in, request acceptance, both-ready gate, tracking loss, 10-second recovery and shared outage.
- Add a deterministic fixture mode only for previews; label it and prevent it from producing ranked/casual receipts.

Acceptance means a real backend/camera implementation can plug in without changing the state contract, and the complete friend battle can reach a confirmed result from the Battle tab or link landing route.

