# C06 — Store listing copy and keyword pass

Status 2026-09-23: **implemented docs-only.** §2 of the Play packet now has
the keyword table, claims checklist, conditional solo sentence and follow-up
list; variant A copy was already truthful and unchanged. Record:
`qa/competitive/c06/REPORT.md`.

Depends on: C00 for the name decision (D-B); docs only. Estimate: 3–6 h.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `research` — mine public listings and reviews for the keyword and hook
  evidence; label every claim `[V]`, `[E]` or `[I]`.

## Goal

Close the listing gap without breaking the truth rules. The market leader's
listing misses keywords this category actually searches (`rep`, `counter`,
`workout`, `challenge`, `friends`, `strength`), while Training Arena's current
listing copy is the camera-off closed-test variant and predates this research.

Scope:

1. **Read first:** `docs/release/PLAY_STORE_PACKET.md` §2 (both listing
   variants), §7 assets, and the analysis §2/§3 for the gap evidence.
2. **Short description** (≤ 80 chars) and **full description**: rewrite for
   the validated camera-off artifact only. Every sentence must be true of the
   current build; competitive claims (ranked, camera counting, cross-play,
   push) may appear only where the artifact actually has them, which today
   means they do not.
3. **Keyword table** in the packet: target term, where it now appears, source
   for the choice, and the truth constraint on it. No stuffing; no terms the
   product cannot honour.
4. **Name decision.** If D-B chose a rename, update the listing copy to the new
   name and mark every other document that still carries the old one as a
   follow-up list — do not mass-rename the repo in this task. If D-B is
   unanswered, keep the current name and mark the copy pending.
5. **Reviewer-access copy** and Data Safety answers: verify they still match
   the packet and the artifact; list anything that must change.

## Owned paths

`docs/release/PLAY_STORE_PACKET.md`, one evidence file under
`qa/competitive/c06/`. No source, no assets, no `challenge-web/` changes.

## Must not

- Claim camera counting, ranked, notifications, cross-play or iOS.
- Claim accuracy percentages, "cheat-proof", health or transformation
  outcomes, or any user/review count that is not real.
- Change store graphics, the app label, the package name or version.
- Publish anything; this is copy only.

## Acceptance

- Both variants updated (or explicitly marked pending the name decision), each
  sentence traceable to the current artifact's real capabilities.
- Keyword table present with sources and truth constraints.
- A forbidden-claims checklist in the packet that a reviewer can apply in one
  pass; the rewritten copy passes it.
- A follow-up list of any document still carrying an outdated name or scope
  claim.
- `git diff` touches only the packet and the evidence file.

## Handoff

Standard handoff, including the name-decision dependency and the follow-up
list.
