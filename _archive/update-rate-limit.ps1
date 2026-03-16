# update-rate-limit.ps1
# Run from C:\Users\fogen\HELIOS\helios-worker

Write-Host 'Updating rate limit to 10/hour...' -ForegroundColor Cyan

if (-not (Test-Path 'worker-v2b.js')) {
    Write-Host 'ERROR: worker-v2b.js not found' -ForegroundColor Red; exit 1
}

Copy-Item -Path 'worker-v2b.js' -Destination 'worker.js' -Force
npx wrangler deploy

Write-Host 'Done! Rate limit is now 10 accounts per IP per hour.' -ForegroundColor Green
