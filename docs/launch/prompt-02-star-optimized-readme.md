# Prompt 2: Star-optimized README

**Purpose:** Produce the full README.md — hero, why, install, features (5 with inline screenshots), how-it-works, what-still-works, FAQ, contributing, license — in the composite PowerToys + Flow Launcher + lazygit structure proven in high-star analog repos.

**Writes to:** README.md at repo root. Also write TRADEMARKS.md with the GordonBeeming/claude-bar pattern (name + logomark are Anthropic's; MIT doesn't grant trademark rights; project runs official app, does not redistribute or embed Anthropic software).

---

## The prompt (paste into Claude/ChatGPT)

```
You are writing the star-optimized README.md for Claude Launcher. Target length: ~250 lines. MIT, Windows-only, Electron.

INPUTS (fill from Prompt 1 output and the following):
- HERO TAGLINE: {{tagline from Prompt 1}}
- DIFFERENTIATORS: {{three from Prompt 1}}
- WHO IT'S FOR / NOT FOR: {{from Prompt 1}}
- TRADEMARK DISCLAIMER: {{from Prompt 1}}
- REPO OWNER: {{github-handle}}
- HERO GIF PATH: docs/images/hero.gif (12s, ~4MB)
- STATIC SHOTS: docs/images/shot-tray.png, shot-two-up.png, shot-settings.png, shot-add-account.png, shot-launch.png

Structure (EXACT order):
1. Hero block: centered <picture> for dark/light logo variants, H1 "Claude Launcher", one-sentence centered tagline, centered sub-line "If this saves you from the sign-out dance, give it a star — it helps others find it.", centered anchor-link nav (Install · Features · Why · FAQ · Contributing), 4 badges only (CI status, MIT, platform=Windows, download count). One line below badges in italic: the non-affiliation disclaimer.
2. Hero GIF (just `![alt](docs/images/hero.gif?raw=true)` — the ?raw=true forces inline render on GitHub).
3. "## Why" — 3-row persona table (Shared Max 20x | Work + personal | MCP/plugin testing) with one-sentence benefit per row.
4. "## What this is NOT" — 4 bullets drawn from Prompt 1 (not a client, not a proxy, not a rate-limit workaround, not affiliated).
5. "## Install" — default-open `<details>` for direct .exe from Releases (includes SmartScreen workaround one-liner: "Windows will show 'Windows protected your PC' on first run — click More info → Run anyway. SHA256 checksums on every release."), then 3 collapsed `<details>` for winget, scoop, build-from-source.
6. "## Features" — 5 h3 blocks, each: verb-first one-sentence paragraph + inline 400px screenshot:
   - ### Pick an account, launch it (shot-tray.png)
   - ### Run accounts side-by-side (shot-two-up.png)
   - ### Keyboard-driven (1-9) (shot-launch.png)
   - ### Add an account in one click (shot-add-account.png)
   - ### Stays out of the way (shot-settings.png — tray-first, no dock icon unless you want one)
7. "## How it works" — 2 short paragraphs on Electron's --user-data-dir + the shim. Link to docs/01-architecture.md.
8. "## What still works" — bulleted list of Claude Desktop surfaces preserved per profile: chat history, Projects, MCP servers, tool use, Opus/Sonnet/Haiku picker, usage counters respect the right account's tier (Max 20x / Max 5x / Pro / Free), Slack-in-Claude.
9. "## FAQ" — 6 Q&As: Is this affiliated with Anthropic? / Does it store my Claude credentials? / Will it survive Claude Desktop auto-updates? / Mac/Linux support? / Why not just Chrome profiles at claude.ai? / How do I uninstall cleanly?
10. "## Contributing" — 3 lines: link to CONTRIBUTING.md, link to `good first issue` filter, SLA one-liner ("First maintainer response within 7 days, best effort.").
11. "## License & Trademarks" — one line: "MIT (see LICENSE). The Claude name belongs to Anthropic — see TRADEMARKS.md."

Voice rules:
- No "blazing fast", "seamless", "powerful", "revolutionary" anywhere.
- Every feature sentence starts with a verb.
- No bullet exceeds 20 words.
- One emoji per section heading at most; zero in bullets.
- Trademark handling: one sentence under hero + full text in TRADEMARKS.md. Do not inline the MIT text.

Output the complete raw Markdown. No commentary before or after.
```
