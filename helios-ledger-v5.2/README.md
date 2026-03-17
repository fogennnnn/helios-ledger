# Helios Ledger

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Runtime](https://img.shields.io/badge/runtime-Cloudflare%20Workers-orange)](https://workers.cloudflare.com)
[![Website](https://img.shields.io/badge/site-ai.oooooooooo.se-teal)](https://ai.oooooooooo.se)

Helios Ledger is an open-source platform for cryptographically sealing the **origin and integrity of AI-generated content**. It uses [Ed25519](https://ed25519.cr.yp.to/) digital signatures and an append-only Merkle tree to create tamper-proof provenance records — independently verifiable by anyone, requiring no trust in the platform itself.

> **Live instance:** [https://ai.oooooooooo.se](https://ai.oooooooooo.se)

---

## Architecture

| Component | Technology |
|-----------|-----------|
| API | Cloudflare Worker (JavaScript, Web Crypto + node:crypto for Ed25519) |
| Database | Cloudflare D1 (SQLite) |
| Frontend | Static HTML/CSS/JS served via GitHub Pages |
| Signing | Ed25519 via node:crypto |
| Hashing | SHA-256 via Web Crypto API (crypto.subtle) |
| Ledger | Incremental append-only Merkle tree — O(log n) insert/proof |
| Consensus | Multi-node peer propagation with Ed25519 signature verification |

---

## API Reference

Base URL: `https://ai.oooooooooo.se/api/v1`

All endpoints also accept `/api/` without the version prefix.

### Health & Meta

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Service status, version, record count, peer info |
| GET | `/pubkey` | Server Ed25519 public key for independent verification |
| GET | `/keygen` | Generate an Ed25519 keypair (for user-side signing) |

### Accounts

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/accounts` | Create account. Body: `{"username": "..."}`. Returns token. |

Account creation is sealed on the ledger as a provenance record.

### Records

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/records` | Submit content for provenance. Requires `Authorization: Bearer <token>`. Body: `{"content": "...", "model": "...", "context": "..."}` |
| GET | `/records/:id` | Retrieve a record by ID |
| GET | `/records/:id/verify` | Verify a record's signature and Merkle proof |

### Ledger

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/ledger/root` | Current Merkle root hash and record count |
| GET | `/ledger/recent` | Last 20 records |
| GET | `/ledger/proof/:id` | Merkle inclusion proof for a record |

### Peer Consensus

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/peers` | This node's public key, peer list, and consensus status |
| POST | `/peer/receive` | Receive a record from a peer node (requires known peer signature) |

---

## Quick Start

### Use the Public API

```bash
# 1. Create an account
curl -X POST https://ai.oooooooooo.se/api/v1/accounts \
  -H "Content-Type: application/json" \
  -d '{"username": "myuser"}'
# Save the token from the response!

# 2. Submit content
curl -X POST https://ai.oooooooooo.se/api/v1/records \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"content": "AI-generated text here", "model": "gpt-4"}'

# 3. Verify a record
curl https://ai.oooooooooo.se/api/v1/records/RECORD_ID/verify

# 4. Check ledger root
curl https://ai.oooooooooo.se/api/v1/ledger/root
```

### Self-Host

**Prerequisites:** Node.js 18+, npm, a [Cloudflare account](https://dash.cloudflare.com/sign-up) with Workers and D1 enabled.

```bash
# 1. Clone the repo
git clone https://github.com/fogennnnn/helios-ledger.git
cd helios-ledger/helios-worker

# 2. Install dependencies
npm install

# 3. Authenticate with Cloudflare
npx wrangler login

# 4. Create the D1 database
npx wrangler d1 create helios-ledger
# Copy the database_id from the output

# 5. Update wrangler.toml — replace YOUR_DATABASE_ID_HERE with the ID from step 4

# 6. Apply the database schema
npx wrangler d1 execute helios-ledger --file=schema.sql

# 7. Generate Ed25519 signing keys
node keygen.js
# Outputs two JSON lines: private key (line 1), then public key (line 2)

# 8. Set the signing keys as secrets
echo '<PRIVATE_KEY_JWK_FROM_LINE_1>' | npx wrangler secret put SIGNING_PRIVATE_KEY
echo '<PUBLIC_KEY_JWK_FROM_LINE_2>' | npx wrangler secret put SIGNING_PUBLIC_KEY

# 9. Deploy
npx wrangler deploy
```

Your Helios node is now live at your Workers URL (shown in the deploy output).

### Join a Peer Network

After deploying your own node, you can connect it to other Helios nodes for multi-node consensus:

```bash
# 1. Get the public node's signing key
curl https://ai.oooooooooo.se/api/v1/pubkey
# Note the public_key object from the response

# 2. Get your own node's signing key
curl https://YOUR_WORKER.workers.dev/api/v1/pubkey

# 3. Configure peers on YOUR node — add the public node as a peer
echo '[{"url":"https://ai.oooooooooo.se","public_key":{"kty":"OKP","crv":"Ed25519","x":"PUBLIC_KEY_X_VALUE"}}]' \
  | npx wrangler secret put PEERS

# 4. Ask the public node operator to add your node as a peer (provide your URL + public_key)

# 5. Verify the connection
curl https://YOUR_WORKER.workers.dev/api/v1/peers
```

Once peered, records submitted to either node automatically propagate to both with cryptographic verification. Each node independently verifies the origin signature before accepting a peer record.

---

## How It Works

1. **Submit** — Send content to the API with your auth token
2. **Hash & Sign** — Helios computes SHA-256 of content and signs it with Ed25519
3. **Merkle Inclusion** — The signed hash is appended to the incremental Merkle tree (O(log n))
4. **Peer Broadcast** — If peers are configured, the record is broadcast to all peer nodes
5. **Verify Anywhere** — Anyone can verify using the public key and Merkle proof

### Multi-Node Consensus

Each Helios node is its own Cloudflare Worker + D1 database with its own Ed25519 key pair. Nodes form a peer network:

- After sealing a record locally, the node **broadcasts** it to all configured peers via `POST /api/v1/peer/receive`
- The receiving node **verifies** the origin node's Ed25519 signature before accepting
- Accepted records are inserted into the receiver's own Merkle tree with a `source_node` marker
- Records received from peers are **not re-broadcast**, preventing infinite loops
- Each node exposes `GET /api/v1/peers` for discovery of its public key and peer list

---

## License

MIT — see [LICENSE](LICENSE).
