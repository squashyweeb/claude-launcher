# 04 · Launch recipes — every way to start a Claude window

## The one-liners you'll actually use

```powershell
# Account B (user-b@example.com, Max 20x)
Start-Process '<CLAUDE_EXE>' -ArgumentList '--user-data-dir="%USERPROFILE%\AppData\Local\Claude-Data\claude_<MSIX_HASH>"'

# Account A (user-a@example.com, Max 5x)
Start-Process '<CLAUDE_EXE>'
# or explicit:
Start-Process '<CLAUDE_EXE>' -ArgumentList '--user-data-dir="%USERPROFILE%\AppData\Roaming\Claude"'
```

Both can run at once. Each gets its own window with no login prompt.

## .cmd shortcuts

Drop these into `<CLAUDE_INSTALL>\` next to the existing
`RunA.cmd` / `RunB.cmd` for Explorer-click convenience:

### `RunMatt.cmd`
```bat
@echo off
start "" "<CLAUDE_EXE>" --user-data-dir="%LOCALAPPDATA%\Claude-Data\claude_<MSIX_HASH>"
```

### `RunRyan.cmd`
```bat
@echo off
start "" "<CLAUDE_EXE>" --user-data-dir="%APPDATA%\Claude"
```

The launcher app wraps all of this in a GUI — see the project README.

## Everything else

### Launch both at once

```powershell
Start-Process '<CLAUDE_EXE>' -ArgumentList '--user-data-dir="%USERPROFILE%\AppData\Local\Claude-Data\claude_<MSIX_HASH>"'
Start-Process '<CLAUDE_EXE>'
```

### Make a new empty profile and sign in fresh

```powershell
Start-Process '<CLAUDE_EXE>' -ArgumentList '--profile=workacct'
```

This uses the shim (see [03-shim-internals.md](03-shim-internals.md))
and creates `%LOCALAPPDATA%\Claude-Data-Profiles\workacct\`. The window
opens on the sign-in screen; sign in once, state persists forever.
Add it to the launcher's `$PROFILES` with `Mode='profile'` once done.

### Close every Claude.exe for a specific profile

```powershell
$target = '%USERPROFILE%\AppData\Local\Claude-Data\claude_<MSIX_HASH>'
Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
  Where-Object { $_.CommandLine -like "*$target*" } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

### Close every Claude.exe period

```powershell
taskkill /F /IM claude.exe /T
```

Nuclear option; closes your current session too if you're reading this
in a Claude window.

### Which profile is each running Claude.exe on?

```powershell
Get-CimInstance Win32_Process -Filter "Name='claude.exe'" |
  Select-Object ProcessId,
    @{N='Profile';E={
      if ($_.CommandLine -match '--user-data-dir=(?:"([^"]+)"|(\S+))') {
        if ($Matches[1]) { $Matches[1] } else { $Matches[2] }
      } elseif ($_.CommandLine -match '--profile=(\S+)') {
        "profile:$($Matches[1])"
      } else {
        'default (%APPDATA%\Claude)'
      }
    }} |
  Format-Table -AutoSize
```

Group by `Profile` to see what's open:

```powershell
# ...pipe the above into Group-Object Profile | Select Count, Name
```

A single open window spawns 10–20 child processes (renderer, GPU,
utility, native host, …). Grouping gives you one entry per window.

### Confirm who's signed in to a profile without launching Claude

```powershell
python '%USERPROFILE%\tools\claude-launcher\scripts\whois.py' `
  '%USERPROFILE%\AppData\Local\Claude-Data\claude_<MSIX_HASH>'
```

See [05-decrypt-tokens.md](05-decrypt-tokens.md) for the whois script.

## Launching from a scheduled task

If you want Account B's window to come up at 9 AM:

```powershell
$action  = New-ScheduledTaskAction -Execute '<CLAUDE_EXE>' `
            -Argument '--user-data-dir="%LOCALAPPDATA%\Claude-Data\claude_<MSIX_HASH>"'
$trigger = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -TaskName 'Claude-Matt-morning' -Action $action -Trigger $trigger
```

Only runs while the Windows user is logged in — the profile dir is
inside their %LOCALAPPDATA%.
