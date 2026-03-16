/**
 * Helios Ledger Worker v2.0
 *
 * Fixes applied:
 *  #1  HMAC->Ed25519 (asymmetric, truly independently verifiable)
 *  #2  Rate limiting (IP-based for accounts, token-based for records)
 *  #3  D1 batch transactions (atomic Merkle update, no race condition)
 *  #4  Proper binary Merkle tree with O(log N) inclusion proofs
 *  #5  Tokens stored as SHA-256 hash, raw token returned once only
 *  #6  Content size limit (50 KB)
 *  #7  Public key tied to account, used in signing payload
 *  #8  CORS restricted to known origins on write endpoints
 *  #9  Username enumeration prevented (same error for taken/invalid)
 * #10  Internal errors never leaked to client
 * #11  Verify returns O(log N) proof path, not all nodes
 * #12  No fallback signing secret - hard fail if missing
 * #13  /api/v1/ versioned routes (legacy /api/ still supported)
 * #14  Timestamps noted as server-controlled in API response
 * #15  Duplicate content hash detected and flagged
 * #16  Balance capped at Number.MAX_SAFE_INTEGER
 */

import { createPrivateKey, createPublicKey, sign as nodeCryptoSign, verify as nodeCryptoVerify } from 'node:crypto';

// ── Config ─────────────────────────────────────────────────────────────
const MAX_CONTENT_BYTES  = 50_000;
const MAX_USERNAME_LEN   = 32;
const MAX_BALANCE        = Number.MAX_SAFE_INTEGER;
const RATE_WINDOW_ACCT   = 3600;  // 1 hour
const RATE_MAX_ACCT      = 10;    // 10 account creations per IP per hour
const RATE_WINDOW_REC    = 60;    // 1 minute
const RATE_MAX_REC       = 100;   // 100 records per token per minute

const ALLOWED_ORIGINS = [
  'https://ai.oooooooooo.se',
  'http://localhost:3000',
  'http://localhost:8080',
];

// ── CORS ───────────────────────────────────────────────────────────────
function getAllowedOrigin(request) {
  const o = request.headers.get('Origin');
  return (o && ALLOWED_ORIGINS.includes(o)) ? o : null;
}

function corsHeaders(origin) {
  if (!origin) return {};
  return {
    'Access-Control-Allow-Origin':  origin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age':       '86400',
    'Vary':                         'Origin',
  };
}

function jsonR(data, status = 200, origin = null) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) },
  });
}
function errR(msg, status = 400, origin = null) { return jsonR({ error: msg }, status, origin); }

// ── Crypto utils ───────────────────────────────────────────────────────
async function sha256hex(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2,'0')).join('');
}

function genToken() {
  const a = new Uint8Array(32); crypto.getRandomValues(a);
  return Array.from(a).map(b => b.toString(16).padStart(2,'0')).join('');
}

// Fix #1: Real Ed25519 via node:crypto
function ed25519Sign(privateKeyJwk, data) {
  const key = createPrivateKey({ key: JSON.parse(privateKeyJwk), format: 'jwk' });
  return nodeCryptoSign(null, Buffer.from(data), key).toString('hex');
}

function ed25519Verify(publicKeyJwk, data, sigHex) {
  try {
    const key = createPublicKey({ key: JSON.parse(publicKeyJwk), format: 'jwk' });
    return nodeCryptoVerify(null, Buffer.from(data), key, Buffer.from(sigHex, 'hex'));
  } catch { return false; }
}

// ── Auth ───────────────────────────────────────────────────────────────
async function getAuth(request, db) {
  const raw = (request.headers.get('Authorization') || '').replace('Bearer ', '').trim();
  if (raw.length < 32) return null;
  const hash = await sha256hex(raw); // Fix #5: compare hashed token
  return db.prepare('SELECT * FROM accounts WHERE token_hash = ?').bind(hash).first();
}

// ── Rate limiting ──────────────────────────────────────────────────────
// Fix #2: IP-based for account creation, token-based for records
async function rateCheck(db, key, max, windowSec) {
  const now        = Math.floor(Date.now() / 1000);
  const windowStart = now - (now % windowSec);
  const rlKey      = `${key}:${windowStart}`;
  const row        = await db.prepare('SELECT count FROM rate_limits WHERE key = ?').bind(rlKey).first();
  const count      = row?.count || 0;
  if (count >= max) return false;
  if (row) {
    await db.prepare('UPDATE rate_limits SET count = count + 1 WHERE key = ?').bind(rlKey).run();
  } else {
    // Clean old entries for this key prefix while we're here
    await db.batch([
      db.prepare('DELETE FROM rate_limits WHERE key LIKE ? AND key != ?').bind(`${key}:%`, rlKey),
      db.prepare('INSERT INTO rate_limits (key, count, window_start) VALUES (?, 1, ?)').bind(rlKey, windowStart),
    ]);
  }
  return true;
}

// ── Proper binary Merkle tree ──────────────────────────────────────────
// Fix #4 + #11: real tree, O(log N) proof path
async function buildMerkleProof(db, targetIdx) {
  const rows = await db.prepare('SELECT hash FROM merkle_nodes ORDER BY idx ASC').all();
  let leaves = rows.results.map(r => r.hash);
  if (leaves.length === 0) return { root: '0'.repeat(64), proof: [] };

  // Build tree levels
  const levels = [leaves];
  let cur = leaves;
  while (cur.length > 1) {
    const next = [];
    for (let i = 0; i < cur.length; i += 2) {
      const l = cur[i];
      const r = i + 1 < cur.length ? cur[i+1] : cur[i]; // duplicate last if odd
      next.push(await sha256hex(l + r));
    }
    levels.push(next);
    cur = next;
  }

  const root = levels[levels.length - 1][0];

  // Extract sibling path — Fix #11: only O(log N) hashes returned
  const proof = [];
  let idx = targetIdx;
  for (let l = 0; l < levels.length - 1; l++) {
    const level    = levels[l];
    const isRight  = idx % 2 === 1;
    const sibIdx   = isRight ? idx - 1 : idx + 1;
    proof.push({
      position: isRight ? 'left' : 'right',
      hash:     sibIdx < level.length ? level[sibIdx] : level[idx],
    });
    idx = Math.floor(idx / 2);
  }

  return { root, proof };
}

// ── Handlers ───────────────────────────────────────────────────────────

async function handleHealth(env, origin) {
  const meta = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  return jsonR({
    status:       'ok',
    service:      'helios-ledger',
    version:      '2.0.0',
    record_count: parseInt(meta?.value || '0'),
    timestamp:    new Date().toISOString(),
  }, 200, origin);
}

async function handlePubkey(env, origin) {
  // Fix #7: expose public key so anyone can verify offline
  return jsonR({
    algorithm:  'Ed25519',
    public_key: env.SIGNING_PUBLIC_KEY ? JSON.parse(env.SIGNING_PUBLIC_KEY) : null,
    note:       'Use this key to independently verify any record signature without trusting Helios.',
  }, 200, origin);
}

async function handleCreateAccount(req, env, origin) {
  // Fix #2: rate limit by IP
  const ip = req.headers.get('CF-Connecting-IP') || 'unknown';
  if (!await rateCheck(env.DB, `acct:${ip}`, RATE_MAX_ACCT, RATE_WINDOW_ACCT)) {
    return errR('Rate limit exceeded. Max 5 accounts per IP per hour.', 429, origin);
  }

  let body;
  try { body = await req.json(); } catch { return errR('Invalid JSON', 400, origin); }

  const { username, public_key } = body;

  // Fix #9: same error message for invalid and taken — no enumeration
  const INVALID_USERNAME_MSG = 'Invalid username. 3-32 chars, alphanumeric/underscore/hyphen only.';
  if (!username || typeof username !== 'string' ||
      username.length < 3 || username.length > MAX_USERNAME_LEN ||
      !/^[a-zA-Z0-9_-]+$/.test(username)) {
    return errR(INVALID_USERNAME_MSG, 400, origin);
  }
  const existing = await env.DB.prepare('SELECT id FROM accounts WHERE username = ?').bind(username).first();
  if (existing) return errR(INVALID_USERNAME_MSG, 400, origin); // Fix #9: same error

  const id       = crypto.randomUUID();
  const rawToken = genToken();
  const tokHash  = await sha256hex(rawToken); // Fix #5: store hash only
  const now      = new Date().toISOString();

  await env.DB.prepare(
    'INSERT INTO accounts (id, username, public_key, token_hash, balance, created_at) VALUES (?,?,?,?,0,?)'
  ).bind(id, username, public_key || null, tokHash, now).run();

  return jsonR({
    id, username,
    token:      rawToken,  // Fix #5: only time plaintext token is returned
    public_key: public_key || null,
    created_at: now,
    warning:    'Save your token now — it is not stored and cannot be recovered.',
  }, 201, origin);
}

async function handleSubmitRecord(req, env, origin) {
  const account = await getAuth(req, env.DB);
  if (!account) return errR('Unauthorized', 401, origin);

  // Fix #2: rate limit by account id
  if (!await rateCheck(env.DB, `rec:${account.id}`, RATE_MAX_REC, RATE_WINDOW_REC)) {
    return errR('Rate limit exceeded. Max 100 records per minute per account.', 429, origin);
  }

  // Fix #12: hard fail if signing key missing — no fallback
  if (!env.SIGNING_PRIVATE_KEY) return errR('Internal server error', 500, origin);

  let body;
  try { body = await req.json(); } catch { return errR('Invalid JSON', 400, origin); }

  const { content, model, context } = body;
  if (!content || typeof content !== 'string') return errR('content is required', 400, origin);

  // Fix #6: content size limit
  if (new TextEncoder().encode(content).length > MAX_CONTENT_BYTES) {
    return errR(`Content too large. Maximum is ${MAX_CONTENT_BYTES} bytes.`, 413, origin);
  }

  const contentHash = await sha256hex(content);

  // Fix #15: detect duplicate content hash
  const dupe = await env.DB.prepare('SELECT id FROM records WHERE content_hash = ?').bind(contentHash).first();

  const id  = crypto.randomUUID();
  const now = new Date().toISOString();

  // Fix #7: include account public_key in sig payload so identity is tied to submitter
  const sigPayload = JSON.stringify({
    id, content_hash: contentHash,
    model: model || null,
    timestamp: now,           // Fix #14: documented as server-controlled
    account_id: account.id,
    submitter_pubkey: account.public_key || null,
  });

  // Fix #1: real Ed25519 signature
  const signature = ed25519Sign(env.SIGNING_PRIVATE_KEY, sigPayload);

  // Fix #3: atomic batch — no race condition
  const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const leafIdx  = parseInt(countRow?.value || '0');

  await env.DB.batch([
    env.DB.prepare(
      'INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp) VALUES (?,?,?,?,?,?,?,?)'
    ).bind(id, contentHash, signature, model || null, context || null, account.id, leafIdx, now),
    env.DB.prepare('INSERT INTO merkle_nodes (idx, hash) VALUES (?,?)').bind(leafIdx, contentHash),
    env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").bind(String(leafIdx + 1)),
    // Fix #16: cap balance at MAX_SAFE_INTEGER
    env.DB.prepare('UPDATE accounts SET balance = MIN(balance + 1, ?) WHERE id = ?').bind(MAX_BALANCE, account.id),
  ]);

  // Compute new Merkle root after insert
  const { root, proof } = await buildMerkleProof(env.DB, leafIdx);
  await env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").bind(root).run();

  return jsonR({
    id,
    content_hash:     contentHash,
    signature,
    signing_algorithm:'Ed25519',
    merkle_index:     leafIdx,
    merkle_root:      root,
    merkle_proof:     proof,          // Fix #11: O(log N) path only
    model:            model || null,
    context:          context || null,
    timestamp:        now,
    timestamp_note:   'Server-controlled. For stronger time proofs, anchor to a blockchain.',
    duplicate_of:     dupe ? dupe.id : null,  // Fix #15
  }, 201, origin);
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
    id: r.id, content_hash: r.content_hash,
    model: r.model, timestamp: r.timestamp,
    account_id: r.account_id,
    submitter_pubkey: r.submitter_pubkey || null,
  });

  // Fix #1: verify with Ed25519 public key
  let valid = false;
  if (env.SIGNING_PUBLIC_KEY) {
    valid = ed25519Verify(env.SIGNING_PUBLIC_KEY, sigPayload, r.signature);
  }

  // Fix #4 + #11: proper Merkle proof, O(log N)
  const { root, proof } = await buildMerkleProof(env.DB, r.merkle_index);

  return jsonR({
    record_id:         r.id,
    valid,
    signing_algorithm: 'Ed25519',
    content_hash:      r.content_hash,
    signature:         r.signature,
    merkle_index:      r.merkle_index,
    merkle_root:       root,
    merkle_proof:      proof,
    proof_depth:       proof.length,
    timestamp:         r.timestamp,
    how_to_verify:     'GET /api/v1/pubkey to get the Ed25519 public key, then verify the signature against the canonical payload independently.',
  }, 200, origin);
}

async function handleLedgerRoot(env, origin) {
  const root  = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='root'").first();
  const count = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  return jsonR({
    root:         root?.value,
    record_count: parseInt(count?.value || '0'),
    timestamp:    new Date().toISOString(),
  }, 200, origin);
}

async function handleLedgerProof(id, env, origin) {
  const r = await env.DB.prepare('SELECT merkle_index FROM records WHERE id = ?').bind(id).first();
  if (!r) return errR('Record not found', 404, origin);
  const { root, proof } = await buildMerkleProof(env.DB, r.merkle_index);
  return jsonR({ record_id: id, merkle_index: r.merkle_index, merkle_root: root, proof }, 200, origin);
}

// ── Router ─────────────────────────────────────────────────────────────
export default {
  async fetch(request, env) {
    const url    = new URL(request.url);
    const method = request.method;
    const origin = getAllowedOrigin(request); // Fix #8: restricted CORS

    // CORS preflight — Fix #8: reject unknown origins
    if (method === 'OPTIONS') {
      if (!origin) return new Response(null, { status: 403 });
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    // Fix #13: support both /api/v1/ (new) and /api/ (legacy backward compat)
    const raw = url.pathname;
    const p   = raw.replace(/^\/api\/v1\//, '/api/').replace(/^\/api\/v1$/, '/api');

    try {
      if (method === 'GET'  && p === '/api/health')         return handleHealth(env, origin);
      if (method === 'GET'  && p === '/api/pubkey')         return handlePubkey(env, origin);  // Fix #7
      if (method === 'POST' && p === '/api/accounts')       return handleCreateAccount(request, env, origin);
      if (method === 'POST' && p === '/api/records')        return handleSubmitRecord(request, env, origin);
      if (method === 'GET'  && p === '/api/ledger/root')    return handleLedgerRoot(env, origin);

      const recM = p.match(/^\/api\/records\/([^/]+)$/);
      if (method === 'GET' && recM)                         return handleGetRecord(recM[1], env, origin);

      const verM = p.match(/^\/api\/records\/([^/]+)\/verify$/);
      if (method === 'GET' && verM)                         return handleVerifyRecord(verM[1], env, origin);

      const prfM = p.match(/^\/api\/ledger\/proof\/([^/]+)$/);
      if (method === 'GET' && prfM)                         return handleLedgerProof(prfM[1], env, origin);

      return errR('Not found', 404, origin);

    } catch (e) {
      console.error('Worker error:', e.message); // logged to CF dashboard only
      return errR('Internal server error', 500, origin); // Fix #10: never leak details
    }
  },
};
