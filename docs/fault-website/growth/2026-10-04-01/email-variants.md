# Email variants — iteration 2026-10-04-01

Six drafts: two each for welcome, useful development update, and launch-interest.

Audience contracts (from `creative-brief.md:13`):
- **Welcome** — only after confirmed opt-in and a currently eligible subscription.
- **Development update** — currently subscribed, eligible members who consented to these updates.
- **Launch-interest** — asks for interest, not an announcement of app access.

Global rules: authenticated sender; actual public operator/address/support; individual unsubscribe URL; suppression check at send time; separate audience/content authorization. Use `[VERIFIED_SITE_URL]`, `[UNSUBSCRIBE_URL]`, `[OPERATOR_ADDRESS]` only where genuinely missing. The actual reply-to address is missing and must be supplied as `[REPLY_TO_ADDRESS]` before any reply action. A website link cannot submit interest or send a reply, so the only permitted website CTA is "Review the development scope", and the meaningful interest action is a reply. No invented survey endpoint or new article. No raw subscriber data and no send operation is performed by this draft. Success is measured by real replies, completed interest action and continued eligibility — not open rates. No invented shipped milestone, pricing, launch access, measured growth or update cadence.

---

## 1. Welcome — Variant A
- **Target audience:** Newly confirmed, currently eligible subscriber (welcome only after confirmed opt-in).
- **Subject:** You're confirmed — here's what Fault is right now
- **Preheader:** A solo push-up tracker being built, Android first. No app access yet.
- **Body:**
  Thanks for confirming. You're on the list — and to be clear, that's all it is right now.

  Fault is a solo push-up tracker in development. You do the set, you count the reps, you type the number in yourself — results are self-reported. Saved sets and your last-seven-days comparison stay on your phone, and solo is signed out.

  There's no download and no launch date. We'll use this list only to send the updates you asked for.
- **CTA:** Review the development scope → `[VERIFIED_SITE_URL]`
- **Footer:** Unsubscribe: `[UNSUBSCRIBE_URL]` · Operator: `[OPERATOR_ADDRESS]` · Reply-to: `[REPLY_TO_ADDRESS]`

## 2. Welcome — Variant B
- **Target audience:** Newly confirmed, currently eligible subscriber.
- **Subject:** Confirmed. One honest paragraph about Fault.
- **Preheader:** What it does, what it doesn't, and how to leave.
- **Body:**
  Confirmation done. Short version:

  **What Fault is:** a bodyweight push-up tracker being built for Android first.
  **How it works:** you count, you enter the reps, it saves them to your phone. Self-reported, labelled as such. Personal best only within the history your phone still holds.
  **What it isn't yet:** a public app. No store download, no launch date, no account required for solo.

  Reply to `[REPLY_TO_ADDRESS]` if you want one specific question answered later.
- **CTA:** Review the development scope → `[VERIFIED_SITE_URL]`
- **Footer:** Unsubscribe: `[UNSUBSCRIBE_URL]` · Operator: `[OPERATOR_ADDRESS]` · Reply-to: `[REPLY_TO_ADDRESS]`

---

## 3. Development update — Variant A
- **Target audience:** Currently subscribed, eligible members who consented to these updates.
- **Subject:** Development checklist: what the checks show so far
- **Preheader:** Source and automated checks only — a physical walkthrough is still pending.
- **Body:**
  You asked to follow the build. Here's the honest state, from source and automated checks.

  **In the code and checks (physical walkthrough still pending):** solo push-ups; manual rep entry; self-reported results; phone-local saved sets; last-seven-days view; personal best within retained history; solo signed out.

  **Present but not claimed:** camera counting is implemented and currently off / under test — not offered as a benefit.

  **Still open:** the release boundary and public availability. Nothing is shipped yet.

  Which platform should come first after Android? Reply to `[REPLY_TO_ADDRESS]` with your answer.
- **CTA:** Reply with your platform answer, or Review the development scope → `[VERIFIED_SITE_URL]`
- **Footer:** Unsubscribe: `[UNSUBSCRIBE_URL]` · Operator: `[OPERATOR_ADDRESS]` · Reply-to: `[REPLY_TO_ADDRESS]`

## 4. Development update — Variant B
- **Target audience:** Currently subscribed, eligible members who consented to these updates.
- **Subject:** In the checks so far vs. not established yet
- **Preheader:** A checklist, not a launch notice. Physical walkthrough pending.
- **Body:**
  Quick checklist from source and automated checks — not a physical-device walkthrough.

  In the checks: solo push-ups; you count and enter reps; self-reported label; local saved sets; last-seven-days view; PB within retained history; signed-out solo.

  Implemented but not claimed: camera counting (present and currently off / under test).

  Not established yet: cloud sync; lifetime PB; store download; guaranteed improvement; any launch date.

  If you'd use this mostly one-handed between sets, reply to `[REPLY_TO_ADDRESS]` and tell us.
- **CTA:** Reply with how you'd use it → `[REPLY_TO_ADDRESS]`
- **Footer:** Unsubscribe: `[UNSUBSCRIBE_URL]` · Operator: `[OPERATOR_ADDRESS]` · Reply-to: `[REPLY_TO_ADDRESS]`

---

## 5. Launch-interest — Variant A
- **Target audience:** Currently subscribed, eligible members being asked whether they want launch interest updates.
- **Subject:** Interested in Fault when it's ready? (Not ready yet.)
- **Preheader:** A reply, not an announcement. No access offered.
- **Body:**
  We're gauging interest — nothing is released and nothing is promised.

  Fault is a solo push-up tracker in development: Android first, you count and enter your own reps, self-reported, saved locally on your phone.

  Reply INTERESTED to `[REPLY_TO_ADDRESS]` and tell us your phone platform. If you'd rather not, unsubscribe — no hard feelings.
- **CTA:** Reply INTERESTED and tell us your phone platform → `[REPLY_TO_ADDRESS]`
- **Footer:** Unsubscribe: `[UNSUBSCRIBE_URL]` · Operator: `[OPERATOR_ADDRESS]` · Reply-to: `[REPLY_TO_ADDRESS]`

## 6. Launch-interest — Variant B
- **Target audience:** Currently subscribed, eligible members being asked whether they want launch interest updates.
- **Subject:** Should we keep you in the loop?
- **Preheader:** Interest only. There is no launch access to give.
- **Body:**
  Simple one. Fault isn't out, and we can't give access we don't have.

  It's a solo push-up tracker being built Android-first: you count, you enter your own reps, results are self-reported and stay on your phone.

  Reply INTERESTED to `[REPLY_TO_ADDRESS]` and tell us your phone platform. If you'd rather stop, unsubscribe.
- **CTA:** Reply INTERESTED and tell us your phone platform → `[REPLY_TO_ADDRESS]`
- **Footer:** Unsubscribe: `[UNSUBSCRIBE_URL]` · Operator: `[OPERATOR_ADDRESS]` · Reply-to: `[REPLY_TO_ADDRESS]`
