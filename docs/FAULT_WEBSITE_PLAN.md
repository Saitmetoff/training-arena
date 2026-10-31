# Fault / fault.fit — prelaunch website plan

Prepared 3 October 2026. Planning proposal; no production code, domain configuration, external accounts, or campaigns changed.

## Objective and scope

Build fault.fit to the standard of a bespoke $30,000 agency website. The owner clarified that this is a quality target, not a fixed spending budget. The site converts attention from videos of the app into an email audience. The owner's public launch trigger is 30,000 emails.

Recommended operational definition: 30,000 unique, confirmed, currently subscribed and deliverable email addresses. Pending confirmations, duplicates, hard bounces, unsubscribes, and detected abuse do not count. This definition is a recommendation for implementation, not a claim that the list already exists.

The website deliverable is a responsive public marketing site, a real waitlist and email flow, source attribution, analytics, and reusable campaign assets. Small private product tests can continue before the public launch milestone. The website timeline and the time needed to acquire 30,000 subscribers are separate.

## What the repository establishes

- The app is Flutter/Android, with Supabase infrastructure. Existing public challenge and policy pages live in `challenge-web/` as plain HTML/CSS/JavaScript.
- The product covers push-ups and squats, solo activity, and competitive challenges. The documented visual system uses charcoal, large Inter typography, lime for the player/action, and violet for an opponent.
- `docs/decisions/12-competitive-direction.md` records a solo-first beta. It also records camera counting as gated on device evidence, with self-reported solo entry as the working pilot path. Check newer device evidence and the exact build before promising camera functionality, ranked competition, or launch availability.
- The owner's new name is Fault and the purchased domain is fault.fit. Brand implementation, public URL changes, and deep-link verification belong in the eventual build plan. A public rename should not casually change the Android application ID.
- Prototype screenshots contain simulated behavior. They are design references, not evidence of functioning features, users, or results.

Sources: `docs/CONTRACT.md`, `docs/decisions/12-competitive-direction.md`, `design/arena/DESIGN_SYSTEM.md`, `prototype/README.md`, and `challenge-web/README.md`. These are documented constraints, not a live feature audit.

## Creative direction

Initial audience hypothesis: people who already do bodyweight workouts and respond to measurable effort, personal bests, and friendly competition. Validate the audience, launch geography, and platform mix with the first content tests.

Explore exactly three directions using the same headline, footage, signup action, and mobile viewport:

| Direction | Visual character | Best use |
| --- | --- | --- |
| Performance editorial — recommended | Oversized Inter, charcoal and off-white, deliberate lime actions, real movement footage, strong crop and spacing | A coherent extension of the existing app, centered on effort and progress |
| Competition broadcast | Two athlete perspectives, lime/violet player identities, restrained score and result transitions | A campaign once the demonstrated battle flow is verified |
| Camera lab | Close product demonstration, setup angles, concise measurement explanations | A campaign once camera counting has convincing real-device evidence |

Carry the existing token meanings through the site. New wordmark and marketing layout proposals should be recorded as brand decisions before production implementation. Keep the visual subject specific to Fault: exertion, reps, results, and the real interface.

Working copy hypothesis: **Every rep. More reason.** Pair any brand headline with a literal product sentence describing the verified launch scope. Primary action: **Join the waitlist**. Avoid implying that signup grants immediate access.

### Page sequence

1. **Hero:** Fault wordmark, clear product sentence, real short demonstration with an optimized poster, and visible email signup. The form works before the video downloads.
2. **Product proof:** a short captioned recording showing setup, a real set, and the result. Use the build intended for the claim.
3. **How it works:** three concise beats: set up, complete a set, review progress. Add competitive messaging only when the release scope and footage support it.
4. **Reason to return:** personal progress and any verified competitive loop. Show actual app screens and permissioned tester feedback when available.
5. **Availability and FAQ:** supported launch platform, expected access process, equipment/setup, and an accurate camera/privacy explanation when applicable.
6. **Final signup and footer:** repeat the same primary action, then support, privacy, and relevant existing public pages.

After signup: check-your-inbox state → confirmation → confirmed state → optional platform preference and share link. Add a referral incentive only after defining a benefit the team can deliver and a way to resist fake referrals.

### Motion specification

- One signature sequence: a user-controlled product story connecting movement footage to the corresponding real app result. Build a simpler stacked sequence on phones when pinning would obstruct content.
- A restrained wordmark/headline entrance, section reveals, and precise hover/press/form feedback.
- Use CSS for simple states and Motion for the interactive sequence; introduce another animation engine only if a proven requirement justifies it.
- Keep the headline, email field, and action available immediately. Preserve normal scrolling.
- Provide a reduced-motion presentation, video controls and captions, and poster fallbacks. Avoid animating a real live timer's digits, consistent with the existing design contract.

Motion's [scroll APIs](https://motion.dev/docs/react-scroll-animations) and [reduced-motion hook](https://motion.dev/docs/react-use-reduced-motion) support this approach.

### Assets required

One genuine 15–25 second product demonstration; 3–5 short movement clips; 4–6 current app captures; a Fault wordmark and social lockup; accurate availability/FAQ copy; and confirmation, welcome, and launch email templates. Shoot vertical-first footage and frame additional crops for desktop. Use generated imagery for early mood exploration only when useful; demonstrated product behavior must come from the product.

## Delivery plan

Planning allowance: approximately 3–4 weeks of focused production with timely feedback and usable footage. This is a scope estimate, not a delivery promise or a forecast of reaching 30,000 subscribers.

| Phase | Work and output | Completion condition |
| --- | --- | --- |
| 1. Product truth and brief, days 1–2 | Check intended build and claims; define audience, scope, primary message, signup definition, and content shot list | The headline and demonstration describe the same verified experience |
| 2. Art direction, days 3–5 | Three comparable hero directions; select one; finalize desktop/mobile composition, typography, wordmark, and motion storyboard | One complete direction reviewed at desktop and phone widths |
| 3. Working waitlist, week 2 | Implement page and basic motion; database, confirmation flow, source attribution, email templates, and analytics | A real test signup is confirmed, stored once, attributed, and excluded after unsubscribe |
| 4. Signature experience, week 3 | Integrate final footage; refine motion and responsive layout; build social previews and campaign variants | Real content replaces placeholders; core signup remains quick and clear |
| 5. QA and launch preparation, week 4 | Cross-device checks, performance fixes, email delivery checks, fault.fit routing/DNS, metadata, and release checklist | Preview passes the critical flows and the exact production build is verified after release |
| 6. Acquisition, ongoing | Publish videos, compare hooks and audiences, improve the page from funnel data, keep subscribers engaged | Growth measured in qualified confirmed subscribers, with 30,000 as the public launch trigger |

Make the basic waitlist available as soon as its copy, confirmation flow, and tracking pass checks. Refine the more ambitious motion in a preview while early content provides audience evidence. The first production implementation brief should cover the hero, demonstration, form, and confirmation flow.

## Technical proposal

Use a separate marketing application, provisionally Next.js + TypeScript + CSS/Tailwind + Motion, on Vercel. Prefer pre-rendered content and small interactive components. Retain the app's existing Flutter and Supabase architecture; do not turn the static challenge pages into the marketing application as a side effect.

Runtime path: visitor → server-side waitlist endpoint → Supabase record → Resend confirmation email → verified subscriber. PostHog records the corresponding funnel events. The database is the authoritative subscriber count.

- Reuse the existing Supabase provider with a deliberately separated waitlist table/schema. Verify the development and production project choices before integration.
- Store email, pending/confirmed status, confirmation time, consent-copy version/time, attribution, and an optional platform preference. Use opaque identifiers in analytics, not raw email addresses or confirmation tokens.
- Validate input server-side; deduplicate; throttle abuse; use expiring, single-use verification tokens; keep credentials server-side. A retry must not create another subscriber.
- Synchronize unsubscribe, bounce, and suppression events into the launch count. Keep pending and confirmed states distinct. Build email-sending retries without duplicating contacts or sends.
- Configure a verified sending domain and sender identity. Draft confirmation, welcome, periodic development update, and launch messages. The plan does not authorize sending a campaign.
- Preserve `/c/*`, `/.well-known/assetlinks.json`, and the public privacy/support/deletion routes described by `challenge-web/README.md`. Align the app's link host, website rewrites, and Android App Links when fault.fit is connected.
- Account access, hosting plans, DNS control, and email capacity for 30,000 contacts remain implementation checks. Installed plugins are not proof these project settings are ready.

[Resend Broadcasts](https://resend.com/docs/dashboard/broadcasts/introduction) provides the campaign side of the proposed email service. Confirm plan capacity and current commercial terms before choosing a paid plan.

## Growth and measurement

Use 30,000 unique confirmed subscribers as the target, with deliverability and engagement tracked alongside it. Do not treat the list size alone as evidence of product retention or readiness.

Start with three repeatable video formats: a real set and result; a progress/personal-best story; and a friend challenge once the battle footage and release scope are verified. Give each video a clear fault.fit action and a trackable campaign/content identifier. Label future-feature previews as previews.

Measure `landing_view`, `demo_play`, `waitlist_submit`, `waitlist_confirmed`, `share_click`, and unsubscribe/suppression changes. Inspect performance by channel, creative, device, and platform interest. Optimize confirmed subscribers per 1,000 video views; monitor confirmation and unsubscribe rates so a high submission rate does not hide poor audience quality.

Illustrative model, not benchmarks or a forecast:

- Video view → website visit: 1%.
- Website visit → valid unique email submission: 25%.
- Submission → confirmed email: 80%.
- These assumptions imply 15 million video views, 150,000 website visits, and 37,500 submissions for 30,000 confirmed emails, before unsubscribe/bounce attrition. Referrals and other traffic sources are not modeled.

At 90 days the net target would average roughly 334 additional confirmed subscribers per day. The correct acquisition timeline must be estimated from actual early traffic, conversion, and list attrition.

| Milestone | Next decision |
| --- | --- |
| First 100 confirmed | Review signup friction, delivery, mobile behavior, and direct tester feedback |
| 1,000 | Identify which video hook and audience produce confirmed, engaged subscribers |
| 5,000 | Improve the best message/page combination; test a simple honest referral offer if useful |
| 10,000 | Check launch interest, device mix, product readiness, and email delivery at increasing volume |
| 30,000 | Apply the agreed public launch trigger together with product readiness and delivery checks |

Keep a small private tester cohort active during acquisition. Use actual product return behavior and completion of the core activity to assess readiness, rather than email opens alone.

## Skills to use

All skill names below are present in this Codex session. Load them when their phase starts; this is a focused working set, not a request to activate every design skill.

| Stage | Skills | Output |
| --- | --- | --- |
| Planning | `website-studio` | Brief, page narrative, capability choices, acceptance criteria |
| Identity | `brand`, `design-system` | Fault identity, typography, color roles, reusable tokens |
| Visual design | `design`, `hallmark` | Distinctive composition and a review against generic patterns |
| Motion | `motion-design`, then relevant `scroll-animations`, `typography`, `sequencing`, `accessibility` | One coherent motion specification and reduced-motion behavior |
| Implementation | `vercel:nextjs`, `vercel:react-best-practices`, `supabase:supabase` | Marketing application and working waitlist |
| Analytics | `posthog:posthog` | Attribution and confirmation funnel |
| Verification/release | `vercel:verification`, `vercel:deployments-cicd`, `motion-audit` | Evidence of working signup, responsive behavior, performance, and deployment |
| Planning explanations | `visualize:visualize` | Interactive traffic model and design comparisons as needed |
| Optional media work | `storyboarding`, `remotion`, `imagegen` | Repeatable video templates and concept exploration when requested |

The most valuable non-tool inputs are real product footage, careful art direction, precise copy, and repeated review on phones.

### Codex and OpenCode execution

Owner update, 4 October 2026: use OpenCode Go with the owner-selected DeepSeek V4.1 Flash model (`opencode-go/deepseek-v4.1-flash`) for the bounded assignments specified in each stage of `D:\TrainingArena\docs\FAULT_WEBSITE_PROMPTS.md`. Codex leads design/architecture, performs MCP operations, and reviews results. OpenCode handles scoped inventories, drafts, routine components, report synthesis, and specified fixes. Read `D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md` for required delegation, compact handoffs, and verification. Keep the model fixed unless the owner changes it. This is a Codex-usage optimization; overall provider token/cost savings must be measured rather than assumed.

## Plugins and MCP connections

A skill supplies a workflow. A plugin packages skills and/or tools. An MCP connection gives the agent access to an external service. A plugin may already supply the MCP capabilities, so these are not separate shopping lists or automatic reasons to configure duplicate servers.

Plugin states below were checked on 3 October 2026. Installed means installed in the environment, not that a specific Fault project, permission, domain, or billing plan has been verified.

| Plugin | Confirmed state | Purpose |
| --- | --- | --- |
| Visualize | Available and explicitly invoked | Planning model and interactive comparisons |
| Vercel | Installed; tools exposed | Previews, hosting, deployment diagnosis |
| Supabase | Installed; tools exposed | Waitlist data, migrations, server functions |
| PostHog | Installed; tool exposed | Analyze signup funnels and creative attribution |
| Context7 | Installed; tools exposed | Current library documentation |
| GitHub | Installed; tools exposed | Source control and review workflow |
| Figma | Not installed at check; suggested | Optional editable design collaboration and handoff |
| Resend | Not installed at check; suggested | Proposed email provider; confirmation and campaign operations |

Recommended MCP capabilities:

| Connection | Priority and use | Official reference |
| --- | --- | --- |
| Vercel | Core; existing tool access for previews and deploy diagnostics | [Vercel MCP](https://vercel.com/docs/ai-tooling/vercel-mcp) |
| Supabase | Core; existing tool access for waitlist schema and server functions | [Supabase MCP](https://supabase.com/docs/guides/ai-tools/mcp) |
| PostHog | Core; existing tool access for conversion analysis | [PostHog MCP](https://posthog.com/docs/model-context-protocol) |
| Context7 | Core; existing documentation tools for selected libraries | [Context7 clients](https://context7.com/docs/resources/all-clients) |
| GitHub | Existing connector tools; repository review and changes | Available in the current tool inventory |
| Resend | Add when implementing email; draft templates and inspect delivery | [Resend remote MCP](https://resend.com/changelog/remote-mcp-server) |
| Figma | Optional; useful if Figma is the chosen design workspace | [Figma MCP](https://developers.figma.com/docs/figma-mcp-server/) |
| Browser automation | Already available through the browser tool; exercise actual page and form states | No additional browser MCP installation required for this plan |

Use the existing connector path first. An MCP is an agent development/operations tool; the public website uses the providers' normal SDKs/APIs and does not require visitors to connect MCP servers.

## Acceptance criteria

- Product story understandable in the first viewport; email action immediately reachable.
- Real, captioned footage; accurate platform/availability claims; no fabricated testimonials, scores, signup totals, or countdowns.
- Full signup, duplicate, expired confirmation, failure/retry, unsubscribe, and suppression flows verified against actual development services.
- Manual review at 320px, 390px, tablet, and desktop; touch and keyboard usability; 200% text reflow; reduced-motion behavior; no clipping or broken media.
- Test social-platform in-app browsers as well as ordinary mobile browsers because the acquisition source is video.
- Target real-user p75 LCP ≤2.5s, INP ≤200ms, and CLS ≤0.1. Use lab checks before launch and field measurements once enough traffic exists; a single Lighthouse score cannot establish these field results. [Google's Core Web Vitals guidance](https://web.dev/articles/vitals).
- Metadata/social previews, redirects, challenge links, public support/policy routes, and fault.fit HTTPS verified after deployment.
- Campaign source survives confirmation; displayed subscriber totals come from the agreed database definition.

## First execution brief

Validate the feature claims against the intended build, select a real demo clip, then produce three comparable Fault hero directions at desktop and mobile widths. Review the chosen direction with one polished motion prototype and a functional email signup/confirmation flow. That gives a concrete standard for building the rest of the site.
