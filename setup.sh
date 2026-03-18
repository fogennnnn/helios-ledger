#!/usr/bin/env bash
# Helios Ledger — One-script deploy
# Run: bash setup.sh
set -e

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   Helios Ledger — Node Setup v5.2    ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── 1. Clone ──────────────────────────────────────────────────────────
if [ -d "helios-ledger" ]; then
  echo "[1/6] helios-ledger/ already exists, skipping clone"
else
  echo "[1/6] Cloning repo..."
  git clone https://github.com/fogennnnn/helios-ledger
fi
cd helios-ledger/helios-worker

# ── 2. Install ────────────────────────────────────────────────────────
echo "[2/6] Installing dependencies..."
npm install

# ── 3. Wrangler login + D1 create ────────────────────────────────────
echo ""
echo "[3/6] Creating D1 database..."
echo "       (browser will open for Cloudflare login if needed)"
echo ""
D1_OUT=$(npx wrangler d1 create helios-ledger 2>&1) || true
echo "$D1_OUT"

DB_ID=$(echo "$D1_OUT" | grep -oP 'database_id\s*=\s*"\K[^"]+')
if [ -n "$DB_ID" ]; then
  echo ""
  echo "       Patching wrangler.toml with database_id: $DB_ID"
  sed -i "s/database_id = \".*\"/database_id = \"$DB_ID\"/" wrangler.toml
else
  echo ""
  echo "  ⚠  Could not auto-detect database_id."
  echo "     Paste it into wrangler.toml manually, then press Enter."
  read -r
fi

# ── 4. Apply schema ──────────────────────────────────────────────────
echo "[4/6] Applying database schema..."
npx wrangler d1 execute helios-ledger --file=schema.sql

# ── 5. Generate keys + set secrets ───────────────────────────────────
echo ""
echo "[5/6] Generating Ed25519 keypair..."
node keygen.js

echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  Copy the keys above, then set them as secrets:     ║"
echo "  ║                                                     ║"
echo "  ║  npx wrangler secret put SIGNING_PRIVATE_KEY        ║"
echo "  ║  npx wrangler secret put SIGNING_PUBLIC_KEY         ║"
echo "  ║                                                     ║"
echo "  ║  Paste each key when prompted.                      ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Set SIGNING_PRIVATE_KEY now:"
npx wrangler secret put SIGNING_PRIVATE_KEY

echo ""
echo "  Set SIGNING_PUBLIC_KEY now:"
npx wrangler secret put SIGNING_PUBLIC_KEY

# ── 6. Deploy ────────────────────────────────────────────────────────
echo ""
echo "[6/6] Deploying worker..."
npx wrangler deploy

echo ""
echo "  ✓ Helios Ledger deployed."
echo "  Run 'curl https://YOUR-WORKER.workers.dev/api/v1/health' to verify."
echo ""
