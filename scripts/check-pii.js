#!/usr/bin/env node
// Simple PII sentinel scanner. Run before every push.
// Scans the repo (excluding .git, node_modules, dist) for patterns that
// should never appear in a public commit.

'use strict';

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const SKIP_DIRS = new Set(['.git', 'node_modules', 'dist', 'out', 'build']);
// Also skip the scanner itself + its config, which contain the sentinel
// strings by definition.
const SKIP_FILES = new Set([
  path.join(REPO_ROOT, 'scripts', 'check-pii.js'),
  path.join(REPO_ROOT, 'scripts', 'check-pii.ps1'),
  path.join(REPO_ROOT, 'scripts', 'check-pii.sh'),
  path.join(REPO_ROOT, '.gitleaks.toml'),
  path.join(REPO_ROOT, 'CONTRIBUTING.md'),
  path.join(REPO_ROOT, 'SECURITY.md'),
  // Upstream dependency metadata (maintainer emails, SHA registry URLs).
  // Public info; not in-scope for user-PII scanning.
  path.join(REPO_ROOT, 'package-lock.json'),
  path.join(REPO_ROOT, 'yarn.lock'),
  path.join(REPO_ROOT, 'pnpm-lock.yaml'),
]);

const PATTERNS = [
  { name: 'anthropic-access-token', re: /sk-ant-oat01-[A-Za-z0-9_-]{30,}/ },
  { name: 'anthropic-refresh-token', re: /sk-ant-ort01-[A-Za-z0-9_-]{30,}/ },
  { name: 'anthropic-api-key', re: /sk-ant-api03-[A-Za-z0-9_-]{30,}/ },
  { name: 'generic-email', re: /\b[a-z0-9._%+-]+@(?!example\.com|users\.noreply\.github\.com)[a-z0-9.-]+\.[a-z]{2,}\b/i },
  { name: 'absolute-user-path', re: /[A-Z]:[\\/]Users[\\/](?!<[^>]+>|.{0,8}@|AppData[\\/])[A-Za-z][\w.-]{2,}/ },
  { name: 'uuid-nonzero', re: /\b(?!00000000-0000-0000-0000-)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/i },
];

const TEXT_EXT = new Set(['.md', '.js', '.mjs', '.cjs', '.ts', '.ps1', '.cmd', '.bat', '.sh', '.py', '.json', '.yaml', '.yml', '.toml', '.html', '.css', '.txt']);

let hits = 0;

function walk(dir) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      if (SKIP_DIRS.has(ent.name)) continue;
      walk(abs);
    } else if (ent.isFile()) {
      if (SKIP_FILES.has(abs)) continue;
      const ext = path.extname(ent.name).toLowerCase();
      if (!TEXT_EXT.has(ext)) continue;
      scan(abs);
    }
  }
}

function scan(file) {
  let txt;
  try { txt = fs.readFileSync(file, 'utf8'); } catch { return; }
  const lines = txt.split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    for (const p of PATTERNS) {
      const m = lines[i].match(p.re);
      if (m) {
        hits++;
        const rel = path.relative(REPO_ROOT, file);
        console.log(`[${p.name}] ${rel}:${i + 1}  ${m[0].slice(0, 80)}`);
      }
    }
  }
}

console.log('scanning', REPO_ROOT);
walk(REPO_ROOT);
console.log('');
if (hits === 0) {
  console.log('[OK] no sentinel hits');
  process.exit(0);
} else {
  console.log(`[FAIL] ${hits} sentinel hit(s)`);
  process.exit(1);
}
