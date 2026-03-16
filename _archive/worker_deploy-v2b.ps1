# deploy-v2b.ps1
# Save this + worker-v2.js + wrangler-v2.toml into C:\Users\fogen\HELIOS\helios-worker\
# Then run from C:\Users\fogen\HELIOS\helios-worker\

Set-Location $PSScriptRoot

Write-Host "=== Helios Ledger v2 Deploy ===" -ForegroundColor Cyan

# Step 0: Copy new files into place
Write-Host "[0/5] Copying new worker files..." -ForegroundColor Cyan
if (-not (Test-Path "worker-v2.js"))    { Write-Host "ERROR: worker-v2.js not found in this folder" -ForegroundColor Red; exit 1 }
if (-not (Test-Path "wrangler-v2.toml")){ Write-Host "ERROR: wrangler-v2.toml not found in this folder" -ForegroundColor Red; exit 1 }
Copy-Item -Path "worker-v2.js"    -Destination "worker.js"    -Force
Copy-Item -Path "wrangler-v2.toml" -Destination "wrangler.toml" -Force
Write-Host "  Files copied OK" -ForegroundColor Green

# Step 1: Check Node
Write-Host "[1/5] Checking Node.js..." -ForegroundColor Cyan
node --version | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "Node.js not found" -ForegroundColor Red; exit 1 }
Write-Host "  OK" -ForegroundColor Green

# Step 2: Generate Ed25519 keypair
Write-Host "[2/5] Generating Ed25519 keypair..." -ForegroundColor Cyan
if (-not (Test-Path "keygen.js")) { Write-Host "ERROR: keygen.js not found" -ForegroundColor Red; exit 1 }
$keys = node keygen.js
$lines = ($keys -split "`n") | Where-Object { $_.Trim().StartsWith("{") }
if ($lines.Count -lt 2) { Write-Host "ERROR: Could not parse keys" -ForegroundColor Red; Write-Host $keys; exit 1 }
$privateKeyJson = $lines[0].Trim()
$publicKeyJson  = $lines[1].Trim()
Write-Host "  Keypair generated OK" -ForegroundColor Green

# Step 3: Set secrets
Write-Host "[3/5] Setting Wrangler secrets..." -ForegroundColor Cyan
$privateKeyJson | npx wrangler secret put SIGNING_PRIVATE_KEY
$publicKeyJson  | npx wrangler secret put SIGNING_PUBLIC_KEY
Write-Host "  Secrets set OK" -ForegroundColor Green

# Step 4: Install deps if needed
Write-Host "[4/5] Checking Wrangler..." -ForegroundColor Cyan
if (-not (Test-Path "node_modules")) { npm install --save-dev wrangler 2>&1 | Select-Object -Last 2 }
Write-Host "  OK" -ForegroundColor Green

# Step 5: Deploy
Write-Host "[5/5] Deploying..." -ForegroundColor Cyan
npx wrangler deploy

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "Run test-v2.ps1 to verify all 16 fixes" -ForegroundColor Cyan
