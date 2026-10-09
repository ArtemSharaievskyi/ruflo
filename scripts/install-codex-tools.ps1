$ErrorActionPreference = 'Stop'
$factory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$codexHome = Join-Path $env:USERPROFILE '.codex'
$skillsHome = Join-Path $codexHome 'skills'
New-Item -ItemType Directory -Path $skillsHome -Force | Out-Null
$agentsLink = Join-Path $codexHome 'agents'
$agentsTarget = Join-Path $factory '.codex/agents'
if (Test-Path -LiteralPath $agentsLink) {
  $existing = Get-Item -LiteralPath $agentsLink
  if ($existing.LinkType -ne 'Junction' -or $existing.Target -notcontains $agentsTarget) { throw "Conflicting user agent directory: $agentsLink" }
} else {
  New-Item -ItemType Junction -Path $agentsLink -Target $agentsTarget | Out-Null
}
Get-ChildItem -LiteralPath (Join-Path $factory '.agents/skills') -Directory | ForEach-Object {
  $link = Join-Path $skillsHome $_.Name
  if (Test-Path -LiteralPath $link) {
    $existing = Get-Item -LiteralPath $link
    if ($existing.LinkType -ne 'Junction' -or $existing.Target -notcontains $_.FullName) { throw "Conflicting skill directory: $link" }
  } else {
    New-Item -ItemType Junction -Path $link -Target $_.FullName | Out-Null
  }
}
Write-Output 'Shared agents and skills linked into Codex user scope.'
