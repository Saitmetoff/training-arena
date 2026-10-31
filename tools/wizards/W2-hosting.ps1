#Requires -Version 5.1
<#
.SYNOPSIS
  W2 - owner wizard: domain, hosting, Supabase and App Links (R2/R3/R16).

.DESCRIPTION
  Dry-run by default; pass -Execute to act. In order:
    1. DNS sanity for the domain (Execute only, read-only);
    2. fill challenge-web/config.js (owner values), then run the release gate;
    3. write .well-known/assetlinks.json from the template with the Play
       app-signing SHA-256 (never the upload-key fingerprint);
    4. link the Supabase project, push migrations, set function secrets and
       deploy both Edge Functions;
    5. run the verification commands and print the evidence list.

  No secret is printed. The dispatcher secret is generated locally and shown
  only as a length.

.EXAMPLE
  powershell -NoProfile -File tools/wizards/W2-hosting.ps1
  powershell -NoProfile -File tools/wizards/W2-hosting.ps1 -Execute `
    -Domain arena.example.com -PlaySigningSha256 AA:BB:... -SupabaseProjectRef abcdefgh
#>
[CmdletBinding()]
param(
  [switch]$Execute,
  [string]$Domain,
  [string]$PlaySigningSha256,
  [string]$SupabaseProjectRef
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repo
try {
  function Write-Step { param([string]$Text) Write-Host "[W2] $Text" }
  function Write-Plan { param([string]$Text) Write-Host "     $Text" -ForegroundColor DarkGray }
  function Stop-Wizard {
    param([string]$Text)
    Write-Host "[W2][STOP] $Text" -ForegroundColor Red
    exit 1
  }
  function Require-Value {
    param([string]$Value, [string]$Prompt)
    if ($Value) { return $Value }
    if (-not $Execute) { return '<prompted in -Execute>' }
    $entered = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($entered)) { Stop-Wizard "$Prompt is required" }
    return $entered.Trim()
  }

  Write-Step "hosting wizard (R2/R3/R16) - $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })"
  $Domain = Require-Value $Domain 'Domain (for example arena.example.com)'
  $PlaySigningSha256 = Require-Value $PlaySigningSha256 'Play app-signing certificate SHA-256 (Play Console -> App integrity)'
  $SupabaseProjectRef = Require-Value $SupabaseProjectRef 'Supabase project ref'

  if ($Execute) {
    $dns = Resolve-DnsName -Name $Domain -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if (-not $dns) {
      Stop-Wizard "DNS for $Domain does not resolve yet; create the hosting target first"
    }
    Write-Step "DNS resolves: $($dns.IPAddress)"
  } else {
    Write-Plan "check DNS for $Domain"
  }

  Write-Plan "fill challenge-web/config.js: apiBase, supabaseAnonKey, linkHost, publicUrl, legalEntity, legalAddress, privacyEmail, supportEmail, effectiveDate, childrenPolicy, retention fields"
  if ($Execute) {
    Write-Step 'opening challenge-web/config.js in Notepad - fill every value, then close it'
    Start-Process notepad.exe -ArgumentList 'challenge-web\config.js' -Wait
    node challenge-web/scripts/check.mjs --release
    if ($LASTEXITCODE -ne 0) { Stop-Wizard 'challenge-web release gate still fails; fix config.js first' }
    Write-Step 'challenge-web release gate passed'
  } else {
    Write-Plan 'open challenge-web/config.js; then: node challenge-web/scripts/check.mjs --release'
  }

  Write-Plan "write challenge-web/.well-known/assetlinks.json with fingerprint $PlaySigningSha256"
  if ($Execute) {
    $templatePath = 'challenge-web\.well-known\assetlinks.json.template'
    if (-not (Test-Path -LiteralPath $templatePath)) { Stop-Wizard "missing $templatePath" }
    $json = (Get-Content -LiteralPath $templatePath -Raw) `
      -replace 'REPLACE_WITH_RELEASE_CERT_SHA256_FINGERPRINT', $PlaySigningSha256
    $null = $json | ConvertFrom-Json
    Set-Content -LiteralPath 'challenge-web\.well-known\assetlinks.json' -Value $json -Encoding UTF8
    Write-Step 'assetlinks.json written and parses as JSON; deploy it at https://<domain>/.well-known/assetlinks.json as application/json'
  } else {
    Write-Plan 'read the template, replace the fingerprint placeholder, validate JSON, deploy'
  }

  $supabase = (Get-Command supabase -ErrorAction SilentlyContinue).Source
  if (-not $supabase) { Write-Plan 'supabase CLI not found: install it before -Execute' }
  Write-Plan "supabase link --project-ref $SupabaseProjectRef"
  Write-Plan 'supabase db push'
  Write-Plan 'supabase secrets set ARENA_ALLOWED_ORIGINS=https://<domain> ARENA_PUBLIC_URL=https://<domain> ARENA_DISPATCHER_SECRET=<generated>'
  Write-Plan 'supabase functions deploy arena arena-dispatcher'
  if ($Execute) {
    if (-not $supabase) { Stop-Wizard 'supabase CLI is required for this step' }
    & $supabase link --project-ref $SupabaseProjectRef
    if ($LASTEXITCODE -ne 0) { Stop-Wizard 'supabase link failed' }
    & $supabase db push
    if ($LASTEXITCODE -ne 0) { Stop-Wizard 'supabase db push failed' }
    $bytes = New-Object byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $dispatcherSecret = [Convert]::ToBase64String($bytes)
    & $supabase secrets set "ARENA_ALLOWED_ORIGINS=https://$Domain" "ARENA_PUBLIC_URL=https://$Domain" "ARENA_DISPATCHER_SECRET=$dispatcherSecret"
    if ($LASTEXITCODE -ne 0) { Stop-Wizard 'supabase secrets set failed' }
    Write-Step "dispatcher secret set (length $($dispatcherSecret.Length)); copy it to the owner vault now"
    & $supabase functions deploy arena arena-dispatcher
    if ($LASTEXITCODE -ne 0) { Stop-Wizard 'functions deploy failed' }
  }

  Write-Host ''
  Write-Step 'verification commands'
  Write-Plan "node tools/release/check_app_links.mjs --release --host $Domain --fingerprint $PlaySigningSha256 --fetch-assetlinks"
  Write-Plan 'adb shell pm verify-app-links --reverify app.trainingarena.mobile'
  Write-Plan 'adb shell pm get-app-links app.trainingarena.mobile   # must show verified'
  Write-Plan 'node challenge-web/scripts/check.mjs --release'
  Write-Host ''
  Write-Step 'evidence to record'
  Write-Plan 'public URLs: privacy.html, support.html, delete-account.html, /.well-known/assetlinks.json'
  Write-Plan 'Supabase project ref; dispatcher secret location (vault, never the repo)'
  Write-Plan 'Data Safety / Health answers for docs/release/PLAY_STORE_PACKET.md'
  Write-Plan 'D1/D3 decision records (docs/decisions/0001-..., 03-...)'
} finally {
  Pop-Location
}
