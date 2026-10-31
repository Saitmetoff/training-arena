#Requires -Version 5.1
[CmdletBinding()]
param(
  [string]$Device,
  [string]$Flutter = 'D:\toolchains\flutter-3.47.5\flutter\bin\flutter.bat',
  [ValidateSet('Solo', 'Backend', 'Fixtures')][string]$Mode = 'Solo',
  [switch]$EnableCameraCounting,
  [switch]$EnableCameraTrace,
  [ValidateSet('pushups', 'squats')][string]$DiagnosticSoloExercise = 'pushups',
  [switch]$PrintOnly
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ($EnableCameraTrace -and -not $EnableCameraCounting) {
  throw 'EnableCameraTrace requires EnableCameraCounting for physical debug sessions'
}
# Fixture mode replaces the HTTP backend at the composition root. It must be
# an explicit design-review choice, never the default for backend validation.
$flags = [ordered]@{
  ARENA_FEATURE_CAMERA_COUNTING = [bool]$EnableCameraCounting
  ARENA_FEATURE_CAMERA_TRACE = [bool]$EnableCameraTrace
  ARENA_FEATURE_CHALLENGE_LINKS = ($Mode -ne 'Solo')
  ARENA_FEATURE_PREVIEW_FIXTURES = ($Mode -eq 'Fixtures')
  ARENA_FEATURE_PUSH_NOTIFICATIONS = $false
  ARENA_FEATURE_RANKED_MATCHMAKING = $false
  ARENA_FEATURE_RESULT_SHARING = $true
  ARENA_FEATURE_SOLO_MODE = $true
}
$runArgs = @('run')
if ($DiagnosticSoloExercise -eq 'squats') {
  if (-not $EnableCameraTrace) { throw 'Squat diagnostics require camera tracing' }
  $runArgs += '--dart-define=ARENA_DIAGNOSTIC_SOLO_EXERCISE=squats'
}
if ($Device) { $runArgs += @('-d', $Device) }
Write-Host "Development mode: $Mode"
foreach ($flag in $flags.Keys) {
  $value = $flags[$flag].ToString().ToLowerInvariant()
  Write-Host "$flag=$value"
  $runArgs += "--dart-define=$flag=$value"
}
if ($Mode -eq 'Backend') {
  foreach ($key in @('ARENA_SUPABASE_URL', 'ARENA_SUPABASE_ANON_KEY', 'ARENA_AUTH_REDIRECT_URL',
      'ARENA_LINK_HOST', 'ARENA_PUBLIC_URL', 'ARENA_PLAY_STORE_URL')) {
    $value = [Environment]::GetEnvironmentVariable($key)
    if ([string]::IsNullOrWhiteSpace($value) -and $key -in @(
        'ARENA_SUPABASE_URL', 'ARENA_SUPABASE_ANON_KEY')) {
      throw "$key must be set in the environment for Backend mode"
    }
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      Write-Host "$key supplied from environment"
      $runArgs += "--dart-define=$key=$value"
      if ($key -eq 'ARENA_LINK_HOST') {
        $runArgs += "--android-project-arg=arenaLinkHost=$value"
        Write-Host 'Android App Links host supplied from environment'
      }
    }
  }
}
if ($PrintOnly) { return }
Push-Location (Join-Path $repo 'app')
try {
  rtk proxy $Flutter @runArgs
  if ($LASTEXITCODE -ne 0) { throw "flutter run failed: $LASTEXITCODE" }
} finally { Pop-Location }
