# Fault — Stage 1 brief and first copy

Prepared 4 October 2026. Codex owns the claims, positioning, copy selection and brief. Required OpenCode assignments completed; evidence below. This is a local planning deliverable, not a website, distribution approval or live waitlist. The bespoke $30,000 standard describes quality; it authorizes no spending.

## Recommendation and audience

**Lead with a personal push-up practice loop.** Recommended headline: **Give your next set a reason.** Pair it with an explicit prelaunch description and a real self-reported solo demonstration. Camera counting and completed battles cannot presently carry the offer.

Primary audience hypothesis: adults who already do bodyweight exercise, especially push-ups, and want a concrete reason to return to another set. Their job is to record an effort and compare it with their own previous efforts. Start with English copy and Android interest; launch countries remain unspecified. Friendly competition is a later audience expansion, conditional on product evidence. Audience fit, motivation and conversion are hypotheses, not research findings.

Positioning: Fault is a focused rep-practice app in development for people who want their push-up effort to leave a useful record. The first experience centers on self-reported sets, device-local history and personal bests. Its credible distinction is focus and an honest counting source; do not claim category uniqueness, increased strength, better adherence or superior accuracy.

Recommended product promise: **Turn a push-up set into a record—and a reason to return.** This describes intended use, not a guaranteed fitness outcome.

Two alternatives within the same scope:

- **One set. Saved. A reason to return.** More literal and close to the worker's second variant; always paired with the prelaunch subline and actual successful-save footage.
- **Every rep. More reason.** Stronger brand line from the website plan; requires the self-reported explanation beside it so visitors do not infer automatic counting.

Current reference check, 4 October 2026: [Hevy's exercise tracking page](https://www.hevyapp.com/features/track-exercises/) emphasizes prior performance and records; [Freeletics' bodyweight page](https://www.freeletics.com/en/bodyweight-training/) emphasizes personalized training. These support a positioning inference: generic “track progress” language is crowded; Fault should express its narrow set-to-record loop concretely. These pages establish neither demand for Fault nor a competitor performance comparison. No third-party media is proposed for reuse.

## Product truth and claims matrix

Evidence classes: **verified behavior** means a named recorded check or direct source finding, with its environment stated; **implemented but unverified** means code exists without the necessary physical/hosted release proof; **future scope** means gated, deferred or undecided. Automated verification is not a physical exercise validation. All paths below are relative to `D:/TrainingArena`; citations identify existing files and line ranges.

| Topic | Evidence and class | Website permission / restriction |
| --- | --- | --- |
| Name/domain | Owner supplied Fault and purchased fault.fit. Legacy name remains in `docs/CONTRACT.md:11`, `docs/decisions/12-competitive-direction.md:25–33`; source ID is `app/android/app/build.gradle:24–45`. | Use Fault/fault.fit in this brief. Rename is not implemented; capture captions must acknowledge legacy UI until recaptured. Keep `app.trainingarena.mobile`; domain purchase does not establish hosting or App Links. |
| Solo exercise | Verified source behavior: camera factory uses push-ups at `app/lib/solo/runtime/solo_controller.dart:197`; every result uses push-ups at `:339–347`; current UI explicitly says complete your push-ups at `app/lib/solo/ui/solo_page.dart:160–167`. | **Push-ups only for the present solo promise.** Broad contract coverage of squats is not a solo exercise selector. Do not promise solo squats. |
| Solo entry/count | Manual path and source label at `app/lib/solo/runtime/solo_controller.dart:303–335`, `app/lib/solo/domain/solo_result.dart:13`; signed-out policy at `docs/release/PILOT_PLAN.md:11–20`. Automated solo-first/save regressions recorded in `qa/beta/checkpoint-results.json:22–30`. Physical first-session walkthrough pending at `PILOT_PLAN.md:27`. | Describe development toward signed-out, self-reported solo. Show explicit manual entry; no app-measured rep overlay. No account required for solo; email waitlist confirmation is a separate process. |
| History/bests/save | Verified implementation: durable store `app/lib/solo/data/solo_result_store.dart:45–104`; save/failure logic `app/lib/solo/runtime/solo_controller.dart:361–393`; same-exercise/source best `app/lib/solo/domain/solo_result.dart:143–158`; seven local calendar days `:160–175`. Automated checkpoint confirms delayed history and failure handling (`qa/beta/checkpoint-results.json:23–25`). Phone save/restart unverified. | Local record and last-seven-days view; best is within retained history and counting source. Store retains newest 100 entries (`solo_result_store.dart:14–20`); do not promise lifetime records, cloud backup, sync or unlimited history. |
| Solo competition boundary | `docs/CONTRACT.md:17–23`; UI `app/lib/solo/ui/solo_page.dart:98–100`; `docs/decisions/12-competitive-direction.md:14–17`. | Practice does not create a server receipt, rating or leaderboard entry. Do not call a self-reported count a verified competitive score. |
| Camera | Implemented bridge `app/lib/camera/bridge/platform_camera_bridge.dart:11–73`, profiles for push-ups/squats `app/lib/camera/counter/exercise_profile.dart:45–87`. Device record `qa/camera/beta_device_results.json:2–8` is blocked, commit/reviewer absent, devices empty. | **Implemented but physically unverified; off.** “Camera counting is being tested” is allowed. No automatic-counting benefit, accuracy percentage, form certification or cheat-proof claim. Front/side push-up and side squat support are implementation targets, not verified device compatibility. |
| Camera evidence gate | `tools/release/check_camera_evidence.mjs:6–37` requires reviewed two-model physical evidence; `:47–54` also checks app source agreement. Fresh command on 4 October exited 1: missing reviewed record and two distinct physical phones. | A fixture pass or compile cannot enable marketing claims. Follow `qa/camera/device_validation_checklist.md`; record human/app counts, alignment, failures, device/build/hash and review. |
| Camera privacy | On-device processing contract `docs/CONTRACT.md:20–23`; native analyzer closes frames and transfers numbers `app/android/app/src/main/kotlin/app/trainingarena/mobile/camera/PoseAnalyzer.kt:14–18,93–104`; inventory `docs/privacy/DATA_INVENTORY.md:112–133`. | Can explain the implemented design: camera frames processed on phone, not uploaded for counting. Do not promise “no data collected” or conflate signup email with camera data. Re-audit the eventual candidate; debug numeric trace export is a separate gated function. |
| Battles | Contract loop `docs/CONTRACT.md:15–28`; actual practice/ready controller `app/lib/battle/runtime/battle_controller.dart:615–665`; camera-only rep rejection `:978–989`. Latest gate `docs/release/PILOT_PLAN.md:17–31`: camera-off cannot complete counted battles; hosted validation unconfigured. | **Implemented but unverified for release.** No live friend-battle hero, actual-win claim or downloadable competitive offer. Later casual battle demo requires two physical phones, hosted accounts and identical full-round receipts. Server receipt is not independent physical verification. |
| Ranked/push | Beta pins `docs/release/PILOT_PLAN.md:17–20`; candidate workflow `.github/workflows/release-checks.yml:228–235`. | Off. No ranked play, live matchmaking, notification delivery or public leaderboard benefit. Links/sharing/solo are pinned on; safe config defaults are false—different contexts, not a contradiction. |
| Platforms | Android first/English at `PILOT_PLAN.md:15`; `app/android/app/build.gradle:24–47` sets minSdk 24, target 36. Native Android bridge above. Browser decision `docs/decisions/14-web-battle-approach.md:42–51`; current funnel `challenge-web/README.md:3–19`. | “Android first” is a direction, not a compatibility guarantee. No established iOS launch or browser gameplay. Public website can be responsive on iPhone without the app being available on iOS. |
| Availability | `qa/beta/checkpoint-results.json:2–5,32–39` identifies version 1.0.1+2 as local/non-distributable and lists physical, hosted, domain/legal, signing and media gates. `docs/PROJECT_STATUS.md:32–39` says not shipped. | Prelaunch waitlist only. No store badges, download CTA, access date, countdown or “available now.” Purchased domain resolves the naming input, not integration/configuration. 30,000 emails is an audience trigger alongside readiness checks. |
| Pricing | Free through validation, later pricing intent at `docs/decisions/12-competitive-direction.md:53–58`; beta direction `PILOT_PLAN.md:15`. | First beta planned free. No “free forever,” subscription offer or established public pricing. |
| Export/web future | Clip decision `docs/decisions/13-share-clip-approach.md:3–4,14–21,32–35`; browser decision `14-web-battle-approach.md:42–51`. | Static card implementation is distinct from a completed real battle. No in-app video export, browser rounds, or new-feature delivery commitment. Website production recording does not imply an app export feature. |
| Prototype | `prototype/README.md:3–7,29–34` explicitly simulates all data and compresses rounds. | Design references only. No screenshot counts, fixture users, wins or testimonials as product/customer evidence. |

Evidence precedence: the 30 September checkpoint and current source supersede the older 21–22 September L07/L11 packets for scope/build identity. `qa/launch/l11/L11.md:9–31` remains useful historical release QA, not a present approval. The broad battle-oriented design principles in `design/arena/DESIGN_SYSTEM.md:20–31` do not override the later solo-first release decision.

## Page narrative and actual first-draft copy

One public anonymous landing page; primary job: understand the proposed experience and confirm an email. Landing-page recipe with durable waitlist capability in later stages. No production stack or paid plan chosen here.

1. **Effort → reason. Hero:** oversized type, real push-up effort, visible email action. Immediate clarity before media loads.
2. **Reason → record. Product proof:** a short, captioned solo sequence: complete push-ups → enter own count → save → review record. Label development build and self-reported source.
3. **Record → repeat. Three benefits:** own entry, local comparison, quick signed-out start. Avoid a wall of capabilities.
4. **Release boundary. FAQ:** camera/battles under test, Android-first direction and prelaunch access. Keep this readable, not hidden behind optimistic claims.
5. **Return to the action. Final signup/footer:** repeat the same CTA; privacy/support links and confirmation explanation. Preserve existing public routes at implementation.

**Hero**

Eyebrow: `FAULT · IN DEVELOPMENT`

Headline: **Give your next set a reason.**

Subline: **Fault is being built for solo push-up practice: enter your own rep count, save the set on your phone, and compare it with your previous sets. Android first.**

Button: **Join the waitlist**

Helper: **Confirm your email for Fault launch updates. Joining the list does not give you app access.**

Form label: **Email address**. Consent beside the action: **Send me Fault development and launch updates. I can unsubscribe at any time.** Privacy link required. This is proposed flow copy; no form or email delivery exists as a result of this stage.

**Product proof**

Heading: **Do the set. Keep the record.**

Caption: **Development build · Solo push-ups · Reps entered by the athlete.** Until renamed, append **App shown under its earlier name, Training Arena.**

Three beats: **Complete your push-ups. Enter your count. Save and review your set.** Keep actual “Self-reported” UI visible. Do not imply the footage drives an automatic counter.

**Benefits** — under the heading **A reason to come back.**

- **Your effort, recorded.** Complete a push-up set and enter the reps yourself. Your result is clearly marked self-reported.
- **A record to compare.** Review your last seven days and your personal best within saved history. Results stay on your phone.
- **Start on your own terms.** Solo practice works without an app account. Your sets are personal practice, separate from competitive ratings.

These benefit cards describe the development experience established in source and automated checks. Place them beside the development demo, not as promises of a released app; publish demonstration only after the physical solo walkthrough.

**FAQ**

**What can I do in Fault?** The first experience centers on solo push-ups: complete a set, enter your own rep count, and save it on your phone. You can review recent sets and your personal best within saved history. Fault is still in development.

**Does the camera count my reps?** Camera counting is being tested and is not available in the current beta scope. For now, you count your push-ups and enter the number yourself. We will explain supported setups when device testing is complete.

**Can I battle a friend?** Friend battles for push-ups and squats are in development. They need camera counting and further device and online testing before we can offer completed battles. We are not announcing battle availability yet.

**Do I need an account?** Solo practice is designed to work signed out. Battles require sign-in. Joining the website waitlist confirms your email; it does not create an app account.

**Which phones will be supported?** We are preparing Fault for Android first. The tested device list will be shared before access opens. We have not announced an iPhone release or browser gameplay.

**Do I need equipment?** The current solo experience is for bodyweight push-ups and recording your count on an Android phone. Camera setup guidance will be published if camera counting becomes available. No gym equipment requirement is implied; no fitness suitability claim is made.

**When will it launch?** There is no confirmed public launch date. Join and confirm your email for updates. Our audience goal is 30,000 confirmed subscribers; the app also needs to pass release checks before public launch. Signing up does not unlock access.

**Will it be free?** The first beta is planned to be free while we validate the experience. Public launch pricing has not been finalized.

**What happens to camera footage?** The camera implementation processes frames on the phone instead of uploading them for counting. Camera counting remains under test. Your waitlist email is handled separately, under the website privacy policy.

**Final CTA:** **Make room for your next set.** / **Join the waitlist** / **Confirm your email. Get Fault updates when there is something to share.**

**Flow copy for later implementation:** submitted: “Check your inbox. Confirm your email to join the Fault waitlist.” confirmed: “You're on the Fault waitlist. We'll email you with launch updates.” expired: “This confirmation link has expired. Request a new one.” error: “We couldn't complete that request. Please try again.” Retry/duplicate UI should avoid exposing another person's subscription status; details belong to Stage 3.

## Identity direction

Performance editorial is the provisional recommendation: real exertion, large Inter, strong crops and deliberate spacing. Charcoal `#17191A`, soft white `#F6F7F2`, graphite `#242729`; lime `#D6FF3F` for the person/action; violet `#BEA1FF` reserved for a real opponent when supported. Source: `design/arena/DESIGN_SYSTEM.md:23–29,35–54,66–90`; runtime mirror `app/lib/theme/arena_tokens.dart`.

Voice: direct, energetic, spare and respectful. “Do the set. Keep the record.” is on voice; shame, punishment, guaranteed transformation and faux scientific language are not. “Fault” should evoke effort and another attempt, not celebrate unsafe form or failure. Do not make the name itself a claim about form detection.

Stage 2 can compare exactly three treatments with the **same approved solo copy and proof**: performance editorial, competition broadcast, camera lab. The latter two may borrow visual composition but cannot show functioning unverified features. New Fault wordmark is required; existing Arena marks are references. No gradients, glows, decorative opponent scores or animated live timer digits. Video needs captions, controls, poster and reduced-motion fallback; signup must be usable before playback.

## Asset inventory and practical shot list

| Existing input | Exact paths / evidence | Status and use |
| --- | --- | --- |
| Identity/tokens/fonts | `design/arena/tokens.json`, `arena-mark.svg`, `arena-mark-mono.svg`, `arena-mark-1024.png`; `app/assets/fonts/`, `app/assets/fonts/LICENSE`; typography provenance `docs/media/PROVENANCE.md:14–17` | Existing project identity reference; Inter licence recorded. Marks say Arena; create Fault wordmark in Stage 2. |
| Prototype captures | `prototype/screenshots/01-battle-home-incoming.png` and other captures; `prototype/README.md:3–7,76–82` | Internal design references; simulated product behavior, not usable proof. |
| Mannequin loops/posters | `app/assets/media/athlete/manifest.json`, `loops/pushup_loop.mp4`, `loops/squat_loop.mp4`, corresponding WebP, `posters/pushup_start.png`, `models/athlete_mannequin_v1.glb` | Original procedural project media per `docs/media/PROVENANCE.md:14–26`; still excluded from release pending human review at `:83–89`. Release report `qa/media/validation_report_release.json:4–6` fails. Review references, not athlete footage or camera evidence. |
| Historical app captures | `qa/integration/screens/l07_01_battle.png`, `l07_02_signin.png`, `l07_03_profile.png`, `l07_03_settings_privacy.png`, `l07_04_settings_links.png`, `l07_05_history.png` | Files present; 21 September emulator/local-test-account captures. `qa/launch/l07/SCREENSHOTS.md:3–18,37–40` records build limitations. Its table numbering differs from actual privacy/history filenames; use actual paths. Recapture latest solo scope. Exclude `l07_excluded_leaderboard.png` (fixtures). |
| Integration walkthrough | `qa/integration/evidence/t10r2/01_cold_link_signed_out.png`, `12_preparation_camera.png`, `13_ready_blocked.png`, `14_result_opponent_absent_defect.png`; `docs/PROJECT_STATUS.md:62–92` | Historical emulator QA, including a defect and unre-captured fix. Internal review only; no full battle proof. |
| Production content | No accepted current solo phone demo, Fault lockup, permissioned adult footage or testimonial identified in scoped inventory | Must create/obtain and log permissions. AI dramatizations and social briefs are not footage or customer evidence. |

Record a media manifest before publication: path, creator/rights holder, written permission or licence, date/build/commit/hash where applicable, intended crops, caption, usage scope and release status. Real participant footage is `unknown` until permission is recorded; use consenting adults and synthetic demo identities, never private tester contact data. Facts and rights require separate review.

**Priority shoot: one genuine 15–25 second vertical solo edit**, with a full uncut take kept as evidence. Shoot 9:16 first, frame safe for 4:5 and wide desktop crops; capture device UI separately at readable resolution and preserve chronology.

| Shot | Action / screen | Editorial purpose and proof requirement |
| --- | --- | --- |
| 1 · 0–3s | Adult prepares for push-ups; phone within reach | Real effort hook. Establish room and stable framing; no automatic-count graphic. |
| 2 · 3–8s | Several genuine push-ups; keep full take | Show the activity. If condensed, label edit; no implication that those few seconds are an entire max-reps set. |
| 3 · 8–13s | Latest build, signed out → Solo set → manual entry | Show actual route and the athlete entering the actual completed take's count. Keep self-reported label readable. |
| 4 · 13–18s | Save → success → history | Only show Saved after actual persistence. Record restart and same result in a separate verification take. No fabricated values. |
| 5 · 18–23s | Actual history/result then Fault/fault.fit end card | Connect effort to record and the waitlist action. Show personal-best badge only if genuinely triggered by saved demo history. |

Supporting assets: 3–5 movement clips (setup, full rep side/front, finish/reaction); 4–6 latest captures (signed-out solo entry, self-reported entry, result, saved history, actual best if achieved, honest camera-off notice); poster showing real effort with readable title; Fault wordmark and social lockup. Main hero uses push-ups; squat footage stays outside the present solo demonstration.

**Separate gated camera/battle shoot:** only after the signed checklist and matching candidate are reviewed. Film stable front/side push-up and side squat setups, the real practice rep, live app counting and human comparison; include recovery/setup limitations. For battles, record invite/accept, both ready, full 60-second round, identical confirmed receipts and fresh rematch on two physical phones with hosted accounts. Preserve full takes. An edited demo cannot replace this evidence. Until then, no live counter overlays or winner stories on the landing page.

## Waitlist definition and video attribution

The public app launch audience target is **30,000 unique confirmed, currently subscribed addresses, excluding duplicates, detected abuse and known delivery suppressions**. At a stated snapshot time count distinct canonical address records with confirmation completed, active consent/subscription, no unsubscribe, and no active suppression (hard bounce, complaint or provider suppression). Pending, invalid, fake/referral-abuse and internal test records count zero. Do not equate “no known suppression” with proven future deliverability.

Canonicalization must be deterministic: trim, validate, normalize domain and apply one documented deduplication rule consistently; do not silently collapse Gmail dots/plus aliases or merge different mailbox identities. Count addresses, not presumed people. Reconfirmation/reactivation changes eligibility, never creates a second address count. Confirmation, unsubscribe and provider events must update the source of truth idempotently. The 30,000 threshold must also pass app readiness and delivery checks; website launch and public app launch are separate.

Give every video a stable `content_id` and every platform/edit a distinct `creative_id`; link with `utm_source`, `utm_medium`, `utm_campaign`, `utm_content` and allowlisted IDs. Save first attributable landing touch and the last eligible touch at signup with timestamps; snapshot the last touch onto the pending subscriber so confirmation on another device does not lose it. Never put email or confirmation tokens in analytics/URLs.

Proposed attribution rule: **last eligible identified website touch within 30 days before submission** is the primary acquisition credit; retain first touch for analysis. Persist via permitted first-party state or the current session; use the actual privacy/consent choice in implementation. Confirmation inherits the saved signup snapshot. Organic bio links shared across several videos receive campaign/bio credit, not invented per-video credit. Direct/unattributed stays explicit; self-reported discovery is a separate optional field. A referral can record a referrer ID without overwriting the original acquisition record.

Emit `landing_view`, `demo_play`, `waitlist_submit`, `waitlist_confirmed`, `share_click` and subscription/suppression changes. `waitlist_confirmed` occurs server-side once per newly confirmed canonical address with an opaque ID, never on every confirmation-page refresh. Attribute one address to one primary creative; preserve later attrition against that cohort. Expose gross confirmations and current net eligible cohort separately.

Measure confirmed signups per 1,000 **reported platform video views**, visits per view, unique valid submissions per visit, confirmations per valid submission, unsubscribe/suppression rates and net eligible subscribers. Report date range, view definition, attribution window, confirmation lag and unknown share. Views are not unique people and cross-platform sums contain repeat exposure. The website plan's 1% visit / 25% submission / 80% confirmation model is only a hypothesis; estimate growth and time to 30,000 from measured cohorts, not assumed rates. No current signup total, acquisition cost or growth rate is established.

## Decisions, unresolved facts and stage acceptance

Codex decisions: solo push-up-first recommendation; future-development framing; motivation headline plus literal self-reported product sentence; performance editorial direction; one waitlist action; no speculative feature proof. User name/domain instructions override the older keep-name decision for marketing, without rewriting the app contract in this stage.

Only high-impact owner decisions remain:

1. **Campaign boundary:** endorse solo-first messaging, or require camera and battle validation before public acquisition. The latter requires a re-verified claims matrix and new footage before switching the hero. A clarification was sent; absent a reply, this document uses the existing solo-first decision provisionally.
2. **Launch geography:** choose initial countries. English-speaking adults are a content assumption, not a finalized geographic release promise.
3. **Demonstration input:** identify the build to film and a consenting adult/recording owner. Need physical solo save/restart evidence and latest captures before public proof. Camera/battle requires the additional evidence above. Do not substitute generated actors or prototype states for product proof.

Other release dependencies already documented: signing, hosted auth/backend, fault.fit integration/App Links, legal/contact/retention values, reviewed media, device compatibility and final pricing/access procedure. None needs an external write to complete this brief; none is silently treated as complete.

**Stage 1 alignment check:** headline promises a reason to return, literal copy promises a self-reported push-up record in development, narrative demonstrates manual entry/save/history, and release scope says Android-first solo with no current public access. All agree. The brief and copy are complete; real-footage production and physical validation remain prerequisites to publishing product proof, not claims of work done here. No automated product suite was rerun for this documentation-only stage. Existing test results are cited as historical evidence; the camera completeness gate was rerun and remains blocked as expected.

## OpenCode delegation

Both assignments used the CLI explicitly with `--model opencode-go/deepseek-v4.1-flash --agent plan --format json --dir D:\TrainingArena --file <packet>`; one worker at a time, no external writes. Authentication/model access succeeded on actual dispatch. Provider: OpenCode Go. Global config/credentials unchanged.

| Assignment | Status / session | Local evidence |
| --- | --- | --- |
| `01-inventory` | **Accepted with Codex qualification.** `ses_efa302e8dffequJNy4JwxNG0b5` | `tmp/fault-opencode/01-inventory.task.md`, `.report.md`, `.events.jsonl`, `.baseline.txt`, `.usage.json` |
| `01-copy` | **Accepted with Codex factual repairs and final selection.** `ses_efa2dc1f8ffeZs5PWLKlM4SI3n` | `tmp/fault-opencode/01-copy.task.md`, `.report.md`, `.events.jsonl`, `.baseline.txt`, `.usage.json` |

Inventory produced a cited source/asset report; Codex checked consequential claims in source, later checkpoint, device record and actual asset listings. Repairs: safe false defaults versus beta pins are not a conflict; Fault overrides the legacy naming decision; solo is push-ups only; old captures are not current proof; actual L07 screenshot filenames differ from the index. Worker report stays intact as evidence.

Copy received only settled facts and source sections after Codex verification. It produced three hero/subline pairs, CTA/helper and four FAQs. Codex removed the first variant's erroneous “Sign in”; discarded “clear score”/“stop guessing” framing; retained the concise set/record motivation, rewrote public-facing development language and expanded FAQ. No model assertions establish physical readiness. Neither worker changed product files; baseline/final tracked diff remains the pre-existing social-brief edit, with new stage outputs confined to this brief and temporary evidence.

Reported event usage, summed by step (token fields retained as reported; do not sum cumulative `total` fields): inventory **90,852 input, 1,924 output, 2,753 reasoning, 378,880 cache-read tokens**, reported cost field **0.01757064**; copy **1,308 input, 412 output, 282 reasoning, 24,832 cache-read tokens**, reported cost field **0.000687096**. The event cost field does not establish billed subscription spend or savings; currency was not supplied in these events. No percentage saved is claimed. Raw logs remain local and should stay out of source control.
