#Requires -Version 5.1
<#
.SYNOPSIS
  W3 - owner wizard: Play closed test and launch (L10).

.DESCRIPTION
  A guided checklist for the Play Console work no script can do. Dry-run by
  default; -Execute walks the steps with a confirmation gate and runs the
  local checks that are scriptable (AAB bundle inspection, signing identity).
  Nothing is uploaded, submitted or purchased by this script.

  The production-access rule is not negotiable: internal testing never counts;
  the clock starts at the 12th continuously opted-in closed tester and runs
  14 days. No review duration is promised.

.EXAMPLE
  powershell -NoProfile -File tools/wizards/W3-play-closed-test.ps1
  powershell -NoProfile -File tools/wizards/W3-play-closed-test.ps1 -Execute `
    -AabPath app\build\app\outputs\bundle\release\app-release.aab -RosterCsv D:\secrets\roster.csv
#>
[CmdletBinding()]
param(
  [switch]$Execute,
  [string]$AabPath,
  [string]$RosterCsv = (Join-Path $env:USERPROFILE 'secrets\training-arena-roster.csv')
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repo
try {
  function Write-Step { param([string]$Text) Write-Host "[W3] $Text" }
  function Write-Plan { param([string]$Text) Write-Host "     $Text" -ForegroundColor DarkGray }
  function Stop-Wizard {
    param([string]$Text)
    Write-Host "[W3][STOP] $Text" -ForegroundColor Red
    exit 1
  }
  function Confirm-Gate {
    param([string]$Text)
    if (-not $Execute) { Write-Plan "gate: $Text"; return }
    $answer = Read-Host "$Text [y/N]"
    if ($answer -notmatch '^(y|Y)$') { Stop-Wizard 'owner stopped the wizard' }
  }

  Write-Step "Play closed-test wizard (L10) - $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })"
  Write-Plan "roster ledger: $RosterCsv (owner-held, outside the repository; columns: tester_code, invited_on, opted_in_on, days_continuous, notes)"

  Write-Plan '1. Play Console: personal/org account type, identity verified, package app.trainingarena.mobile registered'
  Confirm-Gate 'Is the Console account verified and the package registered?'

  Write-Plan '2. Create the CLOSED testing track (internal testing does NOT satisfy production access). Countries: pilot set'
  Write-Plan '3. Recruit 16-24 testers; keep at least 12 continuously opted in for 14 days; no bought opt-ins'
  Confirm-Gate 'Is the closed track live with the roster invited?'

  if ($Execute) {
    if (-not $AabPath) { $AabPath = Read-Host 'Path to the signed AAB' }
    if (-not (Test-Path -LiteralPath $AabPath)) { Stop-Wizard "AAB not found: $AabPath" }
    Write-Step 'local bundle inspection (manifest, 16 KB native, delivery sizes)'
    node tools/release/check_android_bundle.mjs --aab $AabPath
    if ($LASTEXITCODE -ne 0) { Stop-Wizard 'bundle check failed; do not upload this artifact' }
  } else {
    Write-Plan 'node tools/release/check_android_bundle.mjs --aab <signed.aab>'
  }

  Write-Plan '4. Upload the signed AAB to the closed track; record version, track and SHA-256'
  Write-Plan '5. In Play Console -> App integrity, copy the Play app-signing SHA-256/SHA-1; they must match assetlinks.json and the Android OAuth client'
  Confirm-Gate 'Uploaded, and the app-signing fingerprints match the hosted assetlinks.json?'

  Write-Plan '6. Install from Play on a fresh device (not a side-load) and verify: signing identity, pm get-app-links -> verified, Google return, Install Referrer'
  Write-Plan '   adb shell pm verify-app-links --reverify app.trainingarena.mobile'
  Write-Plan '   adb shell pm get-app-links app.trainingarena.mobile'
  Confirm-Gate 'Fresh Play install verified?'

  Write-Plan '7. Complete Data Safety and Health declarations (docs/release/PLAY_STORE_PACKET.md 4-5) and reviewer access (8)'
  Confirm-Gate 'Console forms completed from the packet?'

  Write-Plan '8. Keep a feedback/changes ledger for the production-access application; apply after the 14-day window with 12 continuous testers'
  Write-Plan '   No review duration is promised; record the actual submission and outcome dates'

  Write-Host ''
  Write-Step 'evidence to record'
  Write-Plan 'track name, countries, roster ledger path, first opt-in date, day 14 date'
  Write-Plan 'AAB version/name and SHA-256; Play app-signing fingerprints'
  Write-Plan 'fresh-install verification output; Console form completion dates'
  Write-Plan 'feedback/changes ledger entries used in the production-access application'
  Write-Host ''
  Write-Step 'not done by this wizard: no upload, no submission, no purchase, no rollout'
} finally {
  Pop-Location
}
