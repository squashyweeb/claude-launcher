# Security Policy

## Supported versions

This project is pre-1.0 and ships from `main`. Only the latest tagged
release and the current `main` branch receive security fixes.

## What the launcher does with your data

- The launcher reads and writes **only** files inside its own
  installation directory (`profiles.json`, `prefs.json`,
  `config.json`), plus the per-profile folders you explicitly choose to
  attach.
- It **never** stores, logs, or transmits an OAuth token value. Tokens
  are managed entirely by Claude Desktop and sit encrypted at rest
  inside each profile's `Local State` + `Network/Cookies` files
  (DPAPI-sealed by Windows, tied to your Windows user SID).
- The only outbound network call the launcher ever makes is a single
  `GET https://api.anthropic.com/api/oauth/profile` request, and only
  when you explicitly click **Who is signed in?**. The request includes
  the OAuth access token that is already present on your disk and
  returns the account's email, name, UUID, and plan. The response is
  shown in a MessageBox and discarded. Nothing is sent to any other
  host.
- There is no telemetry, no analytics, no auto-updater, no error
  reporting service.

## Reporting a vulnerability

Please report security issues **privately** via GitHub Security
Advisories:

- Go to the repository's **Security** tab -> **Advisories** -> **New
  draft security advisory**
- Or email the maintainers at the address listed in the GitHub repo
  description (if present)

Do **not** open a public issue for a vulnerability.

What to include:

1. Affected version(s) and OS
2. Reproduction steps
3. Expected vs. observed behavior
4. If applicable, the attack surface (local vs. network vs.
   supply-chain) and whether exploitation requires user interaction

You should get an acknowledgement within 7 days. For in-scope
vulnerabilities, a fix (or a documented mitigation) will land within
30 days, and a coordinated disclosure after a release is cut.

## In-scope issues

- Any path that leaks a user's OAuth token, email, or UUID to a host
  other than `api.anthropic.com`
- Any execution path reachable from a malicious `profiles.json` /
  `prefs.json` / `config.json` (RCE, path traversal, arbitrary file
  write)
- Any way for a third-party website (via the renderer's web view or an
  IPC glitch) to launch arbitrary processes
- Supply-chain concerns (lockfile tampering, dependency confusion)

## Out of scope

- Issues in Claude Desktop itself (report to Anthropic)
- Issues in Node.js, Electron, or any upstream dependency (report
  upstream; we track CVEs via GitHub Dependabot and patch within
  reasonable timeframes)
- Social-engineering a user to launch a crafted profile dir — the
  launcher honors any folder a user explicitly attaches
- Local privilege escalation that already requires full user
  compromise of the Windows account

## Credential hygiene (for contributors and users)

If a token value ever lands in a commit, logs, or screenshot:

1. **Rotate immediately** — sign out of Claude Desktop on every device
   for that account, then sign back in. This invalidates the leaked
   access and refresh tokens.
2. Scrub the git history (`git reset`, `git filter-repo`, or a BFG
   pass) if the commit has not been pushed.
3. If the commit was pushed to a public remote, contact a maintainer
   immediately — we'll coordinate a force-push + rotation window.
