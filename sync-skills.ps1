$ErrorActionPreference = "Stop"

$bundleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsRoot = Join-Path $bundleRoot "skills"
$manifestsRoot = Join-Path $bundleRoot "manifests"
$codexRoot = Join-Path $skillsRoot "codex"
$agentsRoot = Join-Path $skillsRoot "agents"
$codexLive = Join-Path $HOME ".codex\skills"
$agentsLive = Join-Path $HOME ".agents\skills"

New-Item -ItemType Directory -Path $manifestsRoot -Force | Out-Null

$codexSkills = @()
if (Test-Path -LiteralPath $codexRoot) {
    $codexSkills = Get-ChildItem -LiteralPath $codexRoot -Directory | Where-Object { $_.Name -ne ".system" }
}

$agentSkills = @()
if (Test-Path -LiteralPath $agentsRoot) {
    $agentSkills = Get-ChildItem -LiteralPath $agentsRoot -Directory
}

Get-ChildItem -LiteralPath $bundleRoot -Recurse -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq ".git" } |
    ForEach-Object {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }

$codexIsLinked = $false
$agentsIsLinked = $false

if (Test-Path -LiteralPath $codexLive) {
    $codexItem = Get-Item -LiteralPath $codexLive -Force
    $codexIsLinked = [bool]($codexItem.LinkType)
}

if (Test-Path -LiteralPath $agentsLive) {
    $agentsItem = Get-Item -LiteralPath $agentsLive -Force
    $agentsIsLinked = [bool]($agentsItem.LinkType)
}

$manifest = [ordered]@{
    exported_at = (Get-Date).ToString("s")
    layout = "git-source-mode-v1"
    canonical_location = $bundleRoot
    folders = @{
        codex = "skills/codex"
        agents = "skills/agents"
    }
    live_paths = @{
        codex = $codexLive
        agents = $agentsLive
    }
    link_status = @{
        codex = $codexIsLinked
        agents = $agentsIsLinked
    }
    codex_skills = @($codexSkills | ForEach-Object Name)
    agent_skills = @($agentSkills | ForEach-Object Name)
}

$manifest | ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath (Join-Path $manifestsRoot "installed-skills.json") -Encoding UTF8

@(
    "Skill Sync Bundle"
    ""
    "Canonical location: " + $bundleRoot
    "Git source mode: live skill folders should point here"
    ""
    "Codex link active: " + $codexIsLinked
    "Agents link active: " + $agentsIsLinked
    ""
    "Codex skills:"
    @($codexSkills | ForEach-Object { "- " + $_.Name })
    ""
    "Agent skills:"
    @($agentSkills | ForEach-Object { "- " + $_.Name })
) | Set-Content -LiteralPath (Join-Path $manifestsRoot "installed-skills.txt") -Encoding UTF8

Write-Output ""
Write-Output ("Bundle metadata refreshed at: " + $bundleRoot)
Write-Output ("Codex skills: " + $codexSkills.Count)
Write-Output ("Agent skills: " + $agentSkills.Count)
Write-Output ("Codex link active: " + $codexIsLinked)
Write-Output ("Agents link active: " + $agentsIsLinked)
