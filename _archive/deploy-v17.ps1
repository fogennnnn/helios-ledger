# deploy-v17.ps1
# Save this + index_v17.html into C:\Users\fogen\HELIOS

Write-Host 'Deploying...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v17.html')) { Write-Host 'ERROR: index_v17.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v17.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'fix: remove coming soon text, API is live'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
