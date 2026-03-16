# deploy-worker.ps1
# Deploys Helios Ledger API to Cloudflare Workers
# Requires: Node.js (https://nodejs.org) — download and install first if you don't have it
# Run from C:\Users\fogen\HELIOS

Set-Location "$PSScriptRoot"

Write-Host "Checking Node.js..." -ForegroundColor Cyan
try {
    $nodeVersion = node --version 2>&1
    Write-Host "  Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "Node.js is not installed." -ForegroundColor Red
    Write-Host "Download it from https://nodejs.org (click the LTS button)" -ForegroundColor Yellow
    Write-Host "Install it, then re-run this script." -ForegroundColor Yellow
    exit 1
}

Write-Host "Creating worker folder..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path helios-worker | Out-Null

Write-Host "Writing worker.js..." -ForegroundColor Cyan
Set-Content -Path helios-worker\worker.js -Value @'
/**
 * Helios Ledger — Cloudflare Worker API
 */
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
function err(msg, status = 400) { return json({ error: msg }, status); }
function uid() { return crypto.randomUUID(); }
function token() {
  const arr = new Uint8Array(32);
  crypto.getRandomValues(arr);
  return Array.from(arr).map(b => b.toString(16).padStart(2,'0')).join('');
}
async function sha256hex(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2,'0')).join('');
}
async function hmacSign(secret, data) {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
  return Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2,'0')).join('');
}
async function hmacVerify(secret, data, sigHex) {
  return (await hmacSign(secret, data)) === sigHex;
}
async function getAuth(request, db) {
  const auth = request.headers.get('Authorization') || '';
  const tok = auth.replace('Bearer ','').trim();
  if (!tok) return null;
  return await db.prepare('SELECT * FROM accounts WHERE token = ?').bind(tok).first();
}
async function updateMerkleRoot(db, recordId, contentHash) {
  const meta = await db.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
  const count = parseInt(meta?.value||'0');
  await db.prepare('INSERT INTO merkle_nodes (idx, hash) VALUES (?,?)').bind(count, contentHash).run();
  await db.prepare('UPDATE records SET merkle_index=? WHERE id=?').bind(count, recordId).run();
  const leaves = await db.prepare('SELECT hash FROM merkle_nodes ORDER BY idx ASC').all();
  let root = leaves.results[0].hash;
  for (let i = 1; i < leaves.results.length; i++) root = await sha256hex(root + leaves.results[i].hash);
  await db.prepare("UPDATE ledger_meta SET value=? WHERE key='root'").bind(root).run();
  await db.prepare("UPDATE ledger_meta SET value=? WHERE key='record_count'").bind(String(count+1)).run();
  return { leafIdx: count, root };
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;
    if (method==='OPTIONS') return new Response(null, { headers: {
      'Access-Control-Allow-Origin':'*','Access-Control-Allow-Methods':'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers':'Content-Type,Authorization'}});
    try {
      if (method==='GET' && path==='/api/health') {
        const meta = await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
        return json({ status:'ok', service:'helios-ledger', version:'1.0.0', record_count: parseInt(meta?.value||'0'), timestamp: new Date().toISOString() });
      }
      if (method==='POST' && path==='/api/accounts') {
        let body; try { body=await request.json(); } catch { return err('Invalid JSON'); }
        const { username, public_key } = body;
        if (!username||username.length<3) return err('username must be at least 3 characters');
        if (await env.DB.prepare('SELECT id FROM accounts WHERE username=?').bind(username).first()) return err('Username taken',409);
        const id=uid(), tok=token(), now=new Date().toISOString();
        await env.DB.prepare('INSERT INTO accounts (id,username,public_key,token,balance,created_at) VALUES (?,?,?,?,0,?)')
          .bind(id,username,public_key||'',tok,now).run();
        return json({ id, username, token: tok, created_at: now }, 201);
      }
      if (method==='POST' && path==='/api/records') {
        const account = await getAuth(request, env.DB);
        if (!account) return err('Unauthorized',401);
        let body; try { body=await request.json(); } catch { return err('Invalid JSON'); }
        const { content, model, context } = body;
        if (!content) return err('content is required');
        const id=uid(), contentHash=await sha256hex(content), now=new Date().toISOString();
        const sigPayload=JSON.stringify({ id, content_hash:contentHash, timestamp:now, account_id:account.id });
        const signature=await hmacSign(env.SIGNING_SECRET||'helios-default-secret', sigPayload);
        await env.DB.prepare('INSERT INTO records (id,content_hash,signature,model,context,account_id,timestamp) VALUES (?,?,?,?,?,?,?)')
          .bind(id,contentHash,signature,model||null,context||null,account.id,now).run();
        const { leafIdx, root } = await updateMerkleRoot(env.DB, id, contentHash);
        await env.DB.prepare('UPDATE accounts SET balance=balance+1 WHERE id=?').bind(account.id).run();
        return json({ id, content_hash:contentHash, signature, merkle_index:leafIdx, merkle_root:root, model:model||null, timestamp:now }, 201);
      }
      const recordMatch = path.match(/^\/api\/records\/([^/]+)$/);
      if (method==='GET' && recordMatch) {
        const r = await env.DB.prepare('SELECT * FROM records WHERE id=?').bind(recordMatch[1]).first();
        return r ? json(r) : err('Record not found',404);
      }
      const verifyMatch = path.match(/^\/api\/records\/([^/]+)\/verify$/);
      if (method==='GET' && verifyMatch) {
        const r = await env.DB.prepare('SELECT * FROM records WHERE id=?').bind(verifyMatch[1]).first();
        if (!r) return err('Record not found',404);
        const sigPayload=JSON.stringify({ id:r.id, content_hash:r.content_hash, timestamp:r.timestamp, account_id:r.account_id });
        const valid=await hmacVerify(env.SIGNING_SECRET||'helios-default-secret', sigPayload, r.signature);
        const leaves=await env.DB.prepare('SELECT idx,hash FROM merkle_nodes ORDER BY idx ASC').all();
        return json({ record_id:r.id, valid, content_hash:r.content_hash, signature:r.signature, merkle_index:r.merkle_index, merkle_proof:leaves.results, timestamp:r.timestamp });
      }
      if (method==='GET' && path==='/api/ledger/root') {
        const root=await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='root'").first();
        const count=await env.DB.prepare("SELECT value FROM ledger_meta WHERE key='record_count'").first();
        return json({ root:root?.value, record_count:parseInt(count?.value||'0'), timestamp:new Date().toISOString() });
      }
      const proofMatch = path.match(/^\/api\/ledger\/proof\/([^/]+)$/);
      if (method==='GET' && proofMatch) {
        const r=await env.DB.prepare('SELECT merkle_index FROM records WHERE id=?').bind(proofMatch[1]).first();
        if (!r) return err('Record not found',404);
        const leaves=await env.DB.prepare('SELECT idx,hash FROM merkle_nodes ORDER BY idx ASC').all();
        return json({ record_id:proofMatch[1], merkle_index:r.merkle_index, proof:leaves.results });
      }
      return err('Not found',404);
    } catch(e) { return err(`Internal error: ${e.message}`,500); }
  }
};
'@

Write-Host "Writing wrangler.toml..." -ForegroundColor Cyan
Set-Content -Path helios-worker\wrangler.toml -Value @'
name = "helios-ledger-api"
main = "worker.js"
compatibility_date = "2025-01-01"
compatibility_flags = ["nodejs_compat"]

[[d1_databases]]
binding = "DB"
database_name = "helios-ledger"
database_id = "884d3be3-7389-49ea-aab3-7ae6720d4fa7"
'@

Write-Host "Installing Wrangler..." -ForegroundColor Cyan
Set-Location helios-worker
npm install --save-dev wrangler 2>&1 | Tail -5

Write-Host ""
Write-Host "Logging into Cloudflare..." -ForegroundColor Cyan
Write-Host "(A browser window will open — log in if needed)" -ForegroundColor Yellow
npx wrangler login

Write-Host ""
Write-Host "Setting signing secret..." -ForegroundColor Cyan
$secret = -join ((48..57 + 65..90 + 97..122) | Get-Random -Count 48 | ForEach-Object { [char]$_ })
Write-Host "  Generated secret: $secret" -ForegroundColor Gray
Write-Host "  (Save this somewhere safe)" -ForegroundColor Yellow
echo $secret | npx wrangler secret put SIGNING_SECRET

Write-Host ""
Write-Host "Deploying worker..." -ForegroundColor Cyan
npx wrangler deploy

Write-Host ""
Write-Host "ALL DONE!" -ForegroundColor Green
Write-Host "Your API is live at: https://helios-ledger-api.<your-subdomain>.workers.dev" -ForegroundColor Green
Write-Host "Test it: curl https://helios-ledger-api.<your-subdomain>.workers.dev/api/health" -ForegroundColor Cyan
