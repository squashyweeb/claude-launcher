# Prompt 5: Show HN launch package

**Purpose:** Ranked title candidates + submission body + pre-written first comment + thread-health rules. The maintainer pastes the first comment within 2 minutes of submitting — this is the single highest-ROI move for HN front-page probability.

**Writes to:** docs/launch/show-hn.md (archived copy); submission at news.ycombinator.com/submit; first comment pasted as self-reply to the Show HN post within 2 min of submission.

---

## The prompt (paste into Claude/ChatGPT)

```
You are drafting the Show HN launch package for Claude Launcher. Launch date: {{Tuesday or Wednesday}} {{YYYY-MM-DD}} at 8:45 AM ET (= 5:45 AM PT / 2:45 PM CET). Repo URL: https://github.com/{{owner}}/claude-launcher. Direct competitor to acknowledge mid-thread: Arman-Manteghi/Tandem (Windows, same scope).

Produce:

1. THREE TITLE CANDIDATES ranked by HN-upvote likelihood, each ≤80 chars, each with ONE specific checkable claim:
   (a) technical-cleverness lead: "Show HN: Claude Launcher — Run N Claude Desktop accounts on Windows via a 2KB shim"
   (b) portable/MIT lead: "Show HN: Claude Launcher — Portable Electron app for multiple Claude Desktop accounts (MIT)"
   (c) corp-IT angle: "Show HN: Claude Launcher — Multi-account Claude Desktop with a PowerShell fallback for locked-down Windows"
   For each, give one-sentence rationale. Pick ONE as the submission title. Default recommendation: (a) because "2KB shim" is checkable, specific, and HN upvotes clever.

2. SUBMISSION BODY (optional field; ≤80 words) — one short paragraph summarizing pain + mechanism + what makes this different from the already-crowded multi-account-Claude niche.

3. PRE-WRITTEN FIRST COMMENT (post within 2 minutes; 4 paragraphs; ≤200 words total):
   - P1: Why I built it (personal pain — sharing Max 20x between dev + personal)
   - P2: How it works (Electron --user-data-dir + a shim that handles MSIX install path indirection; link to docs/01-architecture.md)
   - P3: Honest limitations — Windows only, unsigned on v0 so SmartScreen will warn once (workaround documented), Anthropic ToS allows multi-account but enforcement has banned legitimate users in waves (link to Feb 2026 Anthropic policy update), no auto-rotation feature and never will be
   - P4: Acknowledge Tandem by name (Arman-Manteghi/Tandem), state the specific differentiator (shim design + portable + MIT), end with ONE open question — "Would anyone actually use a macOS build? I don't own a Mac to test" — to drive comment velocity

4. SHOW HN THREAD HEALTH RULES — 6 bullets the maintainer re-reads 10 minutes before launch:
   - Reply to every top-level comment within 60 min for first 4 hours
   - Never defend features defensively — "good point, tracked in #N" beats explanation
   - Have the 12 pre-written reply templates from Prompt 8 open in a tab
   - Never ask for upvotes anywhere, ever (HN detects coordinated voting via account-age + IP clustering; penalty is silent de-ranking)
   - If post gets <30 pts in first 2 hours, pivot to r/ClaudeAI as primary channel, don't repost
   - Email hn@ycombinator.com with "second-chance pool" request ONLY if post was drowned by concurrent Anthropic/AI headline

5. SUCCESS GATES to decide at T+2h:
   - 100+ points → front-page likely, clear 4 more hours for replies, start PH prep
   - 30-100 pts → mid-tier, pivot amplification to Reddit + newsletters
   - <30 pts → pivot to r/ClaudeAI as primary; don't repost

Output: title choice with rationale + submission body + first comment + health rules + success gates.
```
