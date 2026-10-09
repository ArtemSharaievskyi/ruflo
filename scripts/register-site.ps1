param(
  [Parameter(Mandatory = $true)][string]$ProjectPath
)
$ErrorActionPreference = 'Stop'
$factory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$metadata = Get-Content -LiteralPath (Join-Path $project 'config/site.json') -Raw | ConvertFrom-Json
$siteId = [guid]::Parse($metadata.site_id).ToString()
if ($metadata.slug -notmatch '^[a-z][a-z0-9-]*$') { throw 'Invalid site slug' }
$state = Join-Path $project '.site-state'
$memory = Join-Path $state 'ruflo/memory.db'
New-Item -ItemType Directory -Path (Join-Path $state 'ruflo'), (Join-Path $state 'sessions'), (Join-Path $state 'reports'), (Join-Path $state 'tmp'), (Join-Path $project '.codex') -Force | Out-Null
$rufloCli = Join-Path $factory 'node_modules/ruflo/bin/ruflo.js'
if (-not (Test-Path -LiteralPath $rufloCli)) { throw 'Run npm ci in the Ruflo folder first' }
if (-not (Test-Path -LiteralPath $memory)) {
  Push-Location -LiteralPath $project
  try {
    & node $rufloCli memory init --backend sqlite --path $memory | Out-Null
  } finally {
    Pop-Location
  }
  if ($LASTEXITCODE -ne 0) { throw 'Ruflo memory initialization failed' }
}
$link = Join-Path $project '.codex/agents'
$target = Join-Path $factory '.codex/agents'
if (Test-Path -LiteralPath $link) {
  $existing = Get-Item -LiteralPath $link
  if ($existing.LinkType -ne 'Junction' -or $existing.Target -notcontains $target) { throw "Conflicting agent directory: $link" }
} else {
  New-Item -ItemType Junction -Path $link -Target $target | Out-Null
}
$registryPath = Join-Path $factory 'registry.local.json'
$registry = if (Test-Path -LiteralPath $registryPath) { Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{ schemaVersion = 1; sites = @() } }
$conflict = @($registry.sites | Where-Object { ($_.site_id -eq $siteId -or $_.slug -eq $metadata.slug) -and $_.project_path -ne $project })
if ($conflict.Count) { throw 'Registry has a conflicting site_id or slug' }
if (-not @($registry.sites | Where-Object site_id -eq $siteId).Count) {
  $registry.sites = @($registry.sites) + @([pscustomobject]@{ site_id = $siteId; slug = $metadata.slug; project_path = $project; state_path = $state })
  $registry | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $registryPath -Encoding utf8
}
Write-Output "registered=$($metadata.slug) site_id=$siteId"
