# Fault — Stage 4 polish handoff

4 October 2026. **Poster-based polish complete; real media release and live waitlist acceptance remain open.** No later design selection exists, so this continues the Stage 2 provisional **Performance editorial** direction. The owner explicitly confirmed that no new media exists and approved the poster fallback. The $30,000 figure remains a quality standard, not spending authorization.

## Review links

- Updated [protected Vercel preview](https://fault-website-kp46cuvk8-priler003-7576s-projects.vercel.app), deployment `dpl_24yPCSCw9bgBmq1wka1ge7YY8Kju`. CLI inspect verified **Ready / preview**, rather than relying on the asynchronous deploy message. Vercel authentication remains enabled; no production promotion or domain/DNS change occurred.
- [Local interactive review](http://127.0.0.1:3000/) while the loopback development server is running. Local delivery is explicitly labelled simulated.
- [Desktop screenshot](../../design/fault-website/stage4-desktop.png), [390px phone](../../design/fault-website/stage4-mobile.png), [320px phone](../../design/fault-website/stage4-320.png), [tablet](../../design/fault-website/stage4-tablet.png), [phone sequence detail](../../design/fault-website/stage4-mobile-sequence.png), [reduced motion](../../design/fault-website/stage4-reduced-motion.png).
- [Social preview](../../design/fault-website/stage4-social.png), [poster failure](../../design/fault-website/stage4-poster-failure.png), [synthetic media loading](../../design/fault-website/stage4-media-loading.png), [form retry state](../../design/fault-website/stage4-form-error.png), [local confirmed state](../../design/fault-website/stage4-confirmed.png).

Screenshots are browser evidence, not product footage. Desktop/phone dimensions refer to window viewports; this browser reserves a 15px scrollbar, so screenshot content widths can be 1425/375px at 1440/390px. Full-page images are intentionally tall.

## Final composition and truthful copy

The first render exposes **“Give your next set a reason.”**, the literal manual-entry subline and **“Join the waitlist”** immediately. The wordmark, local Inter weights, charcoal canvas, lime action and editorial rules continue the recorded direction. Benefits flow from completing the set to entering a count, saving it and reviewing history. Ten native FAQ disclosures cover current solo scope, camera status, battles, accounts, storage, platforms, equipment, launch, pricing and camera data. Closing copy is **“Make room for your next set.”** Form feedback explicitly requires email confirmation and says that joining does not give app access.

`fault-web/src/components/Narrative.tsx` retains the source-backed Stage 1 boundaries: solo push-ups are manually entered and self-reported; history is device-local; Android first is preparation, not a published supported-device list; camera counting and completed battles remain under test; no public launch date or iPhone/browser-gameplay release is announced. The 30,000 figure is an audience goal, never a current count or promised growth rate. No historical emulator battle fixture, invented phone screen, rep result, athlete or testimonial was used as hero proof. Exact product evidence remains in `docs/fault-website/01-brief.md`, including `qa/camera/beta_device_results.json` and `docs/release/PILOT_PLAN.md`.

`fault-web/src/lib/metadata.ts` and `src/app/layout.tsx` provide the approved title/description, canonical URL for the current environment, website Open Graph image and Twitter large card. `public/icon.svg` is a Fault F favicon; the native app identity is untouched. `src/app/social-preview.png/route.tsx` renders a 1200×630 charcoal/lime card using the actual local Inter Black font. Preview robots remain noindex/nofollow. Operator identity, public support address and final privacy/retention terms still require real owner information before public collection; development pages disclose that hold.

## Signature motion and implementation paths

The signature is a deliberate four-step **From effort to record** sequence: **Set → Enter → Save → Review**. Selecting a step changes its media frame and the persistent written caption. With real approved media, the intended link is one actual push-up effort, its manual entry, successful save and history on the same build/device. Today all four frames are explicitly illustrative posters. This interaction demonstrates the narrative and controls; it does not prove working camera counting, a completed battle or even a captured current solo app session.

| Behavior | Desktop, ≥1100px | Phone/tablet | Reduced motion |
| --- | --- | --- | --- |
| Step transition | 400ms standard easing, opacity and 24px horizontal offset | 150ms opacity, no offset | Instant cut; no translation |
| First render | First frame visible; no entrance gate | Same | Same |
| Process entrance | Once on intersection: 250ms, 12px offset, 50ms stagger | Same restrained enhancement | No entrance animation |
| Button feedback | 150ms; signup press moves 1px vertically | Same; 48px minimum targets | Press transform omitted, selection remains visible |
| Scroll | Native scrolling, no pinning or hijacking | Same | Same |

`fault-web/src/lib/motion-tokens.json` holds named W3C DTCG tokens matching the existing CSS durations: short-3 150ms, medium-1 250ms, medium-4 400ms, standard `(0.2,0,0,1)`, entering `(0.05,0.7,0.1,1)`, small stagger 50ms. `src/lib/motion.ts` supplies React values. Existing Motion is retained; no second animation library was added. There are no animated live-timer digits, count interpolation, continuous decoration or autoplay.

- `src/components/ProductSequence.tsx`: four semantic buttons with aria-pressed, captions outside the changing frame, outgoing frame hidden from accessibility, stable frame geometry and a full written demonstration plan. At 320px controls form a two-by-two grid; at 390px all four remain in one row. Keyboard selection keeps focus on the control and does not force scrolling.
- `src/app/product-sequence.css`: 3:4 desktop frame and 4:3 phone/tablet frame; centered desktop posters and deliberate 38% vertical phone crop. Missing-media/self-reported labels also sit outside image pixels. Future app captures must use the manifest crop positions after actual review; video uses contain to preserve evidence.
- `src/components/SectionMotion.tsx`: progressive enhancement leaves all text visible before JS; observer disconnects and animations cancel on cleanup; repeated scrolling does not replay entrances. A preference change cancels active animation and prevents later entrances.
- `src/components/DemoPlayer.tsx`: native controls, playsinline, preload none, no autoplay; loading feedback, failure callback and playback pause on inactive frame/unmount. `demo_play` occurs on actual playing, once per mounted player, not on poster selection. No demo_play event was claimed in this stage because no video exists.
- `src/app/polish.css`: additive responsive corrections, fluid desktop headline, non-overflowing grids, benefit spacing, immediate focus and readable form states. Existing global CSS was preserved.
- `src/components/SignupForm.tsx` and `ShareButton.tsx`: busy guards, visible sending/pending/retry/shared feedback, consent unchanged and one active form announcer. Signup motion now uses the shared tokens. Explicit tabIndex fixes the reduced-motion SSR hydration mismatch. Share URLs omit current query/hash; dismissal is quiet.
- `src/lib/captions.ts`: reusable WebVTT formatting with ordered finite timing, single rounding with carry, escaped payload and rejection of overlap, arrow injection, empty payload or cues collapsing below a millisecond. No final caption file was invented without footage.

## Final assets and exact outstanding shots

`fault-web/src/lib/demo-media.json` is the approval manifest: approved is false; build, device, rights and evidenceTake are null; every source is null. A filename alone cannot enable product evidence. Add verified metadata and sources only after capture acceptance.

| Present asset | Location | Format/size | Role |
| --- | --- | --- | --- |
| Four editable poster sources | `fault-web/public/media/solo/{set,enter,save,review}.svg` | 780×1040 SVG | Typographic placeholders only |
| Four optimized posters | Same basenames, `.webp` | 780×1040; 9,402 / 11,626 / 10,998 / 11,606 bytes | About 43.6KB total, no fictitious screenshots |
| Reproducible poster export | `fault-web/scripts/build-posters.mjs` | Node, existing Sharp and Next ImageResponse | WebP export embeds actual local Inter; editable SVG uses Inter with fallback |
| Wordmark and local fonts | `fault-web/public/fault-wordmark.svg` and `fault-web/src/app/fonts/` | SVG/local TTF | Existing direction retained |
| Website favicon | `fault-web/public/icon.svg` | SVG | Fault F, charcoal/lime |
| Social card | `fault-web/src/app/social-preview.png/route.tsx`; exported review image above | 1200×630 PNG, hosted response 49,897 bytes | Honest development headline, solo/manual scope |
| Current movement/app media | **Absent** | No MP4, current solo captures or final VTT | Real release hold |

Record these matching shots, preferably in one documented continuous session:

1. **Set:** 10–15 seconds of actual solo push-ups, full body and complete movement visible. No automatic-count overlay. Record who appears, their permission, device/build and the take ID.
2. **Enter:** 4–6 seconds of the current Android manual-entry UI, entering the actual count from that same take. Keep the self-reported distinction legible; no reconstructed UI.
3. **Save:** 3–5 seconds of the same build completing a successful save, with the actual resulting state. Capture enough context to link entry to save.
4. **Review:** 4–6 seconds of saved history and the real personal-best context on that phone. Do not seed illustrative impressive results or imply a lifetime/all-device record.
5. Supply a portrait movement master and clean full-resolution app captures, then choose desktop/mobile crops without cutting off the body, count source or save evidence. Produce posters from actual accepted frames, timed English VTT and a complete readable transcript. Remove personal data from screen captures.

The current poster fallback is fully understandable without movement or sound. Final footage, current capture consistency, real video load/playback/caption timing and rights acceptance are still required before calling this a finished media release. Lime remains player/action; no opponent is displayed, so violet is not repurposed.

## Verification and limits

Evidence index: `fault-web/test-results/stage4-review.json`, `stage4-local-flow.json`, `stage4-preview.html`, `stage4-preview.headers`, `stage4-social.headers`, `stage4-qa.headers`, `stage4-waitlist.json` and `stage4-waitlist.headers`. These files are local verification output; `.vercelignore` excludes tests, scripts, test-results, local spools and environment files from upload.

| Check | Result and scope |
| --- | --- |
| TypeScript / production build | Passed. Landing content remains pre-rendered with small interaction islands. |
| Regression suite | **31 passed, 0 failed**. Includes metadata/VTT edges and fresh PostgreSQL-backed signup, duplicate, retry, token, attribution, unsubscribe, suppression, signature, RLS and rate-limit cases. |
| Responsive review | 320, 375, 390, 414, 768, 1366 and 1440px: no horizontal overflow; sequence and primary action targets ≥48px. Screenshots for the four requested size classes reviewed visually. |
| Keyboard / pointer / reflow | Keyboard signup, sequence activation, FAQ disclosure and confirm/unsubscribe passed. Low-level pointer activation changed the step at phone size. Synthetic 200% text enlargement at 768px yielded no horizontal overflow or clipped CTA/sequence buttons. No physical touch-device or browser zoom certification is claimed; phone emulation reported zero native touch points. |
| Motion / cleanup | Eight rapid step changes settled to one frame; repeat scrolling left zero running animations. Reduced-motion phone review also had one frame and zero running animations. Fresh reduced-motion reload showed no hydration mismatch after the button fix. Actual-device FPS/battery measurements were not performed. |
| Failed / slow media | Forced missing poster URL produced actual image failure and a readable fallback while CTA stayed usable. Local-only `src/app/qa-media/` harness exercised synthetic waiting, canplay, error and retry: loading message appeared, canplay cleared it, error produced written fallback. This is component-state evidence, not genuine video-network/playback evidence. Hosted harness returned 404. |
| Form feedback | A local fetch mock delayed and rejected signup: aria-busy/loading then visible Try again state. Mock restored by reload. Normal form reached pending via native keyboard submission. |
| Local signup lifecycle | Registered development campaign produced **1 landing_view, 1 waitlist_submit, 1 waitlist_confirmed** for the latest cohort; creative `fault-dev-test-a` survived separate-session confirmation; anonymous identity matched; analytics contained no raw email or token. Unsubscribe succeeded. The authoritative local public count remained **0**, because this browser cohort is marked internalTest and excluded throughout. The fresh-schema cases in `fault-web/tests/flow.test.ts` separately prove eligible synthetic rows change the count **0 → 1 → 0** through pending, confirmation and unsubscribe. Used token replay was rejected. All delivery/analytics spools are simulated. |
| Hosted preview | Ready / preview. Authenticated page and social image 200; local harness 404. Matching-origin signup request 503 configuration_required; missing Origin request 403. This is the intended closed development state, not a hosted signup success. |
| Existing app surfaces | No tracked changes to `lib/`, `android/` or `challenge-web/`; unrelated existing social-document changes preserved. |

Hallmark review judgment: purpose 5, hierarchy 5, emotion 4, structure 4, readability 5, variety 4. This is Codex's design assessment, not measured audience evidence. The approved Inter identity and editorial structure take precedence over inventing a fresh palette/font theme. Missing real imagery still materially limits the site's finished quality.

## OpenCode delegation

**04-polish — accepted with Codex integration repairs.** Codex fixed the signature contract first in `docs/fault-website/04-motion-contract.md`, then batched required CSS/responsive corrections, metadata/caption helpers and repetitive signup/share states. One initial coding assignment; no model substitution or correction run.

- Provider/model: **OpenCode Go / `opencode-go/deepseek-v4.1-flash`**, explicit coding-task CLI routing, build agent. Session **`ses_ef904daeeffeWADEbxm3mQUQ3z`**.
- Packet, baseline, report, event stream and usage: `tmp/fault-opencode/04-polish.task.md`, `04-polish.baseline.json`, `04-polish.report.md`, `04-polish.events.jsonl`, `04-polish.usage.json`. Before-edit component copies also remain local. No service secrets, private recipient, tokens or subscriber rows went into the task.
- Exact six-file ownership: `fault-web/src/app/polish.css`, `src/components/SignupForm.tsx`, `src/components/ShareButton.tsx`, `src/lib/metadata.ts`, `src/lib/captions.ts`, `tests/polish.test.ts`. Worker stayed within this set. Codex inspected the actual outputs against baseline and reviewed all visual/interaction results.
- Worker reported 30 passing cases and a Codex-owned DemoPlayer prop integration error. Codex supplied the final player interface, motion tokens, metadata wiring, favicon/social card and poster sequence. Codex additionally repaired caption rounding/empty-payload validation, social alt accuracy, native share success feedback, duplicate CSS press transform and the reduced-motion hydration warning. Added regression coverage produced the final **31/31** result and passing build/typecheck.
- Reported across 18 completed steps: input **43,492**, output **6,763**, reasoning **17,353**, cache read **902,400**, cache write **0** tokens. Provider-reported cost sum **$0.0237006**; not a verified bill or savings estimate. The cumulative total token field was not summed.

Current animation guidance came through Context7's Motion documentation: [AnimatePresence](https://motion.dev/docs/react-animate-presence) and [scroll animations](https://motion.dev/docs/react-scroll-animations); installed Next.js ImageResponse documentation was checked for the social asset. Design, hallmark, motion-design, scroll-animations, typography, sequencing, accessibility, motion-audit and React best-practices informed the work. No reusable video composition was needed, so Remotion/storyboarding packages and generated artwork were not introduced.

## Remaining release dependencies

1. **Real media:** the exact four shots, current build/device/take metadata, permissions, accepted crops and final captions above. The owner approved the temporary fallback; no missing-media approval is being asked again.
2. **Live signup infrastructure:** unchanged Stage 3 prerequisites—select the intended active Fault development Supabase project, apply the migration and configure server credentials; verify a Resend sender/domain and configure signed webhook, suppressions and retry dispatcher; supply the server-side PostHog ingestion key. The already-authorized test recipient is available. Outstanding check: actually deliver to that recipient, confirm once, inspect hosted attribution/events, unsubscribe and verify exclusion, then replay a signed provider event. No live email, DNS write or paid tier change was made here.
3. **Public collection readiness:** provide operator/support/retention facts and complete later release/load/accessibility review. The precise count stays unique confirmed, currently subscribed addresses excluding duplicates, abuse and known delivery suppressions; test fixtures never contribute to the public launch count.

The headline, narrative, poster interaction and verified release scope agree. Independent Stage 4 polish is reviewable now; the absent real media and hosted integration checks are explicit holds, not claimed successes.
