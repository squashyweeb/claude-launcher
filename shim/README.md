# Profile shim (optional)

The launcher's **"New portable profile"** mode (`--profile=NAME`) relies
on a small shim that intercepts the Electron main process of your
Claude Desktop installation and redirects `userData` /
`sessionData` to a per-profile directory under
`%LOCALAPPDATA%\Claude-Data-Profiles\<NAME>\`.

If you only ever use **"Attach existing folder"** mode (which just
passes `--user-data-dir=<path>` and does not need the shim), you can
skip this entirely.

## What it is, in one paragraph

An ~50-line original JavaScript file this project ships at
[`shim/profile-shim.js`](profile-shim.js). It reads a `--profile=NAME`
command-line flag (or `CLAUDE_PROFILE` env var), validates the name,
and calls `app.setPath('userData', ...)` + `app.setPath('sessionData',
...)` before Electron finishes initialising. It then `require()`s your
Claude Desktop installation's original main entry.

The shim contains no bytes from Anthropic's proprietary Claude Desktop.
It is MIT-licensed source authored by this project's contributors.

## How it gets installed

`shim/install.ps1` renames your Claude Desktop installation's main
entry file (`resources/app/.vite/build/index.pre.js`) to
`orig-index.pre.js` and drops the shim in its place. The shim ends
with `require('./orig-index.pre.js')`, so your Claude Desktop still
runs the real main — the shim just runs first.

This is a modification to YOUR local copy of a proprietary application.
You are responsible for making sure your use of Claude Desktop allows
this (see Anthropic's Terms of Service). Nothing is uploaded; the
patch is purely on your disk.

## Install

```powershell
# From the repo root
powershell -NoProfile -ExecutionPolicy Bypass -File shim\install.ps1
```

The script asks for your `Claude.exe` path (or auto-detects it) and
writes:

- `<install-dir>\resources\app\.vite\build\orig-index.pre.js`
  (renamed original)
- `<install-dir>\resources\app\.vite\build\index.pre.js`
  (the shim)
- `<install-dir>\resources\app\.vite\build\.claude-launcher-shim`
  (marker file so uninstall can be clean)

## Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File shim\uninstall.ps1
```

Removes the shim, restores the original, deletes the marker. Safe to
re-run.

## What happens if Claude Desktop updates

Updates typically overwrite `resources/app/.vite/build/index.pre.js`.
After an update, re-run `shim\install.ps1` and the shim comes back.

If you want to disable the shim without uninstalling it, pass no
`--profile=` flag — the shim is a no-op and hands straight through.

## Legal notes

- The shim is MIT-licensed and contains only original code by this
  project's contributors.
- Installing it modifies files inside your local Claude Desktop
  installation. Review Anthropic's Terms of Service for what's
  allowed on your copy.
- This project does NOT redistribute a modified Claude Desktop. If
  you repackage your post-install install directory, do not share
  that package publicly.

## Troubleshooting

- **"--profile=foo" doesn't redirect data.** Verify installation with:
  `powershell -NoProfile -ExecutionPolicy Bypass -File shim\install.ps1
  -Verify`. Expected output ends with `installed: yes`.
- **Chromium cookies invalidated.** The shim gives each profile a
  separate `Local State` (so a separate Chromium Safe Storage key per
  profile). This is by design — each profile signs in independently.
- **Magic-link login fails.** The shim pins a clean `userAgentFallback`
  because the default Electron UA depends on `app.getName()`, which
  the shim leaves unchanged. If a Claude Desktop update changes the
  UA format, update the string in `profile-shim.js`.
