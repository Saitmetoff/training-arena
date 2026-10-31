# L07 store screenshots

Captured: 2026-09-21 · Repository: `D:/TrainingArena` · Branch: `codex/training-arena`

Build under test: release-equivalent APK, debug-signed smoke artifact
(non-distributable; R9 signing still open).

| Field | Value |
| --- | --- |
| Build command | `flutter build apk --release -PallowDebugSignedRelease=true -ParenaLinkHost=arena.pilot.example` + the pilot dart-defines (camera off, ranked off, push off, challenge links on, sharing on, fixtures off) |
| APK | `app/build/app/outputs/flutter-apk/app-release.apk` |
| APK size / SHA-256 | 91 417 891 bytes; SHA-256 `E35744806C88DE3160D5A0BB03807D6A9E55748A68255B79B87019447D074CC9` |
| Device | `emulator-5554` (AVD `TA_API36`, x86_64, Android API 36) |
| Display | `wm size 1080x1920` (9:16) on a 1080x2400 panel, density 420 |
| Backend | local Supabase stack (`supabase start`, `supabase functions serve --no-verify-jwt --env-file supabase/.env.local`), Mailpit mail catcher for the sign-in code |
| Account | `l07.screens@arena.invalid`, username `arena_l07` (a reserved `.invalid` test address created for this capture; no real user data) |
| Capture | `adb exec-out screencap -p` (binary redirect through `cmd`), converted to 24-bit RGB PNG with Pillow |
| Storage | `qa/integration/screens/` (gitignored) |

| # | File | Screen | Size | SHA-256 | Listing use |
| --- | --- | --- | --- | --- | --- |
| 1 | `l07_01_battle.png` | Battle tab, honest pilot scope: challenge a friend, ranked unavailable, camera counting off | 148 212 B | `b03e326596547d9088968bdf66579664304058a817741d8564476edc3f62de1e` | yes |
| 2 | `l07_02_signin.png` | Profile tab signed out, email/Google sign-in entry | 96 185 B | `6f07591a27e213c3a98a1914c82fd4843bb0f66ca9a83fa3f55ddec3d7c96edf` | yes |
| 3 | `l07_03_profile.png` | Profile tab signed in (`@arena_l07`, rating 1000) | 88 416 B | `fd7b34a4442b8eee78c8dc3e5fe2fd0e5266123ff10588f820080492b8ec1d5c` | yes |
| 4 | `l07_04_settings_privacy.png` | Settings, Privacy card plus Delete account and "Delete from the web instead" | 123 454 B | `4c4d7553e68c1b503a244f66b1e85ebb21ec42308deed9e05071f458a1453f0b` | yes |
| 5 | `l07_05_settings_links.png` | Settings, full Privacy card with Privacy policy and Support buttons | 120 891 B | `8971652e104fcd56786c908ef21422dae653d9583b8e7faff3a0cbdb3985e232` | yes |
| 6 | `l07_06_history.png` | Battle history, honest empty state | 71 536 B | `5daaef4380181e6e0d343aa5839dee4daf4a42aed5faadc6c904df23cb3e2fdf` | yes |

All six are 1080x1920 (9:16), 24-bit PNG without alpha, only app UI, no
device frames, no added text, no personal data.

Captured but **excluded** from the listing: `l07_excluded_leaderboard.png`
shows the local seed fixtures (`@fixture_alice`, `@fixture_bob`,
`@fixture_carol`). Those are development fixtures, not real players, so the
capture must not appear on the store listing.

Not captured: any camera-counted round (camera counting is off in this build
by design), ranked search (ranked is off in this build) and a real two-person
battle (requires camera counting to finish). Recapture from the signed release
candidate if the UI changes before submission.
