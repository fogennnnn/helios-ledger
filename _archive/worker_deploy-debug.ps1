# deploy-debug.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS\helios-worker"
Write-Host "Deploying debug worker..." -ForegroundColor Yellow
Copy-Item -Path "worker-v3-debug.js" -Destination "worker.js" -Force
npx wrangler deploy
Write-Host "Done! Now test the submit box and share the error message." -ForegroundColor Yellow
