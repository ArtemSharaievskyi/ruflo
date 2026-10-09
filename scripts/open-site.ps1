param(
  [Parameter(Mandatory = $true)][ValidatePattern('^[a-z][a-z0-9-]*$')][string]$Slug,
  [switch]$PrintOnly
)
$ErrorActionPreference = 'Stop'
$factory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$registry = Get-Content -LiteralPath (Join-Path $factory 'registry.local.json') -Raw | ConvertFrom-Json
$entry = @($registry.sites | Where-Object { $_.slug -eq $Slug })
if ($entry.Count -ne 1) { throw "Expected one registered site for $Slug" }
$project = (Resolve-Path -LiteralPath $entry[0].project_path).Path
$meta = Get-Content -LiteralPath (Join-Path $project 'config/site.json') -Raw | ConvertFrom-Json
if ($meta.site_id -ne $entry[0].site_id) { throw 'Registry site_id does not match project metadata' }
$state = (Resolve-Path -LiteralPath $entry[0].state_path).Path
if (-not $state.StartsWith($project + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'State directory must be inside the project' }
$env:CLAUDE_FLOW_DB_PATH = Join-Path $state 'ruflo/memory.db'
$env:CLAUDE_FLOW_MEMORY_PATH = Join-Path $state 'ruflo'
$env:SITE_ID = $meta.site_id
Write-Output "site_id=$($meta.site_id)"
Write-Output "project=$project"
Write-Output "ruflo_memory=$env:CLAUDE_FLOW_DB_PATH"
if ($PrintOnly) { return }
$rufloCli = Join-Path $factory 'node_modules/ruflo/bin/ruflo.js'
if (-not (Test-Path -LiteralPath $rufloCli)) { throw 'Run npm ci in the Ruflo folder before opening a site' }
$rufloConfig = "mcp_servers.ruflo.args=['$rufloCli','mcp','start']"
$memoryTools = "mcp_servers.ruflo.enabled_tools=['memory_store','memory_retrieve','memory_search','memory_list','memory_stats']"
$rufloCwd = "mcp_servers.ruflo.cwd='$project'"
$dbConfig = "mcp_servers.ruflo.env.CLAUDE_FLOW_DB_PATH='$env:CLAUDE_FLOW_DB_PATH'"
$memoryRootConfig = "mcp_servers.ruflo.env.CLAUDE_FLOW_MEMORY_PATH='$env:CLAUDE_FLOW_MEMORY_PATH'"
& codex -C $project -a on-request -s workspace-write -c "mcp_servers.ruflo.command='node'" -c $rufloConfig -c $memoryTools -c $rufloCwd -c $dbConfig -c $memoryRootConfig
