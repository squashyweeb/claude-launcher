# Launch plan — claude-launcher

Generated 2026-11-08 from 10-agent research + synthesis. Do not publish; this is your playbook.

## Executive summary

Claude Launcher owns a specific, testable niche — Windows users who need multiple Claude Desktop accounts running side-by-side without the sign-out/sign-in dance. The launch stacks a relatable pain hook ("stop re-signing in") on top of an honest-engineer mechanism ("thin UI around --user-data-dir, Anthropic's binary + Anthropic's OAuth") so it reads as credible to HN readers while still landing in <3 seconds for drive-by stargazers. Three levers do most of the work: (1) a 12-second hero GIF showing two Claude windows opening side-by-side, (2) ruthlessly honest positioning that pre-empts the "is this a TOS-adjacent OAuth wrapper?" suspicion already triggered by TonF1917's 978-star repo, and (3) a maintained-expectations contributor model (lazygit-style radical honesty, not fake all-PRs-welcome). Realistic 30-day target: 500-1500 stars if Show HN hits front page + r/ClaudeAI top-week; 100-300 stars if only Reddit works.

## Positioning (goes in README hero)

**Hero (2 sentences, in this order):**

> Stop re-signing in to Claude Desktop just to switch between your work and personal accounts.
> A thin UI around a Chromium CLI flag Claude Desktop already supports — add an account, pick a color, launch with a keypress. Your tokens stay where Claude Desktop put them; nothing is copied, nothing is forwarded, no telemetry.

This is a composite of Framing #1 (pain hook, converts drive-by readers in 3 seconds) + Framing #5 (honest mechanism, converts the HN technical reader who wants to see the clever simplicity). Together they defuse the "is this one of those TOS-adjacent OAuth wrappers?" suspicion that TonF1917/claude-desktop-multiple-windows-different-api (978 stars) actively triggers. The pattern matches Flow Launcher / Zen Browser / Ollama (pain → mechanism, in two breaths). Explicit scope statement one line below: "Not a Claude client. Not a proxy. Not a rate-limit workaround. Not affiliated with Anthropic — see TRADEMARKS.md."

## Repo metadata

- **name**: `claude-launcher`
- **description**: `⚡ Run multiple Claude Desktop accounts side-by-side on Windows.`
- **topics**: `claude`, `claude-desktop`, `anthropic`, `multi-account`, `account-switcher`, `profile-manager`, `electron`, `windows`, `windows-11`, `desktop-app`, `launcher`, `productivity`, `productivity-tools`, `developer-tools`, `hacktoberfest`
- **website**: `https://{{owner}}.github.io/claude-launcher/`

## The 8-level prompt

Paste each prompt into Claude or ChatGPT in order. Each produces one specific artifact. See `prompt-NN.md` for each full prompt.

### Level 1: Positioning lock-in

**Purpose:** Produce the hero tagline, three checkable differentiators, who-it's-for / who-it's-NOT-for blocks, non-affiliation disclaimer, and the 100-char About field — the foundation every other prompt builds on.

**Writes to:** Saved to docs/positioning.md. Hero + disclaimer go straight into README.md (Prompt 2 consumes them). About field pasted into GitHub repo settings. Who-is/isn't blocks reused in Show HN first comment (Prompt 5).

### Level 2: Star-optimized README

**Purpose:** Produce the full README.md — hero, why, install, features (5 with inline screenshots), how-it-works, what-still-works, FAQ, contributing, license — in the composite PowerToys + Flow Launcher + lazygit structure proven in high-star analog repos.

**Writes to:** README.md at repo root. Also write TRADEMARKS.md with the GordonBeeming/claude-bar pattern (name + logomark are Anthropic's; MIT doesn't grant trademark rights; project runs official app, does not redistribute or embed Anthropic software).

### Level 3: Hero visual production brief

**Purpose:** Shot-by-shot script for the 12s hero GIF + 5 static screenshots, plus the scrub checklist that keeps real emails / tokens / conversation titles out of launch materials.

**Writes to:** docs/images/README.md (shot list + scrub checklist as a reference for future screenshot refreshes). Actual images saved to docs/images/{hero.gif, shot-tray.png, shot-two-up.png, shot-settings.png, shot-add-account.png, shot-launch.png}.

### Level 4: Contributor-magnet kit

**Purpose:** Produce CONTRIBUTING.md, 2 issue templates, PR template, and a pre-filable backlog of 8 `good first issue` drafts — the lazygit model (radical honesty about maintainer bandwidth) adapted for a solo-maintained Windows Electron OSS repo.

**Writes to:** CONTRIBUTING.md at repo root; .github/ISSUE_TEMPLATE/bug_report.md + feature_request.md; .github/pull_request_template.md if not already present. The 8 GFI drafts are pasted into GitHub Issues UI one at a time at launch so each gets a real issue number.

### Level 5: Show HN launch package

**Purpose:** Ranked title candidates + submission body + pre-written first comment + thread-health rules. The maintainer pastes the first comment within 2 minutes of submitting — this is the single highest-ROI move for HN front-page probability.

**Writes to:** docs/launch/show-hn.md (archived copy); submission at news.ycombinator.com/submit; first comment pasted as self-reply to the Show HN post within 2 min of submission.

### Level 6: Reddit launch variants

**Purpose:** Four subreddit-tuned posts (r/ClaudeAI, r/opensource, r/windows, r/selfhosted) with correct flair, culture match, and native-image embedding — scheduled at 30-min intervals from T+30 min onward so none trips Reddit's cross-posting spam filter.

**Writes to:** docs/launch/reddit-posts.md (archived); pasted into each subreddit at T+30 / T+60 / T+90 / T+120 minutes.

### Level 7: Twitter thread + newsletter outreach + LinkedIn

**Purpose:** T-5 teaser tweet, 6-tweet launch-day thread, 4 newsletter emails (Console.dev, TLDR Dev, Bytes, Cooperpress), T+24h LinkedIn reflection — all channels tuned to their audience and rhythm.

**Writes to:** docs/launch/social.md (archived); teaser to X at T-5d; thread to X at T+5min; LinkedIn post at T+24h; newsletter emails at T+12h.

### Level 8: HN/Reddit reply templates + DO-NOT-reply list

**Purpose:** Pre-write the 12 most-likely comment-reply templates so the maintainer can respond in <60 seconds instead of writing from scratch — reply velocity is the single highest signal of thread health.

**Writes to:** docs/launch/replies.md (maintainer's local reference; pin to clipboard manager or paste-buffer app for launch day).


## Launch playbook

**T-7 days — Repo prep (GitHub)**

Finalize all artifacts from Prompts 1-4. Verify README renders on GitHub mobile. Pre-file the 8 `good first issue` drafts as real issues. Set 15 topics, About description with leading ⚡, Website field to GitHub Pages landing. Upload 1280×640 social preview. Enable Discussions (4 categories: Announcements / Q&A / Ideas / Show-and-Tell). Enable GitHub Sponsors.

```
Launch-day checklist (verify each before going public):
[ ] README.md renders on GitHub mobile
[ ] Hero GIF loads <2s on 4G throttle
[ ] 15 topics set, About has leading ⚡
[ ] 8 GFI issues pre-filed and labeled
[ ] Social preview PNG uploaded (Settings → Social preview)
[ ] Discussions enabled with 4 categories
[ ] CONTRIBUTING.md, TRADEMARKS.md, LICENSE in place
[ ] Latest Release has signed-or-noted .exe + SHA256
[ ] Repo visibility flipped from Private → Public
```

**T-5 days — X/Twitter (personal)**

Post 20-second GIF teaser with no link. Builds anticipation and lets early followers mentally bookmark.

```
been building this. Claude Launcher: run multiple Claude Desktop accounts side-by-side on Windows. first release dropping Tue. drop a 👀 if you'd try it. (GIF attached)
```

**T-3 days — DMs (warm network)**

DM 5-10 developer friends personally. Explicitly do NOT ask for upvotes — HN penalizes coordinated voting rings via account-age + IP clustering (silent de-ranking).

```
Hey — I'm Show HN'ing Claude Launcher on Tue 8:45 AM ET. Repo: {{link}}. If you take a look and it's actually interesting, I'd love a substantive comment (tech question, use-case story, or honest critique). Please don't vote or ask others to — HN's rings detector is scary good and I'd rather have a slow-burn thread than a de-ranked one. No obligation — thanks either way.
```

**T-2 days — Awesome-list PRs**

Submit PRs to awesome-claude, awesome-electron, awesome-windows-apps, awesome-anthropic (if it exists). Each merge compounds over months.

```
PR title: Add Claude Launcher — multi-account Claude Desktop for Windows
PR body:
Repo: https://github.com/{{owner}}/claude-launcher
Description: ⚡ Run multiple Claude Desktop accounts side-by-side on Windows
License: MIT
Added under: {{section}}
```

**T-1 day — Fresh Windows VM dry-run**

Install from GitHub Releases on a clean Windows 11 VM (NOT your dev machine). Verify every README install step first-try. Verify hero GIF loads <2s on Chrome DevTools 4G throttle. Check 8 GFIs render cleanly. Verify Discussions has pinned 'Introduce yourself' post seeded.

```
Dry-run verification log (fill in):
VM: Windows 11 clean install, no dev tools
Download: .exe from Releases — SmartScreen? [y/n], SHA256 match? [y/n]
Install: time-to-first-launch ____ seconds
README follow-along: steps that broke ____
GIF render on 4G throttle: ____ seconds
GFI issue #1 visible with full body: [y/n]
Discussions pinned thread live: [y/n]
```

**T+0 — Hacker News**

Submit to news.ycombinator.com/submit with GitHub repo URL (NOT a product domain — GitHub-direct converts 3x better per nastyox1 playbook).

```
Title: Show HN: Claude Launcher — Run N Claude Desktop accounts on Windows via a 2KB shim
URL: https://github.com/{{owner}}/claude-launcher
Text field: [leave empty, OR paste the 80-word submission body from Prompt 5]
```

**T+2 min — HN self-reply**

Paste pre-written first comment (from Prompt 5) as a top-level reply to your own Show HN post. Maker-first-comment-within-the-first-hour correlates with 10+ total comments 19.9% of the time vs 12.3% without.

```
[Uses Prompt 5 output — 4 paragraphs, ~200 words, ends with: 'Would anyone actually use a macOS build? I don't own a Mac to test.']
```

**T+5 min — X/Twitter**

Post the 6-tweet launch thread from Prompt 7. Tweet 1 has the hero GIF + GitHub link + HN link.

```
[Uses Prompt 7 output — 6 tweets numbered 1/6 through 6/6]
```

**T+30 min — r/ClaudeAI**

Post r/ClaudeAI variant with 'Built with Claude' flair. 1M members, highest-activity flair.

```
[Uses Prompt 6 output for r/ClaudeAI]
```

**T+60 min — r/opensource**

Post r/opensource variant with 'Promotional' flair. Name Tandem as differentiation.

```
[Uses Prompt 6 output for r/opensource]
```

**T+90 min — r/windows**

Post r/windows variant. Avoid 'launch' in title (triggers automod). Native image upload required.

```
[Uses Prompt 6 output for r/windows]
```

**T+120 min — r/selfhosted**

Post r/selfhosted variant with 'Software' flair. Lead with per-profile MCP isolation angle.

```
[Uses Prompt 6 output for r/selfhosted]
```

**T+2 hours (decision gate) — Internal**

Read HN points. 100+ → front page probable, clear 4 more hours for replies, start PH prep. 30-100 → mid-tier, double down on Reddit + newsletters. <30 → pivot to r/ClaudeAI as primary, don't repost.

```
Gate decision log:
T+2h points: ____
T+2h comments: ____
Top-level comments awaiting reply: ____
Decision: [go-all-in / mid-tier / pivot]
If pivot, notes on why: ____
```

**T+4 hours — dev.to + Hashnode**

Publish long-form 'I built this' writeup. Tags: #showdev, #opensource, #electron, #windows. Cross-post Hashnode. 800-1200 words with embedded hero GIF + architecture diagram.

```
Title: How I built Claude Launcher — multi-account Claude Desktop for Windows in 3 weekends
Opening: I share a Max 20x with my co-founder and I kept logging in and out of Claude Desktop until I finally built this.
Body: pain → architecture → tradeoffs → launch → next steps
Ending: GitHub link + star CTA
Tags: #showdev #opensource #electron #windows
```

**T+12 hours — Newsletters**

Send the 4 newsletter outreach emails from Prompt 7 (Console.dev form, TLDR Dev, Bytes, Cooperpress). Each ≤120 words with hero GIF inline.

```
[Uses Prompt 7 outputs — 4 separate emails to console.dev/submit, dev@tldrnewsletter.com, hi@bytes.dev, JavaScript Weekly or Node Weekly]
```

**T+24 hours — LinkedIn**

Post T+24h reflection from Prompt 7. Numbers + user story + one honest miss + one thing I'd do differently. Drives a second wave from the pro-network audience that doesn't read HN.

```
[Uses Prompt 7 LinkedIn output — ~300 words, ends with GitHub link]
```

**T+48 hours — GitHub Discussions seed**

Seed Discussions with 2-3 real threads: 'Introduce yourself — what are you using Claude Launcher for?' (pinned), 'Mac/Linux port — who'd want this?', 'MCP server configs per profile — what's your setup?'. Builds the 'this project has a community' signal.

```
Pinned discussion seed:
Title: Introduce yourself — what are you using Claude Launcher for?
Body: Quick thread so the first wave of folks can see who's here. I'll start: I share a Max 20x between my dev account and my personal one, and the profile picker gets me from 'need to switch' to 'in the right account' in under 2 seconds. What's your setup?
```

**T+7 days — Product Hunt**

Separate launch with 'rebuilt based on HN feedback: added X, Y' angle. PH rewards the 'who it's for + screenshot carousel' angle. 5-shot carousel from the static screenshots. Line up a hunter if possible.

```
PH tagline: ⚡ Run multiple Claude Desktop accounts side-by-side on Windows
PH description (260 chars): Stop re-signing in to Claude Desktop just to switch between your work and personal accounts. Claude Launcher adds any account, picks a color, and launches with a keypress — isolated profiles, no telemetry, MIT.
First maker comment: short recap of HN feedback integrated + thank-you + ask for honest first-impression reviews
```

**T+14 days — Package managers**

Submit to winget and scoop manifests. Both have light approval processes. Each merged manifest adds a durable discovery surface compounding for months.

```
winget: fork microsoft/winget-pkgs, add manifests/{{owner}}/claude-launcher/{version}.yaml per schema
scoop: open PR to scoop extras bucket with manifest JSON (installer URL + hash + version)
```

**T+30 days — Retrospective**

If stars > 500: double down on content (dev.to follow-ups, YouTube walkthrough, Twitter threads on specific technical wins). If 100-500: focus on contributor-magnetism metrics (GFI queue, Discussions replies/week). If <100: salvage via awesome-list PRs + niche subreddit posts; the project is still useful even if virality didn't happen.

```
30-day retro template:
Stars: ____
Unique clones: ____
Open issues / closed issues: ____
Discussions threads: ____
Merged community PRs: ____
Top traffic source: ____
Feedback themes (3 bullets): ____
What to double down on: ____
What to kill: ____
Next milestone (60/90 days): ____
```


## Hero visual brief

**Primary deliverable: 12-second hero GIF**
- Dimensions: 1200×800 px, 12-15 fps, target ≤4MB, 64-color palette-optimized
- Export via gifski (`--fps 15 --quality 85`) or ezgif's 64-color preset. NOT Photoshop (bloats to 15MB+)
- Hosted at `docs/images/hero.gif` with `?raw=true` suffix in README to force inline render
- If >5MB: upload as GitHub Release asset or issue comment to get github.com/user-attachments URL (bun pattern) to keep git clone fast

**GIF shot script (12s, record on 1440p for crisp downscale):**
| Time | Shot |
| --- | --- |
| 0-1s | Clean Windows 11 desktop, only Claude Launcher tray icon visible |
| 1-3s | Click tray → card-deck picker opens with 3 profiles ("Ryan — Personal", "Ryan — Work", "Ryan — MCP Dev"), each with distinct avatar color + keyboard-hint chip (1/2/3) |
| 3-5s | Click "Ryan — Personal" → Claude Desktop fades in on LEFT with personal chat sidebar visible |
| 5-7s | Click tray again → picker reopens |
| 7-9s | Click "Ryan — Work" → second Claude Desktop fades in on RIGHT with visibly different sidebar/conversations |
| 9-12s | Both windows live side-by-side, cursor hovers between them to prove both are functional |

**Five static PNG screenshots (1400×900 native, pngquant-compressed to 200-400 KB each):**
1. `shot-tray.png` — picker showing 4 profiles with keyboard hints (1,2,3,4) in corners
2. `shot-two-up.png` — two Claude Desktop windows side-by-side, different sidebars, both Claude icons in Windows taskbar
3. `shot-settings.png` — Launcher settings pane (default profile, launch-on-startup, hotkey fields)
4. `shot-add-account.png` — "Add new account" modal with name field + color picker
5. `shot-launch.png` — picker with one profile keyboard-focused (highlight ring)

**Scrub checklist — must NOT be visible in ANY frame:**
- Real email addresses → scrub to `ryan@personal.example` / `ryan@work.example` / `ryan@mcp.example`
- Real OAuth tokens → record from freshly-made test accounts, never from logged-in production ones
- Any conversation title with a real project/company/person name → replace with `React hooks question`, `Draft blog post`, `Weekly planning notes`
- Taskbar → hide all apps except Claude; solid gray or dark wallpaper only
- Notification badges → clear all
- SmartScreen, UAC, or Windows notification prompts
- Username in title bars or paths → scrub to "ryan" or "user"

**Alt text (one declarative sentence under 100 chars each, screen-reader AND GitHub-search friendly):**
- hero.gif: "Claude Launcher switching between two signed-in Claude Desktop accounts on Windows"
- shot-tray.png: "Claude Launcher profile tray with four saved accounts and keyboard shortcut hints"
- shot-two-up.png: "Two Claude Desktop windows running side-by-side with different accounts on Windows"
- shot-settings.png: "Claude Launcher settings pane showing default profile and hotkey configuration"
- shot-add-account.png: "Claude Launcher add-account modal with name field and color picker"
- shot-launch.png: "Claude Launcher profile picker with keyboard focus on a selected profile"

**Social preview image (separate from README visuals): 1280×640 PNG, shows the two-up screenshot with a title-card overlay reading "Claude Launcher — multi-account Claude Desktop for Windows". Uploaded via repo Settings → Social preview. This is what shows in X/HN/Reddit unfurls — single highest-leverage 300KB in the repo.**

## Alternatives table

## Why not just ___?

Running two Claude Desktop accounts side-by-side on Windows has a few obvious workarounds. Here's where each one falls short, honestly.

| Approach | Pros | Cons | Best for |
| --- | --- | --- | --- |
| **Pass `--user-data-dir` by hand** | Zero install. Uses Electron's built-in flag — no third-party code in the loop. Fully reversible. | Windows MSIX install under `C:\Program Files\WindowsApps` blocks passing args to the exe, so you copy Claude out of `WindowsApps` yourself. The copy drifts on every Claude Desktop auto-update unless you re-copy. No GUI — you manage shortcuts, `CLAUDE_CONFIG_DIR`, and MCP paths by hand. | One-off power users who like living in shortcuts and don't mind redoing the copy after each update. |
| **Two Windows user accounts** | True OS-level isolation — separate `%APPDATA%`, separate DPAPI keychain, separate MCP servers. The most airtight option on this list. | Fast User Switching only shows one desktop — you can't see both accounts on screen at the same time. Doubles the Windows admin surface. Impractical for rapid context switching. | Strict privacy / compliance contexts, or a shared family PC where account bleed-over is unacceptable. |
| **Two Chromium browsers at `claude.ai`** (Chrome + Brave, etc.) | Already installed. Works today with zero tooling. Each browser keeps its own cookies/session. | No MCP servers, no Claude Code tab, no local file access, no tuned OS notifications. Memory doubles because you're running two full Chromium processes. | Chat-only users who aren't running MCPs and don't want anything installed. |
| **Chrome profiles + `claude.ai`** | Free, built into Chrome, one-click switcher, syncs across machines via Google. | Same web-only ceiling — no MCP, no Claude Code, no desktop integration. Claude sign-in is tied to each Google profile, which gets awkward when sharing a Windows machine. | Casual users who already live in Chrome profiles and don't need desktop-only features. |
| **Multi-account web hubs** — Ferdium (Apache-2.0), Rambox, Wavebox, Arc Spaces | One window with every service in a sidebar. Mature UX. Cross-platform. Ferdium is free and OSS. | Still a wrapper around `claude.ai` — no native MCP, no Claude Code tab. Rambox gates workspaces + multi-login behind $7/mo Pro. | People juggling Slack + Discord + Gmail + Claude in one pane who are fine with web-only Claude. |
| **Sign out, sign back in** | Nothing to install. Works on every platform. | Lose window state, open chats, and MCP server state on every switch. Costs minutes per swap and it's easy to forget which account is billing when you're in a hurry. | Rare-switch users (weekly or less) who don't mind the friction. |

**Prior art.** A handful of OSS projects already solve pieces of this. [Arman-Manteghi/Tandem](https://github.com/Arman-Manteghi/Tandem) is Windows + tray + global shortcut with per-account usage tracking, closest in scope. [sypnose-cloud/claude-desktop-multi](https://github.com/sypnose-cloud/claude-desktop-multi) uses a PowerShell installer + MS Store app, focused on surviving auto-updates. [RichardKPL/multi-claude](https://github.com/RichardKPL/multi-claude) is a GPL-3.0 portable launcher. [weidwonder/claude-desktop-multi-instance](https://github.com/weidwonder/claude-desktop-multi-instance) covers macOS. There's also the commercial [claudeprofiles.com](https://claudeprofiles.com/). Claude Launcher's niche inside that group: a Windows-first Electron GUI with a 2KB `--profile` shim, MIT, and a PowerShell fallback for locked-down corporate machines.

Claude Launcher is for people on Windows who want 2+ Claude Desktop accounts open at once without hand-copying the MSIX package or losing their shortcuts on every auto-update. If any row above fits you better, use that instead — we'd rather you find the right tool than star the wrong one.

## Deferred (do NOT do at launch)

- Separate docs site (Docusaurus / Mintlify / GitHub Pages technical docs). Defer until repo passes 1,000 stars OR README exceeds ~400 lines. Justification: zero of the three small-utility comparables that reached real star counts (winfetch 1.8k, Auto Dark Mode 10k, Flow Launcher 16k) built a separate docs site before earning stars. The existing docs/ folder already renders beautifully on GitHub with relative links, zero build pipeline, zero drift. Use the GitHub Wiki as community-FAQ overflow instead.
- CODE_OF_CONDUCT.md. Defer until ~500 stars OR first community incident, whichever comes first. Justification: Charm's entire stack (gum, bubbletea, lipgloss) ships without one at 100k+ collective stars. A templated CoC in a 0-star repo reads as checkbox-performance; add it when there's actual community to govern.
- Discord server. Defer indefinitely — use GitHub Discussions until daily traffic justifies the move. Justification: a dead Discord with 3 members is worse than no Discord (signals abandoned). Discussions are zero-friction, search-indexed, and scale down to empty-state gracefully.
- CODEOWNERS file. Defer until a second regular reviewer joins. Justification: only supabase (corporate, 114k stars) uses it among comparables. For solo maintainers it's bureaucratic noise that fails silently when reviews are missed.
- EV code signing certificate ($400+/yr). Defer indefinitely. Justification: apply to SignPath Foundation instead — free for OSS projects meeting their criteria (public repo + OSI license + MFA on all maintainers + GitHub Actions build + Code-signing-policy section in README). Document the SmartScreen workaround clearly on v0; open a public tracker issue for the SignPath application to show the gap is known.
- Mac and Linux ports. Defer until Windows story is rock-solid (0 critical bugs open, 500+ stars, CI green for 30 consecutive days). Justification: scoped product; a half-working macOS port on launch day dilutes the message. Track as `help wanted` GFI issue so community can start on it.
- Auto-rotation, multi-API routing, or any rate-limit workaround features. Defer PERMANENTLY — hard no. Justification: this is what killed claude-swap's rotation feature (issue #233) and what the Feb 2026 Anthropic policy update targeted. Any such feature turns Claude Launcher from a profile switcher (fully fine with Anthropic ToS) into a guardrail-bypass tool (ToS violation, invites takedown). Marketing the project as non-rotating is itself a trust signal.
- Telemetry, crash reporting, analytics. Defer PERMANENTLY. The "zero outbound traffic beyond what Claude Desktop itself does" promise is a core trust signal used in the README voice. Never add even opt-in crash reporting.
- Plugin / extension system. Defer until 2000+ stars AND a specific user request thread with 20+ replies justifying it. Justification: doubles the maintenance surface for an audience of maybe 3 people. The product's whole pitch is "thin UI around a Chromium flag" — a plugin system betrays that.
- Marketing landing page beyond the minimal GitHub Pages landing. Defer until stars > 1,500. Justification: zed and bun can skip README screenshots because they have strong marketing sites (zed.dev, bun.com); Claude Launcher does not yet have the star-count to pull the brand weight.
- Custom theming / skinning. Defer indefinitely. Not on the critical path for any of the three target personas.
- Mobile companion app. Defer indefinitely. Claude Desktop isn't on mobile.
- Localization beyond ad-hoc i18n. Defer until string-extraction PR lands AND a Crowdin or Weblate project is justified by at least one community-translator volunteer in Discussions.
- Promising a 24h or 48h PR-review SLA. Defer PERMANENTLY — commit only to the 7-day best-effort SLA in CONTRIBUTING.md. Justification: a broken SLA is more damaging than a modest one; lazygit's maintainer explicitly refuses PRs and still has 83k stars because transparency beats pretense.

## Success metrics

- Day 1 HN points at T+2h: 100+ = front-page probable (go all-in on replies, prep Product Hunt). 30-100 = mid-tier (pivot amplification to Reddit + newsletters). <30 = pivot to r/ClaudeAI as primary channel, don't repost on HN.
- Day 1 total stars: target 500-1500 if HN front page + r/ClaudeAI top-week both land; 150-300 if only one channel works; 50-100 floor if nothing virals and compounding comes from awesome-list PRs only.
- Day 7 stars: 1,000+ (sign the launch worked). Day 30 stars: 2,000+ (sign the compounding channels — awesome-list merges, newsletter mentions, Product Hunt — are working).
- HN thread longevity: active author replies for the full first 4 hours keeps the thread alive for 18-24h vs 4-6h with absent author (AFFiNE case study). Measure: time from post to last top-level comment.
- Reddit: r/ClaudeAI post reaches top-week (typical cutoff 300+ upvotes). r/opensource and r/windows: 50+ upvotes each is a win; 200+ is top-day.
- Contributor-magnetism (track weekly for first 90 days): (a) median time from issue open to first maintainer comment <72h, (b) open `good first issue` count stays at 2-5 (refill as they close), (c) Discussions has >0 new threads per week by week 6 — if zero, pin a 'How are you using Claude Launcher?' thread seeded by maintainer.
- External validation: at least 1 newsletter mention in the first 7 days (Console.dev, TLDR Dev, Bytes, or a Cooperpress property). At least 3 awesome-list PRs merged in the first 30 days.
- Qualitative: the 'is this one of those TOS-adjacent OAuth wrappers?' question gets asked and answered cleanly in the HN thread (not avoided). If the question doesn't surface, the positioning was too vague; if it dominates, the positioning failed to pre-empt it.
- Anti-metrics (ignore these): raw clone count without star growth (bots), GitHub profile followers (vanity), Twitter impressions (not correlated with stars for dev tools).
- 30-day retrospective trigger: at T+30 days, run the Prompt 1 output through a brand-voice audit — has the project started making claims it can't demo in 60 seconds? If yes, reset README to the Prompt 2 baseline. Scope drift is the #1 cause of second-month stall for new OSS repos.
