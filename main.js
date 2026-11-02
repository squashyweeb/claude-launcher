'use strict';

const { app, BrowserWindow, ipcMain, Menu, shell, dialog, globalShortcut, nativeImage } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn, execFile } = require('child_process');

// -----------------------------------------------------------------------------
// Config
// -----------------------------------------------------------------------------
const APP_DIR       = __dirname;
const LAUNCHER_DIR  = APP_DIR;
const PROFILES_FILE = path.join(LAUNCHER_DIR, 'profiles.json');
const PREFS_FILE    = path.join(LAUNCHER_DIR, 'prefs.json');
const CONFIG_FILE   = path.join(LAUNCHER_DIR, 'config.json');
const WHOIS_SCRIPT  = path.join(LAUNCHER_DIR, 'scripts', 'whois.py');

// First-run profiles: empty. Users add accounts via the UI (+ Add).
// See profiles.example.json for the shape of each entry.
const DEFAULT_PROFILES = [];

// Resolve Claude.exe. Order: config.json override -> CLAUDE_EXE env var ->
// known Windows install paths. If none found, UI shows a banner with a
// "Locate Claude.exe" picker that writes the choice to config.json.
function resolveClaudeExe() {
  try {
    if (fs.existsSync(CONFIG_FILE)) {
      const cfg = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
      if (cfg.exePath && fs.existsSync(cfg.exePath)) return cfg.exePath;
    }
  } catch (_) {}
  if (process.env.CLAUDE_EXE && fs.existsSync(process.env.CLAUDE_EXE)) return process.env.CLAUDE_EXE;
  const candidates = [
    path.join(process.env.LOCALAPPDATA || '', 'Programs', 'Claude', 'Claude.exe'),
    path.join(process.env.LOCALAPPDATA || '', 'Claude', 'Claude.exe'),
    'C:/Program Files/Claude/Claude.exe',
    'C:/Program Files (x86)/Claude/Claude.exe',
  ];
  for (const c of candidates) if (fs.existsSync(c)) return c;
  return null;
}

let EXE_PATH = resolveClaudeExe();

function saveExePath(p) {
  let cfg = {};
  try { if (fs.existsSync(CONFIG_FILE)) cfg = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')); } catch (_) {}
  cfg.exePath = p;
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2), 'utf8');
  EXE_PATH = p;
}

function loadJSON(file, fallback) {
  try { return JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch { return fallback; }
}
function saveJSON(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

function loadProfiles() {
  if (!fs.existsSync(PROFILES_FILE)) {
    saveJSON(PROFILES_FILE, DEFAULT_PROFILES);
    return DEFAULT_PROFILES.slice();
  }
  const raw = loadJSON(PROFILES_FILE, DEFAULT_PROFILES);
  return Array.isArray(raw) ? raw : DEFAULT_PROFILES.slice();
}

function saveProfiles(profiles) {
  saveJSON(PROFILES_FILE, profiles);
}

// -----------------------------------------------------------------------------
// Process query via PowerShell
// -----------------------------------------------------------------------------
function runPwsh(script, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const ps = execFile(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', script],
      { timeout: timeoutMs, windowsHide: true, maxBuffer: 10 * 1024 * 1024 },
      (err, stdout, stderr) => {
        if (err) return reject(new Error(stderr || err.message));
        resolve(stdout);
      }
    );
  });
}

async function getRunningMap() {
  const script = `
    $procs = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue
    $out = @()
    foreach ($p in $procs) {
      $out += [pscustomobject]@{
        Pid         = $p.ProcessId
        CommandLine = $p.CommandLine
        Memory      = [int64]$p.WorkingSetSize
        Started     = if ($p.CreationDate) { ([datetime]$p.CreationDate).ToUniversalTime().ToString('o') } else { $null }
      }
    }
    $out | ConvertTo-Json -Depth 3 -Compress
  `;
  let stdout;
  try { stdout = await runPwsh(script, 5000); }
  catch { return {}; }
  const trimmed = stdout.trim();
  if (!trimmed) return {};
  let list;
  try { list = JSON.parse(trimmed); } catch { return {}; }
  if (!Array.isArray(list)) list = [list];

  const map = {};
  for (const p of list) {
    const cl = p.CommandLine || '';
    let key;
    const udd = cl.match(/--user-data-dir=(?:"([^"]+)"|(\S+))/);
    const prof = cl.match(/--profile=([A-Za-z0-9_\-]+)/);
    if (udd) {
      key = (udd[1] || udd[2]).replace(/\\+$/, '').toLowerCase();
    } else if (prof) {
      key = path.join(process.env.LOCALAPPDATA, 'Claude-Data-Profiles', prof[1]).toLowerCase();
    } else {
      key = path.join(process.env.APPDATA, 'Claude').toLowerCase();
    }
    if (!map[key]) map[key] = { count: 0, memory: 0, oldest: null, pids: [] };
    map[key].count++;
    map[key].memory += p.Memory || 0;
    map[key].pids.push(p.Pid);
    if (p.Started) {
      const t = new Date(p.Started);
      if (!map[key].oldest || t < new Date(map[key].oldest)) map[key].oldest = p.Started;
    }
  }
  return map;
}

async function closeByDir(dir) {
  const target = dir.replace(/\\/g, '\\\\').toLowerCase();
  const script = `
    Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -and $_.CommandLine.ToLower().Contains('${target}') } |
      ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } catch {} }
  `;
  try { await runPwsh(script, 10000); } catch (_) {}
}

function launchByProfile(prof) {
  if (!EXE_PATH) throw new Error('Claude.exe not configured');
  const args = prof.Mode === 'profile'
    ? [`--profile=${path.basename(prof.Dir)}`]
    : [`--user-data-dir=${prof.Dir}`];
  const child = spawn(EXE_PATH, args, { detached: true, stdio: 'ignore', windowsHide: false });
  child.unref();
}

async function whois(dir) {
  if (!fs.existsSync(path.join(dir, 'config.json'))) {
    return { error: 'no config.json in that folder' };
  }
  return new Promise((resolve) => {
    execFile('python', [WHOIS_SCRIPT, dir], { timeout: 15000 }, (err, stdout, stderr) => {
      if (err) return resolve({ error: (stderr || err.message).trim() });
      const o = {};
      for (const ln of stdout.split('\n')) {
        const m = ln.match(/^(\w+):\s*(.+)$/);
        if (m) o[m[1]] = m[2].trim();
      }
      resolve({ data: o, raw: stdout });
    });
  });
}

// -----------------------------------------------------------------------------
// Window
// -----------------------------------------------------------------------------
let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 720,
    height: 760,
    minWidth: 560,
    minHeight: 500,
    show: false,
    backgroundColor: '#09090b',
    frame: false,
    titleBarStyle: 'hidden',
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      sandbox: false,
      nodeIntegration: false,
    },
  });
  mainWindow.loadFile(path.join(__dirname, 'index.html'));
  mainWindow.once('ready-to-show', () => mainWindow.show());
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// -----------------------------------------------------------------------------
// IPC
// -----------------------------------------------------------------------------
ipcMain.handle('profiles:load', () => loadProfiles());
ipcMain.handle('profiles:save', (_e, profiles) => { saveProfiles(profiles); return true; });

ipcMain.handle('prefs:load', () => loadJSON(PREFS_FILE, { hintsEnabled: true, hintIndex: 0, launchCounts: {} }));
ipcMain.handle('prefs:save', (_e, prefs) => { saveJSON(PREFS_FILE, prefs); return true; });

ipcMain.handle('running:get', () => getRunningMap());

ipcMain.handle('launch', (_e, prof) => { launchByProfile(prof); return true; });
ipcMain.handle('close', async (_e, dir) => { await closeByDir(dir); return true; });

ipcMain.handle('open-folder', (_e, dir) => shell.openPath(dir));

ipcMain.handle('whois', (_e, dir) => whois(dir));

ipcMain.handle('pick-folder', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openDirectory'],
    defaultPath: process.env.LOCALAPPDATA,
  });
  if (result.canceled || !result.filePaths.length) return null;
  return result.filePaths[0];
});

ipcMain.handle('exe-check', () => !!EXE_PATH && fs.existsSync(EXE_PATH));
ipcMain.handle('env:paths', () => ({
  localAppData: process.env.LOCALAPPDATA,
  appData: process.env.APPDATA,
  profilesBase: path.join(process.env.LOCALAPPDATA || '', 'Claude-Data-Profiles'),
  launcherDir: LAUNCHER_DIR,
  exePath: EXE_PATH || '',
  docsDir: path.join(LAUNCHER_DIR, 'docs'),
}));
ipcMain.handle('exe:pick', async () => {
  const r = await dialog.showOpenDialog(mainWindow, {
    title: 'Locate Claude.exe',
    filters: [{ name: 'Claude', extensions: ['exe'] }],
    properties: ['openFile'],
  });
  if (r.canceled || !r.filePaths.length) return null;
  saveExePath(r.filePaths[0]);
  return EXE_PATH;
});

ipcMain.handle('context-menu', (e, items, pos) => {
  const win = BrowserWindow.fromWebContents(e.sender);
  const menu = Menu.buildFromTemplate(items.map(it => {
    if (it.type === 'separator') return { type: 'separator' };
    return {
      label: it.label,
      enabled: it.enabled !== false,
      click: () => e.sender.send('context-menu:click', it.id),
    };
  }));
  menu.popup({ window: win });
  return true;
});

ipcMain.handle('window:minimize', () => mainWindow.minimize());
ipcMain.handle('window:close', () => mainWindow.close());
ipcMain.handle('window:toggle-max', () => {
  if (mainWindow.isMaximized()) mainWindow.unmaximize(); else mainWindow.maximize();
});

ipcMain.handle('message-box', async (_e, opts) => dialog.showMessageBox(mainWindow, opts));
