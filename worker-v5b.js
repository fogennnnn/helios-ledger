// Helios Ledger Worker v5 — Incremental Merkle Tree
// O(log n) per insert/proof instead of O(n)
// Scales to 1M+ records without timeout

import { createPrivateKey, createPublicKey, generateKeyPairSync,
         sign as nodeCryptoSign, verify as nodeCryptoVerify } from 'node:crypto';

// ─── Config ────────────────────────────────────────────────────────────────
const MAX_CONTENT_BYTES = 50000;
const MAX_USERNAME_LEN  = 32;
const MAX_BALANCE       = 2000000000;
const RATE_WINDOW_ACCT  = 3600;
const RATE_MAX_ACCT     = 10;
const RATE_WINDOW_REC   = 60;
const RATE_MAX_REC      = 100;
const VERSION           = '5.1.0';

const BADGE_JS = `// helios-badge.js — Embeddable verification badge for Helios Ledger
// Usage: <script src="https://ai.oooooooooo.se/badge.js" data-record="RECORD_ID"></script>
// Or:    <div class="helios-badge" data-record="RECORD_ID"></div>
//        <script src="https://ai.oooooooooo.se/badge.js"></script>

(function() {
  'use strict';

  var API = 'https://ai.oooooooooo.se/api/v1';
  var BADGE_CLASS = 'helios-badge';
  var STYLE_ID = 'helios-badge-styles';

  // Inject styles once
  if (!document.getElementById(STYLE_ID)) {
    var css = document.createElement('style');
    css.id = STYLE_ID;
    css.textContent = [
      '.hlx-wrap{display:inline-block;position:relative;vertical-align:middle;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;font-size:14px;line-height:1.4;z-index:9999}',
      '.hlx-mark{width:22px;height:22px;cursor:pointer;display:flex;align-items:center;justify-content:center;border-radius:50%;transition:transform 0.15s ease,box-shadow 0.15s ease}',
      '.hlx-mark:hover{transform:scale(1.15)}',
      '.hlx-mark svg{width:22px;height:22px;display:block}',
      '.hlx-mark--valid svg{fill:#1d9bf0}',
      '.hlx-mark--invalid svg{fill:#71767b}',
      '.hlx-mark--loading svg{fill:#71767b;animation:hlx-pulse 1.2s ease infinite}',
      '@keyframes hlx-pulse{0%,100%{opacity:0.4}50%{opacity:1}}',

      '.hlx-card{position:absolute;bottom:calc(100% + 10px);left:50%;transform:translateX(-50%);width:280px;background:#0d1117;border:1px solid rgba(45,212,170,0.25);border-radius:10px;padding:14px 16px;opacity:0;visibility:hidden;pointer-events:none;transition:opacity 0.15s ease,visibility 0.15s ease;box-shadow:0 8px 32px rgba(0,0,0,0.4)}',
      '.hlx-wrap:hover .hlx-card,.hlx-card:hover{opacity:1;visibility:visible;pointer-events:auto}',
      '.hlx-card::after{content:"";position:absolute;top:100%;left:50%;transform:translateX(-50%);border:6px solid transparent;border-top-color:#0d1117}',

      '.hlx-card-header{display:flex;align-items:center;gap:8px;margin-bottom:10px}',
      '.hlx-card-icon{width:16px;height:16px;flex-shrink:0}',
      '.hlx-card-icon svg{width:16px;height:16px;fill:#2dd4aa}',
      '.hlx-card-title{color:#f0f6fc;font-size:12px;font-weight:600;letter-spacing:0.03em}',
      '.hlx-card-title a{color:#2dd4aa;text-decoration:none}',
      '.hlx-card-title a:hover{text-decoration:underline}',

      '.hlx-card--invalid .hlx-card-icon svg{fill:#f85149}',
      '.hlx-card--invalid .hlx-status{color:#f85149}',

      '.hlx-row{display:flex;justify-content:space-between;align-items:center;padding:4px 0}',
      '.hlx-label{color:#8b949e;font-size:11px}',
      '.hlx-value{color:#c9d1d9;font-size:11px;font-family:"SF Mono",Consolas,monospace;max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}',

      '.hlx-copy{display:inline-flex;align-items:center;gap:4px;cursor:pointer;background:none;border:1px solid rgba(45,212,170,0.2);color:#8b949e;font-size:10px;padding:2px 6px;border-radius:4px;font-family:inherit;transition:all 0.15s ease;margin-top:8px}',
      '.hlx-copy:hover{border-color:#2dd4aa;color:#2dd4aa}',
      '.hlx-copy svg{width:10px;height:10px;fill:currentColor}',

      '.hlx-status{font-size:11px;font-weight:600;color:#2dd4aa}',

      '.hlx-sep{height:1px;background:rgba(139,148,158,0.15);margin:8px 0}',
    ].join('\n');
    document.head.appendChild(css);
  }

  // SVG icons
  var CHECKMARK_SVG = '<svg viewBox="0 0 22 22" xmlns="http://www.w3.org/2000/svg">'
    + '<path d="M11 0C4.925 0 0 4.925 0 11s4.925 11 11 11 11-4.925 11-11S17.075 0 11 0zm5.28 8.28l-6 6a.75.75 0 01-1.06 0l-3-3a.75.75 0 111.06-1.06L9.75 12.69l5.47-5.47a.75.75 0 111.06 1.06z"/>'
    + '</svg>';

  var COPY_SVG = '<svg viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">'
    + '<path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 010 1.5h-1.5a.25.25 0 00-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 00.25-.25v-1.5a.75.75 0 011.5 0v1.5A1.75 1.75 0 019.25 16h-7.5A1.75 1.75 0 010 14.25v-7.5z"/>'
    + '<path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0114.25 11h-7.5A1.75 1.75 0 015 9.25v-7.5zm1.75-.25a.25.25 0 00-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 00.25-.25v-7.5a.25.25 0 00-.25-.25h-7.5z"/>'
    + '</svg>';

  function shortenHash(h) {
    if (!h || h.length < 16) return h || '—';
    return h.substring(0, 8) + '...' + h.substring(h.length - 6);
  }

  function copyText(text, btn) {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text);
    } else {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.style.cssText = 'position:fixed;opacity:0';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
    }
    var orig = btn.innerHTML;
    btn.innerHTML = COPY_SVG + ' copied';
    btn.style.color = '#2dd4aa';
    btn.style.borderColor = '#2dd4aa';
    setTimeout(function() {
      btn.innerHTML = orig;
      btn.style.color = '';
      btn.style.borderColor = '';
    }, 1500);
  }

  function createBadge(el, recordId) {
    // Create wrapper
    var wrap = document.createElement('span');
    wrap.className = 'hlx-wrap';

    // Checkmark
    var mark = document.createElement('span');
    mark.className = 'hlx-mark hlx-mark--loading';
    mark.innerHTML = CHECKMARK_SVG;
    mark.title = 'Helios Ledger — verifying...';
    wrap.appendChild(mark);

    // Card (hidden until hover)
    var card = document.createElement('div');
    card.className = 'hlx-card';
    card.innerHTML = '<div style="color:#8b949e;font-size:11px;text-align:center;padding:8px 0">Verifying...</div>';
    wrap.appendChild(card);

    // Replace or append
    if (el.tagName === 'SCRIPT') {
      el.parentNode.insertBefore(wrap, el);
    } else {
      el.innerHTML = '';
      el.appendChild(wrap);
    }

    // Fetch verification data
    var xhr = new XMLHttpRequest();
    xhr.open('GET', API + '/records/' + recordId + '/verify');
    xhr.onload = function() {
      if (xhr.status !== 200) {
        mark.className = 'hlx-mark hlx-mark--invalid';
        mark.title = 'Helios Ledger — record not found';
        card.className = 'hlx-card hlx-card--invalid';
        card.innerHTML = '<div class="hlx-card-header">'
          + '<span class="hlx-card-icon">' + CHECKMARK_SVG + '</span>'
          + '<span class="hlx-card-title"><a href="https://ai.oooooooooo.se" target="_blank" rel="noopener">Helios Ledger</a></span>'
          + '</div>'
          + '<div class="hlx-status">Record not found</div>';
        return;
      }

      var d;
      try { d = JSON.parse(xhr.responseText); } catch(e) { return; }

      var isValid = d.valid;
      mark.className = 'hlx-mark ' + (isValid ? 'hlx-mark--valid' : 'hlx-mark--invalid');
      mark.title = 'Helios Ledger — ' + (isValid ? 'verified' : 'unverified');

      card.className = 'hlx-card' + (isValid ? '' : ' hlx-card--invalid');
      card.innerHTML = '<div class="hlx-card-header">'
        + '<span class="hlx-card-icon">' + CHECKMARK_SVG + '</span>'
        + '<span class="hlx-card-title"><a href="https://ai.oooooooooo.se" target="_blank" rel="noopener">Helios Ledger</a></span>'
        + '</div>'
        + '<div class="hlx-row"><span class="hlx-label">Status</span><span class="hlx-status">' + (isValid ? 'Verified' : 'Unverified') + '</span></div>'
        + '<div class="hlx-sep"></div>'
        + '<div class="hlx-row"><span class="hlx-label">Record</span><span class="hlx-value">' + shortenHash(d.record_id) + '</span></div>'
        + '<div class="hlx-row"><span class="hlx-label">Hash</span><span class="hlx-value">' + shortenHash(d.content_hash) + '</span></div>'
        + '<div class="hlx-row"><span class="hlx-label">Signed</span><span class="hlx-value">' + d.signing_algorithm + '</span></div>'
        + '<div class="hlx-row"><span class="hlx-label">Proof</span><span class="hlx-value">' + d.proof_depth + ' levels</span></div>'
        + '<div class="hlx-row"><span class="hlx-label">Sealed</span><span class="hlx-value">' + (d.timestamp || '').replace('T',' ').substring(0, 19) + '</span></div>'
        + '<div class="hlx-sep"></div>'
        + '<button class="hlx-copy" data-copy="' + d.record_id + '">' + COPY_SVG + ' Copy record ID</button>';

      // Copy button handler
      var copyBtn = card.querySelector('.hlx-copy');
      if (copyBtn) {
        copyBtn.addEventListener('click', function(e) {
          e.stopPropagation();
          copyText(copyBtn.getAttribute('data-copy'), copyBtn);
        });
      }
    };
    xhr.onerror = function() {
      mark.className = 'hlx-mark hlx-mark--invalid';
      mark.title = 'Helios Ledger — could not verify';
    };
    xhr.send();
  }

  // Auto-init: find all script tags and divs with data-record
  function init() {
    // Script tag embeds
    var scripts = document.querySelectorAll('script[data-record]');
    for (var i = 0; i < scripts.length; i++) {
      var s = scripts[i];
      if (s.getAttribute('data-helios-init')) continue;
      s.setAttribute('data-helios-init', '1');
      createBadge(s, s.getAttribute('data-record'));
    }

    // Div/span embeds
    var els = document.querySelectorAll('.' + BADGE_CLASS + '[data-record]');
    for (var j = 0; j < els.length; j++) {
      var el = els[j];
      if (el.getAttribute('data-helios-init')) continue;
      el.setAttribute('data-helios-init', '1');
      createBadge(el, el.getAttribute('data-record'));
    }
  }

  // Run now and on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Expose global API for dynamic badge creation
  window.HeliosBadge = {
    create: function(element, recordId) {
      createBadge(element, recordId);
    },
    verify: function(recordId, callback) {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', API + '/records/' + recordId + '/verify');
      xhr.onload = function() {
        if (xhr.status === 200) {
          try { callback(null, JSON.parse(xhr.responseText)); } catch(e) { callback(e); }
        } else {
          callback(new Error('HTTP ' + xhr.status));
        }
      };
      xhr.onerror = function() { callback(new Error('Network error')); };
      xhr.send();
    }
  };

})();
`;


const ALLOWED_ORIGINS = [
  'https://ai.oooooooooo.se',
  'http://localhost:3000',
  'http://localhost:8080',
];

// ─── Helpers ───────────────────────────────────────────────────────────────

function getAllowedOrigin(request) {
  const o = request.headers.get('Origin');
  // Allow any origin for GET requests (badges, verification)
  // Restrict POST to known origins
  if (request.method === 'GET' && o) return o;
  return o && ALLOWED_ORIGINS.includes(o) ? o : 'https://ai.oooooooooo.se';
}

function corsHeaders(origin) {
  return {
    'Access-Control-Allow-Origin': origin || 'https://ai.oooooooooo.se',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
    'Vary': 'Origin',
  };
}

function jsonR(data, status, origin) {
  return new Response(JSON.stringify(data, null, 2), {
    status: status || 200,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) },
  });
}

function errR(msg, status, origin) {
  return jsonR({ error: msg }, status || 400, origin);
}

async function sha256hex(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

function genToken() {
  const a = new Uint8Array(32);
  crypto.getRandomValues(a);
  return Array.from(a).map(b => b.toString(16).padStart(2, '0')).join('');
}

function heliosSign(privateKeyJwk, data) {
  const key = createPrivateKey({ key: JSON.parse(privateKeyJwk), format: 'jwk' });
  return nodeCryptoSign(null, Buffer.from(data), key).toString('hex');
}

function heliosVerify(publicKeyJwk, data, sigHex) {
  try {
    const key = createPublicKey({ key: JSON.parse(publicKeyJwk), format: 'jwk' });
    return nodeCryptoVerify(null, Buffer.from(data), key, Buffer.from(sigHex, 'hex'));
  } catch { return false; }
}

function verifyUserSignature(publicKeyJwk, contentHash, userSigHex) {
  try {
    const key = createPublicKey({ key: JSON.parse(publicKeyJwk), format: 'jwk' });
    return nodeCryptoVerify(null, Buffer.from(contentHash), key, Buffer.from(userSigHex, 'hex'));
  } catch { return false; }
}

// ─── Auth ──────────────────────────────────────────────────────────────────

async function getAuth(request, db) {
  const raw = (request.headers.get('Authorization') || '').replace('Bearer ', '').trim();
  if (raw.length < 32) return null;
  const hash = await sha256hex(raw);
  return db.prepare('SELECT * FROM accounts WHERE token_hash = ?').bind(hash).first();
}

// ─── Rate limiting ─────────────────────────────────────────────────────────

async function rateCheck(db, key, max, windowSec) {
  const now = Math.floor(Date.now() / 1000);
  const windowStart = now - (now % windowSec);
  const rlKey = key + ':' + windowStart;
  const row = await db.prepare('SELECT count FROM rate_limits WHERE key = ?').bind(rlKey).first();
  const cnt = row ? row.count : 0;
  if (cnt >= max) return false;
  if (row) {
    await db.prepare('UPDATE rate_limits SET count = count + 1 WHERE key = ?').bind(rlKey).run();
  } else {
    await db.batch([
      db.prepare('DELETE FROM rate_limits WHERE key LIKE ? AND key != ?').bind(key + ':%', rlKey),
      db.prepare('INSERT INTO rate_limits (key, count, window_start) VALUES (?, 1, ?)').bind(rlKey, windowStart),
    ]);
  }
  return true;
}

// ─── Incremental Merkle Tree ───────────────────────────────────────────────
//
// Storage: merkle_tree(level, pos, hash)
//   level 0 = leaves, level H = root
//   For n leaves, H = ceil(log2(n))
//
// Insert: write leaf + update O(log n) ancestors
// Proof:  read O(log n) siblings
// Root:   read 1 node at (height, 0)

function treeHeight(n) {
  if (n <= 1) return 0;
  return Math.ceil(Math.log2(n));
}

// Append a new leaf and update the tree incrementally.
// Returns { root, proof } — O(log n) reads + O(log n) writes
async function appendLeaf(db, leafIdx, leafHash) {
  const totalLeaves = leafIdx + 1;
  const height = treeHeight(totalLeaves);

  // Special case: first leaf
  if (height === 0) {
    await db.prepare('INSERT OR REPLACE INTO merkle_tree (level, pos, hash) VALUES (0, 0, ?)')
      .bind(leafHash).run();
    return { root: leafHash, proof: [] };
  }

  // Precompute all sibling positions we need to read
  const siblingReads = [];
  let pos = leafIdx;
  for (let l = 0; l < height; l++) {
    const sibPos = pos ^ 1;
    siblingReads.push(
      db.prepare('SELECT hash FROM merkle_tree WHERE level = ? AND pos = ?').bind(l, sibPos)
    );
    pos = pos >> 1;
  }

  // Batch-read all siblings in one round trip
  const sibResults = await db.batch(siblingReads);

  // Walk up the tree computing parents
  const writes = [];
  const proof = [];
  let currentHash = leafHash;
  pos = leafIdx;

  // Write the leaf node
  writes.push(
    db.prepare('INSERT OR REPLACE INTO merkle_tree (level, pos, hash) VALUES (?, ?, ?)')
      .bind(0, leafIdx, leafHash)
  );

  for (let l = 0; l < height; l++) {
    const isRight = pos % 2 === 1;
    let sibHash = sibResults[l].results?.[0]?.hash || null;

    // No sibling = odd leaf at end of level, duplicates itself
    if (!sibHash) sibHash = currentHash;

    proof.push({
      position: isRight ? 'left' : 'right',
      hash: sibHash,
    });

    // Compute parent hash (left + right)
    const left = isRight ? sibHash : currentHash;
    const right = isRight ? currentHash : sibHash;
    const parentHash = await sha256hex(left + right);

    const parentPos = pos >> 1;
    writes.push(
      db.prepare('INSERT OR REPLACE INTO merkle_tree (level, pos, hash) VALUES (?, ?, ?)')
        .bind(l + 1, parentPos, parentHash)
    );

    currentHash = parentHash;
    pos = parentPos;
  }

  // Batch-write leaf + all ancestors in one round trip
  await db.batch(writes);

  return { root: currentHash, proof };
}

// Get Merkle proof for any existing leaf — O(log n) reads
async function getMerkleProof(db, leafIdx, totalLeaves) {
  if (totalLeaves <= 0) return { root: '0'.repeat(64), proof: [] };
  if (totalLeaves === 1) {
    const leaf = await db.prepare('SELECT hash FROM merkle_tree WHERE level = 0 AND pos = 0').first();
    return { root: leaf?.hash || '0'.repeat(64), proof: [] };
  }

  const height = treeHeight(totalLeaves);

  // Batch-read: sibling at each level + self (fallback) + root
  const queries = [];
  let pos = leafIdx;
  for (let l = 0; l < height; l++) {
    const sibPos = pos ^ 1;
    queries.push(db.prepare('SELECT hash FROM merkle_tree WHERE level = ? AND pos = ?').bind(l, sibPos));
    queries.push(db.prepare('SELECT hash FROM merkle_tree WHERE level = ? AND pos = ?').bind(l, pos));
    pos = pos >> 1;
  }
  // Read root
  queries.push(db.prepare('SELECT hash FROM merkle_tree WHERE level = ? AND pos = 0').bind(height));

  const results = await db.batch(queries);

  const proof = [];
  pos = leafIdx;
  for (let l = 0; l < height; l++) {
    const sibResult = results[l * 2].results?.[0];
    const selfResult = results[l * 2 + 1].results?.[0];
    const isRight = pos % 2 === 1;

    // Sibling exists? Use it. Otherwise duplicate self.
    const sibHash = sibResult?.hash || selfResult?.hash || '0'.repeat(64);

    proof.push({
      position: isRight ? 'left' : 'right',
      hash: sibHash,
    });

    pos = pos >> 1;
  }

  const rootResult = results[results.length - 1].results?.[0];
  const root = rootResult?.hash || '0'.repeat(64);

  return { root, proof };
}

// Get just the root — O(1) read
async function getMerkleRoot(db, totalLeaves) {
  if (totalLeaves <= 0) return '0'.repeat(64);
  const height = treeHeight(totalLeaves);
  const row = await db.prepare('SELECT hash FROM merkle_tree WHERE level = ? AND pos = 0').bind(height).first();
  return row?.hash || '0'.repeat(64);
}

// One-time migration: rebuild full tree from merkle_nodes (old flat table)
// Called automatically if merkle_tree is empty but merkle_nodes has data
async function migrateToIncrementalTree(db) {
  const existing = await db.prepare('SELECT COUNT(*) as cnt FROM merkle_tree').first();
  if (existing.cnt > 0) return false; // already migrated

  const leaves = await db.prepare('SELECT idx, hash FROM merkle_nodes ORDER BY idx ASC').all();
  if (leaves.results.length === 0) return false;

  console.log('Migrating ' + leaves.results.length + ' leaves to incremental Merkle tree...');

  // Insert all leaves as level 0
  const leafWrites = leaves.results.map(r =>
    db.prepare('INSERT OR REPLACE INTO merkle_tree (level, pos, hash) VALUES (0, ?, ?)').bind(r.idx, r.hash)
  );

  // Batch in chunks of 50 (D1 batch limit considerations)
  for (let i = 0; i < leafWrites.length; i += 50) {
    await db.batch(leafWrites.slice(i, i + 50));
  }

  // Build internal levels
  let currentLevel = leaves.results.map(r => r.hash);
  let level = 0;

  while (currentLevel.length > 1) {
    const nextLevel = [];
    const writes = [];

    for (let i = 0; i < currentLevel.length; i += 2) {
      const left = currentLevel[i];
      const right = (i + 1 < currentLevel.length) ? currentLevel[i + 1] : currentLevel[i];
      const parentHash = await sha256hex(left + right);
      nextLevel.push(parentHash);
      writes.push(
        db.prepare('INSERT OR REPLACE INTO merkle_tree (level, pos, hash) VALUES (?, ?, ?)')
          .bind(level + 1, Math.floor(i / 2), parentHash)
      );
    }

    // Batch write this level
    for (let i = 0; i < writes.length; i += 50) {
      await db.batch(writes.slice(i, i + 50));
    }

    currentLevel = nextLevel;
    level++;
  }

  console.log('Migration complete. Tree height: ' + level + ', root: ' + currentLevel[0].substring(0, 16) + '...');
  return true;
}

// ─── Route handlers ────────────────────────────────────────────────────────

async function handleHealth(env, origin) {
  const meta = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const treeCount = await env.DB.prepare('SELECT COUNT(*) as cnt FROM merkle_tree WHERE level = 0').first();
  return jsonR({
    status: 'ok',
    service: 'helios-ledger',
    version: VERSION,
    record_count: parseInt(meta?.value || '0'),
    tree_nodes: treeCount?.cnt || 0,
    merkle_engine: 'incremental',
    timestamp: new Date().toISOString(),
  }, 200, origin);
}

async function handlePubkey(env, origin) {
  return jsonR({
    algorithm: 'Ed25519',
    public_key: env.SIGNING_PUBLIC_KEY ? JSON.parse(env.SIGNING_PUBLIC_KEY) : null,
    note: 'Use this key to independently verify any Helios signature.',
  }, 200, origin);
}

async function handleKeygen(origin) {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const privJwk = privateKey.export({ format: 'jwk' });
  const pubJwk = publicKey.export({ format: 'jwk' });
  return jsonR({
    private_key: privJwk,
    public_key: { kty: pubJwk.kty, crv: pubJwk.crv, x: pubJwk.x },
    warning: 'Store your private key securely. Never share it.',
    usage: {
      step1: 'Save public_key in your account: POST /api/v1/accounts with { public_key: <this> }',
      step2: 'Sign the SHA-256 hex hash of your content with your private key',
      step3: 'Submit record with { content, user_signature: <hex sig> }',
      step4: 'Helios verifies your signature and sets user_verified: true',
    },
  }, 200, origin);
}

async function handleCreateAccount(req, env, origin) {
  const ip = req.headers.get('CF-Connecting-IP') || 'unknown';
  if (!await rateCheck(env.DB, 'acct:' + ip, RATE_MAX_ACCT, RATE_WINDOW_ACCT))
    return errR('Rate limit exceeded. Max 10 accounts per IP per hour.', 429, origin);

  let body;
  try { body = await req.json(); } catch { return errR('Invalid JSON', 400, origin); }

  const { username, public_key } = body;
  if (!username || typeof username !== 'string' || username.length < 3 ||
      username.length > MAX_USERNAME_LEN || !/^[a-zA-Z0-9_-]+$/.test(username))
    return errR('Invalid username. 3-32 chars, alphanumeric/underscore/hyphen only.', 400, origin);

  if (await env.DB.prepare('SELECT id FROM accounts WHERE username = ?').bind(username).first())
    return errR('Username already taken.', 409, origin);

  const id = crypto.randomUUID();
  const rawToken = genToken();
  const tokHash = await sha256hex(rawToken);
  const now = new Date().toISOString();

  let pubKeyStr = null;
  if (public_key) {
    try {
      const jwk = typeof public_key === 'string' ? JSON.parse(public_key) : public_key;
      if (jwk.kty !== 'OKP' || jwk.crv !== 'Ed25519')
        return errR('public_key must be an Ed25519 JWK', 400, origin);
      pubKeyStr = JSON.stringify(jwk);
    } catch { return errR('Invalid public_key format', 400, origin); }
  }

  await env.DB.prepare(
    'INSERT INTO accounts (id, username, public_key, token_hash, balance, created_at) VALUES (?,?,?,?,0,?)'
  ).bind(id, username, pubKeyStr, tokHash, now).run();

  if (!env.SIGNING_PRIVATE_KEY) return errR('Server signing key not configured', 500, origin);

  const acctEvent = JSON.stringify({ event: 'account_created', account_id: id, username, timestamp: now });
  const contentHash = await sha256hex(acctEvent);
  const recordId = crypto.randomUUID();
  const sigPayload = JSON.stringify({ id: recordId, content_hash: contentHash, model: 'system', timestamp: now, account_id: id });
  const signature = heliosSign(env.SIGNING_PRIVATE_KEY, sigPayload);

  const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const leafIdx = parseInt(countRow?.value || '0');

  await env.DB.batch([
    env.DB.prepare('INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp) VALUES (?,?,?,?,?,?,?,?)')
      .bind(recordId, contentHash, signature, 'system', 'account_creation', id, leafIdx, now),
    env.DB.prepare('INSERT OR IGNORE INTO merkle_nodes (idx, hash) VALUES (?,?)').bind(leafIdx, contentHash),
    env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").bind(String(leafIdx + 1)),
  ]);

  // Incremental Merkle update — O(log n)
  const { root, proof } = await appendLeaf(env.DB, leafIdx, contentHash);
  await env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").bind(root).run();

  return jsonR({
    id, username,
    token: rawToken,
    public_key: pubKeyStr ? JSON.parse(pubKeyStr) : null,
    created_at: now,
    warning: 'Save your token -- it cannot be recovered.',
    chain_record: {
      record_id: recordId,
      content_hash: contentHash,
      merkle_index: leafIdx,
      merkle_root: root,
      note: 'Your account creation is now permanently sealed on the Helios ledger.',
    },
  }, 201, origin);
}

async function handleSubmitRecord(req, env, origin) {
  let account;
  try { account = await getAuth(req, env.DB); }
  catch (e) { return errR('E:auth:' + e.message, 500, origin); }
  if (!account) return errR('Unauthorized', 401, origin);

  try {
    if (!await rateCheck(env.DB, 'rec:' + account.id, RATE_MAX_REC, RATE_WINDOW_REC))
      return errR('Rate limit exceeded. Max 100 records per minute per account.', 429, origin);
  } catch (e) { return errR('E:rate:' + e.message, 500, origin); }

  if (!env.SIGNING_PRIVATE_KEY) return errR('Server signing key not configured', 500, origin);

  let body;
  try { body = await req.json(); } catch { return errR('Invalid JSON', 400, origin); }

  const { content, model, context, user_signature } = body;
  if (!content || typeof content !== 'string') return errR('content is required', 400, origin);
  if (new TextEncoder().encode(content).length > MAX_CONTENT_BYTES)
    return errR('Content too large. Maximum is ' + MAX_CONTENT_BYTES + ' bytes.', 413, origin);

  let contentHash;
  try { contentHash = await sha256hex(content); }
  catch (e) { return errR('E:hash:' + e.message, 500, origin); }

  let userVerified = false;
  if (user_signature) {
    if (!account.public_key)
      return errR('user_signature provided but account has no public_key.', 400, origin);
    userVerified = verifyUserSignature(account.public_key, contentHash, user_signature);
    if (!userVerified) return errR('user_signature is invalid.', 400, origin);
  }

  let dupe = null;
  try { dupe = await env.DB.prepare('SELECT id FROM records WHERE content_hash = ?').bind(contentHash).first(); }
  catch (e) { return errR('E:dupe:' + e.message, 500, origin); }

  try {
    const id = crypto.randomUUID();
    const now = new Date().toISOString();
    const sigPayload = JSON.stringify({
      id, content_hash: contentHash, model: model || null,
      timestamp: now, account_id: account.id,
    });
    const signature = heliosSign(env.SIGNING_PRIVATE_KEY, sigPayload);

    const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
    const leafIdx = parseInt(countRow?.value || '0');

    await env.DB.batch([
      env.DB.prepare('INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp) VALUES (?,?,?,?,?,?,?,?)')
        .bind(id, contentHash, signature, model || null, context || null, account.id, leafIdx, now),
      env.DB.prepare('UPDATE accounts SET balance = MIN(balance + 1, ?) WHERE id = ?').bind(MAX_BALANCE, account.id),
      env.DB.prepare('INSERT OR IGNORE INTO merkle_nodes (idx, hash) VALUES (?,?)').bind(leafIdx, contentHash),
      env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").bind(String(leafIdx + 1)),
    ]);

    // Incremental Merkle update — O(log n) instead of O(n)!
    let root, proof;
    try {
      const mp = await appendLeaf(env.DB, leafIdx, contentHash);
      root = mp.root;
      proof = mp.proof;
    } catch (e) { return errR('E:merkle:' + e.message, 500, origin); }

    try {
      await env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").bind(root).run();
    } catch (e) { return errR('E:rootupd:' + e.message, 500, origin); }

    return jsonR({
      id, content_hash: contentHash, signature,
      signing_algorithm: 'Ed25519',
      user_verified: userVerified,
      merkle_index: leafIdx,
      merkle_root: root,
      merkle_proof: proof,
      model: model || null,
      context: context || null,
      timestamp: now,
      duplicate_of: dupe ? dupe.id : null,
    }, 201, origin);

  } catch (e) { return errR('E:submit:' + e.message, 500, origin); }
}

async function handleGetRecord(id, env, origin) {
  const r = await env.DB.prepare(
    'SELECT id, content_hash, signature, model, context, account_id, merkle_index, timestamp FROM records WHERE id = ?'
  ).bind(id).first();
  if (!r) return errR('Record not found', 404, origin);
  return jsonR(r, 200, origin);
}

async function handleVerifyRecord(id, env, origin) {
  const r = await env.DB.prepare('SELECT * FROM records WHERE id = ?').bind(id).first();
  if (!r) return errR('Record not found', 404, origin);

  const sigPayload = JSON.stringify({
    id: r.id, content_hash: r.content_hash, model: r.model,
    timestamp: r.timestamp, account_id: r.account_id,
  });

  let valid = false;
  if (env.SIGNING_PUBLIC_KEY) {
    try { valid = heliosVerify(env.SIGNING_PUBLIC_KEY, sigPayload, r.signature); }
    catch { valid = false; }
  }

  const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const totalLeaves = parseInt(countRow?.value || '0');

  // O(log n) proof generation
  const { root, proof } = await getMerkleProof(env.DB, r.merkle_index, totalLeaves);

  return jsonR({
    record_id: r.id, valid, signing_algorithm: 'Ed25519',
    content_hash: r.content_hash, signature: r.signature,
    merkle_index: r.merkle_index, merkle_root: root,
    merkle_proof: proof, proof_depth: proof.length,
    timestamp: r.timestamp,
    how_to_verify: 'GET /api/v1/pubkey for the Ed25519 public key.',
  }, 200, origin);
}

async function handleLedgerRoot(env, origin) {
  const root = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='root'").first();
  const count = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  return jsonR({
    root: root?.value, record_count: parseInt(count?.value || '0'),
    timestamp: new Date().toISOString(),
  }, 200, origin);
}

async function handleLedgerProof(id, env, origin) {
  const r = await env.DB.prepare('SELECT merkle_index FROM records WHERE id = ?').bind(id).first();
  if (!r) return errR('Record not found', 404, origin);

  const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const totalLeaves = parseInt(countRow?.value || '0');

  const { root, proof } = await getMerkleProof(env.DB, r.merkle_index, totalLeaves);
  return jsonR({ record_id: id, merkle_index: r.merkle_index, merkle_root: root, proof }, 200, origin);
}

async function handleLedgerRecent(env, origin) {
  const rows = await env.DB.prepare(
    'SELECT id, content_hash, model, context, merkle_index, timestamp FROM records ORDER BY merkle_index DESC LIMIT 20'
  ).all();
  return jsonR({ records: rows.results }, 200, origin);
}

async function handleMigrate(env, origin) {
  const migrated = await migrateToIncrementalTree(env.DB);
  if (migrated) {
    // Verify root matches
    const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
    const totalLeaves = parseInt(countRow?.value || '0');
    const newRoot = await getMerkleRoot(env.DB, totalLeaves);
    const storedRoot = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='root'").first();
    return jsonR({
      status: 'migrated',
      leaves: totalLeaves,
      tree_height: treeHeight(totalLeaves),
      computed_root: newRoot,
      stored_root: storedRoot?.value,
      roots_match: newRoot === storedRoot?.value,
    }, 200, origin);
  }
  return jsonR({ status: 'already_migrated' }, 200, origin);
}

// ─── Main router ───────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url    = new URL(request.url);
    const method = request.method;
    const origin = getAllowedOrigin(request);

    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: {
        ...corsHeaders(origin),
        'Access-Control-Allow-Origin': request.headers.get('Origin') || '*',
      }});
    }

    const p = url.pathname
      .replace(/^\/api\/v1\//, '/api/')
      .replace(/^\/api\/v1$/, '/api');

    try {
      if (method === 'GET' && p === '/api/health')       return await handleHealth(env, origin);
      if (method === 'GET' && p === '/api/pubkey')        return await handlePubkey(env, origin);
      if (method === 'GET' && p === '/api/keygen')        return await handleKeygen(origin);
      if (method === 'POST' && p === '/api/accounts')     return await handleCreateAccount(request, env, origin);
      if (method === 'POST' && p === '/api/records')      return await handleSubmitRecord(request, env, origin);
      if (method === 'GET' && p === '/api/ledger/root')   return await handleLedgerRoot(env, origin);
      if (method === 'GET' && p === '/api/ledger/recent') return await handleLedgerRecent(env, origin);
      if (method === 'POST' && p === '/api/migrate')      return await handleMigrate(env, origin);

      const recM = p.match(/^\/api\/records\/([^/]+)$/);
      if (method === 'GET' && recM) return await handleGetRecord(recM[1], env, origin);

      const verM = p.match(/^\/api\/records\/([^/]+)\/verify$/);
      if (method === 'GET' && verM) return await handleVerifyRecord(verM[1], env, origin);

      const prfM = p.match(/^\/api\/ledger\/proof\/([^/]+)$/);
      if (method === 'GET' && prfM) return await handleLedgerProof(prfM[1], env, origin);

      // Badge embed script
      if (method === 'GET' && (url.pathname === '/badge.js' || p === '/api/badge.js')) {
        return new Response(BADGE_JS, {
          status: 200,
          headers: {
            'Content-Type': 'application/javascript; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'public, max-age=3600',
          },
        });
      }

      return errR('Not found', 404, origin);
    } catch (e) {
      console.error('Unhandled worker error:', e.message, e.stack);
      return errR('Internal server error: ' + e.message, 500, origin);
    }
  },
};
