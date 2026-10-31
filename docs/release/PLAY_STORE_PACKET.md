# Training Arena — Google Play store packet

Prepared: 2026-09-20 · Branch: `codex/training-arena` · Starting commit: `1819ebf`
Prepared by: L07 (OpenCode, `opencode-go/deepseek-v4.1-flash`)
Status: **factual packet complete; submission BLOCKED on owner inputs and gates.**

Blocking inputs: legal entity/address, privacy and support contacts, retention
periods, hosting destination for the public pages (L05 D1), Play Console
access, release signing (R9), the camera/media decision (L04/R13) and the
Google OAuth values (R3). Nothing in this packet is published, uploaded or
declared in Play Console.

Companion documents:

- `docs/privacy/DATA_INVENTORY.md` — traceable data inventory, retention and
  deletion behavior this packet declares.
- `challenge-web/privacy.html`, `support.html`, `delete-account.html` — the
  public pages and the external deletion route (deploy steps in §10).
- `design/arena/store/` — the two mandatory graphics.
- `qa/launch/l07/` — evidence for the checks cited here.

## 0. Current artifact and scope

| Item | Value | Source |
| --- | --- | --- |
| Application ID / label | `app.trainingarena.mobile` / `Training Arena` | `app/android/app/build.gradle`, `AndroidManifest.xml` |
| Version | `1.0.0+1` (bump for every pilot build) | `app/pubspec.yaml` |
| minSdk / targetSdk | 24 / 36 | `build.gradle`, `tools/release/check_artifact_identity.mjs` |
| Distribution format | Android App Bundle (Play requirement) | `tools/release/check_android_bundle.mjs` |
| Signing | **not configured (R9)**; no distributable artifact exists | `docs/release/CONFIGURATION.md` §3 |
| Pilot flags | camera counting **off**, ranked **off**, push **off**, challenge links on, result sharing on, preview fixtures off | `PILOT_PLAN.md` §5, `CONFIGURATION.md` §1 |

What the current artifact can do: email-code sign-in, challenge links, inbox,
accept/decline, preparation screens, profile, history, blocking/reporting.
What it cannot do with camera counting off: a counted 60-second round cannot
finish, so there is no competitive result in this build (L04: "a camera-off
demo is not a completed battle release"). The listing copy below therefore has
two variants and the release variant must not be used until L04 signs.

Claims this packet never makes: no medical approval, no medical device, no
diagnosis or treatment, no automatic form scoring, no CV verification and no
camera-accuracy number. Camera counting is described only as "on-device
processing, not yet enabled in the closed-test build".

## 1. Policy check against the live pages (2026-09-20)

| Requirement | Official source (retrieved 2026-09-20) | What it requires | How this packet complies |
| --- | --- | --- | --- |
| Account deletion | https://support.google.com/googleplay/android-developer/answer/13327111 | In-app path **and** an external web resource; the web link must load, be prominent, name the app and let the user request deletion without reinstalling; freezing is not deletion; complete the Data deletion questions in the Data safety form | In-app: Settings → Delete account (real backend deletion). External: `/delete-account.html` with verified email-code ownership and the same backend action (§10). Retention disclosed in the policy |
| User Data policy | https://support.google.com/googleplay/android-developer/answer/10144311 | Delete associated user data on request; disclose lawful retention; privacy policy must be in the app and linked in Play Console | `docs/privacy/DATA_INVENTORY.md` §6; policy page; retention rows pending owner |
| Data safety | https://support.google.com/googleplay/android-developer/answer/10787469 | Declare collection, sharing, encryption in transit and deletion; must match the app **and its SDKs** | Declaration table in §4; ML Kit SDK metrics disclosed |
| Health apps declaration | https://support.google.com/googleplay/android-developer/answer/14738291 | Every app, including closed testing, must complete the declaration; "Activity and Fitness" covers apps that monitor and record physical activities, exercise routines and workouts | Declared in §5 with the exact justification and the limits |
| Content rating | https://support.google.com/googleplay/android-developer/answer/9859655 | IARC questionnaire, target audience and ads declarations are required before publishing | Answers in §3; the owner submits the questionnaire |
| Preview assets | https://support.google.com/googleplay/android-developer/answer/9866151 | Icon 512×512 32-bit PNG with alpha ≤ 1 MB; feature graphic 1024×500 JPEG/24-bit PNG without alpha; at least 2 screenshots, min 320 px, max 3840 px, longest side ≤ 2× shortest, JPEG/24-bit PNG without alpha; 4+ at 1080×1920 recommended | §7; assets generated from the project's own mark |
| Closed-test requirement | https://support.google.com/googleplay/android-developer/answer/14151465 | Personal developer accounts created after 2023-11-13 generally need 12 testers for 14 continuous days before production access | Account-level owner action; recorded as a dependency |

Not checked here (owner-only surfaces): the actual Play Console forms, the
IARC result, account verification and the testing-track state.

## 2. Listing copy

Name: **Training Arena** (as on the launcher; no keyword padding).

**Variant A — closed-test listing for the current camera-off artifact** (this
is the only variant that matches what a tester can actually do today):

- Short description (64 characters, limit 80):
  `Challenge a friend to a live 60-second push-up or squat battle.`
- Full description:

  > Training Arena turns a challenge link into a live 1v1 round. Send a friend
  > a link, they install the app and accept, and the two of you prepare for the
  > same 60-second push-up or squat round.
  >
  > This closed-test build includes:
  > • Sign-in with an email code
  > • Challenge links — no friend search and no code typing
  > • A request inbox with accept, decline and expiry
  > • Profiles, blocked players and reporting
  > • Confirmed match history
  >
  > Camera rep counting and ranked matchmaking are not enabled in this
  > closed-test build. They are being validated before release, and the app
  > never claims a result the server did not confirm.
  >
  > Camera frames stay on your phone. If camera counting is enabled in your
  > build, the pose analysis runs on the device and only the rep count reaches
  > the match score. There are no bots and no offline scored challenges.

**Variant B — release listing, only after L04 signs camera counting and the
media review closes (R1/R13)**:

- Short description (68 characters):
  `Camera-counted 60-second push-up and squat battles with a friend.`
- Full description: variant A's structure plus the camera round, ranked
  ladder, and result sharing, with the same "no bots, server-confirmed
  results, frames stay on the device" statements. Do not use this variant
  while `ARENA_FEATURE_CAMERA_COUNTING=false` ships.

Category: **Health & Fitness** (the honest primary category for an exercise
product); tags to review in Console (for example "Competitive", "Phone").
Contact details, website and the two policy URLs are owner inputs (§9).

### 2.1 Keyword pass (2026-09-23, C06)

Target terms come from how this category is searched, not from stuffing. The
market leader's own listing misses several of these
(`docs/research/COMPETITIVE_ANALYSIS.md` §2), so they are available.

| Term | Where it appears | Source | Truth constraint |
| --- | --- | --- | --- |
| push-up / squat | short + full description | both movements are supported | must not imply camera counting in variant A |
| challenge / friend | short + full | core mechanic | true |
| 60-second / live | short + full | fixed round length | true |
| rep counting / counter | full description | category search term | variant A states it is not enabled in the closed test; variant B may claim it |
| home workout / no equipment | full description | category language | true (bodyweight only) |
| training partner / workout with friends | full description | core mechanic | true |
| leaderboard / ranked | variant B only | gated feature | only when the flags ship enabled |

Rules: no term appears unless the shipped artifact supports it; nothing is
repeated to game ranking; the short description stays under 80 characters.

### 2.2 Forbidden-claims checklist (apply before submitting any variant)

- [ ] No accuracy percentage, "accurate", "cheat-proof" or "verified by AI".
- [ ] No "guaranteed", "best", "#1", "millions of users" or unearned social proof.
- [ ] No medical, health, injury or transformation claim.
- [ ] No feature claim for anything disabled in the artifact (record the `ARENA_FEATURE_*` state from §0 first).
- [ ] No review, rating or testimonial that did not happen.
- [ ] Camera and privacy sentences match `docs/privacy/DATA_INVENTORY.md`.

### 2.3 Conditional additions

- **Solo set** (only when `ARENA_FEATURE_SOLO_MODE=true` in the pilot build):
  add to the full description — "A solo max-reps set with a daily goal and
  streak, kept on your device; solo sets never affect rating." Do not add it
  while the flag is false in the shipped artifact.
- **Name** (decision 12, D-B): the listing keeps "Training Arena". The "Arena"
  name collision is recorded; any rename happens before this copy is
  submitted, never after.

### 2.4 Follow-up list (documents carrying older scope)

- `docs/release/PILOT_PLAN.md` and `docs/release/CONFIGURATION.md` describe the
  camera-off pilot; re-check both if camera counting or solo mode flips.
- `docs/social/ACCOUNTS.md` bio copy predates the solo feature; update before
  publishing content that mentions it.

## 3. Target audience, content rating and ads

| Declaration | Value | Notes |
| --- | --- | --- |
| Target audience | **Adults (18+)** — owner to confirm; not designed for children | Avoids Families policy; if the owner later targets 13–17, the Families requirements must be re-checked |
| Ads | **No ads** | No ad SDK, no advertising ID, no ad code in the artifact |
| In-app purchases | **No** | No billing code |
| Content rating | IARC questionnaire, category closest to Health & Fitness; no violence, no sexual content, no profanity, no gambling, no drugs, no location sharing, no digital purchases; **yes** to user interaction (usernames and optional avatars are visible to other players, with block/report and manual review) | The rating itself is issued by the authorities; do not pre-state a rating as if granted |
| Government app / news / financial features | No | — |

## 4. Data Safety declaration

Matches `docs/privacy/DATA_INVENTORY.md` and the shipped artifact. "Shared"
means transferred to a third party for its own use; displaying data to other
players is not sharing. All transfers use HTTPS/TLS.

| Data type | Collected | Shared | Optional | Purpose | Deletion |
| --- | --- | --- | --- | --- | --- |
| Email address | Yes | No | No (account identity) | Account management, app functionality (sign-in code) | Yes |
| Name (username) | Yes | No | No (required to battle) | App functionality; shown to other players and on the leaderboard | Yes |
| User IDs (account id) | Yes | No | No | App functionality, account management | Yes |
| Photos (avatar) | Yes | No | Yes | App functionality; public profile content, removable in the app | Yes |
| Health and fitness → Fitness info (exercise type, rep counts, confirmed result) | Yes | No | No | App functionality (the match itself) | Yes; counterpart history retained as disclosed |
| App activity → App interactions (matches, requests, limited analytics events) | Yes | No | No | App functionality, analytics | Yes; analytics rows keep no user id after deletion |
| App info and performance → Diagnostics (ML Kit operational metrics) | Yes, by the bundled ML Kit SDK | No | No | SDK diagnostics and performance; the pilot build ships with camera counting off, but the SDK is packaged, so it is declared | SDK-managed |
| Device or other IDs (FCM push token) | **Not in the pilot** (push off); declared only when a push-enabled build ships | No | Yes | Notifications, when enabled | Yes |
| Location, contacts, messages, financial info, browsing history, health records | No | — | — | — | — |

Also required in the form: data encrypted in transit — **yes**; users can
request deletion — **yes**, in-app and at the web resource; a way to request
that *other* data is deleted — the same verified route covers the account and
its data, with the retention disclosure above.

## 5. Health apps declaration

Declare **Activity and Fitness**. It applies because the product records a
physical exercise activity: the exercise type, the counted reps and the
confirmed result of a workout round are stored per player. This matches the
official description "apps that monitor and record physical activities,
exercise routines, and workouts".

The declaration must also state the limits, all true for this product:

- No medical device, no diagnosis, no treatment, no cure claims.
- No vital signs (no heart rate), no body composition, no weight, no sleep.
- No Health Connect permissions or data types; the manifest requests `CAMERA`
  and `POST_NOTIFICATIONS` only (plus `INTERNET`).
- The camera feed is processed on the device; only rep counts are stored.
- The app is not a substitute for professional advice, and it says so in the
  listing and policy copy — without inventing a medical disclaimer the owner
  has not approved (the exact wording is an owner/legal input).

## 6. Reporting, blocking and support for usernames/avatars

Audit of what actually ships:

| Control | Where | Verified |
| --- | --- | --- |
| Username rules | 3–20 chars, letters/digits/underscore, reserved names rejected, unique (case-insensitive), server-validated | `arena_update_profile`, `arena_profiles` constraints |
| Avatar rules | Optional, JPEG/PNG/WebP, ≤ 2 MB bucket limit, uploaded through the server function, removable | `avatar.ts`, `arena_set_avatar`, `arena_clear_avatar` |
| Report a player | Public player card → Report (reason 3–500 chars, stored with match id) | `arena_report`, `arena_reports` |
| Block a player | Public player card → Block; blocked players cannot request or pair; unblock in Settings | `arena_block`, `arena_blocked`, `settings_page.dart` |
| Review process | Manual review by the operator from the support mailbox; the app never auto-enforces from a report | `arena_reports` comment, support page |
| Support route | `/support.html` and the support email; the page tells users never to send a password or a sign-in code | `challenge-web/support.html` |

Gap to keep visible: there is no in-app moderation console. Moderation is a
documented manual process (support mailbox + database review with the service
role). If the owner wants an in-app queue, that is new work, not part of this
packet.

## 7. Store assets

| Asset | File | Spec | SHA-256 |
| --- | --- | --- | --- |
| App icon | `design/arena/store/icon-512.png` | 512×512, 32-bit PNG with alpha, 32 295 bytes | `872ec303adca12cbd7c97903e9976499778804cabd005d7eb6dda49a701d1a0f` |
| Feature graphic | `design/arena/store/feature-graphic-1024x500.png` | 1024×500, 24-bit PNG without alpha, 39 559 bytes | `f78e2713ea851c2eb05b1d758ecd8d49a0633ccd9f11193c575ffbef4e459eec` |
| Screenshots | `qa/integration/screens/l07_*.png` (gitignored) | 1080×1920 (9:16), 24-bit PNG without alpha, captured from the real build | `qa/launch/l07/SCREENSHOTS.md` |
| Preview video | none | optional | — |

Both graphics are generated deterministically from the project's own mark and
fonts by `python tools/store/build_store_assets.py`; the script asserts the
Play dimension/alpha limits. Alt text for Play:

- Icon: "Training Arena app icon: a lime rounded square with a dark letter A."
- Feature graphic: "Training Arena: the lime arena mark beside the words
  Training Arena and the line '60-second push-up and squat battles'."

Screenshot rules followed at capture: only the app UI, no device frames, no
added text beyond the app's own, no personal data, no service-provider names,
full status-bar icons, no alpha, 9:16 at 1080×1920.

## 8. Reviewer access (without weakening authentication)

The app has no password: sign-in is an email one-time code, and a battle needs
two synchronized accounts. Reviewer access is designed as a documented,
consenting session:

1. **Owner creates a dedicated reviewer mailbox** (for example
   `reviewer@<owner-domain>`, or a monitored mailbox with an app password).
   The reviewer account's email is that mailbox. Credentials live only in the
   Play Console "App access" instructions — never in this repository, never in
   CI, never in the app.
2. **App access instructions (template for Play Console):**
   - "Training Arena has no password. Sign in with the email address below and
     the six-digit code sent to that mailbox."
   - mailbox address + mailbox credentials, marked "test account for review".
   - Step-by-step: open the app → Continue with email → enter the reviewer
     address → read the code in the mailbox → enter it. Google sign-in is out
     of scope in this build.
   - "To see a battle, use the second account below on a second device (or the
     same device after signing out), send the challenge link from one account
     and open it in the other. Both players tap ready; the round needs camera
     counting, which is not enabled in this closed-test build, so reviewers
     can see everything up to the preparation screens." — update this sentence
     only when L04 signs camera counting.
3. **Scripted two-account session (consenting testers):** the owner runs two
   accounts on two devices or emulators using the documented support script in
   `PILOT_PLAN.md` §4, and may record it for the reviewer. The video must show
   the real build; the app's own analytics already record only the allowlisted
   events, so nothing extra is needed.
4. **No auth weakening:** no bypass code, no test mode, no anonymous sign-in
   (disabled), no shared session token, no service-role access for reviewers.
   The reviewer accounts are ordinary accounts the owner can delete afterwards.

## 9. Pending owner inputs

| Input | Needed for | Status |
| --- | --- | --- |
| Legal entity name and postal address | Privacy policy identity, Play developer identity | **missing** |
| Privacy contact email | Privacy policy, data requests | **missing** |
| Support address + response commitment | Support page, store listing support contact, Data safety | **missing** |
| Retention periods (matches, telemetry, backups, moderation) | Privacy policy, Data safety deletion answers | **missing** |
| Hosting destination (D1) and deployment of the public pages | Live privacy/support/deletion URLs in Play Console | **missing** (L05 blocked) |
| Play Console access (account, package registration, tracks) | All form declarations and the upload | **missing** |
| Release signing (R9) | Uploadable AAB | **missing** |
| Camera/media decision (L04 R1/R7/R13) | Whether variant A or B ships | **pending** |
| Google OAuth values (R3) | Google sign-in claim in the listing | **missing**; listing copy avoids it |
| Play app-signing certificate SHA-256 | `assetlinks.json`, App Links | **missing** |

## 10. Deployment and submission steps (owner-executed)

1. Supply the §9 inputs; L05 deploys the Supabase project, the landing and the
   public pages on the same host.
2. Fill `challenge-web/config.js` (apiBase, anon key, host, legal entity,
   contacts, retention values) and run the release gate:
   `node challenge-web/scripts/check.mjs --release` — it fails while any owner
   value is missing, so an unfinished policy cannot be published.
3. Deploy the folder as static files with `/c/*` rewritten to `index.html`;
   verify `https://<host>/privacy.html`, `/support.html`, `/delete-account.html`
   load and that the deletion page verifies a real account end to end.
4. Enter the privacy policy URL and the deletion URL in Play Console → App
   content → Data safety; complete the Data deletion questions.
5. Complete the Health apps declaration (§5), target audience and content
   rating (§3) and the ads declaration.
6. Upload the signed AAB (R9) to the chosen track, add the listing copy that
   matches the shipped flags (§2) and the assets (§7), and add the reviewer
   access instructions (§8).
7. Run the store-listing preview and fix every reported issue before
   submitting for review.

## 11. What is not in this packet

- No Play Console entry was created or edited, and no declaration was
  submitted.
- No signed artifact exists to upload (R9).
- No medical, legal or accuracy claim; no fabricated reviews, ratings or
  testimonials anywhere in the copy.
- The screenshots are captured from the non-distributable release-equivalent
  smoke build; they show the real UI with the pilot flags. They must be
  recaptured from the signed release candidate if the UI changes before
  submission.
