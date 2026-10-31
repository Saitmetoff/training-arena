# Competitor analysis — push-up apps (Push Up Arena and adjacent titles)

Research: 2026-09-22 · OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Status: **DRAFT, uncommitted, research only.** No owner decision is taken here,
nothing was purchased or contacted, and no line in this file changes
`docs/CONTRACT.md`, `docs/release/GO_NO_GO.md`, `docs/PROJECT_STATUS.md` or any
release scope. This is not an L-task and adds no status section to
`PROJECT_STATUS.md`. Owner marks and private notes live in
`docs/research/NOTES.md`.

Evidence labels used throughout:

- **[V]** verified from the cited public page on 2026-09-22.
- **[E]** third-party estimate (AppBrain, AppGoblin, MWM, Social Growth
  Engineers, LinkedIn); directionally useful, not audited.
- **[I]** inference from store metadata, review text and publisher portfolios;
  **not** verified by decompilation, purchase or insider access.

## 0. Summary

Two unrelated publishers ship a product called "Push Up Arena". Their growth is
real (400K Android downloads, 93K in the last 30 days) and their product
quality is not (2.0 stars on Android, rep detection broken in a large share of
reviews). They won on **short-form video distribution, not features**. The
repeated creative is one 9:16 format — a body, a pose/skeleton overlay, and a
score or enemy health bar visibly reacting per rep — posted until it hit,
reported at 13.5% viral rate on TikTok and 100M+ organic views/month by
August.

For Training Arena the conclusions are uncomfortable but simple:

1. The distribution inputs are the only thing that cannot be replaced by code
   work (R9 signing, R2 domain, R16 hosting, R1/R7 devices, R6 ranked matrix).
2. The current build gives a new user nothing to do: ranked and camera
   counting are off, and a counted round needs two people. Every successful
   app in this category is playable solo.
3. The growth engine that would work for this product — a real vertical
   capture of a real round — is already scripted (`docs/social/briefs/`) and
   blocked on the same inputs.
4. Do not copy the leader's feature list. They shipped clans, chat, coins, a
   battle pass, a spin wheel, pets and an arcade minigame; reviewers still
   report the core counting as broken and the clan/friend features as
   non-functional.

## 1. "Push Up Arena" is two different apps [V/E]

| | iOS: "Push Up Arena - Fitness Game" | Android: "PUSHUP ARENA" |
| --- | --- | --- |
| Publisher | Airix LLC (US; portfolio: `Duos`, `Victor - Life Reset & AI Coach` — both tiny) | VOLARA (solo developer, Depok, Indonesia) |
| Store ID | `id6762318743` | `com.pushup.arena` |
| Site | `pushuparena.app` | `pushuparena.xyz` |
| First seen | 2026-05-14 [E] | April 2026 [E] |
| Size | 184.1 MB [E] | 115.9 MB APK [V] |
| Installs | ~256K [E] | 400K total, 93K last 30 days [E] |
| Rating | 4.59★, ~3.6–5.1K ratings [E] | **2.0★**, ~980–999 reviews [V] |
| Model | Hard subscription; listing states all features require it [V] | Free + **contains ads** + coins + Season 1 battle pass [V] |
| Feature set | Bosses, dungeons, ranks, horde mode, max reps, speed challenges | AI tracking, PvP lobbies, global chat, clans, streaks, 30-day challenge, spin wheel, Coach Max, arcade minigame |
| Latest seen | 1.3.0 (2026-08-06) [E] | 1.1.0 (2026-09-19) [V] |

Three more titles use the same name or close variants: "PushArena" (Solo
Leveling-styled, ssssstudios), "Push Up Challenge: PushArena", and "PUPG -
Push up playground". At least five apps now compete for the "Push Up Arena"
brand, and third-party estimates for the name may conflate them. Any decision
that references "Push Up Arena" numbers should say which publisher it means.

## 2. How it is built [I]

No APK/AAB was downloaded or decompiled. The following is inferred and should
be treated as a hypothesis:

- **Likely shape.** A cross-platform shell with a bundled on-device pose model
  (ML Kit / MediaPipe / TFLite class) plus heavy art and audio. Bundle sizes
  (116 MB Android, 184 MB iOS) and the on-device-processing claims are
  consistent with that, and with Training Arena's own ML Kit choice.
- **"AI-built" is not speculation about the code; it is what their users say**
  [V]: "used a lot of AI to make it", "copy and paste chatgpt designs", "a
  questionnaire to pretend they care about me then boom, paywall". The funnel
  is the template: quiz onboarding → immediate hard paywall → feature-checklist
  store copy with a keyword-stuffed `Tags:` line.
- **Publisher portfolio pattern.** Airix LLC's other two apps have 149 and
  ~2.2K installs [E]. This is a spray of small AI-assisted apps; Push Up Arena
  is the one that found a hook.
- **Engineering pace is feature churn, not hardening.** v1.1.0 (2026-09-19)
  adds clans, battle pass, spin wheel, arcade minigame and "Coach Max" while
  the top-voted Android reviews remain about counting failures and clans that
  do not work [V].
- **Review-verified weaknesses** [V]: reps not counted on real push-ups,
  camera movement counted as reps, clans/friends non-functional, Android↔iOS
  cross-play missing, paywall before any value, AI art style called cheap, and
  even the daily 100-rep goal reportedly gives no reward.

## 3. How it grew [E]

- Social Growth Engineers, 2026-06-22: Top 100 Health & Fitness in 50+
  countries 39 days after the 2026-05-14 iOS launch; two accounts,
  **11M+ views in a few weeks** (3.4M Instagram / 7.9M TikTok).
- TikTok was the repeatable engine: same visual setup, reported
  **13.5% viral rate**, four separate breakouts; the original hit reached
  3M views and 59K saves with the hook **"what is this app bro"**.
- Instagram was dead until a single 2026-06-14 clip reached 3M views with the
  hook **"bro WHO made this"**.
- LinkedIn (2026-08-05): **100M+ organic views per month** with UGC, ~40K
  installs/month at that point.
- The creative [E]: a real person doing push-ups with a pose/skeleton overlay,
  and an enemy health bar or score dropping per rep. Zero explanation needed;
  the hook imitates organic user curiosity rather than advertising. Audience:
  young male gamers who train.
- Repeat discipline is the actual mechanism: the same footage pattern re-cut
  with new openings, not new concepts. (The brief drafted alongside this file,
  `docs/social/briefs/BRIEF-04-curiosity-hook-cuts.md`, applies that lesson
  inside the existing truth rules.)

## 4. Adjacent field (selection, all [E]/[V] from store listings)

| App | Platform | Traction | Rating | Model | What it demonstrates |
| --- | --- | --- | --- | --- | --- |
| **Stryv** | iOS + Android | 10K+ | 4.6–4.8★ | $2.99/wk · $9.99/mo · $59.99/yr | Closest positioning to Training Arena: 1v1 push-up battles, AI rep verification, browser battles. Pivoted to "Crews" accountability; modest traction despite good ratings |
| **PUPG** | Android | 10K+ | **1.33★** | Free | Same boss-battle formula shipped worse; shows how thin the clone layer is |
| **PushArena** (Solo Leveling) | iOS | n/a | n/a | $12.99/mo · $29.99/yr | E→S rank gates, friends, and **Focus Shield: reps unlock screen time** |
| **Push Up Boss** | iOS + Android | n/a | n/a | Free + sub | Best counting UX: multiple modes, front/side view, anti-cheat calibration, form feedback |
| **PUSHapp** | Web PWA + iOS + Android | n/a | n/a | Free | No signup, voice counting, depth validation, renders a shareable proof video, content-led marketing |
| **Pushup RPG: Fitness Quest** | Android | 100K+ | 4.8★ | Free | Plain RPG progression still sells |
| **PushUp: Screen Time & Fitness** / **PushUp Time** / **ScrollToll** | Android | 100K+ each | 4.5–4.7★ | Free | "Reps are the currency for screen time" is a breakout mechanic repeated across at least three apps |
| **RepChamp / Fit Arena / PushArena (Kamil)** | Android | 5–10K+ | 4.3–4.5★ | Free | Long tail of undifferentiated duels and counters |
| Incumbents: Hevy, Strong, Freeletics, Simple Design "Push Ups" | both | up to 10M+ | ~4.7★ | freemium/sub | They own logging and plans; none owns camera-counted competition |

## 5. Category economics [E]

From RevenueCat / Adapty "State of Subscription Apps 2026", Health & Fitness:

- Annual plans are 68% of revenue in the category; the most common annual
  price band is $49.99–79.99.
- Median trial-to-paid is 37.7%; median download-to-paid is 2.9%.
- 82% of trial starts and about half of conversions happen on Day 0; the
  second window is Day 4–7. Onboarding paywalls with a trial convert best
  (1.78% install-to-paid).
- Hard paywalls convert ~5× better than freemium, but churn 20–30% faster when
  value is not delivered first. Push Up Arena is the case study: hard paywall,
  broken core feature, 2.0★ Android.
- Fitness churn benchmarks: median 10–13% monthly; users who do not complete
  their first value moment churn at 4–5× the rate of those who do.

## 6. Training Arena gap list

Severity is relative to the observed market, not to internal release gates.

| # | Gap | Evidence | Severity |
| --- | --- | --- | --- |
| CA-G1 | **No distribution at all.** No account created, no footage, nothing published; the L09 packet is drafted and blocked on owner inputs | `docs/social/ACCOUNTS.md`, `CONTENT_EXPERIMENT.md` §8, `PROJECT_STATUS.md` L09 | Fatal in this category |
| CA-G2 | **No solo loop.** A new user with no friend cannot do anything; with camera counting off (R1) a counted competitive round cannot even complete | `docs/CONTRACT.md` §1 bans plans/async; `GO_NO_GO.md` R1 | Critical |
| CA-G3 | **No habit mechanics.** No streaks, daily goal, XP/levels, badges, personal bests or stats history | `docs/CONTRACT.md` §1 (absent by design) | Critical for retention |
| CA-G4 | **No shareable video.** Only a static result card renderer exists; the category's growth engine is a vertical clip | `app/lib/sharing/result_share_card_view.dart`; §3 above | High |
| CA-G5 | **Single platform, no cross-play.** No `app/ios/`; the competitor's own reviewers ask for Android↔iOS play | repo tree; §2 above | High |
| CA-G6 | **Counting accuracy and trust unproven.** No physical device has run the camera path | `GO_NO_GO.md` R1/R7, L04 | High — it is the category's #1 complaint |
| CA-G7 | **No monetization path designed.** Zero billing code; correct for launch, but no funnel exists to switch on later | repo search; `LAUNCH_PLAN` §business | Medium |
| CA-G8 | **Brand and ASO collision.** "Arena" appears in at least five app names in this niche; the exact name is already contested by two publishers | §1 above | Medium |
| CA-G9 | **iOS absent** while the highest-rated competitor product is iOS-first | repo tree; §1 above | Medium — do not start before CA-G6 |

Not a gap worth closing: social/chat/economy features. See the reject list in
§7.

## 7. Draft response plan (owner decisions pending)

Ordered by what unblocks what; every P0 item is an owner input, not code.

### P0 — distribution inputs (no code substitutes for these)

| Item | Gate | Owner action |
| --- | --- | --- |
| Keystore + CI secrets | R9 | `docs/release/CONFIGURATION.md` §3 |
| Real domain + `assetlinks.json` | R2 | owner supplies D1; then `check_app_links.mjs --release` |
| Hosted project + auth | R3 | L05 packet §0–§2 |
| Hosted privacy/support/deletion + owner identity/contacts/retention | R16 | L07 §9 + L05 target |
| Physical devices + camera checklist | R1/R7 | `qa/launch/l04/DEVICE_VALIDATION_PACKET.md` |
| Two-phone ranked matrix | R6 | two physical devices |

### P1 — activation and retention (needs owner decision to reopen scope)

1. **Reopen `CONTRACT.md` §1 for a solo mode** (personal max-reps test, daily
   goal, 30-day challenge). Evidence: CA-G2 + §4; every live competitor is
   solo-playable, and solo is also the honest demo format when no opponent
   exists.
2. **First-run calibration test.** The max-reps test doubles as camera
   calibration and the Day-0 value moment. Evidence: §5 Day-0 windows + CA-G6.
3. **Streaks, daily goal, personal bests, badges.** Cheapest retention in the
   category; the leader's own users complain that even their daily goal pays
   nothing. Evidence: CA-G3 + §5.
4. **Trust surface:** verified-rep badge, on-device/no-recording statement,
   server-confirmed results shown in the UI. Evidence: CA-G6, §2 review
   themes (cheating and recording fears are live user emotions).

### P2 — growth engine (after P0/P1 gates)

5. **Vertical clip renderer** reusing the existing share-card pipeline: real
   capture + live count + both score panels, 9:16. Evidence: CA-G4, §3.
6. **Web battle fallback** on `challenge-web/` so a challenged friend without
   the app can finish a round in the browser. Evidence: CA-G5; it is the
   cheapest cross-platform answer before iOS.
7. **ASO pass** against the leader's keyword gaps (rep, counter, workout,
   challenge, friends, strength) once the listing is unlocked. Evidence: §2.
8. **Execute L09 content** plus `BRIEF-04` hook cuts. Evidence: §3.

### Reject list (do not build)

Clans, global chat, coins, battle pass, spin wheel, pets, rival AI coach,
arcade minigame, extra exercise types beyond the reviewed set. Evidence: the
leader shipped all of these and stayed at 2.0★ on Android with broken core
features; §2.

### Decisions required (IDs referenced from `NOTES.md`)

- **D-A:** Reopen `CONTRACT.md` §1 for solo mode? (P1.1)
- **D-B:** Rename before the store listing is locked, or accept ASO against a
  contested "Arena" name? (CA-G8)
- **D-C:** Camera on/off scope for the first pilot (R1): sign the checklist, or
  accept that counted rounds cannot complete.
- **D-D:** Monetization intent: stay fully free through validation, or design
  the annual-first funnel now and switch it on after retention evidence.
- **D-E:** Whether CA-11 (reps as screen-time currency) is studied, ignored or
  rejected — it is a breakout mechanic in this niche but outside the current
  contract.

## 8. Marking surface

Owner marks go in the final two columns (or in `docs/research/NOTES.md` by ID).
Suggested values: **KEEP**, **REJECT**, **LATER**.

| ID | Idea | Evidence | Agent draft verdict | Owner mark | Note |
| --- | --- | --- | --- | --- | --- |
| CA-01 | Copy the curiosity-hook content format (caption as viewer's question, not a product premise) | §3 | KEEP | | |
| CA-02 | One repeatable visual format, re-cut with new openings, not new concepts | §3 | KEEP | | |
| CA-03 | Solo mode (max-reps test, daily goal, 30-day challenge) | CA-G2, §4 | KEEP | | |
| CA-04 | Streaks, personal bests, badges | CA-G3, §5 | KEEP | | |
| CA-05 | Vertical share clip from real capture | CA-G4, §3 | KEEP | | |
| CA-06 | Web battle fallback / cross-play wedge | CA-G5 | KEEP | | |
| CA-07 | Verified-rep trust surface + honest partial reps | CA-G6, §2 | KEEP | | |
| CA-08 | Onboarding paywall + annual-first + trial, after first value | §5 | LATER | | |
| CA-09 | ASO keyword pass before listing lock | §2 | KEEP | | |
| CA-10 | Rename decision before listing lock | CA-G8 | OWNER DECISION | | |
| CA-11 | Reps-as-screen-time-currency mechanic | §4 | OBSERVE | | |
| CA-12 | Reject clans/chat/coins/battle pass/spin wheel/pets/minigame | §2 | REJECT | | |
| CA-13 | iOS build | CA-G9 | LATER (after CA-07) | | |
| CA-14 | UGC creator seeding at scale (the leader's actual August engine) | §3 | LATER (cost/decision) | | |

## 9. What this file does not claim

- No decompilation, purchase, download or account contact was performed; §2 is
  inference.
- Third-party numbers are estimates [E] and may conflate the two publishers.
- The claim of "100k+ social followers" was not independently verified; only
  view counts and the August UGC figure are cited, both [E].
- No capability, accuracy or anti-cheat claim is made for Training Arena here;
  the camera path remains unvalidated on physical hardware (R1/R7).
- Nothing in §7 is approved. Items become work only through the normal owner
  decision and task path.
