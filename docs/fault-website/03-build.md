# Fault — Stage 3 build handoff

4 October 2026. **Implementation and preview complete; live permitted-email confirmation remains blocked by development service configuration.** No live test email was sent. The owner's designated recipient is recorded in the conversation and must be the only address enabled for the live check.

## Design and release scope

Implemented **Performance editorial**, recorded as the Stage 2 provisional recommendation. The owner also selected editorial through the earlier concept interaction. It remains easy to replace the presentational layer without changing the API. Source: `docs/fault-website/02-design.md:7`, with claims bounded by `01-brief.md`.

Headline: **Give your next set a reason.** Literal copy concerns manually entered, self-reported solo push-ups, phone-local history and Android-first development. No download, public date, camera-counting result, completed battle or acquired-subscriber total is presented. Native Flutter code and existing `challenge-web` behavior are untouched. The $30,000 figure is a quality bar; no paid plan, credits or spending commitment was authorized or purchased.

The complete page has hero/signup, an explicitly missing real-media area, manual practice sequence, three benefits, FAQ, final signup/share, privacy and support pages. Charcoal/lime roles, the proposed Fault wordmark and locally bundled Inter fonts carry through. Basic loading, pending, validation, retry, token and unsubscribe states are implemented; the signature footage animation remains dependent on real media for Stage 4.

## Review links and assets

- [Vercel preview](https://fault-website-barytkjf0-priler003-7576s-projects.vercel.app) — Vercel authentication protected; sign in with the connected account. Deployment `dpl_Fs13eVghdSQEpwBWjAP7JSALR3aa`, verified **preview / Ready**. Inspector: https://vercel.com/priler003-7576s-projects/fault-website/Fs13eVghdSQEpwBWjAP7JSALR3aa.
- Local interactive page: http://127.0.0.1:3000 while the development server runs. Local delivery is explicitly simulated.
- [Desktop](../../design/fault-website/stage3-desktop.png), [390px phone](../../design/fault-website/stage3-phone.png), [768px tablet](../../design/fault-website/stage3-tablet.png), [320px phone](../../design/fault-website/stage3-320.png), [confirmed state](../../design/fault-website/stage3-confirmed.png). These browser captures are local development evidence, not live email proof.
- Editable source is `fault-web/`; design source remains `design/fault-website/`. Funnel definition: `design/fault-website/confirmation-funnel.json`.

The first new-project bootstrap inherited Vercel's Other framework preset and was labelled production despite the explicit preview target. It did not produce the Next.js page. Codex set `fault-web/vercel.json` to Next.js, verified subsequent preview builds and **removed only that new bootstrap deployment** (`dpl_6vCQ2K6WQTYbkP4x6k3vxckXkU68`). No fault.fit DNS or existing remote project was changed. Use the final preview link above, not its initial platform alias. Vercel CLI generated and cached its own protection bypass for authenticated HTTP verification; no bypass value is in this handoff or source.

## Implementation paths

| Area | Exact repository files |
| --- | --- |
| Separate app/build | `fault-web/package.json`, `package-lock.json`, `tsconfig.json`, `next.config.ts`, `vercel.json`, `.vercelignore`, `site-quality.config.json`, `README.md` |
| Pre-rendered layout/copy | `fault-web/src/app/layout.tsx`, `src/app/page.tsx`, `src/components/Narrative.tsx`, `src/app/globals.css`, `src/app/integration.css` |
| Small interactive islands | `fault-web/src/components/SignupForm.tsx`, `Attribution.tsx`, `TokenAction.tsx`, `ShareButton.tsx`, `DemoPlayer.tsx` |
| Server contract/validation | `fault-web/src/lib/contracts.ts`, `src/lib/server/service.ts`, `crypto.ts`, `repository.ts`, `runtime.tsx`, `http.ts`, `webhooks.ts` |
| API routes | `fault-web/src/app/api/waitlist/route.ts`, `confirm/route.ts`, `unsubscribe/route.ts`, `events/route.ts`, `webhooks/resend/route.ts`, `internal/dispatch/route.ts` |
| Email | `fault-web/emails/Confirmation.tsx`, `CampaignDraft.tsx` — approved copy; HTML and plain-text renderer; campaign is draft only |
| Authoritative database | `supabase/migrations/20261004112705_fault_waitlist_stage3.sql` — created through installed Supabase CLI; not applied to a hosted project |
| Provider baseline reconciliation | `fault-web/scripts/reconcile-suppressions.ts` — authenticated Resend suppression API, idempotent additive exclusions; no raw-address output |
| Local verification seam | `fault-web/src/lib/server/local-repository.ts`, `scripts/prepare-local-test.mjs`, `open-local-message.mjs`, `audit-local-flow.mjs`, `verify-database.ts` |
| Regression evidence | `fault-web/tests/contracts.test.ts`, `tests/flow.test.ts`, ignored `test-results/local-browser-flow.json`, `preview.html`, `preview-headers.txt`, `preview-api.json`, `preview-api-headers.txt` |
| Real-media contract | `fault-web/public/MEDIA.md`; `public/fault-wordmark.svg`; `src/app/fonts/Inter*.ttf` |

Paths in a table cell after its first path share the stated parent. App content is a server component passed through an attribution provider; only interaction islands hydrate. No browser Supabase/Resend/PostHog credentials, external fonts or automatic tracking SDK is used. Rendering/markup and server integrations were reviewed against the Next.js and React skills. Dependencies are pinned with a lockfile; deprecated React Email components were replaced with the current unified `react-email` package.

## State and schema

Private `fault_waitlist` schema contains `subscribers`, `tokens`, `outbox`, `receipts`, `suppressions`, `rate_limits`. All have RLS enabled and no anonymous/authenticated access. The sole public RPC is `fault_waitlist_command(text,jsonb)`, `SECURITY INVOKER` with an empty search path; PUBLIC/anon/authenticated execution is revoked and service_role execution is explicit. Private tables are fully schema-qualified. The migration is additive and changes no existing app table or policy.

- Canonical email is trimmed, ASCII-validated and lowercased consistently; dots and plus variants remain distinct. A unique constraint and per-address transaction lock prevent duplicate records. No guessed Gmail alias merging.
- Signup atomically stores pending state, consent/version, source snapshot, hashed confirmation/unsubscribe tokens and an encrypted delivery job. Active/suppressed/duplicate responses use generic pending wording. Resend/rejoin requires consent, rate limits and a fresh token; it never overrides a suppression.
- Confirmation token: random 256 bits, SHA-256 digest, 24-hour expiry, single consumption. Explicit POST changes pending→subscribed atomically. GET opens a decision page without consuming it; URL fragment is cleared before action. Invalid/expired/used/unsubscribed states are distinct.
- Unsubscribe link: one-year expiry. Explicit POST removes eligibility immediately, consumes outstanding tokens and cancels future queued email. Repeated action is safe. Fresh rejoin changes the same address record; replay never changes state again. A provider call already in flight may still finish.
- Delivery outbox: AES-256-GCM payload, stable job/provider idempotency key, two-minute lease, eight bounded attempts, exponential backoff, 23-hour deadline. Successful/terminal mail payloads are cleared. Retry delivery is at-least-once, not an exactly-once transport promise.
- Resend raw body/Svix authenticity is checked before parsing. Receipt insertion and subscriber/suppression changes commit together; retries are idempotent. Delivery never clears suppression, old removals cannot supersede newer exclusions, complaints remain held. All bounces conservatively exclude pending review. Verified contact unsubscribe cannot override fresher consent. Initial provider suppressions must be reconciled before live gating is enabled.
- Persistent HMAC-based IP/address buckets: signup 10/IP/10 minutes and 3/address/hour, token actions 30/IP/10 minutes; browser events 60/IP/10 minutes. Hosted IP uses the platform-populated `x-vercel-forwarded-for`; local uses a fixed loopback bucket. Same-origin JSON/body-size checks apply to user mutations. Webhooks use signature authentication and dispatch uses a constant-time bearer check.

**Launch metric:** at an explicit database snapshot, count **unique confirmed, currently subscribed addresses, excluding duplicates, abuse, internal tests and known delivery suppressions**. The service-only `counts` operation returns `uniqueConfirmedSubscribed` and `snapshotAt`. Pending/unsubscribed/suppressed/test records count zero. No known suppression is not a guarantee of future deliverability. Do not substitute historical analytics confirmations for this current-state count.

## Analytics and video attribution

`fault-web/src/lib/event-map.ts` defines `landing_view`, `demo_play`, `waitlist_submit`, `waitlist_confirmed`, `share_click`. Optional analytics is off until consent. A memory-only anonymous UUID connects a consented browser visit with server transitions; the database source snapshot preserves attribution through a confirmation on another device.

| Event | Owner and trigger |
| --- | --- |
| landing_view | Browser, once after analytics consent on the landing visit |
| demo_play | Browser, first actual user-started playback; dormant because approved media is missing |
| waitlist_submit | Database, once on unique canonical subscriber creation; duplicate attempts/rejoin do not recreate the address |
| waitlist_confirmed | Database, once per real pending→subscribed transition; `first_confirmation` identifies rejoin; token replay emits nothing |
| share_click | Browser, successful native share or copied safe root URL; no subscriber identifier in the shared URL |

Server outbox captures use the database enqueue timestamp, stable `$insert_id`, `$process_person_profile:false` and `$geoip_disable:true`. Retries use the same insert ID. Raw email, verification token, IP, arbitrary query strings, full URLs, form contents and referrer are absent. No replay/autocapture is configured. No analytics runs on confirmation/unsubscribe pages.

Approved prospective registry in `fault-web/src/lib/contracts.ts`: `fault-solo-001` / `fault-solo-001-vertical-a|b`, campaign `solo-prelaunch`, organic-social source Instagram/TikTok/YouTube; `fault-bio` for platform bio; and isolated `fault-dev-test` for development. `utm_content` must equal `creative_id`. Credit the last eligible registered touch within 30 days at submission, retaining first touch; unknown/missing is direct. A video gets its own registered content/creative pair before publication. Platform view exports must use the same ID/date window to calculate confirmed subscribers per 1,000 reported views. Rates remain hypotheses until measured; cross-platform views are not unique people.

Created and queried the connected empty PostHog Default project **272861** development-only saved funnel: [Fault development confirmation funnel](https://eu.posthog.com/project/272861/insights/BtxaDFUN), insight `6322014` / `BtxaDFUN`. Ordered landing_view→waitlist_submit→waitlist_confirmed within 30 days; filters site=fault and environment development/preview. Query returned **no data recorded**. No event ingestion or subscriber import occurred. This consented cohort funnel is not all traffic or a net launch-count dashboard. Production filtering/retention and final project choice remain release decisions; the server's default host matches this EU project.

## Environment names — no values

`FAULT_SITE_URL`, `FAULT_ENVIRONMENT`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `RESEND_FROM`, `RESEND_WEBHOOK_SECRET`, `FAULT_ENCRYPTION_KEY`, `FAULT_RATE_LIMIT_SECRET`, `FAULT_DISPATCH_SECRET`, `FAULT_TEST_RECIPIENTS`, `POSTHOG_PROJECT_KEY`, `POSTHOG_HOST`, `FAULT_LOCAL_TEST_MODE`, `FAULT_DELIVERY_READY`.

Use the selected development secret store and Vercel **preview** environment, never source control or a worker task packet. Encryption key is 32 random bytes encoded as hex. Canonical hosted URL must be HTTPS; platform `VERCEL_URL` is the exact-preview fallback. `FAULT_DELIVERY_READY` stays false until intended database, verified sender, suppression baseline, webhook and retry scheduling have been checked. Preview tests are marked internal and excluded from launch counts. Local test mode requires explicit opt-in, loopback URL and absence of Vercel; it cannot become a deployed fallback. `.env.local` / `.local` / test results are ignored and excluded from deployment.

## Verification

| Check | Result and boundary |
| --- | --- |
| TypeScript + optimized build | Passed final code. Next.js 16.3.8 pre-renders `/`, `/confirm`, `/unsubscribe`, `/privacy`, `/support`; API routes are dynamic Node handlers. Hosted final build Ready, target preview. |
| Meaningful regression suite | **21/21 passed**: 10 delegated contract cases plus PostgreSQL flow parent/10 subcases. Actual migration executes on fresh PGlite PostgreSQL; provider calls are test doubles. Covers dedupe, confirmation replay, cross-device attribution, unsubscribe, invalid/expired tokens, durable retry, signed/spoofed/old webhook signatures, stale suppression removal, public-role denial, rate limits, test/abuse exclusion and fresh-consent rejoin. Rejoin creates one address with two separate real confirmation transitions, each once. |
| Local browser flow | Agent-browser 0.27.0: synthetic address submitted via real page/API, separate browser session confirmed, replay returned used, unsubscribe returned unsubscribed. One landing_view, one creation, one confirmation; same anonymous ID, creative retained, no email/token in simulated analytics. Protected aggregate database metric returned zero because test/unsubscribe exclusions apply. Fresh SQL regressions independently assert eligible count 0→1→0. |
| Responsive review | Visually reviewed 1440 desktop and 390 phone, full-page captures at 768/320 also inspected for layout. No horizontal overflow at 390/768/320 after correcting placeholder sizing. Fonts loaded and wordmark decoded. Reduced-motion preference recognized; CSS transitions disabled and CTA tap transform omitted. Keyboard focus has a visible 3px outline. No browser page errors observed. Not a complete screen-reader/device/lighthouse certification. |
| Hosted HTTP | Authenticated Vercel CLI fetch of final preview returned **200**, literal headline and FAQ in initial HTML, no local simulation banner, `noindex` and `no-referrer`. Same-origin signup returned **503 configuration_required** as intended. Anonymous preview requests require Vercel sign-in; protection was retained. |
| Dependency check | `npm audit --omit=dev --audit-level=high`: zero reported production dependency vulnerabilities at this check. Not a guarantee against future advisories. |
| Live email/database/funnel | **Not performed.** No intended active development Supabase project, usable server credentials, verified Resend sender/domain, webhook or scheduler configuration exists. PostHog saved query is empty. Local spools are simulations, not permitted-recipient delivery or hosted database proof. |

Browser review found and Codex repaired the mobile placeholder overflow and Strict Mode double-reading of a cleared token fragment. Final provider/SQL changes were then typechecked and regression-tested on a fresh schema. Existing local fixtures are deliberately retained; they are not automatically migrated after edits. The initial in-app browser/Chrome connector timed out, so the Vercel agent-browser skill supplied the review evidence.

## Remaining dependencies and owner decisions

1. **Choose the intended Fault development Supabase project/ref.** Connected account offers inactive `fit_ap` (`rfruhwgdrlrzhllzmztk`) and inactive `Pixlift` (`jdnzgangqcoprrjalhmr`); neither was assumed to be Fault or restored. Repository backend separation instructions and absent hosted link do not establish a target. Docker is not running, so local Supabase was not a substitute. After selection: inspect schema/capabilities, apply additive migration, provide service-role credential through the secret flow and verify PostgREST/RLS on that hosted environment.
2. **Configure transactional delivery and retry infrastructure.** Resend account has no domain; choose/verify a Fault sender via the purchased domain's DNS, configure server key and signed event webhook, reconcile known suppressions and provision the authenticated five-minute development dispatcher. No domain/DNS record, paid email tier, provider contact list or campaign was written. Approved test recipient exists; it is not an unresolved permission question. The exact outstanding end-to-end check is: deliver to that recipient, explicitly confirm once, inspect saved attribution and one confirmation event, unsubscribe, verify exclusion in the hosted database, then replay the signed provider event safely.
3. **Supply actual current solo media and public operator details before public collection.** Footage/captions/transcript/poster and rights/build manifest remain absent. Add only approved real `solo-demo.mp4`/`solo-demo.vtt`, rebuild and check genuine playback event. Public privacy identity, support contact and final data-retention terms are outstanding. Existing emulator battle/AI dramatization fixtures remain references.

PostHog ingestion key must be placed server-side for the selected development project; the saved funnel already exists. No account upgrade or production promotion is needed to review this preview. Higher-volume/load, mail capacity, accessibility, signature motion and final footage checks belong in subsequent stages; no 30,000-address capacity test has been claimed.

## OpenCode delegation

**03-components — accepted with Codex integration repairs.** Batched required presentational components, approved confirmation/campaign email markup, event-name mapping and meaningful validation/attribution regressions after Codex settled `docs/fault-website/03-contract.md`.

- Provider/model: **OpenCode Go / `opencode-go/deepseek-v4.1-flash`**, explicit coding-task CLI route, `--agent build`; session `ses_ef9542e49ffe5NBXhZIt37qYe2`.
- Evidence: `tmp/fault-opencode/03-components.task.md`, `03-components.baseline.txt`, `03-components.report.md`, `03-components.events.jsonl`, `03-components.usage.json`. Logs remain local. Inputs were bounded contract/design/skill files; no secrets, recipient identity, tokens or subscriber records were sent to the worker.
- Exact six-file ownership: `fault-web/src/components/Narrative.tsx`, `src/app/globals.css`, `emails/Confirmation.tsx`, `emails/CampaignDraft.tsx`, `src/lib/event-map.ts`, `tests/contracts.test.ts`. No server/database/live-write ownership was delegated. One initial assignment; no rerun or model substitution.
- Codex inspected actual files against baseline and checked copy/scope, composition, email markup, browser behavior and assertions. Final typecheck, build and 21-case regression evidence support acceptance; worker's own 10/10 report alone was not used as proof.
- Codex repairs: email package modernization, event metadata/confirmation semantics, hero accessible name, equipment FAQ wording, mobile placeholder width/wrapping and benefit separators. Codex supplied all integration islands, schema/RLS, token/server flow, webhook decisions, test database/flow cases and remote operations.
- Reported per-step usage across 22 completed steps: input **76,575**, output **12,330**, reasoning **21,748**, cache read **1,848,704**, cache write **0** tokens. Provider-reported cost sum **$0.037479162**; not a verified bill, spending commitment or savings calculation. The cumulative total field was not summed. No percentage of Codex savings is asserted.

## Current documentation consulted

Context7 supplied current Next.js route-handler/server-boundary and Resend send/idempotency/webhook guidance. Installed Next.js local `dist/docs` and Resend/Svix SDK type/API behavior were checked; Svix verification returns void, so parsing occurs explicitly after successful verification. Supabase invoker/grant/RLS guidance and its current changelog were reviewed before schema work. Useful primary references: [Vercel trusted request headers](https://vercel.com/docs/headers/request-headers), [Supabase function privileges](https://supabase.com/docs/guides/database/functions), [Resend idempotency](https://resend.com/docs/dashboard/emails/idempotency-keys), [Resend webhook verification](https://resend.com/docs/dashboard/webhooks/verify-webhooks-requests), [PostHog capture API](https://posthog.com/docs/api/capture).

Stage 3's independently verifiable build is complete. **The live integration acceptance criterion remains open**, with the exact external prerequisites above. No simulated evidence is labelled as live delivery or public launch readiness.
