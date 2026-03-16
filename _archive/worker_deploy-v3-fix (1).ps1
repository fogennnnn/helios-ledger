# deploy-v3-fix.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS\helios-worker"
Write-Host "Deploying worker v3 fix (await handlers)..." -ForegroundColor Cyan
Copy-Item -Path "worker-v3.js" -Destination "worker.js" -Force
npx wrangler deploy
Write-Host "Done!" -ForegroundColor Green
