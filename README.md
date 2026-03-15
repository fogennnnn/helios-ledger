# ◉ Helios Ledger

**AI Provenance & Content Authenticity Platform**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-44%20passing-brightgreen)](tests/)
[![Python](https://img.shields.io/badge/python-3.11%2B-blue)](https://python.org)
[![Website](https://img.shields.io/badge/site-ai.oooooooooo.se-orange)](https://ai.oooooooooo.se)

Helios Ledger is an open-source platform for cryptographically sealing the **origin and integrity of AI-generated content**. It uses [Ed25519](https://ed25519.cr.yp.to/) digital signatures and an append-only Merkle tree to create tamper-proof provenance records — independently verifiable by anyone, requiring no trust in the platform itself.

> **Live instance:** [https://ai.oooooooooo.se](https://ai.oooooooooo.se)

---

## Why Helios?

AI-generated content is everywhere. The problem isn't that it exists — it's that there's no reliable way to prove **what was generated, when, by which model, and whether it's been altered since**. Helios solves that with pure cryptography.

| Problem | Helios Answer |
|---------|--------------|
| "Was this AI-generated?" | Ed25519-signed provenance record |
| "Has it been tampered with?" | Merkle inclusion proof |
| "Can I verify without trusting you?" | Yes — public key + proof, verifiable offline |
| "Can I run my own node?" | Yes — MIT licensed, self-hostable |

---

## Features

- 🔑 **Ed25519 signatures** — 64-byte, sub-millisecond verification
- 🌳 **Merkle-tree attestations** — append-only, tamper-evident history
- ⚡ **REST API** — JSON, simple auth, works from any language
- 🏅 **Reward system** — incentivize provenance submissions
- 🤝 **Multi-node consensus** — run a federated provenance network
- 📖 **MIT licensed** — audit, fork, and self-host freely

---

## Quick Start

### Prerequisites

- Python 3.11+
- pip

### Install & Run

```bash
git clone https://github.com/heliosledger/helios-ledger.git
cd helios-ledger
pip install -r requirements.txt
cp .env.example .env          # edit secrets
python -m app.main
```

The API will be live at `http://localhost:8000`.

### Submit a Provenance Record

```bash
# Register and get a token
curl -X POST http://localhost:8000/api/accounts \
  -H "Content-Type: application/json" \
  -d '{"username": "alice", "public_key": "<your-ed25519-pubkey-hex>"}'

# Submit content
curl -X POST http://localhost:8000/api/records \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "The patient presents with...",
    "model": "claude-sonnet-4",
    "context": "medical-report-2026-03-15"
  }'
```

### Verify a Record

```bash
curl http://localhost:8000/api/records/{record_id}/verify
# Returns: { "valid": true, "merkle_proof": [...], "signature": "..." }
```

---

## Architecture

```
helios-ledger/
├── app/
│   ├── api/          # FastAPI route handlers
│   ├── ledger/       # Core ledger logic
│   ├── merkle/       # Merkle tree implementation
│   ├── accounts/     # Account & key management
│   ├── rewards/      # Reward calculation
│   ├── consensus/    # Multi-node consensus
│   ├── crypto/       # Ed25519 sign/verify utilities
│   └── db/           # SQLite persistence layer
├── tests/            # 44 passing tests
└── docs/             # API reference
```

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/accounts` | Create account |
| `POST` | `/api/records` | Submit provenance record |
| `GET`  | `/api/records/{id}` | Retrieve record |
| `GET`  | `/api/records/{id}/verify` | Verify authenticity |
| `GET`  | `/api/ledger/root` | Current Merkle root |
| `GET`  | `/api/ledger/proof/{id}` | Merkle inclusion proof |

Full docs: [https://ai.oooooooooo.se/docs](https://ai.oooooooooo.se/docs)

---

## Tests

```bash
pytest tests/ -v
# ======================== 44 passed ========================
```

---

## Contributing

Pull requests are welcome. Please read [CONTRIBUTING.md](.github/CONTRIBUTING.md) first.

1. Fork the repo
2. Create your branch: `git checkout -b feat/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feat/your-feature`
5. Open a pull request

---

## License

[MIT](LICENSE) — free for personal and commercial use.

---

## Links

- 🌐 **Website:** [ai.oooooooooo.se](https://ai.oooooooooo.se)
- 📖 **Docs:** [ai.oooooooooo.se/docs](https://ai.oooooooooo.se/docs)
- 🐛 **Issues:** [GitHub Issues](https://github.com/heliosledger/helios-ledger/issues)
