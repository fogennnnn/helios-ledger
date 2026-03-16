# fix-rate-limit.ps1
# Run from C:\Users\fogen\HELIOS

Set-Location "C:\Users\fogen\HELIOS\helios-worker"
Write-Host "Patching rate limit to 10/hour..." -ForegroundColor Cyan
(Get-Content worker.js -Raw) -replace 'RATE_MAX_ACCT = 5', 'RATE_MAX_ACCT = 10' | Set-Content worker.js
Write-Host "Deploying..." -ForegroundColor Cyan
npx wrangler deploy
Write-Host "Done! Rate limit is now 10 per hour." -ForegroundColor Green
