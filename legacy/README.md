# Legacy PowerShell + WPF launcher

The original pre-Electron implementation. Feature-complete; kept
alongside the Electron app as a Node-less fallback.

## Why keep it

- Zero install cost. Windows PowerShell 5.1 ships with Windows and
  has WPF built in. `.NET Desktop Runtime` is already present.
- Useful on locked-down machines where `npm install` is not allowed.
- Smaller surface for security audits: a single 1000-line `.ps1`
  file + one `.cmd`.

## Run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File launcher.ps1
```

Or double-click [launcher.cmd](launcher.cmd).

Shares `profiles.json` + `prefs.json` with the Electron app at the
repo root. Edit accounts in either; the other picks up changes on
next refresh.

## Known differences from the Electron version

- `Ctrl+N` (not `Ctrl+Shift+A`) adds a new account. (The browser-based
  Electron version reserves `Ctrl+N` for new window.)
- No window-chrome customisation. Uses the default WPF title bar.
- No animated transitions. UI redraws in-place.
- "Who is signed in?" launches a MessageBox with the python
  `whois.py` output instead of a styled modal.

## Writing docs for both

Shared docs live under `docs/`. If a feature only applies to one
runtime, prefix the section header with `**[Electron only]**` or
`**[PowerShell only]**`.
