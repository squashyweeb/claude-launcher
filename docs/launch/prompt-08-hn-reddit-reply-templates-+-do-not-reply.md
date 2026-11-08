# Prompt 8: HN/Reddit reply templates + DO-NOT-reply list

**Purpose:** Pre-write the 12 most-likely comment-reply templates so the maintainer can respond in <60 seconds instead of writing from scratch — reply velocity is the single highest signal of thread health.

**Writes to:** docs/launch/replies.md (maintainer's local reference; pin to clipboard manager or paste-buffer app for launch day).

---

## The prompt (paste into Claude/ChatGPT)

```
You are pre-writing the 12 most-likely HN/Reddit comment-reply templates for Claude Launcher's launch day. Match the voice of jesseduffield (lazygit) — honest, concise, never defensive. Each template ≤80 words, plain prose, at most one GitHub link per reply.

Produce reply drafts for these 12 questions:

1. "Why not just use Chrome profiles at claude.ai?" → explain web-app ceiling (no MCP, no Claude Code tab, no desktop integration), concede it's fine for chat-only users.
2. "Isn't this against Anthropic's Terms of Service?" → quote the Feb 2026 policy specifically: multi-account itself is allowed for accounts you own; what's banned is sharing/rotating. Link to Anthropic ToS. State Launcher has no rotation and never will.
3. "Why Electron and not Tauri / native / Rust?" → the shim talks to Electron anyway (Claude Desktop is Electron); matching the runtime keeps the whole thing tiny + lets us use Electron's own IPC primitives; also solo-maintainer bandwidth.
4. "When Mac support?" → honest: don't own a Mac, --user-data-dir works upstream, PR welcome; link to tracker issue.
5. "Isn't this the same as Arman-Manteghi/Tandem?" → similar scope; Launcher's differences are {{the three from Prompt 1}}; both projects are fine, pick the one that fits.
6. "How are OAuth tokens stored? Can Launcher read my Claude session?" → Launcher never touches tokens. Each profile is a folder; Claude Desktop stores its own tokens via DPAPI exactly as the unlaunched app does. Link to docs/05-decrypt-tokens.md noting the DPAPI mechanism is documented for RE purposes, not used by Launcher itself.
7. "Any telemetry?" → No. No analytics, no crash reporting, no update ping. Audit: grep the source for `http` — only the official Anthropic domains Claude Desktop itself calls.
8. "Why isn't the installer signed? SmartScreen is gross." → Agreed. V0 is unsigned; SmartScreen workaround is one click (More info → Run anyway); SHA256 checksums on every release; SignPath Foundation application in progress (link to tracker issue #3). EV cert isn't worth $400/yr at v0.
9. "Does it auto-update?" → Launcher itself: no (opt-in via GitHub Releases subscription). Claude Desktop under Launcher: yes, exactly as it did before — we don't touch the install.
10. "Are PRs welcome? What's the review cadence?" → Yes for bugfixes and small UX tweaks; for anything bigger, open an issue first so we can agree on shape. First response within 7 days. Side project, not a job.
11. "Have you benchmarked it vs just having two Windows users?" → Two Windows users is more airtight on isolation (separate DPAPI keychain). Launcher wins on being able to see both accounts on screen simultaneously — Fast User Switching only shows one desktop. Pick based on threat model.
12. "What if Anthropic removes --user-data-dir support?" → Would break Launcher cleanly. The flag is a Chromium primitive, not something Anthropic is likely to remove (it would break their own debug tooling). If they ever did, the project would retire gracefully.

Also produce a "DO NOT reply to these verbatim — think first" list of 5 pattern-matching situations where paste-and-send is wrong:
- An angry user claiming their Claude account got banned → ask for repro, don't speculate on Anthropic enforcement in public
- Someone claiming the repo violates DMCA / trademark → thank them, link to TRADEMARKS.md, do NOT argue inline
- A journalist DM in-thread → respond briefly in-thread, move substantive conversation to DM/email
- A legal takedown template → do not reply inline, consult counsel if real
- Someone posting their own fork with a different license → acknowledge, do not engage with license debate publicly

Output: 12 reply templates + the 5-situation DNR list.
```
