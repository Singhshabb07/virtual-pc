<#
.SYNOPSIS
    Installs and configures Sunshine streaming host and ViGEmBus gamepad driver.
.DESCRIPTION
    Sunshine is the host server for Moonlight streaming. This script installs
    the ViGEmBus gamepad emulation driver (enabling controller support for GTA V),
    installs Sunshine, configures NVENC hardware encoding presets, and installs
    the Sunshine Windows service.
#>

$ErrorActionPreference = "Continue"
Write-Host ">>> Installing Sunshine Streaming Server and ViGEmBus..."

# 1. Install ViGEmBus (Virtual Gamepad Emulation Bus for Xbox 360 / One controller emulation)
Write-Host "[1/3] Installing ViGEmBus Driver..."
try {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install vigembus -y --no-progress
    } else {
        $VigemUrl = "https://github.com/nefarius/ViGEmBus/releases/latest/download/ViGEmBus_Setup_x64.exe"
        $VigemPath = "C:\Codevern\ViGEmBus_Setup.exe"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $VigemUrl -OutFile $VigemPath -UseBasicParsing
        Start-Process -FilePath $VigemPath -ArgumentList "/quiet" -Wait
    }
    Write-Host "ViGEmBus driver installed."
} catch {
    Write-Warning "Could not install ViGEmBus: $_"
}

# 2. Install Sunshine Host
Write-Host "[2/3] Installing Sunshine Host Application..."
$SunshineDir = "C:\Program Files\Sunshine"
$SunshineConfigDir = "$env:USERPROFILE\.config\sunshine"
$GlobalConfigDir = "C:\Program Files\Sunshine\config"

try {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install sunshine -y --no-progress
    } else {
        $SunshineUrl = "https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-windows-installer.exe"
        $SunshineInstaller = "C:\Codevern\sunshine-installer.exe"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $SunshineUrl -OutFile $SunshineInstaller -UseBasicParsing
        Start-Process -FilePath $SunshineInstaller -ArgumentList "/S" -Wait
    }
} catch {
    Write-Warning "Sunshine installation error: $_"
}

# 3. Configure Sunshine for NVIDIA T4 Hardware NVENC Encoding
Write-Host "[3/3] Generating Optimized Sunshine Configuration..."
$TargetConfigDir = "C:\Program Files\Sunshine\config"
New-Item -ItemType Directory -Force -Path $TargetConfigDir | Out-Null

$SunshineConfig = @"
# Codevern Cloud PC - Sunshine Configuration
# Optimized for NVIDIA T4 GPU and Low-Latency Moonlight Client Streaming

# Network Ports
port = 47989
origin_pin_allowed = pc

# Encoder Optimization (NVENC Hardware Acceleration)
encoder = nvenc
nvenc_preset = p1
nvenc_tune = ull
nvenc_rate_control = cbr
nvenc_coder = cabac
nvenc_twopass = disabled

# Supported Display Profiles
resolutions = [
    1280x720,
    1920x1080,
    2560x1440,
    3840x2160
]

fps = [
    30,
    60,
    120
]

# Audio Configuration
channels = 2

# Gamepad Emulation
gamepad = x360

# Capture Mode
capture = dxgi
"@

Set-Content -Path "$TargetConfigDir\sunshine.conf" -Value $SunshineConfig -Encoding UTF8

# Install Sunshine as Windows Service
$SunshineExe = "C:\Program Files\Sunshine\sunshine.exe"
if (Test-Path $SunshineExe) {
    Write-Host "Registering Sunshine as Windows Service..."
    Start-Process -FilePath $SunshineExe -ArgumentList "--install-service" -Wait
    Start-Service -Name "sunshine" -ErrorAction SilentlyContinue
    Write-Host "Sunshine Service registered and started."
} else {
    Write-Warning "Sunshine executable not found at $SunshineExe."
}
