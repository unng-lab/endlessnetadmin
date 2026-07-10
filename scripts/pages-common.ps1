$ErrorActionPreference = "Stop"

function Get-EndlessNetRepoRoot {
  return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Resolve-EndlessNetPagesPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }
  return (Join-Path $RepoRoot $Path)
}

function Assert-EndlessNetChildPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
  $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
  if (-not $resolvedPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw $Message
  }
  return $resolvedPath
}

function Clear-EndlessNetDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string[]]$PreserveNames = @()
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  $preserve = @{}
  foreach ($name in $PreserveNames) {
    $preserve[$name] = $true
  }

  Get-ChildItem -LiteralPath $Path -Force |
    Where-Object { -not $preserve.ContainsKey($_.Name) } |
    Remove-Item -Recurse -Force
}
