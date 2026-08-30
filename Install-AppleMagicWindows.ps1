#requires -Version 5.1
#requires -RunAsAdministrator

<#
.SYNOPSIS
Installs the bundled Apple Magic Keyboard and Magic Mouse 2 drivers on Windows.

.DESCRIPTION
This script is offline after the repository has been cloned. It validates the
fixed SHA-256 checksum and Apple publisher signature of every selected driver
before installation. It does not install PowerToys and does not apply global
keyboard remapping.
#>

[CmdletBinding()]
param(
    [switch]$VerifyOnly,
    [switch]$SkipKeyboardDriver,
    [switch]$SkipMouseDriver
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$DriverDirectory = Join-Path $PSScriptRoot 'drivers'
$Components = @(
    [pscustomobject]@{
        Name = 'Apple Magic Keyboard 2/3'
        FileName = 'magickeyboard2_AppleKeyboardInstaller64.exe'
        Sha256 = 'C7ACD788B0770316AD6A7C1C423ED730FE8B9F01E7E64702A94D7F3D3975CD96'
        DevicePattern = 'VID_05AC&PID_0267'
        Skip = [bool]$SkipKeyboardDriver
    },
    [pscustomobject]@{
        Name = 'Apple Magic Mouse 2'
        FileName = 'magicmouse2_AppleWirelessMouse64.exe'
        Sha256 = '70A56DEE6EFAC4032521A383EE85686FA71F2C2FDD637F05C87D74C48B6B6EBB'
        DevicePattern = 'VID_05AC&PID_0269'
        Skip = [bool]$SkipMouseDriver
    }
)

function Write-Status {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "[AppleMagicWindows] $Message"
}

function Assert-DriverFile {
    param([Parameter(Mandatory)][pscustomobject]$Component)

    $path = Join-Path $DriverDirectory $Component.FileName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing bundled driver: $path"
    }

    $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actualHash -ne $Component.Sha256) {
        throw "SHA-256 mismatch for $($Component.FileName). Expected $($Component.Sha256); received $actualHash"
    }

    $signature = Get-AuthenticodeSignature -LiteralPath $path
    if ($signature.Status -ne 'Valid' -or -not $signature.SignerCertificate -or $signature.SignerCertificate.Subject -notmatch 'Apple Inc\.') {
        $publisher = if ($signature.SignerCertificate) { $signature.SignerCertificate.Subject } else { 'none' }
        throw "Apple signature validation failed for $($Component.FileName). Status: $($signature.Status); publisher: $publisher"
    }

    Write-Status "Verified $($Component.Name): Apple signature valid; SHA-256 $actualHash"
    return $path
}

function Test-ConnectedDevice {
    param([Parameter(Mandatory)][pscustomobject]$Component)

    $device = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -match [regex]::Escape($Component.DevicePattern) } |
        Select-Object -First 1

    if ($device) {
        Write-Status "Detected $($Component.Name) ($($Component.DevicePattern))."
        return $true
    }

    Write-Warning "$($Component.Name) is not currently detected. Its driver can still be installed for later use."
    return $false
}

function Install-DriverPackage {
    param(
        [Parameter(Mandatory)][pscustomobject]$Component,
        [Parameter(Mandatory)][string]$Path
    )

    Write-Status "Installing $($Component.Name)."
    $process = Start-Process -FilePath $Path -Wait -PassThru
    if ($process.ExitCode -notin @(0, 1641, 3010)) {
        throw "$($Component.Name) installer failed with exit code $($process.ExitCode)."
    }

    if ($process.ExitCode -in @(1641, 3010)) {
        Write-Warning "$($Component.Name) requested a Windows restart."
    }
}

$selectedComponents = @($Components | Where-Object { -not $_.Skip })
if ($selectedComponents.Count -eq 0) {
    throw 'Both drivers were skipped; there is nothing to verify or install.'
}

foreach ($component in $selectedComponents) {
    Test-ConnectedDevice -Component $component | Out-Null
    $driverPath = Assert-DriverFile -Component $component
    if (-not $VerifyOnly) {
        Install-DriverPackage -Component $component -Path $driverPath
    }
}

if ($VerifyOnly) {
    Write-Status 'Verification completed. No installers were run and no settings were changed.'
    exit 0
}

& pnputil.exe /scan-devices | Out-Host
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Device rescan returned exit code $LASTEXITCODE. Replug the devices or restart Windows."
}

Write-Status 'Installation completed. Replug the devices or restart Windows if scrolling or function keys are not active yet.'
