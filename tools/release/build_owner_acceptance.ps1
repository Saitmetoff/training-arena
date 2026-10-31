#Requires -Version 5.1
[CmdletBinding()]
param(
  [string]$Flutter = 'D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat',
  [string]$JavaHome = 'D:\Kiro\.tooling\jdk17',
  [string]$AndroidSdk = 'D:\toolchains\android-sdk',
  [string]$ConfigPath,
  [ValidateSet('pushups','squats')][string]$DiagnosticSoloExercise = 'pushups',
  [string]$BuildName = '1.0.1-owner.20261023',
  [int]$BuildNumber = 2026102301,
  [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $ConfigPath) { $ConfigPath = Join-Path $repo 'app\.env.owner-acceptance.json' }
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$allowed = @('ARENA_SUPABASE_URL','ARENA_SUPABASE_ANON_KEY','ARENA_AUTH_REDIRECT_URL',
  'ARENA_LINK_HOST','ARENA_PUBLIC_URL','ARENA_PLAY_STORE_URL')
foreach ($property in $config.PSObject.Properties) {
  if ($property.Name -notin $allowed) { throw "Unexpected client configuration field: $($property.Name)" }
}
if ($config.ARENA_SUPABASE_URL -ne 'https://rfruhwgdrlrzhllzmztk.supabase.co') {
  throw 'Owner acceptance must use the explicitly selected fit_ap project'
}
$publicKey = [string]$config.ARENA_SUPABASE_ANON_KEY
if ($publicKey -notmatch '^sb_publishable_[A-Za-z0-9_-]+$') {
  throw 'Use an active Supabase publishable key; server credentials are never accepted'
}
if ($config.ARENA_AUTH_REDIRECT_URL -ne 'trainingarena://challenge/auth') {
  throw 'The exact registered owner auth redirect must be trainingarena://challenge/auth'
}
$defines = [ordered]@{}
foreach ($key in $allowed) {
  if ($config.$key) { $defines[$key] = [string]$config.$key }
}
$defines.ARENA_FEATURE_CAMERA_COUNTING = 'true'
$defines.ARENA_FEATURE_CAMERA_TRACE = 'true'
$defines.ARENA_FEATURE_CHALLENGE_LINKS = 'true'
$defines.ARENA_FEATURE_RESULT_SHARING = 'true'
$defines.ARENA_FEATURE_SOLO_MODE = 'true'
$defines.ARENA_FEATURE_PREVIEW_FIXTURES = 'false'
$defines.ARENA_FEATURE_RANKED_MATCHMAKING = 'false'
$defines.ARENA_FEATURE_PUSH_NOTIFICATIONS = 'false'
$defines.ARENA_DIAGNOSTIC_SOLO_EXERCISE = $DiagnosticSoloExercise
$source = (rtk proxy git -C $repo rev-parse HEAD).Trim()
$dirty = [bool](rtk proxy git -C $repo status --porcelain --untracked-files=normal)
$defines.ARENA_BUILD_ID = $source
if ($ValidateOnly) {
  Write-Host "Owner config valid: fit_ap, camera+trace+friend backend; solo exercise=$DiagnosticSoloExercise"
  return
}
foreach ($requiredPath in @($Flutter, (Join-Path $JavaHome 'bin\java.exe'),
    (Join-Path $AndroidSdk 'build-tools\36.0.0\apksigner.bat'))) {
  if (-not (Test-Path -LiteralPath $requiredPath)) { throw "Missing pinned tool: $requiredPath" }
}
$env:JAVA_HOME = $JavaHome
$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:PATH = (Join-Path $JavaHome 'bin') + ';' + $env:PATH
$out = Join-Path $repo "artifacts\owner-acceptance\$BuildNumber-$DiagnosticSoloExercise"
New-Item -ItemType Directory -Path $out -Force | Out-Null
$definePath = Join-Path $out 'public-client-defines.json'
$defines | ConvertTo-Json | Set-Content -LiteralPath $definePath -Encoding UTF8
$localProperties = @(
  'sdk.dir=' + $AndroidSdk.Replace('\','/'),
  'flutter.sdk=' + (Split-Path (Split-Path $Flutter)).Replace('\','/')
)
$localProperties | Set-Content -LiteralPath (Join-Path $repo 'app\android\local.properties') -Encoding ASCII
$buildArgs = @('build','apk','--debug',"--build-name=$BuildName", "--build-number=$BuildNumber",
  "--dart-define-from-file=$definePath")
if ($config.ARENA_LINK_HOST) { $buildArgs += "--android-project-arg=arenaLinkHost=$($config.ARENA_LINK_HOST)" }
Push-Location (Join-Path $repo 'app')
try {
  rtk proxy $Flutter @buildArgs
  if ($LASTEXITCODE -ne 0) { throw "Owner APK build failed ($LASTEXITCODE)" }
} finally { Pop-Location }
$apk = Join-Path $out 'Fault-owner-diagnostic.apk'
Copy-Item -LiteralPath (Join-Path $repo 'app\build\app\outputs\flutter-apk\app-debug.apk') -Destination $apk
$signer = rtk proxy (Join-Path $AndroidSdk 'build-tools\36.0.0\apksigner.bat') verify --print-certs $apk
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
$signer | Set-Content -LiteralPath (Join-Path $out 'signer.txt') -Encoding UTF8
$apkStream = [System.IO.File]::OpenRead($apk)
try {
  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  $apkHash = ([BitConverter]::ToString($sha256.ComputeHash($apkStream))).Replace('-','').ToLowerInvariant()
} finally { $apkStream.Dispose() }
$manifest = [ordered]@{
  purpose = 'Private owner diagnostics; not approved for public distribution'
  built_at_utc = [DateTime]::UtcNow.ToString('o')
  source_commit = $source; source_dirty = $dirty
  application_id = 'app.trainingarena.mobile'; build_name = $BuildName; build_number = $BuildNumber
  apk_sha256 = $apkHash
  apk_bytes = (Get-Item -LiteralPath $apk).Length
  flutter = $Flutter; java_home = $JavaHome; android_sdk = $AndroidSdk
  defines_file = 'public-client-defines.json'; signer_file = 'signer.txt'
  physical_acceptance = 'pending'; hosted_auth = 'verify provider configuration and real delivery/return separately'
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $out 'build-manifest.json') -Encoding UTF8
Write-Host "Owner diagnostic APK: $apk"
Write-Host "SHA256: $($manifest.apk_sha256)"
