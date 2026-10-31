# Aggregate patterns — iteration 2026-10-04-01

**Real snapshots (observed).** `aggregates.json:4` production_database is all-zero (`rows:0` … `eligible:0`); `:7` baseline_eligible 0; `:8` net_eligible_change_since_baseline 0, measured from baseline `:6` 2026-10-04T16:24:11Z to snapshot `:3` 2026-10-04T17:02:02Z. `:14` note 3 states this is a 38-minute observation, not daily growth. `:10` resend all zero. `:9` posthog fault_events_observed false; saved_funnel `BtxaDFUN` = "No data recorded for this time period". `:13` release public false, collection_enabled false, protected_preview true.

**Absent measurements (cannot infer).** `:11` video views null and no connected analytics tool, owner export or approved footage. `:12` all rates null. No measured denominator exists anywhere in the snapshot, so rates are undefined, not zero percent (`:14` note 2). `:9` coverage is development/preview, consented analytics only, not all traffic. `:14` note 1: zero recorded analytics is not zero actual visits. The brief supplies no source/device ranking or conversion estimate, and none may be manufactured.

**Hypotheses (unvalidated).** That a concrete return reason lifts repeat sets; that confirmation-first CTA improves valid confirmed yield. Both are untested — the experiment in `creative-brief.md:15` is preview-only after release gates. No winner exists and no causal claim is supported.

**Net pattern:** a genuinely empty, pre-release system with a protected preview and disabled collection. The honest read is "no measurement yet" — not zero demand and not evidence of traction.
