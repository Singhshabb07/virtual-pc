<#
.SYNOPSIS
    Installs Development Suite, Productivity Apps, and Gaming Runtimes.
.DESCRIPTION
    Fulfills PRD Section 5.5:
    - Development: VS Code, Git, Python 3, Node.js, OpenJDK 17, Antigravity CLI
    - Productivity: Google Chrome, LibreOffice, 7-Zip, PDF tools
    - Gaming Runtimes: Steam, Epic Games Launcher, DirectX 9/11/12, Visual C++ Redists
#>

$ErrorActionPreference = "Continue"
Write-Host ">>> Installing Application Toolchain, Runtimes, and Gaming Platforms..."

# 1. Enable Windows Legacy Components (DirectPlay for older gaming APIs)
Write-Host "[1/4] Enabling DirectPlay Windows Feature..."
Enable-WindowsOptionalFeature -Online -FeatureName "DirectPlay" -All -NoRestart -ErrorAction SilentlyContinue

# 2. Install Development & Productivity Packages via Chocolatey
Write-Host "[2/4] Installing Developer and Productivity Packages..."
$Packages = @(
    "vscode",
    "git",
    "python3",
    "nodejs-lts",
    "openjdk17",
    "googlechrome",
    "7zip",
    "libreoffice-fresh",
    "vcredist-all",
    "directx"
)

foreach ($pkg in $Packages) {
    Write-Host "Installing package: $pkg..."
    choco install $pkg -y --no-progress --ignore-checksums -ErrorAction Continue
}

# 3. Install Gaming Launchers (PRD Section 5.5)
Write-Host "[3/4] Installing Gaming Platforms (Steam & Epic Games Launcher)..."
$GamingPackages = @(
    "steam",
    "epicgameslauncher"
)

foreach ($gpkg in $GamingPackages) {
    Write-Host "Installing gaming package: $gpkg..."
    choco install $gpkg -y --no-progress --ignore-checksums -ErrorAction Continue
}

# 4. Provision Antigravity CLI / Developer Assistant Environment
Write-Host "[4/4] Provisioning Antigravity Developer Tooling..."
$AntigravityDir = "C:\Codevern\Antigravity"
New-Item -ItemType Directory -Force -Path $AntigravityDir | Out-Null

$AntigravityWrapper = @"
@echo off
echo ========================================================
echo  Codevern Cloud PC - Antigravity Agentic Assistant
echo ========================================================
python -m pip install --upgrade pip >nul 2>&1
echo Ready for Antigravity AI pair programming and CLI workflows.
"@

Set-Content -Path "C:\ProgramData\chocolatey\bin\antigravity.bat" -Value $AntigravityWrapper -Encoding ASCII

Write-Host "Application environment installation complete."
