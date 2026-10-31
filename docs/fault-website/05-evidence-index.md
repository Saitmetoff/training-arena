# Fault — Stage 5 release evidence index

4 October 2026. Concise, source-backed index of the sanitized Stage 5 evidence. The
detailed release handoff is Codex's separate `docs/fault-website/05-release.md`; this
file only locates and interprets evidence. Release decision: **HOLD public waitlist
collection** (`fault-web/test-results/stage5/service-status.json`). The Performance
editorial composition and product copy are unchanged; the poster fallback is approved
and explicitly illustrative. Local lifecycle runs use PGlite and simulated provider
spools — they are **not** live email delivery.

## Evidence by category

| Category | Source files | What it establishes |
| --- | --- | --- |
| Build / regression | `fault-web/test-results/stage5/checks.json`, `typecheck.txt`, `regressions.txt`, `build.txt`, `dependency-audit.txt` | Typecheck exit 0, final 36/36 regression tests, Next.js build compiled, 0 audited production-vulnerabilities. |
| Browser / keyboard | `fault-web/test-results/stage5/browser.json`; screenshots `design/fault-website/stage5-desktop.png`, `stage5-tablet.png`, `stage5-mobile.png`, `stage5-320.png`, `stage5-reduced-motion.png`, `stage5-review.png`, `stage5-text-200.png` | Local production build at 4 viewports, fonts loaded, no clipping, reduced motion, 200% emulated text reflow. |
| Local lifecycle / security | `fault-web/test-results/stage5/http-flow.json`, `regressions.txt`, `client-secret-scan.json`, `secret-scan.txt`, `public-pages.txt`, `public-page-tests.txt`, `app-links.txt` | Simulated signup→confirm→replay→unsubscribe states, HTTP origin rejection, regression-tested Svix signature rejection, configured local secrets absent from client bundles, 21/21 public-page tests. |
| Hosted database | `fault-web/test-results/stage5/hosted-db.json`, `environment-isolation.json` | Real fit_ap migrations applied. Production/preview have separate schemas/RPCs/outboxes; all 12 tables have RLS, public clients lack access. Eligible production count 0. |
| Hosted preview | `fault-web/test-results/stage5/hosted.json` | Protected preview returns real homepage; robots noindex/nofollow; anonymous request redirects to Vercel SSO. Raw headers stay local and are not worker evidence. |
| Lab performance | `fault-web/test-results/stage5/lab-summary.json`, `lighthouse-mobile-motion-final.json`, `lighthouse-desktop-motion-final.json` | Current-version lab scores. Earlier rows are optimization history, not current performance. |
| External service evidence | `fault-web/test-results/stage5/service-status.json` | Supabase/Resend/PostHog state: no live lifecycle, no verified sender, PostHog funnel has no data. |

## Preview identity

- Protected preview: [Fault preview](https://fault-website-mdwznrktl-priler003-7576s-projects.vercel.app),
  deployment `dpl_CD2k11aeY7AUvFvzTEYUdacA5oNf`, target **preview** (never public
  production). Codex set framework `nextjs`; the preview packages functions and serves
  the real homepage. Earlier Ready build carried Vercel's wrong Other preset and a 404
  root; Codex independently verified this from Stage 5 CLI project inspection and deployment logs.
- Screenshots are browser evidence, not product footage; poster frames are illustrative.

## Performance: lab versus field

Current-version lab rows (`*motion-final`): mobile performance 0.92 with
**LCP 3,175.85 ms**, desktop performance 1.0 with LCP 670.33 ms (`lab-summary.json`).
Mobile LCP remains **above the 2.5 s target** even in the lab simulation. Earlier
mobile rows (`lighthouse-mobile`, `-after`, `-latin-preload`, `-demand-fonts`,
`-final`, `-applied*`) document the font-subset optimization path and are history, not
current field performance. The font transfer work is recorded in
`tmp/fault-opencode/05-font-fix.report.md`; Codex subsequently narrowed the English
font subset and adjusted loading.

These are **navigation lab runs**, not real-user data: INP and p75 are not measured,
no real-user sample exists (`lab-summary.json`, `service-status.json`). The 30,000
subscriber/delivery capacity is not load-tested.

## Failed and blocked checks

- `public-pages-release.txt` (exit 1): release mode blocked on 12 missing owner fields,
  no real backend URL and no publishable key. This is the documented pre-public state,
  not a regression.
- `app-links.txt`: passed with a warning that the challenge host is still the
  placeholder `example.invalid`; App Links cannot verify.
- `.well-known/assetlinks.json` returns 503 on both local and hosted runs (genuine
  release fingerprint missing).
- Hosted `/qa-media` returns 404; the local-only harness is not deployed.
- Hosted anonymous request redirects to Vercel SSO (302) — intended protected state.

## Interpretation notes

- `browser.json` `challenge.codeVisible` is `false` (literal). Readable challenge codes
  may be grouped in the destination flow, so treat this boolean as raw output needing
  interpretation — it is **not** proof of a live backend success.
- `hosted-db.json` confirms the migration, role and grant checks are real, but
  `liveLifecycle` is unexercised: no server credential and no verified email sender.
- The PostHog saved funnel definition is verified but its query returned no data
  (`service-status.json`).

## Keyboard correction (verified by Codex)

`browser.json` shows the first Tab reaches "Skip to content", but activating it does
not move focus to `<main>` because the target lacked `tabindex`. One low-risk
correction was made: `tabIndex={-1}` on the existing `<main id="main">` in
`fault-web/src/components/Narrative.tsx:27`. Semantics, CSS, copy and motion are
unchanged. After rebuilding, Codex used native Tab then Enter: active element became MAIN with id `main` and tabindex -1. Evidence: `fault-web/test-results/stage5/keyboard-final.json`. The original worker report correctly recorded this as pending at dispatch time.

## Exact unresolved external dependencies

1. Supabase server credential through the designated secret store; fit_ap is already selected, resumed and migrated. The live lifecycle remains unexercised.
2. Verified Resend sender/domain, signed webhook, suppression baseline and dispatcher;
   no live email sent.
3. PostHog ingestion key is now stored server-side in Vercel. The live server dependencies still prevent event ingestion; no real-user sample exists.
4. Owner public fields (12), real backend URL and publishable key for the release
   check; genuine Android release fingerprint.
5. Legacy app backend configuration and release certificate remain unresolved. Do not assume the selected waitlist database is the app's challenge/deletion backend.

Asset and performance limitations: real solo media/captions are still absent; the owner approved the labelled poster fallback. This is not a finished footage release. Mobile simulated LCP remains above the 2.5 s target; no real-user percentiles have been established.
