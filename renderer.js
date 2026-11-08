'use strict';

const SWATCHES = [
  '#ef4444','#f97316','#f59e0b','#eab308','#84cc16',
  '#22c55e','#10b981','#14b8a6','#06b6d4','#0ea5e9',
  '#3b82f6','#6366f1','#8b5cf6','#a855f7','#d946ef',
  '#ec4899','#f43f5e','#64748b'
];

const HINTS = [
  'Press 1-9 to launch an account by its keycap number.',
  'Shift+1-9 closes an account. Ctrl+1-9 opens its folder.',
  'Right-click a card to Edit, Duplicate, Move or Remove it.',
  '"Who is signed in?" in the right-click menu runs whois.py and shows the live account identity.',
  'Ctrl+Shift+A adds an account. Ctrl+L launches all; Ctrl+W closes all.',
  'The dot: gray = not running, green = running.',
  'Running cards get an accent-colored border and show RAM + uptime.',
];

const state = {
  profiles: [],
  prefs: { hintsEnabled: true, hintIndex: 0, launchCounts: {} },
  running: {},
  env: { localAppData: '', appData: '', profilesBase: '', launcherDir: '', exePath: '', docsDir: '' },
  modal: null,
};

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------
function fmtBytes(b) {
  if (!b) return '';
  if (b < 1024) return `${b} B`;
  if (b < 1024*1024) return `${Math.round(b/1024)} KB`;
  if (b < 1024*1024*1024) return `${Math.round(b/(1024*1024))} MB`;
  return `${(b/(1024*1024*1024)).toFixed(1)} GB`;
}
function fmtUptime(iso) {
  if (!iso) return '';
  const ms = Date.now() - new Date(iso).getTime();
  const m = ms / 60000;
  if (m < 1) return '<1m';
  if (m < 60) return `${Math.round(m)}m`;
  const h = m / 60;
  if (h < 24) return `${h.toFixed(1)}h`;
  return `${(h/24).toFixed(1)}d`;
}
function fmtTime(d) {
  const p = (n) => n.toString().padStart(2, '0');
  return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
}
function keyFor(prof) { return (prof.Dir || '').replace(/\\+$/, '').toLowerCase(); }

function getInitials(name) {
  if (!name) return '?';
  const parts = name.trim().split(/\s+/);
  if (parts.length >= 2) return (parts[0][0] + parts[parts.length-1][0]).toUpperCase();
  return name.substring(0, Math.min(2, name.length)).toUpperCase();
}

function hashBytes(str) {
  // Lightweight non-crypto hash -> 8 bytes
  const bytes = new Uint8Array(8);
  let h1 = 0xdeadbeef, h2 = 0x41c6ce57;
  for (let i = 0; i < str.length; i++) {
    const ch = str.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  for (let i = 0; i < 4; i++) { bytes[i]     = (h1 >>> (i*8)) & 0xff; }
  for (let i = 0; i < 4; i++) { bytes[i + 4] = (h2 >>> (i*8)) & 0xff; }
  return bytes;
}

function gradientFor(seed, fallback) {
  if (!seed) return `linear-gradient(135deg, ${fallback}, ${fallback})`;
  const b = hashBytes(seed.toLowerCase());
  const h1 = Math.round((b[0] / 255) * 360);
  const h2 = (h1 + 30 + (b[1] % 90)) % 360;
  return `linear-gradient(135deg, hsl(${h1} 65% 52%), hsl(${h2} 65% 38%))`;
}

function escHtml(s) {
  return (s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

// -----------------------------------------------------------------------------
// Render
// -----------------------------------------------------------------------------
function renderCards() {
  const cardsEl = document.getElementById('cards');
  cardsEl.innerHTML = '';
  state.profiles.forEach((prof, idx) => cardsEl.appendChild(buildCard(prof, idx)));
  cardsEl.appendChild(buildAddTile());
}

function buildCard(prof, idx) {
  const card = document.createElement('div');
  card.className = 'card';
  card.tabIndex = 0;
  card.dataset.idx = idx;

  const gradient = gradientFor((prof.Email || '') + '|' + (prof.Id || ''), prof.Accent || '#3b82f6');
  const initials = getInitials(prof.Name);
  const keyCapHTML = idx < 9 ? `<span class="keycap">${idx + 1}</span>` : '';
  const planHTML = prof.Plan ? `<span class="plan-pill" style="background:${prof.Accent}">${escHtml(prof.Plan)}</span>` : '';

  card.innerHTML = `
    <div class="avatar" style="background:${gradient}">
      <span>${initials}</span>
      ${keyCapHTML}
    </div>
    <div class="card-info">
      <div class="card-head">
        <span class="card-name">${escHtml(prof.Name) || '(no name)'}</span>
        ${planHTML}
      </div>
      <div class="card-email" title="${escHtml(prof.Email || '')}">${escHtml(prof.Email || '')}</div>
      <div class="card-status">
        <span class="dot"></span>
        <span class="status-text">Not running</span>
      </div>
      <div class="card-telemetry"></div>
    </div>
    <div class="card-actions">
      <button class="icon-btn btn-folder" title="Open folder (Ctrl+${idx+1})">
        <svg viewBox="0 0 20 20" width="14" height="14">
          <path d="M3 5 L3 15 Q3 16 4 16 L16 16 Q17 16 17 15 L17 7 Q17 6 16 6 L10 6 L8 4 L4 4 Q3 4 3 5 Z"
                fill="none" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round"/>
        </svg>
      </button>
      <button class="ghost-btn btn-close" hidden>Close</button>
      <button class="primary-btn btn-launch" style="background:${prof.Accent}">Launch</button>
    </div>
  `;

  // Wire events
  card.querySelector('.btn-launch').onclick = () => doLaunch(idx);
  card.querySelector('.btn-close').onclick = () => doClose(idx);
  card.querySelector('.btn-folder').onclick = () => window.api.openFolder(prof.Dir);
  card.oncontextmenu = (e) => { e.preventDefault(); showCardMenu(idx); };

  updateCardStatus(card, prof);
  return card;
}

function updateCardStatus(card, prof) {
  const info = state.running[keyFor(prof)];
  const dot = card.querySelector('.dot');
  const statusText = card.querySelector('.status-text');
  const tele = card.querySelector('.card-telemetry');
  const closeBtn = card.querySelector('.btn-close');
  const launchBtn = card.querySelector('.btn-launch');

  if (info) {
    card.classList.add('running');
    card.style.borderColor = prof.Accent;
    const w = info.count === 1 ? 'process' : 'processes';
    statusText.textContent = `Running  ${info.count} ${w}`;
    statusText.style.color = 'var(--running)';
    const t = [];
    if (info.memory) t.push(fmtBytes(info.memory));
    if (info.oldest) t.push(`up ${fmtUptime(info.oldest)}`);
    tele.textContent = t.join('  |  ');
    closeBtn.hidden = false;
    launchBtn.textContent = '+ New window';
  } else {
    card.classList.remove('running');
    card.style.borderColor = '';
    statusText.textContent = 'Not running';
    statusText.style.color = '';
    tele.textContent = '';
    closeBtn.hidden = true;
    launchBtn.textContent = 'Launch';
  }
}

function buildAddTile() {
  const el = document.createElement('div');
  el.className = 'add-tile';
  el.innerHTML = `<span class="plus">+</span>Add account<kbd>Ctrl+Shift+A</kbd>`;
  el.onclick = () => openModal(null);
  return el;
}

function updateAllCardStatus() {
  const cards = document.querySelectorAll('.card');
  cards.forEach((card, i) => {
    if (state.profiles[i]) updateCardStatus(card, state.profiles[i]);
  });
  // Summary + status bar
  const live = state.profiles.filter(p => state.running[keyFor(p)]).length;
  const windows = Object.values(state.running).reduce((n, v) => n + v.count, 0);
  document.getElementById('summary').textContent = `${live} of ${state.profiles.length} live`;
  document.getElementById('foot-status').textContent =
    `${windows} windows total   |   auto-refresh 2s   |   updated ${fmtTime(new Date())}`;
}

// -----------------------------------------------------------------------------
// Actions
// -----------------------------------------------------------------------------
async function doLaunch(idx) {
  const p = state.profiles[idx];
  if (!p) return;
  const card = document.querySelector(`.card[data-idx="${idx}"]`);
  const btn = card && card.querySelector('.btn-launch');
  if (btn) btn.disabled = true;
  try {
    const result = await window.api.launch(p);
    if (result && result.ok === false) {
      window.api.messageBox({ type: 'error', title: 'Launch failed',
        message: `Could not launch ${p.Name}`, detail: result.error || 'unknown error' });
    }
    state.prefs.launchCounts = state.prefs.launchCounts || {};
    state.prefs.launchCounts[p.Id] = (state.prefs.launchCounts[p.Id] || 0) + 1;
    window.api.savePrefs(state.prefs);
  } finally {
    if (btn) btn.disabled = false;
    setTimeout(refresh, 500);
  }
}
async function doClose(idx) {
  const p = state.profiles[idx];
  if (!p) return;
  const card = document.querySelector(`.card[data-idx="${idx}"]`);
  const btn = card && card.querySelector('.btn-close');
  if (btn) btn.disabled = true;
  try {
    await window.api.close(p.Dir);
  } finally {
    if (btn) btn.disabled = false;
    setTimeout(refresh, 400);
  }
}

let refreshSeq = 0;
async function refresh() {
  const mine = ++refreshSeq;
  let next;
  try { next = await window.api.getRunning(); }
  catch (e) {
    // Keep the previous snapshot instead of strobing every card to
    // "Not running" when WMI stalls under load.
    console.warn('getRunning failed, keeping stale state:', e && e.message);
    return;
  }
  // Drop stale responses: an older in-flight refresh must not overwrite
  // a newer one that already landed.
  if (mine !== refreshSeq) return;
  if (next && typeof next === 'object') {
    state.running = next;
    updateAllCardStatus();
  }
}

// -----------------------------------------------------------------------------
// Context menu
// -----------------------------------------------------------------------------
let menuCallback = null;
window.api.onContextClick((id) => { if (menuCallback) menuCallback(id); });

function showCardMenu(idx) {
  const items = [
    { id: 'edit', label: 'Edit...' },
    { id: 'dup',  label: 'Duplicate' },
    { id: 'up',   label: 'Move up',   enabled: idx > 0 },
    { id: 'down', label: 'Move down', enabled: idx < state.profiles.length - 1 },
    { type: 'separator' },
    { id: 'whois',   label: 'Who is signed in?' },
    { id: 'folder',  label: 'Open folder' },
    { type: 'separator' },
    { id: 'remove',  label: 'Remove' },
  ];
  menuCallback = async (id) => {
    menuCallback = null;
    switch (id) {
      case 'edit':   openModal(state.profiles[idx]); break;
      case 'dup':    duplicateProfile(idx); break;
      case 'up':     moveProfile(idx, -1); break;
      case 'down':   moveProfile(idx,  1); break;
      case 'whois':  showWhois(idx); break;
      case 'folder': window.api.openFolder(state.profiles[idx].Dir); break;
      case 'remove': removeProfile(idx); break;
    }
  };
  window.api.contextMenu(items);
}

async function duplicateProfile(idx) {
  const src = state.profiles[idx];
  // Force the copy to be a NEW standalone profile dir, not a shared Dir
  // with the original. Otherwise Close on either kills both; and if the
  // user hits Cancel in the Edit modal, two cards silently share state.
  const copy = { ...src };
  const stamp = Math.floor(Math.random() * 9000 + 1000);
  copy.Id = `${src.Id || 'acct'}-copy-${stamp}`;
  copy.Name = `${src.Name} (copy)`;
  copy.Mode = 'profile';
  copy.Dir = `${state.env.profilesBase}\\${copy.Id}`;
  state.profiles.splice(idx + 1, 0, copy);
  await window.api.saveProfiles(state.profiles);
  renderCards();
  updateAllCardStatus();
  openModal(copy, idx + 1);
}

async function moveProfile(idx, dir) {
  const target = idx + dir;
  if (target < 0 || target >= state.profiles.length) return;
  const item = state.profiles.splice(idx, 1)[0];
  state.profiles.splice(target, 0, item);
  await window.api.saveProfiles(state.profiles);
  renderCards();
  updateAllCardStatus();
}

async function removeProfile(idx) {
  const p = state.profiles[idx];
  const result = await window.api.messageBox({
    type: 'warning',
    buttons: ['Remove', 'Cancel'],
    defaultId: 1,
    cancelId: 1,
    title: 'Remove account',
    message: `Remove "${p.Name}" from the launcher?`,
    detail: `This does NOT delete the profile folder on disk:\n${p.Dir}`,
  });
  if (result.response !== 0) return;
  state.profiles.splice(idx, 1);
  await window.api.saveProfiles(state.profiles);
  renderCards();
  updateAllCardStatus();
}

async function showWhois(idx) {
  const p = state.profiles[idx];
  const res = await window.api.whois(p.Dir);
  const detail = res.error ? `whois.py reported: ${res.error}` : res.raw;
  await window.api.messageBox({
    type: 'info',
    title: 'Who is signed in?',
    message: res.data?.email ? `${res.data.email}` : (res.error ? 'Lookup failed' : 'Decrypted'),
    detail,
  });
}

// -----------------------------------------------------------------------------
// Modal (Add / Edit)
// -----------------------------------------------------------------------------
function openModal(existing, replaceIdx = -1) {
  const isEdit = !!existing;
  const data = existing
    ? { ...existing }
    : {
        Id: `acct-${Math.floor(Math.random()*9000+1000)}`,
        Name: '', Email: '', Plan: 'Max',
        Accent: SWATCHES[Math.floor(Math.random()*SWATCHES.length)],
        Dir: '', Mode: 'profile',
      };
  state.modal = { data, isEdit, replaceIdx: isEdit ? state.profiles.indexOf(existing) : -1, keyTouched: false };

  document.getElementById('modal-title').textContent = isEdit ? 'Edit account' : 'Add account';
  document.getElementById('f-name').value = data.Name;
  document.getElementById('f-email').value = data.Email;
  document.getElementById('f-plan').value = data.Plan;
  document.getElementById('f-key').value  = data.Id;
  document.getElementById('f-dir').value  = data.Dir;
  document.getElementById('m-profile').checked = data.Mode === 'profile';
  document.getElementById('m-dir').checked     = data.Mode === 'user-data-dir';
  toggleModeFields();
  renderSwatches(data.Accent);
  document.getElementById('validation').textContent = '';
  document.getElementById('detect-msg').textContent = '';
  updateModalPreview();
  document.getElementById('modal-root').hidden = false;
  setTimeout(() => document.getElementById('f-name').focus(), 60);
}

function closeModal() {
  document.getElementById('modal-root').hidden = true;
  state.modal = null;
}

function renderSwatches(active) {
  const panel = document.getElementById('swatches');
  panel.innerHTML = '';
  for (const hex of SWATCHES) {
    const s = document.createElement('div');
    s.className = 'swatch' + (hex === active ? ' active' : '');
    s.style.background = hex;
    s.dataset.hex = hex;
    s.onclick = () => {
      state.modal.data.Accent = hex;
      renderSwatches(hex);
      updateModalPreview();
    };
    panel.appendChild(s);
  }
}

function toggleModeFields() {
  const prof = document.getElementById('m-profile').checked;
  document.getElementById('profile-field').hidden = !prof;
  document.getElementById('dir-field').hidden = prof;
}

function updateModalPreview() {
  const name  = document.getElementById('f-name').value;
  const email = document.getElementById('f-email').value;
  const plan  = document.getElementById('f-plan').value;
  const key   = document.getElementById('f-key').value;
  const d = state.modal.data;
  d.Name = name; d.Email = email; d.Plan = plan; d.Id = key || d.Id;

  const grad = gradientFor(email + '|' + d.Id, d.Accent);
  const av = document.getElementById('pv-avatar');
  av.style.background = grad;
  document.getElementById('pv-letter').textContent = getInitials(name);
  document.getElementById('pv-name').textContent = name || 'Preview';
  const subParts = [];
  if (email) subParts.push(email);
  if (plan)  subParts.push(plan);
  document.getElementById('pv-sub').textContent = subParts.length ? subParts.join('   ') : 'no email yet';

  const hint = document.getElementById('f-key-hint');
  if (key) hint.textContent = `becomes ${state.env.profilesBase}\\${key}`;
  else     hint.textContent = `becomes ${state.env.profilesBase}\\<key>`;
}

function slugify(name) {
  return (name || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

async function detectIdentity() {
  const dir = document.getElementById('f-dir').value.trim();
  if (!dir) { document.getElementById('detect-msg').textContent = 'Pick a folder first.'; return; }
  document.getElementById('detect-msg').textContent = 'Decrypting tokens...';
  const res = await window.api.whois(dir);
  if (res.error) {
    document.getElementById('detect-msg').textContent = 'whois.py failed: ' + res.error;
    return;
  }
  const d = res.data;
  if (d.email) document.getElementById('f-email').value = d.email;
  if (d.name)  document.getElementById('f-name').value  = d.name;
  if (d.plan) {
    const m = d.plan.match(/max_(\d+)x/);
    document.getElementById('f-plan').value = m ? `Max ${m[1]}x` : d.plan;
  }
  updateModalPreview();
  document.getElementById('detect-msg').textContent = 'Done.';
}

async function saveModal() {
  const d = state.modal.data;
  d.Name = document.getElementById('f-name').value.trim();
  d.Email = document.getElementById('f-email').value.trim();
  d.Plan = document.getElementById('f-plan').value.trim();
  d.Mode = document.getElementById('m-profile').checked ? 'profile' : 'user-data-dir';

  if (!d.Name) { document.getElementById('validation').textContent = 'Name is required.'; return; }
  if (d.Mode === 'profile') {
    const key = document.getElementById('f-key').value.trim();
    if (!/^[A-Za-z0-9_\-]{1,40}$/.test(key)) {
      document.getElementById('validation').textContent = 'Profile key must be 1-40 chars: letters, digits, _, -.';
      return;
    }
    d.Id = key;
    d.Dir = `${state.env.profilesBase}\\${key}`;
  } else {
    const dir = document.getElementById('f-dir').value.trim();
    if (!dir) { document.getElementById('validation').textContent = 'Folder required for attach mode.'; return; }
    d.Dir = dir;
  }

  // Reject duplicate Dir: two cards sharing a path means Close/status gets
  // attributed to the wrong card and Close on one kills the other.
  const dirKey = d.Dir.replace(/\\+$/, '').toLowerCase();
  const collision = state.profiles.findIndex((p, i) =>
    i !== state.modal.replaceIdx && (p.Dir || '').replace(/\\+$/, '').toLowerCase() === dirKey);
  if (collision !== -1) {
    document.getElementById('validation').textContent =
      `That folder is already used by "${state.profiles[collision].Name}". Pick a different key/folder.`;
    return;
  }

  if (state.modal.isEdit && state.modal.replaceIdx >= 0) {
    state.profiles[state.modal.replaceIdx] = d;
  } else {
    state.profiles.push(d);
  }
  await window.api.saveProfiles(state.profiles);
  renderCards();
  updateAllCardStatus();
  closeModal();
}

// -----------------------------------------------------------------------------
// Hint strip
// -----------------------------------------------------------------------------
// In-memory rotation only; no disk write every 10s.
let _hintCursor = 0;
function showNextHint() {
  if (!state.prefs.hintsEnabled) {
    document.getElementById('hint-strip').hidden = true;
    return;
  }
  document.getElementById('hint-text').textContent = HINTS[_hintCursor % HINTS.length];
  _hintCursor++;
}

// -----------------------------------------------------------------------------
// Keyboard
// -----------------------------------------------------------------------------
document.addEventListener('keydown', (e) => {
  const target = e.target;
  const inField = target.matches && (target.matches('input, textarea'));
  if (inField && e.key !== 'Escape') return;

  if (e.key === 'Escape') {
    if (!document.getElementById('modal-root').hidden) { closeModal(); e.preventDefault(); return; }
    if (!document.getElementById('help-modal').hidden) { document.getElementById('help-modal').hidden = true; e.preventDefault(); return; }
    // No modal open -> Esc closes the launcher (README promises this).
    window.api.window.close();
    e.preventDefault();
    return;
  }
  if (e.key === 'F1') { showHelp(); e.preventDefault(); return; }
  const ctrl  = e.ctrlKey;
  const shift = e.shiftKey;
  if (ctrl && shift && (e.key === 'A' || e.key === 'a')) { openModal(null); e.preventDefault(); return; }
  if (ctrl && (e.key === 'l' || e.key === 'L')) { launchAll(); e.preventDefault(); return; }
  if (ctrl && (e.key === 'w' || e.key === 'W')) { closeAll(); e.preventDefault(); return; }

  const digit = parseInt(e.key, 10);
  if (digit >= 1 && digit <= 9) {
    const idx = digit - 1;
    if (idx >= state.profiles.length) return;
    if (ctrl)       window.api.openFolder(state.profiles[idx].Dir);
    else if (shift) doClose(idx);
    else            doLaunch(idx);
    e.preventDefault();
  }
});

async function launchAll() {
  // Fire launches concurrently; each spawn is sub-50ms, no need to stagger.
  const results = await Promise.allSettled(
    state.profiles.map(p => window.api.launch(p).then(r => ({ p, r })))
  );
  for (const res of results) {
    if (res.status === 'fulfilled' && res.value.r && res.value.r.ok === false) {
      console.warn('launch failed for', res.value.p.Name, res.value.r.error);
    }
  }
  setTimeout(refresh, 500);
}

async function closeAll() {
  // Concurrent closes; closeByDir in main spawns its own PowerShell per call.
  await Promise.allSettled(state.profiles.map(p => window.api.close(p.Dir)));
  setTimeout(refresh, 400);
}

function showHelp() {
  document.getElementById('help-modal').hidden = false;
  document.getElementById('help-path').textContent = state.env.launcherDir + '\\profiles.json';
}

// -----------------------------------------------------------------------------
// Boot
// -----------------------------------------------------------------------------
async function boot() {
  state.env = await window.api.envPaths();
  state.profiles = await window.api.loadProfiles();
  state.prefs = await window.api.loadPrefs();
  if (!state.prefs.hintsEnabled) {
    document.getElementById('hint-strip').hidden = true;
  }

  if (!(await window.api.exeCheck())) {
    const b = document.getElementById('error-banner');
    b.hidden = false;
    document.getElementById('error-text').textContent = state.env.exePath;
  }

  renderCards();
  await refresh();
  showNextHint();

  // Self-scheduling chain: next tick starts AFTER the previous refresh
  // settles. Prevents pile-up when WMI stalls under AV / resume-from-sleep.
  (async function refreshLoop() {
    try { await refresh(); } finally { setTimeout(refreshLoop, 2000); }
  })();
  setInterval(showNextHint, 10000);

  // Launch-error listener (main.js emits via webContents.send when spawn errors)
  if (window.api.onLaunchError) {
    window.api.onLaunchError(({ dir, error }) => {
      const p = state.profiles.find(x => x.Dir === dir);
      window.api.messageBox({ type: 'error', title: 'Launch failed',
        message: p ? `Could not launch ${p.Name}` : 'Could not launch',
        detail: error });
    });
  }

  // Window chrome
  document.getElementById('tb-min').onclick = () => window.api.window.minimize();
  document.getElementById('tb-close').onclick = () => window.api.window.close();

  // Hero + footer
  document.getElementById('help-btn').onclick = showHelp;
  document.getElementById('launch-all').onclick = launchAll;
  document.getElementById('close-all').onclick = closeAll;
  document.getElementById('hint-dismiss').onclick = () => {
    state.prefs.hintsEnabled = false;
    window.api.savePrefs(state.prefs);
    document.getElementById('hint-strip').hidden = true;
  };

  // Modal
  document.getElementById('modal-cancel').onclick = closeModal;
  document.getElementById('modal-close').onclick = closeModal;
  document.getElementById('modal-backdrop').onclick = closeModal;
  document.getElementById('modal-save').onclick = saveModal;

  document.getElementById('f-name').addEventListener('input', (e) => {
    if (!state.modal) return;
    if (!state.modal.keyTouched) {
      document.getElementById('f-key').value = slugify(e.target.value) || `acct-${Math.floor(Math.random()*9000+1000)}`;
    }
    updateModalPreview();
  });
  document.getElementById('f-email').addEventListener('input', updateModalPreview);
  document.getElementById('f-plan').addEventListener('input', updateModalPreview);
  document.getElementById('f-key').addEventListener('input', () => {
    if (state.modal) state.modal.keyTouched = true;
    updateModalPreview();
  });
  document.getElementById('m-profile').addEventListener('change', toggleModeFields);
  document.getElementById('m-dir').addEventListener('change', toggleModeFields);
  document.getElementById('browse-btn').addEventListener('click', async () => {
    const path = await window.api.pickFolder();
    if (path) document.getElementById('f-dir').value = path;
  });
  document.getElementById('detect-btn').addEventListener('click', detectIdentity);

  // Help modal close handlers
  document.querySelectorAll('#help-modal [data-close]').forEach(el => {
    el.onclick = () => { document.getElementById('help-modal').hidden = true; };
  });
}

boot().catch(console.error);
