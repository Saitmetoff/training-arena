# 14-day content experiment — production and measurement packet

Prepared: 2026-09-21 · L09 (OpenCode, `opencode-go/deepseek-v4.1-flash`) ·
Companion: `docs/social/ACCOUNTS.md`, `docs/social/briefs/BRIEF-01..03`.

Status: **drafts only.** No footage is captured, no account exists and nothing
is published. Publishing happens only per-asset after owner approval to the
named project accounts. The experiment is the launch plan's table
(`docs/release/LAUNCH_PLAN_2026-09-20.md` §TikTok and Instagram execution),
expanded into something shootable and measurable.

## 1. Objective and what counts

Hypothesis: real vertical footage of a pair accepting and settling a
60-second challenge moves viewers to invite a friend — measured by confirmed
battles, not by reach.

Activation definition (binding): **a first server-confirmed battle between two
human accounts.** A like, view, profile visit, install or share-sheet open is
not activation and is never reported as one.

## 2. Truth rules (binding on every asset)

- Real app UI in every edit; real builds only. No mockups, no generated UI, no
  fabricated scores, receipts, ratings, counts or testimonials.
- Real results only: if the pair tied or lost, that is the published outcome.
  Never reshoot to manufacture a win.
- Synthetic adults may act only in the clearly labeled dramatization
  (Brief 03). They are never presented as customers, users or testimonials.
- No accuracy percentages, no "cheat-proof", no medical/fitness-transformation
  claims, no social proof that did not happen.
- AI-generated content is labeled on the first frame, in the caption and with
  the platform's own AI disclosure control (TikTok requires realistic-AI
  labels; Meta applies transparency labeling).

## 3. Production standards

| Item | Standard |
| --- | --- |
| Format | 1080×1920 (9:16), 30 fps, H.264 MP4, 15–25 s target (≤ 60 s hard) |
| Captions | Burned in, high contrast, within the safe area (keep the top ~120 px and bottom ~320 px clear of platform UI) |
| UI capture | Screen recording of the real build with reserved test accounts only (no personal data, no emails, no tokens) |
| Music | Platform commercial library (business/professional account) or original/royalty-free with a written licence; every track recorded in the music ledger. No unlicensed music |
| Consent | Signed release per filmed person before the camera rolls: recording + publication on the named project accounts, both platforms, scope, term, revocation contact. Adults only. Forms stay in owner-held records, **not** in this repository |
| Evidence | Signed-build hash on the shoot sheet; licence and consent ledger rows |
| AI assets | Brief 03 only, labeled per §2 |

Ledgers (owner-held or under `qa/social/` at shoot time; no names or contact
details in git):

- consent ledger columns: `participant_code, shoot_date, form_ref, scope, platforms, term, revocation_contact_ref, status, approver`
- music ledger columns: `asset_id, track, source, licence_id_or_url, platforms, term, evidence, date, approver`

## 4. The 14-day calendar

One original vertical edit per day, adapted per platform. "Footage" is the
dependency, not the concept: today every row is **NOT CAPTURED**. Script numbers
are the briefs in `docs/social/briefs/`.

| Day | Hook / concept | Footage needed | Script | CTA gate |
| --- | --- | --- | --- | --- |
| 1 | "Which friend would accept a 60-second challenge?" | Real invitation flow (screen capture, clean context) | 01 open + 02 CTA | no destination → "follow for beta"; invite CTA only after a working link |
| 2 | "We finally settled the push-up argument." | Consenting pair, actual result | 01 | same |
| 3 | "Your phone needs to see your whole body." | Real framing demonstration | 02 | same |
| 4 | "The last five seconds changed the result." | Genuine close match (outcome must be real) | 01 | same |
| 5 | "Push-ups or squats?" | Both reviewed movements shown accurately (media review gate applies) | 01 + 02 | same |
| 6 | "One link. The same opponent." | Real install/auth return on the Play path (needs the Play track) | screen-capture edit | blocked until Play internal testing exists |
| 7 | "We tied." | Actual draw, fresh challenge CTA; no async replay implication | 01 | same |
| 8 | "What happens when tracking is lost?" | Honest pause/reframe demonstration (camera build) | 02 | same |
| 9 | "Two friends, two rooms, one minute." | Real synchronized battle footage | 01 | same |
| 10 | "Can a beginner challenge a friend?" | Voluntary paced demo; no body-shaming, no medical claims | 01/02 | same |
| 11 | "The challenger lost." | Actual result with permission | 01 | same |
| 12 | "Behind the count." | On-device processing explanation supported by verified behavior | 02 | same |
| 13 | "Tonight's beta battle window." | Publish only with a roster, times and live test access | screen capture | blocked until a test track and roster exist |
| 14 | Best-performing hook retest | Different opening on the same truthful story | reused | compare activation per §7 |

Every row inherits §2 and §3. Nothing publishes on Day 1 until: an account
exists, the owner has approved that specific asset, and the CTA is a true
statement at publish time.

## 5. Capture sessions (run when unblocked)

| Session | People | Needs | Produces |
| --- | --- | --- | --- |
| A — setup demo | 1 consenting adult + operator | L04-signed camera build, tripod, good light, real device | Brief 02 scenes (framing, practice, real count, tracking-loss pause, permission prompt) |
| B — real pair battle | 2 consenting adults + operator | L04-signed build, hosted stack, two devices, signed forms | Brief 01 scenes (invite, acceptance, round, real receipt, reactions) |
| C — UI screen capture | nobody | real build + real backend, reserved `.invalid` test accounts | UI inserts for all briefs; no personal data on screen |
| D — AI dramatization | nobody | external AI video tool (owner decision; none in this repo) | Brief 03 scene, labeled |

## 6. Approval and publishing workflow

1. Cut the asset; attach the shoot sheet (build hash), consent and music
   ledger rows.
2. Owner reviews the specific asset against §2 and approves it in writing
   (asset id + platform).
3. Publish only to the named project accounts; record the post URL in the
   per-post ledger.
4. Any edit after approval is a new asset and needs approval again.

## 7. Tracking: content → qualified visit → install → first confirmed battle → repeat play

Each stage has exactly one source. Where a source does not exist yet, the stage
is marked **NOT INSTRUMENTED**; no proxy is substituted.

| Stage | Definition | Source | State |
| --- | --- | --- | --- |
| Content reach | Views/profile visits on the published post | Platform analytics (TikTok/Instagram) | not applicable yet (no account/post); engagement only, never activation |
| Qualified visit | A genuine page view of the product destination opened from a named asset's link | Server-side request logs of the hosted landing (per-asset path or campaign parameter) | **NOT INSTRUMENTED** — no destination (D1/L05), and the landing ships no analytics by design (`challenge-web/app.js` header, `README.md` §security notes) |
| Install | Play install of `app.trainingarena.mobile`, attributable via the Play install referrer (`referrer=challenge=<token>`) | Play Console statistics + install referrer on the Play path | **NOT INSTRUMENTED** — no track/listing evidenced; direct-APK sideloads cannot measure installs (`PILOT_PLAN.md` §4.1) |
| First confirmed human battle (activation) | A match row + receipt with two real human accounts | Server match/receipt tables (owner-run query); pilot roster log for invited cohorts | reachable once the pilot and hosted stack exist; client events (`challenge_request_accepted`, `matchmaking_match_found`) are leading indicators only |
| Repeat play | A second confirmed battle with any human within 7 days of activation | Same server tables | same |

Explicit non-events: `challenge_share_sheet_opened`, `result_share_sheet_opened`
and `challenge_install_cta_tapped` are funnel hints, never installs or
activation. No app event exists for "first open"; installs are never inferred
from app analytics.

Attribution limits (named, not papered over): the app does not parse UTM or
campaign parameters; the landing (`challenge-web/`) serves challenge tokens
only and ships no analytics scripts. Per-asset attribution therefore requires,
once the destination exists, one of: (a) a distinct landing path per asset with
server-log counts, (b) a campaign parameter logged server-side on the landing,
or (c) a manual roster code per asset. Any option is an owner privacy decision
and must fit `docs/privacy/DATA_INVENTORY.md`; L09 adds no tracking code.

Per-post ledger columns: `asset_id, publish_date, platform, post_url,
views, profile_visits, qualified_visits, installs, activations, repeat_plays,
notes`. Report each stage separately with its source and date; do not promote
a concept on views alone. Experiment decision: after the 14 posts, keep the
hook with the best activation-per-qualified-visit, not the best view count.

## 8. Blocked inputs

1. L04 camera/media sign-off — Briefs 01 and 02 cannot be captured honestly
   before it (camera counting stays off; a camera-off demo is not a battle).
2. Hosted stack + signed build (L05, R9) — a real captured battle needs the
   real backend and a distributable build.
3. Play track/listing — Day 6, install measurement and any Play CTA.
4. Owner social inputs — account email, handle, language/country, brand-art
   acceptance (see `ACCOUNTS.md` §2).
5. Two consenting adult testers and their signed releases for Session B.
6. Owner decision on the AI video tool for Brief 03.
