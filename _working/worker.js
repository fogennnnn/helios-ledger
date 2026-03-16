/**
 * Helios Ledger — Cloudflare Worker API
 * Database: D1 (helios-ledger)
 * Crypto:   Web Crypto API (SHA-256 hashing + HMAC signing)
 *
 * Routes:
 *   GET  /api/health
 *   POST /api/accounts
 *   POST /api/records
 *   GET  /api/records/:id
 *   GET  /api/records/:id/verify
 *   GET  /api/ledger/root
 *   GET  /api/ledger/proof/:id
 */

// ── Helpers ────────────────────────────────────────────────────────

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}

function err(msg, status = 400) {
  return json({ error: msg }, status);
}

function uid() {
  return crypto.randomUUID();
}

function token() {
  const arr = new Uint8Array(32);
  crypto.getRandomValues(arr);
  return Array.from(arr).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function sha256hex(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function hmacSign(secret, data) {
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', keyMaterial, new TextEncoder().encode(data));
  return Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function hmacVerify(secret, data, sigHex) {
  const expected = await hmacSign(secret, data);
  return expected === sigHex;
}

function merkleParent(left, right) {
  // Simplified Merkle parent hash
  return sha256hex(left + right);
}

async function getAuth(request, db) {
  const auth = request.headers.get('Authorization') || '';
  const tok = auth.replace('Bearer ', '').trim();
  if (!tok) return null;
  const row = await db.prepare('SELECT * FROM accounts WHERE token = ?').bind(tok).first();
  return row || null;
}

async function updateMerkleRoot(db, recordId, contentHash) {
  // Append new leaf and recompute root (simplified linear chain)
  const meta = await db.prepare("SELECT value FROM ledger_meta WHERE key = 'record_count'").first();
  const count = parseInt(meta?.value || '0');
  const leafIdx = count;

  // Store leaf
  await db.prepare('INSERT INTO merkle_nodes (idx, hash) VALUES (?, ?)').bind(leafIdx, contentHash).run();

  // Update record with merkle_index
  await db.prepare('UPDATE records SET merkle_index = ? WHERE id = ?').bind(leafIdx, recordId).run();

  // Recompute root: hash chain of all leaves
  const leaves = await db.prepare('SELECT hash FROM merkle_nodes ORDER BY idx ASC').all();
  let root = leaves.results[0].hash;
  for (let i = 1; i < leaves.results.length; i++) {
    root = await sha256hex(root + leaves.results[i].hash);
  }

  await db.prepare("UPDATE ledger_meta SET value = ? WHERE key = 'root'").bind(root).run();
  await db.prepare("UPDATE ledger_meta SET value = ? WHERE key = 'record_count'").bind(String(count + 1)).run();

  return { leafIdx, root };
}

// ── Route handlers ─────────────────────────────────────────────────

async function handleHealth(env) {
  const meta = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key = 'record_count'").first();
  return json({
    status: 'ok',
    service: 'helios-ledger',
    version: '1.0.0',
    record_count: parseInt(meta?.value || '0'),
    timestamp: new Date().toISOString(),
  });
}

async function handleCreateAccount(request, env) {
  let body;
  try { body = await request.json(); } catch { return err('Invalid JSON'); }

  const { username, public_key } = body;
  if (!username || typeof username !== 'string' || username.length < 3) {
    return err('username must be at least 3 characters');
  }

  const existing = await env.DB.prepare('SELECT id FROM accounts WHERE username = ?').bind(username).first();
  if (existing) return err('Username already taken', 409);

  const id  = uid();
  const tok = token();
  const now = new Date().toISOString();

  await env.DB.prepare(
    'INSERT INTO accounts (id, username, public_key, token, balance, created_at) VALUES (?, ?, ?, ?, 0, ?)'
  ).bind(id, username, public_key || '', tok, now).run();

  return json({ id, username, token: tok, created_at: now }, 201);
}

async function handleSubmitRecord(request, env) {
  const account = await getAuth(request, env.DB);
  if (!account) return err('Unauthorized — include Authorization: Bearer <token>', 401);

  let body;
  try { body = await request.json(); } catch { return err('Invalid JSON'); }

  const { content, model, context } = body;
  if (!content || typeof content !== 'string') return err('content is required');

  const id           = uid();
  const contentHash  = await sha256hex(content);
  const now          = new Date().toISOString();
  const sigPayload   = JSON.stringify({ id, content_hash: contentHash, timestamp: now, account_id: account.id });
  const signature    = await hmacSign(env.SIGNING_SECRET || 'helios-default-secret', sigPayload);

  await env.DB.prepare(
    'INSERT INTO records (id, content_hash, signature, model, context, account_id, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)'
  ).bind(id, contentHash, signature, model || null, context || null, account.id, now).run();

  const { leafIdx, root } = await updateMerkleRoot(env.DB, id, contentHash);

  // Reward submitter
  await env.DB.prepare('UPDATE accounts SET balance = balance + 1 WHERE id = ?').bind(account.id).run();

  return json({
    id,
    content_hash: contentHash,
    signature,
    merkle_index: leafIdx,
    merkle_root: root,
    model: model || null,
    context: context || null,
    timestamp: now,
  }, 201);
}

async function handleGetRecord(id, env) {
  const record = await env.DB.prepare('SELECT * FROM records WHERE id = ?').bind(id).first();
  if (!record) return err('Record not found', 404);
  return json(record);
}

async function handleVerifyRecord(id, env) {
  const record = await env.DB.prepare('SELECT * FROM records WHERE id = ?').bind(id).first();
  if (!record) return err('Record not found', 404);

  const sigPayload = JSON.stringify({
    id: record.id,
    content_hash: record.content_hash,
    timestamp: record.timestamp,
    account_id: record.account_id,
  });

  const valid = await hmacVerify(
    env.SIGNING_SECRET || 'helios-default-secret',
    sigPayload,
    record.signature
  );

  // Build merkle proof (simplified: just the chain hashes either side of the leaf)
  const allLeaves = await env.DB.prepare('SELECT hash FROM merkle_nodes ORDER BY idx ASC').all();
  const merkleProof = allLeaves.results.map((r, i) => ({ index: i, hash: r.hash }));

  return json({
    record_id: id,
    valid,
    content_hash: record.content_hash,
    signature: record.signature,
    merkle_index: record.merkle_index,
    merkle_proof: merkleProof,
    timestamp: record.timestamp,
  });
}

async function handleLedgerRoot(env) {
  const root  = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key = 'root'").first();
  const count = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key = 'record_count'").first();
  return json({
    root: root?.value,
    record_count: parseInt(count?.value || '0'),
    timestamp: new Date().toISOString(),
  });
}

async function handleLedgerProof(id, env) {
  const record = await env.DB.prepare('SELECT merkle_index FROM records WHERE id = ?').bind(id).first();
  if (!record) return err('Record not found', 404);

  const allLeaves = await env.DB.prepare('SELECT idx, hash FROM merkle_nodes ORDER BY idx ASC').all();
  return json({
    record_id: id,
    merkle_index: record.merkle_index,
    proof: allLeaves.results,
  });
}

// ── Main fetch handler ─────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url    = new URL(request.url);
    const path   = url.pathname;
    const method = request.method;

    // CORS preflight
    if (method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    try {
      // GET /api/health
      if (method === 'GET' && path === '/api/health') return handleHealth(env);

      // POST /api/accounts
      if (method === 'POST' && path === '/api/accounts') return handleCreateAccount(request, env);

      // POST /api/records
      if (method === 'POST' && path === '/api/records') return handleSubmitRecord(request, env);

      // GET /api/records/:id
      const recordMatch = path.match(/^\/api\/records\/([^/]+)$/);
      if (method === 'GET' && recordMatch) return handleGetRecord(recordMatch[1], env);

      // GET /api/records/:id/verify
      const verifyMatch = path.match(/^\/api\/records\/([^/]+)\/verify$/);
      if (method === 'GET' && verifyMatch) return handleVerifyRecord(verifyMatch[1], env);

      // GET /api/ledger/root
      if (method === 'GET' && path === '/api/ledger/root') return handleLedgerRoot(env);

      // GET /api/ledger/proof/:id
      const proofMatch = path.match(/^\/api\/ledger\/proof\/([^/]+)$/);
      if (method === 'GET' && proofMatch) return handleLedgerProof(proofMatch[1], env);

      return err('Not found', 404);
    } catch (e) {
      return err(`Internal error: ${e.message}`, 500);
    }
  },
};
