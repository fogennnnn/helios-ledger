# deploy-v12.ps1
# Save this + index_v12.html into C:\Users\fogen\HELIOS
# Run from C:\Users\fogen\HELIOS

Write-Host 'Deploying live-API terminal...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v12.html')) { Write-Host 'ERROR: index_v12.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v12.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'feat: animated terminal makes live API calls, auto-injects real token'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
