#requires -Version 5.1

<#
.SYNOPSIS
Installs or removes the optional Apple Magic Keyboard key mapping at user logon.

.DESCRIPTION
Creates one shortcut in the current user's Startup folder. The shortcut starts
the bundled AutoHotkey v2 mapping script, which swaps Command and Control for
the Apple keyboard layout. It does not change the registry or install drivers.
#>

[CmdletBinding()]
param(
    [switch]$Remove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$MappingScript = Join-Path $PSScriptRoot 'mapping\AppleMagicKeyboard.ahk'
$StartupShortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'Apple Magic Keyboard Mapping.lnk'

function Find-AutoHotkeyV2 {
    $commandPaths = @(
        'AutoHotkey64.exe',
        'AutoHotkey.exe'
    ) | ForEach-Object {
        $command = Get-Command $_ -ErrorAction SilentlyContinue
        if ($command) {
            $command.Path
        }
    }

    $candidates = @(
        $commandPaths,
        (Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }

    foreach ($candidate in $candidates) {
        $version = (Get-Item -LiteralPath $candidate).VersionInfo.ProductVersion
        if ($version -match '^2\.') {
            return $candidate
        }
    }

    throw 'AutoHotkey v2 was not found. Install it from https://www.autohotkey.com/ and run this script again.'
}

if ($Remove) {
    if (Test-Path -LiteralPath $StartupShortcut -PathType Leaf) {
        Remove-Item -LiteralPath $StartupShortcut
        Write-Host '[AppleMagicKeyboard] Removed the Startup shortcut.'
    }
    else {
        Write-Host '[AppleMagicKeyboard] No Startup shortcut was installed.'
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $MappingScript -PathType Leaf)) {
    throw "Mapping script was not found: $MappingScript"
}

$autoHotkey = Find-AutoHotkeyV2
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($StartupShortcut)
$shortcut.TargetPath = $autoHotkey
$shortcut.Arguments = '"' + $MappingScript + '"'
$shortcut.WorkingDirectory = Split-Path -Parent $MappingScript
$shortcut.IconLocation = $autoHotkey
$shortcut.Description = 'Apple Magic Keyboard Command and Control mapping'
$shortcut.Save()

Start-Process -FilePath $autoHotkey -ArgumentList ('"' + $MappingScript + '"')
Write-Host '[AppleMagicKeyboard] Mapping is active and will start when you sign in.'
