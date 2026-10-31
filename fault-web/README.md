# Fault marketing development app

Selected Performance editorial direction; verified Stage 1 solo/manual Android scope. The Flutter application and `challenge-web` are independent and unchanged.

## Local verification

Use Node 22+ and the lockfile. Repository commands require the `rtk` prefix.

```powershell
rtk proxy npm.cmd ci --ignore-scripts
rtk proxy npm.cmd run typecheck
rtk proxy npm.cmd test
rtk proxy npm.cmd run build
```

For a configuration report, run `rtk proxy npm.cmd run check:launch` with the intended hosted environment supplied by its secret store. It reads only process environment and source files, makes no network calls and prints no secret values. It exits 1 for missing/invalid configuration or the current unfinished public policy/copy. A clean configuration report is **not** approval to publish: the output keeps hosted migration, sender, confirmation/unsubscribe, retry and anonymous-production checks explicit. It does not automatically load `.env.local`; for an intentionally supplied ignored file use `rtk proxy node --env-file=.env.local --import tsx scripts/check-launch-readiness.ts`.

The report describes that local process environment, not remote account state: missing local values do not establish missing hosted secrets, an absent project or an unapplied migration. Optional PostHog configuration produces warnings; database signup and authoritative counts work without analytics delivery. Retry authentication can use either `FAULT_DISPATCH_SECRET` for an external dispatcher or `CRON_SECRET` for the Vercel backstop. Neither secret alone proves that a scheduler is running often enough.

`npm test` regenerates `public/legacy` from the repository's `challenge-web` source first. Keep the whole repository in the test checkout, including `supabase/migrations`. This preserves resolver/deletion code and owner configuration while preventing stale copies or platform line-ending differences from breaking the existing equality check. Make legacy source changes in `challenge-web`, then run tests and commit the regenerated public assets. `npm run build` uses those prepared assets and does not need the sibling source, preserving a standalone `fault-web` deployment root. Production runtime does not load local-test database migrations.

`scripts/prepare-local-test.mjs` prepares ignored `.env.local` with random local keys. `npm run dev` uses PGlite PostgreSQL in `.local/db` only when explicit local-test mode and a loopback site URL are set. Provider delivery writes ignored email/analytics spools; **it sends no email and ingests no live analytics**. Never upload `.local`, `.env.local` or browser state. Local mode cannot run on Vercel.

The local harness initializes both isolated schemas and applies the complaint-hold correction to retained fixtures at startup. Tests always create a fresh database. Test generation scripts and spools are not production dependencies.

## Live development readiness

Choose the intended Supabase development project, inspect existing schemas, then apply the Fault migrations in order: `20261004112705_fault_waitlist_stage3.sql`, `20261004161500_fault_waitlist_preview_isolation.sql`, and `20261020173359_fault_waitlist_preserve_complaint_holds.sql` from `../supabase/migrations/`. Existing installations need the new corrective migration; do not rerun the original schema creation. Configure names from `.env.example` through the development secret store / Vercel preview environment. Service-role, email, encryption, throttling, dispatch and webhook secrets are server-only. No credential belongs in `NEXT_PUBLIC_*` or Git. `FAULT_SITE_URL` is the canonical HTTPS preview origin; an exact platform `VERCEL_URL` fallback is supported.

Set `FAULT_TEST_RECIPIENTS` only to the owner's explicitly permitted recipient(s). Preview records are automatically marked internal tests and excluded from launch metrics. Verify the Resend sender/domain and webhook. Run the authenticated provider reconciliation below to exclude existing suppressions. Enable `FAULT_DELIVERY_READY=true` only after these dependencies are verified. Until then signup returns 503 and never substitutes a mock success.

```powershell
# Credentials must be supplied by the configured development secret environment.
rtk proxy npx.cmd tsx scripts/reconcile-suppressions.ts
```

The development reconciliation always targets the preview RPC and refuses production mode. It reads Resend's paginated suppression API and adds exclusions idempotently; it never clears a complaint or removes a provider suppression. Signed provider removal events can clear eligible exclusions, preserving newer events and complaint holds. Complaint/abuse holds require explicit manual clearance; subsequent automated events cannot overwrite their reasons. The corrective migration preserves existing state and cannot reconstruct reasons already lost before it was applied. All bounces conservatively exclude addresses until reviewed; no claim of deliverability beyond known suppression state is made.

During rollback, `FAULT_DELIVERY_READY=false` closes signup and dispatch while configured unsubscribe and signed webhook routes remain available. Unsubscribe cancels queued mail without flushing other delivery work.

`vercel.json` configures a daily `/api/internal/cron` retry backstop authenticated by `CRON_SECRET`. This is not a provisioned five-minute scheduler: the daily interval can exceed a job's 23-hour delivery deadline. Before public collection, select and verify a retry cadence within that deadline, using an available free scheduler or an explicitly approved plan. The existing POST `/api/internal/dispatch` accepts `Authorization: Bearer FAULT_DISPATCH_SECRET` for that scheduler; provision the secret through its vault/environment, never a query parameter. It performs maintenance, dispatches up to ten due jobs and returns aggregate authoritative counts. Leases, eight bounded attempts, exponential delay and stable Resend idempotency keys handle retries. Pending retries cannot rely on user traffic alone. Higher-volume dispatch capacity requires measured load validation; 30,000 addresses is an audience goal, not a prerequisite to test a small beta or a capacity certification. No additional scheduler or paid plan has been provisioned.

Subscribe Resend to `/api/webhooks/resend` with `RESEND_WEBHOOK_SECRET` for `email.bounced`, `email.complained`, `email.suppressed`, `suppression.added`, `suppression.removed`, and `contact.updated`. Test actual subscribed event availability against the configured provider account. Raw bytes and Svix headers are verified before parsing; database receipts and exclusions commit together. Network retries are safe. In-flight provider requests can complete during unsubscribe; future queued mail is cancelled.

## State, measurement and privacy

The service-only `fault_waitlist_command('counts','{}')` returns `uniqueConfirmedSubscribed` and `snapshotAt`. Count unique canonical addresses that are confirmed and currently subscribed, excluding abuse, internal tests and known suppressions. Do not use PostHog event totals as subscriber counts. Canonicalization trims and lowercases ASCII email, preserving plus and dot variants; it does not guess provider-specific alias equivalence.

Confirmation is a 24-hour, 256-bit random token stored as a SHA-256 digest. Retry payloads use AES-256-GCM and are cleared after successful/terminal delivery. Email links put tokens in fragments; the client removes the fragment and requires an explicit POST action, so GET scanners do not consume them. Unsubscribe links expire after one year; an expired link requires a fresh message or support. Public support identity and final retention policy remain a public-release dependency.

Analytics is opt-in. The server keeps the key; browser events go through an allowlisted same-origin API. Full URLs, email, token, IP and form contents are not sent to PostHog. No replay/autocapture/person profiles or geolocation capture. Source/creative identifiers are prospectively registered in `src/lib/contracts.ts`. Last eligible touch within 30 days is credited at submission; first touch is retained and confirmation inherits the saved snapshot across devices. Unknown sources are direct. Attribution labels are not proof of organic traffic or growth forecasts.

`waitlist_submit` captures unique address creation; `waitlist_confirmed` captures each actual pending-to-subscribed transition once, with `first_confirmation` distinguishing a fresh rejoin. Stable insert IDs deduplicate transport retries; delivery remains at-least-once. Event timestamps retain the actual database enqueue time. The consented landing→creation→confirmation funnel is a cohort view, not all website traffic or net active subscribers.

Missing real footage stays explicitly labelled. The player requires both approved `public/solo-demo.mp4` and accurate `solo-demo.vtt`; see `public/MEDIA.md`. `demo_play` is wired to actual playback and is dormant without media. Campaign email is a local draft only. Public collection, production DNS and campaign delivery are outside this development preview.

## Preorders and subscription interest

The current form collects no-charge launch-update interest after email confirmation. It does not create an app account, grant access, reserve a paid entitlement or start a subscription. No payment SDK, checkout route, price or recurring-billing offer is configured. Keep that boundary until the actual release scope, price, currency, billing interval, cancellation/refund terms and operator identity are decided and a payment provider's test flow is verified. A subscription landing-page experiment is deferred; the existing waitlist is enough to measure initial interest without inventing an offer.
