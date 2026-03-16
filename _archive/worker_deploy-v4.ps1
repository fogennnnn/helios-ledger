# deploy-v4.ps1 -- Helios Ledger Worker v4 production repair
# Fixes POST /api/v1/records 500, adds missing endpoints, better error handling
# Run from anywhere -- script handles cd automatically

Set-Location "C:\Users\fogen\HELIOS\helios-worker"

Write-Host "=== Helios Ledger Worker v4 Deploy ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Overwrite worker.js with v4
Write-Host "[1/2] Copying worker-v4.js to worker.js..." -ForegroundColor Cyan
if (-not (Test-Path "worker-v4.js")) {
    Write-Host "ERROR: worker-v4.js not found in helios-worker\" -ForegroundColor Red
    Write-Host "Download it from Claude and place it in C:\Users\fogen\HELIOS\helios-worker\" -ForegroundColor Yellow
    exit 1
}
Copy-Item -Path "worker-v4.js" -Destination "worker.js" -Force
Write-Host "  Done" -ForegroundColor Green

# Step 2: Deploy
Write-Host "[2/2] Deploying to Cloudflare Workers..." -ForegroundColor Cyan
npx wrangler deploy

Write-Host ""
Write-Host "=== DEPLOYED ===" -ForegroundColor Green
Write-Host ""
Write-Host "Test the fix:" -ForegroundColor Cyan
Write-Host '  $a = Invoke-RestMethod -Uri "https://ai.oooooooooo.se/api/v1/accounts" -Method POST -ContentType "application/json" -Body ''{"username":"test_deploy"}''' -ForegroundColor Gray
Write-Host '  $a.token  # copy this' -ForegroundColor Gray
Write-Host '  Invoke-RestMethod -Uri "https://ai.oooooooooo.se/api/v1/records" -Method POST -ContentType "application/json" -Headers @{"Authorization"="Bearer $($a.token)"} -Body ''{"content":"hello world","model":"test"}''' -ForegroundColor Gray
Write-Host ""
Write-Host "New/fixed endpoints:" -ForegroundColor Cyan
Write-Host "  POST /api/v1/records       -- FIXED (was 500)" -ForegroundColor Green
Write-Host "  GET  /api/v1/ledger/recent -- NEW" -ForegroundColor Green
Write-Host "  GET  /api/v1/pubkey        -- FIXED" -ForegroundColor Green
Write-Host "  GET  /api/v1/health        -- version 4.0.0" -ForegroundColor Green
