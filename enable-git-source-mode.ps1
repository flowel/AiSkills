$ErrorActionPreference = "Stop"

$bundleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Output ("Enabling Git source mode from: " + $bundleRoot)
powershell -ExecutionPolicy Bypass -File (Join-Path $bundleRoot "restore-skills.ps1")
powershell -ExecutionPolicy Bypass -File (Join-Path $bundleRoot "sync-skills.ps1")

Write-Output ""
Write-Output "Git source mode is configured. New skills installed through the linked live directories will land in this repo."
