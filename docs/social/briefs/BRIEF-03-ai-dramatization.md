# Brief 03 — Clearly labeled fictional AI dramatization (real app UI)

Draft: 2026-09-21 · L09 · Parent: `docs/social/CONTENT_EXPERIMENT.md`.

Status: **SPECIFIED & UNBLOCKED ON AI TOOLING.** AI video tool strategy
approved in `docs/social/UGC_VIDEO_GENERATION_STRATEGY.md` (free model stack:
Kling AI 1.5, Hailuo AI, Wan 2.1, Hedra; multi-account Gemini Pro & Codex Plus
pipeline; automated CLI tool `tools/social/ugc_prompt_matrix.py`). Remaining
dependencies: real-UI capture from a real build (Session C) and account
approval workflow.

Runtime ~20 s · 1080×1920 · 30 fps · burned-in captions · labeled in three
places: first frame, caption, platform AI-disclosure control.

Hypothesis: a relatable fictional scene can carry the premise ("challenge a
friend") where no real pair footage exists yet — without pretending the
fiction is a customer story.

## 1. Hard rules (this brief exists only if they hold)

- Synthetic adults are **actors in a dramatization**, never presented as
  customers, users, beta testers or testimonial sources.
- The app screens inserted in the edit are **real captures of the real build**.
  No generated UI, no mocked score, no fake receipt.
- No fabricated score, rating, win, testimonial, fitness result, social proof
  or model-accuracy claim anywhere in the asset or caption.
- Label visible on the first frame and end card: **"AI-generated
  dramatization"**; caption repeats it; the platform's AI-content disclosure
  is enabled (TikTok requires labels for realistic AI content; Meta applies
  transparency labeling).
- No real person's likeness; no third-party characters, logos or music without
  a ledger row.
- Because the actors are synthetic, no consent release is needed for them; the
  real-UI capture still follows Session C (reserved `.invalid` test accounts,
  no personal data on screen).

## 2. Script

| Time | Visual | Audio / caption |
| --- | --- | --- |
| 0–3 s | Two fictional adults, relaxed, talking about a friendly dare; label on frame | Caption: "AI-generated dramatization — fictional characters" |
| 3–8 s | They agree on "60 seconds, push-ups, right now"; one holds up a phone | Dialogue written as generic conversation; no product claims |
| 8–14 s | Cut to **real captured app UI**: the challenge invite, the accept action, the preparation screen from the real build | Caption: "Real app screens." If the captured build has camera counting off, no counted score appears and the caption says so |
| 14–18 s | Back to the fictional pair, mid-laugh, no screen result shown | Caption: "No score shown — this is fiction, not a test." |
| 18–20 s | End card with the label and the true CTA state | Caption: "AI-generated dramatization. Challenge a friend — beta when available." |

Do not show a result screen, receipt, count, rating or leaderboard position in
this asset unless it is a genuine capture of a genuine match — and if it is,
the fictional pair must not be implied to be its players.

## 3. Disclosure text (exact wording)

First frame + caption: `AI-generated dramatization`
End card: `AI-generated dramatization. The app screens are a real recording;
the people are synthetic and not customers.`

## 4. Music, CTA, edit

- Music: platform library or licensed track, one ledger row (`ASSET-03`).
- CTA gate: same as Brief 01 (follow-only until a working destination and per
  asset approval exist).
- Edit: the UI insert must be identifiable as the real app (no beauty filters
  over UI, no invented notification or score graphics).

## 5. Publish checklist

- [ ] Owner approved the tool, the script and this asset id.
- [ ] First-frame label, caption label and platform disclosure all present.
- [ ] UI inserts verified as real captures from the recorded build hash.
- [ ] Music ledger row complete.
- [ ] Post URL recorded; no synthetic person described as a user anywhere.
