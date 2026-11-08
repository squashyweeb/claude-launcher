# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## [0.1.0]

Initial public release.

### Added

- Electron app with per-account cards, gradient avatars, live telemetry
  (RAM + uptime), status refresh every 2 seconds
- Add / Edit / Duplicate / Move / Remove accounts via UI + right-click
  context menu
- Keyboard-first interaction: digit shortcuts, Ctrl+Shift+A, Ctrl+L/W,
  F1 help, Esc dismiss
- Live avatar preview + 18-swatch color picker in the add dialog
- Dashed "+ Add account" empty-state tile
- `Who is signed in?` right-click action that decrypts the profile's
  OAuth tokens via DPAPI and queries `api.anthropic.com/api/oauth/profile`
- PowerShell + WPF fallback (`legacy/launcher.ps1`) that mirrors the
  Electron feature set for Node-less environments
- `profiles.example.json`, `prefs.example.json`, `config.example.json`
  reference files
- Full architecture + recovery docs under `docs/`
- MIT license
- CI pipeline (lint + PII sentinel scan + packager build)
- Release workflow that attaches a built Windows portable zip to tags
