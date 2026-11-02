# 01 · Architecture — where every Claude thing lives on this machine

As of 2026-11-01. This machine has **three distinct Claude Desktop
installs** and **five distinct profile directories**, each in a
different state. Keep this map handy before touching anything.

## 1. The exe your Claude actually runs from

```
<CLAUDE_EXE>       (246 MB, Oct 24 15:07)
```

This is the **portable Claude**. Every running `claude.exe` process on
this machine right now (verified via `Get-Process claude | Select Path`)
is a child of this one binary. It is a repackaged Electron bundle with
a custom profile shim injected at
`<CLAUDE_INSTALL>\resources\app\.vite\build\index.pre.js`
(see [03-shim-internals.md](03-shim-internals.md)).

Also present but **unused** by the running process:

- The MSIX install from the Microsoft Store at
  `C:\Program Files\WindowsApps\AnthropicPBC.ClaudeDesktop_*\Claude.exe`.
  Nothing on this machine launches it in day-to-day use. Its *data dir*
  (see §2) is still populated and we read it, but the exe itself is
  dormant.

## 2. The five profile directories

| # | Path | Who lives there | State | Used by |
|---|---|---|---|---|
| 1 | `%APPDATA%\Claude\` | Account A (user-a@example.com) | Live, actively written | portable Claude when launched **without** `--profile=` or `--user-data-dir` |
| 2 | `%LOCALAPPDATA%\Claude-Data\claude_<MSIX_HASH>\` | Account B (user-b@example.com) | Dormant but complete auth | MSIX install (not currently running); we aim portable Claude at it with `--user-data-dir=` |
| 3 | `%LOCALAPPDATA%\Claude-Data\claude-alt-profile\` | — (empty) | Shells of folders, no `config.json` | Legacy, delete-safe |
| 4 | `%LOCALAPPDATA%\Claude-Data\.swapper-slots\main\` | Nobody (shim data) | **Corrupted** — see [06-swapper-postmortem.md](06-swapper-postmortem.md) | The old `claude-swapper.ps1`, broken |
| 5 | `%LOCALAPPDATA%\Claude-Data\.swapper-slots\second\` | — (empty) | Wiped by a failed `-Switch main` on 2026-11-01 | — |
| 6 | `%LOCALAPPDATA%\Claude-Data-Profiles\main\` | Fresh, logged out | Created by shim when we ran `--profile=main` while diagnosing | Experimental, delete-safe |

Only **#1 and #2** matter. Everything else is debris.

Pattern-wise:

- `%APPDATA%\Claude\` is Electron's default `userData` on Windows for an
  app whose `app.getName()` is `"Claude"`.
- `%LOCALAPPDATA%\Claude-Data\<MSIX-hash>\` is the Windows Store (MSIX)
  install's redirected per-package data dir. The `claude_<MSIX_HASH>`
  segment is `"claude_"` + Microsoft's publisher-ID hash (stable across
  app versions, per the swapper's comment).
- `%LOCALAPPDATA%\Claude-Data-Profiles\<name>\` is what the portable
  shim creates when launched with `--profile=<name>`.
- `%LOCALAPPDATA%\Claude-Data\.swapper-slots\<name>\` is the
  swapper's own stash directory (legacy; see postmortem).

## 3. What lives inside one profile dir

Standard Chromium-flavoured Electron layout plus Anthropic-specific
files:

```
<profile>/
├── Cache/, Code Cache/, GPUCache/, …           # discardable
├── Crashpad/                                   # crash dumps
├── DIPS, DIPS-wal                              # SQLite: tracking protection
├── IndexedDB/
│   └── https_claude.ai_0.indexeddb.leveldb/    # the primary chat/account store
├── Local State                                 # Chromium global prefs + os_crypt.encrypted_key
├── Local Storage/leveldb/                      # LocalStorage key/value
├── Network/
│   ├── Cookies                                 # SQLite: anthropic.com session cookies
│   └── Cookies-journal                         # SQLite rollback journal (REQUIRED)
├── Partitions/                                 # per-origin isolated storage
├── Preferences                                 # Chromium per-profile prefs
├── Session Storage/                            # per-tab storage
├── ant-device-registry.json                    # Anthropic device record
├── ant-did                                     # Anthropic device id
├── bridge-state.json                           # IPC bridge sessions
├── buddy-tokens.json                           # token-usage counter (NOT auth)
├── ccd-ids.json                                # per-install salt
└── config.json                                 # ← oauth:tokenCache / tokenCacheV2 live here
```

`config.json` is the one that holds the actual OAuth refresh tokens,
AES-GCM encrypted with the key from `Local State`. See
[05-decrypt-tokens.md](05-decrypt-tokens.md) for how to decrypt.

## 4. Cross-cutting state (outside profile dirs)

- **DPAPI master key** (per Windows user, not per profile): used to
  unwrap `Local State` `os_crypt.encrypted_key`. Bound to the Windows
  user's SID + password; cannot be moved to another user account.
- **`<CLAUDE_INSTALL>\resources\app\.vite\build\index.pre.js`** — the
  profile shim. Edited to intercept `--profile=NAME` and redirect
  `userData` + `sessionData`. If you ever update ClaudePortable, this
  file may need to be re-patched (see [03-shim-internals.md](03-shim-internals.md)).

## 5. What claude-swapper.ps1 touches

For historical reference only:

- Reads/writes `%LOCALAPPDATA%\Claude-Data\.swapper-slots\meta.json`
- robocopies between `%LOCALAPPDATA%\Claude-Data\claude_<MSIX_HASH>\`
  and `.swapper-slots\<name>\`
- Launches `Claude.exe` resolved from `PATH` or hard-coded location
  (**does not know about the portable at D:\\**)

Because the running Claude is the portable (not the MSIX), nothing the
swapper does affects what the user sees. The swapper is effectively a
no-op. Keep it uninstalled or ignore it.
