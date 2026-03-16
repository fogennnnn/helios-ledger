# Helios Ledger

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python](https://img.shields.io/badge/runtime-Cloudflare%20Workers-orange)](https://workers.cloudflare.com)
[![Website](https://img.shields.io/badge/site-ai.oooooooooo.se-teal)](https://ai.oooooooooo.se)

Helios Ledger is an open-source platform for cryptographically sealing the **origin and integrity of AI-generated content**. It uses [Ed25519](https://ed25519.cr.yp.to/) digital signatures and an append-only Merkle tree to create tamper-proof provenance records -- independently verifiable by anyone, requiring no trust in the platform itself.

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
| Ledger | Append-only Merkle tree with inclusion proofs |

---

## API Reference

Base URL: `https://ai.oooooooooo.se/api/v1`

All endpoints also accept `/api/` without the version prefix.

### Health & Meta

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Service status, version, record count |
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

Requirements: Node.js 18+, Cloudflare account with Workers and D1.

```bash
git clone https://github.com/fogennnnn/helios-ledger.git
cd helios-ledger/helios-worker
npm install --save-dev wrangler
npx wrangler login
npx wrangler d1 create helios-ledger
# Update database_id in wrangler.toml
node keygen.js  # Generate Ed25519 signing keys
# Set secrets:
echo '<private_key_jwk>' | npx wrangler secret put SIGNING_PRIVATE_KEY
echo '<public_key_jwk>' | npx wrangler secret put SIGNING_PUBLIC_KEY
npx wrangler deploy
```

---

## How It Works

1. **Submit** -- Send content to the API with your auth token
2. **Hash & Sign** -- Helios computes SHA-256 of content and signs it with Ed25519
3. **Merkle Inclusion** -- The signed hash is appended to the Merkle tree
4. **Verify Anywhere** -- Anyone can verify using the public key and Merkle proof

---

## License

MIT -- see [LICENSE](LICENSE).
