# deploy-v3.ps1
# Deploys Helios Ledger Worker v3 - user signing + accounts on chain
# Run from anywhere in C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS\helios-worker"

Write-Host "=== Helios Worker v3 Deploy ===" -ForegroundColor Cyan

Write-Host "[1/2] Copying worker-v3.js..." -ForegroundColor Cyan
if (-not (Test-Path "worker-v3.js")) {
    Write-Host "ERROR: worker-v3.js not found in helios-worker\" -ForegroundColor Red; exit 1
}
Copy-Item -Path "worker-v3.js" -Destination "worker.js" -Force
Write-Host "  OK" -ForegroundColor Green

Write-Host "[2/2] Deploying to Cloudflare..." -ForegroundColor Cyan
npx wrangler deploy

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "New in v3:" -ForegroundColor Cyan
Write-Host "  GET  /api/v1/keygen          - generate Ed25519 keypair" -ForegroundColor Gray
Write-Host "  POST /api/v1/accounts        - account creation now sealed on chain" -ForegroundColor Gray
Write-Host "  POST /api/v1/records         - accepts user_signature for user_verified:true" -ForegroundColor Gray
