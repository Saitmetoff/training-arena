# Training Arena — 0 → 100,000 users strategy

Date: 2026-09-27 · Basis: full audit of `app/lib`, `supabase/`, `challenge-web/`, `docs/`, `qa/`, `tools/` on this tree. Every claim below is grounded in an audited file; nothing is invented.

---

## 0. The one-sentence situation

Training Arena is a **finished, heavily-tested product that has never been used by a stranger**: the growth problem is not features, it is that the loop has zero exposure to reality — and the fastest path to 100k is to close the launch blockers (keystore, domain, hosted stack, camera validation on one real phone), ship the pilot **camera-on with solo on and share cards on**, then run a content engine + event calendar on top of the receipt-share loop that is already built.

---

## 1. Audit of the current state

### 1.1 What exists (verified)

| Capability | State | Evidence |
| --- | --- | --- |
| 1v1 live 60-second camera-counted push-up/squat battles | Built, server-authoritative clock, 5s countdown, presence/forfeit sweep | `supabase/migrations/*arena*.sql`, `app/lib/battle/` |
| Challenge links (durable per-user token), join-by-code, Install Referrer recovery, App Links + custom scheme | Built; landing page `challenge-web/` with Play CTA | `app/lib/linking/`, `challenge-web/` |
| Result share cards (Stories + Feed PNG, QR, caption), share sheet | Built, behind `ARENA_FEATURE_RESULT_SHARING` (off) | `app/lib/sharing/` |
| Elo 1000/K=32 ranked-only, top-100 leaderboard + own rank, receipts, immutable audit | Built, server-side, pgTAP-tested | `arena_close_match`, `arena_leaderboard` |
| Ranked queue (FIFO, 60s seat) | Built; client-gated behind `ARENA_FEATURE_RANKED_MATCHMAKING` + camera flag (both off) | `app/lib/battle/runtime/` |
| Solo mode: 20 reps/day goal, streak (current/longest), 6 badges, PBs, stats — local-only | Built, behind `ARENA_FEATURE_SOLO_MODE` (pinned false in release) | `app/lib/solo/`, decision 12 D-A |
| Push notifications (challenge, accepted, matchReady, finished; contextual one-shot permission ask) | Built, double-gated (flag off + no `google-services.json`) | `app/lib/notifications/`, L06 |
| Camera counting: ML Kit pose, front camera, push-ups side+front view, squats side-only, skeleton overlay, 13 pause-reason guidance copy | Built; **thresholds never validated on a physical device** (F2/F3/F4 device sessions BLOCKED) | `app/lib/camera/`, `qa/competitive/f2..f4/` |
| Privacy/trust surface: frames never leave device, RLS-everything, honest copy, forbidden-claims test, account deletion route | Built and tested | `docs/privacy/`, `app/test/copy/` |
| Store packet, privacy/support pages, deletion funnel, 6 real screenshots | Written, **not hosted** (R16) | `docs/release/PLAY_STORE_PACKET.md` |
| Owner wizards for signing/hosting/Play closed test | Dry-run ready | `tools/wizards/W1..W3` |
| Content engine: 4 UGC briefs, 14-day calendar, activation funnel definition, AI-UGC prompt tooling | Written; no accounts created, nothing published | `docs/social/`, `tools/social/` |
| Tests: 606 Flutter, 194 pgTAP, 24 e2e, 21 web | Passing | `docs/PROJECT_STATUS.md` 2026-09-25 |

### 1.2 What does not exist (verified)

- **Users.** Zero installs, zero testers, no Play listing, no social accounts, no hosted backend ("no hosted backend has been configured or deployed" — `docs/API.md`).
- **Any monetization** — no billing code at all (decision D-D records the future intent: annual-first subscription via Play Billing, never Stripe).
- Onboarding/tutorial/first-run framing calibration; any re-engagement (no local reminders, no streak nudges, no dormant campaigns); any in-app social graph (no friends/follow/chat — frozen out of scope); any "my code" retrieval surface; any live waiting feedback ("your friend opened the link" is invisible); web landing analytics (deliberately unmeasured); rematch ("never replays this match" is in the copy contract); seasons/resets for the leaderboard; server-side kill switch (R15 proposal unapplied).

### 1.3 Strengths / weaknesses / differentiation

**Strengths**
1. The **receipt**: a server-confirmed, immutable, QR-carrying proof of a real 60-second battle. It is simultaneously the reward, the share artifact, and the ad. Almost no competitor has honest, server-confirmed competition.
2. **Counting honesty as a wedge**: the category's #1 complaint is broken rep counting (the 400k-download Android leader is 2.0★ largely for that). TA shows the skeleton it counts, guides framing, and stamps receipts "Source: Server receipt". If validated on real devices, "the one that actually counts" is a defensible position.
3. The **60-second format is TikTok-shaped by construction**: two people, live count, decisive result, zero context needed.
4. Engineering depth out of proportion to team size: server-authoritative play (hard to fake), anti-cheat windows, privacy posture — this matters with fitness-competitive audiences.

**Weaknesses (ranked by growth damage)**
1. **Distribution = zero**, and the whole acquisition design depends on pairs, not solo downloads (harder than the industry default).
2. **No solo value on day one in the pilot build** (solo flag pinned off): a person who downloads and has no opponent has *nothing to do* except wait. This is the single biggest activation killer in the current config.
3. **Camera counting unvalidated on real hardware** — the "wow" moment can misfire on the exact devices the target audience owns (the Redmi 10 framing failure is documented).
4. **No re-engagement loop**: streaks and badges exist but nothing ever brings anyone back; push is built but off.
5. **Silent waiting states**: after sharing a link, the sender sees nothing; the web funnel measures nothing.
6. Default-release config ships **every feature off** — a config/flag flip is required before any launch, and it must be treated as a launch-critical task, not a detail.
7. Scale debt that only matters past ~10k DAU: 1s heartbeat / 2s queue / 4s inbox polling through one Edge Function; `arena_history` scans receipts JSONB without an index; leaderboard recomputes rank per call; no retention jobs on `arena_match_events`/outbox/analytics; no kill switch (R15).

**What could make it differentiated**: the only camera-counted, server-verified, receipt-backed head-to-head rep battle — sold on *trustworthy counting* while competitors sell broken counting plus coins.

### 1.4 Sort: exists / improve / build / don't build

- **Already exists (use as-is):** battles, receipts, Elo + leaderboard, challenge links/codes, share cards + QR, solo streak/badges, push pipeline, privacy pages, store packet, wizards, content briefs.
- **Needs improvement (not replacement):** camera thresholds (validate + tune with F3 traces on a real phone); share-card reach (enable + always offer after every receipt); challenge-web (add a minimal, disclosed funnel event); waiting states (show "friend opened/accepted"); pilot flag config (ship most flags on).
- **Worth building (small, growth-locked):** "My code" retrieval surface; 1-tap rematch (same-opponent new request); local streak reminder notifications; first-run framing self-test (30-second practice with pass/fail); minimal web funnel analytics; Play Billing annual Pro; simple event surfaces (leaderboard snapshot page/pin).
- **NOT worth building now:** chat/followers/clans, coins/currency/battle pass, async challenges, extra exercises, training plans/AI coaching, web battles, iOS, screen-recorded clip renderer, real-time channel migration. (The contract freezes most of these out; decisions 12–14 confirm.)

---

## 2. The 100k strategy by phase

Working definitions (adopt the project's own, already instrumented): **activation = first server-confirmed battle between two humans**; repeat = second confirmed battle within 7 days. Views/likes/installs are not activation.

**The loop to keep healthy:** content/link → install → solo set in 60s (instant value, streak starts) → challenge a friend (or queue) → 60s battle → receipt → share card → friend installs. Solo fills the dead zone while you find an opponent; receipts re-seed the loop.

### Phase A — 0 → 1,000 (launch blockers → closed test → soft launch) · ~Months 0–2

- **Channel:** hand-recruited testers (gym/university/friend groups), the owner's own phone for camera validation; TikTok/IG only as documentation of the build, not acquisition yet.
- **Audience:** 18–35 casual-to-mid fitness people in ONE country/language who train with a partner or rival.
- **Acquisition mechanism:** pairs recruited directly ("bring your training partner"); each pair installs via a challenge link.
- **Activation:** first-run framing self-test + solo mode on → everyone gets a counted result on visit one; then one real battle within the session.
- **Retention:** two scheduled play windows per week for the roster; push on (challenge/matchReady) once R17 closes.
- **Viral loop:** receipts shared inside the group chats of the roster (manual, honest).
- **Product priorities:** close R9/R2/R3/R16/R15/R17; camera validation + threshold tuning (R1) on the owner's Redmi 10; flip release flags (camera on, solo on, links on, sharing on, push on, ranked on after R6 two-device check); first-run framing self-test; "My code" surface; waiting-state feedback.
- **Monetization:** none. Decision D-D stands: free through validation.
- **Key metrics:** ≥70% of 20 recruited pairs complete a first battle unaided; ≥30% battle again within 7 days; count-complaint rate; crash rate.
- **Biggest risk:** the pilot ships camera-off (per D-C) and therefore cannot complete a single counted round — the pilot would prove nothing. Camera-on is mandatory; R1 is the critical path.
- **Gate to next stage:** the two thresholds above hit on real strangers (not friends), and counting complaints <5% of rounds.

### Phase B — 1,000 → 10,000 (organic content engine + first events) · ~Months 2–5

- **Channel:** TikTok + Reels + Shorts from the existing briefs (BRIEF-01 real battles, BRIEF-04 hook re-cuts), creator seeding wave 1 (10–20 micro fitness creators, free, personal challenge links), fitness communities (Discord/Reddit/gym group chats) with challenge links.
- **Audience:** same geo + English-speaking spillover; short-form fitness viewers who enjoy competition content.
- **Acquisition mechanism:** the receipt/card as the ad; "beat the creator" live open-challenge sessions; every post ends with the challenge-link CTA.
- **Activation:** unchanged loop; now measured through the web funnel event + in-app analytics events that already exist.
- **Retention:** streak reminders on; weekly scheduled event ("Fight Night Friday" — 48h ranked sprint, leaderboard snapshot) as a standing reason to return.
- **Viral loop:** creator receipts + follower battles; K-factor tracked per activation definition.
- **Product priorities:** web funnel analytics; rematch; New-Year seasonal event (January); leaderboard snapshot/event page; scale fixes before 10k DAU (history index, outbox/analytics retention, leaderboard cache, R15 kill switch applied).
- **Monetization:** launch **Pro (annual-first, 7-day trial, Play Billing)** late in this phase, only after the 70/30 gates hold for 4 consecutive weeks. Pro = cosmetics + extended stats + event perks. Competitive play stays 100% free.
- **Key metrics:** activation-per-qualified-visit per hook; D1/D7; % of matches from links vs queue; K-factor; Pro trial starts/conversion.
- **Biggest risk:** a counting-accuracy scandal on camera (a viral video showing a miscount). Mitigate with the trust surface and fast threshold fixes.
- **Gate:** ≥10k registered with D7 ≥25% and a proven repeatable content format (one hook family with stable activation-per-visit).

### Phase C — 10,000 → 50,000 (events + creator flywheel + monetization tune) · ~Months 5–9

- **Channel:** monthly **Arena Open** ladder weekends with titled results; creator program wave 2 (50+, still free product access + their own links, small prize pool from Pro revenue); cross-promo with adjacent apps/communities; localized push into 2–3 new geos once counting is validated there.
- **Product priorities:** simple bracket/finale event format; seasonal themes; share-card themes (Pro); performance hardening.
- **Monetization:** monthly Pro tier added; one-time founder/cosmetic purchases tested; revenue funds prize pools (growth-positive spending).
- **Key metrics:** event participation rate (share of DAU entering event windows), revenue per activated player, organic share rate of receipts, infra cost per DAU.
- **Gate:** 50k registered, paying-or-engaged base with D30 ≥10%, infra cost per activated player bounded.

### Phase D — 50,000 → 100,000 (flagship annual + platform expansion decision) · ~Months 9–12

- **Channel:** annual **Arena Open Championship** (top-64 by season rating, streamed finals), press/creator coverage of the finals, referral program with cosmetic rewards, possible iOS if unit economics justify.
- **Product priorities:** iOS go/no-go (build only if D30 payback and support load allow); localization of store listing; partnership integrations.
- **Key metrics:** 100k registered, ≥50k activated, D7 ≥25%, Pro conversion 3–6%, K-factor ≥0.5.
- **Biggest risk:** scaling infra/support/abuse (reports, boosting, alt accounts) faster than one person can moderate — automation and controls must precede the 50k→100k push.

---

## 3. "Blow-up" mechanics (ranked by leverage ÷ effort)

| # | Mechanic | Concept | Why participate / share | Brings new users via | Uses existing | Effort | Cost | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **Receipt share cards** | "I BEAT @X BY 12" PNG with QR after every battle | Proof + bragging rights; QR = one-tap revenge | Every battle end-screen | Built (flag off) | Trivial (enable) | $0 | **P0 — the core viral artifact** |
| 2 | **Creator "beat me" live sessions** | Creator posts their link + a time window; fans join the queue; creator accepts repeatedly | Fans get to battle a creator; creator gets content | Creator's audience | Links + inbox + queue (built); needs an auto-accept "open challenge" toggle + counter of pending fans | Low-Med | $0 | **P1 — highest external reach per dev-hour** |
| 3 | **Fight Night Friday** | Recurring 48h ranked sprint; Monday leaderboard snapshot posted | Weekly ritual, rank movement, snapshot is shareable | Tag-a-friend comments, snapshot shares | Elo + leaderboard built; needs event framing + snapshot export | Low | $0 | **P1 — retention + content engine** |
| 4 | **Streak events ("Last Rep Standing")** | Solo-streak survival window; badges for event streaks | Loss aversion; badge bragging | Streaks are personal — weak acquisition, strong retention | Solo streak (built) + reminder notifications | Low | $0 | P1 retention |
| 5 | **Arena Open (monthly) → Championship (annual)** | Season ladder snapshot → top-64 bracket finale, streamed | Status; finals content | Creator/press coverage of finals | Leaderboard; needs lightweight bracket page + season label | Medium | prize pool from Pro revenue | P2 flagship |
| 6 | **Community goal counter** | "The world did 1,000,000 counted reps this week" from server rep events | Collective identity; stat content | Milestone posts | `arena_match_events` already stores reps | Low-Med | $0 | P2 content |
| 7 | **Referral rewards** | Cosmetic titles/frames for N accepted challenges | Status cosmetics | Direct invites | Links + analytics events | Medium | $0 (cosmetics) | P2 (test first; risk ofinvite spam) |
| 8 | **Team battles** | 5v5 aggregate weekends | Team identity | Team recruitment | Would need new match grouping | High | — | **Do not build now** (clans-adjacent; contract excludes) |

Self-reinforcing loop check: #1 feeds #2 and #3 (creators need receipts; events need snapshots); #3 feeds content weekly; #5 annualizes it. Start with 1–4.

---

## 4. The growth loop and where it is broken

```
Content / creator link / friend share
   → challenge-web landing (CTA: Open app / Play with referrer)
   → install → sign-in (email OTP or Google) → username
   → [BROKEN 1: no opponent yet → dead tab]      ← fixed by: solo ON day one + streak starts
   → first solo set counted by camera (trust moment)
   → challenge a friend (link/code/QR) or ranked queue
   → accept → prep (framing self-test) → 60s battle
   → receipt + share card with QR
   → [BROKEN 2: sharing is off in the release config] ← flip flag
   → friend opens QR/link → loop repeats
   → [BROKEN 3: nothing brings yesterday's player back] ← fixed by: push (built) + streak reminders + Fight Night
```

Broken points, in priority order: (1) pilot config ships the loop off; (2) no first-run value for opponent-less users; (3) no re-engagement; (4) silent waiting states; (5) unmeasured web funnel; (6) no rematch for the most common post-battle desire ("again, right now" — currently "Share challenge" to the same person is 4 taps).

---

## 5. Monetization without killing growth

**Never paywalled:** battles, ranked, queue, leaderboard, receipts, sharing, solo counting/goal/streak/badges, camera counting. Competition must be exactly fair or the trust positioning dies.

**Free forever / Pro split (decision D-D: annual-first, Play Billing, trial):**
- **Pro (subscription):** extended battle history + advanced personal stats, share-card themes, avatar frames + title cosmetics, event perks (extra event badge slots, event cosmetics), early access to event formats. Target: annual ~$25–35/yr with 7-day trial; monthly ~$5–7 added at Phase C.
- **One-time (later, Phase C+):** "Founder" badge during year one (supports the arena, cosmetic only), cosmetic packs. Never sell score, reps, rating, or counting advantages.
- **Upgrade timing/placement:** only after a receipt exists (post-battle result screen and profile stats are the two placements); trial offered after the 3rd confirmed battle, when value is proven. Never interstitial, never before activation.
- **Anti-pay-to-win guarantees:** cosmetics/stats-only Pro; no matchmaking advantages; ranked integrity untouched; say it on the paywall itself.

**Progression:**
- **Early (0–10k):** zero monetization; every ounce of leverage goes to activation/retention gates.
- **10k:** launch Pro annual-first, cosmetics/stats-only, trial after 3rd battle. Watch D7 of trial cohort vs non-trial.
- **50k:** monthly tier + first one-time cosmetics; fund event prize pools from revenue (revenue → growth, not growth → revenue).
- **100k:** optimize pricing/regions, partnerships, merch-adjacent one-times only if they don't clutter.

**Growth vs revenue:** growth until the Phase-B gates hold 4 consecutive weeks; then revenue. The reason: at <10k users, any paywall friction costs more (lost K-factor) than it earns.

---

## 6. Annual event calendar (fits the arena identity)

| When | Event | Prep | Engineering | Marketing | Cost | Growth | Retention | Monetization |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Every Fri–Sun | **Fight Night Friday** (48h ranked sprint + Monday snapshot) | Season tagline | None (v1: framed window + snapshot export) | Weekly post + creator reshares | $0 | tag-a-friend | weekly ritual | later: event XP cosmetics |
| January | **Resolution Rush** (streak + first-battle drive; "30 days, 20 reps a day") | Content calendar | streak reminder polish | New-year content wave | $0 | resolution search traffic | streak habit | Pro trial push after 3rd battle |
| Quarterly | **Arena Open** ladder weekend → snapshot + honorable mentions | Prize/rules page | snapshot page | creator invites, community posts | small prize pool from Pro revenue | creator participation | seasonal spike | prize funded by Pro |
| Summer | **Last Rep Standing** (longest streak survives) | rules | streak event window | survivor-style content | $0 | challenge-a-friend to outlast | daily return | cosmetics |
| October (anniversary) | **The Arena Open Championship** — top-64 season ladder, streamed finals | 6–8 weeks | bracket page, season reset, anti-abuse review | press + creators + shorts series | prize pool | the flagship spike | season-long runway | sponsor-adjacent later; Pro push during season |

Everything above runs on the existing Elo/leaderboard/solo systems; the only new surfaces are framing (naming/window), snapshot export, and eventually a bracket page.

---

## 7. Content + social media strategy

**Repeatable formats (each is a series, not a post):**
1. **Real battle receipts (BRIEF-01)** — two people, one phone each, live count, decisive receipt. The hero format; infinite episodes.
2. **"Does it actually count?" trust tests (new series from the trust surface)** — deliberately bad reps, sag reps, partial reps, phone-too-far: show the counter reject them; then a clean rep counts. Directly attacks the category's #1 complaint. The skeleton overlay makes this visually legible.
3. **Curiosity hook cuts (BRIEF-04)** — "my phone counted my push-ups and refused to let me lie" style openers; re-cuts of #1/#2, zero new footage.
4. **Creator beat-me sessions (mechanic #2)** — live open-challenge windows; the fan battles become the next episode.
5. **Leaderboard/community stats moments (#3, #6)** — "the arena did 214,000 counted reps this week; Friday the ladder resets."
6. **Setup/framing demos (BRIEF-02)** — how to place the phone; doubles as activation support.

Cadence: 4–7 posts/week across TikTok/IG/Shorts from the same vertical masters; every post carries a challenge-link CTA; measure **activation-per-qualified-visit**, not views (the project's own decision rule).

**The $50 UGC budget — recommendation: do not spend it yet.**
- **Whether to spend:** only after 2–3 weeks of organic posting from the briefs produces one hook with measurable activations. Before that, spending hides whether the problem is the hook or the production.
- **If a hook works:** spend ~$50 on **2 real-person UGC remakes** (Fiverr/micro-creator, ~$25 each) of the *exact winning hook* — real faces outperform AI dramatization per the briefs' own hierarchy (BRIEF-01 is "hero" for a reason). AI-generated dramatization stays the free background pipeline (`tools/social` already builds it); real UGC is the paid amplifier.
- **Hook/CTA:** the winning hook verbatim, ending on the challenge link.
- **Platform:** TikTok first (fastest organic feedback loop), cross-post winners.
- **Test/metric:** cost per **activated player** (first server-confirmed battle via the shared link) ≤ $3–5 → commission more with the next revenue; > $5 or zero activations → stop spending entirely and fix hook/product.
- **Stop rule:** the $50 is fully gone after one failed test; it is a measurement budget, not a marketing budget.

---

## 8. Product-driven marketing (build-inside-the-app)

Ranked by "one active user → multiple exposures":
1. **Result share cards with QR** (built) — every battle ends with an ad for the next battle. Enable everywhere: result screen, history rows, receipt details.
2. **Durable personal challenge link + readable code** (built) — bio-link compatible; add a "My code" surface so users can paste it anywhere without starting a battle flow.
3. **Creator open-challenge mode** (small build) — turns one creator into a faucet of matches and receipts.
4. **Public player cards** (built) — shareable profile pages/URLs (extend `profile_public` into a web card) → "check my arena profile" links.
5. **Leaderboard snapshots** (small build) — weekly PNG export → community content that self-advertises.
6. **Streak/badge cards** (small build) — "30-day streak" share card from the solo system; acquisition from habit content.
7. **Challenge-web as public challenge pages** (built) — every link is already a landing page; add the funnel event and keep it honest.

---

## 9. Lean execution map (impact ÷ effort)

**High impact / Low effort (do these):** close R9 keystore (wizard exists, $0); buy domain + host Supabase free tier (only real spend: ~$10–15/yr domain); host privacy pages (R16); apply R15 controls table; flip pilot flags (camera/solo/links/sharing/push, ranked after R6); camera validation on the owner's Redmi 10 with F3 traces; "My code" surface; enable result sharing; rematch (same-opponent new request); streak reminder local notifications; web funnel event; weekly leaderboard snapshot.
**High impact / Medium effort:** first-run framing self-test; creator open-challenge mode; Fight Night/event framing; Pro subscription (Play Billing); scale fixes (history index, retention jobs, leaderboard cache, outbox pruning); season system.
**High impact / High effort (defer, gate behind metrics):** clip renderer (decision 13 stands), iOS, web battles, realtime migration.
**Low impact / any effort (skip):** extra exercises, chat, followers, clans, coins, battle pass, training plans, AI coaching, pets/minigames.

---

## 10. Testing before scaling (experiments)

| Hypothesis | Test | Cost | Metric | Success threshold | Decision |
| --- | --- | --- | --- | --- | --- |
| People finish a first battle unaided | 20 recruited pairs, two play windows, observe | $0 | % pairs completing 1st confirmed battle | ≥70% | <70% → fix onboarding/framing before any promotion |
| Counting is trusted on real devices | Owner Redmi 10 F3 traces + 50 traced reps vs human count; pilot complaint log | $0 | count agreement; complaints/rounds | ≥95% agreement, <5% complaints | fail → threshold tuning sprint before camera-on |
| Solo-on day one lifts activation | A/B flag on 50% of closed-test roster | $0 | D0 solo completion, D7 battle rate | +15% relative D7 | roll out / revert |
| Hook family X activates | 14-day calendar, 3 hook families (BRIEF-01/02/04) | $0 (AI pipeline) | activation per qualified visit | any hook ≥1% visit→install and ≥25% install→activation | double down on winner; kill losers weekly |
| Real UGC beats AI dramatization | 2 bought clips vs 2 AI clips of same hook | $50 total | activation per $ | ≤$5 per activation | continue or stop (one test only) |
| Fight Night lifts DAU | Run 4 weekly sprints vs prior-week baseline | $0 | matches/hour in window, DAU delta | +20% DAU in window | make it permanent |
| Creator open-challenge converts | 3 creators × 1 session each | $0 (free product) | battles/session, installs attributed | ≥20 battles and ≥50 link opens/session | build the auto-accept toggle |
| Pro pays without hurting growth | Fake-door + price survey in community, then trial cohort | $0 | trial start rate, D7 of triers vs non | conversion ≥2% and D7 delta ≥0 | launch / reposition |
| Referral cosmetics work | 50-user closed test | $0 | accepted challenges/user in 14d | ≥1.5 accepted/user | build properly or drop |

Evidence needed before scaling any winner: two consecutive weeks of the same result, measured in the existing analytics events, with the funnel stage attributed.

---

## 11. Strategic priorities

**P0 — immediately (this is "ship the pilot"):**
1. Execute the owner-input list: keystore (W1), domain + hosted Supabase + SMTP (W2), privacy pages (R16), apply R15. ~$15 cash.
2. Camera-on decision: validate counting on the owner's Redmi 10 with the F3 trace tool; tune thresholds; sign the checklist (R1). *Without this the pilot cannot complete one counted battle.*
3. Pilot release config: camera ON, solo ON, challenge links ON, result sharing ON, push ON after R17, ranked ON after R6 two-device check.
4. Recruit 12–24 closed testers as pairs; run the 14-day content experiment as documentation (accounts per `ACCOUNTS.md`).
5. Ship the small activation/retention set: first-run framing self-test, "My code", rematch, streak reminders, web funnel event.

**P1 — after the 70/30 gates pass:** creator open-challenge mode; Fight Night Friday; scale fixes before 10k DAU; Pro annual launch; creator wave 1.

**P2 — later:** Arena Open quarterly/annual, seasons, referral program, public profile cards, iOS decision, clip renderer revisit.

**DO NOT BUILD:** chat, followers, clans, coins/currency, battle pass, async challenges, extra exercises, training plans/AI coaching, web battles, pets/minigames/spin wheels, any pay-to-win element.

---

## 12. Master 12-month roadmap

**Month 0 (Oct 2026) — Ship the pilot.**
Objective: real strangers complete real battles.
Actions: P0 list above; closed test with 12–24 roster; instrument funnel; capture BRIEF-01/02 footage with the roster.
Expected: production-access application after 14 days of 12 opted-in testers; 20+ confirmed battles.
Metrics: ≥70% pair activation, ≥30% repeat, <5% count complaints.
Gate: all three hit → open soft launch.

**Months 1–2 (Nov–Dec) — Soft launch + content engine.**
Objective: prove one repeatable organic format.
Actions: Play production release in one geo; daily posting per briefs; first Fight Night Fridays; solo A/B; $50 UGC decision point end of month 2.
Expected: first 1,000 registered; 2–3 hook winners identified.
Metrics: activation-per-visit per hook; D1/D7; K-factor.
Gate: a hook family with stable activation and D7 ≥25% → scale content.

**Months 3–4 (Jan–Feb) — Resolution Rush + creator wave 1.**
Objective: seasonal acquisition + first external creators.
Actions: January event; 10–20 micro creators with open-challenge sessions; Pro annual launch behind the gates; scale-fix sprint.
Expected: 1k→10k registered; first revenue.
Metrics: event participation ≥15% DAU; creator session battles ≥20 each; Pro trial conversion ≥2%.
Gate: CAC-equivalent (time+money) per activated player falling, infra stable → go wider.

**Months 5–6 (Mar–Apr) — First quarterly Arena Open.**
Objective: flagship rhythm + monetization tune.
Actions: quarterly ladder event with prize pool from revenue; monthly Pro tier; one-time founder cosmetic test; public profile cards.
Expected: 10k→25k registered.
Metrics: D30 ≥10%; revenue per activated player; organic share rate.
Gate: event ROA (participants and installs per prize dollar) positive → annualize.

**Months 7–9 (May–Jul) — Flywheel + hardening.**
Objective: compound creators + events; prepare scale.
Actions: creator wave 2; Last Rep Standing; referral experiment; abuse/boosting defenses; support automation.
Expected: 25k→50k registered.
Metrics: K-factor ≥0.4; D7 ≥25%; infra cost/DAU bounded.
Gate: 50k with healthy retention → championship runway.

**Months 10–12 (Aug–Oct) — The Arena Open Championship.**
Objective: the flagship annual moment.
Actions: season 1 ladder → top-64 finals streamed; press/creator series; iOS go/no-go decided on unit economics; year-2 plan.
Expected: 50k→100k registered (ceiling case: the format hit + championship coverage; base case without a viral format: 30–60k — do not fake the difference, measure it).
Metrics: registrations from event coverage; finals viewership→install conversion; 100k cumulative registrations.
Gate: none — this is the year-end review.

---

## 13. CEO conclusion

1. **Strongest growth opportunity right now:** the receipt-share loop is already built and simply off. Enabling camera + solo + share cards, then pointing TikTok content at it, is the highest-leverage move in the company — it costs ~$15 and existing tooling.
2. **Biggest threat:** the launch never happens. Every external step has sat blocked on owner inputs for weeks (keystore dry-run since Sep 23, accounts packet since Sep 21, no physical device ever attached). The second threat is shipping camera-off, which makes the pilot a product that cannot finish a battle.
3. **Stop doing:** QA re-verification loops that re-prove already-green suites; speculative research docs; adding flags/off-switches as a substitute for a decision. Freeze all of it until the pilot ships.
4. **Focus disproportionately on:** activation (first battle unaided) and the receipt-share moment — everything else is downstream.
5. **Signature feature:** the **receipt** — a server-confirmed, QR-backed proof of a real 60-second battle, with the skeleton overlay as the trust visual.
6. **Signature event:** **Fight Night Friday**, annualized into **The Arena Open Championship** (top-64 streamed finals).
7. **Free forever:** all competition — battles, ranked, leaderboard, receipts, sharing, solo counting, streaks, camera counting.
8. **Monetized:** cosmetics + extended stats + event perks via an annual-first Play Billing Pro with trial; one-time founder/cosmetic purchases later; never score or counting advantages.
9. **First major growth campaign:** the 14-day real-battle content experiment (BRIEF-01/04) run with the closed-test roster, graduating into Fight Night Friday and creator "beat me" sessions — "Challenge a friend. Battle for 60 seconds."
10. **UGC budget:** hold the $50 until a hook proves it activates; then 2 real-person remakes of the winning hook at ~$25 each, judged on cost per activated player ≤ $5; stop after one failed test.
11. **Before scaling aggressively:** 20+ real pairs complete first battles unaided (≥70%), ≥30% repeat within 7 days, counting agreement ≥95% on real devices, funnel measured end-to-end.
12. **The single most important decision:** declare a launch date and personally clear the owner-input list this week — keystore, domain, hosted stack, and the Redmi 10 camera-validation session. Everything in this document is downstream of the app existing in public.
