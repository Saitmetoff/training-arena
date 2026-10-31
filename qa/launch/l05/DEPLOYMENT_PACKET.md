# L05 hosted deployment packet

Prepared: 2026-09-20 · Repository: `D:/TrainingArena` · Branch:
`codex/training-arena` · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`)
Status: **prepared and locally verified; hosted execution BLOCKED — no owner
target exists.** Value ownership: `docs/release/CONFIGURATION.md` §1–§6.
Rollback: `docs/release/ROLLBACK.md` §3–§6. This packet is the ordered
execution runbook; it does not invent a domain, project, provider or budget.

## 0. Why this is blocked

Every hosted step needs a named target. None is identified:

| Input | Needed for | Status |
| --- | --- | --- |
| Real HTTPS domain (D1) | App Links, challenge-web, Supabase site URL/redirect, assetlinks | **missing** — defaults are `example.invalid` |
| Supabase organization + new project (D3) and region | database, functions, Auth, SMTP | **missing** — no project ref |
| Hosting destination for `challenge-web/` | `/c/<token>` landing page and `/.well-known/` | **missing** |
| SMTP provider + sender identity + ownership | email OTP delivery to real testers | **missing** |
| Secret storage location (vault) + dispatcher-secret custodian | `ARENA_DISPATCHER_SECRET`, service role, SMTP creds | **missing** |
| Google OAuth client values (optional for L05) | Google sign-in; may finish in L06 | **missing** |
| Play app-signing certificate SHA-256 (from Play Console) | `assetlinks.json` fingerprint; App Links verification | **missing** (R2/R9) |
| Play Console production access + closed-test start | Play-installed referrer proof | **not evidenced** |

Nothing external was created, deployed, purchased or rotated. The moment the
owner names these values, run §3–§7 in order; every command below is exact.

## 1. Local pre-flight already verified (2026-09-20)

The code is deploy-ready on the current tree; evidence in `qa/launch/l05/`.

| Check | Command | Result | Evidence |
| --- | --- | --- | --- |
| Migrations from scratch | `supabase db reset` | applied cleanly | `db_reset.txt` |
| pgTAP (schema/flow/authz/ops) | `supabase test db --local` | **184/184, 4 files, PASS** | `pgtap.txt` |
| Arena edge tests | `deno test tests` (`supabase/functions/arena`) | **48 passed / 0 failed** | `deno_arena.txt` |
| Dispatcher edge tests | `deno test tests` (`supabase/functions/arena-dispatcher`) | **10 passed / 0 failed** | `deno_dispatcher.txt` |
| Landing guard + unit | `node challenge-web/scripts/check.mjs`, `node --test challenge-web/test/link.test.mjs` | passed | `challenge_web_check.txt`, `challenge_web_tests.txt` |
| Placeholder release gate | `node tools/release/check_app_links.mjs --release` | **exit 1** (missing real host) | `app_links_placeholder.txt` |
| Real-host release gate | `... --release --host arena.pilot.example --fingerprint <64-hex>` | exit 0 | `app_links_realhost.txt` |
| Worker boundary + shared outage | `supabase functions serve --no-verify-jwt --env-file supabase/.env.local` + `node backend/e2e/arena_smoke.mjs` | **24/24 passed**, including wrong/missing dispatcher bearer → 401, and both clients gone → `no_result`/`service_outage` via the worker sweep | `arena_smoke_dispatcher.txt` |
| Serve-log hygiene | scan of the served-function logs for JWT/emails/bearer values | no token, email or bearer value | `serve_log_scan.txt` |

The extended smoke section is gated on `ARENA_DISPATCHER_SECRET`; without it
the smoke stays the task-04 16-check smoke. `supabase/.env.local` (gitignored)
now carries a local-only random `ARENA_DISPATCHER_SECRET`; never copy it to a
hosted project or an evidence file.

## 2. Ordered execution (owner values required)

### 2.1 Supabase project

```powershell
# 1. Owner creates the project in the Supabase dashboard (new org or existing;
#    never the previous application's project). Record: project ref, region,
#    plan, owner account, billing owner.
# 2. Link this checkout (project ref is public):
supabase link --project-ref <project-ref>
# 3. Push only the migrations. seed.sql is local-only and must never reach a
#    hosted project.
supabase db push
supabase migration list --linked          # both 20260917* migrations applied
```

Post-push checks (SQL editor, service role):

```sql
select relname, relrowsecurity from pg_class
  where relnamespace = 'public'::regnamespace and relname like 'arena_%';
-- every row relrowsecurity = true
select count(*) from information_schema.role_table_grants
  where grantee in ('anon','authenticated') and table_schema = 'public';
-- 0
```

Do **not** run `seed.sql`, `db reset`, truncate or drop on the hosted project.

### 2.2 Edge functions and secrets

```powershell
supabase functions deploy arena --project-ref <project-ref>
supabase functions deploy arena-dispatcher --project-ref <project-ref>
# config.toml keeps verify_jwt = false for both; the arena POST verifies the
# JWT in-function and the RPC re-checks auth.sessions; the dispatcher uses its
# own bearer secret.
supabase secrets set --project-ref <project-ref> `
  ARENA_ALLOWED_ORIGINS=https://<domain> `
  ARENA_PUBLIC_URL=https://<domain> `
  ARENA_DISPATCHER_SECRET=<long random, generated into the owner vault>
# FCM_SERVICE_ACCOUNT_JSON only with owner authorization and L06 (no-push pilot
# ships without it).
```

Verification (exact commands, no tokens printed):

```powershell
# anonymous read-only resolve is up
curl.exe -s "https://<project-ref>.supabase.co/functions/v1/arena?token=unknown0token"
# -> {"data":{"owner":null,"available":false}}
# dispatcher rejects a missing/wrong bearer and accepts only its secret
curl.exe -s -o NUL -w "%{http_code}`n" -X POST "https://<project-ref>.supabase.co/functions/v1/arena-dispatcher"
# -> 401
curl.exe -s -o NUL -w "%{http_code}`n" -X POST -H "Authorization: Bearer wrong" "https://<project-ref>.supabase.co/functions/v1/arena-dispatcher"
# -> 401
curl.exe -s -X POST -H "Authorization: Bearer <secret>" "https://<project-ref>.supabase.co/functions/v1/arena-dispatcher"
# -> {"data":{"maintenance":{...},"delivery":"not_configured"}}
```

### 2.3 Auth, OTP and SMTP (dashboard)

| Setting | Value |
| --- | --- |
| Site URL | `https://<domain>` |
| Additional redirect URLs | `trainingarena://challenge/auth` (exact match with the app's `ARENA_AUTH_REDIRECT_URL`) |
| Email provider | email OTP enabled, `otp_length = 6`; copy `supabase/templates/magic_link.html` (shows `{{ .Token }}`) as the magic-link template |
| SMTP | owner's provider: host/port/user/pass, verified sender, sender name "Training Arena"; production SMTP is required for real testers |
| Rate limits | keep the defaults (`email_sent = 2/h` locally; set the hosted limit deliberately and record it) |
| Anonymous sign-ins | disabled (`enable_anonymous_sign_ins = false`) |
| Google provider | only if the owner supplies client id/secret and the Play app-signing SHA-1; otherwise defer to L06 |
| Confirmations | email confirmations off (OTP code flow) |

Then verify delivery with a real mailbox before inviting testers.

### 2.4 Maintenance/outbox schedule (worker-secret separation)

Enable the `pg_cron` and `pg_net` extensions in the dashboard, store the
dispatcher secret in Vault, then schedule one run per minute:

```sql
select vault.create_secret('<same secret>', 'arena_dispatcher_secret');
select cron.schedule('arena-dispatcher', '* * * * *', $$
  select net.http_post(
    url := 'https://<project-ref>.supabase.co/functions/v1/arena-dispatcher',
    headers := jsonb_build_object(
      'Authorization',
      'Bearer ' || (select decrypted_secret from vault.decrypted_secrets
                    where name = 'arena_dispatcher_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 10000
  );
$$);
```

- The worker holds the dispatcher bearer; the app never does. The service-role
  key stays inside the function settings.
- Verify: `select * from cron.job where jobname = 'arena-dispatcher';` and
  `select status, return_message, start_time from cron.job_run_details
   order by start_time desc limit 5;`
- Alternative (owner choice): an external scheduler (for example a CI cron
  job) POSTing the same URL with the bearer. Either way, record the owner and
  the alerting path.
- Stop the schedule (`select cron.unschedule('arena-dispatcher');`) or rotate
  the secret to pause outbox leasing (ROLLBACK.md §3.3).

### 2.5 Landing page, App Links and domain consistency

1. Deploy `challenge-web/` to `https://<domain>` with `/c/*` rewritten to
   `index.html`; `/.well-known/assetlinks.json` served as
   `application/json` without redirects.
2. Replace the placeholder in `challenge-web/config.js`:

   | Field | Value |
   | --- | --- |
   | `apiBase` | `https://<project-ref>.supabase.co` |
   | `linkHost` | `<domain>` |
   | `publicUrl` | `https://<domain>` |
   | `playStoreUrl` | unchanged (frozen Play URL) |

3. `assetlinks.json`: `package_name = app.trainingarena.mobile`,
   `sha256_cert_fingerprints = [<Play app-signing SHA-256>]` (Play Console →
   App integrity). Include the upload-key SHA-256 only if side-loaded
   upload-key builds must also verify.
4. Verify:

   ```powershell
   node tools/release/check_app_links.mjs --release --host <domain> `
     --fingerprint <play-app-signing-sha256> --fetch-assetlinks
   adb shell pm verify-app-links --reverify app.trainingarena.mobile
   adb shell pm get-app-links app.trainingarena.mobile   # -> verified for https://<domain>
   ```

5. Domain consistency (all four must match):

   | Place | Value | Enforced by |
   | --- | --- | --- |
   | Gradle property | `-ParenaLinkHost=<domain>` | `check_artifact_identity.mjs` / manifest |
   | Dart `ARENA_LINK_HOST` / `ARENA_PUBLIC_URL` | `<domain>` / `https://<domain>` | `check_app_links.mjs --release` |
   | `challenge-web/config.js` `linkHost`/`publicUrl`/`apiBase` | as above | `challenge-web/scripts/check.mjs` + release review |
   | Supabase site URL + redirect allowlist | `https://<domain>`, `trainingarena://challenge/auth` | hosted Auth settings |

## 3. Hosted verification matrix (L05 acceptance)

Run on real devices against the hosted project, with the pilot build
(`CONFIGURATION.md` §1 values, `ARENA_FEATURE_CAMERA_COUNTING=false` until L04
signs off).

| # | Case | Exact check | Expected |
| --- | --- | --- | --- |
| 1 | Fresh user | new email → OTP from real SMTP → choose unique username | signed in, profile loads, durable link shown |
| 2 | Username conflict | second account picks the same username | `username_taken`, retry works |
| 3 | Expired session | revoke the session in the dashboard (or wait past JWT expiry) and use the app | signed out, no crash, sign-in returns to the same pending challenge |
| 4 | Process death | kill the app with a pending invitation, relaunch | the pending invitation is restored exactly |
| 5 | Cold link | tap the HTTPS challenge link with the app not running | App Links opens the app directly (no disambiguation), challenge shown |
| 6 | Warm link | same while the app runs | same challenge, no duplicate |
| 7 | Explicit acceptance | recipient accepts | match created, both see the same match id |
| 8 | Unavailable/expired challenge | revoked link, expired request (>24 h), completed link | read-only copy; landing page shows the matching state; `link_not_found`/`request_expired` |
| 9 | Anonymous resolve | `GET /functions/v1/arena?token=<real token>` | `{owner,available:true}`; unknown token `available:false` |
| 10 | Play referrer | install from the Play link carrying `referrer=challenge%3D<token>` | challenge recovered after install (Play-installed artifact only; a sideload cannot prove it) |

Record each row with device, build SHA-256, timestamp and screenshot/log path.

## 4. Operations to record (owner)

- **Backups/recovery**: record the project plan, whether PITR is enabled, the
  backup window and the restore owner. Before real data, take a logical dump
  (`supabase db dump --linked -f backups/<date>.sql` or dashboard export);
  rehearse one restore into a scratch project. Never restore over live data
  without owner approval.
- **Logs without tokens**: the served-function log scan (§1) shows function
  names only. On hosted, spot-check Edge Function logs and Auth logs for
  tokens/emails after the matrix run; the gateway/dispatcher never log tokens
  by code (audited in `docs/API.md` §8 and task-11 checks).
- **Cost visibility**: record the owner-visible usage pages (project usage,
  bandwidth, storage, Edge invocations, Cron) and set a budget alert. No spend
  beyond the owner-approved plan without a separate approval.
- **Secret custody**: owner + vault location for `ARENA_DISPATCHER_SECRET`,
  `SUPABASE_SERVICE_ROLE_KEY`, SMTP password, FCM service account (later),
  release keystore (R9). Rotation actions in `ROLLBACK.md` §5.
- **Operational ownership**: product owner (domain/project/hosting/SMTP),
  backend owner (functions, schedule, RLS), release owner (keystore, Play).

## 5. Small measured concurrent-pair load test

Run after the matrix passes, with the owner's approval, against the hosted
project:

1. Four hosted test accounts (2 pairs) signed in on four clients.
2. Pair A and pair B each start a casual battle within the same 10 s window
   (friend challenge or queue); run one full 60 s round per pair concurrently.
3. Measure from the Supabase Edge Function logs: invocation count, error rate
   (must be 0 × 5xx), p50/p95 duration for `arena` during the window; from the
   clients: round completed, one receipt per match, no duplicate rating rows
   (`select count(*) from arena_receipts` per match = 1).
4. Record the numbers and the log timestamps in the L05 report. Any 5xx or
   duplicate receipt stops the pilot and opens an incident.

## 6. Rollback (per layer, owner-approved)

Use `docs/release/ROLLBACK.md`: client/feature flags (§2), hosted project
(§3.2 — forward fixes only with real data), dispatcher/schedule (§3.3),
landing page and App Links (§4), secrets (§5). Never drop hosted tables or run
`db reset` against a hosted project without written approval and a verified
backup.

## 7. Definition of done for L05

- Owner inputs in §0 supplied and recorded in `docs/decisions/0001-...`
  (D1, D3) and `CONFIGURATION.md`.
- §2 executed; §3 matrix passed with real hosted evidence; §4 operations
  recorded; §5 numbers recorded.
- `check_app_links.mjs --release --host <domain> --fingerprint <sha256>
  --fetch-assetlinks` passes and `pm get-app-links` reports `verified`.
- No placeholder runtime value in the pilot build; no fixture data in the
  hosted project; `node tools/release/secret_scan.mjs` clean.
