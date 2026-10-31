# Task 05 — implement the invite-first challenge link and install recovery

You own the challenge entry route for Training Arena. Work only in `D:\TrainingArena`; read `docs/CONTRACT.md`, `docs/API.md` and the design prototype. Keep backend mutations in the backend owner’s path and keep camera/battle code out of this task. Never touch `D:\Kiro`.

## Goal

Make a friend link the shortest path into one specific live battle. The normal path is: open a link → see the challenger → sign in if needed → accept → both return and confirm readiness. No friend search, contact import, room setup or code typing is required on the normal path.

When the owner taps **Challenge a friend**, open the platform share sheet immediately with a generated message in this shape (using confirmed runtime values): `@azizbek challenges you. Push-ups or squats. 60 seconds. Accept the challenge: <link>`. The sender then sees a waiting/request state and can leave without cancelling the durable link.

## Link semantics

- A link identifies the sharer, not a completed match or reserved seat. It survives username changes and remains valid until revoked or account deletion.
- Opening a link or generating a preview is read-only. It must not send a request, reserve a seat or create a match.
- Each recipient creates a separate request. Accepting one prevents overlapping accepted battles. Requests expire after 24 hours.
- Use `trainingarena://challenge/<token>` for local fallback and a configurable HTTPS URL such as `https://<ARENA_LINK_HOST>/c/<token>` for sharing. Keep `example.invalid` in local config until the owner supplies a real domain.

## Required routes/states

Build the focused landing experience for:

- installed and signed-in user;
- installed but signed-out user, returning to the same challenge after Google/email sign-in;
- not-installed user, with a web landing page that explains the challenge and provides the supported Play install route;
- install recovery through Android App Links and Play Install Referrer;
- a visible “Reopen this link after installing” and readable short code fallback;
- revoked, expired, completed-link, busy-player, blocked and unavailable states;
- challenger offline: **Send live challenge** with a clear explanation that both people must be available.

Do not promise asynchronous replay or “beat the old score.” Accepted requests create a live casual match only when both players return and confirm readiness.

## Android/web requirements

- Add verified App Links intent filter with a configurable host and document the required `assetlinks.json` relation; do not pretend verification works on `example.invalid`.
- Persist pending challenge context across auth redirect, process restart and supported install recovery. Clear it only after explicit accept/decline/cancel or an unrecoverable expiry.
- Use a static/web landing page that reads runtime configuration, has a passive social preview, no hardcoded secrets and no mutation on GET.
- Provide analytics events for link opened, sign-in completed, request sent and accepted without treating a share-sheet opening as a referral.

Acceptance is the primary user test: a new user following a friend link can complete that challenge without navigating tabs or re-entering a code. Add cold/warm link tests and install-referrer fallback tests with fake tokens.
