# PII sentinel scanner for PowerShell.
# Run from the repo root. Zero exit = clean.
param()
$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
$skipDirs = @('.git', 'node_modules', 'dist', 'out', 'build')
$skipFiles = @(
    'scripts/check-pii.js',
    'scripts/check-pii.ps1',
    'scripts/check-pii.sh',
    '.gitleaks.toml',
    'CONTRIBUTING.md',
    'SECURITY.md',
    'package-lock.json',
    'yarn.lock',
    'pnpm-lock.yaml'
) | ForEach-Object { Join-Path $repo $_ }
$patterns = @(
    @{ name = 'anthropic-access-token';  re = 'sk-ant-oat01-[A-Za-z0-9_-]{30,}' },
    @{ name = 'anthropic-refresh-token'; re = 'sk-ant-ort01-[A-Za-z0-9_-]{30,}' },
    @{ name = 'anthropic-api-key';       re = 'sk-ant-api03-[A-Za-z0-9_-]{30,}' },
    @{ name = 'generic-email';           re = '[a-z0-9._%+-]+@(?!example\.com|users\.noreply\.github\.com)[a-z0-9.-]+\.[a-z]{2,}' },
    @{ name = 'absolute-user-path';      re = '[A-Z]:\\Users\\(?!<)[A-Za-z][\w.-]{2,}' },
    @{ name = 'uuid-nonzero';            re = '(?!00000000-0000-0000-0000-)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' }
)
$textExt = @('.md','.js','.ps1','.cmd','.sh','.py','.json','.yaml','.yml','.toml','.html','.css','.txt')
$hits = 0
Write-Host "scanning $repo"
Get-ChildItem $repo -Recurse -File | Where-Object {
    $skipHit = $false
    foreach ($d in $skipDirs) { if ($_.FullName -match [regex]::Escape("\\$d\\")) { $skipHit = $true; break } }
    (-not $skipHit) -and ($skipFiles -notcontains $_.FullName) -and ($textExt -contains $_.Extension.ToLower())
} | ForEach-Object {
    $file = $_
    $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($p in $patterns) {
            if ($lines[$i] -match $p.re) {
                $script:hits++
                $rel = Resolve-Path $file.FullName -Relative
                Write-Host "[$($p.name)] ${rel}:$($i+1)  $($Matches[0].Substring(0, [Math]::Min(80, $Matches[0].Length)))"
            }
        }
    }
}
Write-Host ""
if ($hits -eq 0) { Write-Host "[OK] no sentinel hits"; exit 0 }
else             { Write-Host "[FAIL] $hits sentinel hit(s)"; exit 1 }
