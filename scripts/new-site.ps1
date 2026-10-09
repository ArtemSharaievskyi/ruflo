param(
  [Parameter(Mandatory = $true)][ValidatePattern('^[a-z][a-z0-9-]*$')][string]$Slug
)
$ErrorActionPreference = 'Stop'
$factory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$parent = (Resolve-Path (Join-Path $factory '..')).Path
$project = Join-Path $parent $Slug
if (Test-Path -LiteralPath $project) { throw "Project already exists: $project" }
$registryPath = Join-Path $factory 'registry.local.json'
$rufloCli = Join-Path $factory 'node_modules/ruflo/bin/ruflo.js'
if (-not (Test-Path -LiteralPath $rufloCli)) { throw 'Run npm ci in the Ruflo folder first' }
$registry = if (Test-Path -LiteralPath $registryPath) { Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{ schemaVersion = 1; sites = @() } }
if (@($registry.sites | Where-Object { $_.slug -eq $Slug }).Count) { throw "Slug already registered: $Slug" }
$siteId = [guid]::NewGuid().ToString()
New-Item -ItemType Directory -Path $project, (Join-Path $project 'config'), (Join-Path $project 'docs'), (Join-Path $project 'assets'), (Join-Path $project '.site-state/ruflo'), (Join-Path $project '.site-state/sessions'), (Join-Path $project '.site-state/reports'), (Join-Path $project '.site-state/tmp') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $project '.codex') -Force | Out-Null
New-Item -ItemType Junction -Path (Join-Path $project '.codex/agents') -Target (Join-Path $factory '.codex/agents') | Out-Null
@{ schemaVersion = 1; site_id = $siteId; slug = $Slug } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $project 'config/site.json') -Encoding utf8
"# Client brief`n`n" | Set-Content -LiteralPath (Join-Path $project 'docs/client-brief.md') -Encoding utf8
New-Item -ItemType File -Path (Join-Path $project 'assets/.gitkeep') | Out-Null
@('.site-state/', '.claude/', '.claude-flow/', '.swarm/', '.ruvector/', '.ruflo/', '.codex/agents/', '.codex/config.toml', '.env', '.env.*', '!.env.example', 'node_modules/', '.next/', 'dist/', 'coverage/', '*.log') | Set-Content -LiteralPath (Join-Path $project '.gitignore') -Encoding utf8
git -C $project init -b main | Out-Null
Push-Location -LiteralPath $project
try {
  & node $rufloCli memory init --backend sqlite --path (Join-Path $project '.site-state/ruflo/memory.db') | Out-Null
} finally {
  Pop-Location
}
if ($LASTEXITCODE -ne 0) { throw 'Ruflo memory initialization failed' }
$registry.sites = @($registry.sites) + @([pscustomobject]@{ site_id = $siteId; slug = $Slug; project_path = $project; state_path = (Join-Path $project '.site-state') })
$registry | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $registryPath -Encoding utf8
Write-Output "site_id=$siteId"
Write-Output "project=$project"
Write-Output "Open with: powershell -File `"$PSScriptRoot/open-site.ps1`" -Slug $Slug"
