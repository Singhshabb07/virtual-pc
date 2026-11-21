<#
.SYNOPSIS
    Codevern Cloud PC - Master In-Guest Bootstrap Script
.DESCRIPTION
    Executed automatically on instance launch via EC2 UserData.
    Prepares disk partitions, Windows Audio, NVIDIA drivers, Virtual Display,
    Sunshine streaming host, Developer environment, and the Idle Auto-Shutdown daemon.
#>

[CmdletBinding()]
param(
    [int]$IdleTimeoutMinutes = 15
)

$ErrorActionPreference = "Continue"
$LogPath = "C:\Codevern\bootstrap.log"
New-Item -ItemType Directory -Force -Path "C:\Codevern" | Out-Null

Start-Transcript -Path $LogPath -Append

Write-Host "=========================================================="
Write-Host "    Starting Codevern Cloud PC In-Guest Provisioning      "
Write-Host "=========================================================="

# 1. Initialize and Format Secondary Persistent Data Volume (Drive D: - 400 GB)
Write-Host "[1/7] Initializing Persistent Data Disk..."
try {
    $disks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' }
    foreach ($disk in $disks) {
        Write-Host "Initializing RAW Disk Number: $($disk.Number)"
        Initialize-Disk -Number $disk.Number -PartitionStyle GPT
        $part = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
        Format-Volume -Partition $part -FileSystem NTFS -NewFileSystemLabel "CloudPC_Data" -Confirm:$false
        Write-Host "Formatted and mounted Disk $($disk.Number) as Drive $($part.DriveLetter):"
    }
} catch {
    Write-Warning "Disk initialization note: $_"
}

# 2. Enable Windows Audio Services
Write-Host "[2/7] Enabling Windows Audio Service (Audiosrv)..."
Set-Service -Name "Audiosrv" -StartupType Automatic
Start-Service -Name "Audiosrv"
Set-Service -Name "AudioEndpointBuilder" -StartupType Automatic
Start-Service -Name "AudioEndpointBuilder"

# 3. Configure Windows Firewall for Sunshine Streaming
Write-Host "[3/7] Configuring Windows Firewall Rules..."
New-NetFirewallRule -DisplayName "Sunshine HTTPS WebUI" -Direction Inbound -LocalPort 47990 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Sunshine TCP Control" -Direction Inbound -LocalPort 47984,47989,48010 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Sunshine UDP Streaming" -Direction Inbound -LocalPort 47998-48002,48010 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue

# 4. Install Chocolatey Package Manager
Write-Host "[4/7] Installing Chocolatey..."
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:Path += ";$env:ALLUSERSPROFILE\chocolatey\bin"
}

# 5. Execute Modular Setup Scripts
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Execute NVIDIA Driver Setup
if (Test-Path "$ScriptDir\install-nvidia-grid.ps1") {
    Write-Host "[5.1/7] Running NVIDIA Driver Setup..."
    & "$ScriptDir\install-nvidia-grid.ps1"
}

# Execute Virtual Display Driver Setup
if (Test-Path "$ScriptDir\install-virtual-display.ps1") {
    Write-Host "[5.2/7] Running Virtual Display Driver Setup..."
    & "$ScriptDir\install-virtual-display.ps1"
}

# Execute Audio Driver Setup
if (Test-Path "$ScriptDir\configure-audio.ps1") {
    Write-Host "[5.3/7] Running Audio Device Configuration..."
    & "$ScriptDir\configure-audio.ps1"
}

# Execute Sunshine Streaming Host Setup
if (Test-Path "$ScriptDir\install-sunshine.ps1") {
    Write-Host "[5.4/7] Running Sunshine Streamer Setup..."
    & "$ScriptDir\install-sunshine.ps1"
}

# Execute Developer Suite Setup
if (Test-Path "$ScriptDir\install-devtools.ps1") {
    Write-Host "[6/7] Running Developer & Gaming Applications Setup..."
    & "$ScriptDir\install-devtools.ps1"
}

# Configure Idle Auto-Shutdown Service
Write-Host "[7/7] Registering Idle Auto-Shutdown Daemon ($IdleTimeoutMinutes min timeout)..."
if (Test-Path "$ScriptDir\idle-shutdown-daemon.ps1") {
    $daemonTarget = "C:\Codevern\idle-shutdown-daemon.ps1"
    Copy-Item -Path "$ScriptDir\idle-shutdown-daemon.ps1" -Destination $daemonTarget -Force

    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$daemonTarget`" -TimeoutMinutes $IdleTimeoutMinutes"
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

    Unregister-ScheduledTask -TaskName "CodevernIdleShutdown" -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName "CodevernIdleShutdown" -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    Start-ScheduledTask -TaskName "CodevernIdleShutdown"
    Write-Host "Idle Auto-Shutdown Task successfully registered and started."
}

Write-Host "=========================================================="
Write-Host "    Codevern Cloud PC Provisioning Complete!              "
Write-Host "=========================================================="

Stop-Transcript
