# Free UGC-style video creation options — 2026-10-03

Research: 2026-10-03 · OpenCode (`opencode-go/deepseek-v4.1-flash`) ·
Status: **DRAFT, uncommitted, research only.** No source, config, test or
release file was changed. Nothing here changes
`docs/social/UGC_VIDEO_GENERATION_STRATEGY.md`; that doc is only quoted and
corrected below. Quotas, watermarks and licences change weekly — every number
here is a snapshot "checked 2026-10-03" unless a row says otherwise. Re-verify
before spending a production day on any of them.

Scope: where to create UGC-style vertical 9:16 clips (selfie hook / talking
head, workout reps, reaction to screen) for **$0**, for an app whose posts and
ads are commercial. That last word rules out a lot of "free": the usual free
tier is watermarked, non-commercial, or both.

Evidence labels:

- **[V]** verified from the cited primary page (official pricing page, official
  docs, official model card/GitHub licence, first-party API docs) on
  2026-10-03. Pages marked "search-index text" could not be fetched directly
  (Cloudflare/JS) and were read from the page's own text via the search index;
  see §12.
- **[E]** estimate or secondary source used only as a lead; not audited, not
  safe to plan around.
- **[I]** inference from the pages read in this pass.

## 0. Headline

**The strategy doc's engine list is half right and half stale, and none of the
free hosted tiers give commercial rights.** Three of the six named engines need
correction today: **Luma's free tier no longer exists** (pricing page lists
only $30/$90/$300 plans), **Hedra no longer advertises a free plan** (its
pricing page starts at Basic, paid), and **Kling's "66 free daily credits" is
not in Kling's own policy** — 66 is the *purchase rate* ($1 = 66 credits), the
free daily grant is an event/promo the policy explicitly declines to commit to,
free output is watermarked and the free terms forbid commercial use. Hailuo's
"free web tier" is real but is a queued, watermarked trial with no documented
recurring quota, and its old 100-credits/day era is gone. On the other hand,
**PixVerse and Dreamina have genuine recurring free credits** (mechanism
documented officially; PixVerse's amount is not), **Wan 2.2 is now Apache-2.0
and much better than the doc's Wan 2.1**, and **Hugging Face ZeroGPU is a real
but tiny free GPU: 5 minutes of GPU time per user per day**, not an unlimited
"free ZeroGPU".

For paid ads, the only genuinely free route with commercial rights is
**self-hosting Apache-licensed open weights** (Wan 2.2 / Wan-Animate-2 /
EchoMimic V3 / MultiTalk) on free compute (Kaggle ~30 GPU h/week, Colab T4,
ZeroGPU 5 min/day, ModelScope promo hours), plus **CapCut Free + Canva Free**
for editing and **Pexels/Mixkit** for real-footage B-roll. Everything else is a
drafting tool: use it to find the prompt, then re-render the keeper on Apache
weights. EU AI Act Article 50 has applied since 2026-08-02: the *advertiser*
deploying a deepfake (any realistic synthetic person) must label it — plan for
that on every asset.

## 1. Comparison

All allowances "checked 2026-10-03". "Commercial" = licence permits use in ads,
not just personal posting.

### 1.1 Hosted tools with a free tier (web/app)

| Option | Makes | Free allowance (checked 2026-10-03) | Resets | Watermark | Commercial / ad rights | Access | Evidence | Primary URL |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Kling AI | T2V / I2V | 66 credits/day is **not committed officially**; login credits are an "event" for subscribers; third-party reports 66/day for free accounts | 24 h if granted | Yes, free exports | **No** — free ToS forbids commercial use of output; paid members unrestricted | Web/app; no free API | [V] policy + ToS; [E] 66/day | https://kling.ai/docs/point-policy · https://kling.ai/docs/user-policy · https://kling.ai/docs/payment-policy |
| PixVerse | T2V / I2V, V6 audio | Daily credits + one-time signup bonus; **official docs confirm daily credits, not the amount**; 2026 third-party reports 60/day + 90 signup | Daily 0:00 UTC, expire same day | Yes (secondary) | Not permitted on free (secondary) | Web/app; separate paid API | [V] mechanism; [E] amount | https://docs.pixverse.ai/FAQ-Subscriptions-Billing-45723f6092f740bca8f0209878440ca1 |
| Dreamina (CapCut) | T2V / I2V / image | **120 credits/day** (official FAQ); shared across image+video | Daily | Yes on free; paid benefit "Remove the Dreamina watermark" | Not stated | Web/app | [V] 120/day | https://dreamina.capcut.com/ai-video/free-image-to-video-generator-credits-faq |
| Vidu | T2V / I2V, avatar/sing | Sign-up trial credits + **daily login credits**; amount not published officially; third-party history 20/day → 5/day | Daily | Yes (free tier 720p, secondary) | Paid only (secondary) | Web/app; paid API | [V] mechanism; [E] amount | https://www.vidu.com/pricing |
| Hailuo AI (MiniMax) | T2V / I2V | Free tier exists: queued, watermarked downloads; new-user welcome credits expire after 3 days; **no fixed daily quota documented**; launch-period daily free credits possible | Welcome credits expire in 3 days | Yes, free downloads | Not stated in agreement (secondary: no free commercial rights) | Web; API free tier is rate-limit only, not free clips | [V] terms + tool page | https://hailuoai.video/doc/payment-policy.html · https://hailuoai.video/tools/hailuo-2-3-model |
| Google Gemini / AI Studio (Veo) | T2V / I2V with audio | **No free Veo**; Gemini API free tier does not include Veo (Tier 1 examples show 10 RPD); Gemini app video generation is paid (AI Pro has a limited Veo 3.1 Lite trial) | — | — | Paid tiers | API (paid), app | [V] pricing/subscription pages | https://ai.google.dev/gemini-api/docs/pricing · https://gemini.google/subscriptions/ |
| Grok Imagine (xAI) | T2V / I2V, 15 s | Official grid: images on Free, **video not on Free**; free video appeared/unappeared by account in 2026 promos | — | — | Paid | Web/app + paid API | [E] grid quoted by secondaries | https://x.ai/pricing |
| Sora (OpenAI) | T2V | **Discontinued** — web/app gone 2026-04-26, API 2026-09-24 | — | — | — | — | [V] | https://help.openai.com/en/articles/20001152-what-to-know-about-the-sora-discontinuation |
| Pika | T2V / I2V / effects | **Free plan now 0 credits/month** (credit packs only) | — | No (free has no gens) | Commercial licence starts at Creator | Web | [V] | https://pika.art/pricing |
| Runway | T2V / I2V / editing | **125 credits one-time**, no refresh; limited model set; free output watermarked | Never | Yes | **Yes** — Runway grants commercial rights on all tiers incl. free | Web | [V] | https://help.runwayml.com/hc/en-us/articles/50404627334547-Free-plan-details · https://help.runwayml.com/hc/en-us/articles/18927776141715-Usage-rights |
| Luma (Dream Machine / Luma Agents) | T2V / I2V | **No free plan listed**; only Plus $30 / Pro $90 / Ultra $300 | — | Free/Lite legacy outputs watermarked, personal only | Paid (Plus+) | Web | [V] pricing page | https://lumalabs.ai/pricing |
| LTX Studio | T2V / storyboard / editing | 800 credits **one-time** for eligible new accounts; personal use only | Never | — | **No** — commercial starts at Standard $35 | Web | [V] help centre | https://help.ltx.io/hc/en-us/articles/32042304720146-Is-LTX-Studio-free |
| Krea | Image + video | 100 units/day; **video concurrency 0 on Free** (a video costs ~240 units, more than a day's allowance) | Daily | Watermarked (secondary) | No commercial licence on Free (secondary) | Web | [V] pricing page text | https://www.krea.ai/pricing |
| Wan.video (Alibaba cloud app) | T2V / I2V (Wan 2.x) | Daily check-in bonus credits per secondary sources; official pricing page is JS-only and could not be read | Daily (reported) | Not verified | Not verified | Web | [E] | https://wan.video/ |
| HeyGen | Talking avatar | **3 videos/month** (1–3 by region), ≤1 min, 720p share link, stock avatars; watermark removal is a paid benefit | Monthly | Yes on free | Not verified for free | Web; API paid | [V] pricing + help | https://www.heygen.com/pricing · https://help.heygen.com/en/articles/15125761-heygen-credit-based-pricing-plans-explained |
| Hedra | Talking head / lip sync | **No free plan shown on pricing page** (starts at Basic, paid); page title still says "Free Plan"; secondaries report a 100-credit one-time trial or 300/mo, watermarked, often disabled | — | Yes on trial | No on trial | Web; API paid | [V] pricing page; [E] trial | https://www.hedra.com/pricing |
| Synthesia | Avatar presenter | 10 min video/month + ~500 credits, 9 avatars, **cannot download MP4**, watermark | Monthly | Yes | Not usable for ads as delivered | Web | [V] pricing page (search-index text) | https://www.synthesia.io/pricing |
| D-ID | Talking avatar | **14-day trial only**, 3 min video, full-screen watermark, non-commercial; no ongoing free plan | — | Yes (trial + Lite) | Non-commercial on trial/Lite | Web; API paid | [V] FAQ + [E] trial detail | https://www.d-id.com/faqs/ · https://www.d-id.com/pricing/studio/ |
| Captions | Editing + AI models | Free editing + **60–200 lifetime credits** (don't refresh); all generative video models are paid-locked (❌ on Free) | Never | No watermark on manual edits | Editing rights, not model gen | iOS/web | [V] help docs | https://captions.ai/help/docs/ai-usage · https://captions.ai/help/docs/subscriptions |
| Argil | UGC avatar ads | **No free plan listed**; paid tiers only | — | — | Paid | Web | [V] docs/pricing | https://docs.argil.ai/resources/subscription-and-plans |
| Virbo (Wondershare) | Talking avatar | Free use: 2 min production, max 30 s per video, 720p, personal use only; free digital-human videos not licensed for commercial | One-time/free feature set | Marketing says no watermark; EULA restricts rights | **No** (EULA: personal only) | Web/desktop | [V] EULA | https://virbo.wondershare.com/virbo-eula-terms.html |
| Canva | Editing, Magic Video, AI clips | Magic Video included on Free (hourly limit); Magic Media video counts against AI allowance (Free: up to 200 Standard or 20 Premium AI uses/mo); "Create a video clip with Canva AI" is paid Ultra | Monthly (AI allowance, 1st 00:00 UTC) | Standard assets no watermark | Canva Free licence allows personal/commercial use of own designs, but Ultra video gen is paid | Web | [V] help + pricing | https://www.canva.com/help/ai-access/ · https://www.canva.com/help/magic-video/ |
| CapCut | Editing (+ some AI) | Free editor, 1080p export, no watermark on standard exports; premium assets add a watermark; free AI caps (auto-captions ≤10 min/video, AI Auto-Edit ~5/mo, background removal limited) | Monthly for AI credits | Only on Pro-flagged assets | Commercial use governed by CapCut terms/asset licences | Web/desktop/mobile | [V] help + [E] secondary | https://www.capcut.com/help/pricing-change · https://www.capcut.com/support |
| Viggle | Motion transfer / avatar | **5 free videos/day**, 1 at a time, 7-day asset storage; free exports watermarked; API new accounts get 100 free credits | Daily | Yes on free web; API output terms allow commercial use | Free web: not stated; API outputs commercially usable per developer terms | Web/app/Discord; API | [V] pricing + developers | https://viggle.ai/pricing · https://viggle.ai/developers |
| Vmake | Editing / video enhance | Not verified this pass | — | — | — | Web | [E] | https://vmake.ai/ |

### 1.2 Open-weight models (self-host or free hosted demos)

| Model | Task | Licence (checked 2026-10-03) | Commercial? | VRAM / notes | Evidence | Primary URL |
| --- | --- | --- | --- | --- | --- | --- |
| Wan 2.2 TI2V-5B | T2V + I2V, 720p24 | **Apache 2.0**; authors claim no rights over outputs | Yes | 24 GB (RTX 4090), 5 s in <9 min | [V] | https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B |
| Wan 2.2 I2V-A14B / T2V-A14B | I2V / T2V 480p–720p | Apache 2.0 | Yes | 14B active MoE, needs offload; 80 GB comfortable | [V] | https://github.com/Wan-Video/Wan2.2 |
| Wan2.2-Animate-14B / Animate-2-14B | Motion transfer / character replacement | Apache 2.0 | Yes | 14B; space demo exists | [V] | https://huggingface.co/Wan-AI/Wan2.2-Animate-14B · https://huggingface.co/Wan-AI/Wan2.2-Animate-2-14B |
| LTX-Video 13B (0.9.8) | T2V / I2V | LTXV Open Weights Licence: free for entities <$10M annual revenue | Yes under threshold | 13B distilled/fp8 variants | [V] licence text | https://huggingface.co/Lightricks/LTX-Video |
| HunyuanVideo / 1.5 | T2V | Tencent Hunyuan Community Licence; **does not apply in EU, UK, South Korea**; commercial free <100M MAU | Yes outside excluded regions | needs big VRAM; fp8 ~10 GB savings | [V] licence text | https://github.com/Tencent-Hunyuan/HunyuanVideo-1.5/blob/main/LICENSE |
| CogVideoX-2B | T2V | **Apache 2.0** | Yes | runs on older GPUs incl. GTX 1080Ti | [V] | https://github.com/zai-org/CogVideo |
| CogVideoX-5B / 1.5-5B | T2V / I2V 768–1360px | CogVideoX Licence: free commercial only after registering; ≤1M visits/month | Registration required | diffusers from ~5 GB with offload | [V] licence text | https://huggingface.co/zai-org/CogVideoX-5b/blob/main/LICENSE |
| Mochi 1 (preview) | T2V 480p | **Apache 2.0** | Yes | 10B AsymmDiT, heavy | [V] | https://huggingface.co/genmo/mochi-1-preview |
| EchoMimic V3 | Audio-driven talking head/body | **Apache 2.0** | Yes | **12 GB VRAM**, up to 768×768; V1 repo says "academic research" in its disclaimer | [V] | https://github.com/antgroup/echomimic_v3 |
| MultiTalk / LongCat-Video-Avatar 1.5 | Multi-person talking / lip sync | **Apache 2.0** | Yes | built on Wan 2.1 14B; A100 Colab example | [V] | https://github.com/MeiGen-AI/MultiTalk |
| SadTalker | Talking head from one image | **Apache 2.0**; non-commercial restriction removed | Yes | old, low-res-ish | [V] README | https://github.com/OpenTalker/SadTalker |
| LivePortrait | Portrait animation | Repo lists licence "Other"; MIT wrapper notes pretrained weights/training data and the InsightFace detection dependency are **non-commercial** | **Risky — no** until InsightFace is replaced | ~4 GB VRAM reportedly works | [V] repo + wrapper warning | https://github.com/KwaiVGI/LivePortrait |
| MimicMotion | Pose-driven human video | Tencent weights: **academic/research only, no commercial** | **No** | — | [V] licence text | https://huggingface.co/tencent/MimicMotion/blob/main/LICENSE |
| HunyuanVideo-Avatar | Audio-driven avatar | Tencent Hunyuan community family (see card); expect territory limits | Outside EU/UK/KR only | very heavy | [E] | https://huggingface.co/tencent/HunyuanVideo-Avatar |

### 1.3 Free compute for the open weights

| Platform | Free allowance (checked 2026-10-03) | Limits/caveats | Evidence | Primary URL |
| --- | --- | --- | --- | --- |
| Hugging Face ZeroGPU Spaces | **Free account 5 min GPU/day**; unauthenticated 2 min/day; PRO 40 min/day (+$1/10 min credits); resets 24 h after first use | RTX Pro 6000 Blackwell 48 GB (`large`) or 96 GB (`xlarge`, 2× quota); Gradio-only; free hosting of your own Space needs verified email + 30-day-old account, max 2 | [V] | https://huggingface.co/docs/hub/spaces-zerogpu |
| Google Colab free | T4-class GPU, **max 12 h runtime**, idle timeouts; no published quota | "Deepfakes" are explicitly prohibited; content generation via web UI outside notebook programming can be terminated; GPU types vary | [V] | https://research.google.com/colaboratory/faq.html |
| Kaggle Notebooks | **~30 GPU h/week** (floating, can be higher with demand), P100 or T4; sessions up to ~9 h | Must be signed in; quota resets weekly Saturday 00:00 UTC | [V] | https://www.kaggle.com/docs/efficient-gpu-usage · https://www.kaggle.com/page/GPU-tips-and-tricks |
| ModelScope Notebook | Free CPU always; limited free NVIDIA 24 GB hours; AMD 192 GB ~100 h campaign | Requires binding an Alibaba Cloud account; session ≤10 h; free tier reported non-commercial; quotas vary by account/promo | [E] | https://modelscope.cn/ (Notebook docs; official quota page is China-region) |

### 1.4 Free real-footage sources (for genuine human B-roll)

| Source | Licence | Commercial ads? | Caveats | Evidence | Primary URL |
| --- | --- | --- | --- | --- | --- |
| Pexels | Pexels Licence (non-CC0 content) / CC0 for marked content | **Yes**, no attribution required | No selling unaltered copies; no implied endorsement by people/brands; consent may be needed for identifiable people in promotional use | [V] help text | https://help.pexels.com/hc/en-us/articles/360042295214-Can-I-use-the-photos-and-videos-for-a-commercial-project |
| Pixabay | Pixabay Content Licence (CC0 for pre-2019) | **Yes**, no attribution | No standalone resale; trademark/brand content restricted; model/property releases are your responsibility | [V] | https://pixabay.com/service/license-summary/ |
| Mixkit | Stock Video Free Licence vs Restricted Licence | **Yes for Free-licence items** (YouTube, social marketing, ads); Restricted = personal only | Can't resell unaltered; some items include third-party rights | [V] | https://mixkit.co/license/ |

## 2. Hosted free tiers — the detail that matters

1. **Kling AI (kling.ai).** The strategy doc's "66 free daily credits" is not a
   documented free allowance. The Credits Policy, fetched 2026-10-03, uses 66
   only as a purchase rate ("Standard Pricing: $1 USD = 66 Credits") and
   describes login credits as "During the event … Kling subscribers can claim
   daily credits", amount "subject to platform announcement" [V]. The free
   account has been widely reported at 66/day, reduced from 166, with
   eligibility varying by region/account and some accounts losing it in
   February 2026 [E]. The free account's output is watermarked, watermark
   removal is premium-only [V policy §8], and the User Policy §4.6 says that
   without written permission you may not use Output "for any commercial
   purposes", while the Paid Service terms confirm members' commercial use is
   unrestricted [V]. **Rule for us: Kling free = prompt testing only, never a
   shipped ad.**
2. **PixVerse (pixverse.ai).** Official docs confirm the credit types: daily
   credits renew 0:00 UTC and expire same day; monthly credits expire end of
   billing period; purchased credits are for subscribers only [V]. The amount
   is not in the docs read; 2026 third-party reports converge on 90 signup +
   60/day but one says the daily refresh decays and free exports carry no
   visible watermark, contradicting older reports — treat any number as [E]
   and check the app balance. Free resolution/awards are low (540p reported).
3. **Dreamina (dreamina.capcut.com).** The strongest documented recurring
   free allowance found: an official FAQ page states **120 credits/day for
   free users** across image and video, with no fixed clip count because model
   and settings choose the burn rate [V]. Paid plans list watermark removal as
   a benefit, implying free exports are watermarked [V pricing page]. This is
   the best "every day, no card" drafting tool in the list.
4. **Vidu (vidu.com).** Official pricing page states new users get trial
   credits and can "earn credits by logging in every day" but publishes no
   amount [V]. Community history: 20/day, cut to 5/day in September 2025 [E].
   Vidu's own blog describes free output as 720p, watermarked, personal use
   only [E search-index]. Best treated as too small to plan around.
5. **Hailuo AI / MiniMax.** The Payment Policy (fetched via search index,
   2026-10-03) says free users get basic features, sequential queue, and
   **watermarked downloads**; paid plans add credits, watermark-free downloads
   and priority. New users registered from 2025-06-18 get a one-time welcome
   package that expires three days after grant [V]. The old "100 credits/day"
   era is over; the Hailuo 2.3 tool page only promises daily free trial
   credits "during launch periods" [V]. Do not plan a daily cadence on it.
6. **Google Veo.** The Gemini API pricing page lists free-of-charge tiers for
   several models but Veo is billed; developer-forum screenshots show Veo 3
   Fast at RPD 10 on Tier 1 (paid) [V pricing page; E forum]. The Gemini app
   gives video generation to paid AI plans (Pro has a limited Veo 3.1 Lite
   trial, Ultra unlocks Veo 3.1) [V]. Google Vids free is separately reported
   at 10 videos/month [E]. There is no free Veo pipeline worth building.
7. **Grok Imagine.** xAI's own pricing grid reportedly checks image generation
   on Free and dashes video generation; free accounts in 2026 received one
   video/day in some cohorts and nothing in others, and xAI publishes no
   number [E — page not fetched]. Do not rely on it.
8. **Sora is dead.** OpenAI's help centre: web/app discontinued 2026-04-26,
   API 2026-09-24 [V]. Any 2026 guide still recommending Sora is stale.
9. **Pika, Runway, Luma, LTX Studio, Krea.** Pika's free tier grants zero
   monthly credits now [V]. Runway free keeps a one-time 125-credit deposit,
   no refresh, watermarked output, but *does* grant commercial rights to
   outputs on every tier [V] — a small but legally clean amount of test
   footage. Luma has no free plan on its pricing page [V]. LTX Studio's free
   route is 800 one-time credits, personal use only [V]. Krea free gives
   100 units/day and explicitly 0 video concurrency [V], so it cannot generate
   video on free in practice (a video is ~240 units).
10. **Talking-head platforms (HeyGen, Hedra, Synthesia, D-ID, Virbo).**
    HeyGen free: 3 videos/month, ≤1 min, 720p, watermark removal paid [V].
    Hedra: the pricing page fetched 2026-10-03 shows only paid plans
    ($20/$50/$100 or $15/$30/$75 depending on render — the page is
    inconsistent), and the "Free Plan" in the title is not in the page body;
    secondary reviews disagree between a 100-credit one-time and 300/month
    trial, watermarked and non-commercial, "often disabled" [E]. Synthesia
    free: 10 min/month but **no MP4 download at all**, so it cannot produce a
    shippable file [V]. D-ID: 14-day trial only, 3 minutes, non-commercial
    [V FAQ + E]. Virbo free: 2 min, 30 s max, 720p, EULA says Standard
    (free) is personal use only [V]. **None of these free tiers is an ad
    pipeline.**
11. **Captions, Canva, CapCut.** Captions free is editing-only with lifetime
    credits [V]. Canva Free includes Magic Video but the 4-second AI video
    clip generation is paid Ultra, and all AI draws from a monthly 200/20-use
    allowance [V]. CapCut Free is the best free editor of the three: full
    timeline, 1080p exports, no watermark on standard content, some free AI
    (auto-captions ≤10 min) [V official + E secondary].
12. **Viggle.** Free web: 5 videos/day, one at a time, 7-day storage,
    watermarked exports [V pricing]. The developer side is more interesting:
    new API accounts get 100 free credits and the API page states outputs can
    be used commercially (subject to API terms and underlying rights) [V] —
    worth a test if the motion-transfer quality is good enough for workout
    reps.

## 3. Open weights — the only free path with clean ad rights

- **Wan 2.2 is the workhorse.** TI2V-5B does 720p24 T2V+I2V on a 24 GB
  consumer card (5 s in under 9 minutes per the model card) under Apache 2.0
  with no claim on outputs [V]. The I2V-A14B is the quality option on bigger
  cards. This replaces the strategy doc's Wan 2.1 recommendation.
- **Wan2.2-Animate(-2)-14B** is the Viggle-style motion transfer model:
  input video + character image → animation or replacement, Apache 2.0 [V].
  This is how Type B (reps) gets 100% correct biomechanics without a paid
  rig: film a real push-up on a phone, animate the synthetic character onto
  it.
- **EchoMimic V3 / MultiTalk / SadTalker** cover Type A (hook/talking head)
  under Apache 2.0; V3 runs in 12 GB VRAM [V].
- **CogVideoX-2B, Mochi 1** are Apache 2.0 but older/slower; CogVideoX-5B and
  LTX 13B allow free commercial use with conditions (registration /
  <$10M revenue); HunyuanVideo is unusable in the EU/UK/South Korea per its
  own licence; MimicMotion weights are research-only; LivePortrait's
  InsightFace dependency makes its commercial status unclear — avoid for ads.
- **Licence hygiene:** for every model, keep the model card URL + licence text
  with the asset. Apache-2.0 models (Wan family, EchoMimic V3, MultiTalk,
  SadTalker, CogVideoX-2B, Mochi) are the recommendation precisely because
  they do not have revenue, territory or registration conditions.

## 4. Free compute — what "free GPU" actually buys

- **HF ZeroGPU is the best turnaround.** 5 GPU-min/day per free account on a
  Blackwell 48 GB (96 GB at 2× quota cost), queue priority by remaining quota,
  quota resets 24 h after first use [V]. A Wan 2.2 5-second render often fits
  in one 60–120 s slot, so a free account can realistically get a few renders
  a day across the many Wan/EchoMimic/Animate Spaces; use several accounts
  only within HF's terms. Relevant public Spaces found this pass:
  `Wan-AI/Wan2.2-Animate`, `zerogpu-aoti/wan2-2-fp8da-aoti`,
  `fffiloni/Meigen-MultiTalk`, plus the curated list
  `huggingface.co/spaces/enzostvs/zero-gpu-spaces` [V URLs].
- **Kaggle** is the volume option: ~30 GPU h/week (floating), P100/T4, ~9 h
  sessions, free [V]. Batch renders overnight; download outputs before the
  session ends.
- **Colab free** gives T4-class with max 12 h runtimes and no published quota,
  but its FAQ explicitly bans "creating deepfakes" and can terminate runtimes
  that are not interactive programming [V]. Synthetic-person generation is
  legal in most contexts with disclosure, but Colab's house rules make it a
  riskier host than Kaggle for this use case; keep the work as notebook code.
- **ModelScope** offers free NVIDIA 24 GB and campaign AMD 192 GB hours in
  exchange for binding an Alibaba Cloud account; quotas move and the free tier
  is reportedly non-commercial [E]. Use only after checking the account's own
  quota page.

## 5. UGC-specific app free plans — quick verdicts

| App | Free verdict |
| --- | --- |
| Captions | Editing only; AI models locked |
| Argil | No free plan |
| HeyGen | 3 watermarked videos/month — testing only |
| Hedra | Free plan no longer advertised; trial terms inconsistent |
| Synthesia | No download on free — not usable |
| D-ID | 14-day non-commercial trial |
| Vmake | Not verified; no primary pricing page read this pass [E] |
| Virbo | 2 min, 30 s clips, personal-use EULA |
| Canva | Free editing/Magic Video; AI video-clip gen is paid |
| CapCut | Best free editor; standard exports watermark-free at 1080p |
| Viggle | 5 watermarked videos/day; API has 100 free credits with commercial terms |

## 6. Caveats that kill "free"

- **Commercial rights are the cliff, not credits.** Kling free, Vidu free,
  PixVerse free, Hailuo free, Synthesia free, D-ID trial, LTX Studio free,
  Krea free, Virbo free and Hedra trial are all personal/limited-use only.
  Running them in a paid ad is a licence breach even at $0. Apache-2.0
  self-hosting and Runway's free 125 credits are the exceptions found.
- **Watermarks.** Kling, Hailuo, Viggle, Runway, HeyGen, Synthesia, D-ID and
  most trials burn a visible mark into exports; removal is a paid toggle.
  A watermark usually also voids the "authentic UGC" look.
- **One-time vs recurring.** Runway 125 credits, LTX Studio 800 credits,
  Captions 60–200 credits, D-ID 3 min and the Hailuo welcome pack are
  one-time. Kling/PixVerse/Dreamina/Vidu (mechanisms), Colab, Kaggle and
  ZeroGPU reset on their own schedule. Anything "one-time" is a test, not a
  pipeline.
- **Signup gates.** Colab/Kaggle/HF need accounts (Kaggle needs phone
  verification for some features); ModelScope needs an Alibaba Cloud account
  binding; most consumer apps need only email but region-gate features
  (Sora never launched in the UK/CH/EEA before it was discontinued; Hunyuan
  licence excludes EU/UK/South Korea; Sora's UK gap is a warning about how
  normal region locks are).
- **Queues.** Free tiers are lowest priority by design (Kling "currently
  busy" reports, Hailuo sequential queue, Runway free model subset). Budget
  wall-clock time, not credit count.
- **AI-content labelling is now law in the EU.** Article 50 of the AI Act has
  applied since 2026-08-02: deployers of a deepfake (any realistic
  AI-generated person) must disclose it clearly at first exposure, and video
  needs the label at the start and at regular intervals; the Commission's
  optional EU icons ("AI GENERATED"/"AI MODIFIED") are the sanctioned label
  [V EC pages]. TikTok requires labels on realistic AIGC and offers an
  AIGC self-disclosure toggle for ads [V TikTok]. So even a perfect synthetic
  hook must ship with a visible AI label in the EU/UK and on TikTok — plan the
  edit so the label doesn't read as a bug.

## 7. Corrections to `docs/social/UGC_VIDEO_GENERATION_STRATEGY.md` (checked 2026-10-03)

| Strategy doc claim | Verdict | Correct value | Source |
| --- | --- | --- | --- |
| "Kling AI — 66 Free Daily Credits" | **Stale/misleading** | 66 is the *purchase rate* ($1 = 66 credits). Daily login credits are event-based and the policy does not promise free users any grant or amount; free output is watermarked and non-commercial; eligibility varies by account/region | kling.ai/docs/point-policy [V], kling.ai/docs/user-policy [V] |
| "Hailuo AI / MiniMax Video-01 — Free Web Tier" | **Vague but real; quotas gone** | Free tier is queued + watermarked; no recurring daily quota documented; one-time new-user welcome credits expire after 3 days; launch-period daily credits are temporary | hailuoai.video/doc/payment-policy.html [V] |
| "Wan 2.1 14B / 1.3B — Free ZeroGPU on Hugging Face / Colab" | **Outdated + imprecise** | Use Wan 2.2 (TI2V-5B / I2V-A14B, Apache-2.0, 24 GB for 5B). ZeroGPU free allowance is exactly 5 GPU-min/day per free account (2 min unauthenticated, 40 min PRO), not unlimited | HF ZeroGPU docs [V]; Wan2.2 model cards [V] |
| "Hedra — Free Daily Talking Head Spaces" | **Wrong today** | Hedra's pricing page lists only paid plans; no free daily tier advertised. Free trials reported inconsistently and often disabled | hedra.com/pricing [V] |
| "Luma Dream Machine — 30 Free Monthly Generations" | **Stale** | Luma's pricing page lists no free plan at all (Plus/Pro/Ultra only); legacy free generation is gone | lumalabs.ai/pricing [V] |
| "Viggle AI — Free Discord / Web Tier" | **Correct mechanism, missing limits** | 5 free videos/day on web, 1 concurrent, 7-day storage, watermarked exports; API new accounts = 100 free credits, API terms allow commercial use | viggle.ai/pricing [V], viggle.ai/developers [V] |
| "Wan guarantees biomechanics" via Viggle-style transfer | **Better free option exists** | Wan2.2-Animate(-2)-14B (Apache-2.0) does the same character-in-video motion transfer with commercial rights | HF model cards [V] |
| "4 Gemini Pro accounts for quotas / Imagen 3" | **Not a Veo plan** | Gemini API free tier does not include Veo; video generation is paid (Gemini app AI plans, or AI Studio billing). Image quota stacking is unaffected by this note | ai.google.dev pricing [V], gemini.google/subscriptions [V] |

## 8. Best $0 stack for Training Arena

Covering the strategy doc's three asset types with commercial rights and no
card. Accept that the tradeoff is manual notebook work and queues — this stack
buys licence cleanliness, not convenience.

1. **Type A — Hook / talking head: EchoMimic V3 (Apache-2.0) on Kaggle or a
   ZeroGPU Space.** 12 GB VRAM fits a free Kaggle T4/P100 session; image +
   audio in, talking head out, commercial use allowed. *Tradeoff:* slow and
   manual (download weights, run notebook), lower polish than Hedra/HeyGen,
   and voice audio must still be produced separately (CapCut free TTS or a
   recorded scratch read).
2. **Type B — Phone setup & reps: Wan 2.2 TI2V-5B I2V on ZeroGPU/Kaggle, or
   Wan2.2-Animate-2 with a phone-shot reference rep.** Apache-2.0, 720p24,
   clean ad rights. *Tradeoff:* 24 GB VRAM locally; on free compute you take
   the queue and the 5 min/day ZeroGPU ceiling, so batch on Kaggle (~30 h/wk).
3. **Type C — Fatigue & reaction: Dreamina free 120 credits/day for drafts,
   final keeper re-rendered on Wan/LTX-Video (if within licence) or Wan 2.2.**
   Dreamina is the fastest free iteration loop documented [V]. *Tradeoff:*
   Dreamina free is watermarked and its commercial terms are unstated, so it
   is a storyboard tool; the shippable render comes from the open model.
4. **Reps biomechanics assist: film a real push-up/squat yourself (phone) and
   Wan2.2-Animate the synthetic character onto it.** Real motion, synthetic
   face. *Tradeoff:* you must shoot reference footage; free compute steps.
5. **Real-footage B-roll + editing: Pexels/Mixkit (commercial-safe) and
   CapCut Free (1080p, no watermark on standard exports).** Covers cutaways,
   gym B-roll, captions and 9:16 assembly. *Tradeoff:* CapCut premium assets
   watermark themselves; stick to free assets.
6. **Compliance layer (free, non-optional): label every synthetic-person clip
   for EU AI Act Art. 50 and TikTok/Meta disclosure before posting.** Use the
   EU "AI GENERATED" icon or an equivalent clear label at first exposure and
   at intervals. *Tradeoff:* slightly less "organic" look — mandated anyway.

Skipped on purpose: every hosted "free UGC" app with watermark +
non-commercial terms (Kling free, Hailuo free, HeyGen free, Synthesia free,
D-ID trial, Virbo), because shipping an ad with them is a licence breach, not
a cost saving. Runway's free 125 one-time credits are a legitimate exception
for a handful of test shots (commercial rights granted) but not a pipeline.

## 9. Sources / verification notes

Method: web search (2026 queries) to locate primary pages, then direct fetch
of the primary page where possible, on 2026-10-03. Quotas change monthly;
re-check before production. Pages that could not be fetched directly from this
session and were read via the search index's rendering of the page are marked
below.

Directly fetched (webfetch/bash curl) on 2026-10-03:

- Kling Credits Policy — https://kling.ai/docs/point-policy
- Luma pricing/landing — https://lumalabs.ai/pricing, https://lumalabs.ai/app
- Hedra pricing — https://www.hedra.com/pricing (paid plans only; no Free in
  the body despite the page title)
- HF ZeroGPU docs — https://huggingface.co/docs/hub/spaces-zerogpu
- HF Spaces GPU docs — https://huggingface.co/docs/hub/spaces-gpus
- Colab FAQ — https://research.google.com/colaboratory/faq.html
- Wan 2.2 TI2V-5B model card — https://huggingface.co/Wan-AI/Wan2.2-TI2V-5B
- Kling ToS/payment document fetch returned empty (JS app); their text was
  read from the search index.

Read via search-index text of the official page (could not be fetched
directly — Cloudflare/JS/tool timeouts):

- Kling User Policy / Paid Service terms (kling.ai/docs/user-policy,
  /docs/payment-policy)
- PixVerse billing FAQ (docs.pixverse.ai; page is Notion/JS)
- Dreamina free-credits FAQ and pricing (dreamina.capcut.com)
- Vidu pricing (vidu.com/pricing — FAQ text only; amounts not published)
- Hailuo Payment Policy (hailuoai.video/doc/payment-policy.html)
- Google Gemini API pricing and rate limits (ai.google.dev), Gemini
  subscriptions (gemini.google/subscriptions)
- Runway pricing/help (runwayml.com, help.runwayml.com)
- Pika pricing (pika.art/pricing)
- LTX Studio help/pricing (ltx.io, help.ltx.io)
- Krea pricing (krea.ai/pricing)
- HeyGen pricing/help (heygen.com, help.heygen.com)
- Synthesia pricing (synthesia.io/pricing)
- Captions help docs (captions.ai/help/docs/*)
- Argil docs (docs.argil.ai)
- Viggle pricing/developers/terms (viggle.ai)
- Virbo EULA (virbo.wondershare.com)
- Canva help/pricing (canva.com/help/*)
- CapCut help (capcut.com/help/pricing-change)
- Wan2.2 GitHub, Wan2.2-Animate model cards, LTX-Video licence, HunyuanVideo
  licences, CogVideoX licence, Mochi model card, EchoMimic GitHub,
  MultiTalk GitHub, SadTalker GitHub, MimicMotion licence, LivePortrait
  GitHub
- Pexels help centre (help.pexels.com; pexels.com/license is Cloudflare-
  blocked), Pixabay licence summary, Mixkit licence
- EC AI Act Article 50 pages and EU icons page
  (digital-strategy.ec.europa.eu, ai-act-service-desk.ec.europa.eu)
- TikTok AI-generated content help/safety pages and Business API AIGC toggle

Could not verify from a primary source (do not plan on these without checking
in the product):

- The exact PixVerse free credit amount (official docs confirm the mechanism
  and reset; the 60/day + 90 signup figure is third-party [E]).
- The exact Vidu daily credit amount (official page confirms daily login
  credits, not the number) [E].
- Whether Kling currently grants 66 free credits/day to a given account
  (policy declines to commit; third-party reports only) [E].
- Hedra's trial size (100 one-time vs 300/month reports conflict; pricing page
  shows no free plan) [E].
- Grok Imagine free video availability (x.ai/pricing not fetched; secondaries
  report images-only on the published grid and cohort-dependent promo video)
  [E].
- Wan.video app daily check-in credit amount and licence (JS-only official
  page) [E].
- Vmake free plan (no primary pricing page read) [E].
- Runway free-plan current model list and whether the 125 credits currently
  buy any Gen-4.5 clip (model access is limited on Free) [E].
- ModelScope exact free GPU hours (official page is China-region; forum/blog
  figures range 36 h NVIDIA to 100 h AMD) [E].
- Meta/Facebook AI-content ad disclosure policy text was not read this pass —
  only TikTok's was verified. Add before running Meta ads.
- Google Vids free "10 videos/month" (secondary only; no official page read)
  [E].
- Pexels licence page text was read from the search index because
  pexels.com/license is Cloudflare-protected; the help-centre article was
  also read via search index [E, official wording].
