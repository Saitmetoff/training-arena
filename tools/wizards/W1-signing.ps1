#Requires -Version 5.1
<#
.SYNOPSIS
  W1 - owner wizard: release signing (R9).

.DESCRIPTION
  Dry-run by default; pass -Execute to act. In order:
    1. locates keytool (PATH, JAVA_HOME or the known JDK 17 path);
    2. creates the release keystore outside the repository;
    3. writes app/android/key.properties and proves git ignores it;
    4. prints the upload-key fingerprints;
    5. uploads the signing CI secrets with gh (or prints the manual names);
    6. prints the evidence to record and the next command.

  Passwords are read with Read-Host -AsSecureString, handed to keytool through
  an environment variable and never printed, logged or written into the
  repository. Re-running is safe: an existing keystore is never overwritten.

.EXAMPLE
  powershell -NoProfile -File tools/wizards/W1-signing.ps1
  powershell -NoProfile -File tools/wizards/W1-signing.ps1 -Execute
#>
[CmdletBinding()]
param(
  [switch]$Execute,
  [string]$KeystorePath = (Join-Path $env:USERPROFILE 'secrets\training-arena-release.jks'),
  [string]$Alias = 'training-arena-release',
  [string]$KeyPropertiesPath = 'app\android\key.properties'
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repo
try {
  function Write-Step { param([string]$Text) Write-Host "[W1] $Text" }
  function Write-Plan { param([string]$Text) Write-Host "     $Text" -ForegroundColor DarkGray }
  function Stop-Wizard {
    param([string]$Text)
    Write-Host "[W1][STOP] $Text" -ForegroundColor Red
    exit 1
  }
  function Invoke-Guarded {
    param([string]$Description, [scriptblock]$Action)
    if (-not $Execute) {
      Write-Host "     [dry-run] $Description" -ForegroundColor DarkGray
      return
    }
    Write-Step $Description
    & $Action
  }

  Write-Step "release signing wizard (R9) - $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })"

  $keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
  if (-not $keytool) {
    $candidates = @()
    if ($env:JAVA_HOME) {
      $candidates += (Join-Path $env:JAVA_HOME 'bin\keytool.exe')
    }
    $candidates += 'D:\Kiro\.tooling\jdk17\bin\keytool.exe'
    foreach ($candidate in $candidates) {
      if ($candidate -and (Test-Path -LiteralPath $candidate)) { $keytool = $candidate; break }
    }
  }
  if (-not $keytool) { Stop-Wizard 'keytool not found. Install JDK 17 or set JAVA_HOME.' }
  Write-Step "keytool: $keytool"

  $password = $null
  if ($Execute) {
    $secure = Read-Host -AsSecureString 'Keystore password (store and key)'
    $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
      [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    if ([string]::IsNullOrEmpty($password)) { Stop-Wizard 'empty password' }
  }

  if (Test-Path -LiteralPath $KeystorePath) {
    Write-Step "keystore exists at $KeystorePath - creation skipped"
  } else {
    Write-Plan "create $KeystorePath (RSA 4096, validity 10000 days, alias $Alias)"
    Invoke-Guarded 'creating the release keystore' {
      $directory = Split-Path -Parent $KeystorePath
      if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
      }
      $env:ARENA_W1_PASS = $password
      try {
        & $keytool -genkeypair -v -keystore $KeystorePath -alias $Alias `
          -keyalg RSA -keysize 4096 -validity 10000 `
          -storepass:env ARENA_W1_PASS -keypass:env ARENA_W1_PASS `
          -dname 'CN=Training Arena, OU=Release, O=Training Arena, C=US'
        if ($LASTEXITCODE -ne 0) { Stop-Wizard "keytool exited $LASTEXITCODE" }
      } finally {
        Remove-Item Env:ARENA_W1_PASS -ErrorAction SilentlyContinue
      }
    }
  }

  Write-Plan "write $KeyPropertiesPath (gitignored, passwords inside, never committed)"
  Invoke-Guarded 'writing key.properties' {
    $escaped = $KeystorePath.Replace('\', '\\')
    @(
      "storeFile=$escaped",
      "storePassword=$password",
      "keyAlias=$Alias",
      "keyPassword=$password"
    ) | Set-Content -LiteralPath $KeyPropertiesPath -Encoding ASCII
    git check-ignore -q -- $KeyPropertiesPath
    if ($LASTEXITCODE -ne 0) {
      Stop-Wizard "$KeyPropertiesPath is NOT gitignored - refusing to leave it on disk"
    }
    Write-Step 'key.properties written and confirmed ignored by git'
  }

  Write-Plan 'print the upload-key fingerprints'
  if ($Execute) {
    $env:ARENA_W1_PASS = $password
    try {
      $certText = & $keytool -list -v -keystore $KeystorePath -alias $Alias `
        -storepass:env ARENA_W1_PASS
    } finally {
      Remove-Item Env:ARENA_W1_PASS -ErrorAction SilentlyContinue
    }
    $sha256 = ($certText | Select-String 'SHA256:' | Select-Object -First 1) -replace '.*SHA256:\s*', ''
    $sha1 = ($certText | Select-String 'SHA1:' | Select-Object -First 1) -replace '.*SHA1:\s*', ''
    if (-not $sha256) { Stop-Wizard 'could not read the SHA-256 fingerprint' }
    Write-Step "upload-key SHA-256: $($sha256.Trim())"
    Write-Step "upload-key SHA-1:   $($sha1.Trim())"
  } else {
    Write-Plan 'keytool -list -v -keystore <path> -alias <alias> | Select-String "SHA256:|SHA1:"'
  }

  $gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
  if ($gh) {
    Write-Plan 'upload 5 CI secrets: ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD, ARENA_RELEASE_CERT_SHA256'
    Invoke-Guarded 'uploading CI secrets with gh' {
      [Convert]::ToBase64String([IO.File]::ReadAllBytes($KeystorePath)) |
        & $gh secret set ANDROID_KEYSTORE_BASE64
      $password | & $gh secret set ANDROID_KEYSTORE_PASSWORD
      $Alias | & $gh secret set ANDROID_KEY_ALIAS
      $password | & $gh secret set ANDROID_KEY_PASSWORD
      $sha256.Trim() | & $gh secret set ARENA_RELEASE_CERT_SHA256
    }
  } else {
    Write-Plan 'gh not found: set the five secrets manually in GitHub repository settings'
  }

  Write-Host ''
  Write-Step 'evidence to record (owner vault / task record)'
  Write-Plan "keystore: $KeystorePath (back it up; losing it blocks upgrades)"
  Write-Plan 'upload-key SHA-256 / SHA-1: from the output above'
  Write-Plan 'Play app-signing SHA-256 / SHA-1: from Play Console -> App integrity (DIFFERENT certificate; assetlinks + OAuth use this one)'
  Write-Plan 'next: run the release-candidate workflow (workflow_dispatch) and pin the signer with check_artifact_identity.mjs / check_android_bundle.mjs'
} finally {
  Pop-Location
}
