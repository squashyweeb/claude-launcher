# shim/install.ps1
# Installs the Claude Launcher profile shim into a Claude Desktop
# installation. Non-destructive: renames the existing main entry and
# drops the shim beside it.
param(
    [string]$ClaudeExe,
    [switch]$Verify
)
$ErrorActionPreference = 'Stop'

function Find-ClaudeExe {
    param([string]$Hint)
    if ($Hint -and (Test-Path $Hint)) { return (Resolve-Path $Hint).Path }
    if ($env:CLAUDE_EXE -and (Test-Path $env:CLAUDE_EXE)) { return $env:CLAUDE_EXE }
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Claude\Claude.exe",
        "$env:LOCALAPPDATA\Claude\Claude.exe",
        "C:\Program Files\Claude\Claude.exe",
        "C:\Program Files (x86)\Claude\Claude.exe"
    )
    foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
    Add-Type -AssemblyName System.Windows.Forms
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = 'Locate Claude.exe (the one you want to add --profile support to)'
    $dlg.Filter = 'Claude.exe|Claude.exe'
    if ($dlg.ShowDialog() -ne 'OK') { throw 'cancelled' }
    return $dlg.FileName
}

$exe = Find-ClaudeExe -Hint $ClaudeExe
$exeDir = Split-Path $exe -Parent
$buildDir = Join-Path $exeDir 'resources\app\.vite\build'
if (-not (Test-Path $buildDir)) {
    throw "Not an Electron-style Claude Desktop install (no resources\app\.vite\build\): $exeDir"
}

$marker = Join-Path $buildDir '.claude-launcher-shim'
$mainJs = Join-Path $buildDir 'index.pre.js'
$origJs = Join-Path $buildDir 'orig-index.pre.js'
$shimSrc = Join-Path $PSScriptRoot 'profile-shim.js'

if ($Verify) {
    if (Test-Path $marker) {
        Write-Host "installed: yes" -ForegroundColor Green
        Write-Host "  marker: $marker"
        Write-Host "  shim:   $mainJs"
        Write-Host "  orig:   $origJs"
        exit 0
    } else {
        Write-Host "installed: no" -ForegroundColor Yellow
        exit 1
    }
}

if (Test-Path $marker) {
    Write-Host "shim already installed at $buildDir" -ForegroundColor Yellow
    Write-Host "to reinstall, run shim\uninstall.ps1 first"
    exit 0
}

if (-not (Test-Path $mainJs)) {
    throw "Expected index.pre.js at $mainJs — Claude Desktop may be a different version. Aborting."
}

Write-Host "[1/3] Renaming original index.pre.js -> orig-index.pre.js..."
Move-Item -LiteralPath $mainJs -Destination $origJs -Force

Write-Host "[2/3] Copying shim into place..."
Copy-Item -LiteralPath $shimSrc -Destination $mainJs -Force

Write-Host "[3/3] Writing marker..."
"shim installed by claude-launcher at $(Get-Date -Format o)" |
    Set-Content $marker -Encoding UTF8

Write-Host ""
Write-Host "Shim installed." -ForegroundColor Green
Write-Host "You can now launch:  $exe --profile=<name>"
Write-Host "To uninstall:        shim\uninstall.ps1"
