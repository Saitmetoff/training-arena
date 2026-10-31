# Training Arena social identity packet

Prepared: 2026-09-21 · Branch: `codex/training-arena` · Prepared by: L09
(OpenCode, `opencode-go/deepseek-v4.1-flash`).

Status: **NO ACCOUNT EXISTS. Account creation is BLOCKED.** Nothing was
registered, reserved, renamed or published. An account is claimed only when its
logged-in project profile is visible; until then every row is "not created".

Two independent blockers:

1. **Owner inputs absent** (§2): account email, password (owner-created), real
   date of birth, final handle, language/country, MFA/recovery ownership and
   brand-art acceptance.
2. **No browser tool in this executor session.** Registration requires an
   interactive browser with the owner entering the password/OTP and confirming
   terms/CAPTCHA at action time. HTTP fetch probes cannot check handle
   availability; transcript: `qa/launch/l09/handle_probe.txt`.

## 1. Truth constraints on these profiles

The profile copy and link only claim what the shipped artifact can do. Camera
counting is **off** (L04 unsigned), ranked matchmaking is **off** (refusal path
only), push is **off**, and the only enterable destination today is the invited
pilot. Therefore:

- no "download now", no counted-battle promise, no accuracy or health claim;
- no link until a working destination exists (§5); a placeholder host,
  `example.invalid` or a non-public APK is not a destination;
- likes, views and share sheets are never described as sign-ups or battles;
- all copy below is an English draft; the owner's language/country is pending.

## 2. Required owner inputs (all missing)

| Input | Needed for | Status |
| --- | --- | --- |
| Dedicated project email (not the personal one) | registration, recovery | **missing** |
| Password, created by the owner in the browser | both accounts | **missing** — never entered in this repo or chat |
| Real date of birth (18+) | both registrations | **missing** — never invented |
| Final handle + language/country | both profiles | **missing**; candidates §3 |
| MFA method + recovery email/phone under owner control | both accounts | **missing** |
| Brand-art acceptance (D4) | avatar upload | **pending**; provisional mark §4 |
| Destination choice (§5) | bio link | **blocked** |

## 3. Handle candidates (availability NOT VERIFIED)

| Order | Handle | TikTok | Instagram | Notes |
| --- | --- | --- | --- | --- |
| 1 | `@trainingarena` | NOT VERIFIED | NOT VERIFIED | first choice |
| 2 | `@playtrainingarena` | NOT VERIFIED | NOT VERIFIED | fallback |
| 3 | `@trainingarena.app` | NOT VERIFIED | NOT VERIFIED | reserve fallback |

All candidates fit the platforms' handle limits (TikTok 24, Instagram 30).
Authoritative check: the handle field during signup (it validates live; a taken
handle is refused) plus the signed-out profile URL in a real browser. Record
the result per candidate at registration time. Do not invent availability.

"Training Arena" is a generic phrase; any trademark/confusion concern is an
owner decision recorded at signup, not asserted here.

## 4. Brand mark (existing project art, used provisionally)

| Asset | Value |
| --- | --- |
| `design/arena/arena-mark-1024.png` | 1024×1024 RGBA, 39 078 B, SHA-256 `c99b62bbd3619bdf7cd7b22e7caaf8e149d037dd7aeacc530699a00fb437bd04` |
| `design/arena/arena-mark.svg` | vector master, SHA-256 `d7818b98682e3360a6266d3ba41faa076b159a4cb1034e3e1e2d19525a07ead7` |
| `design/arena/arena-mark-mono.svg` | mono master for small sizes |

Upload the 1024 PNG, then check it as the platform's circular crop at small
size (TikTok/Instagram avatars render around 48 px). No new art was generated
in L09 and no third-party asset is involved. Owner art acceptance (D4) is the
condition the launch plan sets before even provisional use, and it is still
pending — do not upload the mark until the owner accepts it.

## 5. Link destination (profile link field)

| Option | State | Requirement |
| --- | --- | --- |
| Play internal-testing opt-in link | **BLOCKED** | Play track + listing evidenced; the owner reports an account but no track, listing or tester roster is evidenced |
| Hosted beta page (`challenge-web/`) | **BLOCKED** | real host (D1) + L05 deployment; `node challenge-web/scripts/check.mjs --release` must pass |
| No link, copy only | available today | honest; CTA limited to "follow for beta updates" |

Platform capability note: both platforms allow a website field, but the exact
behaviour (clickability, professional/business account requirements) must be
verified in the app at setup — do not assume. Instagram link features may need
a professional account; the related owner decision (music library access) is
recorded in `CONTENT_EXPERIMENT.md` §3.

## 6. Registration runbook (owner or browser-enabled session)

Preconditions: §2 inputs supplied; a clean browser context (new profile or
private window). **Do not use the signed-in personal Instagram session** — the
previously observed signup redirected to the personal account and the
switch-account flow only offered existing-account login.

1. Open the platform's signup in the clean context; choose email signup, not
   phone, when offered.
2. Owner enters the project email and completes the emailed code.
3. Owner creates the password and stores it in the owner's password manager.
   It never appears in this repository, chat, CI or a screenshot.
4. Owner enters the real date of birth (platform rule; 18+ product audience).
5. Try §3 handles in order; accept the platform's live validation result.
6. Owner confirms the terms/CAPTCHA at action time — required by the browser
   tool's confirmation policy; do not pre-confirm or automate it.
7. Set the avatar (§4, only after D4 acceptance) and the bio (§7); set the
   link only per §5.
8. Enable MFA and store recovery codes (§8).
9. Evidence: screenshot of the **logged-in project profile** with the handle
   visible into `qa/launch/l09/`, and the profile URL into §9.

Platform specifics:

- **TikTok**: a previous inspection stalled at the email/phone link step; retry
  in a fresh context. Decide personal vs business account **before** publishing
  music-bearing edits: a business account unlocks the Commercial Music Library
  (music rights), with some UI/tool differences.
- **Instagram**: email + a new handle; never log in with the personal account;
  confirm the visible profile is the project handle before any activity.

## 7. Bio variants (drafts; owner approval required before use)

| Variant | Text | Chars | When it may be used |
| --- | --- | --- | --- |
| B1 (current, truthful) | `Challenge a friend. 60-second push-up & squat battles. Invite-only beta.` | 72 | now |
| B2 (public beta) | `Challenge a friend. 60-second push-up & squat battles. Free Android beta.` + link | 73 | only after §5(a)/(b) works **and** L04 signs camera counting for the shipped build |
| B0 (launch-plan original) | `Challenge a friend. 60-second push-up & squat battles. Android beta.` | 68 | the launch-plan draft; true today only because the invited pilot is the beta — B1 states that explicitly |

TikTok bio limit is 80 characters; Instagram is 150. B1 is the only variant
that is fully true today. Do not add claim lines ("accurate counting", "no
cheating", "burn calories") to any variant. Translations follow the owner's
language choice.

## 8. Recovery and MFA checklist (owner-controlled, no secrets in this repo)

- [ ] MFA enabled with an authenticator app where offered (both platforms
      offer it; TikTok also offers SMS/email).
- [ ] Recovery/backup codes stored in the owner's password manager.
- [ ] Recovery email is the owner-controlled project email; recovery phone,
      if used, is owner-controlled.
- [ ] Device/session list reviewed; unknown sessions removed.
- [ ] Password, codes and tokens never written to this repository, CI, chat or
      screenshots; profile screenshots must not show the email/phone.

L09 cannot verify account state without access; owner confirmation plus a
visible "two-step verification on" screenshot is the accepted evidence and is
recorded as PENDING(owner) until it exists.

## 9. Status and profile URLs

| Platform | Handle | Profile URL | Account state | Evidence |
| --- | --- | --- | --- | --- |
| TikTok | not chosen | — | **NOT CREATED** | — |
| Instagram | not chosen | — | **NOT CREATED** | — |

No profile URL exists to return. This table gains a URL only when the
logged-in project profile is visible and its screenshot is stored in
`qa/launch/l09/`.
