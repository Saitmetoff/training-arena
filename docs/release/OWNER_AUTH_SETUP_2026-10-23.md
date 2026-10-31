# Fault private authentication evidence — 23 October 2026

The official product name is **Fault**. The owner chose display name Fault and the temporary onboarding@resend.dev address. Both hosted code templates use Fault and the footer “Fault · fault.fit”. No fault.fit DNS was changed.

## Verified hosted configuration

- Existing fit_ap project: rfruhwgdrlrzhllzmztk. Public settings report email and Google enabled, signups enabled and email confirmation required.
- The approved trainingarena://challenge/auth callback is the sole redirect allowlist entry. The existing Site URL remains unchanged. The technical app package and callback keep their identifiers for upgrade and sign-in continuity.
- The owner saved Google credentials and the existing Resend sending key directly in Supabase. Stored secrets are hidden and were not copied into the APK, repository, client defines, logs or chat. These steps are complete.
- SMTP: sender onboarding@resend.dev, name **Fault**, host smtp.resend.com, port 465 (implicit TLS), username resend. The approved key label remains “Training Arena owner SMTP temporary”; labels do not determine sender copy.
- Resend has no verified domains. The temporary sender permits only the account's own email recipient. Free capacity is 100 messages/day and 3,000/month. This does not enable general tester email delivery.
- OTP length is **8 digits**, expiry **3600 seconds**. The app accepts 4–10 characters without truncating eight-digit codes. These settings were preserved.

| Hosted template | Saved subject | Source |
| --- | --- | --- |
| Confirm signup | Confirm your Fault email | [owner-signup-code.html](owner-signup-code.html) |
| Magic link or OTP | Your Fault sign-in code | [owner-email-code.html](owner-email-code.html) |

Both use {{ .Token }}. Confirmation remains required. First/unconfirmed sign-in may use Confirm signup; confirmed returning users use Magic link/OTP. Saved previews are not by themselves delivery evidence.

## Actual email and app evidence

The first authorized host OTP request returned HTTP200. Resend delivered the signup email with an expanded eight-digit code and no magic link. Host code verification and the Arena profile flow ran; SQL subsequently confirmed email confirmation, a real sign-in and an Arena profile. A returning-user email was also delivered. Those initial emails had the former product copy.

After the Fault change, the installed app requested a fresh code. Resend reported delivery at **2026-10-23 16:11:00 UTC**, subject **Your Fault sign-in code**, From **Fault <onboarding@resend.dev>**, with Fault copy and the fault.fit footer. Its actual eight-digit code was submitted in the app without exposing it in chat or evidence logs. The app advanced to **Choose a username**, proving code verification and profile retrieval. The owner selected new. Backend SQL and the app both confirm @new; build2026102304 restored that named session after an in-place upgrade and new process launch. The profile loaded its real readable challenge code and honest empty battle history.

The earlier emulator request failed before delivery because DNS lookup was broken. Restarting the same AVD with explicit DNS restored hostname resolution; the actual app request and code verification above then succeeded. No app data was wiped and no email setting was weakened.

## Google configuration and remaining acceptance

Reuse the approved Web client “Training Arena owner acceptance” in existing project workflow-506710. Its public client ID is 471928166127-hu9luqnd6rnl7ojjklm7jg28j162i02e.apps.googleusercontent.com. Its only authorized redirect is https://rfruhwgdrlrzhllzmztk.supabase.co/auth/v1/callback.

The existing unrelated Web client and test user were preserved; the owner was added as a test user. The project's consent name stays **workflow**, as approved. Changing that shared Google brand is separate from the Fault app/email copy. The provider is saved and enabled; nonce checks remain enabled and email is required. A real public authorization request returned HTTP302 to Google with the approved client, exact callback and basic email/profile scope.

The native app opens Chrome, whose first-run Terms screen stops this AVD's flow. Actual Google consent, token exchange and warm/cold/process return remain pending owner interaction. No Terms agreement was accepted on the owner's behalf. Browser launch and cancellation are distinct from completed OAuth.

An actual browser-back check found a five-minute disabled-button wait. Source 5b54eb6 adds Cancel sign-in, durable pending-auth cleanup and stale callback rejection before exchange. Build 2026102302 passed native browser back → Cancel sign-in → immediate email retry. Full Flutter: 661 pass, 2 optional skips; analyzer clean. Tests preserve pending invitations through return/retry. A separate first-sign-in username defect was found in the native email flow: removing the signed-out controls invalidated the automatic username prompt context. Source7937c7f moves callbacks to the persistent profile body. Both email and Google widget regressions fail before the fix and pass afterward; final build2026102304 contains it.

On owner devices, finish Google sign-in and verify the same invitation on warm and cold/process return, then cancel and retry. Repeat email sign-in after logout, verify the same account/profile and restart persistence. A second independently authenticated account is needed for real friend battles; the temporary Resend sender cannot send codes to that account.

No new key/client, subscription, domain, billing or public publication is needed for the completed owner setup. Keep using the existing credentials.

References checked on 23 October: [Supabase SMTP](https://supabase.com/docs/guides/auth/auth-smtp), [email templates](https://supabase.com/docs/guides/auth/auth-email-templates), [Google browser OAuth](https://supabase.com/docs/guides/auth/social-login/auth-google), [Resend SMTP](https://resend.com/docs/send-with-smtp) and its [temporary sender restriction](https://resend.com/docs/knowledge-base/403-error-resend-dev-domain).
