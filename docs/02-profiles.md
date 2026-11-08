# 02 · Profiles — what's in a profile dir

Every Claude Desktop profile is a directory that Chromium (via
Electron) stores all of its per-browser-user state in. The launcher
only needs to know the path; everything inside is managed by Claude
Desktop itself.

## Standard contents

```
<profile>/
├── Cache/                                    discardable
├── Code Cache/                               discardable
├── Crashpad/                                 crash dumps
├── DawnGraphiteCache/                        discardable
├── GPUCache/                                 discardable
├── IndexedDB/
│   └── https_claude.ai_0.indexeddb.leveldb/  primary chat/account store
├── Local State                               Chromium global + os_crypt key
├── Local Storage/leveldb/                    LocalStorage per-origin
├── Network/
│   ├── Cookies                               SQLite: claude.ai session cookies
│   ├── Cookies-journal                       SQLite rollback journal
│   └── TransportSecurity                     HSTS cache
├── Partitions/                               isolated per-origin storage
├── Preferences                               Chromium per-profile prefs
├── Session Storage/                          per-tab storage
├── ant-device-registry.json                  Anthropic device record
├── ant-did                                   Anthropic device id
├── bridge-state.json                         IPC bridge sessions
├── buddy-tokens.json                         local token-usage counter (not auth)
├── ccd-ids.json                              per-install salt
└── config.json                               oauth:tokenCacheV2 lives here
```

## Which bytes matter for a signed-in session

Short answer: `Local State` + `Network/Cookies` + `config.json`.

- **`Local State`** — JSON that contains the AES-GCM key for Chromium
  Safe Storage. The key is DPAPI-wrapped (sealed to the Windows user's
  SID + password), so you cannot decrypt a `Local State` from a
  different Windows account.
- **`Network/Cookies`** — SQLite DB holding the `sessionKey`,
  `sessionKeyV3`, `__Host-ant_trusted_device`, and
  `anthropic-device-id` cookies. These are what the webview checks on
  startup to decide whether the user is signed in. Values are
  AES-GCM-encrypted with the Safe Storage key.
- **`config.json`** — contains `oauth:tokenCacheV2`, a Chromium Safe
  Storage blob of the OAuth access + refresh tokens. If both cookies
  and tokenCacheV2 are missing, the user sees the login screen.

Everything else (IndexedDB, LocalStorage, Preferences, caches) carries
state like chat history and UI preferences but does not gate sign-in.

## Launch modes

Both modes end up setting Chromium's `userData` path. Which path
depends on how you launched:

- **`--user-data-dir=<path>`**: Chromium honours the flag directly.
  Use this to point at an existing directory you want to reuse (e.g.
  the MSIX install's data folder).
- **`--profile=NAME`**: handled by the shim at
  `resources/app/.vite/build/index.pre.js`. Sets `userData` to
  `%LOCALAPPDATA%\Claude-Data-Profiles\<NAME>\`. Each profile gets its
  own `Local State` (so its own Safe Storage key), independent of
  every other profile.

The launcher stores one entry per profile with its launch mode and
path in `profiles.json`. Shape:

```json
[
  {
    "Id": "account-a",
    "Name": "Account A",
    "Email": "user-a@example.com",
    "Plan": "Max 20x",
    "Accent": "#ef4444",
    "Dir": "%LOCALAPPDATA%\\Claude-Data-Profiles\\account-a",
    "Mode": "profile"
  }
]
```

`Id` is the stable identifier; keep it short and URL-safe. `Dir` and
`Mode` together determine the CLI flag the launcher passes.

## Portability caveat

DPAPI binds to the Windows user's SID. Copying a profile dir between
Windows user accounts (or between machines) means the Safe Storage key
cannot be decrypted — the user sees the login screen on first launch.

The way to migrate a profile across machines is to sign in again on
the new machine. There is no portable key export.

## Where this matters for the launcher

The launcher never reads or writes any of the files above. It only:

1. Reads `profiles.json` (its own file) to know which path goes with
   which account.
2. Spawns `Claude.exe` with `--user-data-dir` or `--profile`.
3. Polls `Win32_Process` to count running `claude.exe` instances per
   path.

The optional "Who is signed in?" action reads `Local State` +
`config.json` from a profile dir (via the Python `whois.py` script),
unwraps the key with DPAPI, decrypts `oauth:tokenCacheV2`, and uses the
access token for one `GET https://api.anthropic.com/api/oauth/profile`
request. That request returns the email + name + UUID, which is shown
to the user and then discarded.
