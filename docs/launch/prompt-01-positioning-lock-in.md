# Prompt 1: Positioning lock-in

**Purpose:** Produce the hero tagline, three checkable differentiators, who-it's-for / who-it's-NOT-for blocks, non-affiliation disclaimer, and the 100-char About field — the foundation every other prompt builds on.

**Writes to:** Saved to docs/positioning.md. Hero + disclaimer go straight into README.md (Prompt 2 consumes them). About field pasted into GitHub repo settings. Who-is/isn't blocks reused in Show HN first comment (Prompt 5).

---

## The prompt (paste into Claude/ChatGPT)

```
You are a technical copywriter for OSS developer tools. I'm launching Claude Launcher — a Windows Electron app that runs multiple Claude Desktop accounts side-by-side using the --user-data-dir Chromium flag.

Context:
- Platform: Windows only (portable installer; MSIX dormant)
- Mechanism: execs the official Claude Desktop binary with a per-profile --user-data-dir
- Not a client, not a proxy, not a wrapper — Anthropic's binary + Anthropic's OAuth
- MIT, no telemetry, no account rotation
- Audience: shared Max 20x households, dev+personal account jugglers, MCP/plugin testers
- Known competitors to differentiate against: TonF1917/claude-desktop-multiple-windows-different-api (978 stars, TOS-adjacent multi-API angle), Arman-Manteghi/Tandem (Windows, direct competitor), sypnose-cloud/claude-desktop-multi (PowerShell), RichardKPL/multi-claude (GPL-3 portable)
- The Feb 2026 Anthropic policy that killed OpenClaw/Cline banned third-party harnesses using OAuth tokens outside the official app. Claude Launcher is structurally NOT that — it just runs Claude.exe with a documented flag.

Produce:
1. A 2-sentence hero: pain-hook sentence (≤15 words) + mechanism sentence (≤30 words). Match the voice of Flow Launcher ("A quick file search and app launcher for Windows with community-made plugins"), Zen Browser, Ollama.
2. Three differentiator statements, each checkable in under 60 seconds (no "fast", "powerful", "seamless", "next-gen").
3. A "Who this is for" block (3 bullets covering: shared Max 20x household member, dev with work+personal accounts, MCP/connector testing) + a "Who this is NOT for" block (3 bullets explicitly rejecting: splitting one Max across multiple humans, auto-rotating accounts to dodge weekly caps, replacing the official app).
4. A one-sentence trademark/non-affiliation disclaimer in yt-dlp's tone — factual, no banner, no legal-fear framing.
5. GitHub About-field description, ≤100 chars, one leading emoji (model: Flow Launcher's :mag: pattern).

Hard constraints: no "revolutionary/powerful/blazing/seamless/next-generation", no claims the repo can't demo in 60 seconds, no mention of "different APIs" or "multi-API" (that's TonF1917's lane and carries real TOS risk).

Output each of the 5 items under a numbered heading. Plain prose; no commentary before or after.
```
