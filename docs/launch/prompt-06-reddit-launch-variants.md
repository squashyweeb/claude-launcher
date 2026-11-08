# Prompt 6: Reddit launch variants

**Purpose:** Four subreddit-tuned posts (r/ClaudeAI, r/opensource, r/windows, r/selfhosted) with correct flair, culture match, and native-image embedding — scheduled at 30-min intervals from T+30 min onward so none trips Reddit's cross-posting spam filter.

**Writes to:** docs/launch/reddit-posts.md (archived); pasted into each subreddit at T+30 / T+60 / T+90 / T+120 minutes.

---

## The prompt (paste into Claude/ChatGPT)

```
You are writing Reddit launch posts for Claude Launcher — one per subreddit, each tuned to that sub's culture and rules. Posting cadence: 30-minute intervals starting T+30 after the HN submission.

For EACH of the 4 subs below, produce a full post with (a) title, (b) body, (c) required flair, (d) note on which hero image to embed natively, (e) the "author reply within 10 min" comment.

1. r/ClaudeAI (~1M members) — flair: "Built with Claude". Format: what / how / screenshots / one actual Claude prompt I used while building Launcher. Audience: Claude users, many non-developers. Lead with the user-facing win, not the architecture. Rule: don't post download links in a top-level comment — put GitHub link inline in the post body.

2. r/opensource (~400K members) — flair: "Promotional" (required for "I made X" posts). Audience: OSS enthusiasts. Lead with MIT + Windows + no-telemetry + honest-mechanism angle. Mention Arman-Manteghi/Tandem by name and explain the differentiator (shim architecture + portable). Include "Source: {{link}}" at the bottom.

3. r/windows (~500K members) — no special flair but mods remove anything that reads as marketing. Lead with the concrete Windows pain (sign-out dance between Max 20x accounts). Include a screenshot in the post. Avoid the word "launch" in the title (triggers automod spam filter). Body ≤80 words.

4. r/selfhosted (~400K members) — flair: "Software". Audience will ask "why not just two Windows users?" — lead with that answer. Include a brief note that per-profile MCP server configs are isolated (selfhosters love isolated config).

Rules across all 4:
- No marketing adjectives ("powerful", "seamless", "blazing")
- Each post embeds the hero GIF or a static shot NATIVELY (Reddit upload, not external link)
- Each post ends with a "What would you want added?" question to drive comments
- Author posts a first comment within 10 min saying "Builder here — AMA"
- 30-min gap between each subreddit's post to avoid cross-post spam detection

Output: 4 fully-formatted posts in clear blocks. Include the first-comment AMA text for each.
```
