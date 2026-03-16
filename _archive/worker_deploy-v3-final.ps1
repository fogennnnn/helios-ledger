# deploy-v3-final.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS\helios-worker"
Write-Host "Deploying v3 final - sync Merkle hashing..." -ForegroundColor Cyan
Copy-Item -Path "worker-v3.js" -Destination "worker.js" -Force
npx wrangler deploy
Write-Host "Done! Merkle tree now uses sync hash - no more CPU timeouts." -ForegroundColor Green
