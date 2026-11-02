# Publishing checklist — delete after push

This file exists only to walk you through the first push. **Delete it
once you've pushed.**

## Status

- Local git repo initialized at `C:\Users\wranr\Documents\claude-launcher-oss\`
- 1 commit on `main`, 49 files, 310 KB
- `profiles.json`, `prefs.json`, `config.json`, `node_modules/`, etc. are
  all gitignored and verified not committed
- PII sentinel scan passes
- `OWNER` placeholder is in **one file**: `.github/ISSUE_TEMPLATE/config.yml`
  (two lines) — fill in your GitHub handle before pushing

## Steps

### 1. Fill in the OWNER placeholder

Replace `OWNER` with your actual GitHub handle in
`.github/ISSUE_TEMPLATE/config.yml`:

```powershell
cd C:\Users\wranr\Documents\claude-launcher-oss
(Get-Content .github\ISSUE_TEMPLATE\config.yml) `
  -replace 'OWNER/claude-launcher', '<YOUR-HANDLE>/claude-launcher' |
  Set-Content .github\ISSUE_TEMPLATE\config.yml
git add .github/ISSUE_TEMPLATE/config.yml
git commit -m "chore: set repo owner in issue template"
```

### 2. (Optional but recommended) Rotate OAuth tokens

Sign out of Claude Desktop on **both** accounts (System tray → Quit,
then File → Sign out from each window). Sign back in. This
invalidates any `sk-ant-oat01-*` and `sk-ant-ort01-*` tokens that were
ever on your disk, so even a worst-case leak is harmless.

The scrub already removed those tokens from the repo contents, so this
is defence-in-depth, not a required step.

### 3. Delete this PUBLISH.md

```powershell
git rm PUBLISH.md
git commit -m "chore: remove publish checklist"
```

### 4. Create the GitHub repo (private)

Using `gh` (already in your PATH):

```powershell
gh repo create <YOUR-HANDLE>/claude-launcher `
  --private `
  --source=. `
  --remote=origin `
  --description "Side-by-side launcher for multiple Claude Desktop accounts on Windows."
```

If `gh` asks for auth, follow the prompt. Does **not** push yet.

### 5. Enable push protection BEFORE pushing

Open the repo on github.com, go to **Settings → Code security and
analysis**, and enable:

- Secret scanning
- Push protection ← important — stops a token leak at the push boundary
- Dependabot alerts
- Dependabot security updates

### 6. Push

```powershell
git push -u origin main
```

If push protection blocks the push, read the error message, fix the
flagged line, amend the commit (`git commit --amend`), re-run
`node scripts/check-pii.js`, and push again.

### 7. (Optional) First release

```powershell
git tag -a v0.1.0 -m "Initial release"
git push --follow-tags
```

The release workflow (`.github/workflows/release.yml`) runs
`check-pii`, builds the Electron app, zips it, and attaches the zip +
SHA256 to a new GitHub Release.

### 8. (Optional) Flip to public later

```powershell
gh repo edit <YOUR-HANDLE>/claude-launcher --visibility public
```

### 9. Smoke-test by cloning fresh

```powershell
git clone https://github.com/<YOUR-HANDLE>/claude-launcher.git `
  "$env:TEMP\cl-fresh"
cd "$env:TEMP\cl-fresh"
npm install
npm start
```

You should see an empty-state window with no profiles loaded and no
errors in DevTools (`Ctrl+Shift+I`).

## If you change your mind

The repo is entirely local; nothing has reached GitHub. To scrap:

```powershell
Remove-Item -Recurse -Force C:\Users\wranr\Documents\claude-launcher-oss
```
