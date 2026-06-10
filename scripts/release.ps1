# scripts/release.ps1
# This script updates the version in the .toc file and zips the addon for release.

param (
    [string]$Version
)

# Set working directory to project root (one level up from scripts/)
$root = (Get-Item $PSScriptRoot).Parent.FullName
Push-Location $root

if (-not $Version) {
    $Version = Read-Host "Enter new version number (e.g., 1.1)"
}

if (-not $Version) { 
    Write-Host "No version entered. Aborting." -ForegroundColor Red
    Pop-Location
    exit 
}

$tocFile = "SoDRuneEnforcer.toc"
if (-not (Test-Path $tocFile)) {
    Write-Host "Error: $tocFile not found in $root!" -ForegroundColor Red
    Pop-Location
    exit
}

# 1. Update the .toc file version
$content = Get-Content $tocFile
$newContent = $content -replace "## Version: .*", "## Version: $Version"
Set-Content $tocFile $newContent -Encoding UTF8
Write-Host "Updated $tocFile to version $Version"

# 2. Prepare the zip file
$folderName = "SoDRuneEnforcer"
$zipName = "$folderName-v$Version.zip"
$releaseDir = "releases"

if (-not (Test-Path $releaseDir)) { New-Item -ItemType Directory -Path $releaseDir | Out-Null }

# Create a clean staging directory in Temp
$stagingBase = Join-Path $env:TEMP "SRE_Build_$(Get-Random)"
$stagingFolder = Join-Path $stagingBase $folderName
New-Item -ItemType Directory -Path $stagingFolder -Force | Out-Null

# Copy project files to staging (only core addon files)
Write-Host "Staging files..."
$filesToInclude = @("Core.lua", "RuneData.lua", "SoDRuneEnforcer.toc", "README.md")
foreach ($file in $filesToInclude) {
    Copy-Item -Path $file -Destination $stagingFolder
}

# 3. Create the Archive in the releases/ folder
$zipPath = Join-Path $releaseDir $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath }

Write-Host "Creating $zipPath..."
Compress-Archive -Path $stagingFolder -DestinationPath $zipPath

# 4. Cleanup
Remove-Item -Path $stagingBase -Recurse -Force
Pop-Location

Write-Host "Done! Your release is ready in: $zipPath" -ForegroundColor Green
