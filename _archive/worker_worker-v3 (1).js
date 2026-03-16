/**
 * Helios Ledger Worker v3.0
 *
 * New in v3:
 *  - User-side Ed25519 signing: submit your own signature with records
 *  - Account creation sealed on-chain (wallet analogy complete)
 *  - GET /api/v1/keygen — generate an Ed25519 keypair on the fly
 *  - user_verified field in record responses
 */

import { createPrivateKey, createPublicKey, generateKeyPairSync, sign as nodeCryptoSign, verify as nodeCryptoVerify } from 'node:crypto';

// ── Config ─────────────────────────────────────────────────────────────
const MAX_CONTENT_BYTES  = 50_000;
const MAX_USERNAME_LEN   = 32;
const MAX_BALANCE        = Number.MAX_SAFE_INTEGER;
const RATE_WINDOW_ACCT   = 3600;
const RATE_MAX_ACCT      = 10;
const RATE_WINDOW_REC    = 60;
const RATE_MAX_REC       = 100;

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

// ── Crypto ─────────────────────────────────────────────────────────────
async function sha256hex(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2,'0')).join('');
}
function genToken() {
  const a = new Uint8Array(32); crypto.getRandomValues(a);
  return Array.from(a).map(b => b.toString(16).padStart(2,'0')).join('');
}

// Helios server-side signing
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

// User-side verification — verify a hex signature against a stored JWK public key
function verifyUserSignature(publicKeyJwk, contentHash, userSigHex) {
  try {
    const key = createPublicKey({ key: JSON.parse(publicKeyJwk), format: 'jwk' });
    // User signs the content hash directly
    return nodeCryptoVerify(null, Buffer.from(contentHash), key, Buffer.from(userSigHex, 'hex'));
  } catch { return false; }
}

// ── Auth ───────────────────────────────────────────────────────────────
async function getAuth(request, db) {
  const raw = (request.headers.get('Authorization') || '').replace('Bearer ', '').trim();
  if (raw.length < 32) return null;
  const hash = await sha256hex(raw);
  return db.prepare('SELECT * FROM accounts WHERE token_hash = ?').bind(hash).first();
}

// ── Rate limiting ──────────────────────────────────────────────────────
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
    await db.batch([
      db.prepare('DELETE FROM rate_limits WHERE key LIKE ? AND key != ?').bind(`${key}:%`, rlKey),
      db.prepare('INSERT INTO rate_limits (key, count, window_start) VALUES (?, 1, ?)').bind(rlKey, windowStart),
    ]);
  }
  return true;
}

// ── Merkle ─────────────────────────────────────────────────────────────
async function buildMerkleProof(db, targetIdx) {
  const rows = await db.prepare('SELECT hash FROM merkle_nodes ORDER BY idx ASC').all();
  let leaves = rows.results.map(r => r.hash);
  if (leaves.length === 0) return { root: '0'.repeat(64), proof: [] };
  const levels = [leaves];
  let cur = leaves;
  while (cur.length > 1) {
    const next = [];
    for (let i = 0; i < cur.length; i += 2) {
      next.push(await sha256hex(cur[i] + (i + 1 < cur.length ? cur[i+1] : cur[i])));
    }
    levels.push(next);
    cur = next;
  }
  const root  = levels[levels.length - 1][0];
  const proof = [];
  let idx = targetIdx;
  for (let l = 0; l < levels.length - 1; l++) {
    const level   = levels[l];
    const isRight = idx % 2 === 1;
    const sibIdx  = isRight ? idx - 1 : idx + 1;
    proof.push({ position: isRight ? 'left' : 'right', hash: sibIdx < level.length ? level[sibIdx] : level[idx] });
    idx = Math.floor(idx / 2);
  }
  return { root, proof };
}

// Shared: insert a leaf and update root atomically
async function sealOnChain(db, recordId, contentHash, leafIdx) {
  await db.batch([
    db.prepare('INSERT INTO merkle_nodes (idx, hash) VALUES (?,?)').bind(leafIdx, contentHash),
    db.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").bind(String(leafIdx + 1)),
  ]);
  const { root, proof } = await buildMerkleProof(db, leafIdx);
  await db.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").bind(root).run();
  return { root, proof };
}

// ── Handlers ───────────────────────────────────────────────────────────

async function handleHealth(env, origin) {
  const meta = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  return jsonR({ status: 'ok', service: 'helios-ledger', version: '3.0.0',
    record_count: parseInt(meta?.value || '0'), timestamp: new Date().toISOString() }, 200, origin);
}

async function handlePubkey(env, origin) {
  return jsonR({
    algorithm:  'Ed25519',
    public_key: env.SIGNING_PUBLIC_KEY ? JSON.parse(env.SIGNING_PUBLIC_KEY) : null,
    note:       'Use this key to independently verify any Helios signature.',
  }, 200, origin);
}

// NEW: generate a keypair on the fly so users can start signing immediately
async function handleKeygen(origin) {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const privJwk = privateKey.export({ format: 'jwk' });
  const pubJwk  = publicKey.export({ format: 'jwk' });
  // Strip private component from public
  const pubClean = { kty: pubJwk.kty, crv: pubJwk.crv, x: pubJwk.x };
  return jsonR({
    private_key: privJwk,
    public_key:  pubClean,
    warning:     'Store your private key securely. Never share it. Use it to sign content hashes before submitting records.',
    usage: {
      step1: 'Save public_key in your account: POST /api/v1/accounts with { public_key: <this> }',
      step2: 'Sign the SHA-256 hex hash of your content with your private key (Ed25519, sign the raw hash bytes)',
      step3: 'Submit record with { content, user_signature: <hex sig> }',
      step4: 'Helios verifies your signature and sets user_verified: true in the response',
    },
  }, 200, origin);
}

async function handleCreateAccount(req, env, origin) {
  const ip = req.headers.get('CF-Connecting-IP') || 'unknown';
  if (!await rateCheck(env.DB, `acct:${ip}`, RATE_MAX_ACCT, RATE_WINDOW_ACCT))
    return errR('Rate limit exceeded. Max 10 accounts per IP per hour.', 429, origin);

  let body;
  try { body = await req.json(); } catch { return errR('Invalid JSON', 400, origin); }

  const { username, public_key } = body;
  const BAD_USERNAME = 'Invalid username. 3-32 chars, alphanumeric/underscore/hyphen only.';
  if (!username || typeof username !== 'string' || username.length < 3 ||
      username.length > MAX_USERNAME_LEN || !/^[a-zA-Z0-9_-]+$/.test(username))
    return errR(BAD_USERNAME, 400, origin);

  if (await env.DB.prepare('SELECT id FROM accounts WHERE username = ?').bind(username).first())
    return errR(BAD_USERNAME, 400, origin);

  const id       = crypto.randomUUID();
  const rawToken = genToken();
  const tokHash  = await sha256hex(rawToken);
  const now      = new Date().toISOString();

  // Validate public_key JWK if provided
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

  // NEW: Seal account creation as a chain record
  if (!env.SIGNING_PRIVATE_KEY) return errR('Internal server error', 500, origin);

  const acctEvent    = JSON.stringify({ event: 'account_created', account_id: id, username, timestamp: now, has_pubkey: !!pubKeyStr });
  const contentHash  = await sha256hex(acctEvent);
  const recordId     = crypto.randomUUID();
  const sigPayload   = JSON.stringify({ id: recordId, content_hash: contentHash, model: 'system', timestamp: now, account_id: id, submitter_pubkey: null });
  const signature    = heliosSign(env.SIGNING_PRIVATE_KEY, sigPayload);

  const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const leafIdx  = parseInt(countRow?.value || '0');

  // Atomic batch: record + merkle + count all together
  await env.DB.batch([
    env.DB.prepare('INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp) VALUES (?,?,?,?,?,?,?,?)')
      .bind(recordId, contentHash, signature, 'system', 'account_creation', id, leafIdx, now),
    env.DB.prepare('INSERT OR IGNORE INTO merkle_nodes (idx, hash) VALUES (?,?)').bind(leafIdx, contentHash),
    env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").bind(String(leafIdx + 1)),
  ]);

  const { root, proof } = await buildMerkleProof(env.DB, leafIdx);
  await env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").bind(root).run();

  return jsonR({
    id, username,
    token:      rawToken,
    public_key: pubKeyStr ? JSON.parse(pubKeyStr) : null,
    created_at: now,
    warning:    'Save your token — it cannot be recovered.',
    chain_record: {
      record_id:    recordId,
      content_hash: contentHash,
      merkle_index: leafIdx,
      merkle_root:  root,
      note:         'Your account creation is now permanently sealed on the Helios ledger.',
    },
  }, 201, origin);
}

async function handleSubmitRecord(req, env, origin) {
  const account = await getAuth(req, env.DB);
  if (!account) return errR('Unauthorized', 401, origin);

  if (!await rateCheck(env.DB, `rec:${account.id}`, RATE_MAX_REC, RATE_WINDOW_REC))
    return errR('Rate limit exceeded. Max 100 records per minute per account.', 429, origin);

  if (!env.SIGNING_PRIVATE_KEY) return errR('Internal server error', 500, origin);

  let body;
  try { body = await req.json(); } catch { return errR('Invalid JSON', 400, origin); }

  const { content, model, context, user_signature } = body;
  if (!content || typeof content !== 'string') return errR('content is required', 400, origin);
  if (new TextEncoder().encode(content).length > MAX_CONTENT_BYTES)
    return errR(`Content too large. Maximum is ${MAX_CONTENT_BYTES} bytes.`, 413, origin);

  const contentHash = await sha256hex(content);

  // NEW: verify user signature if provided
  let userVerified = false;
  if (user_signature) {
    if (!account.public_key)
      return errR('user_signature provided but account has no public_key registered. Create account with public_key first.', 400, origin);
    userVerified = verifyUserSignature(account.public_key, contentHash, user_signature);
    if (!userVerified)
      return errR('user_signature is invalid. Sign the SHA-256 hex hash of content with your Ed25519 private key.', 400, origin);
  }

  const dupe = await env.DB.prepare('SELECT id FROM records WHERE content_hash = ?').bind(contentHash).first();
  const id   = crypto.randomUUID();
  const now  = new Date().toISOString();

  const sigPayload = JSON.stringify({
    id, content_hash: contentHash, model: model || null,
    timestamp: now, account_id: account.id,
    submitter_pubkey: account.public_key || null,
    user_verified: userVerified,
  });
  const signature = heliosSign(env.SIGNING_PRIVATE_KEY, sigPayload);

  const countRow = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const leafIdx  = parseInt(countRow?.value || '0');

  // All writes in one atomic batch — prevents merkle_nodes PRIMARY KEY conflict on retry
  await env.DB.batch([
    env.DB.prepare('INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp) VALUES (?,?,?,?,?,?,?,?)')
      .bind(id, contentHash, signature, model || null, context || null, account.id, leafIdx, now),
    env.DB.prepare('UPDATE accounts SET balance = MIN(balance + 1, ?) WHERE id = ?').bind(MAX_BALANCE, account.id),
    env.DB.prepare('INSERT OR IGNORE INTO merkle_nodes (idx, hash) VALUES (?,?)').bind(leafIdx, contentHash),
    env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").bind(String(leafIdx + 1)),
  ]);

  const { root, proof } = await buildMerkleProof(env.DB, leafIdx);
  await env.DB.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").bind(root).run();

  return jsonR({
    id, content_hash: contentHash, signature,
    signing_algorithm: 'Ed25519',
    user_verified,
    user_verified_note: userVerified
      ? 'Content hash was verified against your registered Ed25519 public key.'
      : user_signature ? 'Signature check failed.' : 'No user_signature provided — only Helios-signed.',
    merkle_index: leafIdx, merkle_root: root, merkle_proof: proof,
    model: model || null, context: context || null, timestamp: now,
    timestamp_note: 'Server-controlled.',
    duplicate_of: dupe ? dupe.id : null,
  }, 201, origin);
}

async function handleGetRecord(id, env, origin) {
  const r = await env.DB.prepare('SELECT id, content_hash, signature, model, context, account_id, merkle_index, timestamp FROM records WHERE id = ?').bind(id).first();
  if (!r) return errR('Record not found', 404, origin);
  return jsonR(r, 200, origin);
}

async function handleVerifyRecord(id, env, origin) {
  const r = await env.DB.prepare('SELECT * FROM records WHERE id = ?').bind(id).first();
  if (!r) return errR('Record not found', 404, origin);

  const sigPayload = JSON.stringify({
    id: r.id, content_hash: r.content_hash, model: r.model,
    timestamp: r.timestamp, account_id: r.account_id,
    submitter_pubkey: r.submitter_pubkey || null,
    user_verified: false, // legacy records
  });
  let valid = false;
  if (env.SIGNING_PUBLIC_KEY) valid = heliosVerify(env.SIGNING_PUBLIC_KEY, sigPayload, r.signature);

  const { root, proof } = await buildMerkleProof(env.DB, r.merkle_index);
  return jsonR({
    record_id: r.id, valid, signing_algorithm: 'Ed25519',
    content_hash: r.content_hash, signature: r.signature,
    merkle_index: r.merkle_index, merkle_root: root,
    merkle_proof: proof, proof_depth: proof.length,
    timestamp: r.timestamp,
    how_to_verify: 'GET /api/v1/pubkey for the Ed25519 public key. Verify signature against the canonical sigPayload independently.',
  }, 200, origin);
}

async function handleLedgerRoot(env, origin) {
  const root  = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='root'").first();
  const count = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  return jsonR({ root: root?.value, record_count: parseInt(count?.value || '0'), timestamp: new Date().toISOString() }, 200, origin);
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
    const origin = getAllowedOrigin(request);

    if (method === 'OPTIONS') {
      if (!origin) return new Response(null, { status: 403 });
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    const p = url.pathname.replace(/^\/api\/v1\//, '/api/').replace(/^\/api\/v1$/, '/api');

    try {
      if (method === 'GET'  && p === '/api/health')       return await handleHealth(env, origin);
      if (method === 'GET'  && p === '/api/pubkey')        return await handlePubkey(env, origin);
      if (method === 'GET'  && p === '/api/keygen')        return await handleKeygen(origin);
      if (method === 'POST' && p === '/api/accounts')      return await handleCreateAccount(request, env, origin);
      if (method === 'POST' && p === '/api/records')       return await handleSubmitRecord(request, env, origin);
      if (method === 'GET'  && p === '/api/ledger/root')   return await handleLedgerRoot(env, origin);

      const recM = p.match(/^\/api\/records\/([^/]+)$/);
      if (method === 'GET' && recM) return await handleGetRecord(recM[1], env, origin);

      const verM = p.match(/^\/api\/records\/([^/]+)\/verify$/);
      if (method === 'GET' && verM) return await handleVerifyRecord(verM[1], env, origin);

      const prfM = p.match(/^\/api\/ledger\/proof\/([^/]+)$/);
      if (method === 'GET' && prfM) return await handleLedgerProof(prfM[1], env, origin);

      return errR('Not found', 404, origin);
    } catch (e) {
      console.error('Worker error:', e.message);
      return errR('Internal server error', 500, origin);
    }
  },
};
