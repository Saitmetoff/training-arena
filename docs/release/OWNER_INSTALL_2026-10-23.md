# Fault private owner diagnostic — 23 October 2026

Fault build **2026102304** includes camera counting, the real fit_ap friend
backend, email-code authentication, browser sign-in cancellation and the
first-sign-in username fix. It is a debug-signed private diagnostic; physical
camera accuracy and full two-phone acceptance remain pending.

## Artifact and reproducibility

Packet: artifacts/owner-acceptance/2026102304-pushups/

- Fault-owner-diagnostic.apk
- build-manifest.json — actual source/version/hash/size/tool record
- signer.txt — certificate verification
- public-client-defines.json — public client configuration and diagnostic flags

Version: 1.0.1-owner.20261023 / **2026102304**.
Application label: **Fault**. Technical package: app.trainingarena.mobile.
Source: **7937c7f6476287bfaf628bac62d0c4323a37deb8**, source_dirty=false.
Later documentation commits do not relabel this APK's source.

- APK SHA256: 857064ce902e13ac384bc0d7df753d43a8550898972fb2d9f9c7f3dd3dc39add
- Bytes: 201,348,471
- Debug signer SHA256: b72f647900bd4725dacab73bba5dfc14ec82cc11fe967644e82080b584b5f20c
- Min SDK24; target/compile/build-tools36; arm64-v8a, armeabi-v7a and x86_64.
- Flutter3.47.5; Temurin OpenJDK17.0.20.1+1; D:\toolchains\android-sdk.
- Signature verification, APK manifest/ABI inspection, copied-artifact hash
  comparison and repository/artifact secret scans passed.

Rebuild from this source using the ignored public-only owner config:

~~~powershell
rtk proxy powershell -NoProfile -File tools/release/build_owner_acceptance.ps1 -BuildNumber 2026102304
~~~

The script validates the exact fit_ap URL, active publishable key and approved
trainingarena://challenge/auth redirect. It rejects unexpected config fields
and server credentials. Camera, trace, solo, challenge links and result sharing
are on; fixtures, ranked and push are off. Counter version remains 1.3.0.
Normal solo is push-ups. A separate debug/trace squat diagnostic can be built
with -DiagnosticSoloExercise squats. No counter threshold was loosened.

## Verified app and authentication evidence

- Sender is **Fault <onboarding@resend.dev>**. Both hosted numeric-code
  templates use Fault and “Fault · fault.fit”; DNS was untouched.
- A fresh email requested from the installed app was delivered with the new
  branding. Its actual eight-digit code signed in and loaded the profile.
- The owner selected **new**. The backend and app both confirm **@new**.
- A first-sign-in username defect was reproduced in both email and Google
  widget flows: rebuilding the signed-out controls invalidated the prompt's
  context. Persistent profile-owned callbacks fix it. Both regressions fail
  before the change and pass afterward.
- Final Flutter: **661 pass, 2 optional skips, 0 failures**; analyzer clean.
  Backend: 75 Deno tests and both Edge entrypoint checks pass. Earlier unchanged
  SQL contracts passed 240 native PostgreSQL assertions.
- Same-certificate upgrades 02 → 03 → 04 succeeded with install -r and no wipe.
  Build04's installed version was verified. A new process restored @new.
  The am start -W timing command reported a timeout; the actual Battle UI then
  appeared and Profile worked. This is functional recovery evidence, not a
  passed startup-performance gate.
- The actual signed-in app loaded its real readable challenge code and honest
  empty battle history. No invitation or message was sent to another person.
- Earlier API36 emulator checks observed permission deny/retry/grant and a
  native virtual-camera test-pattern preview, including Home/foreground and
  camera reopen. The pattern has no person; it proves no physical rep accuracy.
  A pre-existing System UI ANR and initial missing camera inventory are recorded
  in the earlier evidence. Explicit emulator DNS restored the app's network
  path without clearing its data.
- Google is enabled; the public authorization endpoint routes to the approved
  client and callback. The app launches Chrome and cancel/retry works.
  Actual Google consent/token exchange/warm-cold return still need owner
  interaction; this AVD reaches Chrome's first-run Terms screen.

Full provider/delivery details:
[OWNER_AUTH_SETUP_2026-10-23.md](OWNER_AUTH_SETUP_2026-10-23.md).
The final restored profile screenshot is kept under ignored
artifacts/owner-acceptance/emulator-fault-profile-2026102304.png.
Historical builds01–03 remain preserved with their original identities.

## Install on the two physical phones

The chat's APK link is a file on this PC, not a phone download URL. Use USB.
Enable USB debugging on each phone and accept this PC's authorization prompt.

~~~powershell
rtk proxy D:\toolchains\android-sdk\platform-tools\adb.exe devices -l
rtk proxy D:\toolchains\android-sdk\platform-tools\adb.exe -s <serial> shell dumpsys package app.trainingarena.mobile
rtk proxy D:\toolchains\android-sdk\platform-tools\adb.exe -s <serial> shell pm path app.trainingarena.mobile
~~~

Record model, Android version, installed app version and needed local history.
If the app exists, pull the returned base.apk and inspect its signer with SDK36
apksigner verify --print-certs. Compare with this packet's signer.txt. If the
certificate differs, stop and choose data handling with the owner; do not
uninstall or wipe data to force installation. If absent or matching:

~~~powershell
rtk proxy D:\toolchains\android-sdk\platform-tools\adb.exe -s <serial> install -r artifacts/owner-acceptance/2026102304-pushups/Fault-owner-diagnostic.apk
~~~

Use this build on both phones. The owner reviews any Android install prompt.

## Guided physical acceptance

1. Actual email code and Google sign-in; warm/cold/process return, cancellation,
   retry and invitation retention. Confirm the same account after restart.
   Temporary Resend delivery is limited to its owner's address; the second
   account needs its own working sign-in path.
2. Solo → camera permission → practice rep → full counted set → end → save →
   history → restart. Deny once, recover through Settings and reopen camera.
3. Open My challenge on one phone; Join by code on the other. Send a real
   request, inspect inbox, accept, practice, both Ready, complete the 60-second
   round, and compare server results, receipts and history.
4. Background/resume, brief tracking loss and network loss; verify the same
   match/count sequence. Test terminal disconnect and a fresh rematch.
5. Follow [the trace runbook](../../qa/camera/TRACE_RUNBOOK.md). Export after the
   round and compare observer counts. Record device/model/Android/build/hash
   and mismatches. Traces contain numeric coordinates and timestamps, without
   frames, audio, account/device IDs or automatic upload.

Required physical results: zero false positives; at least 90% of 20-rep rounds
within ±2; aggregate error at most 5%; understandable pauses, recovery and no
crash/frame leak. None is claimed from the emulator.

Public HTTPS App Links/website installation, release signing, signed-candidate
native16KB checks, public policies and Play publication remain separate gates.
Use the real in-app code/inbox for private testing; the placeholder HTTPS
domain does not establish a working public invite website. Optional work stays
in [POST_LAUNCH_PLAN.md](POST_LAUNCH_PLAN.md).
