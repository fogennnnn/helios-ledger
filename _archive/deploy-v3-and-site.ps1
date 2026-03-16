# deploy-v3-and-site.ps1
# Deploys worker v3 fix + site fix together
# Run from C:\Users\fogen\HELIOS

# 1. Deploy worker fix
Set-Location "C:\Users\fogen\HELIOS\helios-worker"
Write-Host "[1/2] Deploying worker fix (atomic batch, no more 500)..." -ForegroundColor Cyan
Copy-Item -Path "worker-v3.js" -Destination "worker.js" -Force
npx wrangler deploy
Write-Host "  Worker deployed" -ForegroundColor Green

# 2. Deploy site fix
Set-Location "C:\Users\fogen\HELIOS"
Write-Host "[2/2] Deploying site fix (correct API path)..." -ForegroundColor Cyan
if (-not (Test-Path "index_v25c.html")) { Write-Host "ERROR: index_v25c.html not found" -ForegroundColor Red; exit 1 }
Copy-Item -Path "index_v25c.html" -Destination "docs\index.html" -Force
git add docs\index.html
git commit -m "fix: atomic DB batch prevents 500, correct api/v1 path in demo"
git push
Write-Host "  Site deployed" -ForegroundColor Green

Write-Host ""
Write-Host "All done! https://ai.oooooooooo.se" -ForegroundColor Green
