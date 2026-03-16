# deploy-v22.ps1
# Save this + index_v22.html into C:\Users\fogen\HELIOS

Write-Host 'Deploying...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v22.html')) { Write-Host 'ERROR: index_v22.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v22.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'fix: button label, reliable clipboard copy, rate limits cleared'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
