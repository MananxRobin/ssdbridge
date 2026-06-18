
/* ============================================
   SSDBridge — Guest Client
   Version: 5.0 (Advanced Features)
   ============================================ */

const ICONS = {
  logo: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/></svg>`,
  folder: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>`,
  file: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><polyline points="13 2 13 9 20 9"/></svg>`,
  image: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>`,
  video: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2"/></svg>`,
  music: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>`,
  home: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>`,
  upload: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>`,
  download: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>`,
  trash: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>`,
  plus: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  chevronRight: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><polyline points="9 18 15 12 9 6"/></svg>`,
  lock: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>`,
  grid: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>`,
  list: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>`,
  menu: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/></svg>`,
  shield: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>`,
  search: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>`,
  moon: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`,
  sun: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>`,
  rename: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"/></svg>`
};

const IMAGE_EXTS = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'ico'];

// Minimal QR code SVG generator (byte mode, Version 2, ECC M — handles up to ~28 chars).
// For longer URLs, falls back to the QR Server API.
function generateQRSVG(text, size) {
  if (text.length > 28) {
    return `<img src="https://api.qrserver.com/v1/create-qr-code/?size=${size}x${size}&data=${encodeURIComponent(text)}" width="${size}" height="${size}" alt="QR Code" style="display:block">`;
  }

  // Version 2: 25x25 modules
  const N = 25;
  const matrix = Array.from({length: N}, () => new Uint8Array(N));

  // Pre-computed finder patterns (top-left, top-right, bottom-left)
  function placeFinder(r, c) {
    for (let i = -1; i <= 7; i++)
      for (let j = -1; j <= 7; j++) {
        const rr = r + i, cc = c + j;
        if (rr >= 0 && rr < N && cc >= 0 && cc < N)
          matrix[rr][cc] = (i >= 0 && i <= 6 && j >= 0 && j <= 6 && (i === 0 || i === 6 || j === 0 || j === 6 || (i >= 2 && i <= 4 && j >= 2 && j <= 4))) ? 1 : 0;
      }
  }
  placeFinder(0, 0); placeFinder(0, N - 7); placeFinder(N - 7, 0);

  // Timing patterns
  for (let i = 8; i < N - 8; i++) matrix[6][i] = matrix[i][6] = (i % 2 === 0) ? 1 : 0;

  // Encode data: byte mode
  const bits = [];
  // Mode indicator: 0100 (byte)
  bits.push(0,1,0,0);
  // Count indicator: 8 bits for version 1-9
  const len = text.length;
  for (let i = 7; i >= 0; i--) bits.push((len >> i) & 1);
  // Data bytes
  for (let i = 0; i < len; i++) {
    const b = text.charCodeAt(i);
    for (let j = 7; j >= 0; j--) bits.push((b >> j) & 1);
  }
  // Terminator (up to 4 bits)
  const termLen = Math.min(4, 28 * 8 - len * 8 - 4 - 8);
  for (let i = 0; i < termLen; i++) bits.push(0);
  // Pad to 8-bit boundary
  while (bits.length % 8 !== 0) bits.push(0);
  // Pad bytes: 11101100, 00010001 alternating
  const padBytes = [0xEC, 0x11];
  let pi = 0;
  while (bits.length < 28 * 8) { const b = padBytes[pi % 2]; pi++; for (let j = 7; j >= 0; j--) bits.push((b >> j) & 1); }

  // Place data bits in zigzag (right-to-left, upward then downward)
  let bi = 0, col = N - 1, up = true;
  while (col >= 0) {
    if (col === 6) col--; // Skip vertical timing pattern column
    const rows = up ? [N - 1, -1, -1] : [0, N, 1];
    for (let r = rows[0]; r !== rows[1]; r += rows[2]) {
      for (let cOff = 0; cOff < 2; cOff++) {
        const c = col - cOff;
        if (c >= 0 && matrix[r][c] === 0 && bi < bits.length) { matrix[r][c] = bits[bi] ? 2 : 3; bi++; }
      }
    }
    col -= 2; up = !up;
  }

  // Render SVG (module 2 = dark, 3 = light; 0 = finder dark, 1 = finder light)
  const modSize = size / N;
  let svg = `<svg viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}"><rect width="${size}" height="${size}" fill="white"/>`;
  for (let r = 0; r < N; r++)
    for (let c = 0; c < N; c++) {
      const v = matrix[r][c];
      if (v === 0 || v === 2) svg += `<rect x="${(c*modSize).toFixed(1)}" y="${(r*modSize).toFixed(1)}" width="${modSize.toFixed(1)}" height="${modSize.toFixed(1)}"/>`;
    }
  svg += '</svg>';
  return svg;
}

const state = {
  view: 'init',
  sessionId: null,
  scopePath: '',
  permissions: 'read',
  currentPath: '',
  items: [],
  loading: false,
  error: null,
  joinError: null,
  selectedPaths: new Set(),
  viewMode: 'list',     // 'list' | 'gallery'
  sidebarOpen: false,
  filterText: '',
  pagination: { offset: 0, limit: 100, total: 0, hasMore: false },
  loadingMore: false,
  sortField: 'name',
  sortDir: 'asc',
  lastClickedIndex: null,
  recentFiles: [],
  encrypted: false,
  encryptionKey: null,   // CryptoKey for AES-GCM
  presence: { count: 0, viewers: [] },
  activityFeed: [],
  wormholeActive: false,
  wormholeFilename: null
};

// Upload progress tracking
const uploads = {
  active: [],           // [{name, progress, done}]
  visible: false
};

let ws = null;
let wsReconnectTimer = null;
let wsReconnectDelay = 1000;

// ============================================
//  INIT
// ============================================

async function init() {
  const stored = sessionStorage.getItem('ssdb_session');
  if (stored) {
    try {
      const s = JSON.parse(stored);
      state.sessionId = s.sessionId;
      state.scopePath = s.scopePath;
      state.permissions = s.permissions;
      if (s.encrypted) state.encrypted = true;
    } catch (e) {
      console.error(e);
    }
  }

  // MUST await — key must be ready before any upload or download
  await parseEncryptionKey();

  const path = window.location.pathname;
  if (path.startsWith('/join/')) {
    state.view = 'join';
    render();
  } else if (state.sessionId) {
    state.view = 'browse';
    loadFiles();
    connectWebSocket();

    // Check for interrupted uploads
    const pendingUpload = hasPendingUpload();
    if (pendingUpload && Date.now() - pendingUpload.ts < 86400000) {
      setTimeout(() => showResumeToast(pendingUpload), 1000);
    }
  } else {
    state.view = 'join';
    state.joinError = 'Link required to access files';
    render();
  }

  // Global keyboard shortcuts
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const modal = document.querySelector('.modal-overlay');
      if (modal) closeModal();
      const confirmEl = document.querySelector('.confirm-overlay');
      if (confirmEl) confirmEl.remove();
    }
    // Backspace or Cmd+ArrowUp = go to parent directory
    if (state.view === 'browse' && state.currentPath) {
      const target = e.target;
      const isInput = target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable;
      if (!isInput && (e.key === 'Backspace' || (e.metaKey && e.key === 'ArrowUp'))) {
        e.preventDefault();
        goUp();
      }
    }
  });

  // Mobile swipe-to-close sidebar
  let touchStartX = 0;
  document.addEventListener('touchstart', (e) => {
    if (state.sidebarOpen) touchStartX = e.touches[0].clientX;
  }, { passive: true });
  document.addEventListener('touchmove', (e) => {
    if (state.sidebarOpen && touchStartX - e.touches[0].clientX > 60) closeSidebar();
  }, { passive: true });
}

// ============================================
//  E2E ENCRYPTION
// ============================================

async function parseEncryptionKey() {
  const hash = window.location.hash;
  if (!hash) return;
  const match = hash.match(/key=([A-Za-z0-9_-]+)/);
  if (!match) return;

  state.encrypted = true;
  const keyBase64 = match[1]
    .replace(/-/g, '+')
    .replace(/_/g, '/');
  // Pad base64
  const padded = keyBase64 + '='.repeat((4 - keyBase64.length % 4) % 4);
  const keyBytes = Uint8Array.from(atob(padded), c => c.charCodeAt(0));

  try {
    state.encryptionKey = await crypto.subtle.importKey(
      'raw', keyBytes, { name: 'AES-GCM' }, false, ['encrypt', 'decrypt']
    );
    console.log('🔐 E2E encryption key loaded — uploads and downloads will be encrypted/decrypted');
  } catch (e) {
    console.error('Failed to import encryption key:', e);
    state.encrypted = false;  // don't try to encrypt/decrypt with broken key
  }
}

async function encryptData(data) {
  if (!state.encryptionKey) return data;
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv }, state.encryptionKey, data
  );
  // Prepend IV to ciphertext
  const result = new Uint8Array(iv.length + encrypted.byteLength);
  result.set(iv);
  result.set(new Uint8Array(encrypted), iv.length);
  return result.buffer;
}

async function decryptData(data) {
  if (!state.encryptionKey) return data;
  const buf = new Uint8Array(data);
  if (buf.length < 13) {
    throw new Error('Data too short to be encrypted — may not be an encrypted file');
  }
  const iv = buf.slice(0, 12);
  const ciphertext = buf.slice(12);
  return crypto.subtle.decrypt(
    { name: 'AES-GCM', iv }, state.encryptionKey, ciphertext
  );
}

// ============================================
//  API & SESSION
// ============================================

async function api(method, endpoint, body) {
  const headers = { 'Content-Type': 'application/json' };
  if (state.sessionId) headers.Authorization = `Bearer ${state.sessionId}`;

  const request = { method, headers };
  if (body !== undefined) request.body = JSON.stringify(body);

  const res = await fetch(`/api${endpoint}`, request);
  if (!res.ok) {
    if (res.status === 401 && state.sessionId) {
      sessionStorage.removeItem('ssdb_session');
      state.sessionId = null;
      state.view = 'join';
      state.joinError = 'Session expired. Please use a new link to reconnect.';
      render();
      throw new Error('Session expired');
    }
    const err = await res.json().catch(() => ({ reason: res.statusText }));
    throw new Error(err.reason || res.statusText);
  }
  return res.json();
}

function leaveSession() {
  sessionStorage.removeItem('ssdb_session');
  state.sessionId = null;
  state.scopePath = '';
  state.currentPath = '';
  state.items = [];
  state.selectedPaths.clear();
  state.view = 'join';
  state.joinError = null;
  if (ws) { ws.close(); ws = null; }
  clearTimeout(wsReconnectTimer);
  render();
}

async function joinSession(password = null) {
  const token = window.location.pathname.split('/').pop();
  try {
    const data = await api('POST', `/join/${token}`, { password });
    state.sessionId = data.sessionId;
    state.scopePath = data.scopePath;
    state.permissions = data.permissions;
    sessionStorage.setItem('ssdb_session', JSON.stringify({
      sessionId: state.sessionId,
      scopePath: state.scopePath,
      permissions: state.permissions,
      encrypted: state.encrypted
    }));

    history.replaceState(null, '', '/browse');
    state.view = 'browse';
    loadFiles();
    connectWebSocket();
  } catch (e) {
    state.joinError = e.message;
    render();
  }
}

// ============================================
//  WEBSOCKET — REAL-TIME SYNC
// ============================================

function connectWebSocket() {
  if (!state.sessionId) return;
  if (ws && ws.readyState <= 1) return; // already connected or connecting

  const proto = location.protocol === 'https:' ? 'wss' : 'ws';
  ws = new WebSocket(`${proto}://${location.host}/ws?token=${state.sessionId}`);

  ws.onopen = () => {
    console.log('🔌 WebSocket connected');
    wsReconnectDelay = 1000;
  };

  ws.onmessage = (e) => {
    try {
      const msg = JSON.parse(e.data);
      switch (msg.type) {
        case 'refresh':
          loadFiles(true); // silent refresh
          break;
        case 'presence':
          state.presence = { count: msg.count || 0, viewers: msg.viewers || [] };
          render();
          break;
        case 'activity':
          state.activityFeed.unshift(msg);
          if (state.activityFeed.length > 8) state.activityFeed.pop();
          showActivityToast(msg);
          if (msg.action === 'joined' || msg.action === 'left') render();
          break;
        case 'beam':
          handleBeam(msg);
          break;
      }
    } catch (err) {
      console.error('WS message error:', err);
    }
  };

  ws.onclose = () => {
    console.log('🔌 WebSocket disconnected, reconnecting...');
    clearTimeout(wsReconnectTimer);
    wsReconnectTimer = setTimeout(() => {
      wsReconnectDelay = Math.min(wsReconnectDelay * 2, 30000);
      connectWebSocket();
    }, wsReconnectDelay);
  };

  ws.onerror = () => {
    ws.close();
  };
}

// ============================================
//  FILE OPERATIONS
// ============================================

async function loadFiles(silent = false, append = false) {
  if (!silent) {
    state.loading = true;
    state.error = null;
    render();
  }

  try {
    const p = state.pagination;
    const path = state.currentPath ? `/files/${state.currentPath}` : '/files/';
    const data = await api('GET', `${path}?offset=${p.offset}&limit=${p.limit}`);
    const newItems = data.items || [];
    state.items = append ? [...state.items, ...newItems] : newItems;
    sortItems();
    state.pagination.total = data.totalItems || newItems.length;
    state.pagination.hasMore = data.hasMore || false;
    if (!silent) { state.selectedPaths.clear(); state.lastClickedIndex = null; }
  } catch (e) {
    state.error = e.message;
  } finally {
    state.loading = false;
    render();
  }
}

function loadMore() {
  state.loadingMore = true;
  render();
  state.pagination.offset += state.pagination.limit;
  loadFiles(true, true).finally(() => {
    state.loadingMore = false;
    render();
  });
}

function sortItems() {
  const { sortField, sortDir } = state;
  state.items.sort((a, b) => {
    if (a.type !== b.type) return a.type === 'directory' ? -1 : 1;
    let cmp = 0;
    if (sortField === 'name') {
      cmp = a.name.localeCompare(b.name);
    } else if (sortField === 'size' && a.type === 'file' && b.type === 'file') {
      cmp = (a.size || 0) - (b.size || 0);
    } else if (sortField === 'modified') {
      cmp = (a.modified || '').localeCompare(b.modified || '');
    }
    return sortDir === 'asc' ? cmp : -cmp;
  });
  // Reset selection index after sort
  state.lastClickedIndex = null;
}

function toggleSort(field) {
  if (state.sortField === field) {
    state.sortDir = state.sortDir === 'asc' ? 'desc' : 'asc';
  } else {
    state.sortField = field;
    state.sortDir = 'asc';
  }
  sortItems();
  render();
}

async function loadRecent() {
  state.view = 'recent';
  state.loading = true;
  render();
  try {
    const data = await api('GET', '/recent');
    state.recentFiles = data.files || [];
  } catch (e) {
    state.error = e.message;
  } finally {
    state.loading = false;
    render();
  }
}

function sendViewing(path) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type: 'viewing', path: path || state.currentPath || '/' }));
  }
}

function navigate(path) {
  state.view = 'browse';
  state.currentPath = path;
  state.pagination.offset = 0;
  state.selectedPaths.clear();
  loadFiles();
  sendViewing(path || '/');
}

function goUp() {
  if (!state.currentPath) return;
  const parts = state.currentPath.split('/');
  parts.pop();
  navigate(parts.join('/'));
}

// ============================================
//  UPLOAD WITH PROGRESS (CHUNKED FOR LARGE FILES)
// ============================================

const CHUNK_SIZE = 10 * 1024 * 1024;  // 10 MB
const CHUNKED_THRESHOLD = 50 * 1024 * 1024;  // 50 MB
const MAX_CHUNK_RETRIES = 3;

function triggerUpload() {
  const input = document.getElementById('upload-input');
  if (input) input.click();
}

function triggerDirUpload() {
  const input = document.getElementById('upload-dir-input');
  if (input) input.click();
}

async function handleUpload(files) {
  if (!files.length) return;
  uploads.visible = true;

  for (const file of files) {
    const isLarge = file.size > CHUNKED_THRESHOLD;
    const totalChunks = isLarge ? Math.ceil(file.size / CHUNK_SIZE) : 0;
    const entry = {
      name: file.name,
      progress: 0,
      done: false,
      error: false,
      chunked: isLarge,
      chunksTotal: totalChunks,
      chunksDone: 0,
      resuming: false,
      abortController: new AbortController(),
      uploadId: null
    };
    uploads.active.push(entry);
    renderUploadPanel();

    try {
      if (isLarge) {
        await chunkedUpload(file, entry);
      } else {
        let uploadData = file;
        if (state.encrypted && state.encryptionKey) {
          const buf = await file.arrayBuffer();
          const encBuf = await encryptData(buf);
          uploadData = new Blob([encBuf]);
        }
        await uploadWithProgress(uploadData, file.name, entry);
      }
      entry.done = true;
    } catch (e) {
      if (e.name === 'AbortError') { entry.done = true; }
      else {
        entry.error = true;
        console.error(`Upload failed: ${file.name}`, e);
        // If chunked upload got partial progress, offer resume
        if (entry.chunked && entry.uploadId && entry.chunksDone > 0 && !entry.assembling) {
          showResumeToast({ uploadId: entry.uploadId, filename: file.name, totalSize: file.size, totalChunks: entry.chunksTotal, ts: Date.now() });
        }
      }
    }
    renderUploadPanel();
  }

  // Auto-hide after 3s when all done
  setTimeout(() => {
    uploads.active = uploads.active.filter(u => !u.done && !u.error);
    if (uploads.active.length === 0) uploads.visible = false;
    renderUploadPanel();
  }, 3000);

  loadFiles();
}

// --- Chunked upload for large files ---

async function chunkedUpload(file, entry) {
  const totalChunks = Math.ceil(file.size / CHUNK_SIZE);

  // 1. Init session
  const initRes = await api('POST', '/chunked/init', {
    filename: file.name,
    totalSize: file.size,
    chunkSize: CHUNK_SIZE,
    totalChunks: totalChunks,
    targetPath: state.currentPath
  });
  const uploadId = initRes.uploadId;
  entry.uploadId = uploadId;

  // Save to sessionStorage for resume on page reload
  try { sessionStorage.setItem('ssdb-pending-upload', JSON.stringify({
    uploadId, filename: file.name, totalSize: file.size,
    totalChunks, targetPath: state.currentPath, ts: Date.now()
  })); } catch(e) {}

  // 2. Upload chunks with retry
  let completedChunks = new Set();
  for (let i = 0; i < totalChunks; i++) {
    entry.abortController.signal.throwIfAborted();
    await uploadChunkWithRetry(file, uploadId, i, entry, completedChunks);
    completedChunks.add(i);
    entry.chunksDone = completedChunks.size;
    entry.progress = Math.round((completedChunks.size / totalChunks) * 100);
    renderUploadPanel();
  }

  // 3. Finalize — server assembles chunks into the final file
  entry.progress = 99;
  entry.assembling = true;
  renderUploadPanel();
  await api('POST', `/chunked/complete/${uploadId}`);
  entry.assembling = false;
  try { sessionStorage.removeItem('ssdb-pending-upload'); } catch(e) {}
}

async function uploadChunkWithRetry(file, uploadId, index, entry, completedChunks) {
  const start = index * CHUNK_SIZE;
  const end = Math.min(start + CHUNK_SIZE, file.size);
  // NOTE: Chunked large files are NOT encrypted per-chunk.
  // Per-chunk AES-GCM produces multiple independent IV+ciphertext blocks that
  // cannot be reassembled and decrypted as a single stream.
  // Large files rely on HTTPS/TLS for transport security.
  // Full AES-GCM E2E encryption applies only to files < CHUNKED_THRESHOLD (50MB).
  const chunk = file.slice(start, end);

  for (let attempt = 0; attempt < MAX_CHUNK_RETRIES; attempt++) {
    try {
      const res = await fetch(`/api/chunked/upload/${uploadId}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${state.sessionId}`,
          'X-Chunk-Index': String(index),
          'Content-Type': 'application/octet-stream'
        },
        body: chunk,
        signal: entry.abortController.signal
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return; // success
    } catch (e) {
      console.warn(`Chunk ${index} attempt ${attempt + 1} failed:`, e.message);
      if (attempt === MAX_CHUNK_RETRIES - 1) {
        // Last retry — try to resume by checking server status
        entry.resuming = true;
        renderUploadPanel();
        try {
          const status = await api('GET', `/chunked/status/${uploadId}`);
          const received = new Set(status.receivedChunks);
          if (received.has(index)) return; // server got it anyway
        } catch (statusErr) {
          // ignore status check failure
        }
        throw e; // truly failed
      }
      // Wait before retry (exponential backoff)
      await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));
    }
  }
}

// --- Resume a failed chunked upload ---

async function resumeChunkedUpload(uploadId, file, entry) {
  entry.resuming = true;
  renderUploadPanel();

  const status = await api('GET', `/chunked/status/${uploadId}`);
  const received = new Set(status.receivedChunks);
  const totalChunks = status.totalChunks;

  for (let i = 0; i < totalChunks; i++) {
    if (received.has(i)) continue; // already uploaded
    await uploadChunkWithRetry(file, uploadId, i, entry, received);
    received.add(i);
    entry.chunksDone = received.size;
    entry.progress = Math.round((received.size / totalChunks) * 100);
    renderUploadPanel();
  }

  entry.resuming = false;
  await api('POST', `/chunked/complete/${uploadId}`);
}

// --- Simple upload for small files ---

function uploadWithProgress(data, filename, entry) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', `/api/upload/${state.currentPath}`);
    xhr.setRequestHeader('Authorization', `Bearer ${state.sessionId}`);
    xhr.setRequestHeader('X-Filename', filename);

    entry.abortController.signal.addEventListener('abort', () => xhr.abort());

    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable) {
        entry.progress = Math.round((e.loaded / e.total) * 100);
        renderUploadPanel();
      }
    };

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) resolve();
      else reject(new Error(`HTTP ${xhr.status}`));
    };
    xhr.onerror = () => reject(new Error('Network error'));
    xhr.onabort = () => reject(new DOMException('Upload cancelled', 'AbortError'));
    xhr.send(data);
  });
}

function renderUploadPanel() {
  let panel = document.getElementById('upload-progress-panel');
  if (!uploads.visible || uploads.active.length === 0) {
    if (panel) panel.remove();
    return;
  }

  if (!panel) {
    panel = document.createElement('div');
    panel.id = 'upload-progress-panel';
    document.body.appendChild(panel);
  }

  const isDownload = uploads.active.length > 0 && uploads.active[0].download;
  const label = isDownload ? 'Downloading' : 'Uploading';

  panel.innerHTML = `
    <div class="upload-panel-header">
      <strong>${label} ${uploads.active.length} file(s)</strong>
      <button class="btn btn-icon btn-ghost" onclick="closeUploadPanel()">✕</button>
    </div>
    ${uploads.active.map((u, i) => {
    const statusText = u.done ? '✓'
      : u.error ? '✕'
        : u.assembling ? '⚙'
          : u.resuming ? '⟳'
            : u.progress + '%';
    const subLabel = u.assembling ? 'Assembling...'
      : u.resuming ? 'Resuming...'
        : u.chunked && !u.done ? `${u.chunksDone}/${u.chunksTotal} chunks`
          : u.download && !u.done ? `${u.progress}% of ${u.name}`
            : '';
    return `
        <div class="upload-item ${u.assembling ? 'upload-assembling' : u.resuming ? 'upload-resuming' : ''}">
          <span class="upload-name">${u.name}</span>
          ${subLabel ? `<span class="upload-sublabel">${subLabel}</span>` : ''}
          <div class="upload-bar-bg">
            <div class="upload-bar" style="width:${u.progress}%"></div>
          </div>
          <span class="upload-pct">${statusText}</span>
          ${!u.done && !u.error ? `<button class="btn btn-icon btn-ghost" onclick="cancelTransfer(${i})" title="Cancel" style="width:24px;min-height:24px;font-size:12px;padding:0;line-height:1;flex-shrink:0">✕</button>` : ''}
        </div>
      `;
  }).join('')}
  `;
}

function closeUploadPanel() {
  for (const entry of uploads.active) {
    if (entry.abortController) entry.abortController.abort();
    if (entry.uploadId) fetch(`/api/chunked/${entry.uploadId}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${state.sessionId}` } }).catch(() => {});
  }
  uploads.active = [];
  uploads.visible = false;
  const panel = document.getElementById('upload-progress-panel');
  if (panel) panel.remove();
}

// ============================================
//  BEAM (Host → Guest file push)
// ============================================

async function handleBeam(msg) {
  const fname = msg.filename || 'a file';
  const size = msg.size ? formatBytes(msg.size) : '';
  const ok = await showConfirm(
    `The host is sending "${fname}"${size ? ' (' + size + ')' : ''} directly to you. Receive it?`,
    'Incoming Beam'
  );
  if (!ok) return;

  try {
    const url = msg.downloadUrl;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const blob = await res.blob();
    const blobUrl = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = blobUrl;
    a.download = fname;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(() => URL.revokeObjectURL(blobUrl), 10000);
    showToast(`"${fname}" received via beam`, 'success', 4000);
  } catch (e) {
    showToast('Beam failed: ' + e.message, 'error');
  }
}

// ============================================
//  WORMHOLE (Guest → Host file teleport)
// ============================================

function triggerWormhole() {
  state.wormholeActive = true;
  render();
  setTimeout(() => {
    const input = document.getElementById('wormhole-input');
    if (input) input.click();
  }, 100);
}

async function handleWormholeUpload(files) {
  if (!files.length) { state.wormholeActive = false; render(); return; }

  const file = files[0];
  state.wormholeFilename = file.name;
  state.wormholeActive = true;
  render();

  try {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', '/api/wormhole');
    xhr.setRequestHeader('Authorization', `Bearer ${state.sessionId}`);
    xhr.setRequestHeader('X-Filename', file.name);

    await new Promise((resolve, reject) => {
      xhr.onload = () => xhr.status >= 200 && xhr.status < 300 ? resolve() : reject(new Error(`HTTP ${xhr.status}`));
      xhr.onerror = () => reject(new Error('Network error'));
      xhr.send(file);
    });

    state.wormholeActive = false;
    state.wormholeFilename = null;
    showToast(`"${file.name}" arrived on host's desktop`, 'success', 4000);
    render();
  } catch (e) {
    state.wormholeActive = false;
    state.wormholeFilename = null;
    showToast('Wormhole failed: ' + e.message, 'error');
    render();
  }
}

// ============================================
//  ACTIVITY TOAST
// ============================================

function showActivityToast(msg) {
  const icons = {
    joined: ICONS.shield,
    left: '',
    downloaded: ICONS.download,
    wormhole: ICONS.upload,
    beamed: ICONS.upload
  };
  const labels = {
    joined: 'Someone joined the bridge',
    left: 'Someone left',
    downloaded: 'Downloaded',
    wormhole: 'Sent via wormhole',
    beamed: 'Beamed'
  };
  const icon = icons[msg.action] || '';
  const label = labels[msg.action] || msg.action;
  const detail = msg.detail ? ` ${escHtml(msg.detail)}` : '';
  const text = `${label}${detail}`;
  showToast(`${icon} ${text}`, msg.action === 'left' ? 'warning' : 'success', 3000);
}

function cancelTransfer(index) {
  const entry = uploads.active[index];
  if (!entry) return;
  if (entry.abortController) entry.abortController.abort();
  if (entry.uploadId) fetch(`/api/chunked/${entry.uploadId}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${state.sessionId}` } }).catch(() => {});
  uploads.active.splice(index, 1);
  if (uploads.active.length === 0) uploads.visible = false;
  renderUploadPanel();
}

// ============================================
//  UPLOAD RESUME
// ============================================

function hasPendingUpload() {
  try { return JSON.parse(sessionStorage.getItem('ssdb-pending-upload') || 'null'); }
  catch(e) { return null; }
}

function showResumeToast(pending) {
  showToast(`Interrupted upload: ${escHtml(pending.filename)} (${formatBytes(pending.totalSize)}) — re-select the file to resume.`, 'warning', 10000);
}

async function resumePendingUpload() {
  const pending = hasPendingUpload();
  if (!pending) return;
  if (Date.now() - pending.ts > 86400000) { try { sessionStorage.removeItem('ssdb-pending-upload'); } catch(e) {} return; }

  const input = document.createElement('input');
  input.type = 'file';
  input.onchange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size !== pending.totalSize) { showToast('File size does not match the interrupted upload.', 'error'); return; }

    // Check which chunks the server already has
    let completedChunks = new Set();
    try {
      const status = await api('GET', `/chunked/status/${pending.uploadId}`);
      completedChunks = new Set(status.receivedChunks);
    } catch (e) { showToast('Upload session expired. Please start a new upload.', 'error'); return; }

    uploads.visible = true;
    const entry = {
      name: file.name, progress: Math.round((completedChunks.size / pending.totalChunks) * 100),
      done: false, error: false, chunked: true,
      chunksTotal: pending.totalChunks, chunksDone: completedChunks.size,
      resuming: true, abortController: new AbortController(), uploadId: pending.uploadId
    };
    uploads.active.push(entry);
    renderUploadPanel();

    try {
      await resumeChunkedUpload(pending.uploadId, file, entry);
      entry.done = true;
      try { sessionStorage.removeItem('ssdb-pending-upload'); } catch(_) {}
      loadFiles();
    } catch (err) {
      if (err.name === 'AbortError') { entry.done = true; }
      else { entry.error = true; showToast('Resume failed: ' + err.message, 'error'); }
    }
    renderUploadPanel();
  };
  input.click();
}

// ============================================
//  FOLDER & DELETE
// ============================================

async function createFolder() {
  const name = await showPrompt('Enter a name for the new folder.', 'New folder');
  if (name) {
    try { await api('POST', `/mkdir/${state.currentPath}`, { name }); loadFiles(); }
    catch (e) { showToast(e.message, 'error'); }
  }
}

async function confirmDelete(path, fileName) {
  const name = fileName || path.split('/').pop();
  const ok = await showConfirm(`"${name}" will be permanently deleted. This cannot be undone.`, `Delete "${name}"?`, true);
  if (ok) {
    try { await api('DELETE', `/delete/${path}`); loadFiles(); }
    catch (e) { showToast('Delete failed: ' + e.message, 'error'); }
  }
}

async function renameItem(pathEncoded, nameEncoded) {
  const oldName = decodeURIComponent(nameEncoded);
  const newName = await showPrompt('Enter a new name.', 'Rename', oldName);
  if (newName && newName !== oldName) {
    try { await api('PUT', `/rename/${decodeURIComponent(pathEncoded)}`, { newName }); loadFiles(); }
    catch (e) { showToast('Rename failed: ' + e.message, 'error'); }
  }
}

// ============================================
//  MULTI-SELECT & BULK DOWNLOAD
// ============================================

function toggleSelect(path, event, fileIndex) {
  event.stopPropagation();
  const fileItems = state.items.filter(i => i.type === 'file');

  if (event.shiftKey && state.lastClickedIndex !== null && fileIndex !== undefined) {
    const start = Math.min(state.lastClickedIndex, fileIndex);
    const end = Math.max(state.lastClickedIndex, fileIndex);
    const adding = !state.selectedPaths.has(path);
    for (let i = start; i <= end; i++) {
      if (fileItems[i]) {
        if (adding) state.selectedPaths.add(fileItems[i].path);
        else state.selectedPaths.delete(fileItems[i].path);
      }
    }
    state.lastClickedIndex = fileIndex;
  } else {
    if (state.selectedPaths.has(path)) {
      state.selectedPaths.delete(path);
    } else {
      state.selectedPaths.add(path);
    }
    state.lastClickedIndex = fileIndex !== undefined ? fileIndex : null;
  }
  render();
}

function toggleSelectAll() {
  const fileItems = state.items.filter(i => i.type === 'file');
  if (state.selectedPaths.size === fileItems.length && fileItems.length > 0) {
    state.selectedPaths.clear();
  } else {
    fileItems.forEach(i => state.selectedPaths.add(i.path));
  }
  render();
}

async function bulkDownload() {
  if (state.selectedPaths.size === 0) return;
  const paths = Array.from(state.selectedPaths);

  try {
    const res = await fetch('/api/download-bulk', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${state.sessionId}`
      },
      body: JSON.stringify({ paths })
    });

    if (!res.ok) throw new Error('Bulk download failed');

    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `SSDBridge-${paths.length}-files.zip`;
    a.click();
    URL.revokeObjectURL(url);
    state.selectedPaths.clear();
    render();
  } catch (e) {
    showToast('Bulk download failed: ' + e.message, 'error');
  }
}

async function bulkDelete() {
  if (state.selectedPaths.size === 0) return;
  const ok = await showConfirm(`Delete ${state.selectedPaths.size} selected item(s)? This cannot be undone.`, 'Bulk delete', true);
  if (!ok) return;

  const paths = Array.from(state.selectedPaths);
  let failed = 0;
  for (const path of paths) {
    try {
      await api('DELETE', `/delete/${encode(path)}`);
    } catch (e) {
      failed++;
    }
  }
  if (failed) showToast(`${failed} item(s) failed to delete`, 'warning');
  state.selectedPaths.clear();
  loadFiles();
}

// ============================================
//  PREVIEW & DOWNLOAD
// ============================================

const LARGE_FILE_THRESHOLD = 100 * 1024 * 1024; // 100 MB — files above this use native/streaming download
const RESUME_KEY_PREFIX = 'ssdb-dl-';

function openItem(item) {
  if (item.type === 'directory') {
    navigate(item.path);
  } else {
    previewFile(item);
  }
}

async function downloadItem(item) {
  // E2E encrypted small files: use existing decrypt path
  const isSmallEncrypted = state.encrypted && state.encryptionKey
    && item.type === 'file'
    && typeof item.size === 'number'
    && item.size <= CHUNKED_THRESHOLD;

  if (isSmallEncrypted) { downloadEncrypted(item); return; }

  // Check for interrupted download that can be resumed
  const resumeState = getResumeState(item.path);
  if (resumeState && item.type === 'file' && 'showSaveFilePicker' in window) {
    const pct = resumeState.total ? Math.round(resumeState.bytes / resumeState.total * 100) : '?';
    const ok = await showConfirm(
      `Previous download of "${item.name}" was interrupted at ${formatBytes(resumeState.bytes)} (${pct}%). Resume?`,
      'Resume download'
    );
    if (!ok) clearResumeState(item.path);
  }

  const supportsFS = 'showSaveFilePicker' in window;
  const isLarge = !item.size || item.size > LARGE_FILE_THRESHOLD;

  if (supportsFS && item.type === 'file') {
    await streamingDownload(item);
  } else if (isLarge || item.type === 'directory') {
    legacyDownload(item);
  } else {
    await fetchDownloadWithProgress(item);
  }
}

// ============================================
//  RESUME STATE MANAGEMENT
// ============================================

function saveResumeState(path, bytesReceived, totalSize, downloadUrl) {
  try {
    localStorage.setItem(RESUME_KEY_PREFIX + path, JSON.stringify({
      bytes: bytesReceived, total: totalSize, url: downloadUrl, ts: Date.now()
    }));
  } catch (e) { /* localStorage full or unavailable */ }
}

function getResumeState(path) {
  try {
    const raw = localStorage.getItem(RESUME_KEY_PREFIX + path);
    if (!raw) return null;
    const state = JSON.parse(raw);
    if (Date.now() - state.ts > 86400000) { clearResumeState(path); return null; }
    return state;
  } catch (e) { return null; }
}

function clearResumeState(path) {
  try { localStorage.removeItem(RESUME_KEY_PREFIX + path); } catch (e) {}
}

// ============================================
//  TIER 1: STREAMING DOWNLOAD (File System Access API — Chromium)
// ============================================

async function streamingDownload(item) {
  const encodedPath = item.path.split('/').map(s => encodeURIComponent(s)).join('/');
  const downloadUrl = `/api/download/${encodedPath}?token=${state.sessionId}`;
  const resumeState = getResumeState(item.path);
  const startByte = resumeState ? resumeState.bytes : 0;

  let handle, writable;
  try {
    handle = await window.showSaveFilePicker({ suggestedName: item.name });
    writable = await handle.createWritable({ keepExistingData: startByte > 0 });
  } catch (e) {
    if (e.name === 'AbortError') return; // user cancelled picker
    showToast('File save not supported in this context. Trying fallback…', 'warning', 3000);
    legacyDownload(item);
    return;
  }

  const dlEntry = { name: item.name, progress: Math.round(startByte / (item.size || 1) * 100), done: false, error: false, download: true, streaming: true, abortController: new AbortController() };
  uploads.active.push(dlEntry);
  uploads.visible = true;
  renderUploadPanel();

  let received = startByte;
  const totalSize = resumeState?.total || item.size || 0;

  try {
    if (startByte > 0) await writable.seek(startByte);

    const res = await fetch(downloadUrl, {
      headers: startByte > 0 ? { Range: `bytes=${startByte}-` } : {},
      signal: dlEntry.abortController.signal
    });

    if (!res.ok && res.status !== 206) throw new Error(`HTTP ${res.status}`);

    // If server returned a Content-Range, extract the total size
    const contentRange = res.headers.get('Content-Range');
    let effectiveTotal = totalSize;
    if (contentRange) {
      const m = contentRange.match(/bytes \d+-\d+\/(\d+)/);
      if (m) effectiveTotal = parseInt(m[1], 10);
    }

    const reader = res.body.getReader();
    let lastSave = Date.now();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      await writable.write(value);
      received += value.length;
      dlEntry.progress = effectiveTotal ? Math.round((received / effectiveTotal) * 100) : 0;
      renderUploadPanel();
      // Save resume state every 2 seconds
      if (Date.now() - lastSave > 2000) {
        saveResumeState(item.path, received, effectiveTotal, downloadUrl);
        lastSave = Date.now();
      }
    }

    await writable.close();
    dlEntry.done = true;
    clearResumeState(item.path);
    showToast(`${item.name} downloaded successfully`, 'success', 3000);
  } catch (e) {
    if (e.name === 'AbortError') { dlEntry.done = true; }
    else {
      dlEntry.error = true;
      if (received > startByte) {
        saveResumeState(item.path, received, totalSize, downloadUrl);
        showToast(`Download interrupted at ${formatBytes(received)}. Click again to resume.`, 'warning', 6000);
      } else {
        showToast('Download failed: ' + e.message, 'error');
      }
    }
    try { writable.close(); } catch (_) {}
  }

  renderUploadPanel();
  setTimeout(() => {
    uploads.active = uploads.active.filter(u => u !== dlEntry);
    if (uploads.active.length === 0) uploads.visible = false;
    renderUploadPanel();
  }, dlEntry.done ? 3000 : 0);
}

// ============================================
//  TIER 2: FETCH + BLOB (small files only — ≤100 MB)
// ============================================

async function fetchDownloadWithProgress(item) {
  const endpoint = item.type === 'directory' ? 'download-zip' : 'download';
  const encodedPath = item.path.split('/').map(s => encodeURIComponent(s)).join('/');
  const dlEntry = { name: item.name, progress: 0, done: false, error: false, download: true, abortController: new AbortController() };
  uploads.active.push(dlEntry);
  uploads.visible = true;
  renderUploadPanel();

  try {
    const res = await fetch(`/api/${endpoint}/${encodedPath}?token=${state.sessionId}`, { signal: dlEntry.abortController.signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const contentLength = res.headers.get('Content-Length');
    const total = contentLength ? parseInt(contentLength, 10) : 0;
    const reader = res.body.getReader();
    const chunks = [];
    let received = 0;

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(value);
      received += value.length;
      if (total) { dlEntry.progress = Math.round((received / total) * 100); renderUploadPanel(); }
    }

    const blob = new Blob(chunks);
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = item.name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(() => URL.revokeObjectURL(url), 10000);
    dlEntry.done = true;
  } catch (e) {
    if (e.name === 'AbortError') { dlEntry.done = true; }
    else { dlEntry.error = true; showToast('Download failed: ' + e.message, 'error'); }
  }
  renderUploadPanel();
  setTimeout(() => {
    uploads.active = uploads.active.filter(u => u !== dlEntry);
    if (uploads.active.length === 0) uploads.visible = false;
    renderUploadPanel();
  }, 3000);
}

// ============================================
//  TIER 3: LEGACY DOWNLOAD (native browser — large files, Safari/Firefox)
// ============================================

function legacyDownload(item) {
  const endpoint = item.type === 'directory' ? 'download-zip' : 'download';
  const encodedPath = item.path.split('/').map(s => encodeURIComponent(s)).join('/');
  window.location.href = `/api/${endpoint}/${encodedPath}?token=${state.sessionId}`;
}

function formatBytes(bytes) {
  if (bytes < 1024) return bytes + ' B';
  const kb = bytes / 1024;
  if (kb < 1024) return kb.toFixed(1) + ' KB';
  const mb = kb / 1024;
  if (mb < 1024) return mb.toFixed(1) + ' MB';
  const gb = mb / 1024;
  return gb.toFixed(2) + ' GB';
}

async function downloadEncrypted(item) {
  try {
    // Encode each path segment individually (preserves '/' separators)
    const encodedPath = item.path.split('/').map(s => encodeURIComponent(s)).join('/');
    const res = await fetch(`/api/download/${encodedPath}?token=${state.sessionId}`);

    if (!res.ok) {
      const errText = await res.text().catch(() => res.statusText);
      throw new Error(`Server error ${res.status}: ${errText}`);
    }

    const contentType = res.headers.get('Content-Type') || '';
    if (contentType.includes('application/json')) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.reason || 'Server returned error instead of file');
    }

    const encData = await res.arrayBuffer();
    let decData;
    try {
      decData = await decryptData(encData);
    } catch (decryptErr) {
      // Decryption failed — file may have been uploaded before key was ready
      console.warn('Decryption failed, offering fallback:', decryptErr.message);
      const fallback = await showConfirm(
        `Decryption failed for "${item.name}". This file may have been uploaded without encryption. Download the raw file instead?`,
        'Decryption failed'
      );
      if (!fallback) return;
      // Offer raw bytes as-is
      decData = encData;
    }

    const blob = new Blob([decData]);
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = item.name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  } catch (e) {
    console.error('E2E decrypt error:', e);
    showToast('Download failed: ' + e.message, 'error');
  }
}

async function previewFile(item) {
  const ext = item.name.split('.').pop().toLowerCase();
  const url = `/api/preview/${item.path}?token=${state.sessionId}`;
  const el = document.getElementById('modal-container');

  const showModal = (body) => {
    el.innerHTML = `
      <div class="modal-overlay" onclick="closeModal()">
        <div class="modal" onclick="event.stopPropagation()">
          <div class="modal-header">
             <strong class="modal-title">${item.name}</strong>
             <div style="display:flex;gap:8px;align-items:center">
               <button class="btn btn-secondary" onclick="downloadItemEncoded('${encode(item.path)}','${item.type}',${item.size || 0})">${ICONS.download} Download</button>
               <button class="btn btn-icon btn-ghost" aria-label="Close" onclick="closeModal()">✕</button>
             </div>
          </div>
          <div class="modal-content">${body}</div>
        </div>
      </div>
    `;
  };

  // Handle encrypted previews
  if (state.encrypted && state.encryptionKey) {
    if (IMAGE_EXTS.includes(ext)) {
      showModal(`<div style="padding:40px;text-align:center;color:#64748b">Decrypting...</div>`);
      try {
        const res = await fetch(url);
        const encData = await res.arrayBuffer();
        const decData = await decryptData(encData);
        const blob = new Blob([decData]);
        const blobUrl = URL.createObjectURL(blob);
        document.querySelector('.modal-content').innerHTML = `<img src="${blobUrl}" alt="${item.name}">`;
      } catch (e) {
        document.querySelector('.modal-content').innerHTML = `<div style="padding:40px;text-align:center;color:#dc2626">Decryption failed.</div>`;
      }
      return;
    }
    // For non-image encrypted files, just show download option
    showModal(`<div style="padding:40px;text-align:center;color:#64748b">
      ${ICONS.shield}
      <p style="margin:16px 0">This file is encrypted. Download to view.</p>
      <button class="btn btn-primary" onclick="downloadItemEncoded('${encode(item.path)}','${item.type}',${item.size || 0})">Download & Decrypt</button>
    </div>`);
    return;
  }

  if (IMAGE_EXTS.includes(ext)) {
    showModal(`<img src="${url}" alt="${item.name}">`);
    return;
  }
  if (['mp4', 'mov', 'webm'].includes(ext)) {
    showModal(`<video src="${url}" controls autoplay></video>`);
    return;
  }
  if (['mp3', 'wav', 'ogg', 'aac'].includes(ext)) {
    showModal(`<div style="padding:40px"><audio src="${url}" controls autoplay style="width:100%"></audio></div>`);
    return;
  }
  if (ext === 'pdf') {
    showModal(`<iframe src="${url}" style="width:100%;height:80vh;border:none"></iframe>`);
    return;
  }

  const textExts = ['txt', 'md', 'json', 'js', 'css', 'html', 'xml', 'csv', 'log', 'yaml', 'yml', 'py', 'swift', 'sh', 'env', 'toml', 'cfg', 'ini', 'conf', 'ts', 'jsx', 'tsx', 'java', 'c', 'cpp', 'h', 'rb', 'go', 'rs', 'php', 'sql'];
  if (textExts.includes(ext)) {
    showModal(`<div style="padding:24px;color:#64748b">Loading...</div>`);
    try {
      const res = await fetch(url);
      const data = await res.json();
      if (data.type === 'text' && data.content) {
        const escaped = data.content.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        document.querySelector('.modal-content').innerHTML = `<pre style="font-family:'IBM Plex Mono','SF Mono',Menlo,monospace;font-size:13px;line-height:1.6;color:#334155;padding:24px;margin:0;white-space:pre-wrap;word-break:break-word;text-align:left;width:100%;max-height:80vh;overflow:auto;background:#f8fafc">${escaped}</pre>`;
      } else {
        document.querySelector('.modal-content').innerHTML = `<div style="padding:40px;text-align:center;color:#64748b">Preview not available.</div>`;
      }
    } catch (e) {
      document.querySelector('.modal-content').innerHTML = `<div style="padding:40px;text-align:center;color:#dc2626">Error loading preview.</div>`;
    }
    return;
  }

  showModal(`<div style="padding:40px;text-align:center;color:#64748b">
    <p style="margin-bottom:16px">Preview not available for <strong>.${ext}</strong> files.</p>
    <button class="btn btn-primary" onclick="downloadItemEncoded('${encode(item.path)}','${item.type}',${item.size || 0})">Download file</button>
  </div>`);
}

function closeModal() {
  document.getElementById('modal-container').innerHTML = '';
}

function encode(value) {
  return encodeURIComponent(value || '');
}

function escHtml(str) {
  return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

let filterTimer = null;
function debounceFilter(value) {
  state.filterText = value;
  clearTimeout(filterTimer);
  filterTimer = setTimeout(() => render(), 150);
}

function openItemEncoded(path, name, type) {
  openItem({
    path: decodeURIComponent(path),
    name: decodeURIComponent(name),
    type
  });
}

function downloadItemEncoded(path, type, size) {
  const decodedPath = decodeURIComponent(path);
  const name = decodedPath.split('/').pop();
  downloadItem({ path: decodedPath, type, name, size: size != null ? Number(size) : undefined });
}

function deleteItemEncoded(path, nameEncoded) {
  confirmDelete(decodeURIComponent(path), decodeURIComponent(nameEncoded || ''));
}

// ============================================
//  VIEW MODE (LIST / GALLERY)
// ============================================

function toggleViewMode() {
  state.viewMode = state.viewMode === 'list' ? 'gallery' : 'list';
  render();
}

function hasImages() {
  return state.items.some(i => {
    if (i.type !== 'file') return false;
    const ext = i.name.split('.').pop().toLowerCase();
    return IMAGE_EXTS.includes(ext);
  });
}

// ============================================
//  MOBILE SIDEBAR
// ============================================

function toggleSidebar() {
  state.sidebarOpen = !state.sidebarOpen;
  const sidebar = document.querySelector('.sidebar');
  const overlay = document.getElementById('sidebar-overlay');
  if (sidebar) sidebar.classList.toggle('sidebar-open', state.sidebarOpen);
  if (overlay) overlay.classList.toggle('visible', state.sidebarOpen);
}

function closeSidebar() {
  state.sidebarOpen = false;
  const sidebar = document.querySelector('.sidebar');
  const overlay = document.getElementById('sidebar-overlay');
  if (sidebar) sidebar.classList.remove('sidebar-open');
  if (overlay) overlay.classList.remove('visible');
}

// ============================================
//  THEME
// ============================================

function toggleTheme() {
  const html = document.documentElement;
  const current = html.getAttribute('data-theme');
  const next = current === 'dark' ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  localStorage.setItem('ssdb-theme', next);
}

// ============================================
//  TOAST NOTIFICATIONS
// ============================================

function showToast(message, type = 'error', duration = 4000) {
  let container = document.getElementById('toast-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container';
    document.body.appendChild(container);
  }
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  const icons = { error: '✕', success: '✓', warning: '⚠' };
  toast.innerHTML = `<span class="toast-icon">${icons[type] || ''}</span><span class="toast-body">${message}</span><button class="toast-close" aria-label="Dismiss" onclick="this.parentElement.remove()">×</button>`;
  container.appendChild(toast);
  setTimeout(() => { toast.classList.add('toast-exit'); setTimeout(() => toast.remove(), 300); }, duration);
}

// ============================================
//  CONFIRMATION / PROMPT DIALOGS
// ============================================

function showConfirm(message, title = 'Confirm', danger = false) {
  return new Promise((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'confirm-overlay';
    overlay.innerHTML = `<div class="confirm-dialog" role="alertdialog" aria-labelledby="confirm-title"><h3 id="confirm-title">${title}</h3><p>${message}</p><div class="confirm-actions"><button class="btn btn-secondary" id="confirm-cancel">Cancel</button><button class="btn ${danger ? 'btn-danger' : 'btn-primary'}" id="confirm-ok">${danger ? 'Delete' : 'OK'}</button></div></div>`;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) { overlay.remove(); resolve(false); } });
    overlay.querySelector('#confirm-cancel').onclick = () => { overlay.remove(); resolve(false); };
    overlay.querySelector('#confirm-ok').onclick = () => { overlay.remove(); resolve(true); };
    overlay.querySelector('#confirm-ok').focus();
    overlay.onkeydown = (e) => { if (e.key === 'Escape') { overlay.remove(); resolve(false); } };
  });
}

function showPrompt(message, title = 'Input', defaultValue = '') {
  return new Promise((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'confirm-overlay';
    overlay.innerHTML = `<div class="confirm-dialog" role="dialog" aria-labelledby="prompt-title"><h3 id="prompt-title">${title}</h3><p>${message}</p><input type="text" id="prompt-input" value="${escHtml(defaultValue)}" autofocus><div class="confirm-actions"><button class="btn btn-secondary" id="prompt-cancel">Cancel</button><button class="btn btn-primary" id="prompt-ok">OK</button></div></div>`;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) { overlay.remove(); resolve(null); } });
    overlay.querySelector('#prompt-cancel').onclick = () => { overlay.remove(); resolve(null); };
    overlay.querySelector('#prompt-ok').onclick = () => { const val = overlay.querySelector('#prompt-input').value; overlay.remove(); resolve(val); };
    overlay.querySelector('#prompt-input').focus();
    overlay.onkeydown = (e) => { if (e.key === 'Escape') { overlay.remove(); resolve(null); } if (e.key === 'Enter') { const val = overlay.querySelector('#prompt-input').value; overlay.remove(); resolve(val); } };
  });
}

// ============================================
//  RECENT FILES VIEW
// ============================================

function renderRecentView(app) {
  const recentItems = state.recentFiles.map(f => {
    const { icon, colorClass } = getIcon(f.file, 'file');
    const time = f.time ? new Date(f.time).toLocaleString() : '—';
    return `<tr onclick="navigateToRecentFile('${escHtml(f.file)}')" tabindex="0" role="row" onkeydown="if(event.key==='Enter') navigateToRecentFile('${escHtml(f.file)}')">
      <td role="gridcell"><div class="file-name"><span class="file-icon ${colorClass}">${icon}</span><span class="file-name-text">${escHtml(f.file)}</span></div></td>
      <td role="gridcell"><span style="font-size:12px;color:${f.action === 'upload' ? 'var(--color-brand)' : 'var(--color-info)'}">${f.action === 'upload' ? ICONS.upload : ICONS.download} ${f.action}</span></td>
      <td role="gridcell" style="font-size:12px;color:var(--color-text-tertiary)">${time}</td>
      <td role="gridcell" style="text-align:right"><button class="btn btn-secondary" onclick="event.stopPropagation(); downloadItemEncoded('${encodeURIComponent(f.file)}', 'file', 0)">${ICONS.download}</button></td>
    </tr>`;
  }).join('');

  app.innerHTML = `<div class="app-shell">
    <div class="sidebar-overlay" id="sidebar-overlay" onclick="closeSidebar()"></div>
    <aside class="sidebar ${state.sidebarOpen ? 'sidebar-open' : ''}">
      <div class="brand"><span class="brand-icon">${ICONS.logo}</span><div><strong>SSDBridge</strong><small>File workspace</small></div></div>
      <button class="nav-item" onclick="navigate(''); closeSidebar();">${ICONS.home}<span>All files</span></button>
      <button class="nav-item active" onclick="loadRecent(); closeSidebar();">${ICONS.search}<span>Recent</span></button>
      <div class="sidebar-spacer"></div>
      <button class="nav-item theme-toggle-item" onclick="toggleTheme()"><span class="nav-icon-placeholder">${ICONS.moon}</span><span>Toggle theme</span></button>
      <button class="nav-item leave-item" onclick="leaveSession()"><span class="nav-icon-placeholder">${ICONS.lock}</span><span>Leave session</span></button>
    </aside>
    <main class="main">
      <header class="header">
        <div class="header-left">
          <button class="btn btn-icon btn-ghost hamburger" onclick="toggleSidebar()">${ICONS.menu}</button>
          <div class="header-content"><p class="eyebrow">Files</p><h1>Recent</h1></div>
        </div>
      </header>
      <section class="content-card">
        <div class="card-header"><span class="item-count">${state.recentFiles.length} files</span></div>
        <div class="file-list-container">
          ${state.loading ? '<div style="padding:24px;text-align:center;color:var(--color-text-tertiary)">Loading...</div>' :
            state.error ? `<div style="padding:24px;text-align:center;color:var(--color-danger)">${state.error}</div>` :
            state.recentFiles.length === 0 ? '<div class="empty-state"><div class="empty-icon">'+ICONS.file+'</div><h3>No recent files</h3><p>Files accessed via download or upload will appear here.</p></div>' :
            `<table role="grid" aria-label="Recent files"><thead role="rowgroup"><tr><th>File</th><th>Action</th><th>Time</th><th style="text-align:right">Download</th></tr></thead><tbody>${recentItems}</tbody></table>`
          }
        </div>
      </section>
    </main>
  </div><div id="modal-container"></div>`;
}

function navigateToRecentFile(filePath) {
  const parts = filePath.split('/');
  parts.pop();
  navigate(parts.join('/'));
}

// ============================================
//  RENDER
// ============================================

function render() {
  clearTimeout(filterTimer);
  const app = document.getElementById('app');
  if (!app) return;

  if (state.view === 'join') {
    renderJoinView(app);
    return;
  }

  if (state.view !== 'browse') {
    if (state.view === 'recent') { renderRecentView(app); return; }
    return;
  }

  const canWrite = state.permissions === 'readwrite';
  const parts = state.currentPath ? state.currentPath.split('/') : [];

  let bcHtml = `<button class="crumb ${!state.currentPath ? 'current' : ''}" onclick="navigate('')">${ICONS.home} Home</button>`;
  parts.forEach((part, i) => {
    const path = parts.slice(0, i + 1).join('/');
    bcHtml += `
      <span class="crumb-sep">${ICONS.chevronRight}</span>
      <button class="crumb ${i === parts.length - 1 ? 'current' : ''}" onclick="navigate(decodeURIComponent('${encode(path)}'))">${part}</button>
    `;
  });

  let bodyContent = '';
  if (state.loading) {
    bodyContent = Array.from({ length: 6 }, () => `
      <div class="skeleton-row">
        <div class="skeleton-pill sk-icon"></div>
        <div class="skeleton-pill sk-name"></div>
        <div class="skeleton-pill sk-size"></div>
        <div class="skeleton-pill sk-date"></div>
      </div>
    `).join('');
    app.innerHTML = buildBrowseShell(canWrite, bcHtml, 0, bodyContent, true);
    attachDragDrop(canWrite);
    return;
  }

  if (state.error) {
    bodyContent = `<tr><td colspan="5" class="table-message table-error">${state.error}</td></tr>`;
  } else if (state.items.length === 0) {
    bodyContent = `<tr><td colspan="5" class="table-message">
      <div class="empty-state">
        <div class="empty-icon">${ICONS.folder}</div>
        <h3>No files here</h3>
        <p>${canWrite ? 'Drag and drop or use the upload button to add files.' : 'This folder is empty.'}</p>
      </div>
    </td></tr>`;
  } else if (state.viewMode === 'gallery') {
    bodyContent = renderGalleryGrid();
  } else {
    bodyContent = renderTableRows(canWrite);
  }

  app.innerHTML = buildBrowseShell(canWrite, bcHtml, state.items.length, bodyContent, false);
  attachDragDrop(canWrite);
}

function renderJoinView(app) {
  const encBadge = state.encrypted
    ? `<div class="encrypted-badge">${ICONS.shield} <span>End-to-End Encrypted</span></div>`
    : '';

  app.innerHTML = `
    <div class="join-page">
      <section class="hero-panel">
        <p class="eyebrow">SSDBridge</p>
        <h1>Secure File<br>Bridge</h1>
	        <p class="hero-subtitle">// encrypted &middot; peer-to-peer &middot; zero-knowledge</p>
        <p class="hero-copy">
          Access shared files directly from any device. No cloud storage. No intermediaries. Your files, your infrastructure.
        </p>
        <div class="hero-features">
          <div class="feature-item">
            <span class="feature-icon">${ICONS.lock}</span>
            <span>Password-protected access</span>
          </div>
          <div class="feature-item">
            <span class="feature-icon">${ICONS.upload}</span>
            <span>End-to-end encryption</span>
          </div>
          <div class="feature-item">
            <span class="feature-icon">${ICONS.folder}</span>
            <span>Browse and transfer in real time</span>
          </div>
        </div>
      </section>

      <section class="join-card">
        <div class="join-card-icon">${ICONS.lock}</div>
        <h2>Access</h2>
        <p>Enter the password provided by the host to continue.</p>
        ${encBadge}

        ${state.joinError ? `<div class="form-error" role="alert">${state.joinError}</div>` : ''}

        <div class="input-group">
          <label for="join-pass" class="sr-only">Password</label>
          <input
            type="password"
            id="join-pass"
            class="input-main"
            placeholder="Enter password"
            autocomplete="current-password"
            autofocus
            onkeydown="if(event.key==='Enter') joinSession(this.value)"
          >
        </div>
        <button class="btn btn-primary btn-lg btn-full" onclick="joinSession(document.getElementById('join-pass').value)">
          Continue
        </button>
      </section>
    </div>
  `;
}

function renderTableRows(canWrite) {
  const ft = state.filterText.toLowerCase();
  const visibleItems = ft ? state.items.filter(i => i.name.toLowerCase().includes(ft)) : state.items;
  const fileItems = visibleItems.filter(i => i.type === 'file');
  const allSelected = fileItems.length > 0 && state.selectedPaths.size === fileItems.length;

  let fileIdx = 0;
  return visibleItems.map((item) => {
    const { icon, colorClass } = getIcon(item.name, item.type);
    const size = item.sizeFormatted || '—';
    const modified = item.modifiedFormatted || item.modified || '—';
    const pathEncoded = encode(item.path);
    const nameEncoded = encode(item.name);
    const isSelected = state.selectedPaths.has(item.path);
    const isFile = item.type === 'file';
    const currentFileIdx = isFile ? fileIdx++ : -1;
    // Presence dot — someone else is viewing this file/folder
    const viewer = state.presence.viewers.find(v => v.path === item.path);
    const presenceDot = viewer ? `<span class="presence-file-dot" style="background:${viewer.color}" title="Someone is viewing this"></span>` : '';

    return `
      <tr class="${isSelected ? 'row-selected' : ''}" tabindex="0" role="row" aria-selected="${isSelected}"
          onclick="openItemEncoded('${pathEncoded}', '${nameEncoded}', '${item.type}')"
          onkeydown="if(event.key==='Enter') openItemEncoded('${pathEncoded}', '${nameEncoded}', '${item.type}')">
        <td class="td-checkbox" role="gridcell" onclick="event.stopPropagation()">
          ${isFile ? `<input type="checkbox" ${isSelected ? 'checked' : ''} onchange="toggleSelect(decodeURIComponent('${pathEncoded}'), event, ${currentFileIdx})" aria-label="Select ${item.name}">` : ''}
        </td>
        <td role="gridcell">
          <div class="file-name">
            <span class="file-icon ${colorClass}">${icon}</span>
            <span class="file-name-text">${item.name}</span>
            ${presenceDot}
          </div>
        </td>
        <td role="gridcell">${size}</td>
        <td class="td-modified" role="gridcell">${modified}</td>
        <td class="align-right" role="gridcell">
           <div class="row-actions">
             <button class="btn btn-icon btn-ghost" title="Download" aria-label="Download ${item.name}" onclick="event.stopPropagation(); downloadItemEncoded('${pathEncoded}', '${item.type}', ${item.size || 0})">${ICONS.download}</button>
             ${canWrite ? `<button class="btn btn-icon btn-ghost" title="Rename" aria-label="Rename ${item.name}" onclick="event.stopPropagation(); renameItem('${pathEncoded}', '${nameEncoded}')">${ICONS.rename}</button>` : ''}
             ${canWrite ? `<button class="btn btn-icon btn-ghost danger" title="Delete" aria-label="Delete ${item.name}" onclick="event.stopPropagation(); deleteItemEncoded('${pathEncoded}','${nameEncoded}')">${ICONS.trash}</button>` : ''}
           </div>
        </td>
      </tr>
    `;
  }).join('');
}

function renderGalleryGrid() {
  return `<div class="gallery-grid">${state.items.map(item => {
    const ext = item.name.split('.').pop().toLowerCase();
    const isImage = IMAGE_EXTS.includes(ext) && item.type === 'file';
    const pathEncoded = encode(item.path);
    const nameEncoded = encode(item.name);
    const { icon, colorClass } = getIcon(item.name, item.type);

    if (isImage) {
      const thumbUrl = `/api/preview/${item.path}?token=${state.sessionId}`;
      return `
        <div class="gallery-item" onclick="openItemEncoded('${pathEncoded}', '${nameEncoded}', '${item.type}')">
          <div class="gallery-thumb" style="background-image:url('${thumbUrl}')"></div>
          <div class="gallery-label">${item.name}</div>
        </div>
      `;
    }

    return `
      <div class="gallery-item gallery-item-file" onclick="openItemEncoded('${pathEncoded}', '${nameEncoded}', '${item.type}')">
        <div class="gallery-icon ${colorClass}">${icon}</div>
        <div class="gallery-label">${item.name}</div>
      </div>
    `;
  }).join('')}</div>`;
}

// ============================================
//  BUILD SHELL
// ============================================

function buildBrowseShell(canWrite, bcHtml, itemCount, bodyContent, isSkeleton) {
  const folderName = state.currentPath ? state.currentPath.split('/').pop() : 'All files';
  const showGalleryBtn = hasImages();
  const encBanner = state.encrypted
    ? `<div class="enc-banner">${ICONS.shield} End-to-End Encrypted</div>`
    : '';

  // Bulk action bar
  const bulkBar = state.selectedPaths.size > 0
    ? `<div class="bulk-bar">
        <span>${state.selectedPaths.size} file(s) selected</span>
        <button class="btn btn-primary" onclick="bulkDownload()">${ICONS.download} Download ZIP</button>
        ${canWrite ? `<button class="btn btn-danger" onclick="bulkDelete()">${ICONS.trash} Delete</button>` : ''}
        <button class="btn btn-ghost" onclick="state.selectedPaths.clear(); render();">Clear</button>
      </div>`
    : '';

  // Select-all checkbox header
  const fileItems = state.items.filter(i => i.type === 'file');
  const allSelected = fileItems.length > 0 && state.selectedPaths.size === fileItems.length;

  // Sort arrow helper
  const sortArrow = (field) => {
    const active = state.sortField === field;
    return `<span class="sort-arrow${active ? ' active' : ''}">${active ? (state.sortDir === 'asc' ? ' ▲' : ' ▼') : ' ⇅'}</span>`;
  };

  return `
    <div class="app-shell">
      <div class="sidebar-overlay" id="sidebar-overlay" onclick="closeSidebar()"></div>
      <aside class="sidebar ${state.sidebarOpen ? 'sidebar-open' : ''}">
        <div class="brand">
          <span class="brand-icon">${ICONS.logo}</span>
          <div>
            <strong>SSDBridge</strong>
            <small>File workspace</small>
          </div>
        </div>

        <button class="nav-item active" onclick="navigate(''); closeSidebar();">${ICONS.home}<span>All files</span></button>
        <button class="nav-item" onclick="loadRecent(); closeSidebar();">${ICONS.search}<span>Recent</span></button>

        <div class="sidebar-section">
          <p class="sidebar-label">Access</p>
          <p class="sidebar-value">
            <span class="status-dot ${state.permissions === 'readwrite' ? 'status-write' : 'status-read'}"></span>
            ${state.permissions === 'readwrite' ? 'Read & Write' : 'Read only'}
          </p>
          ${state.encrypted ? '<p class="sidebar-value"><span class="status-dot status-encrypted"></span>Encrypted</p>' : ''}
        </div>

        <div class="sidebar-section">
          <p class="sidebar-label">Share</p>
          <div style="background:rgba(255,255,255,0.06);padding:6px;border-radius:3px;display:inline-block;margin:4px 0">
            ${generateQRSVG(window.location.origin + window.location.pathname, 120)}
          </div>
          <p style="color:#706860;font-size:9px;font-family:'IBM Plex Mono',monospace;text-align:center;margin-top:2px;letter-spacing:0.04em">SCAN TO JOIN</p>
        </div>

        <div class="sidebar-spacer"></div>

        <button class="nav-item theme-toggle-item" onclick="toggleTheme()" aria-label="Toggle dark mode">
          <span class="nav-icon-placeholder">${ICONS.moon}</span>
          <span>Toggle theme</span>
        </button>

        <button class="nav-item leave-item" onclick="leaveSession()" aria-label="Leave session">
          <span class="nav-icon-placeholder">${ICONS.lock}</span>
          <span>Leave session</span>
        </button>

        ${canWrite ? `
        <div class="sidebar-cta">
          <button class="btn btn-primary btn-full" onclick="triggerUpload(); closeSidebar();">${ICONS.upload}<span>Upload files</span></button>
          <button class="btn btn-secondary btn-full" onclick="triggerDirUpload(); closeSidebar();">${ICONS.upload}<span>Upload folder</span></button>
          <button class="btn btn-secondary btn-full" onclick="createFolder(); closeSidebar();">${ICONS.plus}<span>New folder</span></button>
          <input type="file" id="upload-input" multiple style="display:none" onchange="handleUpload(this.files)">
          <input type="file" id="upload-dir-input" webkitdirectory multiple style="display:none" onchange="handleUpload(this.files)">
        </div>
        ` : ''}
      </aside>

      <main class="main">
        <header class="header">
          <div class="header-left">
            <button class="btn btn-icon btn-ghost hamburger" onclick="toggleSidebar()">${ICONS.menu}</button>
            <div class="header-content">
              <p class="eyebrow">Files</p>
              <h1>${folderName}</h1>
            </div>
          </div>
          <div class="header-tools">
            ${state.presence.count > 1 ? `
            <div class="presence-badge" title="${state.presence.count - 1} other(s) browsing">
              <span class="presence-dot-live"></span>
              <span>${state.presence.count - 1} here</span>
            </div>
            ` : ''}
            ${encBanner}
            <button class="btn btn-secondary" onclick="triggerWormhole()" title="Wormhole — send a file to the host">${ICONS.upload}<span style="font-size:10px;margin-left:2px;opacity:0.7">⚡</span></button>
            <button class="btn btn-secondary" onclick="goUp()" ${!state.currentPath ? 'disabled' : ''}>${ICONS.chevronRight} Back</button>
            <input type="file" id="wormhole-input" style="display:none" onchange="handleWormholeUpload(this.files); this.value='';">
          </div>
        </header>

        ${bulkBar}
        <div class="search-bar">
          <input type="text" class="search-input" placeholder="Filter files…" value="${escHtml(state.filterText)}"
            oninput="debounceFilter(this.value)">
          ${state.filterText ? `<button class="btn btn-ghost" onclick="state.filterText=''; render();">Clear</button>` : ''}
        </div>
        ${state.filterText && state.pagination.hasMore ? `
        <div class="search-scope-note">
          ${ICONS.search} Showing matches from first ${state.items.length} of ${state.pagination.total} items.
          <button class="btn btn-ghost" style="font-size:11px;min-height:24px;padding:0 8px" onclick="loadMore()">Search more</button>
        </div>
        ` : ''}

        <section class="content-card">
          <div class="card-header">
            <div class="breadcrumbs">${bcHtml}</div>
            <div class="card-header-right">
              <span class="item-count">${state.pagination.total > 0 ? `${state.items.length} of ${state.pagination.total} items` : `${itemCount} items`}</span>
              ${showGalleryBtn ? `
                <button class="btn btn-icon btn-ghost view-toggle" title="${state.viewMode === 'gallery' ? 'List view' : 'Gallery view'}" onclick="toggleViewMode()">
                  ${state.viewMode === 'gallery' ? ICONS.list : ICONS.grid}
                </button>
              ` : ''}
            </div>
          </div>

          ${isSkeleton ? `<div class="file-list-container">${bodyContent}</div>` :
      state.viewMode === 'gallery' ? `<div class="file-list-container gallery-container">${bodyContent}</div>` : `
          <div class="file-list-container">
            <table role="grid" aria-label="File list">
              <thead role="rowgroup">
                <tr role="row">
                  <th class="th-checkbox"><input type="checkbox" ${allSelected ? 'checked' : ''} onchange="toggleSelectAll()"></th>
                  <th class="sortable" style="width:40%" onclick="toggleSort('name')">Name${sortArrow('name')}</th>
                  <th class="sortable" style="width:12%" onclick="toggleSort('size')">Size${sortArrow('size')}</th>
                  <th class="sortable th-modified" style="width:25%" onclick="toggleSort('modified')">Modified${sortArrow('modified')}</th>
                  <th style="width:13%;text-align:right">Actions</th>
                </tr>
              </thead>
              <tbody>${bodyContent}</tbody>
            </table>
          </div>`}
          ${state.pagination.hasMore && !isSkeleton ? `
            <div style="text-align:center;padding:12px 0;">
              <button class="btn btn-secondary" onclick="loadMore()" ${state.loadingMore ? 'disabled' : ''}>
                ${state.loadingMore ? 'Loading…' : 'Load more…'}
              </button>
            </div>
          ` : ''}
        </section>
      </main>

      ${canWrite ? `<button class="fab" onclick="triggerUpload()" title="Upload">${ICONS.upload}</button>` : ''}

      <div class="mobile-bottom-bar">
        <button class="bottom-bar-btn" onclick="navigate('')">${ICONS.home}<span>Files</span></button>
        ${canWrite ? `<button class="bottom-bar-btn" onclick="triggerUpload()">${ICONS.upload}<span>Upload</span></button>` : ''}
        <button class="bottom-bar-btn" onclick="document.querySelector('.search-input')?.focus()">${ICONS.search}<span>Search</span></button>
        <button class="bottom-bar-btn" onclick="toggleSidebar()">${ICONS.menu}<span>Menu</span></button>
      </div>
    </div>

    <div id="modal-container"></div>
    <div class="drop-zone" id="drop-zone">Drop files to upload</div>
    ${state.wormholeActive ? `
    <div class="wormhole-overlay" onclick="state.wormholeActive=false;state.wormholeFilename=null;render()">
      <div class="wormhole-portal" onclick="event.stopPropagation()">
        <div class="wormhole-ring"></div>
        <div class="wormhole-ring wormhole-ring-2"></div>
        <div class="wormhole-ring wormhole-ring-3"></div>
        <div class="wormhole-core">
          ${ICONS.upload}
          <p class="wormhole-label">${state.wormholeFilename ? `Sending "${escHtml(state.wormholeFilename)}"…` : 'Wormhole Active'}</p>
          <p class="wormhole-sub">${state.wormholeFilename ? 'Materializing on host…' : 'Drop any file to teleport it to the host'}</p>
          ${state.wormholeFilename ? '<div class="wormhole-spinner"></div>' : `
          <button class="btn btn-primary" onclick="triggerWormhole()" style="margin-top:12px">Choose file</button>
          `}
        </div>
      </div>
    </div>
    ` : ''}
  `;
}

// ============================================
//  DRAG & DROP
// ============================================

function attachDragDrop(canWrite) {
  if (canWrite) {
    const drop = document.getElementById('drop-zone');
    if (!drop) return;
    document.body.ondragover = (e) => { e.preventDefault(); drop.style.opacity = 1; };
    document.body.ondragleave = (e) => { e.preventDefault(); drop.style.opacity = 0; };
    document.body.ondrop = (e) => { e.preventDefault(); drop.style.opacity = 0; handleUpload(e.dataTransfer.files); };
  } else {
    document.body.ondragover = null;
    document.body.ondragleave = null;
    document.body.ondrop = null;
  }
}

// ============================================
//  HELPERS
// ============================================

function getIcon(name, type) {
  if (type === 'directory') return { icon: ICONS.folder, colorClass: 'icon-folder' };
  const ext = name.split('.').pop().toLowerCase();
  if (IMAGE_EXTS.includes(ext)) return { icon: ICONS.image, colorClass: 'icon-image' };
  if (['mp4', 'mov', 'mkv', 'webm'].includes(ext)) return { icon: ICONS.video, colorClass: 'icon-video' };
  if (['mp3', 'wav', 'ogg', 'aac'].includes(ext)) return { icon: ICONS.music, colorClass: 'icon-music' };
  return { icon: ICONS.file, colorClass: 'icon-file' };
}

// Start — use DOMContentLoaded for safety on mobile
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

