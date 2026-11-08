# Contributing to Claude Launcher

Thanks for taking a look. A few things up front so we don't waste each
other's time:

## Scope

This project is a **wrapper around Claude Desktop**. It will not grow
into:

- A Claude client (don't talk to `/v1/messages` directly)
- A proxy or router (don't share auth across accounts)
- A rate-limit workaround (each profile is its own account, hits its
  own limits)
- A plugin / extension system (doubles maintenance for a user count
  that doesn't justify it)
- A telemetry collector (zero outbound traffic is a load-bearing trust
  signal)

Features in those directions will be closed with a thank-you. Features
that make the wrapper nicer, more reliable, more accessible, or
cross-platform are all fair game.

## Maintainer realities (lazygit-style honesty)

- **Solo maintainer, best-effort SLA.** First comment on a PR within
  ~7 days. Occasional week-long silences during life.
- **I will push back on features** that expand scope. "No" is the
  default answer for anything in the scope list above.
- **I won't merge PRs** that add npm dependencies without justification
  in the PR body, change the trust boundary (telemetry, external
  calls, token handling), or ship without matching docs.
- **I will merge PRs** that fix bugs, add tests, improve accessibility,
  tighten the PII scanner, make install easier, or add platform
  support with real maintainer interest.

If this isn't your style, that's genuinely fine — fork is encouraged.

## Dev setup

```bash
git clone https://github.com/squashyweeb/claude-launcher
cd claude-launcher
npm install
npm start
```

For the PowerShell fallback:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File legacy\launcher.ps1
```

For the Python `whois.py` helper:

```bash
python -m pip install -r scripts/requirements.txt
```

## What to work on

- Issues tagged [`good first issue`](https://github.com/squashyweeb/claude-launcher/labels/good%20first%20issue)
  (always 2-5 open, refilled as they close)
- [`help wanted`](https://github.com/squashyweeb/claude-launcher/labels/help%20wanted)
  for things the maintainer can't easily do (Mac/Linux ports, SignPath
  cert, package-manager manifests)
- Anything in [docs/09-roadmap.md](docs/09-roadmap.md) listed as Tier-2
  (not in the "permanent no" pile)

Not sure? Open a Discussion first.

## Testing

**Manual smoke before every PR:**

1. Delete your local `profiles.json` / `prefs.json` / `config.json`
   (or move aside)
2. `npm start` — empty-state tile shows, no DevTools errors
   (`Ctrl+Shift+I`)
3. Add a throwaway test account, launch, close, right-click Edit,
   Remove
4. If you touched `legacy/launcher.ps1`, run it once and confirm the
   window opens

**CI runs on every push:**

- `node scripts/check-pii.js` — PII sentinel scan
- `gitleaks` — secret scan
- `node --check` on every JS file
- PowerShell parse check on `legacy/launcher.ps1`
- Python compile check on `scripts/whois.py`
- Electron packager smoke build on Windows

## Avoiding PII leaks

Before every push:

```bash
npm run check-pii
```

**Never commit:**

- Real email addresses (anyone's)
- Real Anthropic account UUIDs
- Any OAuth token (`sk-ant-oat01-*` / `sk-ant-ort01-*` / `sk-ant-api03-*`)
- The MSIX publisher hash from your machine (`claude_<hex>\`)
- Absolute paths with usernames (`C:\Users\<you>\…`)
- `profiles.json` / `prefs.json` / `config.json` (gitignored, but
  double-check)
- Screenshots with the above visible in a status bar or dev-tools pane

If a secret lands in a commit:

1. **Don't push.**
2. Rotate: sign out of Claude Desktop, sign back in → invalidates any
   leaked `sk-ant-ort01-*`.
3. Rewrite history (`git reset --soft HEAD~1`, redo the commit).
4. If you already pushed to a public remote: open a private Security
   Advisory immediately; maintainer will coordinate a rotation window.

See [SECURITY.md](SECURITY.md).

## Commit style

Conventional-commit prefixes keep history scannable:

- `feat(ui): add plan-pill color inheritance`
- `fix(main): handle null EXE_PATH on first run`
- `docs(readme): clarify Node 20 requirement`
- `chore(deps): bump electron to 32.2.3`
- `refactor(renderer): hoist swatch render out of modal boot`

First line under 72 chars. Body explains the *why*.

## Pull requests

- Fill in the PR template completely (the security checklist is not
  decorative)
- Link the issue if there is one
- Expect maintainer feedback within 7 days
- CI must pass. If `check-pii` fails, read the output and fix the
  flagged file.

## Platform ports (Mac / Linux)

Yes, in principle. But: only merge a port when a contributor commits
to maintaining it (the maintainer can't verify Mac/Linux bugs). Open
a `help wanted` / port PR; include your availability for triage over
the next 6 months. The core team (currently 1 person) won't take on
a platform they can't run.

## Questions

- General: [GitHub Discussions](https://github.com/squashyweeb/claude-launcher/discussions)
- Bugs / features: [Issues](https://github.com/squashyweeb/claude-launcher/issues/new/choose)
- Security: [Private advisory](https://github.com/squashyweeb/claude-launcher/security/advisories/new)

By contributing, you agree your contributions are licensed under the
[MIT License](LICENSE).
