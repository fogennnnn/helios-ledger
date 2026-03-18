#!/usr/bin/env node
// Helios Ledger Standalone Server v5.2
// No Cloudflare required — Express + better-sqlite3
// Usage: node server.js

import express from 'express';
import Database from 'better-sqlite3';
import { createHash, randomBytes, randomUUID,
         createPrivateKey, createPublicKey, generateKeyPairSync,
         sign as nodeCryptoSign, verify as nodeCryptoVerify } from 'node:crypto';
import { readFileSync, existsSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT              = parseInt(process.env.PORT || '3000');
const DB_PATH           = process.env.DB_PATH || join(__dirname, 'helios.db');
const MAX_CONTENT_BYTES = 50000;
const MAX_USERNAME_LEN  = 32;
const MAX_BALANCE       = 2000000000;
const RATE_WINDOW_ACCT  = 3600;  const RATE_MAX_ACCT = 10;
const RATE_WINDOW_REC   = 60;   const RATE_MAX_REC  = 100;
const PEER_RECEIVE_MAX  = 200;  const PEER_RECEIVE_WIN = 60;
const TS_MAX_SKEW_MS    = 60000; const TS_FUTURE_SKEW_MS = 5000;
const VERSION           = '5.2.0';

// ─── Database ──────────────────────────────────────────────────────────────
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.exec(`
CREATE TABLE IF NOT EXISTS accounts (id TEXT PRIMARY KEY, username TEXT UNIQUE NOT NULL, public_key TEXT, token_hash TEXT NOT NULL, balance INTEGER DEFAULT 0, created_at TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS records (id TEXT PRIMARY KEY, content_hash TEXT NOT NULL, signature TEXT NOT NULL, model TEXT, context TEXT, account_id TEXT, merkle_index INTEGER NOT NULL, timestamp TEXT NOT NULL, source_node TEXT);
CREATE TABLE IF NOT EXISTS merkle_tree (level INTEGER NOT NULL, pos INTEGER NOT NULL, hash TEXT NOT NULL, PRIMARY KEY (level, pos));
CREATE TABLE IF NOT EXISTS merkle_nodes (idx INTEGER PRIMARY KEY, hash TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS ledger_meta (key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE IF NOT EXISTS rate_limits (key TEXT PRIMARY KEY, count INTEGER DEFAULT 0, window_start TEXT);
CREATE TABLE IF NOT EXISTS seen_nonces (nonce TEXT PRIMARY KEY);
INSERT OR IGNORE INTO ledger_meta (key, value) VALUES ('record_count', '0');
INSERT OR IGNORE INTO ledger_meta (key, value) VALUES ('root', '');
CREATE INDEX IF NOT EXISTS idx_records_ch ON records (content_hash);
CREATE INDEX IF NOT EXISTS idx_records_mi ON records (merkle_index);
CREATE INDEX IF NOT EXISTS idx_accounts_th ON accounts (token_hash);
`);

// ─── Keys — auto-generates if missing ──────────────────────────────────────
const KEYS_PATH = join(__dirname, 'keys.json');
let PRIV, PUB;
if (process.env.SIGNING_PRIVATE_KEY) {
  PRIV = process.env.SIGNING_PRIVATE_KEY; PUB = process.env.SIGNING_PUBLIC_KEY;
} else if (existsSync(KEYS_PATH)) {
  const k = JSON.parse(readFileSync(KEYS_PATH, 'utf8'));
  PRIV = JSON.stringify(k.private_key); PUB = JSON.stringify(k.public_key);
} else {
  const { privateKey, publicKey } = generateKeyPairSync('ed25519');
  const pr = privateKey.export({ format: 'jwk' });
  const pu = publicKey.export({ format: 'jwk' });
  const keys = { private_key: pr, public_key: { kty: pu.kty, crv: pu.crv, x: pu.x } };
  writeFileSync(KEYS_PATH, JSON.stringify(keys, null, 2));
  PRIV = JSON.stringify(pr); PUB = JSON.stringify(keys.public_key);
  console.log('Generated Ed25519 keypair → keys.json (back this up)');
}
const PEERS = process.env.PEERS ? JSON.parse(process.env.PEERS) : [];

// ─── Crypto ────────────────────────────────────────────────────────────────
const sha256hex = t => createHash('sha256').update(t).digest('hex');
const genToken = () => randomBytes(32).toString('hex');
function hSign(d) { return nodeCryptoSign(null, Buffer.from(d), createPrivateKey({ key: JSON.parse(PRIV), format: 'jwk' })).toString('hex'); }
function hVerify(pub, d, sig) { try { return nodeCryptoVerify(null, Buffer.from(d), createPublicKey({ key: JSON.parse(pub), format: 'jwk' }), Buffer.from(sig, 'hex')); } catch { return false; } }

// ─── Rate limiter ──────────────────────────────────────────────────────────
function rl(key, max, win) {
  const now = Math.floor(Date.now() / 1000), ws = now - (now % win), rk = key + ':' + ws;
  const row = db.prepare('SELECT count FROM rate_limits WHERE key = ?').get(rk);
  if ((row?.count || 0) >= max) return false;
  if (row) db.prepare('UPDATE rate_limits SET count = count + 1 WHERE key = ?').run(rk);
  else { db.prepare('DELETE FROM rate_limits WHERE key LIKE ? AND key != ?').run(key + ':%', rk); db.prepare('INSERT INTO rate_limits (key, count, window_start) VALUES (?, 1, ?)').run(rk, String(ws)); }
  return true;
}
function auth(req) { const t = (req.headers.authorization || '').replace('Bearer ', '').trim(); return t.length >= 32 ? db.prepare('SELECT * FROM accounts WHERE token_hash = ?').get(sha256hex(t)) || null : null; }
const clientIp = req => req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket.remoteAddress || '?';

// ─── Merkle tree ───────────────────────────────────────────────────────────
function treeH(n) { return n <= 1 ? 0 : Math.ceil(Math.log2(n)); }
const getSib = db.prepare('SELECT hash FROM merkle_tree WHERE level = ? AND pos = ?');
const upsert = db.prepare('INSERT OR REPLACE INTO merkle_tree (level, pos, hash) VALUES (?, ?, ?)');

function appendLeaf(idx, hash) {
  const h = treeH(idx + 1);
  if (h === 0) { upsert.run(0, 0, hash); return { root: hash, proof: [] }; }
  const proof = []; let cur = hash, pos = idx;
  upsert.run(0, idx, hash);
  for (let l = 0; l < h; l++) {
    const ir = pos % 2 === 1, sp = pos ^ 1;
    let sh = getSib.get(l, sp)?.hash || cur;
    proof.push({ position: ir ? 'left' : 'right', hash: sh });
    cur = sha256hex((ir ? sh : cur) + (ir ? cur : sh));
    upsert.run(l + 1, pos >> 1, cur); pos >>= 1;
  }
  return { root: cur, proof };
}
function merkleProof(idx, total) {
  if (total <= 0) return { root: '0'.repeat(64), proof: [] };
  if (total === 1) return { root: getSib.get(0, 0)?.hash || '0'.repeat(64), proof: [] };
  const h = treeH(total), proof = []; let pos = idx;
  for (let l = 0; l < h; l++) { const ir = pos % 2 === 1, sp = pos ^ 1; proof.push({ position: ir ? 'left' : 'right', hash: getSib.get(l, sp)?.hash || getSib.get(l, pos)?.hash || '0'.repeat(64) }); pos >>= 1; }
  return { root: db.prepare('SELECT hash FROM merkle_tree WHERE level = ? AND pos = 0').get(h)?.hash || '0'.repeat(64), proof };
}
function broadcast(rec) {
  if (!PEERS.length || !PRIV || !PUB) return;
  const p = JSON.stringify({ record_id: rec.id, content_hash: rec.content_hash, signature: rec.signature, model: rec.model, context: rec.context, account_id: rec.account_id, merkle_index: rec.merkle_index, timestamp: rec.timestamp, nonce: rec.nonce || null });
  const body = JSON.stringify({ record: JSON.parse(p), origin_signature: hSign(p), origin_public_key: JSON.parse(PUB) });
  for (const peer of PEERS) fetch(peer.url.replace(/\/$/, '') + '/api/v1/peer/receive', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body }).catch(() => {});
}

// ─── Badge JS ──────────────────────────────────────────────────────────────
const badgePath = join(__dirname, 'badge.js');
const BADGE_JS = existsSync(badgePath) ? readFileSync(badgePath, 'utf8') : '// badge.js not found';

// ─── Express ───────────────────────────────────────────────────────────────
const app = express();
app.use(express.json({ limit: '100kb' }));
app.use((req, res, next) => { res.set({ 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'Content-Type, Authorization', 'Access-Control-Allow-Methods': 'GET, POST, OPTIONS' }); if (req.method === 'OPTIONS') return res.status(204).end(); next(); });
app.use((req, _, next) => { req.url = req.url.replace(/^\/api\/v1\//, '/api/').replace(/^\/api\/v1$/, '/api'); next(); });

// ─── Routes ────────────────────────────────────────────────────────────────
app.get('/api/health', (_, res) => { const m = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(); const t = db.prepare('SELECT COUNT(*) as cnt FROM merkle_tree WHERE level = 0').get(); res.json({ status: 'ok', service: 'helios-ledger', version: VERSION, record_count: parseInt(m?.value || '0'), tree_nodes: t?.cnt || 0, merkle_engine: 'incremental', consensus: PEERS.length ? 'federated' : 'standalone', peer_count: PEERS.length, timestamp: new Date().toISOString() }); });
app.get('/api/nonce', (_, res) => res.type('text').send(randomUUID()));
app.get('/api/pubkey', (_, res) => res.json({ algorithm: 'Ed25519', public_key: PUB ? JSON.parse(PUB) : null, note: 'Use this key to independently verify any Helios signature.' }));
app.get('/api/keygen', (_, res) => { const { privateKey, publicKey } = generateKeyPairSync('ed25519'); const pr = privateKey.export({ format: 'jwk' }), pu = publicKey.export({ format: 'jwk' }); res.json({ private_key: pr, public_key: { kty: pu.kty, crv: pu.crv, x: pu.x }, warning: 'Store your private key securely.' }); });

app.post('/api/accounts', (req, res) => {
  if (!rl('acct:' + clientIp(req), RATE_MAX_ACCT, RATE_WINDOW_ACCT)) return res.status(429).json({ error: 'Rate limit exceeded.' });
  const { username, public_key } = req.body || {};
  if (!username || typeof username !== 'string' || username.length < 3 || username.length > MAX_USERNAME_LEN || !/^[a-zA-Z0-9_-]+$/.test(username)) return res.status(400).json({ error: 'Invalid username.' });
  if (db.prepare('SELECT id FROM accounts WHERE username = ?').get(username)) return res.status(409).json({ error: 'Username taken.' });
  const id = randomUUID(), tok = genToken(), th = sha256hex(tok), now = new Date().toISOString();
  let pks = null;
  if (public_key) { try { const j = typeof public_key === 'string' ? JSON.parse(public_key) : public_key; if (j.kty !== 'OKP' || j.crv !== 'Ed25519') return res.status(400).json({ error: 'Must be Ed25519 JWK' }); pks = JSON.stringify(j); } catch { return res.status(400).json({ error: 'Invalid public_key' }); } }
  db.prepare('INSERT INTO accounts (id, username, public_key, token_hash, balance, created_at) VALUES (?,?,?,?,0,?)').run(id, username, pks, th, now);
  const ev = JSON.stringify({ event: 'account_created', account_id: id, username, timestamp: now }), ch = sha256hex(ev), rid = randomUUID();
  const sp = JSON.stringify({ id: rid, content_hash: ch, model: 'system', timestamp: now, account_id: id }), sig = hSign(sp);
  const cr = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(), li = parseInt(cr?.value || '0');
  db.prepare('INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp) VALUES (?,?,?,?,?,?,?,?)').run(rid, ch, sig, 'system', 'account_creation', id, li, now);
  db.prepare('INSERT OR IGNORE INTO merkle_nodes (idx, hash) VALUES (?,?)').run(li, ch);
  db.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").run(String(li + 1));
  const { root } = appendLeaf(li, ch);
  db.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").run(root);
  broadcast({ id: rid, content_hash: ch, signature: sig, model: 'system', context: 'account_creation', account_id: id, merkle_index: li, timestamp: now });
  res.status(201).json({ id, username, token: tok, public_key: pks ? JSON.parse(pks) : null, created_at: now, warning: 'Save your token -- it cannot be recovered.', chain_record: { record_id: rid, content_hash: ch, merkle_index: li, merkle_root: root, note: 'Account creation sealed on the Helios ledger.' } });
});

app.post('/api/records', (req, res) => {
  const acc = auth(req); if (!acc) return res.status(401).json({ error: 'Unauthorized' });
  if (!rl('rec:' + acc.id, RATE_MAX_REC, RATE_WINDOW_REC)) return res.status(429).json({ error: 'Rate limit exceeded.' });
  const { content, model, context, user_signature } = req.body || {};
  if (!content || typeof content !== 'string') return res.status(400).json({ error: 'content is required' });
  if (Buffer.byteLength(content) > MAX_CONTENT_BYTES) return res.status(413).json({ error: 'Content too large.' });
  const ch = sha256hex(content);
  let uv = false;
  if (user_signature) { if (!acc.public_key) return res.status(400).json({ error: 'No public_key on account.' }); uv = hVerify(acc.public_key, ch, user_signature); if (!uv) return res.status(400).json({ error: 'Invalid user_signature.' }); }
  const dupe = db.prepare('SELECT id FROM records WHERE content_hash = ?').get(ch);
  const id = randomUUID(), now = new Date().toISOString(), nonce = randomUUID();
  const sp = JSON.stringify({ id, content_hash: ch, model: model || null, timestamp: now, account_id: acc.id }), sig = hSign(sp);
  const cr = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(), li = parseInt(cr?.value || '0');
  db.prepare('INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp) VALUES (?,?,?,?,?,?,?,?)').run(id, ch, sig, model || null, context || null, acc.id, li, now);
  db.prepare('UPDATE accounts SET balance = MIN(balance + 1, ?) WHERE id = ?').run(MAX_BALANCE, acc.id);
  db.prepare('INSERT OR IGNORE INTO merkle_nodes (idx, hash) VALUES (?,?)').run(li, ch);
  db.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").run(String(li + 1));
  const { root, proof } = appendLeaf(li, ch);
  db.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").run(root);
  broadcast({ id, content_hash: ch, signature: sig, model: model || null, context: context || null, account_id: acc.id, merkle_index: li, timestamp: now, nonce });
  res.status(201).json({ id, content_hash: ch, signature: sig, signing_algorithm: 'Ed25519', user_verified: uv, merkle_index: li, merkle_root: root, merkle_proof: proof, model: model || null, context: context || null, timestamp: now, nonce, duplicate_of: dupe?.id || null });
});

app.get('/api/records/:id', (req, res) => { const r = db.prepare('SELECT id, content_hash, signature, model, context, account_id, merkle_index, timestamp FROM records WHERE id = ?').get(req.params.id); r ? res.json(r) : res.status(404).json({ error: 'Not found' }); });

app.get('/api/records/:id/verify', (req, res) => {
  const r = db.prepare('SELECT * FROM records WHERE id = ?').get(req.params.id); if (!r) return res.status(404).json({ error: 'Not found' });
  const sp = JSON.stringify({ id: r.id, content_hash: r.content_hash, model: r.model, timestamp: r.timestamp, account_id: r.account_id });
  let valid = false; try { valid = hVerify(PUB, sp, r.signature); } catch {}
  const cr = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(), tl = parseInt(cr?.value || '0');
  const { root, proof } = merkleProof(r.merkle_index, tl);
  res.json({ record_id: r.id, valid, signing_algorithm: 'Ed25519', content_hash: r.content_hash, signature: r.signature, merkle_index: r.merkle_index, merkle_root: root, merkle_proof: proof, proof_depth: proof.length, timestamp: r.timestamp, how_to_verify: 'GET /api/v1/pubkey for the Ed25519 public key.' });
});

app.get('/api/ledger/root', (_, res) => { const r = db.prepare("SELECT value FROM ledger_meta WHERE key='root'").get(), c = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(); res.json({ root: r?.value, record_count: parseInt(c?.value || '0'), timestamp: new Date().toISOString() }); });
app.get('/api/ledger/proof/:id', (req, res) => { const r = db.prepare('SELECT merkle_index FROM records WHERE id = ?').get(req.params.id); if (!r) return res.status(404).json({ error: 'Not found' }); const c = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(); const { root, proof } = merkleProof(r.merkle_index, parseInt(c?.value || '0')); res.json({ record_id: req.params.id, merkle_index: r.merkle_index, merkle_root: root, proof }); });
app.get('/api/ledger/recent', (_, res) => { res.json({ records: db.prepare('SELECT id, content_hash, model, context, merkle_index, timestamp FROM records ORDER BY merkle_index DESC LIMIT 20').all() }); });
app.get('/api/peers', (_, res) => { const p = PUB ? JSON.parse(PUB) : null, c = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(); res.json({ node_id: p?.x?.substring(0, 16) || null, public_key: p, record_count: parseInt(c?.value || '0'), peers: PEERS.map(x => ({ url: x.url, public_key: x.public_key })), peer_count: PEERS.length, consensus: PEERS.length ? 'federated' : 'standalone', endpoint: '/api/v1/peer/receive' }); });

app.post('/api/peer/receive', (req, res) => {
  if (!rl('peer:' + clientIp(req), PEER_RECEIVE_MAX, PEER_RECEIVE_WIN)) return res.status(429).json({ error: 'Rate limit.' });
  const { record: rec, origin_signature, origin_public_key } = req.body || {};
  if (!rec || !origin_signature || !origin_public_key) return res.status(400).json({ error: 'Missing fields.' });
  const kp = PEERS.find(p => p.public_key?.x === origin_public_key.x); if (!kp) return res.status(403).json({ error: 'Unknown peer.' });
  const pl = JSON.stringify({ record_id: rec.record_id, content_hash: rec.content_hash, signature: rec.signature, model: rec.model, context: rec.context, account_id: rec.account_id, merkle_index: rec.merkle_index, timestamp: rec.timestamp, nonce: rec.nonce || null });
  if (!hVerify(JSON.stringify(origin_public_key), pl, origin_signature)) return res.status(400).json({ error: 'Bad signature.' });
  const ts = Date.parse(rec.timestamp); if (!ts || isNaN(ts)) return res.status(400).json({ error: 'Bad timestamp' }); const nm = Date.now();
  if (ts > nm + TS_FUTURE_SKEW_MS) return res.status(400).json({ error: 'Future ts' }); if (nm - ts > TS_MAX_SKEW_MS) return res.status(400).json({ error: 'Too old' });
  if (rec.nonce) { if (db.prepare('SELECT 1 FROM seen_nonces WHERE nonce = ?').get(rec.nonce)) return res.status(400).json({ error: 'Nonce reuse' }); db.prepare('INSERT INTO seen_nonces (nonce) VALUES (?)').run(rec.nonce); }
  const ex = db.prepare('SELECT id FROM records WHERE content_hash = ? OR id = ?').get(rec.content_hash, rec.record_id); if (ex) return res.json({ status: 'duplicate', existing_id: ex.id });
  const lid = randomUUID(), now = new Date().toISOString(), lsp = JSON.stringify({ id: lid, content_hash: rec.content_hash, model: rec.model || null, timestamp: now, account_id: rec.account_id }), ls = hSign(lsp);
  const cr = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get(), li = parseInt(cr?.value || '0');
  db.prepare('INSERT INTO records (id, content_hash, signature, model, context, account_id, merkle_index, timestamp, source_node) VALUES (?,?,?,?,?,?,?,?,?)').run(lid, rec.content_hash, ls, rec.model || null, rec.context || null, rec.account_id, li, now, kp.url);
  db.prepare('INSERT OR IGNORE INTO merkle_nodes (idx, hash) VALUES (?,?)').run(li, rec.content_hash);
  db.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").run(String(li + 1));
  const { root } = appendLeaf(li, rec.content_hash); db.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").run(root);
  res.status(201).json({ status: 'accepted', local_id: lid, origin_record_id: rec.record_id, content_hash: rec.content_hash, merkle_index: li, merkle_root: root, source_node: kp.url });
});

app.get(['/badge.js', '/api/badge.js'], (_, res) => { res.set({ 'Content-Type': 'application/javascript; charset=utf-8', 'Cache-Control': 'public, max-age=3600' }); res.send(BADGE_JS); });
app.use((_, res) => res.status(404).json({ error: 'Not found' }));

app.listen(PORT, () => {
  const c = db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").get();
  console.log(`\n  Helios Ledger v${VERSION} · http://localhost:${PORT} · ${c?.value || 0} records\n`);
});
