# Build CLion Installer and ZIP package for voidImageViewer (Chinese version)
# Usage: .\build_clion_installer.ps1

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Check if version.nsh exists
if (-not (Test-Path "version.nsh")) {
    Write-Host "Error: version.nsh not found!" -ForegroundColor Red
    exit 1
}

# Parse version
$ver = "1.0.0.15"
$versionContent = Get-Content "version.nsh"
foreach ($line in $versionContent) {
    if ($line -match '!define VERSION "([^"]+)"') {
        $ver = $Matches[1]
        break
    }
}

$ExePath = "..\build\voidImageViewer.exe"

Write-Host "Checking for compiled executable at $ExePath..." -ForegroundColor Cyan
if (-not (Test-Path $ExePath)) {
    Write-Host "Error: Compiled executable not found!" -ForegroundColor Red
    Write-Host "Please build the project first in CLion." -ForegroundColor Yellow
    exit 1
}

# Check if NSIS is installed at default path
$makensis = "C:\Program Files (x86)\NSIS\makensis.exe"
if (-not (Test-Path $makensis)) {
    # Check if in PATH
    $makensisCmd = Get-Command makensis.exe -ErrorAction SilentlyContinue
    if ($makensisCmd) {
        $makensis = $makensisCmd.Source
    } else {
        Write-Host "Error: makensis.exe not found at standard path or in PATH!" -ForegroundColor Red
        Write-Host "Please install NSIS or add it to system PATH." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Found NSIS compiler at: $makensis" -ForegroundColor Green

# Convert Chinese configuration files to UTF-8 with BOM if the converter script exists
if (Test-Path "convert_to_utf8_bom.ps1") {
    Write-Host "Converting translation resource files to UTF-8 with BOM..." -ForegroundColor Cyan
    & powershell -ExecutionPolicy Bypass -File "convert_to_utf8_bom.ps1" | Out-Null
}

# Define arguments
$makensisArgs = @(
    "/Dx64",
    "/DLANG=Chinese",
    "/DEXE_PATH=$ExePath",
    "installer.nsi"
)

Write-Host "Compiling NSIS Setup package..." -ForegroundColor Cyan
$process = Start-Process -FilePath $makensis -ArgumentList $makensisArgs -Wait -NoNewWindow -PassThru

if ($process.ExitCode -eq 0) {
    $setupFileName = "voidImageViewer-$ver.x64.zh-CN-Setup.exe"
    Write-Host "Setup package built successfully!" -ForegroundColor Green
    if (Test-Path $setupFileName) {
        # Copy to project root directory
        Copy-Item -Path $setupFileName -Destination "..\$setupFileName" -Force
        Write-Host "Copied Setup to: $ScriptDir\..\$setupFileName" -ForegroundColor Green
    }
} else {
    Write-Host "NSIS Compilation failed!" -ForegroundColor Red
    exit 1
}

# Generate Portable ZIP package
Write-Host ""
Write-Host "Creating Portable ZIP package..." -ForegroundColor Cyan

$zipDirName = "voidImageViewer-$ver-x64-zh-CN-Portable"
$stagingDir = "..\build\$zipDirName"

if (Test-Path $stagingDir) {
    Remove-Item -Path $stagingDir -Recurse -Force | Out-Null
}

New-Item -ItemType Directory -Path $stagingDir | Out-Null
Copy-Item -Path $ExePath -Destination "$stagingDir\voidImageViewer.exe" -Force
if (Test-Path "..\LICENSE") {
    Copy-Item -Path "..\LICENSE" -Destination "$stagingDir\LICENSE.txt" -Force
}
if (Test-Path "..\README.md") {
    Copy-Item -Path "..\README.md" -Destination "$stagingDir\README.md" -Force
}

$zipFileName = "voidImageViewer-$ver.x64.zh-CN-Portable.zip"
$zipPath = "..\$zipFileName"

if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force | Out-Null
}

# Use Compress-Archive
Compress-Archive -Path "$stagingDir\*" -DestinationPath $zipPath -Force

# Clean up staging dir
Remove-Item -Path $stagingDir -Recurse -Force | Out-Null

Write-Host "Portable ZIP package created successfully!" -ForegroundColor Green
Write-Host "ZIP file path: $ScriptDir\..\$zipFileName" -ForegroundColor Green

Write-Host ""
Write-Host "All packages built successfully!" -ForegroundColor Green
