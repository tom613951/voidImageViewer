# Upload voidImageViewer release packages to GitHub using REST API
# Usage: .\upload_release.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Go up to root directory
Set-Location ..

$token = $env:GITHUB_TOKEN
if ([string]::IsNullOrEmpty($token)) {
    # Try retrieving it from gh CLI
    $token = & gh auth token 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($token)) {
        Write-Host "Error: GITHUB_TOKEN environment variable is not set and 'gh auth token' failed!" -ForegroundColor Red
        Write-Host "Please set GITHUB_TOKEN or run 'gh auth login' first." -ForegroundColor Yellow
        exit 1
    }
}
$token = $token.Trim()

$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

# Construct Chinese description safely using [char]
$ch_zhong = [char]0x4e2d
$ch_wen = [char]0x6587
$ch_han = [char]0x6c49
$ch_hua = [char]0x5316
$ch_ban = [char]0x7248
$ch_fa = [char]0x53d1
$ch_xing = [char]0x884c
$ch_period = [char]0x3002
$ch_bao = [char]0x5305
$ch_han2 = [char]0x542b
$ch_an = [char]0x5b89
$ch_zhuang = [char]0x88c5
$ch_he = [char]0x548c
$ch_mian = [char]0x514d
$ch_lv = [char]0x7eff
$ch_se = [char]0x8272
$ch_bian = [char]0x4fbf
$ch_xie = [char]0x643a

$bodyText = "voidImageViewer v1.0.0.15 " + $ch_zhong + $ch_wen + $ch_han + $ch_hua + $ch_ban + $ch_fa + $ch_xing + $ch_period + $ch_bao + $ch_han2 + $ch_an + $ch_zhuang + $ch_bao + " (Setup) " + $ch_he + $ch_mian + $ch_an + $ch_zhuang + $ch_lv + $ch_se + $ch_bian + $ch_xie + $ch_ban + " (ZIP)."

# 1. Create Release
$body = @{
    tag_name = "v1.0.0.15"
    name = "v1.0.0.15"
    body = $bodyText
    draft = $false
    prerelease = $false
} | ConvertTo-Json

Write-Host "Creating GitHub release v1.0.0.15..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/tom613951/voidImageViewer/releases" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    $uploadUrl = $release.upload_url.Replace("{?name,label}", "")
    Write-Host "Release created successfully."
    Write-Host "Upload URL: $uploadUrl"
} catch {
    Write-Host "Create release returned an error (it might already exist). Fetching existing release..."
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/tom613951/voidImageViewer/releases/tags/v1.0.0.15" -Method Get -Headers $headers
        $uploadUrl = $release.upload_url.Replace("{?name,label}", "")
        Write-Host "Found existing release."
        Write-Host "Upload URL: $uploadUrl"
    } catch {
        Write-Host "Error: Could not retrieve release: $_"
        exit 1
    }
}

# 2. Upload Assets
$files = @(
    @{ Path = "voidImageViewer-1.0.0.15.x64.zh-CN-Setup.exe"; ContentType = "application/octet-stream"; Name = "voidImageViewer-1.0.0.15.x64.zh-CN-Setup.exe" },
    @{ Path = "voidImageViewer-1.0.0.15.x64.zh-CN-Portable.zip"; ContentType = "application/zip"; Name = "voidImageViewer-1.0.0.15.x64.zh-CN-Portable.zip" }
)

foreach ($file in $files) {
    if (Test-Path $file.Path) {
        Write-Host "Uploading $($file.Name)..."
        try {
            $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $file.Path))
            $uploadHeaders = $headers.Clone()
            $uploadHeaders.Add("Content-Type", $file.ContentType)
            
            $uri = $uploadUrl + "?name=" + $file.Name
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $uploadHeaders -Body $bytes
            Write-Host "Uploaded $($file.Name) successfully!"
        } catch {
            Write-Host "Error uploading $($file.Name): $_"
        }
    } else {
        Write-Host "Warning: File not found: $($file.Path)"
    }
}

Write-Host "Done!"
