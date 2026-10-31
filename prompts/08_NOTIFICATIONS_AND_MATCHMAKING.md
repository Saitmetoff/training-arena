# Task 08 — add request notifications and honest low-population matchmaking

You own notification plumbing and the ranked-search experience for Training Arena. Work only in `D:\TrainingArena`; read `docs/API.md` and the battle state contract. Do not create a bot, alter rating rules or duplicate backend authorization. Keep production secrets out of the repository.

## Request notifications

When someone first sends or receives a challenge request, ask for notification permission in context. Permission denial leaves the in-app request authoritative and usable. Register only a device token through the backend’s device action; never log tokens. A server-side outbox/worker may deliver best-effort push notifications with lease/retry, but inbox state remains the source of truth.

Handle foreground, background, cold-start and duplicate notification taps. A notification tap opens the exact pending request/challenge, not a generic home screen. Expired, cancelled, blocked and already-accepted requests must resolve to an explanatory screen. Document Android channel, API 33 permission and server worker configuration without committing Firebase credentials.

## Ranked search

Implement a truthful queue UX:

- `Find an opponent` clearly says it is ranked and camera-counted.
- Keep **Challenge a friend** visible during the search.
- At 15 seconds show an alternative action, not a claim that a player is online.
- End an unsuccessful search at 60 seconds with Retry and Challenge a friend. Never loop indefinitely or create a bot.
- Queue leave is idempotent on back, app pause, network loss and switching to friend challenge.
- Show only a match issued by the authoritative server; never pair a blocked player.

Integrate polling/realtime according to the backend contract, show reconnecting/offline state and prevent two active queue seats or overlapping battles. Track analytics for search started, matched, cancelled, timed out and friend-challenge alternative; do not call a share-sheet opening a successful referral.

## Acceptance checks

- Permission allowed/denied paths both preserve the request and have tests.
- Duplicate notification delivery/taps are harmless.
- A 60-second empty-queue simulation ends predictably and never displays a fake opponent.
- A real match transitions into the battle runtime’s preparation state with the correct mode and match ID.
- Worker deployment prerequisites and secret names are documented for task `11`, with no live send performed here.

