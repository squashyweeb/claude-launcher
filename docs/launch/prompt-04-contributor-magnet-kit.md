# Prompt 4: Contributor-magnet kit

**Purpose:** Produce CONTRIBUTING.md, 2 issue templates, PR template, and a pre-filable backlog of 8 `good first issue` drafts — the lazygit model (radical honesty about maintainer bandwidth) adapted for a solo-maintained Windows Electron OSS repo.

**Writes to:** CONTRIBUTING.md at repo root; .github/ISSUE_TEMPLATE/bug_report.md + feature_request.md; .github/pull_request_template.md if not already present. The 8 GFI drafts are pasted into GitHub Issues UI one at a time at launch so each gets a real issue number.

---

## The prompt (paste into Claude/ChatGPT)

```
You are writing the contributor-onboarding kit for Claude Launcher, a solo-maintained Windows Electron OSS repo at pre-launch. Match the lazygit tone — radical honesty about maintainer bandwidth, no fake all-PRs-welcome promises.

Produce 5 artifacts, each clearly delimited with a `--- FILE: <path> ---` header:

1. CONTRIBUTING.md (≤150 lines) with these sections:
   - "The short version" (3 numbered steps: small PRs open directly; bigger changes open an issue first; every PR has a 1-line description + testing done + screenshot-if-UI)
   - "What I love getting" (5 bullets — clear bug reports with Claude Desktop version + Windows version + repro, feature requests that describe the problem not the solution, translations once string extraction lands, "I ran your commit and it broke X" reports, code review on open PRs)
   - "What I'll probably punt on" (3 bullets — cross-platform until Windows is rock-solid, plugin system, marketing/SEO PRs)
   - "SLA" — one explicit line: "First maintainer response within 7 days, best effort. If 14 days pass with no response, ping the issue."
   - "Setup" (5 lines max: git clone / pnpm install / pnpm dev / pnpm test / done)
   - A closing line in lazygit's voice about the project being a side project, not a job.

2. .github/ISSUE_TEMPLATE/bug_report.md — frontmatter + a form with fields: Claude Desktop version (with "where to find: Help → About"), Windows version, Launcher version, exact repro steps, actual vs expected, log file location (hint: %APPDATA%\claude-launcher\logs\).

3. .github/ISSUE_TEMPLATE/feature_request.md — fields: Problem you're trying to solve, Your workaround today, Proposed solution (optional), Who else might benefit.

4. .github/pull_request_template.md (≤10 lines) — What this changes (one sentence) / Why / Testing done / Screenshot-or-GIF-if-UI checkbox / Linked issue checkbox.

5. GOOD-FIRST-ISSUE BACKLOG — 8 fully-drafted GFI issues to pre-file in the repo BEFORE going public. For each, provide: title, labels (good first issue + area label), 2-paragraph body with exact file path + expected diff size (10-50 LOC) + "Ask here if stuck" footer. Draw from:
   - Add tray-icon badge for unread count
   - Localize error message for duplicate profile name (first i18n hook)
   - Add --help text to shim/install.ps1
   - Replace placeholder app icon (design-help ask)
   - Add "Copy launch command" button in profile row
   - Write unit test for the --profile shim argument parser
   - Document profile folder migration between machines in docs/
   - Add dark-mode styles to settings page

Tone: concrete, friendly, no corporate-OSS fluff. Zero emoji in CONTRIBUTING.md.

Output: 5 artifacts, each with its file-path header.
```
