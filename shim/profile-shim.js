// SPDX-License-Identifier: MIT
// Copyright (c) 2026 claude-launcher contributors
//
// Profile shim for Claude Desktop (Electron). Intercepts the main
// process start-up, reads a --profile=NAME flag (or CLAUDE_PROFILE
// env var), and redirects Electron's userData + sessionData paths to
// %LOCALAPPDATA%\Claude-Data-Profiles\<NAME>\ before the real main
// runs. Then hands control to the original main.
//
// This file contains NO bytes from Anthropic's proprietary Claude
// Desktop. It is an original work.
//
// How it's wired up:
//   1) install.ps1 renames the installation's existing index.pre.js
//      to orig-index.pre.js
//   2) This file is dropped in as the new index.pre.js
//   3) The last line below does require('./orig-index.pre.js'), so
//      Claude Desktop still runs the real main; this just goes first.

'use strict';

const path = require('path');
const { app } = require('electron');

function readProfileName() {
  for (const arg of process.argv) {
    if (arg.startsWith('--profile=')) return arg.slice('--profile='.length).trim();
  }
  if (process.env.CLAUDE_PROFILE) return String(process.env.CLAUDE_PROFILE).trim();
  return null;
}

const profile = readProfileName();

if (profile && /^[A-Za-z0-9_\-]{1,40}$/.test(profile)) {
  const base = path.join(
    process.env.LOCALAPPDATA || app.getPath('appData'),
    'Claude-Data-Profiles',
    profile
  );
  app.setPath('userData', base);
  app.setPath('sessionData', base);

  // Give each profile its own AppUserModelId so Windows groups the
  // taskbar icons separately.
  try { app.setAppUserModelId('com.claude-launcher.profile.' + profile); } catch (_) {}

  // Pin a clean, RFC-7230-valid Chromium user-agent so Anthropic's
  // auth endpoints (notably magic-link email) do not reject the
  // request. Do NOT change app.setName here — the default Electron UA
  // derives from app.getName(), and anything with a space or paren
  // produces a UA Anthropic's WAF currently refuses.
  try {
    const v = app.getVersion();
    app.userAgentFallback =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
      'AppleWebKit/537.36 (KHTML, like Gecko) ' +
      'Claude/' + v + ' Chrome/136.0.7103.149 ' +
      'Electron/36.3.1 Safari/537.36';
  } catch (_) {}

  // Minimal breadcrumb in the main-process console for debugging.
  // Does not include any token value or user identifier.
  // eslint-disable-next-line no-console
  console.log('[claude-launcher shim] profile=' + profile + ' userData=' + base);
} else if (profile) {
  // eslint-disable-next-line no-console
  console.warn('[claude-launcher shim] ignoring invalid profile name: ' + JSON.stringify(profile));
}

// Hand off to the original Claude Desktop main. Must be require (sync),
// not import — Electron will finish booting as soon as this file
// returns.
require('./orig-index.pre.js');
