# 09 · Roadmap — tier-2 features documented but not shipped

Features surfaced by the 15-agent brainstorm on 2026-11-01 that are
intentionally **not** implemented in v2. Picked up here so they are
easy to resurrect later.

## Background identity verification

Shell `scripts\whois.py` once per profile on launcher start via
`Start-Job`. Cache 24h in
`%LOCALAPPDATA%\Claude-Data-Profiles\.launcher-identity.json`.
Show a per-card pill: `Verified` / `PlanDrift` / `Mismatch` / `SignedOut`
/ `Expired`. On `Mismatch`, show an amber banner
"Signed in as X, not Account B  [Fix card]  [Ignore]".

Why defer: N parallel python + DPAPI + HTTPS calls need concurrency
throttling and rate-limit awareness, which adds complexity v2 can skip.

## System tray + global hotkey

Dependency-free WinForms `NotifyIcon`:

- GDI `Bitmap` + `Icon.FromHandle` for the tray icon
- Dark context menu rebuilt every 2s from `$script:PROFILES`
- "Close to tray" / "Minimize to tray"
- `Win+Shift+C` global hotkey via `user32.RegisterHotKey` through an
  `HwndSource` hook

Why defer: requires switching from `ShowDialog` to `Show + Dispatcher.Run`
and careful HICON teardown to avoid handle leaks.

## Window arrangement

"Tile side-by-side" button that uses `Win32 EnumWindows` + `SetWindowPos`
to split the primary monitor 50/50 between all live Claude windows.
"Center all". Account-specific preferred monitor via
`window-prefs.json` storing each profile's lastPosition keyed by
`\\.\DISPLAY1`, etc.

Why defer: 240 LOC of P/Invoke. Worth adding only after multi-monitor
use becomes a daily pain point.

## Settings pane

Slide-in right-side panel triggered by a cogwheel in the header
(`Ctrl+,`). Persist to `settings.json`:

- Auto-refresh interval (0-10s)
- Startup behavior (none / launch all / start minimized)
- Default launch mode (profile vs user-data-dir)
- Light/dark theme toggle
- Verify identity on startup
- Claude.exe path

Why defer: overlaps heavily with the theme-polish toggle and the
prefs.json added for help-discoverability. Sequence after those stabilize.

## Launcher autostart (per-account)

Lightning-bolt icon per card that creates/removes
`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\ClaudeLauncher-<Id>.lnk`
pointing at `Claude.exe` with that profile's `--profile` or
`--user-data-dir` args. Right-click flyout switches to a
`Register-ScheduledTask` with 30s delay. State probed every 2s refresh.

Why defer: niche enough to ship after the account CRUD + context menu
lands.

## Launch presets

Per-account JSON (`presets.json`):

- startup URL (e.g. `claude.ai/new` vs a specific chat)
- extra CLI args
- environment variables (passed via
  `ProcessStartInfo.EnvironmentVariables`)

A ~12-line extension to the shim at
`<CLAUDE_INSTALL>\resources\app\.vite\build\index.pre.js` would honor
`--launch-url` by routing `BrowserWindow.loadURL` after `whenReady`.

Why defer: needs a shim edit and a URL-regex guard against phishing
redirects.

## Error UX

- Red banner above `ProfileList` when `Claude.exe` is missing
  (links to `docs/07-recovery.md`)
- Amber banner when the shim is missing
- Per-card "folder missing" badge via `Test-Path`
- Bottom-right toast for one-off failures with a "View fix" link
- All routed through the health probe that re-runs on the existing 2s tick

Why defer: current errors are rare and surface as PowerShell exceptions
in the hidden host — acceptable while the app is used by one person.

## Right-click power menu (opt-in)

Behind an "enable power menu" flag:

- **Backup** — `Compress-Archive` the profile dir to a timestamped zip
  (excluding `Cache\` to avoid the LevelDB WAL destruction that killed
  the old swapper)
- **Charles proxy** — `--proxy-server=http://127.0.0.1:8888`
- **DevTools port** — `--remote-debugging-port=922N`
- **Token copy** — 60s auto-clearing clipboard copy of the decrypted
  access token

Why defer: security-sensitive. A bearer credential on the clipboard
needs a visible timer and a one-click revoke. Ship after an audit.

## Design overhaul (partial — carried forward)

The agents proposed:

- 13 DynamicResource `Theme.*` brushes (shipped)
- 5-step typography scale (not yet — current code uses ad-hoc sizes)
- 10 stroked SVG `PathGeometry` icons (not yet — emoji + text used instead)
- Card hover `Storyboard` lifting the card -2px (not yet)
- Spinner on button click, replacing `Start-Sleep` UI freezes (not yet)
- Animated status dot pulse 1.0 -> 1.8 on going-live (not yet)
- Sun/moon theme toggle in the header (not yet)

What's shipped from this list: the resource dictionary + accent-based
border on running cards + "+ New window" button content swap. The rest
is good future work but not blocking.
