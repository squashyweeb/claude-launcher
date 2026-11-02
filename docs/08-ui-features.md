# 08 · UI feature tour

Everything the launcher v2 does, and where in the code it lives.

## The main window

Dimensions: 680x720 (resizable, min 560x500). Dark theme throughout.

Layout, top to bottom:

1. **Header** — "Claude Accounts" + subtitle + live "N of M live" summary + "?" help button
2. **Hint strip** — amber tip rotating every 10s; dismissable
3. **Profile list** — one card per account + a dashed "Add account" tile at the end
4. **Footer** — total-windows status + "Close all" + "Launch all"

## Profile cards

Each card has:

| Element | Behaviour |
|---|---|
| Avatar | Gradient circle (SHA256 of email+id) with first/last initials. Keycap number in bottom-right. |
| Name + plan pill | Plan pill colored to match the account's accent. |
| Email | Sub-headline. |
| Status row | Gray dot "Not running" or green dot "Running N process(es)". |
| Telemetry | When running: `420 MB  \|  up 1.2h`. |
| Folder button | Opens the profile dir in Explorer. |
| Close button | Only visible when running; closes all claude.exe for this dir. |
| Launch button | Accent-colored primary action. "Launch" or "+ New window". |
| Right-click | Context menu: Edit / Duplicate / Move up / Move down / Who is signed in? / Remove. |

Running cards get an accent-colored border (2px, matches the Launch button).

## Add account dialog (Ctrl+N or click the dashed tile)

Fields:

- **Display name** — required
- **Email** — optional, used to seed the avatar gradient
- **Plan badge** — free-text; shown as a colored pill (e.g. "Max 20x")
- **Launch mode** — radio: `New portable profile` vs `Attach existing folder`
  - **profile** sub-panel: Profile key (becomes `%LOCALAPPDATA%\Claude-Data-Profiles\<key>\`)
  - **folder** sub-panel: Folder path with Browse… + "Detect identity from this folder" button that runs whois.py and auto-fills Name/Email/Plan
- **Accent color** — 18-swatch picker

Live avatar preview updates as you type.

Validation:

- Name required
- Profile key must match `^[A-Za-z0-9_\-]{1,40}$`
- Folder required if mode = attach

Save appends the account to `profiles.json` and rebuilds the card list.

## Edit dialog

Same XAML as Add dialog (reused). Right-click a card → Edit... (or `Ctrl+E`
when the card has focus — Tab to focus).

Changing the launch mode or key for an existing account mutates its
`Dir`. Changing anything that doesn't affect disk (name, email, plan,
accent) is safe without restarting Claude.

## Who is signed in?

Right-click → "Who is signed in?" runs `scripts\whois.py` on the profile
dir and shows the live `email / name / UUID / plan / org` from
`https://api.anthropic.com/api/oauth/profile`.

Useful when:
- You suspect the hard-coded Email field is wrong
- A profile's auth has drifted (someone signed out and signed in as someone else)
- You migrated a dir from one install to another and want to verify what came along

## Running telemetry

`Get-RunningMap` is called every 2 seconds and returns `{Count, Mem, Oldest}`
per profile. Count comes from matching `--user-data-dir=` or `--profile=`
in the command line of every `claude.exe` process. Mem is the sum of
`WorkingSetSize`. Oldest is the earliest `CreationDate`.

Shown as `420 MB  |  up 1.2h` under the status row.

Also: `buddy-tokens.json` in each profile dir has a `tokens-today`
counter maintained by Claude Desktop itself (not the launcher). If a
future feature wants to surface this, call `Get-ProfileTokens $dir`.

## Hint strip

Amber-tinted strip above the profile list. Rotates every 10s through
seven tips. Dismissable (`x` button) — stored in `prefs.json` as
`hintsEnabled: false`; delete that file to bring it back.

## Help (F1 or ?)

Opens a MessageBox with all keyboard shortcuts and basic UI legend.
Not a modal dialog — just a one-screen reference.

## Context menu actions in detail

| Item | Behaviour |
|---|---|
| Edit... | Opens the dialog pre-filled with this profile |
| Duplicate | Clones the profile, adds "-copy-NNN" to the Id and " (copy)" to the Name, inserts after the original, opens Edit |
| Move up / Move down | Shifts the card in the list (and persists); affects keycap numbering (1-9) |
| Who is signed in? | Runs whois.py on the profile dir |
| Remove | Confirms via MessageBox, then removes from `profiles.json`. Does NOT delete the folder on disk. |

## Persistence

- **profiles.json** — array of profile hashtables, written on every mutation.
- **prefs.json** — `{hintsEnabled, hintIndex}`, written when hints are dismissed and when rotating.

Both live next to `launcher.ps1`. Safe to version-control (no secrets).

## Not in v2 — see [09-roadmap.md](09-roadmap.md)

- Light-theme toggle, animated transitions, loading spinners
- System tray + global hotkey
- Window arrangement helpers (tile/center/cascade across monitors)
- Full Settings pane
- Per-card autostart (Startup folder .lnk or Scheduled Task)
- Launch presets (startup URL, extra args, env vars)
- Background identity-verification with mismatch warnings
- Right-click power menu (Backup profile, Charles proxy, DevTools port, token copy)
