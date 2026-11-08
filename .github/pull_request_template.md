<!--
Thanks for the PR. Please fill in the sections below.
Keep PRs focused: one feature or one fix per PR.
-->

## Summary

<!-- One or two sentences. What does this change do? -->

## Why

<!-- Link an issue if there is one. Otherwise, explain the motivation. -->

Closes #

## Testing

<!-- Describe what you ran and what you saw. -->

- [ ] Deleted my local `profiles.json` / `prefs.json` / `config.json`,
      ran `npm start`, saw the empty-state UI with no errors
- [ ] Launched + closed a test account via the UI
- [ ] If I touched the renderer, I opened DevTools (Ctrl+Shift+I) and
      saw no new errors or warnings
- [ ] If I touched `legacy/launcher.ps1`, I ran it on Windows and
      confirmed it still opens

## Security checklist

<!--
These checks protect you AND other contributors from accidentally
publishing a real account identifier. Please tick each box.
-->

- [ ] My diff does NOT contain my real email address
- [ ] My diff does NOT contain my real Anthropic account UUID or
      organization UUID
- [ ] My diff does NOT contain an OAuth access token
      (`sk-ant-oat01-...`) or refresh token (`sk-ant-ort01-...`)
- [ ] My diff does NOT contain the MSIX publisher-hash directory name
      from my machine (`claude_<hex>\`)
- [ ] My diff does NOT contain an absolute path that reveals my
      Windows username (`C:\Users\<me>\...`)
- [ ] I did NOT commit `profiles.json`, `prefs.json`, `config.json`,
      `node_modules/`, or `dist/`
- [ ] I ran `npm run check-pii` locally and it printed `[OK] no
      sentinel hits`
- [ ] If this PR touches anything related to tokens or network calls,
      I re-read [SECURITY.md](../SECURITY.md) and confirmed the change
      stays within scope

## Screenshots (optional)

<!--
If you include a screenshot, redact: tab names, title bar text, status
bar, and anything in the taskbar.
-->
