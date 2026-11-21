<#
.SYNOPSIS
    Installs official NVIDIA GRID / Gaming drivers for AWS EC2 G4dn (NVIDIA T4).
.DESCRIPTION
    Downloads NVIDIA GRID driver from AWS official repository, installs in silent mode,
    and configures registry settings for headless Cloud Gaming performance.
#>

$ErrorActionPreference = "Continue"
Write-Host ">>> Checking NVIDIA GPU Driver Status..."

# Check if nvidia-smi exists and GPU is already detected
if (Get-Command "nvidia-smi" -ErrorAction SilentlyContinue) {
    Write-Host "NVIDIA driver already detected:"
    nvidia-smi --query-gpu=name,driver_version,utilization.gpu --format=csv
    return
}

$InstallerDir = "C:\Codevern\Drivers\NVIDIA"
New-Item -ItemType Directory -Force -Path $InstallerDir | Out-Null
$InstallerPath = "$InstallerDir\NVIDIA-GRID-Driver.exe"

Write-Host ">>> Downloading AWS Official NVIDIA GRID Driver for G4dn..."
try {
    # Check if AWS CLI is available to pull from AWS S3 bucket
    if (Get-Command "aws" -ErrorAction SilentlyContinue) {
        Write-Host "Using AWS CLI to pull driver from S3 bucket ec2-windows-nvidia-drivers..."
        aws s3 cp --recursive s3://ec2-windows-nvidia-drivers/g4/latest/ $InstallerDir/
        $InstallerPath = (Get-ChildItem -Path $InstallerDir -Filter "*.exe" | Select-Object -First 1).FullName
    } else {
        # Fallback to direct download link
        Write-Host "Downloading via web URL..."
        $DriverUrl = "https://ec2-windows-nvidia-drivers.s3.amazonaws.com/g4/latest/NVIDIA-GRID-Setup.exe"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $DriverUrl -OutFile $InstallerPath -UseBasicParsing
    }
} catch {
    Write-Warning "Could not automatically download driver from S3: $_"
}

if (Test-Path $InstallerPath) {
    Write-Host ">>> Installing NVIDIA GRID Driver silently..."
    Start-Process -FilePath $InstallerPath -ArgumentList "-s -clean -noreboot" -Wait
    Write-Host "NVIDIA Driver installation process finished."

    # Verify installation
    $env:Path += ";C:\Program Files\NVIDIA Corporation\NVSMI"
    if (Get-Command "nvidia-smi" -ErrorAction SilentlyContinue) {
        Write-Host "Verified NVIDIA Driver successfully installed:"
        nvidia-smi
    } else {
        Write-Warning "Driver installed, but a system reboot is recommended for full initialization."
    }
} else {
    Write-Warning "Driver installer binary not found at $InstallerPath. Manual driver installation may be required."
}

# Registry optimization for NVIDIA Cloud Gaming
Write-Host ">>> Configuring NVIDIA display driver registry optimizations..."
$RegPath = "HKLM:\SOFTWARE\NVIDIA Corporation\Global"
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
Set-ItemProperty -Path $RegPath -Name "GridLicensing" -Value 1 -Type DWord -ErrorAction SilentlyContinue
