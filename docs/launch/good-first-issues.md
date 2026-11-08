# Good first issues (pre-filable backlog)

Eight ready-to-file GitHub issues for new contributors. Paste each into
**Issues → New** at launch (T-7 days, per `README.md` step 1). Apply
labels: `good first issue`, `help wanted`. Keep 2-5 open at all times
(close one → file a new one from this list).

---

## 1. Make auto-refresh interval configurable via Settings

**Labels:** `good first issue`, `enhancement`

**Summary.** Status refresh currently hard-codes 2 seconds
(`renderer.js` — the self-scheduling `refreshLoop`). On low-power
machines or when running on battery, this is more polling than
necessary. Expose it as a setting.

**Suggested approach.**

1. Add a `refreshIntervalMs` field to `prefs.json` (default `2000`).
2. Add a slider / dropdown (1s / 2s / 5s / 10s / "manual") in a new
   Settings modal — or inline in the help modal if a full Settings
   pane is too much.
3. Guard against `< 500` to avoid DoS'ing PowerShell.

**Files to touch.** `renderer.js`, `index.html`, `styles.css`.

**Acceptance.** Changing the value takes effect without restart.

---

## 2. Fetch a free SignPath Foundation code-signing certificate

**Labels:** `help wanted`, `distribution`

**Summary.** Unsigned Electron `.exe` trips Windows SmartScreen for
every first-time download. SignPath Foundation provides free
code-signing for OSS projects meeting their criteria.

**What's needed.**

1. Apply at https://signpath.io/foundation
2. Pass their criteria (MFA on all maintainer accounts, OSI license,
   public repo — all true today).
3. Wire the signing step into `.github/workflows/release.yml` per
   their docs.

**Ownership note.** Signing credentials have to live in GitHub
Secrets on the main repo — contributor would need to work with the
maintainer to set up.

---

## 3. Package for winget

**Labels:** `good first issue`, `distribution`

**Summary.** Submit a manifest to `microsoft/winget-pkgs` so users
can `winget install squashyweeb.ClaudeLauncher`.

**Suggested approach.**

1. After first release is cut, fork `microsoft/winget-pkgs`.
2. Create `manifests/s/squashyweeb/ClaudeLauncher/{version}.yaml`
   per their schema.
3. Open PR; their validation CI gives fast feedback.

**Acceptance.** Manifest merged upstream, `winget install
squashyweeb.ClaudeLauncher` works from a fresh Windows prompt.

---

## 4. Package for scoop (extras bucket)

**Labels:** `good first issue`, `distribution`

**Summary.** Mirror of #3 but for `scoop`. Open PR to
`ScoopInstaller/Extras`.

---

## 5. Add a `--help` / `--version` CLI mode for the Electron app

**Labels:** `good first issue`, `enhancement`

**Summary.** `ClaudeLauncher.exe --version` and `--help` should
print and exit without opening a window. Useful for scripts and
packagers (winget uses it to verify installs).

**Suggested approach.** In `main.js`, parse `process.argv` before
`app.whenReady()` and handle the two flags (print to stdout, call
`app.exit(0)`).

---

## 6. Document how to find your Claude Desktop install path

**Labels:** `good first issue`, `docs`

**Summary.** Users on uncommon Claude Desktop installs (portable
builds, non-default locations) need to point the launcher at their
`Claude.exe`. The UI has a picker, but the docs don't explain how to
find it.

**Deliverable.** Add a section to `README.md` or
`docs/01-architecture.md` listing the five standard install
locations on Windows, plus a one-liner PowerShell command users can
paste to find it.

---

## 7. Add dark/light theme toggle (follows system by default)

**Labels:** `good first issue`, `enhancement`, `a11y`

**Summary.** Palette is hardcoded to a single dark theme in
`styles.css`. Add a light palette + a toggle; default to
`nativeTheme.shouldUseDarkColors` from Electron's main.

**Suggested approach.**

1. Extract current colors into CSS variables under `:root[data-theme="dark"]`.
2. Mirror the palette under `:root[data-theme="light"]`.
3. On boot: `document.documentElement.setAttribute('data-theme',
   await window.api.theme())`.
4. Toggle button in help modal.

**Acceptance.** Toggles live, respects system default, persists
across restart.

---

## 8. Screen-reader labels on avatar keycap numbers

**Labels:** `good first issue`, `a11y`

**Summary.** The number overlay on each avatar (`1`, `2`, …) is a
visual shortcut hint. Screen readers announce it as a stray number.

**Suggested approach.**

1. Wrap the keycap in `<span aria-label="Keyboard shortcut: press
   {N} to launch">`.
2. Add `aria-hidden="true"` on the visual number so it isn't
   double-announced.
3. Make the card itself have `role="button" aria-label="Launch
   {profile name}, press {N}"`.

**Acceptance.** NVDA / Narrator reads a complete sentence per card,
no bare numbers.

---

## Notes for the maintainer

- Keep **2-5 open** at any time. Close one → file the next from this
  list.
- If a drive-by contributor asks "what should I pick?", suggest #3,
  #4, or #6 (zero architecture context needed).
- #1, #5, #7 touch renderer state and need a 30-second code tour.
- #2 is the most strategically valuable — unblocks SmartScreen for
  everyone.
- #8 is a credibility win and fast (10 lines of HTML / CSS).
