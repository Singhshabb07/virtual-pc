<#
.SYNOPSIS
    Configures audio subsystem and virtual audio loopback for Sunshine streaming.
.DESCRIPTION
    Enables Windows Audio Service, configures registry for background audio playback,
    and installs VB-Cable / virtual audio loopback driver for low-latency streaming to Moonlight clients.
#>

$ErrorActionPreference = "Continue"
Write-Host ">>> Configuring Windows Audio Subsystem for Cloud Streaming..."

# 1. Enable and start core Windows Audio Services
Set-Service -Name "Audiosrv" -StartupType Automatic
Set-Service -Name "AudioEndpointBuilder" -StartupType Automatic
Start-Service -Name "Audiosrv" -ErrorAction SilentlyContinue
Start-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue

# 2. Configure Windows Server Group Policy / Registry to allow audio in remote sessions
$AudioRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
if (Test-Path $AudioRegPath) {
    Set-ItemProperty -Path $AudioRegPath -Name "fDisableAudioCapture" -Value 0 -Type DWord -ErrorAction SilentlyContinue
}

# 3. Install VB-Audio Virtual Cable (for clean stereo / 5.1 surround sound capture)
$AudioDir = "C:\Codevern\Drivers\Audio"
New-Item -ItemType Directory -Force -Path $AudioDir | Out-Null
$CableZip = "$AudioDir\VBCABLE_Driver_Pack43.zip"

Write-Host ">>> Downloading VB-Cable Virtual Audio Driver..."
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $CableUrl = "https://download.vb-audio.com/Download_CAB/VBCABLE_Driver_Pack43.zip"
    Invoke-WebRequest -Uri $CableUrl -OutFile $CableZip -UseBasicParsing
    Expand-Archive -Path $CableZip -DestinationPath $AudioDir -Force
    
    $SetupExe = "$AudioDir\VBCABLE_Setup_x64.exe"
    if (Test-Path $SetupExe) {
        Write-Host "Installing VB-Cable Driver silently..."
        Start-Process -FilePath $SetupExe -ArgumentList "-i -h" -Wait
        Write-Host "VB-Cable Virtual Audio Driver installed successfully."
    }
} catch {
    Write-Warning "Could not install VB-Cable automatically: $_"
}

Write-Host "Windows Audio configuration completed."
