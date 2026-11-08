# Prompt 3: Hero visual production brief

**Purpose:** Shot-by-shot script for the 12s hero GIF + 5 static screenshots, plus the scrub checklist that keeps real emails / tokens / conversation titles out of launch materials.

**Writes to:** docs/images/README.md (shot list + scrub checklist as a reference for future screenshot refreshes). Actual images saved to docs/images/{hero.gif, shot-tray.png, shot-two-up.png, shot-settings.png, shot-add-account.png, shot-launch.png}.

---

## The prompt (paste into Claude/ChatGPT)

```
You are directing the hero GIF and static screenshots for Claude Launcher's README. These materials carry the pitch — the GIF has to make someone want to install in under 12 seconds. Target production tools: ShareX for recording, gifski or ezgif for GIF export, pngquant for PNG compression.

Produce:

1. HERO GIF SCRIPT — 12 seconds, 1200×800 px, 12-15 fps, target ≤4MB, 64-color palette-optimized. Shot-by-shot in seconds:
   - 0-1: Clean Windows 11 desktop with only the Claude Launcher tray icon visible
   - 1-3: Click tray icon → card-deck picker opens with 3 profiles ("Ryan — Personal", "Ryan — Work", "Ryan — MCP Dev"), each with distinct avatar color and keyboard-hint chip (1/2/3)
   - 3-5: Click "Ryan — Personal" → Claude Desktop window fades in on the LEFT with Ryan's personal chat history visible in the sidebar
   - 5-7: Click tray icon again → picker reopens
   - 7-9: Click "Ryan — Work" → second Claude Desktop window fades in on the RIGHT with a visibly different sidebar (different conversation titles)
   - 9-12: Both windows live side-by-side, cursor hovers between them to prove both are functional

2. FIVE STATIC SCREENSHOTS, 1400×900 native PNG, pngquant-compressed to ~200-400 KB each:
   - shot-tray.png: picker showing 4 profiles with keyboard hints (1,2,3,4) in corners
   - shot-two-up.png: two Claude Desktop windows side-by-side, different sidebars, both Claude icons visible in Windows taskbar
   - shot-settings.png: Launcher settings pane — default profile, launch-on-startup, hotkey fields
   - shot-add-account.png: "Add new account" modal — name field + color picker
   - shot-launch.png: picker with one profile keyboard-focused (highlight ring) showing keypress action

3. SCRUB CHECKLIST — must-NOT-be-visible in any frame:
   - Real email addresses (scrub to ryan@personal.example / ryan@work.example / ryan@mcp.example)
   - Real OAuth tokens (record from freshly-made test accounts, never from actual logged-in ones)
   - Any conversation title with a real project, company, or person name — replace with: "React hooks question", "Draft blog post", "Weekly planning notes"
   - Taskbar: hide all apps except Claude; use a plain solid-gray or dark wallpaper
   - Notification area: clear all badges
   - SmartScreen, UAC, or Windows notification prompts
   - Username in title bars or paths — show "ryan" or scrub to "user"

4. PRODUCTION NOTES:
   - Record on a 1440p monitor to preserve crispness after 1200px downscale
   - Export GIF with gifski (`--fps 15 --quality 85`) or ezgif's "optimize to 64 colors" preset — NOT with Photoshop (bloats to 15MB+)
   - All images at docs/images/ in the repo root. If hero.gif > 5MB, upload to a GitHub Release asset or an issue comment to get a github.com/user-attachments URL (bun uses this pattern) rather than committing to git
   - Verify GIF loads in <2s on simulated 4G (Chrome DevTools throttle) before shipping

5. ALT TEXT — one declarative sentence under 100 chars for each of the 6 assets (hero GIF + 5 PNGs). Should scan as both screen-reader friendly AND GitHub-search-crawler friendly.

Output: the shot list + scrub checklist + production notes + alt text table, verbatim. No commentary.
```
