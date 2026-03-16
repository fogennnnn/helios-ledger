# deploy-v2.ps1 — Helios Ledger v2 full deployment
# Save ALL files from helios-v2/ into C:\Users\fogen\HELIOS\helios-worker\
# Then run this script from C:\Users\fogen\HELIOS\helios-worker\

Set-Location $PSScriptRoot

Write-Host "=== Helios Ledger v2 Deploy ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prereqs
Write-Host "[1/5] Checking Node.js and Wrangler..." -ForegroundColor Cyan
node --version | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "Node.js not found. Install from nodejs.org" -ForegroundColor Red; exit 1 }
Write-Host "  Node.js OK" -ForegroundColor Green

# Step 2: Generate Ed25519 keypair
Write-Host "[2/5] Generating Ed25519 keypair..." -ForegroundColor Cyan
$keys = node keygen.js
Write-Host $keys

# Parse the two JSON lines from output
$lines = $keys -split "`n" | Where-Object { $_.Trim().StartsWith("{") }
if ($lines.Count -lt 2) {
    Write-Host "Failed to parse keys from keygen output" -ForegroundColor Red
    exit 1
}
$privateKeyJson = $lines[0].Trim()
$publicKeyJson  = $lines[1].Trim()
Write-Host "  Keys generated OK" -ForegroundColor Green

# Step 3: Set Wrangler secrets
Write-Host "[3/5] Setting Wrangler secrets..." -ForegroundColor Cyan
Write-Host "  Setting SIGNING_PRIVATE_KEY..."
$privateKeyJson | npx wrangler secret put SIGNING_PRIVATE_KEY
Write-Host "  Setting SIGNING_PUBLIC_KEY..."
$publicKeyJson  | npx wrangler secret put SIGNING_PUBLIC_KEY
Write-Host "  Secrets set OK" -ForegroundColor Green

# Step 4: Install deps if needed
Write-Host "[4/5] Checking Wrangler install..." -ForegroundColor Cyan
if (-not (Test-Path "node_modules")) {
    npm install --save-dev wrangler 2>&1 | Select-Object -Last 3
}
Write-Host "  OK" -ForegroundColor Green

# Step 5: Deploy
Write-Host "[5/5] Deploying worker..." -ForegroundColor Cyan
npx wrangler deploy

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Test: curl https://ai.oooooooooo.se/api/v1/health" -ForegroundColor Cyan
Write-Host "Pubkey: curl https://ai.oooooooooo.se/api/v1/pubkey" -ForegroundColor Cyan
