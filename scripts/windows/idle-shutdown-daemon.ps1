<#
.SYNOPSIS
    In-Guest Real-Time Inactivity & Cost Guardrail Daemon.
.DESCRIPTION
    Monitors user input activity (mouse & keyboard via Win32 GetLastInputInfo)
    and NVIDIA GPU utilization. If the workstation is inactive for longer than
    the configured threshold, cleanly shuts down the instance to halt EC2 compute billing.
#>

[CmdletBinding()]
param(
    [int]$TimeoutMinutes = 15,
    [int]$GpuThresholdPercent = 15,
    [string]$LogFile = "C:\Codevern\idle-shutdown.log"
)

# Win32 API to query last user input timestamp
$Win32TypeDef = @"
using System;
using System.Runtime.InteropServices;

public class Win32Input {
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleTimeMillis() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(lii);
        if (GetLastInputInfo(ref lii)) {
            return ((uint)Environment.TickCount - lii.dwTime);
        }
        return 0;
    }
}
"@

try {
    Add-Type -TypeDefinition $Win32TypeDef -ErrorAction SilentlyContinue
} catch {
    # Type may already be loaded in session
}

function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] $Message"
    Write-Output $logEntry
    Add-Content -Path $LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

Write-Log "Starting Codevern Inactivity Daemon (Timeout: $TimeoutMinutes min, Max GPU threshold: $GpuThresholdPercent%)."

$ConsecutiveIdleMinutes = 0

while ($true) {
    Start-Sleep -Seconds 60

    # 1. Query User Input Inactivity
    $idleMillis = [Win32Input]::GetIdleTimeMillis()
    $idleMinutes = [Math]::Floor($idleMillis / 60000)

    # 2. Query GPU Utilization
    $gpuUtil = 0
    if (Get-Command "nvidia-smi" -ErrorAction SilentlyContinue) {
        try {
            $smiOutput = (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits).Trim()
            $gpuUtil = [int]$smiOutput
        } catch {
            $gpuUtil = 0
        }
    }

    # 3. Decision Logic
    if ($idleMinutes -ge $TimeoutMinutes) {
        if ($gpuUtil -lt $GpuThresholdPercent) {
            Write-Log "SHUTDOWN TRIGGERED: User has been idle for $idleMinutes minutes (Limit: $TimeoutMinutes min) and GPU usage is $gpuUtil%."
            Write-Log "Shutting down system to stop AWS EC2 compute billing..."
            
            # Flush log
            Start-Sleep -Seconds 3
            
            # Cleanly stop Windows, which transitions EC2 to 'stopped' state
            Stop-Computer -Force
            break
        } else {
            Write-Log "User input idle for $idleMinutes min, but GPU workload active ($gpuUtil% >= $GpuThresholdPercent%). Postponing shutdown."
        }
    } else {
        # Active session
        if ($idleMinutes -eq 0 -and ($ConsecutiveIdleMinutes % 30 -eq 0)) {
            Write-Log "Session active (User active, GPU: $gpuUtil%)."
        }
    }

    $ConsecutiveIdleMinutes = $idleMinutes
}
