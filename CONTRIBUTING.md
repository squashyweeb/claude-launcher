# Contributing to Claude Launcher

Thanks for considering a contribution. This project is small by design
and aims to stay that way, so most changes benefit from an issue first.

## Table of contents

- [Ground rules](#ground-rules)
- [Dev setup](#dev-setup)
- [What to work on](#what-to-work-on)
- [Making a change](#making-a-change)
- [Testing](#testing)
- [Avoiding leaks](#avoiding-leaks)
- [Commit style](#commit-style)
- [Pull requests](#pull-requests)

---

## Ground rules

1. **Treat the launcher as a utility, not a product.** It's a thin UI
   around Claude Desktop's existing CLI flags. It should not grow a
   plugin system, auto-updater, or anything that phones home.
2. **Be kind.** See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
3. **Protect your own accounts and other contributors' accounts.** See
   [Avoiding leaks](#avoiding-leaks) below.

## Dev setup

```bash
git clone https://github.com/<owner>/claude-launcher
cd claude-launcher
npm install
npm start
```

The Electron app runs from source directly, no transpile step.

For the optional "Who is signed in?" feature:

```bash
python -m pip install -r scripts/requirements.txt
```

For the PowerShell fallback:

```bash
# No install needed; Windows PowerShell 5.1 ships with Windows.
pwsh -NoProfile -ExecutionPolicy Bypass -File legacy\launcher.ps1
```

## What to work on

- Look at issues tagged `good first issue` and `help wanted`.
- Items in [docs/09-roadmap.md](docs/09-roadmap.md) are documented and
  deliberately not shipped — any of them is a reasonable PR topic.
- Bug reports with repro steps are especially welcome. (Please redact
  your real email and UUIDs from screenshots and logs.)

## Making a change

1. Fork the repo, create a branch (`feat/<slug>` or `fix/<slug>`).
2. Keep changes small and focused. A single PR should land one feature
   or one bug, not a bundle.
3. Avoid introducing new runtime dependencies if a few lines of code
   would do. This project values a short npm tree.
4. UI changes should keep the dark theme and the keyboard-first
   interaction model.

## Testing

- **Manual smoke test** before every PR:
  1. Delete `profiles.json`, `prefs.json`, `config.json` from your
     working copy (or move them aside).
  2. `npm start` should bring up an empty window with the "+ Add
     account" tile and no errors in DevTools (Ctrl+Shift+I).
  3. Add a throwaway test account pointing at a scratch directory;
     launch, close, right-click Edit, Remove.
- **PowerShell fallback**: run `legacy\launcher.ps1` once with your
  change and confirm it still opens.
- **CI runs `check-pii` and lints on every push.**

## Avoiding leaks

The launcher sits next to sensitive data (OAuth tokens, cookies). This
project asks every contributor to help keep that data out of the
public repo.

**Before every push:**

```bash
npm run check-pii
```

**Never commit:**

- Real email addresses (yours or anyone else's)
- Real Anthropic account UUIDs or organization UUIDs
- Any OAuth access/refresh token (`sk-ant-oat01-...` / `sk-ant-ort01-...`)
- The MSIX publisher hash directory from your machine
  (`claude_<hex>\`)
- Absolute paths that reveal your Windows username
  (`C:\Users\<you>\...`)
- `profiles.json`, `prefs.json`, `config.json` (gitignored, but
  double-check)
- Any screenshot that shows the above in a status bar, dev-tools pane,
  or address bar

If a secret ends up in a commit:

1. Do **not** push.
2. Rotate the token (sign out of Claude Desktop, sign back in — this
   invalidates the leaked `sk-ant-ort01-...`).
3. Rewrite history (`git reset --soft HEAD~1`, redo the commit).
4. If you did push: open a private security advisory on GitHub and the
   maintainers will coordinate rotation + a force-push.

See [SECURITY.md](SECURITY.md) for the full policy.

## Commit style

Conventional-commit prefixes keep history scannable:

- `feat(ui): add plan-pill color inheritance`
- `fix(main): handle null EXE_PATH on first run`
- `docs(readme): clarify Node 20 requirement`
- `chore(deps): bump electron to 32.2.3`
- `refactor(renderer): hoist swatch render out of modal boot`

Keep the first line under 72 characters. Body (if any) explains the
*why*.

## Pull requests

- Fill in the PR template completely. The security checklist is not
  optional.
- Link the related issue if there is one.
- Expect a maintainer to run the local smoke test on Windows before
  merging.
- CI must be green. If `check-pii` fails, read the output and fix the
  flagged file.
