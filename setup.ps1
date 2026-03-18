# Helios Ledger — One-script deploy (PowerShell)
# Run: .\setup.ps1
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  +======================================+" -ForegroundColor Cyan
Write-Host "  |   Helios Ledger - Node Setup v5.2    |" -ForegroundColor Cyan
Write-Host "  +======================================+" -ForegroundColor Cyan
Write-Host ""

# -- 1. Clone ---------------------------------------------------------------
if (Test-Path "helios-ledger") {
    Write-Host "[1/6] helios-ledger/ already exists, skipping clone" -ForegroundColor Yellow
} else {
    Write-Host "[1/6] Cloning repo..."
    git clone https://github.com/fogennnnn/helios-ledger
}
Set-Location helios-ledger\helios-worker

# -- 2. Install --------------------------------------------------------------
Write-Host "[2/6] Installing dependencies..."
npm install

# -- 3. Wrangler login + D1 create ------------------------------------------
Write-Host ""
Write-Host "[3/6] Creating D1 database..."
Write-Host "       (browser will open for Cloudflare login if needed)"
Write-Host ""

$d1Out = npx wrangler d1 create helios-ledger 2>&1 | Out-String
Write-Host $d1Out

if ($d1Out -match 'database_id\s*=\s*"([^"]+)"') {
    $dbId = $Matches[1]
    Write-Host "       Patching wrangler.toml with database_id: $dbId" -ForegroundColor Green
    (Get-Content wrangler.toml) -replace 'database_id = ".*"', "database_id = `"$dbId`"" |
        Set-Content wrangler.toml
} else {
    Write-Host "  ! Could not auto-detect database_id." -ForegroundColor Yellow
    Write-Host "    Paste it into wrangler.toml manually, then press Enter."
    Read-Host
}

# -- 4. Apply schema ---------------------------------------------------------
Write-Host "[4/6] Applying database schema..."
npx wrangler d1 execute helios-ledger --file=schema.sql

# -- 5. Generate keys + set secrets ------------------------------------------
Write-Host ""
Write-Host "[5/6] Generating Ed25519 keypair..."
node keygen.js

Write-Host ""
Write-Host "  +====================================================+" -ForegroundColor Cyan
Write-Host "  |  Copy the keys above, then paste when prompted:    |" -ForegroundColor Cyan
Write-Host "  +====================================================+" -ForegroundColor Cyan
Write-Host ""

Write-Host "  Set SIGNING_PRIVATE_KEY now:" -ForegroundColor Yellow
npx wrangler secret put SIGNING_PRIVATE_KEY

Write-Host ""
Write-Host "  Set SIGNING_PUBLIC_KEY now:" -ForegroundColor Yellow
npx wrangler secret put SIGNING_PUBLIC_KEY

# -- 6. Deploy ---------------------------------------------------------------
Write-Host ""
Write-Host "[6/6] Deploying worker..."
npx wrangler deploy

Write-Host ""
Write-Host "  Done. Helios Ledger deployed." -ForegroundColor Green
Write-Host "  Verify: curl https://YOUR-WORKER.workers.dev/api/v1/health"
Write-Host ""
