<#
.SYNOPSIS
    Installs and configures Virtual Display Driver (IddSampleDriver) for headless EC2.
.DESCRIPTION
    Headless cloud instances do not have a physical monitor attached.
    This script provisions an Indirect Display Driver supporting 1080p, 1440p, and 4K at 60/120Hz,
    enabling NVIDIA NVENC hardware acceleration and full resolution scaling in Sunshine/Moonlight.
#>

$ErrorActionPreference = "Continue"
Write-Host ">>> Configuring Virtual Display Driver for Headless Cloud PC..."

$VDDDir = "C:\Codevern\Drivers\VirtualDisplay"
New-Item -ItemType Directory -Force -Path $VDDDir | Out-Null

$VddZip = "$VDDDir\Virtual-Display-Driver.zip"
$VddReleaseUrl = "https://github.com/itsmikethetech/Virtual-Display-Driver/releases/latest/download/Virtual-Display-Driver.zip"

Write-Host ">>> Downloading Virtual Display Driver release..."
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $VddReleaseUrl -OutFile $VddZip -UseBasicParsing
    Expand-Archive -Path $VddZip -DestinationPath $VDDDir -Force
    Write-Host "Extracted Virtual Display Driver."
} catch {
    Write-Warning "Failed downloading latest release directly: $_"
}

# Generate resolution configuration file (options.txt)
$OptionFile = "$VDDDir\options.txt"
@"
1
1920, 1080, 60
1920, 1080, 120
2560, 1440, 60
2560, 1440, 120
3840, 2160, 60
"@ | Out-File -FilePath $OptionFile -Encoding ascii -Force

# Install Certificate and Driver via pnputil / certutil if inf is present
$InfFile = Get-ChildItem -Path $VDDDir -Filter "*.inf" -Recurse | Select-Object -First 1
$CerFile = Get-ChildItem -Path $VDDDir -Filter "*.cer" -Recurse | Select-Object -First 1

if ($CerFile) {
    Write-Host "Installing Driver Root Certificate ($($CerFile.FullName))..."
    certutil -addstore "TrustedPublisher" $CerFile.FullName
    certutil -addstore "Root" $CerFile.FullName
}

if ($InfFile) {
    Write-Host "Registering Virtual Display Driver via pnputil ($($InfFile.FullName))..."
    pnputil /add-driver $InfFile.FullName /install
    Write-Host "Virtual Display Driver installed successfully."
} else {
    Write-Warning "INF file not found in $VDDDir. Ensure driver bundle is unpacked."
}

# Set Windows Display registry settings to prefer hardware GPU rendering
$GraphicsPerfPath = "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"
if (-not (Test-Path $GraphicsPerfPath)) {
    New-Item -Path $GraphicsPerfPath -Force | Out-Null
}
