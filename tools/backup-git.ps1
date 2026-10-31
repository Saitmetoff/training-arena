#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputPath)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$target = [IO.Path]::GetFullPath($OutputPath)
if ($target.Equals($repo,[StringComparison]::OrdinalIgnoreCase) -or
    $target.StartsWith($repo + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
  throw 'The bundle path must be outside the repository'
}
if (Test-Path -LiteralPath $target) { throw 'Refusing to overwrite an existing bundle' }
$parent = Split-Path -Parent $target
if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw 'Output directory must exist' }
Push-Location $repo
try {
  rtk git bundle create $target --all
  if ($LASTEXITCODE -ne 0) { throw "git bundle create failed: $LASTEXITCODE" }
  rtk git bundle verify $target
  if ($LASTEXITCODE -ne 0) { throw "git bundle verify failed: $LASTEXITCODE" }
  Write-Host "Committed Git history saved: $target"
  Write-Host 'Uncommitted and untracked files are not in this bundle.'
} finally { Pop-Location }
