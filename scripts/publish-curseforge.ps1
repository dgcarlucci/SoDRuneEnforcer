# scripts/publish-curseforge.ps1
# This script uploads the latest zip from the releases folder to CurseForge using the CurseForge Upload API.

param (
    [string]$ProjectId,
    [string]$ApiToken,
    [string]$Version,
    [string]$Changelog = "Updated compliance grid UI, manual inspect triggers, and connected realm support."
)

$root = (Get-Item $PSScriptRoot).Parent.FullName
$releaseDir = Join-Path $root "releases"

# Load .env file if it exists in the root directory
$envFile = Join-Path $root ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $key, $value = $line -split '=', 2
            if ($key -and $value) {
                $key = $key.Trim()
                $value = $value.Trim().Trim("'").Trim('"')
                [System.Environment]::SetEnvironmentVariable($key, $value)
            }
        }
    }
}

# Fallback to env vars if parameters are empty
if (-not $ProjectId) {
    $ProjectId = [System.Environment]::GetEnvironmentVariable("CURSEFORGE_PROJECT_ID")
}
if (-not $ApiToken) {
    $ApiToken = [System.Environment]::GetEnvironmentVariable("CURSEFORGE_API_TOKEN")
}

if (-not $ProjectId -or -not $ApiToken) {
    Write-Host "Error: ProjectId and ApiToken are required (via parameters or .env file)." -ForegroundColor Red
    Write-Host "Usage: .\scripts\publish-curseforge.ps1 -ProjectId '<id>' -ApiToken '<token>' [-Version '<version>'] [-Changelog '<text>']" -ForegroundColor Yellow
    exit
}

# 1. Find the latest zip if not specified
if (-not $Version) {
    $latestZip = Get-ChildItem -Path $releaseDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latestZip) {
        Write-Host "Error: No zip files found in $releaseDir. Run release.ps1 first." -ForegroundColor Red
        exit
    }
    $zipPath = $latestZip.FullName
    $zipName = $latestZip.Name
    if ($zipName -match "v([\d\.]+)\.zip") {
        $Version = $Matches[1]
    } else {
        $Version = "1.0"
    }
} else {
    $zipName = "SoDRuneEnforcer-v$Version.zip"
    $zipPath = Join-Path $releaseDir $zipName
    if (-not (Test-Path $zipPath)) {
        Write-Host "Error: Zip file $zipPath not found." -ForegroundColor Red
        exit
    }
}

Write-Host "Publishing $zipName to CurseForge Project $ProjectId..."

# 2. Query game versions from CurseForge
$headers = @{
    "X-Api-Token" = $ApiToken
}

Write-Host "Fetching WoW Classic game versions from CurseForge..."
$versionsUrl = "https://wow.curseforge.com/api/game/versions"
try {
    $cfVersions = Invoke-RestMethod -Uri $versionsUrl -Headers $headers -Method Get
} catch {
    Write-Host "Error: Failed to fetch game versions from CurseForge: $_" -ForegroundColor Red
    exit
}

# Filter version IDs for WoW Classic 1.15.x (Season of Discovery)
$targetVersions = @()
foreach ($v in $cfVersions) {
    if ($v.name -like "1.15.*") {
        $targetVersions += $v.id
    }
}

if ($targetVersions.Count -eq 0) {
    Write-Host "Warning: No '1.15.*' game versions found. Trying to find exact '1.15' version..." -ForegroundColor Yellow
    foreach ($v in $cfVersions) {
        if ($v.name -eq "1.15") {
            $targetVersions += $v.id
        }
    }
}

if ($targetVersions.Count -eq 0) {
    Write-Host "Error: Could not determine game version IDs for WoW Classic 1.15." -ForegroundColor Red
    exit
}

Write-Host "Found compatible game version IDs: $($targetVersions -join ', ')"

# 3. Construct Metadata JSON
$metadata = @{
    changelog = $Changelog
    changelogType = "text"
    displayName = "SoD Rune Enforcer v$Version"
    gameVersions = $targetVersions
    releaseType = "release"
} | ConvertTo-Json -Compress

# 4. Perform Multipart Upload
$uploadUrl = "https://wow.curseforge.com/api/projects/$ProjectId/upload-file"

# Ensure System.Net.Http is loaded
[Void][System.Reflection.Assembly]::LoadWithPartialName("System.Net.Http")

$httpClient = New-Object System.Net.Http.HttpClient
$httpClient.DefaultRequestHeaders.Add("X-Api-Token", $ApiToken)

$content = New-Object System.Net.Http.MultipartFormDataContent

# Add metadata part
$metadataContent = New-Object System.Net.Http.StringContent($metadata)
$metadataContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/json")
$content.Add($metadataContent, "metadata")

# Add file part
$fileStream = [System.IO.File]::OpenRead($zipPath)
$fileContent = New-Object System.Net.Http.StreamContent($fileStream)
$fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/zip")
$content.Add($fileContent, "file", $zipName)

Write-Host "Uploading to CurseForge..."
try {
    $response = $httpClient.PostAsync($uploadUrl, $content).GetAwaiter().GetResult()
    $responseBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    
    if ($response.IsSuccessStatusCode) {
        Write-Host "Upload Successful! CurseForge File ID: $responseBody" -ForegroundColor Green
    } else {
        Write-Host "Error: CurseForge Upload failed with status code $($response.StatusCode)" -ForegroundColor Red
        Write-Host "Details: $responseBody" -ForegroundColor Red
    }
} catch {
    Write-Host "Error: Failed to perform upload request: $_" -ForegroundColor Red
} finally {
    $fileStream.Close()
    $httpClient.Dispose()
}
