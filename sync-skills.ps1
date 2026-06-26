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

# ----------------------------------------------------------------------
# Cleanup nested .git directories (defense-in-depth, two layers)
#
# Background: an earlier version of this script did a blind
# `Get-ChildItem -Recurse` and deleted every .git it found, including the
# bundle repo's own .git at $bundleRoot\.git. That wiped git state and
# severed the link to GitHub.
#
# Layer 1: defense-in-depth guard. If the bundle's own .git exists, refuse
# to do the blanket recursive scan altogether. Falling back to the explicit
# allow-list (Layer 2) keeps the original intent (kill stray nested .git)
# while making it physically impossible for the script to touch its own
# repo root.
#
# Layer 2: explicit allow-list of known nested .git locations. Only these
# paths are ever inspected for removal. The bundle root .git is not in
# this list, so even if Layer 1 is somehow bypassed, the root .git is
# still safe.
# ----------------------------------------------------------------------

function Remove-NestedGit([string]$parentDir) {
    if (!(Test-Path -LiteralPath $parentDir)) {
        return
    }
    Get-ChildItem -LiteralPath $parentDir -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq ".git" } |
        ForEach-Object {
            Write-Output ("Removing nested .git: " + $_.FullName)
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
}

# Layer 1: bail out of the recursive scan if the bundle is itself a git repo.
$bundleRepoGit = Join-Path $bundleRoot ".git"
$isBundleRepo = $false
if (Test-Path -LiteralPath $bundleRepoGit) {
    $bundleGitItem = Get-Item -LiteralPath $bundleRepoGit -Force -ErrorAction SilentlyContinue
    # A real .git directory (or file in worktree mode) marks this as a repo.
    if ($bundleGitItem -and !$bundleGitItem.LinkType) {
        $isBundleRepo = $true
    }
}

if ($isBundleRepo) {
    Write-Output ("[guard] Detected bundle repo at " + $bundleRepoGit + " — skipping recursive .git scan, using allow-list only.")
} else {
    # Original behavior: bundle is not a git repo, do the recursive scan.
    Get-ChildItem -LiteralPath $bundleRoot -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq ".git" } |
        ForEach-Object {
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
        }
}

# Layer 2: explicit allow-list of nested .git cleanup paths. Always runs,
# even when the bundle is itself a repo. Only known skill-folder locations
# are ever inspected; the bundle root .git is never in scope.
foreach ($skillDir in @($codexSkills)) {
    Remove-NestedGit (Join-Path $codexRoot $skillDir.Name)
}
foreach ($skillDir in @($agentSkills)) {
    Remove-NestedGit (Join-Path $agentsRoot $skillDir.Name)
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
    canonical_location = $bundleRoot.ToLowerInvariant()
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
