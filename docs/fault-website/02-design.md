# Fault — Stage 2 design handoff

4 October 2026. Local concepts; no production website, signup, service configuration or publication. Fault/fault.fit and the Stage 1 solo-first claims are retained. $30,000 is a quality standard, not spending authorization. Figma capabilities are not connected in this session; editable local HTML/CSS/SVG/JSON is the design source.

## Direction and shared evidence

**Provisional baseline: Performance editorial.** It gives the current solo experience the clearest hierarchy: motivation, literal explanation, email action, then a genuine product sequence. Strong type and real effort can make the narrow experience distinctive without borrowing unverified camera or competitive claims. This is an art-direction judgment, not a measured conversion result. The owner can select broadcast or lab without changing the shared content or future signup contract.

Exactly three concepts use the identical Stage 1 headline, subline, CTA, helper, consent, process and benefits. Headline: **Give your next set a reason.** Literal subline: **Fault is being built for solo push-up practice: enter your own rep count, save the set on your phone, and compare it with your previous sets. Android first.** CTA: **Join the waitlist**. This is still a development experience, not currently downloadable access.

Verified boundaries remain in [01-brief.md](./01-brief.md): solo is push-ups, manually entered/self-reported, signed-out and device-local. The camera device record remains blocked (`qa/camera/beta_device_results.json:2–8`); current camera-off scope cannot finish counted battles (`docs/release/PILOT_PLAN.md:17–31`). These designs introduce no broader scope. The supplied name supersedes legacy marketing naming; native identity is unchanged.

Current solo footage and screenshots are missing. Each hero reserves explicitly labeled media, and none invents athletes, screens, rep totals, testimonials or results. Every direction includes the same optional actual historical Android capture: `qa/integration/screens/l07_01_battle.png`, labeled 21 September 2026 emulator/camera-off/Training Arena/not current solo. It is a reference disclosure, not hero proof. `qa/launch/l07/SCREENSHOTS.md:3–18,37–40` identifies its limitations; `prototype/README.md:3–7` excludes fixtures as evidence.

## Reviewable concepts

Editable [gallery](../../design/fault-website/index.html). Serve repository root at localhost, then open `/design/fault-website/`. Gallery switches exact internal viewport widths 1440 and 390; direct pages provide ordinary scrolling and interaction. The review gallery needs JavaScript for frame sizing and direction switching; core editorial content is static HTML. Stage 3 must preserve pre-rendered core content.

Full-page browser previews:

| Direction | Wide desktop 1440px | Phone 390px |
| --- | --- | --- |
| Performance editorial | [Desktop](../../design/fault-website/previews/editorial-1440.png) | [Phone](../../design/fault-website/previews/editorial-390.png) |
| Competition broadcast | [Desktop](../../design/fault-website/previews/broadcast-1440.png) | [Phone](../../design/fault-website/previews/broadcast-390.png) |
| Camera lab | [Desktop](../../design/fault-website/previews/lab-1440.png) | [Phone](../../design/fault-website/previews/lab-390.png) |

The in-chat comparison uses browser-captured crops of these concepts, with three named variants and a desktop/phone switch. These are website concept previews, not product screenshots. Editable interaction and complete storyboards remain in the gallery. Inline source: `C:/Users/ADMIN/.codex/visualizations/2026/10/04/01a105ce-0460-7311-9ee2-533d98a64538/fault-directions.html`.

| Direction | Direct route | Composition / tradeoff |
| --- | --- | --- |
| Performance editorial | `concept.html?direction=editorial` | Asymmetric 7/5 split, left-aligned monumental type, form beside a tall effort recording area; next section reverses emphasis into a quiet record narrative. Best match for current honest solo promise. |
| Competition broadcast | `concept.html?direction=broadcast` | Centered title and signup above full-width set/record diptych; horizontal broadcast bands organize personal effort. Strong campaign energy, but can invite a mistaken battle inference. No opponent, violet, live badge, timer or scores. |
| Camera lab | `concept.html?direction=lab` | Compact 5/7 explanation/workbench split, framed demonstration with source annotations and a process table. Strong clarity, but measurement styling can overstate an unvalidated camera. All labels explicitly concern manual entry. |

The concepts are structurally different while preserving palette and content. They are scoped adaptations of Split Studio, Narrative Workflow and Workbench; fixed Fault identity and early signup take precedence over a generic theme recipe. No new type family, catalog palette, image generation or external media was needed.

## Proposed wordmark

`design/fault-website/fault-wordmark.svg` is Codex's proposed primary wordmark: solid geometric uppercase FAULT, a sharp triangular A counter, open F and robust U. It is authored vector lettering rather than live font text, so its proportions remain fixed. Soft-white lettering on charcoal; no diagonal speed marks, broken-body imagery or defect metaphor. Existing `design/arena/arena-mark.svg` remains an app reference, not a renamed Fault asset.

Use width144px desktop/112px phone, intrinsic ratio315:72, minimum112px for this wordmark-only lockup. Reserve at least half its cap-height around it (approximately16px desktop/13px phone); never stretch, recolor individual letters or use violet. A future dark-on-light inverse can change the whole fill to charcoal. This is a proposal awaiting owner selection, not a trademark clearance or a native app icon update. Mobile legibility and final screenshot review determine acceptance below.

## Implementation-ready baseline

Source contract: `design/fault-website/concept-spec.md`. Token source: `design/fault-website/tokens.json`; prototype consumer: `concepts.css`. Existing app tokens are unchanged. Three layers: primitive values → semantic roles → hero/form/media components.

| Role | Value / application |
| --- | --- |
| Canvas / raised surfaces | Charcoal `#17191A`; graphite `#242729`; raised `#303537`. Flat stepped surfaces; no glow, texture, gradient or shadow. |
| Ink / supporting text | Soft white `#F6F7F2`; secondary `#B6BDB9`; quiet `#9BA59E`. No essential copy in low-contrast decorative lines. |
| Action / identity | Lime `#D6FF3F` with charcoal ink for primary CTA/current-person identity. Violet `#BEA1FF` remains opponent-only and is unused in these solo heroes. |
| Boundaries / focus / error | Decorative line `#3B4245`; controls `#6F787A`; focus3px soft white/offset2px; error `#FF807C` with readable text. |
| Typography | Bundled Inter400–900. Editorial desktop104px/0.96/900/tracking−0.055em; phone58px/1/900. Broadcast96px desktop/48px phone. Lab72px/800 desktop/48px phone. Body18px/1.5 desktop,16px/1.5 phone; helper14px/1.45; labels≥12px. |
| Spacing / shape | 4,8,12,16,24,32,48,64,96px. Control radius14px; media20px (lab10px); min48px targets. No repeated card grid. |
| Grid | Max1312px inner content; desktop64px gutters at1440; phone24px at390 and16px at320. Hero columns begin at1100px; below that text/form precede media. At≤760px body type and broadcast diptych also switch to phone treatment. |

Original palette/type meanings: `design/arena/DESIGN_SYSTEM.md:23–29,35–54,66–90`; original spacing/focus/touch values: `design/arena/tokens.json:64–108`. Marketing enlargement and1312px width are explicit website additions, not changes to native app typography.

Editorial at1440: header wordmark/fault.fit separated by a neutral rule; hero64px top/bottom, columns7/5 with64px column gap,24px text/form gaps. Inner1312px divides into728px copy and520px media columns. H1 three composed lines, subline≤560px. Email input and lime button align horizontally at56px high; helper/consent/preview notice follow. Media520×693px (3:4) alongside, with source-aware caption. Next section presents “Do the set. Keep the record.” opposite three process beats; benefits are quiet rule-separated prose.

Editorial at390:342px content width, header24px padding, hero32px top. Three headline lines, subline24px below. Input full width48px then CTA52px with12px gap; helper, consent and preview notice follow. Media moves after the complete signup explanation with32px gap. The eventual footage uses4:3; the current text-heavy reserved slot has a300px minimum height to keep its missing-media labels readable. Next section48px later, heading40px; process and benefits stack. At320 use16px gutters and editorial headline49px. Keep email editable text≥16px to avoid mobile zoom.

Form/state contract: visible label, native email validation, readable hover/focus/press/disabled/loading/error feedback. Prototype completion explicitly says no signup was created; it stores/sends nothing. Production pending/confirmed/expired/retry states use Stage 1 flow copy in Stage 3. Privacy details is visibly a concept note, not a claim that a final policy exists. Signup remains available before video loads; media failures get the labeled poster/description rather than a blank area.

## Signature motion storyboards

All three are user-controlled editorial product stories, not product telemetry. Initial content and CTA appear immediately. No autoplay, looping, scroll hijack, countdown animation or digit interpolation. Timing follows the requested motion skill's Material3 baseline: standard cubic-bezier(0.2,0,0,1), micro150ms, source transition250–400ms. Tokens are local and reusable. Each prototype stage is explicitly a storyboard placeholder.

| Direction / key frame | Desktop transition / eventual source | Phone alternative | Reduced motion |
| --- | --- | --- | --- |
| Editorial A: Set | Initial effort frame, caption names real push-up take; hold until interaction. | Static4:3 frame/caption. | Same static frame. |
| Editorial B: Enter | Move crop≤140px over400ms/24frames at60fps toward actual manual-entry screen; caption150ms/9frames. No app-derived rep overlay. | Frame/caption crossfade150ms, no moving crop/pinning. | Immediate cut, no transform. |
| Editorial C: Save | Replace with actual successful persistence/history evidence using same400ms transition; hold. Never simulate Saved. |150ms frame change. |Immediate cut. |
| Editorial D: Return | Reveal real retained history/valid personal-best context, then settle. Replay only by user. |Stacked history capture; caption retained. |Static labeled history. |
| Broadcast A: Set | Real effort stays in left frame; right empty until authentic entry capture. |Two vertically stacked frames. |Same stack. |
| Broadcast B: Enter | Neutral wipe crosses diptych350ms/21frames; actual manual-entry capture replaces right; caption150ms. |150ms opacity change, no wipe. |Instant replacement. |
| Broadcast C: Saved history | Actual record replaces right; left effort remains. No opponent/result or score animation. |Static effort above changed record. |Instant change. |
| Lab A: Set | Initial real demonstration, neutral source underline at Set. |One frame and wrapped stage buttons. |Static label/frame. |
| Lab B: Manual entry | Neutral annotation underline moves250ms/15frames to genuine source/action region; caption names self-report. |Underline changes with frame, no overlay leader. |Instant selected state. |
| Lab C: Local history | Actual saved history replaces frame; underline moves250ms. No camera landmarks/rulers representing measured values. |Simple frame/caption change. |Instant frame/label. |

Storyboard buttons expose selected state and keyboard focus; settled captions announce politely. Operating-system reduced-motion overrides any preview setting. In production, video controls, captions/transcript, poster and pause are mandatory; reduced motion avoids playback unless explicitly requested. Long capture duration is real footage time, not a350ms app workflow. Editing must preserve causality and the athlete's own count.

## Remaining assets and gates

Need a permissioned adult solo push-up recording15–25seconds plus full uncut evidence take, latest signed-out/manual-entry/success/history captures, and physical save/restart verification on the named build. Keep Self-reported readable. Record build/commit/hash/device and permissions. Recapture renamed Fault UI when available; until then label the legacy Training Arena name. Stage 1 supplies the practical shot list.

No human footage, testimonial, launch date, public-compatible-device matrix or camera accuracy claim was invented here. Mannequin media remains under human review (`app/assets/media/athlete/README.md:3–5`, `qa/media/validation_report_release.json:4–6`). Do not replace empty hero footage with it. Camera/battle campaigns require new two-phone/hosted validation and a rechecked brief before changing these narratives. Countries and final public access remain owner decisions.

## Verification

Codex reviewed all six full-page renders at1440/390px and the actual wordmark in both header sizes. The directions differ in composition, alignment, media shape and next-section structure, while headline, scope, CTA, consent and benefits stay identical. Editorial has the best hierarchy for solo-first acquisition; broadcast makes the demo arrive later and risks a battle inference; lab is clear but risks implying camera measurement. These are design judgments to test later, not conversion forecasts.

[Browser evidence](../../design/fault-website/review.json): Playwright Chromium checked all three directions at1440,768,390,320px (12 combinations). No horizontal overflow, broken loaded images or JavaScript errors; local Inter and the historical image loaded. Form completion created no network mutation, external request, localStorage or sessionStorage record. Stage controls changed selected state/captions; OS reduced-motion yielded zero running animations after interaction. These checks establish prototype behavior, not product/device validation.

[Supplementary evidence](../../design/fault-website/review-supplement.json): all three gallery frames switched to actual internal widths390/1440; invalid email showed error text and aria-invalid; keyboard Tab moved from email to the CTA with3px focus outline. A720px viewport, equivalent to the layout width of a1440px desktop at200% zoom, reflowed without overflow. This is a layout proxy, not a full browser zoom or assistive-technology audit.

[Inline review](../../design/fault-website/review-inline.json): six preview images decoded, exactly three named variants, desktop/phone switch worked, phone reflow had no overflow or runtime errors in the sandboxed standalone renderer. All motion is user-triggered. Mobile operating systems, Safari, physical devices, final footage, production accessibility/performance and a real confirmed waitlist remain later-stage checks.

Codex repaired worker integration defects: inactive direction media/process visibility, phone reserved-slot sizing/overflow, desktop gutters, form row/button wrapping, next-section ordering, gallery resize after disclosures and reduced-motion button transitions. Codex added exported motion tokens and kept the native app/design sources unchanged. Meaningful browser checks were rerun after those repairs. Source syntax and JSON checks pass. Existing unrelated user work is retained; no commits, app rename, production website, service writes or deployment occurred.

## OpenCode delegation

Both required assignments were executed through the CLI with explicit provider/model `opencode-go/deepseek-v4.1-flash`, one worker at a time. Codex created the creative specifications, wordmark, recommendation, review and this handoff. The inventory used text-task/read-only routing (`--agent plan`); routine layout construction used coding-task routing (`--agent build`) with six editable paths. No substitute provider, retry generation, account changes or purchases were used.

| Assignment / status | Session | Packet / report / events / usage |
| --- | --- | --- |
| `02-inventory` — **accepted** | `ses_ef976b812ffeBVpE87LWcQyAGY` | `tmp/fault-opencode/02-inventory.task.md`, `.report.md`, `.events.jsonl`, `.usage.json`, `.baseline.txt` |
| `02-layout` — **accepted after Codex repairs** | `ses_ef971a25effebhqawI6xHuUT74` | `tmp/fault-opencode/02-layout.task.md`, `.report.md`, `.events.jsonl`, `.usage.json`, `.baseline.txt` |

Paths are rooted at `D:/TrainingArena/`; raw local event streams remain outside source control. CLI pattern actually used:

```powershell
rtk proxy opencode.cmd run 'Complete only the attached task. Return the requested compact report.' --dir 'D:\TrainingArena' --model 'opencode-go/deepseek-v4.1-flash' --agent plan --format json --file 'D:\TrainingArena\tmp\fault-opencode\02-inventory.task.md' > 'D:\TrainingArena\tmp\fault-opencode\02-inventory.events.jsonl'
```

The second invocation substituted `--agent build` and the `02-layout` packet/log. Initial dispatch access succeeded; both sessions returned completed final reports.

Inventory output compared the supplied native design-system/component/token references and bounded asset directories, with file/line citations. Codex checked consequential palette/role/font/spacing statements against `design/arena/DESIGN_SYSTEM.md`, `tokens.json`, `tokens.css` and `COMPONENT_INVENTORY.md`; the existing `prototype/scripts/check.mjs` passed10 groups including token parity. No prototype result was promoted to product evidence. Marketing type enlargement, content width and the Fault wordmark were identified as new website decisions.

Layout output: `design/fault-website/index.html`, `concept.html`, `concepts.css`, `concepts.js`, `tokens.json`, `README.md`. It implemented Codex's `concept-spec.md` and used the supplied `fault-wordmark.svg`; it did not author a creative direction or alter the Stage1 evidence. Codex accepted the final files using the actual source review and browser evidence above, rather than the worker's check assertions alone.

Reported step-finish usage, token counts (sums per field; not assumed disjoint):

| Assignment | Input | Output | Reasoning | Cache read | Cache write | CLI cost field |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `02-inventory` |46918|1034|1872|74880|0|0.00900594|
| `02-layout` |53114|16070|26957|1021056|0|0.036846468|

These are reported provider fields, not an independently verified bill, unique-token total or savings calculation. No savings percentage is claimed.

## Decisions carried forward

Proceed with **Performance editorial** as the provisional baseline and the geometric Fault wordmark as the proposed lockup. The owner can choose either other direction before Stage3 without changing the factual copy or confirmation contract. Native naming is a separate release task.

The launch metric stays **unique confirmed, currently subscribed addresses, excluding duplicates, abuse and known delivery suppressions**. No subscriber number or growth rate appears as social proof. Stage3 must preserve each video's campaign/content identifier through submission and confirmation, count confirmation once per unique address, and report confirmed conversions by attribution rather than form clicks. Historical growth scenarios remain hypotheses until measured.

The immediate content dependency is current, permissioned solo footage plus real manual-entry/save/history captures from a named build. Hero publication waits for that evidence and physical persistence verification; the design and waitlist implementation can proceed with honest reserved media. No unresolved design decision blocks the next stage.
