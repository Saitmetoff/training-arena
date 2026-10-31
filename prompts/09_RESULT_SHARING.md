# Task 09 — turn confirmed results into new challenge invitations

You own result sharing for Training Arena. Work only in `D:\TrainingArena`; read the design system, backend receipt contract and battle state model. Do not change match scoring, invent outcomes, upload camera footage or make a result link replay an old match.

## Result contract

Render only an immutable, server-confirmed receipt. The sharer is always on the left and lime; the opponent is violet. Use factual perspective-aware headlines such as `ALEX BEAT ME BY 3`, `I BEAT ALEX BY 3`, or `DRAW`. Include:

- confirmed scores with the exercise and `60 seconds`;
- `@username` identities;
- Arena rating after the match only for ranked receipts (never imply casual rating change);
- a prominent `CHALLENGE @OPPONENT` call to action;
- a real short challenge URL and readable short code;
- a QR code inside the artwork that encodes the same URL.

The challenge URL identifies the sharer for a new live casual battle. It never promises an immediate rematch, asynchronous score comparison or a chance to beat the old score. Opening it is read-only until the recipient explicitly accepts.

## Export and UX

Provide two exact exports: 1080×1920 for stories and 1080×1350 for feeds. Keep headline, scores, identities, CTA, URL and QR inside a generous central safe area. Exclude raw camera frames. Offer `Share challenge`, `Copy challenge link` and system share separately. Preview the exact card before invoking the share sheet; a painted button is not an interactive link. Handle missing avatar, deleted/renamed users, no-result, offline URL creation and destination apps that strip captions.

## Deliverables

- Reusable card model and renderer with the design tokens.
- QR/short URL generation with validation and accessible alt/copy text.
- Native share adapter and deterministic preview/export tests.
- Fixtures for win, loss, draw, ranked, casual and no-result receipts.
- `docs/SHARING_SPEC.md` describing copy, safe area, URL semantics, privacy and analytics events.

Acceptance means the recipient can understand who won, what exercise was performed and who is being challenged from the image alone, while the copied URL remains a real challenge destination. Tests must verify that unconfirmed/local results cannot be shared as confirmed outcomes.

