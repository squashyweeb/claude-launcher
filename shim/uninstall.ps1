# shim/uninstall.ps1
# Removes the Claude Launcher profile shim and restores the original.
param([string]$ClaudeExe)
$ErrorActionPreference = 'Stop'

function Find-ClaudeExe {
    param([string]$Hint)
    if ($Hint -and (Test-Path $Hint)) { return (Resolve-Path $Hint).Path }
    if ($env:CLAUDE_EXE -and (Test-Path $env:CLAUDE_EXE)) { return $env:CLAUDE_EXE }
    foreach ($p in @(
        "$env:LOCALAPPDATA\Programs\Claude\Claude.exe",
        "$env:LOCALAPPDATA\Claude\Claude.exe",
        "C:\Program Files\Claude\Claude.exe"
    )) { if (Test-Path $p) { return $p } }
    throw 'Could not locate Claude.exe. Pass -ClaudeExe <path>.'
}

$exe = Find-ClaudeExe -Hint $ClaudeExe
$exeDir = Split-Path $exe -Parent
$buildDir = Join-Path $exeDir 'resources\app\.vite\build'
$marker = Join-Path $buildDir '.claude-launcher-shim'
$mainJs = Join-Path $buildDir 'index.pre.js'
$origJs = Join-Path $buildDir 'orig-index.pre.js'

if (-not (Test-Path $marker)) {
    Write-Host "No shim installed at $buildDir" -ForegroundColor Yellow
    exit 0
}
if (-not (Test-Path $origJs)) {
    throw "orig-index.pre.js is missing — cannot restore safely. Reinstall Claude Desktop."
}
Write-Host "Restoring original index.pre.js..."
Remove-Item -LiteralPath $mainJs -Force
Move-Item   -LiteralPath $origJs -Destination $mainJs -Force
Remove-Item -LiteralPath $marker -Force
Write-Host "Shim uninstalled." -ForegroundColor Green
