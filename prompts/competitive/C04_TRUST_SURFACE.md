# C04 — Trust surface: verified rep, no recording, server-confirmed result

Status 2026-09-23: **audited; trust copy already shipped since L01.** Added
the forbidden-claims copy guard and the audit record; nothing user-facing was
rewritten. Record: `qa/competitive/c04/REPORT.md`.

Depends on: nothing for code; use C00's decision record for wording rules.
Estimate: 4–8 h.

Include the common preamble from `prompts/competitive/README.md`.

## Skills to load

- `accessibility` — status text must not rely on colour alone; contrast and
  content descriptions for the new labels.
- `tdd` — the copy scan and the result-state labels get tests.

## Goal

Make the product's real advantage visible. The category's two live user fears
are cheating and being recorded (analysis §2 review themes), and Training
Arena's actual architecture answers both: server-confirmed results and
on-device processing with no video upload (`docs/privacy/DATA_INVENTORY.md`).
This task surfaces that truthfully wherever the user already is; it does not
invent badges the build cannot back.

Scope:

1. **Audit first.** Read the current user-facing strings in the result screen,
   settings, camera guidance and share flows. Report what already exists
   before changing anything — do not duplicate an existing statement.
2. **Result screen.** State that the result is server-confirmed (it is) and
   name the counterparty check as factual copy; no "cheat-proof", no accuracy
   figure.
3. **Settings / privacy.** One plain-language block: processing on device, no
   video or frames uploaded, what is stored and the link to the existing
   privacy page. Every sentence must be traceable to
   `docs/privacy/DATA_INVENTORY.md`; if a sentence cannot be traced, delete the
   sentence, do not soften the inventory.
4. **Honest counting language.** Only if C05 has landed depth/partial-rep
   behaviour, label it accurately ("reps that do not reach depth may not
   count"). If C05 has not landed, do not describe behaviour that does not
   exist.
5. **Copy guard.** A small test that scans user-facing string constants for the
   forbidden terms (accuracy %, cheat-proof, guaranteed, medical/fitness
   transformation) so the rule survives future edits.

## Owned paths

User-facing string files in `app/lib/` for the named surfaces, one new copy
test under `app/test/`, `qa/competitive/c04/`.

## Must not

- Claim anything the inventory or the code does not support.
- Use the words "cheat-proof", "100% accurate", "AI-verified" or any accuracy
  percentage.
- Touch camera behaviour, counting thresholds or release flags.
- Rewrite the privacy inventory or public pages.

## Acceptance

- An audit list in the handoff: existing statements, what was added, what was
  deliberately left alone.
- Every new claim has a pointer to the code or inventory line that proves it.
- Copy test fails on the forbidden terms and passes on the current strings
  (show both runs).
- `flutter analyze` and the full test suite pass.
- Screenshot of the updated result and settings surfaces under
  `qa/competitive/c04/`.

## Handoff

Standard handoff, including the audit list and the exact provenance of each
new claim.
