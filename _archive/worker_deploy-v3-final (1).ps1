# deploy-v3-final.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS\helios-worker"
Write-Host "Deploying v3 final - ALL hashing now synchronous..." -ForegroundColor Cyan
Copy-Item -Path "worker-v3.js" -Destination "worker.js" -Force
npx wrangler deploy
Write-Host "Done! Zero async crypto calls - record submission should work now." -ForegroundColor Green
