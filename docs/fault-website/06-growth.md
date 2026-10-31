# Fault — Stage 6 growth iteration 01

**4 October 2026 · iteration `2026-10-04-01` · drafts and protected preview only.** The next useful step is to make acquisition measurable, then film one real manual-set demonstration. There is no measured creative winner or conversion-loss ranking. Public collection remains held under Stage 5; this iteration does not publish posts, send campaigns, schedule work, promise app access or forecast a date for 30,000 subscribers. Earlier handoffs and evidence are preserved. Append a new dated iteration rather than replace these results.

## Results and what they establish

Supabase read-only aggregate snapshot at **17:02:02.802495 UTC / 22:02 Yekaterinburg**, selected fit_ap project, production `fault_waitlist` namespace:

| Measure | Actual result | Boundary |
| --- | --- | --- |
| Unique confirmed, currently subscribed, eligible addresses | **0** | Authoritative production count; preview excluded |
| Net eligible change | **0** | From Stage 5's 16:24:11 UTC snapshot (0) to 17:02:02 UTC (0), about 38 minutes; not a daily growth estimate |
| Pending / ever confirmed / currently unsubscribed | **0 / 0 / 0** | No production subscriber rows |
| Known active suppressions / suppressed subscribers | **0 / 0** | No provider webhook receipts; no mail jobs; not proof of universal deliverability |
| Confirmation / unsubscribe / suppression rates | **Undefined** | Zero cohort denominators, not 0% |
| Collected landing → submission → confirmation funnel | **No data recorded** | PostHog development/preview insight, not all website traffic or a production conversion rate |
| Video views and visit-per-view / confirmed-per-1,000-views | **Unavailable** | No connected video analytics tool or owner-supplied view export |
| Resend messages / domains / webhooks | **0 / 0 / 0** | Read-only account diagnostics; delivery/engagement rates undefined |

Source: [sanitized aggregate export](growth/2026-10-04-01/aggregates.json), obtained by Codex through Supabase SELECT-only counts, PostHog taxonomy/query and Resend diagnostics. No addresses, verification tokens or raw subscriber rows were exported. Production and preview data were not merged.

The [saved PostHog funnel](https://eu.posthog.com/project/272861/insights/BtxaDFUN) is ordered `landing_view → waitlist_submit → waitlist_confirmed`, with a 30-day conversion window; its UTC reporting range resolved to **4 September–4 October 2026**. It filters `site=fault`, environment development/preview and does not exclude tests. Its cached refresh timestamp is 12:11 UTC, so the empty query is historical development evidence. Fresh 17:02:41 UTC taxonomy inspection found no observed Fault events in the preceding 30 days. Neither source measures all actual visits. Production source/device breakdowns have no sample and are withheld. The current database snapshot, not that development funnel, establishes the launch count.

These windows have different jobs: the two database snapshots establish a short net change; the preceding 30 days establish available analytics coverage. They are not divided into a cross-window conversion rate. A future acquisition cohort uses one explicitly recorded UTC intake window and mature follow-up windows throughout.

**Largest evidenced obstacle:** anonymous acquisition cannot yet reach a collecting public website. The protected preview redirects anonymous visitors to Vercel authentication and the hosted signup API fails closed with configuration-required 503. This is an operational gate, not a measured percentage of visitor drop-off. Without traffic and confirmation cohorts, no downstream stage can truthfully be declared the largest conversion loss.

## Metric and attribution contract

**Launch metric:** at snapshot S, count one canonical address row where `status=subscribed`, `confirmed_at` exists, and `suppressed`, `abuse`, `internal_test` are false. Database uniqueness deduplicates canonical addresses; do not strip dots or plus tags. Pending, unsubscribed, abuse, internal tests and known active delivery suppressions contribute zero. The private production schema is authoritative. Analytics lifetime confirmations are not the current eligible total.

Use an intake cohort C of first-time valid subscriber creations during `[T0,T1)` UTC, excluding internal tests and detected abuse. A valid submission means a successful unique row creation, not a button click or repeated HTTP request. Known-suppressed addresses rejected before admission create no new row. Report the cohort size and exclusions explicitly.

- **Confirmation rate:** first confirmations within 24 hours of creation / C. Rejoins and duplicate requests do not count as first creations/confirmations. Wait at least **48 hours after a cohort closes** for the 24-hour response window and ingestion lag; report late confirmations separately. The token expires after 24 hours. Do not remove later bounces from the denominator to inflate the rate.
- **Retained eligible yield:** members of C still meeting the authoritative eligibility definition at a scheduled seven-day follow-up / C. Preserve dated aggregate snapshots; current state cannot reconstruct a past seven-day snapshot after the fact.
- **Net growth:** eligible(S1) − eligible(S0), with both timestamps and the same production filters. It includes gains, unsubscribes, suppression and authorized rejoin changes. Zero eligible growth today is not zero demand.
- **Unsubscribe attrition:** currently unsubscribed first-confirmed cohort members at the seven-day snapshot / first-confirmed cohort members. Separately report currently suppressed cohort members / first-confirmed cohort members; exclusions can overlap. This is snapshot attrition, not an all-time unsubscribe-event rate. The schema clears `unsubscribed_at` on re-confirmation and does not retain a comprehensive unsubscribe transition ledger. Therefore cumulative unsubscribe-event rates and suppression history are unavailable without additional approved instrumentation; no such database change was made here.
- **Delivery:** verified provider accepted/delivered/bounced/complained counts with matching message IDs, window and known suppression reconciliation. Opens can be inflated by privacy proxies/scanners; prioritize genuine replies, completed interest actions, confirmations and retained eligibility. Clicks are diagnostic and can also be scanned.
- **Website conversion:** only the consented anonymous analytics cohort can support `landing_view → waitlist_submit → first waitlist_confirmed`. Report opt-in coverage; do not present it as all visitors. The memory-only visit ID can fragment repeat/reload visits. Confirmation uses the ID and attribution stored at creation, so another device can confirm without sending the address/token to analytics.
- **Video efficiency:** current eligible confirmed addresses attributed to a creative / its reported platform views × 1,000. Keep gross first confirmations and retained eligible yield separate. Platform views are not unique people and should not be summed as unique reach. Match the content mapping, publication/time zone, platform view definition, UTC intake cutoff and confirmation lag. Direct/unknown traffic remains an explicit unattributed group.

Implementation sources: `fault-web/src/lib/contracts.ts`, `src/lib/server/service.ts`, `src/lib/server/repository.ts`; `supabase/migrations/20261004112705_fault_waitlist_stage3.sql:5–15,93–126` and preview-isolation migration. Duplicate creations and first/rejoin confirmation semantics are tested in `fault-web/tests/flow.test.ts`. No SQL mutation or migration was performed in Stage 6.

**New prospective registry:** `growth-iteration-01`, content `fault-growth-r` / `fault-growth-p`, creatives `fault-growth-d01-r` … `fault-growth-d14-p`, alternating r/p. Registered sources instagram/tiktok/youtube, medium organic-social, `utm_content=creative_id`. The exact pairs are allowlisted in `fault-web/src/lib/contracts.ts`; unknown/mismatched labels fail to direct credit. Retain first and last eligible touch; primary credit is the last registered touch within 30 days of submission. One address gets one primary creative at a snapshot. Rejoin can change the stored touch; keep cohort snapshots rather than infer immutable lifetime acquisition from a mutable row.

Draft link example (not published): `https://fault.fit/?content_id=fault-growth-r&creative_id=fault-growth-d01-r&utm_source=instagram&utm_medium=organic-social&utm_campaign=growth-iteration-01&utm_content=fault-growth-d01-r`. fault.fit is deferred by the owner and not currently an acquisition destination. Before publication either connect it to the verified live waitlist or replace spoken, visible and written URLs with the verified free Vercel public hostname. Do not send viewers to this protected review preview. For bio-only platforms, use the separately registered bio link and classify it as bio/unattributed-to-video unless an actual clickable creative-specific link is available; do not assign every bio visit to the latest clip. Need an owner export containing creative/platform post mapping, reporting timestamps/time zone, views and platform click definition to complete video analysis.

## One experiment: confirmation-first copy pilot

**Hypothesis:** explicitly describing the inbox step before submission improves completion of email confirmation. This is chosen for the required double opt-in journey, not from observed drop-off. Hold the headline, product scope, posters, placement, consent wording and server behavior constant.

| | Control at `/` | Treatment at `/growth-preview` |
| --- | --- | --- |
| Button | Join the waitlist | **Send confirmation email** |
| Helper | Confirm your email for Fault launch updates. Joining the list does not give you app access. | **1. Request an email. 2. Open it and confirm. You join after confirmation. This does not give app access.** |
| After request | Existing loading, pending/resend and failure feedback | Same states and API |

[Protected treatment preview](https://fault-website-k0yue7h1i-priler003-7576s-projects.vercel.app/growth-preview), [control](https://fault-website-k0yue7h1i-priler003-7576s-projects.vercel.app/). Ready deployment **dpl_2uCNpSfgG4cnPdfAA2QMgw6YrdyZ**, target preview, project fault-website. Authenticated request returned 200 with treatment and noindex; anonymous request returned 302 to Vercel authentication. Signup remains 503 configuration-required. This is reviewable implementation, **not a live growth test**.

The treatment route is server-rendered and checks trusted environment at request time: only development/preview, never production. A local production-environment request verifies 404. The original route retains its CTA. No PostHog experiment/flag or production rollout was created. Do not infer treatment exposure merely from a campaign ID: the same video could reach different pages.

**Proposed pilot design:** after release gates and separate activation approval, serve treatment to the complete new-cohort landing route in one identified production deployment, keeping video IDs and placement stable. Record T0, deployment identity and exact UTC intake window. It is a **single-arm baseline pilot**, not randomized A/B; absent a control cohort there can be no causal lift or winner claim. The preview route itself will not be opened as a production route. The follow-up activation change would select `confirmationFirst` on the normal landing component and configure production-only reporting; that action is not performed here.

**Primary metric:** the mature 24-hour first-confirmation rate defined above. Secondary: unique valid creations per consented landing visit; seven-day retained eligible yield and net eligible growth. Use the existing database transitions and privacy-safe lifecycle events, not raw addresses or tokens. The current saved funnel is development-only/30 days; a production pilot requires a separately filtered 24-hour cohort readout with `first_confirmation=true`, tests excluded, production environment only. It was not configured as a live experiment today.

**Evaluation window:** 14 full days after verified T0; freeze the intake cutoff, allow 48 hours for confirmation reporting and seven days for retention. An initial operational review at 100 mature creations can locate friction but does not automatically end the pilot or establish significance. At fewer than 100, report counts and uncertainty and decide whether to collect another fixed window; do not declare a winner. Report numerator/denominator and confidence intervals when a real sample exists. No unmeasured 80% confirmation assumption is used as a achieved benchmark.

**Guardrails:** close enrollment on delivery/API faults, invalid consent, privacy leakage, failed unsubscribe/suppression synchronization or authoritative count disagreement. Review unexpected bounces/complaints immediately in the small cohort rather than hiding them in a percentage. Watch pending resend attempts, failed/expired mail jobs, unknown attribution share, mobile reflow, p75 field LCP/INP/CLS and seven-day eligibility. Keep optional analytics optional. No fake urgency, subscriber-counter experiment or access promise.

**Rollback:** leave the normal page on control, or after authorized activation set `confirmationFirst=false` on the normal landing instance and deploy the previously verified production copy version. Preserve subscriber consent, token validity, suppressions and attribution. Do not reset the database, remove records or promote a preview deployment into production. Existing Stage 5 source recovery remains available; this pilot changes copy/presentation and adds only allowlisted creative IDs. The verified current protected preview can be replaced with Stage 5's corrected protected version for review recovery. No production rollback target exists because no production publication occurred.

## Verification and evidence

| Check | Result and evidence |
| --- | --- |
| Typecheck and actual Next production build | Pass; `fault-web/test-results/stage6/build.txt`; final guard build confirms normal page pre-rendered and review route dynamic. Hosted final build Ready. No dependencies added. |
| Regression suite | **37/37 pass**; `test-results/stage6/regressions.txt`. Fresh PostgreSQL simulation covers duplicate/token/retry/rate/webhook/count behavior; new `tests/growth.test.ts` verifies all 14 creatives across three sources and rejects mismatch/PII labels. |
| Local browser → API → data → response | Pass with simulated delivery/analytics only; `test-results/stage6/browser.json`, `http-flow.json`, `scripts/growth-review.mjs`. Invalid input blocks submission; permitted synthetic signup reaches pending/resend; duplicate has one message, confirmation occurs once, replay is used, unsubscribe is idempotent. New creative retained across confirmation; no raw email/token in simulated analytics. No real email sent. |
| Layout/accessibility | 320/390/768/1440 Chromium viewport review, no horizontal overflow; native Tab/Enter skip focus; reduced-motion preference with zero running animations; 200% computed-text enlargement with no clipped text. Emulation, not physical touch/native zoom/Safari/social-platform browsers. |
| Runtime release boundary | `production-guard.json`: review route 404 in production environment with delivery disabled. `hosted.json`: authenticated treatment 200/noindex; anonymous 302; hosted signup configuration-required 503. |
| Email drafts | Three React Email HTML/plain-text previews rendered and size/structure checked, single h1, lang=en, unsubscribe links, no SVG/WebP/flex/grid or external images. All below 102 KB. Chromium 390px previews fit; real Gmail/Outlook/Apple Mail delivery/client rendering not performed. `test-results/stage6/email-render.json`. |
| Performance | No new field or current-iteration Lighthouse claim. Stage 5's latest lab mobile LCP **3.176 s** exceeded the 2.5 s target; desktop 0.670 s, CLS 0. This remains historical lab evidence, not field p75/INP. Existing consented RUM pipeline has no representative live cohort. |

Screenshots: [390px](../../design/fault-website/stage6-mobile.png), [320px](../../design/fault-website/stage6-320.png), [tablet](../../design/fault-website/stage6-tablet.png), [desktop](../../design/fault-website/stage6-desktop.png), [reduced motion](../../design/fault-website/stage6-reduced-motion.png), [enlarged text](../../design/fault-website/stage6-text-200.png), [welcome draft mobile](../../design/fault-website/stage6-welcome-mobile.png). These are real browser captures of the local review page, not physical app/device proof. `test-results/stage6/change-manifest.json` hashes the changed/new reviewed sources; Stage 5 recovery sources are not overwritten.

## Creative selection and production brief

Start with **R — real set → manual entry → saved record**, specifically d05-r's explanation of self-reported counting. It needs one genuine take and its matching screen capture. Then **P — two actual sets → same-phone retained history**, with higher/equal/lower results all valid. A P clip needs both dated sets and the actual history; the seven-day view is seven local calendar days, not a cloud or lifetime graph. There is no friend-challenge format until counted battle scope and physical/hosted evidence pass.

Scope checks: `app/lib/solo/runtime/solo_controller.dart:303–335,361–393` (manual count/save); `app/lib/solo/ui/solo_page.dart:245–263,275–316,393–409,489` (real manual input, self-reported/save/history UI); `app/lib/solo/domain/solo_result.dart:143–175` (best within retained matching exercise/source and seven local days). Camera record `qa/camera/beta_device_results.json:2–8` remains blocked; `docs/release/PILOT_PLAN.md:17–31` gates camera/battles. The verified brief is authoritative. No new approved media was supplied; Stage 4's illustrative posters remain review assets. No posters, emulator battle fixtures or generated athlete imagery are passed off as product footage.

**Master R storyboard, 24 seconds at 30 fps:** 0–4s/f0–119 hook plus development disclosure; 4–11s/f120–329 actual push-up effort, count supplied by athlete; 11–17s/f330–509 real manual entry → actual self-reported result → successful device save; 17–24s/f510–719 readable draft website CTA. Use cuts, one restrained transition between the same take and app capture, no animated rep/timer digits. If the save fails, do not cut directly to an unrelated successful result. Keep source take identifier in the edit manifest.

**Master P storyboard, 26 seconds:** 0–5s/f0–149 hook/disclosure; 5–13s/f150–389 actual first set and dated record; 13–19s/f390–569 actual next record/recent history or explicitly editorial juxtaposition, with real relation and self-reported labels; 19–26s/f570–779 draft CTA. Dates/counts must be readable in the actual captures. No invented comparison widget, PB delta, growth line or staged exact equality. If the two records cannot fit together in actual UI, use labelled editorial captures rather than rebuild the app in post.

**Production requirements:** vertical 1080×1920; captions centered away from platform chrome, reviewed on a 390px screen; square/desktop crop from a separate framing where needed; 3–5 shot beats; complete captions and transcript; clear rights/performer permission, build/commit, phone model/OS and take IDs. Preserve any legacy Training Arena label until real renamed captures exist. App/public access remain in development. No reused testimonial or numbers. Actual final durations including spoken CTA must be 15–30 seconds; placeholder date/count expansions must be read aloud and shortened before export. A reduced-motion edit uses hard cuts, static captions and zero animated figures; a phone edit uses one capture at a time. Captions plus silent playback must communicate manual counting/save/development without audio. No reusable video composition was built, so Remotion was not needed.

The complete **14-day production/review calendar and actual timed scripts, shot lists, captions and IDs** are included in the production appendix below and retained separately in [content-drafts.md](growth/2026-10-04-01/content-drafts.md). Proposed 5–18 October dates are targets for owner review/production, not a publishing schedule. Shift the entire window when asset/release gates delay it; keep IDs stable. Only d05-r followed by a genuine d02-p pilot is recommended for the first shoot, rather than producing all fourteen before feedback.

## Selected email drafts

All three are **review drafts** for confirmed, currently subscribed eligible members with matching update consent. Recheck authoritative eligibility and known suppressions at send-time; do not email pending rows or assume confirmation grants app access. No campaign, audience import, welcome automation or send is configured. Sender/reply-to, public operator/address, individual unsubscribe URL and public site URL remain unresolved. Every future marketing message needs the real footer/unsubscribe and verified sending domain; prepare applicable unsubscribe headers/provider handling at activation. HTML review exports deliberately use reserved `.invalid` links and visible draft placeholders, never pretend these are live URLs.

**Welcome — only newly confirmed, eligible members.** Subject: **You’re confirmed. Welcome to Fault.** Preheader: *Give your next set a reason. Android first, still in development.*

> Thanks for confirming your email. We’ll send the Fault development and launch updates you asked for.
>
> Fault is being built around a simple loop: do a push-up set, enter your own count, save it on your phone, and review your recent sets. Results are self-reported. Android first.
>
> Joining this list does not give app access. There is no confirmed public launch date.

CTA: **Review the development scope** → `[VERIFIED_SITE_URL]`. Footer: update-consent explanation, `[UNSUBSCRIBE_URL]`, `[OPERATOR_ADDRESS]`, `[REPLY_TO_ADDRESS]`. [HTML](../../design/fault-website/growth-2026-10-04-01/welcome.html), [plain text](../../design/fault-website/growth-2026-10-04-01/welcome.txt).

**Useful development update — eligible members who requested development updates.** Subject: **The set-to-record loop we’re building**. Preheader: *Manual entry, local history, and what still needs checking.*

> The current implementation lets you enter a push-up count yourself, label it self-reported, and save it on your phone. The history view covers the last seven days; a personal best means best within retained history.
>
> Source and automated checks support that loop. The physical-phone walkthrough and release checks still need to be completed. Camera counting remains under test and is not offered in the current scope.
>
> What would make a saved set useful to you next time? Reply with one thing you would want to compare.

CTA: **Review the development scope**; meaningful action is a genuine reply to the future verified reply-to. Same required footer. [HTML](../../design/fault-website/growth-2026-10-04-01/development.html), [plain text](../../design/fault-website/growth-2026-10-04-01/development.txt).

**Launch-interest — eligible update subscribers; no access invitation.** Subject: **Would you try Fault on Android?** Preheader: *A question about interest, with no access or launch date promised.*

> We’re preparing Fault for Android first: solo push-ups, your own rep count, and a record saved on your phone.
>
> If you would want to try that when access is ready, reply INTERESTED and tell us your phone platform. This is a question about interest, not an invitation or reservation of access.
>
> There is no confirmed public launch date. You can unsubscribe whenever you want.

Action: **Reply INTERESTED** to `[REPLY_TO_ADDRESS]`; website button only reviews development scope and cannot record interest. Do not invent a survey/click-confirmation endpoint. Same required footer. [HTML](../../design/fault-website/growth-2026-10-04-01/interest.html), [plain text](../../design/fault-website/growth-2026-10-04-01/interest.txt). Additional worker subjects/bodies remain [variants for review](growth/2026-10-04-01/email-variants.md); Codex selected/revised the three above. Template: `fault-web/emails/GrowthDraft.tsx`; renderer `scripts/render-growth-drafts.tsx`. No send API is called.

## Milestones and next decision

| Current eligible milestone | Focus of the next decision |
| --- | --- |
| **100** | Confirm real inbox delivery, signup/unsubscribe reconciliation and mobile friction. Review tester feedback before increasing content production. |
| **1,000** | Compare mature R/P and source cohorts with actual views, confirmed yield and retained eligibility; repeat a format only when sample/quality support it. |
| **5,000** | Test whether a second source/audience repeats the result; audit suppressions, consent and useful development-email replies. Avoid scaling a hook with high submissions but weak confirmation. |
| **10,000** | Verify queue/retry/provider capacity and campaign delivery before larger acquisition volume; address representative field p75 and unavailable physical/in-app-browser checks. No paid plan is implicitly authorized. |
| **30,000** | Reconcile the current authoritative eligible count, suppressions, consent and app release readiness. This marketing milestone alone does not release the app. |

**Recommended next action:** resolve the existing server-credential/sender/operator release gates and film one genuine manual-set take plus matching entry/save capture. The website experiment is ready for review; its outcome is unmeasured. Do not spend production effort on friend-battle films or volume forecasts yet. The owner already approved the designated development test recipient; no new test-recipient request is needed. Domain fault.fit remains deferred; a verified free Vercel public URL can satisfy the marketing release when other gates pass, with CTA replacement before posts are approved.

Exact remaining inputs are the Stage 5 secret-store `SUPABASE_SERVICE_ROLE_KEY`, verified sender plus `RESEND_API_KEY`/`RESEND_FROM`/signed webhook, public operator/support/retention fields and preserved-route backend/certificate details as applicable. Real media and a platform view export are separate acquisition evidence gaps. Supply secrets through the existing secret store, not a worker packet or chat. No new service writes beyond protected Vercel preview deployment occurred. No paid purchase, sender setup, production publication, campaign sending or recurring schedule was performed.

## OpenCode delegation

**06-growth-batch — accepted with one bounded correction and Codex final edits.** Actual provider/model **OpenCode Go / `opencode-go/deepseek-v4.1-flash`**, text-task route, build agent; session **ses_ef81f8fdeffeNxGwd8j5giFYC1**. Original packet and baseline: `tmp/fault-opencode/06-growth-batch.task.md`, `.baseline.json`; raw logs `.events.jsonl`; one correction `.correction.md` / `.correction.events.jsonl`; compact `.report.md`; usage/observed tool-path evidence `.usage.json`. The task batched sanitized aggregate synthesis, fourteen video hook/script/caption/calendar entries and six email variants after Codex supplied the verified creative brief. Exact write ownership was `growth/2026-10-04-01/{patterns,content-drafts,email-variants}.md` and the report only. Observed writes match that allowlist; no production secrets, subscriber rows or private recipient identity were provided.

Codex independently checked the aggregate results, chose the pilot, reviewed all content, corrected invented result relations/UI, moved CTAs inside advertised durations, removed unsupported offline/form/clear-history implications and corrected camera evidence classes and interest actions. After the one worker correction, Codex further made the PB example consistent, removed the implied clear-history control, required disclosure on every final caption and shortened/selected the final emails. These are approved **draft structures**, not final approved footage/results or send authorization.

Worker log inspection found one initial unprefixed read-only directory existence/listing command despite the packet's RTK instruction. The bounded correction restated the shell requirement; subsequent shell commands used RTK. The shell-policy deviation is recorded, not concealed; no service/private-data operation resulted. Worker report/status claims alone were not used as proof.

Reported usage across initial/correction runs: input **39,134**, output **17,396**, reasoning **7,241**, cache-read **1,299,584**, cache-write **0** tokens; reported cost sum **$0.024551052**. Provider reporting is not a verified bill, savings percentage or spending authorization. Raw streams stay locally ignored. Codex retained all interpretation, final copy selection, schema/security boundaries, preview deployment and verification. All required Stage 6 delegation outputs are present; live acquisition and sending remain separately gated.

## Production appendix — complete fourteen-day scripts


<!-- complete-production-calendar-2026-10-04-01 -->

Registered IDs. Campaign: `growth-iteration-01`. Content IDs: `fault-growth-r` (R), `fault-growth-p` (P). Creative IDs: `fault-growth-d01-r` … `d14`, r on odd days, p on even days; `utm_content` equals the creative ID. Source: instagram / tiktok / youtube. Medium: organic-social. Planned dates 5–18 October are production/review targets, not scheduled publishing. All drafts held until footage, permission and a verified anonymous waitlist are ready.

Global rules: vertical 1080×1920, captions inside center-safe area, deliberate desktop alternative crop, no essential bottom-edge CTA; real footage and the matching screen capture must be the same take/build with a visible self-reported label and production rights/build/device metadata. Static legible rep numerals, captioned audio, no animated timer digits. R placeholders: `[ACTUAL_REPS]`, `[ACTUAL_SET_DATE]`. P placeholders: `[FIRST_REPS]`, `[NEXT_REPS]`, `[FIRST_DATE]`, `[NEXT_DATE]`, `[ACTUAL_RELATION]`. Screen capture shows the recent saved sets / history view only; no fabricated overlays or computed results. `[TAKE]`. Every duration below includes the full spoken CTA. Spoken CTA (all): "Fault is in development. Join and confirm at fault.fit. Android first." Written CTA: "fault.fit — join and confirm. Android first." Mandatory on-screen disclosure on every clip: **Development build · Self-reported · Android first**. Mandatory prefix on every final post caption: **Fault is in development. Android first.** All fault.fit links are drafts until the owner connects a verified anonymous live waitlist. Any spoken result, mood, signed-out/save observation or dates must be supported by the actual take; placeholders are not supplied truth. No final assets are approved yet. Read the lines aloud with the actual dates/numbers and shorten them if needed; the final export, including CTA, must remain 15–30 seconds.

---

### Oct 5 — d01-r
- **Format:** R (real set → manually entered result)
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-r / fault-growth-d01-r
- **Duration:** 24 s
- **Hook:** "Last time I logged [ACTUAL_REPS]."
- **Timed script:** 0–4 s "Last time I logged [ACTUAL_REPS]." 4–10 s "Today I do one set and count it myself." 10–17 s "Then I type the number in by hand — self-reported." 17–24 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — athlete mid-set, phone on floor visible in frame. [TAKE] B — phone screen: manual rep entry field typed, self-reported label visible. [TAKE] C — same-build recent saved sets / last-seven-days history view.
- **Captions:** "[ACTUAL_SET_DATE]: [ACTUAL_REPS] reps" / "Typed in by me. Self-reported." / "Recent sets on this phone."
- **Post caption:** "I count the set, I type the number in, and Fault keeps my recent sets on my phone. Being built — Android first. fault.fit"
- **Notes:** Reps/date are placeholders, not results.

### Oct 6 — d02-p
- **Format:** P (two actual sets → same-phone history)
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-p / fault-growth-d02-p
- **Duration:** 26 s
- **Hook:** "Two saved sets on this phone. Higher, equal or lower — I'll check."
- **Timed script:** 0–5 s "Two saved sets on this phone. Higher, equal or lower — I'll check." 5–13 s "First set: [FIRST_REPS] on [FIRST_DATE]." 13–19 s "Next: [NEXT_REPS] on [NEXT_DATE]. The saved-sets view holds both — [ACTUAL_RELATION]." 19–26 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — first set capture. [TAKE] B — next set capture, same set-up. [TAKE] C — same-build recent saved sets view with both entries visible and the self-reported label, or a clearly editorial two-capture juxtaposition with the label.
- **Captions:** "[FIRST_DATE]: [FIRST_REPS]" / "[NEXT_DATE]: [NEXT_REPS]" / "[ACTUAL_RELATION]".
- **Post caption:** "Two sets I actually saved, both still on the phone. I'll show the real relation — higher, equal or lower. Building in the open. fault.fit"
- **Notes:** Relation spoken only from `[ACTUAL_RELATION]`; hook is conditional on the footage.

### Oct 7 — d03-r
- **Format:** R
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-r / fault-growth-d03-r
- **Duration:** 22 s
- **Hook:** "I didn't feel like training today."
- **Timed script:** 0–4 s "I didn't feel like training today." 4–11 s "I did one set anyway and counted it myself." 11–15 s "Logged [ACTUAL_REPS] on [ACTUAL_SET_DATE]." 15–22 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — slow start, phone visible. [TAKE] B — manual entry typed. [TAKE] C — saved set appears in recent sets.
- **Captions:** "Low-motivation set" / "[ACTUAL_SET_DATE]: [ACTUAL_REPS]" / "Saved locally."
- **Post caption:** "A logged set beats a skipped one. Manual entry, saved on my phone. In development. fault.fit"
- **Notes:** No guarantee-of-improvement claim.

### Oct 8 — d04-p
- **Format:** P
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-p / fault-growth-d04-p
- **Duration:** 26 s
- **Hook:** "Two sets from my retained history. I'll show whatever the numbers are."
- **Timed script:** 0–5 s "Two sets from my retained history. I'll show whatever the numbers are." 5–13 s "First: [FIRST_REPS] on [FIRST_DATE]." 13–19 s "Next: [NEXT_REPS] on [NEXT_DATE] — [ACTUAL_RELATION]." 19–26 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — first set. [TAKE] B — next set, same framing. [TAKE] C — recent saved sets view with both entries and the self-reported label, or editorial two-capture juxtaposition.
- **Captions:** "[FIRST_DATE]: [FIRST_REPS]" / "[NEXT_DATE]: [NEXT_REPS]" / "[ACTUAL_RELATION]".
- **Post caption:** "The sets I actually saved, shown as they are. Higher, equal or lower, it's still my record. Still being built. fault.fit"
- **Notes:** No asserted direction; relation only from `[ACTUAL_RELATION]`.

### Oct 9 — d05-r
- **Format:** R
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-r / fault-growth-d05-r
- **Duration:** 24 s
- **Hook:** "Here's what 'self-reported' means in Fault."
- **Timed script:** 0–4 s "Here's what 'self-reported' means in Fault." 4–11 s "I count every rep. No camera is counting for me." 11–17 s "Then I type [ACTUAL_REPS] in after the set on [ACTUAL_SET_DATE]." 17–24 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — set performed, no counting overlay. [TAKE] B — manual entry, self-reported label legible. [TAKE] C — saved result.
- **Captions:** "You count." / "You type it." / "Labelled self-reported."
- **Post caption:** "I do the counting and enter it myself. Fault labels it self-reported. Development build. fault.fit"
- **Notes:** Avoids any camera-counting benefit claim.

### Oct 10 — d06-p
- **Format:** P
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-p / fault-growth-d06-p
- **Duration:** 26 s
- **Hook:** "Two saved sets, one phone. No cloud involved."
- **Timed script:** 0–5 s "Two saved sets, one phone. No cloud involved." 5–13 s "Set one: [FIRST_REPS], [FIRST_DATE]." 13–19 s "Set two: [NEXT_REPS], [NEXT_DATE]. Both stay on this phone — [ACTUAL_RELATION]." 19–26 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — first set. [TAKE] B — second set. [TAKE] C — recent saved sets view on device, self-reported label.
- **Captions:** "Saved set: [FIRST_REPS]" / "Saved set: [NEXT_REPS]" / "Phone-local. Signed out."
- **Post caption:** "My saved sets stay on my phone, and solo is signed out. No sync involved. Being built. fault.fit"
- **Notes:** No cloud-sync claim; no offline proof implied.

### Oct 11 — d07-r
- **Format:** R
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-r / fault-growth-d07-r
- **Duration:** 22 s
- **Hook:** "Last seven days, one view, no spreadsheet."
- **Timed script:** 0–4 s "Last seven days, one view, no spreadsheet." 4–11 s "I add one set and log it. [ACTUAL_REPS] on [ACTUAL_SET_DATE]." 11–15 s "The last-seven-days view shows my recent sets." 15–22 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — set. [TAKE] B — manual entry. [TAKE] C — last-seven-days view.
- **Captions:** "[ACTUAL_SET_DATE]: [ACTUAL_REPS]" / "Last 7 days" / "One screen."
- **Post caption:** "My last seven days on one screen, from sets I logged myself. No spreadsheet. fault.fit"
- **Notes:** Retained-history scope only.

### Oct 12 — d08-p
- **Format:** P
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-p / fault-growth-d08-p
- **Duration:** 26 s
- **Hook:** "A personal best only counts inside the history I kept."
- **Timed script:** 0–5 s "My personal best here means best in retained history." 5–14 s "Two saved sets: [FIRST_REPS] on [FIRST_DATE], [NEXT_REPS] on [NEXT_DATE]." 14–19 s "The app's displayed best is [ACTUAL_BEST_REPS]. Not a lifetime record." 19–26 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — strong set. [TAKE] B — recent saved sets / history view showing best-within-history. [TAKE] C — retained sets listed by date, self-reported label.
- **Captions:** "Best in retained history" / "Not a lifetime PB" / "[FIRST_DATE], [NEXT_DATE]".
- **Post caption:** "Fault only claims what it can hold: a personal best within my retained history. No lifetime numbers. Building honestly. fault.fit"
- **Notes:** Avoids lifetime-PB claim.

### Oct 13 — d09-r
- **Format:** R
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-r / fault-growth-d09-r
- **Duration:** 22 s
- **Hook:** "Solo is signed out. That's on purpose."
- **Timed script:** 0–4 s "Solo is signed out. That's on purpose." 4–11 s "I did [ACTUAL_REPS] on [ACTUAL_SET_DATE]." 11–15 s "It saves to this phone and nowhere else." 15–22 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — signed-out state visible. [TAKE] B — set. [TAKE] C — manual entry saved.
- **Captions:** "Signed out" / "[ACTUAL_SET_DATE]: [ACTUAL_REPS]" / "Stays local."
- **Post caption:** "Solo mode is signed out and local. My set, my phone. In development, Android first. fault.fit"
- **Notes:** No account/app-access promise.

### Oct 14 — d10-p
- **Format:** P
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-p / fault-growth-d10-p
- **Duration:** 26 s
- **Hook:** "Two sets don't have to climb to be worth keeping."
- **Timed script:** 0–5 s "Two sets don't have to climb to be worth keeping." 5–13 s "First: [FIRST_REPS] on [FIRST_DATE]." 13–19 s "Next: [NEXT_REPS] on [NEXT_DATE] — [ACTUAL_RELATION]." 19–26 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — first set. [TAKE] B — next set. [TAKE] C — recent saved sets view with both entries, self-reported label, or editorial two-capture juxtaposition.
- **Captions:** "[FIRST_DATE]: [FIRST_REPS]" / "[NEXT_DATE]: [NEXT_REPS]" / "[ACTUAL_RELATION]".
- **Post caption:** "Higher, equal or lower, both sets are worth saving. Fault keeps the sets I actually logged. fault.fit"
- **Notes:** Equal or lower explicitly permitted; no asserted result.

### Oct 15 — d11-r
- **Format:** R
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-r / fault-growth-d11-r
- **Duration:** 22 s
- **Hook:** "The set I actually finished is the one I log."
- **Timed script:** 0–4 s "The set I actually finished is the one I log." 4–11 s "One set, counted by me — [ACTUAL_REPS]." 11–15 s "Typed in by hand on [ACTUAL_SET_DATE]." 15–22 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — finished set. [TAKE] B — manual entry. [TAKE] C — saved result.
- **Captions:** "Counted by me" / "[ACTUAL_SET_DATE]: [ACTUAL_REPS]" / "Self-reported save."
- **Post caption:** "One finished set, counted and entered by hand. Manual, self-reported, saved locally. fault.fit"
- **Notes:** No form-certification claim.

### Oct 16 — d12-p
- **Format:** P
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-p / fault-growth-d12-p
- **Duration:** 26 s
- **Hook:** "Two saved sets, in the order I did them."
- **Timed script:** 0–5 s "Two saved sets, in the order I did them." 5–13 s "First: [FIRST_REPS], [FIRST_DATE]." 13–19 s "Next: [NEXT_REPS], [NEXT_DATE] — [ACTUAL_RELATION]." 19–26 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — earlier set ([FIRST_DATE]). [TAKE] B — later set ([NEXT_DATE]). [TAKE] C — recent saved sets view listing both by date, self-reported label.
- **Captions:** "[FIRST_DATE]: [FIRST_REPS]" / "[NEXT_DATE]: [NEXT_REPS]" / "[ACTUAL_RELATION]".
- **Post caption:** "Two sets in the order I actually did them, both kept on the phone. Building in the open. fault.fit"
- **Notes:** Shot order matches date order; no assumed drop.

### Oct 17 — d13-r
- **Format:** R
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-r / fault-growth-d13-r
- **Duration:** 22 s
- **Hook:** "I do the counting. The app holds the number."
- **Timed script:** 0–4 s "I do the counting. The app holds the number." 4–11 s "Every rep counted by me, then typed in." 11–15 s "[ACTUAL_REPS] on [ACTUAL_SET_DATE] — self-reported." 15–22 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — athlete counting. [TAKE] B — manual entry, self-reported label. [TAKE] C — saved result.
- **Captions:** "You count" / "You enter" / "Self-reported."
- **Post caption:** "I do the counting, Fault keeps what I enter. Labelled self-reported, on my phone. Being built. fault.fit"
- **Notes:** Avoids camera-counting claim.

### Oct 18 — d14-p
- **Format:** P
- **Campaign / Content / Creative:** growth-iteration-01 / fault-growth-p / fault-growth-d14-p
- **Duration:** 26 s
- **Hook:** "Two sets, retained history only. Here's what that means."
- **Timed script:** 0–5 s "Two sets, still saved on this phone." 5–14 s "First: [FIRST_REPS] on [FIRST_DATE]. Next: [NEXT_REPS] on [NEXT_DATE]." 14–19 s "Both self-reported. The result is [ACTUAL_RELATION]." 19–26 s CTA: "Fault is in development. Join and confirm at fault.fit. Android first."
- **Shot list:** [TAKE] A — first set. [TAKE] B — next set. [TAKE] C — actual recent saved sets view with both entries, self-reported label; no invented clear-history control or recovery behavior.
- **Captions:** "[FIRST_REPS] / [NEXT_REPS]" / "Retained history only" / "[ACTUAL_RELATION]".
- **Post caption:** "Fault shows the sets my phone still holds. Nothing invented, nothing resurrected. Building in public. fault.fit"
- **Notes:** No invented totals; relation only from `[ACTUAL_RELATION]`.
