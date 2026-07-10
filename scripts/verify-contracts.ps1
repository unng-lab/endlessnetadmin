$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$contractRoot = Join-Path $repoRoot "contracts"
$lock = Get-Content -LiteralPath (Join-Path $contractRoot "contracts.lock.json") -Raw | ConvertFrom-Json

if ($lock.contract_version -ne "1.0.0") {
  throw "Unsupported frontend contract version: $($lock.contract_version)"
}

foreach ($property in $lock.files.PSObject.Properties) {
  $path = Join-Path $contractRoot $property.Name
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Pinned contract file is missing: $($property.Name)"
  }
  $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  $expected = ([string]$property.Value).ToLowerInvariant()
  if ($actual -ne $expected) {
    throw "Pinned contract checksum mismatch for $($property.Name): $actual, want $expected"
  }
}

Write-Host "Pinned frontend contracts verified at version $($lock.contract_version)"
