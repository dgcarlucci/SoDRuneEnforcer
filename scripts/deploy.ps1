# scripts/deploy.ps1
# This script deploys the latest zip from the releases folder to the WoW AddOns directory.

$wowPath = "E:\Battle.net\World of Warcraft\_classic_era_\Interface\AddOns"
$root = (Get-Item $PSScriptRoot).Parent.FullName
$releaseDir = Join-Path $root "releases"

if (-not (Test-Path $wowPath)) {
    Write-Host "Error: WoW AddOns directory not found at $wowPath" -ForegroundColor Red
    exit
}

# 1. Find the latest zip in the releases folder
$latestZip = Get-ChildItem -Path $releaseDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $latestZip) {
    Write-Host "Error: No zip files found in $releaseDir. Run release.ps1 first." -ForegroundColor Red
    exit
}

Write-Host "Found latest release: $($latestZip.Name)"

# 2. Extract to WoW directory
$targetPath = Join-Path $wowPath "SoDRuneEnforcer"

if (Test-Path $targetPath) {
    Write-Host "Removing existing addon folder: $targetPath"
    Remove-Item -Path $targetPath -Recurse -Force
}

Write-Host "Deploying to $wowPath..."
Expand-Archive -Path $latestZip.FullName -DestinationPath $wowPath -Force

Write-Host "Deployment Successful! Please /reload in WoW." -ForegroundColor Green
