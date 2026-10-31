# C04 — trust surface: audit and copy guard

Date: 2026-09-23 · Executor: OpenCode (`opencode-go/deepseek-v4.1-flash`).

## Audit first (the prompt required reporting before changing)

The trust statements were already shipped in the L01 freeze; this task adds
the missing guard and records the audit. Nothing was rewritten.

| Surface | Existing statement | File |
| --- | --- | --- |
| Settings / privacy | "Camera frames stay on this device and are never uploaded. Only rep counts reach the match score. Public profile content is username, rating and an optional avatar." | `app/lib/account/ui/settings_page.dart:321` |
| Live round | "Frames are processed on this device and never uploaded. Only rep counts leave the phone." | `app/lib/battle/ui/battle_flow_page.dart:363` |
| Result | "Scores are confirmed by the server. Camera frames never leave the device." | `app/lib/battle/ui/battle_flow_page.dart:797` |
| Camera guidance | "Training Arena counts reps privately on this phone. No video ever leaves the device." | `app/lib/camera/camera_types.dart:369-372` |
| Challenge entry | "Your camera stays on your phone" / "Camera frames are processed on your device and never uploaded. Only rep counts are sent to the match score." | `app/lib/linking/challenge_entry_view.dart:183-185` |
| Challenge result | "result confirmed by the server." | `app/lib/linking/challenge_entry_view.dart:154` |
| Solo | "Solo sets are practice: no receipt, no rating, no leaderboard. Results stay on this device." | `app/lib/solo/ui/solo_page.dart` |

## What was added

- `app/test/copy/forbidden_claims_test.dart`:
  - fails on any lib/ string literal containing `cheat-proof`, `cheat proof`,
    `guaranteed`, `guarantee`, `medically proven`, `clinically proven`,
    `fda approved`, `fda-approved`, or a numeric accuracy claim such as
    `98% accurate`;
  - asserts the on-device statement still exists in the camera guidance and
    settings, so a future edit cannot silently drop it.
- Heuristic documented in the test header: single-line literals only; the
  guard is a tripwire, not a parser.

## Deliberately not done

- No change to counting behaviour, thresholds or release flags.
- No claim was added: the audit found nothing missing, so nothing was
  invented to fill a "gap".
- Depth/partial-rep wording waits for C05; the guard would flag an accuracy
  percentage if one were added now.

## Verification (2026-09-23)

| Command | Result |
| --- | --- |
| `flutter analyze` | No issues found |
| `flutter test test/copy` | 2/2 passed |
| `flutter test` (full) | 524/524 passed (522 before; +2) |
