# deploy-v19.ps1
# Save this + index_v19.html into C:\Users\fogen\HELIOS

Write-Host 'Deploying...' -ForegroundColor Cyan
if (-not (Test-Path 'index_v19.html')) { Write-Host 'ERROR: index_v19.html not found' -ForegroundColor Red; exit 1 }
Copy-Item -Path 'index_v19.html' -Destination 'docs\index.html' -Force
git add docs\index.html
git commit -m 'fix: move token badge outside quotes for cleaner display'
git push
Write-Host 'Done! https://ai.oooooooooo.se' -ForegroundColor Green
