# Claude Launcher

> A small Windows desktop app that lets you run multiple **Claude Desktop**
> accounts side-by-side, in separate windows, with per-account launch,
> close, and status.

![platform](https://img.shields.io/badge/platform-Windows-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![status](https://img.shields.io/badge/status-alpha-orange)

Not affiliated with Anthropic. See [NOTICE](NOTICE) for the full
trademark + scope statement.

---

## What it does

Claude Desktop stores each signed-in account inside a separate on-disk
profile directory. The Electron runtime it ships on top of already
supports `--profile=<name>` and `--user-data-dir=<path>` command-line
flags that pick which profile a given window uses.

This project packages that into a UI:

- One **card per account** with a per-account color, avatar, and
  keyboard shortcut
- **Launch** / **Close** buttons that spawn or kill Claude Desktop with
  the right flag
- Live **running status** (count of windows, RAM, uptime) via a cheap
  `Get-CimInstance Win32_Process` poll
- **Add / Edit / Duplicate / Move / Remove** accounts without leaving the
  app; nothing is hard-coded in source
- Optional **"Who is signed in?"** button that decrypts the profile dir's
  OAuth tokens with DPAPI and asks `api.anthropic.com/api/oauth/profile`
  to confirm which account that dir actually belongs to

---

## Requirements

- **Windows 10 or 11.** The app relies on Chromium / Electron CLI flags
  that are stable only on the Windows build of Claude Desktop.
- **Node.js 20+** to run the Electron app from source.
- A copy of **Claude Desktop** already installed. Supported layouts:
  - Microsoft Store MSIX install (`%LOCALAPPDATA%\Claude-Data\claude_<hash>\`)
  - Signed `.exe` installer (`%LOCALAPPDATA%\Programs\Claude\Claude.exe`)
  - Any portable Electron build (set `CLAUDE_EXE` env var or pick via UI)
- *(Optional)* Python 3.10+ with `pywin32` + `pycryptodome`, if you want
  the "Who is signed in?" feature.

---

## Install

```bash
git clone https://github.com/<owner>/claude-launcher
cd claude-launcher
npm install
npm start
```

A dark 720x760 window opens. The first run creates an empty
`profiles.json`; click **+ Add account** or press `Ctrl+Shift+A` to add
your first one.

### Build a standalone `.exe`

```bash
npm run pack
```

Writes `dist\ClaudeLauncher-win32-x64\ClaudeLauncher.exe`. The whole
folder (around 210 MB including the Electron runtime) is standalone and
can be zipped for distribution.

### PowerShell fallback

If you don't want to install Node, there's a feature-equivalent
`legacy/launcher.ps1` that uses Windows PowerShell 5.1 + WPF.
See [legacy/README.md](legacy/README.md).

---

## Configuration

| File | Purpose | Committed? |
|---|---|---|
| `profiles.json` | The list of accounts you've added | No (gitignored) |
| `prefs.json` | UI prefs (hint strip, launch counts) | No (gitignored) |
| `config.json` | Claude.exe path override | No (gitignored) |
| `profiles.example.json` | Starter template | Yes |
| `prefs.example.json` | Starter template | Yes |
| `config.example.json` | Starter template | Yes |

### Choosing which Claude.exe to launch

The launcher resolves `Claude.exe` in this order:

1. `exePath` from `config.json` (written by the UI when you pick a file)
2. `CLAUDE_EXE` environment variable
3. `%LOCALAPPDATA%\Programs\Claude\Claude.exe`
4. `%LOCALAPPDATA%\Claude\Claude.exe`
5. `C:\Program Files\Claude\Claude.exe`
6. `C:\Program Files (x86)\Claude\Claude.exe`

If none exist, the UI shows a red banner with a **Locate Claude.exe**
button that persists your pick to `config.json`.

### The two launch modes

- **New portable profile** (`--profile=<key>`) opens a fresh profile at
  `%LOCALAPPDATA%\Claude-Data-Profiles\<key>\`. You sign in there once.
  Requires the optional profile shim; see [docs/03-shim-internals.md](docs/03-shim-internals.md)
  and [shim/README.md](shim/README.md).
- **Attach existing folder** (`--user-data-dir=<path>`) points Claude
  at an existing profile dir you already use (for example, the MSIX
  install's data folder). Nothing is copied; no re-login.

---

## Keyboard shortcuts

| Keys | Action |
|---|---|
| `1`-`9` | Launch account N |
| `Shift`+`1`-`9` | Close account N |
| `Ctrl`+`1`-`9` | Open account N's folder |
| `Ctrl`+`Shift`+`A` | Add new account |
| `Ctrl`+`L` | Launch all |
| `Ctrl`+`W` | Close all |
| `F1` | Help |
| `Esc` | Dismiss open dialog |

---

## Documentation

Each file in [docs/](docs/) is self-contained and short:

| | |
|---|---|
| [docs/01-architecture.md](docs/01-architecture.md) | Where Claude Desktop stores data on Windows, how the launcher sits beside it |
| [docs/02-profiles.md](docs/02-profiles.md) | What's in a profile dir, which bytes matter for sign-in |
| [docs/03-shim-internals.md](docs/03-shim-internals.md) | How `--profile=NAME` works + how to install the optional shim |
| [docs/04-launch-recipes.md](docs/04-launch-recipes.md) | All CLI equivalents (launch, close, scheduled, scripted) |
| [docs/05-decrypt-tokens.md](docs/05-decrypt-tokens.md) | DPAPI + Chromium Safe Storage recipe that `whois.py` uses |
| [docs/07-recovery.md](docs/07-recovery.md) | What to do if a profile stops signing in |
| [docs/08-ui-features.md](docs/08-ui-features.md) | Full feature tour |
| [docs/09-roadmap.md](docs/09-roadmap.md) | What's intentionally not shipped yet |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Short version:

- Open an issue first for anything bigger than a bugfix
- Run `npm run check-pii` locally before every push
- Never paste real emails, real UUIDs, real tokens, or absolute paths
  from your machine in issues, PR descriptions, or commit messages

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) applies to all interactions.

## Security

See [SECURITY.md](SECURITY.md) for how to report a vulnerability.

**TL;DR of the security model:**

- The launcher executes `Claude.exe` with flags you supply. It never
  reads from, writes to, or exposes any token value in its own storage.
- Tokens stay inside the per-profile `Local State` + `Network/Cookies`
  files that Claude Desktop manages. They are DPAPI-sealed by Windows
  and tied to the current user's SID.
- The only network call the launcher ever makes is the optional
  `api.anthropic.com/api/oauth/profile` identity check, triggered by a
  user action. No telemetry, no analytics, no auto-updater.

## License

[MIT](LICENSE). See [NOTICE](NOTICE) for trademarks and third-party
attributions.
