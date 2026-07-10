param(
  [string]$OutputPath = "dist",
  [string]$BuildId = "",
  [string]$ApiBaseUrl = "",
  [string]$AdminUrl = "https://admin.endlessnet.ru/",
  [string]$SiteRoot = "https://endlessnet.ru/",
  [switch]$Clean,
  [switch]$SkipFlutterBuild,
  [switch]$Standalone
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "pages-common.ps1")

$repoRoot = Get-EndlessNetRepoRoot
$adminSource = Join-Path $repoRoot "build\prepared"
$adminFlutter = Join-Path $repoRoot "app"
$installScript = Join-Path $adminSource "install.sh"
$output = Resolve-EndlessNetPagesPath -RepoRoot $repoRoot -Path $OutputPath
$adminOutput = if ($Standalone) { $output } else { Join-Path $output "admin" }

$adminRoutes = @(
  "machines",
  "apps",
  "services",
  "users",
  "access-controls",
  "logs",
  "dns",
  "settings",
  "settings/personal",
  "settings/billing",
  "resource-hub",
  "connect/windows",
  "networks",
  "nodes",
  "access",
  "billing",
  "billing/plans",
  "billing/checkout",
  "billing/yookassa/return",
  "billing/success",
  "billing/failure",
  "billing/invoices",
  "billing/usage",
  "billing/legal",
  "billing/license",
  "billing/enterprise"
)

$adminUtf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Read-EndlessNetUtf8Text {
  param([Parameter(Mandatory = $true)][string]$Path)

  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-EndlessNetUtf8Text {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Value
  )

  [System.IO.File]::WriteAllText($Path, $Value, $script:adminUtf8NoBom)
}

function Add-EndlessNetAdminHashInput {
  param(
    [Parameter(Mandatory = $true)][System.IO.MemoryStream]$Stream,
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][byte[]]$Bytes
  )

  $labelBytes = [System.Text.Encoding]::UTF8.GetBytes($Label + "`n")
  $Stream.Write($labelBytes, 0, $labelBytes.Length)
  $Stream.Write($Bytes, 0, $Bytes.Length)
  $separator = [System.Text.Encoding]::UTF8.GetBytes("`n")
  $Stream.Write($separator, 0, $separator.Length)
}

function Remove-EndlessNetAdminCacheVersion {
  param([Parameter(Mandatory = $true)][string]$Value)

  return $Value `
    -replace '((?:flutter_bootstrap|main\.dart|flutter)\.js)(?:\?v=[A-Za-z0-9._~-]+)?', '$1' `
    -replace '((?:main\.dart)\.(?:mjs|wasm))(?:\?v=[A-Za-z0-9._~-]+)?', '$1' `
    -replace '(manifest\.json)(?:\?v=[A-Za-z0-9._~-]+)?', '$1'
}

function Get-EndlessNetAdminContentBuildId {
  param([Parameter(Mandatory = $true)][string]$AdminSource)

  $requiredInputs = @(
    "flutter_bootstrap.js",
    "main.dart.js"
  )
  foreach ($relativePath in $requiredInputs) {
    $path = Join-Path $AdminSource $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
      throw "Admin cache-busting input not found: $path"
    }
  }

  $stream = [System.IO.MemoryStream]::new()
  try {
    $bootstrap = Read-EndlessNetUtf8Text -Path (Join-Path $AdminSource "flutter_bootstrap.js")
    $normalizedBootstrap = Remove-EndlessNetAdminCacheVersion -Value $bootstrap
    Add-EndlessNetAdminHashInput `
      -Stream $stream `
      -Label "flutter_bootstrap.js" `
      -Bytes ([System.Text.Encoding]::UTF8.GetBytes($normalizedBootstrap))

    foreach ($relativePath in @(
      "session_bootstrap.js",
      "main.dart.js",
      "version.json",
      "manifest.json",
      "assets\AssetManifest.bin.json",
      "assets\FontManifest.json"
    )) {
      $path = Join-Path $AdminSource $relativePath
      if (Test-Path -LiteralPath $path) {
        Add-EndlessNetAdminHashInput `
          -Stream $stream `
          -Label $relativePath `
          -Bytes ([System.IO.File]::ReadAllBytes($path))
      }
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
      $hash = $sha.ComputeHash($stream.ToArray())
      return ([System.BitConverter]::ToString($hash).Replace("-", "").Substring(0, 16).ToLowerInvariant())
    }
    finally {
      $sha.Dispose()
    }
  }
  finally {
    $stream.Dispose()
  }
}

function Resolve-EndlessNetAdminBuildId {
  param(
    [Parameter(Mandatory = $true)][string]$AdminSource,
    [string]$BuildId = ""
  )

  $resolvedBuildId = $BuildId.Trim()
  if ($resolvedBuildId -eq "" -and $env:ENDLESSNET_ADMIN_BUILD_ID) {
    $resolvedBuildId = $env:ENDLESSNET_ADMIN_BUILD_ID.Trim()
  }
  if ($resolvedBuildId -eq "") {
    $resolvedBuildId = Get-EndlessNetAdminContentBuildId -AdminSource $AdminSource
  }

  $resolvedBuildId = $resolvedBuildId -replace '[^A-Za-z0-9._-]', '-'
  $resolvedBuildId = $resolvedBuildId.Trim([char[]]"-._")
  if ($resolvedBuildId -eq "") {
    throw "Admin cache-busting build id is empty after normalization."
  }
  return $resolvedBuildId
}

function Set-EndlessNetAdminPathCacheVersion {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$BuildId
  )

  $basePath = ($Path -split '\?', 2)[0]
  return "${basePath}?v=$BuildId"
}

function Add-EndlessNetAdminCacheBuster {
  param(
    [Parameter(Mandatory = $true)][string]$AdminSource,
    [Parameter(Mandatory = $true)][string]$BuildId
  )

  $encodedBuildId = [System.Uri]::EscapeDataString($BuildId)

  $indexPath = Join-Path $AdminSource "index.html"
  if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "Admin index.html not found: $indexPath"
  }
  $indexHtml = Read-EndlessNetUtf8Text -Path $indexPath
  $indexHtml = $indexHtml `
    -replace 'src="session_bootstrap\.js(?:\?v=[^"]*)?"', "src=`"session_bootstrap.js?v=$encodedBuildId`"" `
    -replace 'href="manifest\.json(?:\?v=[^"]*)?"', "href=`"manifest.json?v=$encodedBuildId`""
  if ($indexHtml -notmatch 'session_bootstrap\.js\?v=') {
    throw "Failed to add session bootstrap cache buster to $indexPath"
  }
  Write-EndlessNetUtf8Text -Path $indexPath -Value $indexHtml

  $sessionBootstrapPath = Join-Path $AdminSource "session_bootstrap.js"
  if (-not (Test-Path -LiteralPath $sessionBootstrapPath)) {
    throw "Admin session_bootstrap.js not found: $sessionBootstrapPath"
  }
  $sessionBootstrap = Read-EndlessNetUtf8Text -Path $sessionBootstrapPath
  $sessionBootstrap = $sessionBootstrap -replace `
    'new URL\("flutter_bootstrap\.js(?:\?v=[^"]*)?", document\.baseURI\)', `
    "new URL(`"flutter_bootstrap.js?v=$encodedBuildId`", document.baseURI)"
  if ($sessionBootstrap -notmatch 'flutter_bootstrap\.js\?v=') {
    throw "Failed to add Flutter bootstrap cache buster to $sessionBootstrapPath"
  }
  Write-EndlessNetUtf8Text -Path $sessionBootstrapPath -Value $sessionBootstrap

  $bootstrapPath = Join-Path $AdminSource "flutter_bootstrap.js"
  if (-not (Test-Path -LiteralPath $bootstrapPath)) {
    throw "Admin flutter_bootstrap.js not found: $bootstrapPath"
  }
  $bootstrap = Read-EndlessNetUtf8Text -Path $bootstrapPath
  $buildConfigPattern = '(?s)_flutter\.buildConfig\s*=\s*(\{.*?\});'
  $buildConfigMatch = [regex]::Match($bootstrap, $buildConfigPattern)
  if (-not $buildConfigMatch.Success) {
    throw "Flutter buildConfig not found in $bootstrapPath"
  }

  $buildConfig = $buildConfigMatch.Groups[1].Value | ConvertFrom-Json
  $versionedEntrypoints = 0
  foreach ($build in @($buildConfig.builds)) {
    foreach ($propertyName in @("mainJsPath", "mainWasmPath", "jsSupportRuntimePath")) {
      if ($build.PSObject.Properties.Name -contains $propertyName) {
        $build.$propertyName = Set-EndlessNetAdminPathCacheVersion `
          -Path ([string]$build.$propertyName) `
          -BuildId $encodedBuildId
        $versionedEntrypoints++
      }
    }
  }
  if ($versionedEntrypoints -eq 0) {
    throw "No Flutter entrypoint paths found in $bootstrapPath"
  }

  $updatedBuildConfig = $buildConfig | ConvertTo-Json -Depth 20 -Compress
  $buildConfigRegex = [regex]::new($buildConfigPattern)
  $updatedBootstrap = $buildConfigRegex.Replace($bootstrap, {
    param($match)
    return "_flutter.buildConfig = $updatedBuildConfig;"
  }, 1)
  if ($updatedBootstrap -notmatch '\?v=') {
    throw "Failed to add Flutter entrypoint cache buster to $bootstrapPath"
  }
  Write-EndlessNetUtf8Text -Path $bootstrapPath -Value $updatedBootstrap
}

function Write-EndlessNetAdminRouteEntrypoints {
  param([Parameter(Mandatory = $true)][string]$AdminSource)

  $indexPath = Join-Path $AdminSource "index.html"
  if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "Admin index.html not found: $indexPath"
  }

  Remove-Item -LiteralPath (Join-Path $AdminSource "billing\billing.js") -Force -ErrorAction SilentlyContinue

  $indexHtml = Read-EndlessNetUtf8Text -Path $indexPath
  foreach ($route in $adminRoutes) {
    $segments = @($route -split "/" | Where-Object { $_.Trim() -ne "" })
    $baseHref = "../" * $segments.Count
    if ($baseHref -eq "") {
      $baseHref = "./"
    }
    $routeDir = Join-Path $AdminSource $route
    New-Item -ItemType Directory -Path $routeDir -Force | Out-Null
    $routeHtml = $indexHtml -replace '<base href="[^"]*">', "<base href=`"$baseHref`">"
    Write-EndlessNetUtf8Text -Path (Join-Path $routeDir "index.html") -Value $routeHtml
  }
}

function Disable-EndlessNetAdminServiceWorker {
  param([Parameter(Mandatory = $true)][string]$AdminSource)

  $bootstrapPath = Join-Path $AdminSource "flutter_bootstrap.js"
  if (Test-Path -LiteralPath $bootstrapPath) {
    $bootstrap = Read-EndlessNetUtf8Text -Path $bootstrapPath
    $registrationPattern = '(?s)_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{\s*serviceWorkerVersion:\s*"[^"]*"\s*\}\s*\}\);'
    $updated = $bootstrap -replace $registrationPattern, '_flutter.loader.load();'
    if ($updated -match '(?s)_flutter\.loader\.load\(\{\s*serviceWorkerSettings:') {
      throw "Failed to remove Flutter service worker registration from $bootstrapPath"
    }
    Write-EndlessNetUtf8Text -Path $bootstrapPath -Value $updated
  }

  $serviceWorkerPath = Join-Path $AdminSource "flutter_service_worker.js"
  $serviceWorker = @'
'use strict';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name === 'flutter-app-cache' ||
        name === 'flutter-app-manifest' ||
        name === 'flutter-temp-cache' ||
        name.startsWith('flutter-'))
      .map((name) => caches.delete(name)));

    await self.clients.claim();
    await self.registration.unregister();

    const clients = await self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    });
    for (const client of clients) {
      if ('navigate' in client) {
        client.navigate(client.url);
      }
    }
  })());
});
'@
  Write-EndlessNetUtf8Text -Path $serviceWorkerPath -Value $serviceWorker
}

if ((Test-Path -LiteralPath (Join-Path $adminFlutter "pubspec.yaml")) -and -not $SkipFlutterBuild) {
  if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "flutter is required to build the admin frontend: $adminFlutter"
  }
  Push-Location $adminFlutter
  try {
    flutter pub get
    flutter build web --release --no-wasm-dry-run --no-web-resources-cdn --pwa-strategy=none
  }
  finally {
    Pop-Location
  }

  $flutterBuild = Join-Path $adminFlutter "build\web"
  if (-not (Test-Path -LiteralPath $flutterBuild)) {
    throw "Flutter admin build output not found: $flutterBuild"
  }

  New-Item -ItemType Directory -Path $adminSource -Force | Out-Null
  $resolvedAdminSource = Assert-EndlessNetChildPath `
    -Root $repoRoot `
    -Path $adminSource `
    -Message "Refusing to clean outside repository root: $adminSource"
  Clear-EndlessNetDirectory -Path $resolvedAdminSource
  Copy-Item -Path (Join-Path $flutterBuild "*") -Destination $adminSource -Recurse -Force
  Remove-Item -LiteralPath (Join-Path $adminSource ".last_build_id") -ErrorAction SilentlyContinue
}

if (-not (Test-Path -LiteralPath $adminSource)) {
  throw "Admin frontend assets not found: $adminSource"
}

if (-not (Test-Path -LiteralPath $installScript)) {
  throw "Install script not found: $installScript"
}

Disable-EndlessNetAdminServiceWorker -AdminSource $adminSource
$adminBuildId = Resolve-EndlessNetAdminBuildId -AdminSource $adminSource -BuildId $BuildId
Add-EndlessNetAdminCacheBuster -AdminSource $adminSource -BuildId $adminBuildId
Write-EndlessNetAdminRouteEntrypoints -AdminSource $adminSource

New-Item -ItemType Directory -Path $adminOutput -Force | Out-Null

if ($Clean) {
  $resolvedAdminOutput = Assert-EndlessNetChildPath `
    -Root $repoRoot `
    -Path $adminOutput `
    -Message "Refusing to clean outside repository root: $adminOutput"
  $preserveNames = if ($Standalone) { @(".git", "CNAME") } else { @() }
  Clear-EndlessNetDirectory -Path $resolvedAdminOutput -PreserveNames $preserveNames
}

Remove-Item -LiteralPath (Join-Path $adminOutput "billing\billing.js") -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $adminSource "*") -Destination $adminOutput -Recurse -Force
Copy-Item -LiteralPath $installScript -Destination (Join-Path $output "install.sh") -Force
New-Item -ItemType File -Path (Join-Path $output ".nojekyll") -Force | Out-Null

if ($Standalone) {
  $resolvedApiBaseUrl = $ApiBaseUrl.Trim().TrimEnd("/")
  if ($resolvedApiBaseUrl -eq "") {
    throw "ApiBaseUrl is required for a standalone admin Pages build."
  }
  $resolvedSiteRoot = $SiteRoot.Trim()
  if ($resolvedSiteRoot -eq "") {
    throw "SiteRoot is required for a standalone admin Pages build."
  }
  $resolvedAdminUrl = $AdminUrl.Trim()
  if ($resolvedAdminUrl -eq "") {
    throw "AdminUrl is required for a standalone admin Pages build."
  }
  foreach ($value in @($resolvedApiBaseUrl, $resolvedSiteRoot, $resolvedAdminUrl)) {
    $uri = $null
    if (-not [System.Uri]::TryCreate($value, [System.UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne "https") {
      throw "Standalone frontend URLs must be absolute HTTPS URLs: $value"
    }
  }
  $apiBaseJson = ConvertTo-Json $resolvedApiBaseUrl -Compress
  $siteRootJson = ConvertTo-Json $resolvedSiteRoot -Compress
  $config = @"
window.ENDLESSNET_API_BASE = $apiBaseJson;
window.ENDLESSNET_ADMIN_ROOT = "/";
window.ENDLESSNET_SITE_ROOT = $siteRootJson;
"@
  Write-EndlessNetUtf8Text -Path (Join-Path $output "config.js") -Value $config

  $runtimeConfig = [ordered]@{
    schema_version = 1
    api_base_url = $resolvedApiBaseUrl
    site_url = $resolvedSiteRoot
    admin_url = $resolvedAdminUrl
    admin_root = "/"
  } | ConvertTo-Json -Depth 5
  Write-EndlessNetUtf8Text -Path (Join-Path $output "runtime-config.json") -Value ($runtimeConfig + "`n")
}

Write-Host "Admin Pages frontend written to $adminOutput"
Write-Host "Admin Pages cache buster build id: $adminBuildId"
