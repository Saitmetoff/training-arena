# 14 — Web battle approach (C08 spike)

Date: 2026-09-23 · Phase 1 spike only; no production change, no dependency,
no hosted artifact. The measured prototype could not be run in this session
(no browser/mobile measurement environment); device numbers are **not
measured** and are marked accordingly.

## Question

Can a challenged friend without the app complete a fair round in the browser,
or should `challenge-web/` stay an accept/install funnel?

## Verified facts

- MediaPipe Pose Landmarker ships as `.task` bundles: lite ~5.8 MB, full
  ~9.4 MB as served (Google CDN, verified against the public catalog and
  independent measurements, 2026-08-02). Model-card sizes (3/6/26 MB) are the
  landmark model alone, not the served bundle. `[V]`
- The web runtime is WASM + WebGL with no WebGPU requirement; documented
  support includes Chrome/Edge 80+, Firefox 75+, **Safari 14+** (module
  workers 16.4+). `[V]` (vendor documentation, not independently measured)
- `getUserMedia` is Baseline widely available since September 2017, requires
  a secure context, and on iOS Safari has documented regressions in
  standalone/PWA display mode (WebKit bug 273938, recurring across 17.x). `[V]`
- **Not measured here**: model load time, sustained FPS on a mid-range
  Android, battery behaviour, or iOS Safari in-app behaviour. Any claim about
  them would be invented.

## The real cost is divergence, not the model

`app/lib/camera/counter/rep_counter.dart` is ~500 lines of pure Dart with
framing, hysteresis, dwell, duration, debounce, body-straightness, confidence
and stall rules, and it is the product's differentiator (server-confirmed,
honest counting). A browser battle needs that logic in JavaScript or WASM:
a second implementation to keep in sync with every threshold change, plus the
same server-receipt semantics. The model download is the small problem.

## Options

| Option | Shape | Verdict |
| --- | --- | --- |
| A. Full browser battle | In-browser pose + the existing realtime match channel | **Reject for now**: duplicate counting logic, unmeasured device performance, iOS Safari risk, and the fairness claim would rest on an unverified second implementation |
| B. Browser solo demo (no opponent) | Count reps in the browser as a marketing demo | **Defer**: same duplication for a demo; revisit only if content shows the demo converts installs |
| C. Keep the web as accept/install funnel | Improve install conversion and link recovery instead | **Recommended** |
| D. View-only spectate | Watch a live match in the browser | **Reject**: needs realtime cost and accounts for a feature nobody asked for |

## Recommendation

**C now.** The funnel's measurable gap is install drop-off, which
`docs/social/CONTENT_EXPERIMENT.md` §7 currently marks NOT INSTRUMENTED. Fix
the measurement before adding a second counting implementation.

If the owner wants A later, the spike's open questions are exactly: model
load time and FPS on a mid Android, iOS Safari in standalone mode, the
divergence plan for the counter, and whether a browser result can be
server-confirmed with the same receipts.

## Owner decision

- [ ] Accept C (recommended) — no browser battle work.
- [ ] Approve a measured A spike on real devices (new task, with the
      divergence plan written first).
- [ ] Other:
