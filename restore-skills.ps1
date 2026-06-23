$ErrorActionPreference = "Stop"

$bundleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$codexSource = Join-Path $bundleRoot "skills\codex"
$agentsSource = Join-Path $bundleRoot "skills\agents"
$codexDest = Join-Path $HOME ".codex\skills"
$agentsDest = Join-Path $HOME ".agents\skills"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

function Ensure-ParentDirectory($path) {
    $parent = Split-Path -Parent $path
    if (!(Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Ensure-CodexSystemFolder {
    $bundleSystem = Join-Path $codexSource ".system"
    $localSystem = Join-Path $codexDest ".system"

    if (!(Test-Path -LiteralPath $bundleSystem) -and (Test-Path -LiteralPath $localSystem)) {
        Copy-Item -LiteralPath $localSystem -Destination $bundleSystem -Recurse -Force
        Write-Output "Seeded local .system into bundle skills/codex/.system"
    }
}

function Backup-IfNeeded($path) {
    if (!(Test-Path -LiteralPath $path)) {
        return
    }

    $item = Get-Item -LiteralPath $path -Force
    if ($item.LinkType) {
        return
    }

    $backupPath = $path + ".pre-link-backup-" + $timestamp
    Move-Item -LiteralPath $path -Destination $backupPath
    Write-Output ("Backed up existing directory: " + $backupPath)
}

function Ensure-Junction($path, $target) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if ($item.LinkType -and $item.Target -contains $target) {
            Write-Output ("Junction already active: " + $path + " -> " + $target)
            return
        }

        if ($item.LinkType) {
            Remove-Item -LiteralPath $path -Force
        } else {
            throw "Expected $path to be absent or already backed up before linking."
        }
    }

    New-Item -ItemType Junction -Path $path -Target $target | Out-Null
    Write-Output ("Created junction: " + $path + " -> " + $target)
}

Ensure-ParentDirectory $codexDest
Ensure-ParentDirectory $agentsDest
Ensure-CodexSystemFolder
Backup-IfNeeded $codexDest
Backup-IfNeeded $agentsDest
Ensure-Junction $codexDest $codexSource
Ensure-Junction $agentsDest $agentsSource

Write-Output ""
Write-Output "Git source mode enabled. Restart Codex to pick up linked skills."
