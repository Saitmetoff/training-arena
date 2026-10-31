# C07 — share clip spike: verification record

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

Phase 1 only, as the prompt requires. Deliverable:
`docs/decisions/13-share-clip-approach.md`.

## Outcome

Four options compared on privacy delta, effort and risk. Recommendation:
**keep the static card (D) now**; revisit native screen recording (A) only
after R1 enables camera counting, with an inventory and consent decision
first; reject the encoder-dependency path (B) and the server-rendered path
(C).

Decisive constraint: with camera counting off in the pilot there is no honest
motion content to record, and the task's own red lines forbid fabricating it.

## Not done (deliberately)

- No app code, no dependency, no `ARENA_FEATURE_SHARE_CLIP` flag, no asset.
- Phase 2 stays owner-gated per the prompt; the decision record carries the
  checklist a Phase 2 task must satisfy.
