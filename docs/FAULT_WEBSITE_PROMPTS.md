# Fault website — stage prompts

Prepared 4 October 2026 from `D:\TrainingArena\docs\FAULT_WEBSITE_PLAN.md`.

Copy one prompt at a time into a Codex chat working in `D:\TrainingArena`. These prompts request execution when you paste them; writing this document has not executed the stages. Stage 5 is the public website deployment prompt. Stage 6 is one growth iteration, not a recurring automation or permission to send a campaign.

Each stage saves a handoff under `D:\TrainingArena\docs\fault-website\` so the next stage can run in the same chat or a fresh one. Those handoffs will be created by the stages; they are not existing deliverables yet. Reuse implemented work and recorded decisions on reruns.

Skills are instructions to load; MCP connections are service tools. Use the connections already provided by the installed plugins. Check actual project access when needed rather than equating plugin installation with account readiness. Resend is installed as of this check; Figma is not installed and remains optional. Browser automation is an existing tool, not another required MCP purchase.

OpenCode delegation is mandatory for the assignments named in each stage. Codex invokes the CLI using the owner's selected **OpenCode Go** provider and **DeepSeek V4.1 Flash** model (`opencode-go/deepseek-v4.1-flash`), keeps the main decisions and MCP operations, and verifies worker results. The shared policy and command examples are in `D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md`. This reduces repeated context in the prompts while keeping each stage independently runnable.

## Stage 1 — Product truth, positioning, and brief

```text
Execute Stage 1 of the Fault website project in D:\TrainingArena.
Read and follow D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md. Act as the lead Codex agent and execute this stage's required OpenCode assignments through the CLI; include delegation evidence in the stage handoff.
Read D:\TrainingArena\docs\FAULT_WEBSITE_PLAN.md and applicable repository instructions. Fault is the product name, fault.fit is the purchased domain, and the goal is the quality of a bespoke $30,000 website with a waitlist supporting a 30,000-email public app launch. The $30,000 figure is a quality bar, not an authorized spending budget.

Skills: website-studio and brand. Use visualize:visualize only when an interactive explanation improves a real decision.
MCP/tools: local repository tools; web research for current references; Context7 if current technical documentation is needed. GitHub is optional for relevant remote evidence. No external service writes are needed for this stage.

Required OpenCode assignments: first delegate the bounded repository/asset inventory with exact source citations. After Codex verifies material product claims, delegate a batch of hero/FAQ variants constrained to those facts. Codex owns the claims matrix, positioning, final copy selection, and brief. Use the workflow's text-task model; pass only relevant files and settled facts.

Inspect the product contract, design system, latest release decisions, relevant implementation, and available device-test evidence. Separate verified behavior, implemented but unverified behavior, and future scope. Specifically resolve what we can truthfully show or say about camera counting, solo sets, battles, supported platforms, and availability. Treat prototype fixtures as design references.

Produce a concise audience and positioning brief; one recommended product promise with two alternatives; the page narrative; actual first-draft hero, benefits, CTA, and FAQ copy; and a practical footage shot list. Use the existing charcoal/lime identity as a starting point. Ask only for missing facts that materially change the work, and continue independent work while awaiting answers.

Define the waitlist metric precisely: unique confirmed, currently subscribed addresses, excluding duplicates, abuse, and known delivery suppressions. Specify how videos will be attributed to confirmed signups. Treat growth rates as hypotheses until measured.

Save D:\TrainingArena\docs\fault-website\01-brief.md with the brief, source-backed claims matrix, draft copy, asset inventory/shot list, decisions, and unresolved facts. Reference exact existing files for technical evidence.

Finish when the proposed headline, page narrative, demonstration requirements, and verified release scope agree. Return the saved file and the few decisions that need my attention. This stage produces the brief and copy, not the production website.
```

## Stage 2 — Brand, visual direction, and motion storyboard

```text
Execute Stage 2 of the Fault website project in D:\TrainingArena.
Read and follow D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md. Act as the lead Codex agent and execute this stage's required OpenCode assignments through the CLI; include delegation evidence in the stage handoff.
Read D:\TrainingArena\docs\FAULT_WEBSITE_PLAN.md and D:\TrainingArena\docs\fault-website\01-brief.md. Use the verified claims and actual available assets from the brief. If that handoff is missing, identify the missing prerequisite and complete the independent concept work using clearly labeled assumptions.

Skills: website-studio, brand, design-system, design, and hallmark. Use motion-design and storyboarding for the motion concept, and visualize:visualize to present comparable interactive concepts in chat.
MCP/tools: Figma if connected for editable designs and handoff; browser automation for local concept review. Context7 is optional for prototype implementation. Figma is optional: local interactive concepts are a valid deliverable when it is unavailable.

Required OpenCode assignments: delegate a comparison/inventory of the supplied design references and tokens, then routine component/layout construction from Codex's concrete concept specifications. Codex creates the three creative directions, judges the wordmark and composition, and reviews every concept. Use text-task routing for inventories and coding-task routing for local layouts. Codex performs any Figma or inline Visualize operations.

Create exactly three distinct hero directions using identical product copy and evidence: Performance editorial, Competition broadcast, and Camera lab. Keep claims within the verified brief even when a direction uses a competitive or measurement-inspired visual treatment. Show each at a wide desktop viewport and a 390px phone viewport.

Make these reviewable visual concepts, not moodboard descriptions. Include a proposed Fault wordmark, typography, spacing, color roles, a real app/demo area, email CTA, and transition into the next section. Preserve lime/player and violet/opponent meanings when those identities appear. Use explicit placeholders only for genuinely missing media; do not invent product screenshots or results.

For each direction, storyboard one signature product animation and its mobile and reduced-motion alternatives. Explain which direction best fits Fault and the signup goal. If no direction is selected yet, record your recommendation as a provisional baseline so the next stage can proceed; keep it easy for me to choose another.

Save local design assets in D:\TrainingArena\design\fault-website\ and the handoff in D:\TrainingArena\docs\fault-website\02-design.md. Include concept previews or Figma links, the selected/provisional direction, tokens, page composition, motion storyboard, and remaining asset needs.

Finish when all three concepts are visually reviewable and the recommended direction has an implementation-ready desktop/mobile specification. Return the previews and your recommendation.
```

## Stage 3 — Working website, waitlist, email, and measurement

```text
Execute Stage 3 of the Fault website project in D:\TrainingArena.
Read and follow D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md. Act as the lead Codex agent and execute this stage's required OpenCode assignments through the CLI; include delegation evidence in the stage handoff.
Read D:\TrainingArena\docs\FAULT_WEBSITE_PLAN.md and the 01-brief.md and 02-design.md handoffs in D:\TrainingArena\docs\fault-website\. Use my selected design; if no selection exists, use the recorded provisional recommendation and state that assumption. Inspect current code and account capabilities before scaffolding anything.

Skills: website-studio, vercel:nextjs, vercel:react-best-practices, supabase:supabase, and posthog:posthog. For email, load email-best-practices and react-email from the Resend plugin. Use vercel:deployments-cicd for a preview deployment.
MCP/tools: Context7 for current library documentation; Supabase for the intended development database/functions; Resend for email configuration/templates/delivery diagnostics; PostHog for events/funnels; Vercel for preview hosting; browser automation for signup checks. GitHub is optional for an existing review workflow.

Required OpenCode assignments: after Codex sets the design/API contracts, delegate bounded presentational components, email-template markup from approved copy, the event-name mapping, and meaningful regression cases for specified behavior. Batch compatible work and give exact file ownership. Codex retains database/RLS design, server-side signup and verification logic, webhook/security decisions, integration review, and all live service writes. Route code assignments to the coding-task model.

Implement the complete responsive page and basic interaction states. Provisionally use a separate Next.js/TypeScript marketing app with CSS/Tailwind and Motion, adapting to existing implementation if it already satisfies the brief. Preserve the Flutter app and existing challenge/public-page behavior. Prefer pre-rendered content and small interactive components.

Build a real server-side waitlist flow: validate email, save pending status, send confirmation, verify an expiring single-use token, then show a confirmed state. Include duplicate handling, retries, throttling, invalid/expired tokens, and unsubscribe. Keep credentials server-side and use the configured secret-management flow. Send test emails only to test addresses I explicitly provide or that are already designated for this project; prepare campaign emails as drafts.

Make the database authoritative for subscriber counts. Deduplicate safely and synchronize verified unsubscribe/bounce/suppression events. Verify webhook authenticity and handle retries idempotently. Preserve campaign attribution through confirmation without sending raw email addresses or verification tokens to analytics.

Instrument landing_view, demo_play, waitlist_submit, waitlist_confirmed, and share_click with a documented source/creative scheme. Build a confirmation funnel. Capture subscriber creation and confirmation once per real state transition.

Use a development environment and preview deployment. If a required account, DNS setting, or test recipient is missing, finish the code and independently verifiable work, then report the exact remaining dependency. Distinguish mocked checks from live integration evidence.

Save D:\TrainingArena\docs\fault-website\03-build.md with implementation paths, preview URL if available, environment-variable names without values, schema/event definitions, and verification results. Finish when a real permitted test signup can be confirmed once, attributed, and excluded after unsubscribe, or explicitly identify which external check remains blocked. Return the working preview and evidence.
```

## Stage 4 — Signature animation and final content

```text
Execute Stage 4 of the Fault website project in D:\TrainingArena.
Read and follow D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md. Act as the lead Codex agent and execute this stage's required OpenCode assignments through the CLI; include delegation evidence in the stage handoff.
Read D:\TrainingArena\docs\FAULT_WEBSITE_PLAN.md and the 01–03 handoffs in D:\TrainingArena\docs\fault-website\. Continue the existing implementation and chosen design.

Skills: design, hallmark, motion-design, scroll-animations, typography, sequencing, accessibility, and motion-audit. Use vercel:react-best-practices for implementation. Load storyboarding or remotion only if a reusable video composition is needed; use imagegen only for concept/supporting artwork, with real footage remaining the evidence of product behavior.
MCP/tools: Context7 for the animation/library APIs; Vercel for preview updates; browser automation for visual/interaction checks. Figma is optional for the recorded design reference. Use the existing animation library unless a specific requirement justifies adding another.

Required OpenCode assignments: delegate explicit CSS/responsive corrections, metadata and caption-formatting helpers, and repetitive interaction states after Codex defines the signature motion pattern. Give exact target files and expected behavior. Codex owns the signature animation, final media/copy selection, and visual acceptance. Use coding-task routing for implementation and text-task routing for caption drafts or asset reports.

Implement the approved signature sequence connecting actual movement footage to its corresponding app experience. Refine entrances, section transitions, typography, button feedback, and form states as one consistent motion system. Keep the value proposition and signup action immediately available and preserve normal scrolling.

Integrate the real demonstration, current app captures, deliberate mobile/desktop crops, captions, optimized posters, and controlled media loading. Make the mobile and reduced-motion versions fully understandable. Preserve the existing rule against animated live-timer digits.

Complete all page copy, honest availability details, FAQ, metadata, favicon, social preview, and visible form feedback. If final footage is unavailable, complete the poster-based layout and document the exact missing shots; do not represent that as a finished media release.

Review at 320px, 390px, tablet, and desktop widths. Check keyboard use, touch use, text reflow, animation cleanup, repeat scrolling, and slow/loading/failed media states. Fix concrete issues and rerun checks affected by those fixes.

Save D:\TrainingArena\docs\fault-website\04-polish.md with the updated preview, final asset inventory, screenshots, motion behavior, and remaining issues. Finish when the site matches the chosen direction, the signature interaction works, and the signup flow still passes. Return a reviewable preview and evidence of the mobile and reduced-motion versions.
```

## Stage 5 — QA and public website deployment

```text
Execute Stage 5 of the Fault website project in D:\TrainingArena.
Read and follow D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md. Act as the lead Codex agent and execute this stage's required OpenCode assignments through the CLI; include delegation evidence in the stage handoff.
Read D:\TrainingArena\docs\FAULT_WEBSITE_PLAN.md and the 01–04 handoffs in D:\TrainingArena\docs\fault-website\. Verify and publish the finished waitlist website to fault.fit. This publishes the marketing website; the public app launch remains a separate milestone.

Skills: website-studio, vercel:verification, vercel:deployments-cicd, motion-audit, and accessibility. Load supabase:supabase, posthog:posthog, and the Resend email-best-practices skill for the relevant integration checks.
MCP/tools: Vercel for deployment/domain diagnostics, Supabase for waitlist verification, Resend for sender and delivery checks, PostHog for event verification, and browser automation for real user flows. Use GitHub if the established deployment uses repository CI. Use existing DNS access where available; otherwise prepare exact records for the domain owner.

Required OpenCode assignments: use ordinary commands to produce and filter reports, then delegate synthesis of substantial sanitized QA output and assembly of the release-evidence index. Delegate allowlisted low-risk fixes when the reports identify any; do not invent fixes to satisfy delegation. Codex independently validates consequential findings, handles sensitive fixes, and performs DNS/production configuration and deployment. The worker must not receive production secrets or subscriber records.

Inspect the actual build scripts and run the production build and relevant checks. Verify the complete signup lifecycle: invalid input, pending signup, duplicate submission, confirmation, expired/used tokens, send failure/retry, unsubscribe, and bounce/suppression synchronization. Verify rate limiting, secret boundaries, webhook authenticity, and attribution. Use designated test data and recipient addresses.

Inspect 320px, 390px, tablet, and desktop; keyboard navigation; 200% text reflow; reduced motion; video fallbacks; and social-platform in-app browsers where available. Report any device/browser checks that cannot be performed.

Target real-user p75 LCP ≤2.5s, INP ≤200ms, and CLS ≤0.1. Use lab measurements as prelaunch evidence and set up field measurement; distinguish these types of evidence. Fix release-blocking usability, security, delivery, or routing defects before publishing.

Prepare and verify production configuration, sender DNS, domain routing, HTTPS, canonical/social metadata, and redirects. Preserve /c/*, /.well-known/assetlinks.json, and the existing policy/support/deletion routes. Use the repository's public-page release checks where applicable, including required owner details. Preserve unrelated domain records and retain a rollback path.

Publish the exact validated version to fault.fit using existing authorized accounts and plans. If missing access or a paid purchase prevents deployment, finish the deployable work and supply the precise outstanding action; do not claim it is live. After deployment, verify the public URL anonymously and exercise a permitted confirmation flow against production.

Save D:\TrainingArena\docs\fault-website\05-release.md with the verified URL, deployment identity, check results, measured performance, remaining limitations, and rollback procedure. Finish when the public website and critical flows are verified, or identify the exact unresolved external dependency. Return the release evidence and launch status.
```

## Stage 6 — Video acquisition and conversion improvement

```text
Execute one Stage 6 growth iteration for Fault in D:\TrainingArena.
Read and follow D:\TrainingArena\docs\FAULT_OPENCODE_WORKFLOW.md. Act as the lead Codex agent and execute this stage's required OpenCode assignments through the CLI; include delegation evidence in the stage handoff.
Read D:\TrainingArena\docs\FAULT_WEBSITE_PLAN.md and the completed handoffs in D:\TrainingArena\docs\fault-website\. The objective is progress toward 30,000 unique confirmed, currently subscribed emails through videos of the real app and fault.fit. Use actual results when available; clearly separate hypotheses and projections.

Skills: posthog:posthog, website-studio, brand, storyboarding, and visualize:visualize. Use remotion only when building reusable video templates. Use the Resend email-best-practices and react-email skills for email drafts, and vercel:verification for website experiments.
MCP/tools: PostHog for funnel/source analysis; read-only Supabase access to reconcile eligible subscriber counts; Resend for delivery and engagement diagnostics; Vercel and browser automation for previewing website changes. Use an already connected video-platform tool or owner-provided exports for video-view data. If that data is unavailable, report the gap and analyze website conversion independently.

Required OpenCode assignments: supply aggregate, sanitized exports for a concise pattern summary; delegate batches of video hooks/scripts/captions, email-copy variants, and the 14-day calendar using Codex's verified creative brief. Codex owns metric interpretation, experiment selection, claim accuracy, and final content approval. Use the text-task model; keep raw subscriber data and all publishing/sending operations with Codex.

Analyze the journey from video views to website visits, valid submissions, confirmations, and retained eligible subscribers. Break down by source, creative, and device where sample size supports it. Report net subscriber growth, confirmation rate, known suppressions, and unsubscribe rate. Use consistent time windows and allow time for confirmation before comparing recent cohorts. Treat email opens cautiously and prioritize meaningful downstream actions.

Identify the largest evidenced conversion loss and propose a focused improvement. For limited data, propose an instrumented hypothesis instead of declaring a winner. Prepare one justified website experiment in a preview, with its primary metric, guardrails, evaluation window, and rollback. Verify any code changed.

Produce a 14-day content plan containing concrete hooks, 15–30 second scripts, shot lists, on-screen captions, fault.fit CTA, and campaign/content identifiers. Use real-set/result and progress-story formats; include friend challenges only when the verified app scope supports them. Prioritize a small number of repeatable formats.

Draft a welcome message, a useful development update, and a launch-interest email in the same Fault voice. Prepare posts and emails for review; publishing, scheduling recurring work, and sending campaigns require a separate request identifying the intended audience/content. Use milestones at 100, 1,000, 5,000, 10,000, and 30,000 subscribers to focus the next decision.

Save D:\TrainingArena\docs\fault-website\06-growth.md with dated results, metric definitions, data gaps, content scripts, email drafts, the experiment, and the next decision. Preserve earlier iterations when updating it. Finish with one actionable growth iteration grounded in available evidence; do not forecast a guaranteed date for reaching 30,000 subscribers.
```
