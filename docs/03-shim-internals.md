# 03 · Shim internals — how `--profile=NAME` works

The portable Claude at `<CLAUDE_INSTALL>\` has a **profile shim**
injected into its Electron main process. This is what makes
`--profile=NAME` work.

## The file

```
<CLAUDE_INSTALL>\resources\app\.vite\build\index.pre.js
```

(1941 bytes, Oct 24 15:35)

The Electron main entry originally lived at `index.pre.js`. Someone
renamed it to `orig-index.pre.js` and replaced `index.pre.js` with the
shim below, which does its work and then `require()`s the original.

## What it does, in order

```js
// 1. Read the profile name
const profile =
  process.argv.find(a => a.startsWith('--profile=')).slice(10).trim()
  ?? process.env.CLAUDE_PROFILE
  ?? null;

// 2. Validate (safe chars only, 1–40 long)
if (!/^[A-Za-z0-9_\-]{1,40}$/.test(profile)) return;

// 3. Redirect Electron's userData path
const base = path.join(
  process.env.LOCALAPPDATA,
  'Claude-Data-Profiles',
  profile
);
app.setPath('userData',    base);
app.setPath('sessionData', base);

// 4. Give each profile its own AppUserModelId so the taskbar groups
//    them separately
app.setAppUserModelId('com.anthropic.claude.' + profile);

// 5. Pin a known-good user-agent so Anthropic's WAF accepts
//    /api/auth/send_magic_link requests. The default Electron UA
//    (which pulls from app.getName()) breaks magic-link auth.
app.userAgentFallback =
  'Mozilla/5.0 (…) Claude/<v> Chrome/136.0.7103.149 Electron/36.3.1 …';

// 6. Hand off to the real main
require('./orig-index.pre.js');
```

## Why this matters

- **Independent sign-in per profile.** `userData` is where Chromium's
  `Network/Cookies`, `Local State` (with its `os_crypt.encrypted_key`),
  `Local Storage`, `IndexedDB` and `config.json` live. By redirecting
  it, each profile has its own cookies, its own AES key, its own auth
  tokens. No DPAPI surgery, no file copying.

- **No singleton collisions.** Electron's single-instance lock is
  scoped to `userData`. Different `userData` dirs ⇒ different locks
  ⇒ side-by-side windows just work.

- **Taskbar grouping.** `setAppUserModelId` with the profile suffix
  means Account B's window and Account A's window get separate taskbar icons
  rather than clustering.

- **User-agent must stay plain.** The shim's author left a comment:
  if you also change `app.setName(...)` or add anything with spaces /
  parens, the default Electron UA ends up RFC-7230-invalid and
  Anthropic's WAF rejects magic-link requests. The shim therefore
  leaves `app.getName()` alone and pins `userAgentFallback` directly.

## Where that puts data on disk

```
%LOCALAPPDATA%\Claude-Data-Profiles\<name>\
```

Same layout as any other Claude profile dir (see
[01-architecture.md](01-architecture.md) § 3).

## `--profile=` vs `--user-data-dir=`

Both end up setting `userData`, but through different code paths:

| | `--profile=NAME` | `--user-data-dir=<path>` |
|---|---|---|
| Who handles it | The shim | Chromium itself |
| Where data goes | `%LOCALAPPDATA%\Claude-Data-Profiles\<name>\` | wherever you say |
| User-agent fix | yes | no (irrelevant unless magic-link login) |
| AppUserModelId | per-profile | shared default |
| Fresh os_crypt key per profile | yes (new Local State) | no (reuses what's at the path) |
| Good for | a *new* account you own | pointing at an *existing* profile dir (MSIX install, old setup, backup) |

In this project we use `--user-data-dir=` for Account B (he already has
auth in the MSIX dir) and the portable default (no flag) for Account A.
Both are safe to run at the same time.

## If ClaudePortable updates

Updating the portable build will overwrite `resources/app/.vite/build/`
including `index.pre.js`. After an update:

1. Check whether `--profile=foo` still redirects by running
   `<CLAUDE_EXE> --profile=debug` and watching
   whether `%LOCALAPPDATA%\Claude-Data-Profiles\debug\` gets created.
2. If not: the shim is gone. Re-apply by renaming the new
   `index.pre.js` to `orig-index.pre.js` and dropping the shim back as
   `index.pre.js`. The 1941-byte reference text is in this doc.

Keep a copy of `index.pre.js` next to this file if you worry about it:

```bash
copy <CLAUDE_INSTALL>\resources\app\.vite\build\index.pre.js ^
     %USERPROFILE%\tools\claude-launcher\shim-backup.pre.js
```
